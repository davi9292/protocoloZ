-- RLS em todas as tabelas. Cliente nunca escreve diretamente em inventário/reputação/facção.
alter table public.factions enable row level security;
alter table public.profiles enable row level security;
alter table public.items enable row level security;
alter table public.inventory enable row level security;
alter table public.shelters enable row level security;
alter table public.expedition_types enable row level security;
alter table public.expeditions enable row level security;
alter table public.trades enable row level security;
alter table public.trade_items enable row level security;
alter table public.horde_alerts enable row level security;
alter table public.alert_confirmations enable row level security;

create policy "factions readable" on public.factions for select to authenticated using(true);
create policy "profiles readable" on public.profiles for select to authenticated using(true);
create policy "profile owner update" on public.profiles for update to authenticated
using(id=auth.uid()) with check(id=auth.uid());
revoke update on public.profiles from anon, authenticated;
grant update (nickname,avatar_url) on public.profiles to authenticated;
create policy "items readable" on public.items for select to authenticated using(true);
create policy "inventory own read" on public.inventory for select to authenticated using(user_id=auth.uid());
create policy "expedition types readable" on public.expedition_types for select to authenticated using(true);
create policy "expeditions own read" on public.expeditions for select to authenticated using(user_id=auth.uid());
create policy "shelters readable by visibility" on public.shelters for select to authenticated using(
 visibility='public' or faction_id=(select faction_id from public.profiles where id=auth.uid())
);
create policy "shelter owner insert" on public.shelters for insert to authenticated
with check(owner_id=auth.uid() and faction_id=(select faction_id from public.profiles where id=auth.uid()));
create policy "shelter owner update" on public.shelters for update to authenticated
using(owner_id=auth.uid()) with check(owner_id=auth.uid());
create policy "shelter owner delete" on public.shelters for delete to authenticated using(owner_id=auth.uid());
create policy "trade participants read" on public.trades for select to authenticated using(auth.uid() in (author_id,recipient_id));
create policy "trade items participants read" on public.trade_items for select to authenticated using(
 exists(select 1 from public.trades t where t.id=trade_id and auth.uid() in (t.author_id,t.recipient_id))
);
create policy "alerts active read" on public.horde_alerts for select to authenticated using(expires_at>now());
create policy "alert own insert" on public.horde_alerts for insert to authenticated with check(author_id=auth.uid());
create policy "confirmations read" on public.alert_confirmations for select to authenticated using(true);

-- Impedir alterações diretas de facção e reputação inclusive por colunas escolhidas pelo cliente.
revoke insert, update, delete on public.inventory from anon, authenticated;
revoke insert, update, delete on public.alert_confirmations from anon, authenticated;
revoke insert, update, delete on public.trades from anon, authenticated;
revoke insert, update, delete on public.trade_items from anon, authenticated;
revoke update (faction_id,reputation) on public.profiles from anon, authenticated;

create or replace function public.choose_faction(p_faction_id uuid)
returns void language plpgsql security definer set search_path=public
as $$
declare v_user uuid := auth.uid();
begin
 if v_user is null then raise exception 'Sessão inválida'; end if;
 if not exists(select 1 from public.factions where id=p_faction_id) then raise exception 'Facção inválida'; end if;
 update public.profiles set faction_id=p_faction_id where id=v_user and faction_id is null;
 if not found then raise exception 'A facção já foi escolhida e não pode ser alterada'; end if;
 insert into public.inventory(user_id,item_id,quantity)
 select v_user,i.id,seed.quantity
 from (values ('Água potável',3),('Ração',3),('Analgésico',1),('Kit de ferramentas',1)) seed(item_name,quantity)
 join public.items i on i.name=seed.item_name
 on conflict(user_id,item_id) do update set quantity=public.inventory.quantity+excluded.quantity;
end; $$;

create or replace function public.start_expedition(p_type_id uuid)
returns uuid language plpgsql security definer set search_path=public
as $$
declare v_id uuid; v_duration int;
begin
 if auth.uid() is null then raise exception 'Sessão inválida'; end if;
 select duration_seconds into v_duration from public.expedition_types where id=p_type_id;
 if v_duration is null then raise exception 'Tipo de expedição inválido'; end if;
 if exists(select 1 from public.expeditions where user_id=auth.uid() and status='active') then raise exception 'Você já possui uma expedição em andamento'; end if;
 insert into public.expeditions(user_id,type_id,ends_at)
 values(auth.uid(),p_type_id,now()+make_interval(secs=>v_duration)) returning id into v_id;
 return v_id;
end; $$;

