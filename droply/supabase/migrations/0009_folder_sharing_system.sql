-- Migración 0009: Sistema de carpetas compartidas colaborativas
-- Autor: Sistema Droply
-- Fecha: 2026-05-05
-- Descripción: Permite compartir carpetas con otros usuarios mediante invitaciones por email

-- 1. Crear tipo enum para permisos de carpetas compartidas
do $$
begin
  if not exists (
    select 1
    from pg_type
    where typname = 'folder_permission'
  ) then
    create type public.folder_permission as enum ('view', 'download', 'upload', 'full');
  end if;
end $$;

-- 2. Crear tabla de carpetas compartidas (colaboraciones activas)
create table if not exists public.folder_shares (
  id uuid primary key default gen_random_uuid(),
  folder_id uuid not null references public.folders (id) on delete cascade,
  owner_id uuid not null references public.users (id) on delete cascade,
  shared_with_user_id uuid not null references public.users (id) on delete cascade,
  permission public.folder_permission not null default 'view',
  inherit_to_subfolders boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  accepted_at timestamptz,
  
  -- Un usuario no puede compartirse una carpeta a sí mismo
  constraint folder_shares_not_self check (owner_id <> shared_with_user_id),
  
  -- No duplicar comparticiones para el mismo usuario y carpeta
  constraint folder_shares_unique_user_folder unique (folder_id, shared_with_user_id)
);

