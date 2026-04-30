create or replace function public.generate_share_token()
returns text
language sql
volatile
as $$
  select replace(gen_random_uuid()::text, '-', '') || replace(gen_random_uuid()::text, '-', '');
$$;

drop function if exists public.resolve_share_token(text, text, text, inet);
drop function if exists public.resolve_share_token(text, public.event_action, text, inet);

create or replace function public.create_share_link(
  p_file_id uuid,
  p_note text default null
)
returns public.shares
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner uuid := auth.uid();
  v_file public.files%rowtype;
  v_share public.shares%rowtype;
  v_token text;
begin
  if v_owner is null then
    raise exception 'Authentication required.';
  end if;

  select *
  into v_file
  from public.files
  where id = p_file_id
    and owner_id = v_owner
    and is_deleted = false;

  if not found then
    raise exception 'File not found or not owned by current user.';
  end if;

  for i in 1..5 loop
    v_token := public.generate_share_token();

    begin
      insert into public.shares (
        file_id,
        owner_id,
        token,
        permission,
        expires_at,
        revoked,
        note
      )
      values (
        v_file.id,
        v_owner,
        v_token,
        'read',
        now() + interval '7 days',
        false,
        p_note
      )
      returning * into v_share;

      return v_share;
    exception
      when unique_violation then
        null;
    end;
  end loop;

  raise exception 'Could not generate a unique share token.';
end;
$$;

create or replace function public.resolve_share_token(
  p_token text,
  p_action public.event_action default 'PREVIEW',
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
  is_image boolean,
  is_pdf boolean,
  revoked boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_share public.shares%rowtype;
  v_file public.files%rowtype;
begin
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
    null,
    v_file.id,
    v_share.id,
    p_action,
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
    (v_file.mime_type like 'image/%') as is_image,
    (v_file.mime_type = 'application/pdf') as is_pdf,
    v_share.revoked;
end;
$$;
