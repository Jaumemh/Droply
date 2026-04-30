create table if not exists public.share_grants (
  id uuid primary key default gen_random_uuid(),
  share_id uuid not null references public.shares (id) on delete cascade,
  recipient_id uuid not null references public.users (id) on delete cascade,
  accepted_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint share_grants_unique_recipient unique (share_id, recipient_id)
);

create index if not exists share_grants_recipient_idx
  on public.share_grants (recipient_id, accepted_at desc);

alter table public.share_grants enable row level security;

drop policy if exists "share_grants_select_own" on public.share_grants;
create policy "share_grants_select_own"
on public.share_grants
for select
using (
  recipient_id = auth.uid()
  or exists (
    select 1
    from public.shares s
    where s.id = share_grants.share_id
      and s.owner_id = auth.uid()
  )
);

drop policy if exists "share_grants_insert_own" on public.share_grants;
create policy "share_grants_insert_own"
on public.share_grants
for insert
with check (recipient_id = auth.uid());

drop policy if exists "share_grants_delete_own" on public.share_grants;
create policy "share_grants_delete_own"
on public.share_grants
for delete
using (recipient_id = auth.uid());

create or replace function public.accept_share_token(
  p_token text,
  p_user_agent text default null,
  p_ip_client inet default null
)
returns table (
  share_id uuid,
  file_id uuid,
  file_name text,
  mime_type text,
  storage_path text,
  expires_at timestamptz,
  size_bytes bigint,
  accepted boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_share public.shares%rowtype;
  v_file public.files%rowtype;
begin
  if v_user is null then
    raise exception 'Authentication required.';
  end if;

  select *
  into v_share
  from public.shares
  where shares.token = p_token
    and shares.revoked = false
    and shares.expires_at > now();

  if not found then
    raise exception 'Link expired, revoked or invalid.';
  end if;

  select *
  into v_file
  from public.files
  where id = v_share.file_id
    and is_deleted = false;

  if not found then
    raise exception 'File unavailable.';
  end if;

  insert into public.share_grants (
    share_id,
    recipient_id
  )
  values (
    v_share.id,
    v_user
  )
  on conflict (share_id, recipient_id)
  do update set accepted_at = now();

  insert into public.events (
    user_id,
    file_id,
    share_id,
    action,
    target_type,
    ip_client,
    user_agent,
    metadata
  )
  values (
    v_user,
    v_file.id,
    v_share.id,
    'SHARE_ACCEPT'::public.event_action,
    'share',
    coalesce(p_ip_client, inet_client_addr()),
    p_user_agent,
    jsonb_build_object('token', p_token)
  );

  return query
  select
    v_share.id,
    v_file.id,
    v_file.name,
    v_file.mime_type,
    v_file.storage_path,
    v_share.expires_at,
    v_file.size_bytes,
    true;
end;
$$;

create or replace function public.get_shared_files()
returns table (
  id uuid,
  share_id uuid,
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
language sql
security definer
set search_path = public
as $$
  select distinct on (f.id)
    f.id,
    s.id as share_id,
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
  join public.shares s on s.file_id = f.id and s.revoked = false and s.expires_at > now()
  join public.share_grants g on g.share_id = s.id
  where g.recipient_id = auth.uid()
    and f.is_deleted = false
  order by f.id, g.accepted_at desc;
$$;

drop policy if exists "files_select_own" on public.files;
create policy "files_select_own"
on public.files
for select
using (
  owner_id = auth.uid()
  or exists (
    select 1
    from public.shares s
    join public.share_grants g on g.share_id = s.id
    where s.file_id = files.id
      and s.revoked = false
      and s.expires_at > now()
      and g.recipient_id = auth.uid()
  )
);