-- 3. Crear tabla de invitaciones pendientes
create table if not exists public.folder_invitations (
  id uuid primary key default gen_random_uuid(),
  folder_id uuid not null references public.folders (id) on delete cascade,
  owner_id uuid not null references public.users (id) on delete cascade,
  invitee_email text not null check (char_length(trim(invitee_email)) > 0 and invitee_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$'),
  token text not null unique check (char_length(trim(token)) >= 32),
  permission public.folder_permission not null default 'view',
  inherit_to_subfolders boolean not null default true,
  message text,
  expires_at timestamptz not null,
  accepted boolean not null default false,
  revoked boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  
  constraint folder_invitations_expiry_after_create check (expires_at > created_at)
);

-- 4. Índices para optimizar consultas
create index if not exists folder_shares_folder_idx
  on public.folder_shares (folder_id);

create index if not exists folder_shares_shared_with_idx
  on public.folder_shares (shared_with_user_id);

create index if not exists folder_shares_owner_idx
  on public.folder_shares (owner_id);

create index if not exists folder_invitations_token_idx
  on public.folder_invitations (token);

create index if not exists folder_invitations_email_idx
  on public.folder_invitations (invitee_email);

create index if not exists folder_invitations_folder_idx
  on public.folder_invitations (folder_id);

-- 5. Función para crear invitación a carpeta compartida
create or replace function public.create_folder_invitation(
  p_folder_id uuid,
  p_owner_id uuid,
  p_invitee_email text,
  p_permission text default 'view',
  p_inherit_to_subfolders boolean default true,
  p_message text default null,
  p_days_valid integer default 7
)
returns table (
  invitation_id uuid,
  token text,
  expires_at timestamptz
)
language plpgsql
security definer
as $$
declare
  v_folder_owner uuid;
  v_invitation_id uuid;
  v_token text;
  v_expires_at timestamptz;
begin
  -- Verificar que la carpeta existe y pertenece al owner
  select owner_id into v_folder_owner
  from public.folders
  where id = p_folder_id;
  
  if v_folder_owner is null then
    raise exception 'Folder not found';
  end if;
  
  if v_folder_owner <> p_owner_id then
    raise exception 'You do not own this folder';
  end if;
  
  -- Generar token único y seguro
  v_token := encode(gen_random_bytes(32), 'base64');
  v_token := replace(replace(replace(v_token, '+', ''), '/', ''), '=', '');
  
  -- Calcular fecha de expiración
  v_expires_at := timezone('utc', now()) + (p_days_valid || ' days')::interval;
  
  -- Insertar invitación
  insert into public.folder_invitations (
    folder_id,
    owner_id,
    invitee_email,
    token,
    permission,
    inherit_to_subfolders,
    message,
    expires_at
  ) values (
    p_folder_id,
    p_owner_id,
    lower(trim(p_invitee_email)),
    v_token,
    p_permission::public.folder_permission,
    p_inherit_to_subfolders,
    p_message,
    v_expires_at
  )
  returning id into v_invitation_id;
  
  return query
  select v_invitation_id, v_token, v_expires_at;
end;
$$;

-- 6. Función para aceptar invitación
create or replace function public.accept_folder_invitation(
  p_token text,
  p_user_id uuid,
  p_user_email text
)
returns table (
  folder_share_id uuid,
  folder_id uuid,
  folder_name text,
  permission text
)
language plpgsql
security definer
as $$
declare
  v_invitation record;
  v_folder_name text;
  v_share_id uuid;
begin
  -- Buscar invitación válida
  select *
  into v_invitation
  from public.folder_invitations
  where token = p_token
    and accepted = false
    and revoked = false
    and expires_at > timezone('utc', now())
    and lower(trim(invitee_email)) = lower(trim(p_user_email));
  
  if v_invitation.id is null then
    raise exception 'Invalid or expired invitation';
  end if;
  
  -- Obtener nombre de la carpeta
  select name into v_folder_name
  from public.folders
  where id = v_invitation.folder_id;
  
  -- Crear la compartición (si no existe ya)
  insert into public.folder_shares (
    folder_id,
    owner_id,
    shared_with_user_id,
    permission,
    inherit_to_subfolders,
    accepted_at
  ) values (
    v_invitation.folder_id,
    v_invitation.owner_id,
    p_user_id,
    v_invitation.permission,
    v_invitation.inherit_to_subfolders,
    timezone('utc', now())
  )
  on conflict (folder_id, shared_with_user_id) do update
  set
    permission = excluded.permission,
    inherit_to_subfolders = excluded.inherit_to_subfolders,
    accepted_at = timezone('utc', now())
  returning id into v_share_id;
  
  -- Marcar invitación como aceptada
  update public.folder_invitations
  set accepted = true
  where id = v_invitation.id;
  
  return query
  select 
    v_share_id,
    v_invitation.folder_id,
    v_folder_name,
    v_invitation.permission::text;
end;
$$;

-- 7. Función para verificar si un usuario tiene acceso a una carpeta
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
as $$
declare
  v_folder_owner uuid;
  v_share_permission text;
begin
  -- Verificar si es el dueño
  select owner_id into v_folder_owner
  from public.folders
  where id = p_folder_id;
  
  if v_folder_owner = p_user_id then
    return query select true, 'full'::text, true;
    return;
  end if;
  
  -- Verificar si tiene acceso compartido
  select fs.permission::text into v_share_permission
  from public.folder_shares fs
  where fs.folder_id = p_folder_id
    and fs.shared_with_user_id = p_user_id;
  
  if v_share_permission is not null then
    return query select true, v_share_permission, false;
    return;
  end if;
  
  -- No tiene acceso
  return query select false, null::text, false;
end;
$$;

-- 8. Función para obtener carpetas compartidas con un usuario
create or replace function public.get_shared_folders_for_user(
  p_user_id uuid
)
returns table (
  folder_id uuid,
  folder_name text,
  owner_id uuid,
  owner_email text,
  permission text,
  shared_at timestamptz,
  file_count bigint
)
language plpgsql
security definer
as $$
begin
  return query
  select
    f.id,
    f.name,
    f.owner_id,
    u.email,
    fs.permission::text,
    fs.created_at,
    count(fi.id) as file_count
  from public.folder_shares fs
  inner join public.folders f on f.id = fs.folder_id
  inner join public.users u on u.id = fs.owner_id
  left join public.files fi on fi.folder_id = f.id and fi.is_deleted = false
  where fs.shared_with_user_id = p_user_id
  group by f.id, f.name, f.owner_id, u.email, fs.permission, fs.created_at
  order by fs.created_at desc;
end;
$$;

-- 8b. Obtener detalles de una invitación por token sin depender de RLS en users/folders
create or replace function public.get_folder_invitation_by_token(
  p_token text
)
returns table (
  id uuid,
  folder_id uuid,
  owner_id uuid,
  invitee_email text,
  token text,
  permission text,
  inherit_to_subfolders boolean,
  message text,
  expires_at timestamptz,
  accepted boolean,
  revoked boolean,
  created_at timestamptz,
  folder_name text,
  owner_email text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select
    fi.id,
    fi.folder_id,
    fi.owner_id,
    fi.invitee_email,
    fi.token,
    fi.permission::text,
    fi.inherit_to_subfolders,
    fi.message,
    fi.expires_at,
    fi.accepted,
    fi.revoked,
    fi.created_at,
    f.name as folder_name,
    u.email as owner_email
  from public.folder_invitations fi
  left join public.folders f on f.id = fi.folder_id
  left join public.users u on u.id = fi.owner_id
  where fi.token = p_token;
end;
$$;

-- 9. Función para revocar acceso a carpeta compartida
create or replace function public.revoke_folder_share(
  p_folder_id uuid,
  p_owner_id uuid,
  p_shared_with_user_id uuid
)
returns boolean
language plpgsql
security definer
as $$
declare
  v_deleted boolean;
begin
  delete from public.folder_shares
  where folder_id = p_folder_id
    and owner_id = p_owner_id
    and shared_with_user_id = p_shared_with_user_id
  returning true into v_deleted;
  
  return coalesce(v_deleted, false);
end;
$$;

-- 10. RLS (Row Level Security) policies
alter table public.folder_shares enable row level security;
alter table public.folder_invitations enable row level security;

-- Política: Los usuarios pueden ver sus propias carpetas compartidas
drop policy if exists "Users can view their shared folders" on public.folder_shares;
create policy "Users can view their shared folders"
  on public.folder_shares
  for select
  using (
    auth.uid() = owner_id or auth.uid() = shared_with_user_id
  );

-- Política: Solo el dueño puede crear comparticiones
drop policy if exists "Owners can create folder shares" on public.folder_shares;
create policy "Owners can create folder shares"
  on public.folder_shares
  for insert
  with check (auth.uid() = owner_id);

-- Política: Solo el dueño puede revocar comparticiones
drop policy if exists "Owners can delete folder shares" on public.folder_shares;
create policy "Owners can delete folder shares"
  on public.folder_shares
  for delete
  using (auth.uid() = owner_id);

-- Política: Los usuarios pueden ver invitaciones dirigidas a su email
drop policy if exists "Users can view their invitations" on public.folder_invitations;
create policy "Users can view their invitations"
  on public.folder_invitations
  for select
  using (
    auth.uid() = owner_id or 
    exists (
      select 1 from auth.users
      where id = auth.uid() and email = folder_invitations.invitee_email
    )
  );

-- Política: Solo el dueño puede crear invitaciones
drop policy if exists "Owners can create invitations" on public.folder_invitations;
create policy "Owners can create invitations"
  on public.folder_invitations
  for insert
  with check (auth.uid() = owner_id);

-- Política: Solo el dueño puede revocar invitaciones
drop policy if exists "Owners can update invitations" on public.folder_invitations;
create policy "Owners can update invitations"
  on public.folder_invitations
  for update
  using (auth.uid() = owner_id);

comment on table public.folder_shares is 
  'Carpetas compartidas activas entre usuarios con permisos colaborativos';

comment on table public.folder_invitations is 
  'Invitaciones pendientes para compartir carpetas, se envían por email';

comment on function public.create_folder_invitation is 
  'Crea una invitación para compartir una carpeta con un email específico';

comment on function public.accept_folder_invitation is 
  'Acepta una invitación usando el token recibido por email';

comment on function public.user_has_folder_access is 
  'Verifica si un usuario tiene acceso a una carpeta y qué permisos tiene';

comment on function public.get_shared_folders_for_user is 
  'Obtiene todas las carpetas compartidas con un usuario específico';

comment on function public.get_folder_invitation_by_token is 
  'Obtiene los detalles públicos de una invitación de carpeta a partir del token';
