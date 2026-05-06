-- Migracion 0010: colaboracion real sobre carpetas compartidas.
-- Mantiene una unica carpeta fisica y aplica permisos por RPC.

create or replace function public.user_has_folder_access(
  p_user_id uuid,
  p_folder_id uuid
)
returns table (
  has_access boolean,
  permission text,
  is_owner boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_folder_owner uuid;
  v_share_permission text;
begin
  select owner_id
  into v_folder_owner
  from public.folders
  where id = p_folder_id;

  if v_folder_owner is null then
    return query select false, null::text, false;
    return;
  end if;

  if v_folder_owner = p_user_id then
    return query select true, 'full'::text, true;
    return;
  end if;

  with recursive folder_ancestors as (
    select id, parent_id, 0 as depth
    from public.folders
    where id = p_folder_id

    union all

    select parent.id, parent.parent_id, child.depth + 1
    from public.folders parent
    join folder_ancestors child on child.parent_id = parent.id
  ),
  matching_shares as (
    select
      fs.permission::text as permission,
      fa.depth,
      case fs.permission::text
        when 'full' then 4
        when 'upload' then 3
        when 'download' then 2
        else 1
      end as permission_rank
    from folder_ancestors fa
    join public.folder_shares fs on fs.folder_id = fa.id
    where fs.shared_with_user_id = p_user_id
      and (fa.depth = 0 or fs.inherit_to_subfolders = true)
  )
  select ms.permission
  into v_share_permission
  from matching_shares ms
  order by ms.depth asc, ms.permission_rank desc
  limit 1;

  if v_share_permission is not null then
    return query select true, v_share_permission, false;
    return;
  end if;

  return query select false, null::text, false;
end;
$$;

create or replace function public.folder_permission_rank(p_permission text)
returns integer
language sql
immutable
as $$
  select case p_permission
    when 'full' then 4
    when 'upload' then 3
    when 'download' then 2
    when 'view' then 1
    else 0
  end;
$$;

create or replace function public.require_folder_permission(
  p_user_id uuid,
  p_folder_id uuid,
  p_min_permission text
)
returns table (
  folder_owner_id uuid,
  permission text,
  is_owner boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_access record;
  v_owner_id uuid;
begin
  select owner_id
  into v_owner_id
  from public.folders
  where id = p_folder_id;

  if v_owner_id is null then
    raise exception 'Folder not found';
  end if;

  select *
  into v_access
  from public.user_has_folder_access(p_user_id, p_folder_id);

  if not coalesce(v_access.has_access, false) then
    raise exception 'Access denied';
  end if;

  if public.folder_permission_rank(v_access.permission) <
     public.folder_permission_rank(p_min_permission) then
    raise exception 'Insufficient folder permission';
  end if;

  return query select v_owner_id, v_access.permission::text, v_access.is_owner;
end;
$$;

drop function if exists public.get_folder_browser_snapshot(uuid, uuid);
create or replace function public.get_folder_browser_snapshot(
  p_user_id uuid,
  p_folder_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_folder_owner uuid;
  v_access record;
  v_folder_path jsonb := '[]'::jsonb;
  v_folder_records jsonb := '[]'::jsonb;
  v_folder_children jsonb := '[]'::jsonb;
  v_files jsonb := '[]'::jsonb;
begin
  select owner_id
  into v_folder_owner
  from public.folders
  where id = p_folder_id;

  if v_folder_owner is null then
    raise exception 'Folder not found';
  end if;

  select *
  into v_access
  from public.user_has_folder_access(p_user_id, p_folder_id);

  if not coalesce(v_access.has_access, false) then
    raise exception 'Access denied';
  end if;

  with recursive path_tree as (
    select id, owner_id, name, parent_id, created_at, 0 as depth
    from public.folders
    where id = p_folder_id

    union all

    select f.id, f.owner_id, f.name, f.parent_id, f.created_at, pt.depth + 1
    from public.folders f
    join path_tree pt on pt.parent_id = f.id
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', id,
        'owner_id', owner_id,
        'name', name,
        'parent_id', parent_id,
        'created_at', created_at
      )
      order by depth desc
    ),
    '[]'::jsonb
  )
  into v_folder_path
  from path_tree;

  select coalesce(jsonb_agg(to_jsonb(f) order by f.created_at), '[]'::jsonb)
  into v_folder_children
  from public.folders f
  where f.parent_id = p_folder_id
    and exists (
      select 1
      from public.user_has_folder_access(p_user_id, f.id) access_info
      where access_info.has_access
    );

  select coalesce(jsonb_agg(to_jsonb(fi) order by fi.created_at desc), '[]'::jsonb)
  into v_files
  from public.files fi
  where fi.folder_id = p_folder_id
    and fi.is_deleted = false;

  select coalesce(jsonb_agg(to_jsonb(f) order by f.created_at), '[]'::jsonb)
  into v_folder_records
  from public.folders f
  where f.owner_id = v_folder_owner
    and exists (
      select 1
      from public.user_has_folder_access(p_user_id, f.id) access_info
      where access_info.has_access
    );

  return jsonb_build_object(
    'current_folder_id', p_folder_id,
    'folder_path', v_folder_path,
    'all_folders', v_folder_records,
    'folders', v_folder_children,
    'files', v_files,
    'permission', v_access.permission,
    'is_owner', v_access.is_owner
  );
end;
$$;

create or replace function public.create_collaborative_folder(
  p_user_id uuid,
  p_parent_id uuid,
  p_name text
)
returns table (
  id uuid,
  owner_id uuid,
  name text,
  parent_id uuid,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_access record;
begin
  select *
  into v_access
  from public.require_folder_permission(p_user_id, p_parent_id, 'upload');

  return query
  insert into public.folders (owner_id, name, parent_id)
  values (v_access.folder_owner_id, trim(p_name), p_parent_id)
  returning folders.id, folders.owner_id, folders.name, folders.parent_id, folders.created_at;
end;
$$;

create or replace function public.rename_collaborative_folder(
  p_user_id uuid,
  p_folder_id uuid,
  p_new_name text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  perform 1
  from public.require_folder_permission(p_user_id, p_folder_id, 'full');

  update public.folders
  set name = trim(p_new_name)
  where id = p_folder_id;

  return found;
end;
$$;

create or replace function public.delete_collaborative_folder(
  p_user_id uuid,
  p_folder_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  perform 1
  from public.require_folder_permission(p_user_id, p_folder_id, 'full');

  delete from public.folders
  where id = p_folder_id;

  return found;
end;
$$;

create or replace function public.create_collaborative_file(
  p_user_id uuid,
  p_folder_id uuid,
  p_name text,
  p_extension text,
  p_size_bytes bigint,
  p_mime_type text,
  p_storage_path text
)
returns table (
  id uuid,
  owner_id uuid,
  folder_id uuid,
  name text,
  extension text,
  size_bytes bigint,
  mime_type text,
  storage_path text,
  version integer,
  is_deleted boolean,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_access record;
  v_file_id uuid;
begin
  select *
  into v_access
  from public.require_folder_permission(p_user_id, p_folder_id, 'upload');

  insert into public.files (
    owner_id,
    folder_id,
    name,
    extension,
    size_bytes,
    mime_type,
    storage_path,
    version,
    is_deleted
  ) values (
    v_access.folder_owner_id,
    p_folder_id,
    trim(p_name),
    p_extension,
    p_size_bytes,
    trim(p_mime_type),
    trim(p_storage_path),
    1,
    false
  )
  returning files.id into v_file_id;

  insert into public.events (
    user_id,
    file_id,
    action,
    target_type,
    metadata
  ) values (
    p_user_id,
    v_file_id,
    'UPLOAD',
    'file',
    jsonb_build_object(
      'size_bytes', p_size_bytes,
      'storage_path', p_storage_path,
      'mime_type', p_mime_type,
      'folder_id', p_folder_id,
      'collaborative', true
    )
  );

  return query
  select
    f.id,
    f.owner_id,
    f.folder_id,
    f.name,
    f.extension,
    f.size_bytes,
    f.mime_type,
    f.storage_path,
    f.version,
    f.is_deleted,
    f.created_at
  from public.files f
  where f.id = v_file_id;
end;
$$;

create or replace function public.rename_collaborative_file(
  p_user_id uuid,
  p_file_id uuid,
  p_new_name text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_file record;
begin
  select *
  into v_file
  from public.files
  where id = p_file_id
    and is_deleted = false;

  if v_file.id is null then
    raise exception 'File not found';
  end if;

  if v_file.owner_id <> p_user_id then
    perform 1
    from public.require_folder_permission(p_user_id, v_file.folder_id, 'full');
  end if;

  update public.files
  set name = trim(p_new_name)
  where id = p_file_id;

  insert into public.events (user_id, file_id, action, target_type, metadata)
  values (p_user_id, p_file_id, 'RENAME', 'file', jsonb_build_object('name', p_new_name));

  return found;
end;
$$;

create or replace function public.move_collaborative_file(
  p_user_id uuid,
  p_file_id uuid,
  p_target_folder_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_file record;
  v_target_owner uuid;
begin
  select *
  into v_file
  from public.files
  where id = p_file_id
    and is_deleted = false;

  if v_file.id is null then
    raise exception 'File not found';
  end if;

  if v_file.folder_id is not null and v_file.owner_id <> p_user_id then
    perform 1
    from public.require_folder_permission(p_user_id, v_file.folder_id, 'full');
  elsif v_file.owner_id <> p_user_id then
    raise exception 'Access denied';
  end if;

  if p_target_folder_id is not null then
    select owner_id
    into v_target_owner
    from public.folders
    where id = p_target_folder_id;

    if v_target_owner is null then
      raise exception 'Target folder not found';
    end if;

    if v_target_owner <> v_file.owner_id then
      raise exception 'Target folder must belong to the same owner as the file';
    end if;

    perform 1
    from public.require_folder_permission(p_user_id, p_target_folder_id, 'upload');
  elsif v_file.owner_id <> p_user_id then
    raise exception 'Shared files cannot be moved to personal root';
  end if;

  update public.files
  set folder_id = p_target_folder_id
  where id = p_file_id;

  insert into public.events (user_id, file_id, action, target_type, metadata)
  values (
    p_user_id,
    p_file_id,
    'MOVE',
    'file',
    jsonb_build_object('target_folder_id', p_target_folder_id)
  );

  return found;
end;
$$;

create or replace function public.delete_collaborative_file(
  p_user_id uuid,
  p_file_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_file record;
begin
  select *
  into v_file
  from public.files
  where id = p_file_id
    and is_deleted = false;

  if v_file.id is null then
    raise exception 'File not found';
  end if;

  if v_file.owner_id <> p_user_id then
    perform 1
    from public.require_folder_permission(p_user_id, v_file.folder_id, 'full');
  end if;

  update public.files
  set is_deleted = true
  where id = p_file_id;

  insert into public.events (user_id, file_id, action, target_type, metadata)
  values (p_user_id, p_file_id, 'DELETE', 'file', jsonb_build_object('collaborative', true));

  return found;
end;
$$;

drop policy if exists "folders_select_shared_access" on public.folders;
create policy "folders_select_shared_access"
on public.folders
for select
to authenticated
using (
  exists (
    select 1
    from public.user_has_folder_access(auth.uid(), folders.id) access_info
    where access_info.has_access
  )
);

drop policy if exists "files_select_shared_folder_access" on public.files;
create policy "files_select_shared_folder_access"
on public.files
for select
to authenticated
using (
  folder_id is not null
  and exists (
    select 1
    from public.user_has_folder_access(auth.uid(), files.folder_id) access_info
    where access_info.has_access
  )
);

create or replace function public.storage_path_has_folder_access(
  p_storage_path text,
  p_user_id uuid
)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.files f
    where f.storage_path = p_storage_path
      and f.is_deleted = false
      and f.folder_id is not null
      and exists (
        select 1
        from public.user_has_folder_access(p_user_id, f.folder_id) access_info
        where access_info.has_access
      )
  );
$$;

drop policy if exists "droply_files_select_folder_shared_access" on storage.objects;
create policy "droply_files_select_folder_shared_access"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'droply-files'
  and public.storage_path_has_folder_access(name, auth.uid())
);

grant execute on function public.user_has_folder_access(uuid, uuid) to authenticated;
grant execute on function public.folder_permission_rank(text) to authenticated;
grant execute on function public.require_folder_permission(uuid, uuid, text) to authenticated;
grant execute on function public.get_folder_browser_snapshot(uuid, uuid) to authenticated;
grant execute on function public.create_collaborative_folder(uuid, uuid, text) to authenticated;
grant execute on function public.rename_collaborative_folder(uuid, uuid, text) to authenticated;
grant execute on function public.delete_collaborative_folder(uuid, uuid) to authenticated;
grant execute on function public.create_collaborative_file(uuid, uuid, text, text, bigint, text, text) to authenticated;
grant execute on function public.rename_collaborative_file(uuid, uuid, text) to authenticated;
grant execute on function public.move_collaborative_file(uuid, uuid, uuid) to authenticated;
grant execute on function public.delete_collaborative_file(uuid, uuid) to authenticated;
grant execute on function public.storage_path_has_folder_access(text, uuid) to authenticated;
