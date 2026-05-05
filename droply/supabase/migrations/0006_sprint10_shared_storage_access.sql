create or replace function public.storage_path_has_active_share(p_storage_path text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.files f
    join public.shares s on s.file_id = f.id
    where f.storage_path = p_storage_path
      and f.is_deleted = false
      and s.revoked = false
      and s.expires_at > now()
  );
$$;

revoke all on function public.storage_path_has_active_share(text) from public;
grant execute on function public.storage_path_has_active_share(text) to anon, authenticated;

drop policy if exists "droply_files_select_active_share" on storage.objects;
create policy "droply_files_select_active_share"
on storage.objects
for select
to anon, authenticated
using (
  bucket_id = 'droply-files'
  and public.storage_path_has_active_share(name)
);
