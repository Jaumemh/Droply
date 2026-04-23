create extension if not exists "pgcrypto";

do $$
begin
  if not exists (
    select 1
    from pg_type
    where typname = 'share_permission'
  ) then
    create type public.share_permission as enum ('read');
  end if;

  if not exists (
    select 1
    from pg_type
    where typname = 'event_action'
  ) then
    create type public.event_action as enum (
      'UPLOAD',
      'DOWNLOAD',
      'PREVIEW',
      'DELETE',
      'SHARE_CREATE',
      'SHARE_REVOKE'
    );
  end if;
end $$;

create table if not exists public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null unique,
  display_name text,
  role text not null default 'free' check (role in ('free', 'admin')),
  quota_mb integer not null default 1024 check (quota_mb > 0),
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.folders (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.users (id) on delete cascade,
  name text not null check (char_length(trim(name)) > 0),
  parent_id uuid references public.folders (id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  constraint folders_unique_name_per_parent unique (owner_id, parent_id, name)
);

create table if not exists public.files (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.users (id) on delete cascade,
  folder_id uuid references public.folders (id) on delete set null,
  name text not null check (char_length(trim(name)) > 0),
  extension text,
  size_bytes bigint not null check (size_bytes >= 0 and size_bytes <= 52428800),
  mime_type text not null check (char_length(trim(mime_type)) > 0),
  storage_path text not null unique check (char_length(trim(storage_path)) > 0),
  version integer not null default 1 check (version >= 1),
  is_deleted boolean not null default false,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.shares (
  id uuid primary key default gen_random_uuid(),
  file_id uuid not null references public.files (id) on delete cascade,
  owner_id uuid not null references public.users (id) on delete cascade,
  token text not null unique check (char_length(trim(token)) >= 16),
  permission public.share_permission not null default 'read',
  expires_at timestamptz not null,
  revoked boolean not null default false,
  note text,
  created_at timestamptz not null default timezone('utc', now()),
  constraint shares_expiry_after_create check (expires_at > created_at)
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users (id) on delete set null,
  file_id uuid references public.files (id) on delete set null,
  share_id uuid references public.shares (id) on delete set null,
  action public.event_action not null,
  target_type text,
  ip_client inet,
  user_agent text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists folders_owner_parent_idx
  on public.folders (owner_id, parent_id);

create index if not exists files_owner_folder_created_idx
  on public.files (owner_id, folder_id, created_at desc);

create index if not exists shares_owner_file_idx
  on public.shares (owner_id, file_id);

create index if not exists shares_token_idx
  on public.shares (token);

create index if not exists events_user_created_idx
  on public.events (user_id, created_at desc);

create index if not exists events_file_created_idx
  on public.events (file_id, created_at desc);

create or replace function public.validate_folder_parent_owner()
returns trigger
language plpgsql
as $$
declare
  parent_owner uuid;
begin
  if new.parent_id is null then
    return new;
  end if;

  select owner_id
  into parent_owner
  from public.folders
  where id = new.parent_id;

  if parent_owner is null then
    raise exception 'Parent folder does not exist.';
  end if;

  if parent_owner <> new.owner_id then
    raise exception 'Parent folder must belong to the same owner.';
  end if;

  return new;
end;
$$;

create or replace function public.validate_file_folder_owner()
returns trigger
language plpgsql
as $$
declare
  folder_owner uuid;
begin
  if new.folder_id is null then
    return new;
  end if;

  select owner_id
  into folder_owner
  from public.folders
  where id = new.folder_id;

  if folder_owner is null then
    raise exception 'Folder does not exist.';
  end if;

  if folder_owner <> new.owner_id then
    raise exception 'File folder must belong to the same owner.';
  end if;

  return new;
end;
$$;

create or replace function public.validate_share_file_owner()
returns trigger
language plpgsql
as $$
declare
  file_owner uuid;
begin
  select owner_id
  into file_owner
  from public.files
  where id = new.file_id;

  if file_owner is null then
    raise exception 'File does not exist.';
  end if;

  if file_owner <> new.owner_id then
    raise exception 'Share file must belong to the same owner.';
  end if;

  return new;
end;
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, email)
  values (new.id, coalesce(new.email, ''))
  on conflict (id) do update
  set email = excluded.email;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

drop trigger if exists validate_folder_parent_owner_trigger on public.folders;
create trigger validate_folder_parent_owner_trigger
before insert or update on public.folders
for each row execute procedure public.validate_folder_parent_owner();

drop trigger if exists validate_file_folder_owner_trigger on public.files;
create trigger validate_file_folder_owner_trigger
before insert or update on public.files
for each row execute procedure public.validate_file_folder_owner();

drop trigger if exists validate_share_file_owner_trigger on public.shares;
create trigger validate_share_file_owner_trigger
before insert or update on public.shares
for each row execute procedure public.validate_share_file_owner();

alter table public.users enable row level security;
alter table public.folders enable row level security;
alter table public.files enable row level security;
alter table public.shares enable row level security;
alter table public.events enable row level security;

drop policy if exists "users_select_own_profile" on public.users;
create policy "users_select_own_profile"
on public.users
for select
to authenticated
using (id = auth.uid());

drop policy if exists "users_update_own_profile" on public.users;
create policy "users_update_own_profile"
on public.users
for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "folders_select_own" on public.folders;
create policy "folders_select_own"
on public.folders
for select
to authenticated
using (owner_id = auth.uid());

drop policy if exists "folders_insert_own" on public.folders;
create policy "folders_insert_own"
on public.folders
for insert
to authenticated
with check (owner_id = auth.uid());

drop policy if exists "folders_update_own" on public.folders;
create policy "folders_update_own"
on public.folders
for update
to authenticated
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

drop policy if exists "folders_delete_own" on public.folders;
create policy "folders_delete_own"
on public.folders
for delete
to authenticated
using (owner_id = auth.uid());

drop policy if exists "files_select_own" on public.files;
create policy "files_select_own"
on public.files
for select
to authenticated
using (owner_id = auth.uid());

drop policy if exists "files_insert_own" on public.files;
create policy "files_insert_own"
on public.files
for insert
to authenticated
with check (owner_id = auth.uid());

drop policy if exists "files_update_own" on public.files;
create policy "files_update_own"
on public.files
for update
to authenticated
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

drop policy if exists "files_delete_own" on public.files;
create policy "files_delete_own"
on public.files
for delete
to authenticated
using (owner_id = auth.uid());

drop policy if exists "shares_select_own" on public.shares;
create policy "shares_select_own"
on public.shares
for select
to authenticated
using (owner_id = auth.uid());

drop policy if exists "shares_insert_own" on public.shares;
create policy "shares_insert_own"
on public.shares
for insert
to authenticated
with check (owner_id = auth.uid());

drop policy if exists "shares_update_own" on public.shares;
create policy "shares_update_own"
on public.shares
for update
to authenticated
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

drop policy if exists "shares_delete_own" on public.shares;
create policy "shares_delete_own"
on public.shares
for delete
to authenticated
using (owner_id = auth.uid());

drop policy if exists "events_select_own" on public.events;
create policy "events_select_own"
on public.events
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "events_insert_own" on public.events;
create policy "events_insert_own"
on public.events
for insert
to authenticated
with check (user_id = auth.uid());

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'droply-files',
  'droply-files',
  false,
  52428800,
  array[
    'image/png',
    'image/jpeg',
    'image/webp',
    'image/gif',
    'image/svg+xml',
    'application/pdf',
    'text/plain',
    'text/markdown',
    'text/csv',
    'application/json',
    'application/xml',
    'text/xml',
    'text/html',
    'text/css',
    'application/javascript',
    'application/zip',
    'application/x-zip-compressed',
    'application/x-rar-compressed',
    'application/x-7z-compressed',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'audio/mpeg',
    'audio/wav',
    'audio/mp4',
    'video/mp4',
    'video/quicktime'
  ]
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "droply_files_select_own" on storage.objects;
create policy "droply_files_select_own"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'droply-files'
  and owner = auth.uid()
  and name like auth.uid()::text || '/%'
);

drop policy if exists "droply_files_insert_own" on storage.objects;
create policy "droply_files_insert_own"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'droply-files'
  and owner = auth.uid()
  and name like auth.uid()::text || '/%'
);

drop policy if exists "droply_files_update_own" on storage.objects;
create policy "droply_files_update_own"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'droply-files'
  and owner = auth.uid()
  and name like auth.uid()::text || '/%'
)
with check (
  bucket_id = 'droply-files'
  and owner = auth.uid()
  and name like auth.uid()::text || '/%'
);

drop policy if exists "droply_files_delete_own" on storage.objects;
create policy "droply_files_delete_own"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'droply-files'
  and owner = auth.uid()
  and name like auth.uid()::text || '/%'
);