create or replace function public.collect_expedition(p_expedition_id uuid)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare e public.expeditions; t public.expedition_types; reward jsonb; entry jsonb; item_id uuid; qty int; result jsonb := '[]'::jsonb;
begin
 select * into e from public.expeditions where id=p_expedition_id and user_id=auth.uid() for update;
 if not found or e.status<>'active' then raise exception 'Expedição indisponível'; end if;
 if now()<e.ends_at then raise exception 'A expedição ainda está em andamento'; end if;
 select * into t from public.expedition_types where id=e.type_id;
 for entry in select value from jsonb_array_elements(t.reward_table) loop
   if random() <= (entry->>'chance')::numeric then
     select id into item_id from public.items where name=entry->>'item';
     qty := floor(random()*((entry->>'max')::int-(entry->>'min')::int+1)+(entry->>'min')::int)::int;
     insert into public.inventory(user_id,item_id,quantity) values(auth.uid(),item_id,qty)
     on conflict(user_id,item_id) do update set quantity=public.inventory.quantity+excluded.quantity;
     result := result || jsonb_build_array(jsonb_build_object('item',entry->>'item','quantity',qty));
   end if;
 end loop;
 update public.expeditions set status='completed',rewards=result,collected_at=now() where id=e.id;
 update public.profiles set reputation=reputation+10 where id=auth.uid();
 return jsonb_build_object('rewards',result);
end; $$;

create or replace function public.create_trade(p_recipient_id uuid,p_items jsonb)
returns uuid language plpgsql security definer set search_path=public
as $$
declare v_id uuid; entry jsonb;
begin
 if auth.uid() is null or p_recipient_id=auth.uid() then raise exception 'Destinatário inválido'; end if;
 if not exists(select 1 from public.profiles where id=p_recipient_id and faction_id is not null) then raise exception 'Jogador destinatário não encontrado'; end if;
 if jsonb_array_length(p_items)<2 then raise exception 'Informe itens oferecidos e solicitados'; end if;
 insert into public.trades(author_id,recipient_id) values(auth.uid(),p_recipient_id) returning id into v_id;
 for entry in select value from jsonb_array_elements(p_items) loop
   if (entry->>'quantity')::int<=0 or entry->>'side' not in ('offer','request') then raise exception 'Item ou quantidade inválida'; end if;
   insert into public.trade_items(trade_id,item_id,side,quantity)
   values(v_id,(entry->>'item_id')::uuid,entry->>'side',(entry->>'quantity')::int);
 end loop;
 return v_id;
end; $$;

create or replace function public.respond_trade(p_trade_id uuid,p_action text)
returns void language plpgsql security definer set search_path=public
as $$
declare t public.trades;
begin
 select * into t from public.trades where id=p_trade_id for update;
 if not found or t.status<>'pending' then raise exception 'Proposta indisponível'; end if;
 if now()>t.expires_at then update public.trades set status='expired' where id=t.id; raise exception 'Proposta expirada'; end if;
 if p_action='cancel' and auth.uid()=t.author_id then update public.trades set status='cancelled' where id=t.id; return; end if;
 if p_action='decline' and auth.uid()=t.recipient_id then update public.trades set status='declined' where id=t.id; return; end if;
 if p_action<>'accept' or auth.uid()<>t.recipient_id then raise exception 'Ação não permitida'; end if;
 -- Bloqueia os registros de inventário dos dois jogadores antes de validar.
 perform 1 from public.inventory where user_id in (t.author_id,t.recipient_id) for update;
 -- Validação antes de qualquer transferência.
 if exists(
   select 1 from public.trade_items ti
   left join public.inventory inv on inv.user_id=t.author_id and inv.item_id=ti.item_id
   where ti.trade_id=t.id and ti.side='offer' and coalesce(inv.quantity,0)<ti.quantity
 ) or exists(
   select 1 from public.trade_items ti
   left join public.inventory inv on inv.user_id=t.recipient_id and inv.item_id=ti.item_id
   where ti.trade_id=t.id and ti.side='request' and coalesce(inv.quantity,0)<ti.quantity
 ) then raise exception 'Um dos jogadores não possui mais os itens necessários'; end if;
 update public.inventory inv set quantity=inv.quantity-ti.quantity
 from public.trade_items ti where ti.trade_id=t.id and ti.side='offer' and inv.user_id=t.author_id and inv.item_id=ti.item_id;
 update public.inventory inv set quantity=inv.quantity+ti.quantity
 from public.trade_items ti where ti.trade_id=t.id and ti.side='offer' and inv.user_id=t.recipient_id and inv.item_id=ti.item_id;
 update public.inventory inv set quantity=inv.quantity-ti.quantity
 from public.trade_items ti where ti.trade_id=t.id and ti.side='request' and inv.user_id=t.recipient_id and inv.item_id=ti.item_id;
 update public.inventory inv set quantity=inv.quantity+ti.quantity
 from public.trade_items ti where ti.trade_id=t.id and ti.side='request' and inv.user_id=t.author_id and inv.item_id=ti.item_id;
 update public.trades set status='accepted',completed_at=now() where id=t.id;
 update public.profiles set reputation=reputation+20 where id in (t.author_id,t.recipient_id);
