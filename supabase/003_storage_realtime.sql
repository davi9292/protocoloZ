-- Bucket privado: use signed URLs no app se desejar ocultar mídias não públicas.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('player-media','player-media',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict(id) do nothing;

create policy "players upload own folder" on storage.objects for insert to authenticated
with check(bucket_id='player-media' and (storage.foldername(name))[2]=auth.uid()::text);
create policy "players update own files" on storage.objects for update to authenticated
using(bucket_id='player-media' and (storage.foldername(name))[2]=auth.uid()::text)
with check(bucket_id='player-media' and (storage.foldername(name))[2]=auth.uid()::text);
create policy "players delete own files" on storage.objects for delete to authenticated
using(bucket_id='player-media' and (storage.foldername(name))[2]=auth.uid()::text);
create policy "public read player media" on storage.objects for select to public using(bucket_id='player-media');

-- Habilite as tabelas para Supabase Realtime (idempotente).
do $$
begin
  alter publication supabase_realtime add table public.horde_alerts;
exception when duplicate_object then null;
when undefined_object then null;
end $$;
do $$
begin
  alter publication supabase_realtime add table public.trades;
exception when duplicate_object then null;
when undefined_object then null;
end $$;
