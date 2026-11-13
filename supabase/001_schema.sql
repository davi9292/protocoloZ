-- PROTOCOLO Z — schema inicial. Executar no SQL Editor do Supabase.
create extension if not exists pgcrypto;

create table public.factions (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  symbol text not null,
  color_hex text not null,
  description text not null
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nickname text not null,
  avatar_url text,
  faction_id uuid references public.factions(id),
  reputation integer not null default 0 check (reputation >= 0),
  created_at timestamptz not null default now()
);

create table public.items (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  icon text not null,
  category text not null check (category in ('agua','comida','medicamentos','ferramentas','combustivel','outros'))
);

create table public.inventory (
  user_id uuid not null references public.profiles(id) on delete cascade,
  item_id uuid not null references public.items(id),
  quantity integer not null default 0 check (quantity >= 0),
  primary key(user_id, item_id)
);

create table public.shelters (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id),
  faction_id uuid references public.factions(id),
  name text not null,
  description text not null default '',
  capacity integer not null check (capacity > 0),
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  photo_url text,
  visibility text not null check (visibility in ('public','faction')),
  status text not null default 'safe' check (status in ('safe','compromised')),
  created_at timestamptz not null default now()
);

create table public.expedition_types (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text not null,
  duration_seconds integer not null check (duration_seconds between 60 and 300),
  risk_level integer not null check (risk_level between 1 and 5),
  reward_table jsonb not null
);

create table public.expeditions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id),
  type_id uuid not null references public.expedition_types(id),
  started_at timestamptz not null default now(),
  ends_at timestamptz not null,
  status text not null default 'active' check (status in ('active','completed','failed')),
  rewards jsonb,
  collected_at timestamptz
);
create unique index one_active_expedition_per_user on public.expeditions(user_id) where status='active';

create table public.trades (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id),
  recipient_id uuid not null references public.profiles(id),
  status text not null default 'pending' check (status in ('pending','accepted','declined','cancelled','expired')),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '24 hours',
  completed_at timestamptz,
  check (author_id <> recipient_id)
);

create table public.trade_items (
  id uuid primary key default gen_random_uuid(),
  trade_id uuid not null references public.trades(id) on delete cascade,
  item_id uuid not null references public.items(id),
  side text not null check (side in ('offer','request')),
  quantity integer not null check (quantity > 0),
  unique(trade_id,item_id,side)
);

create table public.horde_alerts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id),
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  intensity text not null check (intensity in ('low','medium','high')),
  description text not null check (char_length(description) between 3 and 180),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '30 minutes',
  reputation_awarded_at timestamptz
);

create table public.alert_confirmations (
  id uuid primary key default gen_random_uuid(),
  alert_id uuid not null references public.horde_alerts(id) on delete cascade,
  user_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  unique(alert_id,user_id)
);

create index shelters_location_idx on public.shelters(latitude,longitude);
create index alerts_expiry_idx on public.horde_alerts(expires_at);
create index trades_recipient_status_idx on public.trades(recipient_id,status);
create index inventory_user_idx on public.inventory(user_id);

-- Profile automático a partir dos metadados do Auth.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public
as $$
begin
  insert into public.profiles(id,nickname)
  values(new.id, coalesce(new.raw_user_meta_data->>'nickname', split_part(new.email,'@',1)));
  return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Kit inicial e catálogo de jogo.
insert into public.factions(name,symbol,color_hex,description) values
('Sentinelas','🛡️','#9DBB73','Defensores de perímetros e especialistas em proteção.'),
('Errantes','⚡','#D6A84F','Exploradores ágeis que conhecem rotas esquecidas.'),
('Engenheiros','⚙️','#6FA7B8','Especialistas em reparo, tecnologia e infraestrutura.')
on conflict(name) do nothing;

insert into public.items(name,icon,category) values
('Água potável','💧','agua'),('Ração','🥫','comida'),('Analgésico','💊','medicamentos'),
('Kit de ferramentas','🧰','ferramentas'),('Gasolina','⛽','combustivel')
on conflict(name) do nothing;

insert into public.expedition_types(name,description,duration_seconds,risk_level,reward_table) values
('Mercado abandonado','Procure alimentos e água entre os corredores destruídos.',60,2,
 '[{"item":"Água potável","min":1,"max":3,"chance":0.8},{"item":"Ração","min":1,"max":4,"chance":0.9}]'),
('Hospital','Vasculhe alas médicas em busca de suprimentos.',120,4,
 '[{"item":"Analgésico","min":1,"max":3,"chance":0.8},{"item":"Água potável","min":1,"max":2,"chance":0.4}]'),
('Posto de gasolina','Uma incursão perigosa por combustível e ferramentas.',180,3,
 '[{"item":"Gasolina","min":1,"max":4,"chance":0.8},{"item":"Kit de ferramentas","min":1,"max":2,"chance":0.5}]')
on conflict(name) do nothing;