end; $$;

create or replace function public.confirm_horde_alert(p_alert_id uuid)
returns void language plpgsql security definer set search_path=public
as $$
declare a public.horde_alerts; n int;
begin
 select * into a from public.horde_alerts where id=p_alert_id for update;
 if not found or a.expires_at<=now() then raise exception 'Alerta expirado ou inexistente'; end if;
 if a.author_id=auth.uid() then raise exception 'Você não pode confirmar seu próprio alerta'; end if;
 insert into public.alert_confirmations(alert_id,user_id) values(p_alert_id,auth.uid());
 select count(*) into n from public.alert_confirmations where alert_id=p_alert_id;
 if n>=2 and a.reputation_awarded_at is null then
   update public.profiles set reputation=reputation+25 where id=a.author_id;
   update public.horde_alerts set reputation_awarded_at=now() where id=p_alert_id;
 end if;
end; $$;

create or replace function public.profile_stats()
returns jsonb language sql stable security definer set search_path=public
as $$
 select jsonb_build_object(
  'completed_expeditions',(select count(*) from public.expeditions where user_id=auth.uid() and status='completed'),
  'completed_trades',(select count(*) from public.trades where status='accepted' and auth.uid() in (author_id,recipient_id)),
  'shelters_count',(select count(*) from public.shelters where owner_id=auth.uid()),
  'alerts_confirmed',(select count(*) from public.alert_confirmations where user_id=auth.uid())
 );
$$;

create or replace view public.inventory_view as
select i.id as item_id,i.name,i.icon,i.category,coalesce(v.quantity,0)::int as quantity
from public.items i left join public.inventory v on v.item_id=i.id and v.user_id=auth.uid()
where coalesce(v.quantity,0)>0;

create or replace view public.survivor_ranking as
select row_number() over(order by p.reputation desc,p.nickname) as position,
 p.id,p.nickname,p.reputation,f.name as faction_name,f.symbol
from public.profiles p left join public.factions f on f.id=p.faction_id
where p.faction_id is not null;

create or replace view public.faction_ranking as
select f.id,f.name,f.symbol,coalesce(sum(p.reputation),0)::int as total_reputation,count(p.id)::int as members
from public.factions f left join public.profiles p on p.faction_id=f.id
group by f.id,f.name,f.symbol;

grant execute on function public.choose_faction(uuid) to authenticated;
grant execute on function public.start_expedition(uuid) to authenticated;
grant execute on function public.collect_expedition(uuid) to authenticated;
grant execute on function public.create_trade(uuid,jsonb) to authenticated;
grant execute on function public.respond_trade(uuid,text) to authenticated;
grant execute on function public.respond_trade(uuid,text) to authenticated;
grant execute on function public.confirm_horde_alert(uuid) to authenticated;
grant execute on function public.profile_stats() to authenticated;

-- Views precisam ser consultáveis por usuários autenticados.
grant select on public.inventory_view,public.survivor_ranking,public.faction_ranking to authenticated;

-- Reputação de abrigo: concedida somente pelo trigger do banco.
create or replace function public.award_shelter_reputation()
returns trigger language plpgsql security definer set search_path=public
as $$
begin
  update public.profiles set reputation=reputation+15 where id=new.owner_id;
  return new;
end; $$;
drop trigger if exists shelter_reputation_after_insert on public.shelters;
create trigger shelter_reputation_after_insert after insert on public.shelters
for each row execute function public.award_shelter_reputation();

create or replace function public.set_shelter_faction()
returns trigger language plpgsql security definer set search_path=public
as $$
begin
  select faction_id into new.faction_id from public.profiles where id=new.owner_id;
  if new.faction_id is null then raise exception 'Escolha uma facção antes de cadastrar abrigo'; end if;
  return new;
end; $$;
drop trigger if exists shelter_set_faction_before_insert on public.shelters;
create trigger shelter_set_faction_before_insert before insert on public.shelters
for each row execute function public.set_shelter_faction();
