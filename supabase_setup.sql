-- ============================================================
-- Venetucci Control — Setup completo de Supabase
-- Correr UNA vez en el SQL Editor. Es idempotente (se puede
-- correr de nuevo sin romper nada).
-- ============================================================

-- 1) Columnas que usa la app
alter table public.inspections add column if not exists form_data     jsonb;
alter table public.inspections add column if not exists berth         text;
alter table public.inspections add column if not exists berth2        text;
alter table public.inspections add column if not exists berth3        text;
alter table public.inspections add column if not exists surveyor2     text;
alter table public.inspections add column if not exists surveyor3     text;
-- id interno de la inspeccion (permite ACTUALIZAR en vez de duplicar)
alter table public.inspections add column if not exists inspection_id text;
-- quien creo el registro (necesario para el autoguardado de usuarios no-admin)
alter table public.inspections add column if not exists created_by    uuid default auth.uid();

-- 2) Clave unica: sin esto el autoguardado duplicaria filas
create unique index if not exists inspections_inspection_id_key
  on public.inspections(inspection_id);

-- 3) Normalizar el tipo (Bulker / Tanker con mayuscula)
update public.inspections set type = initcap(type) where type in ('bulker','tanker');

-- 4) Perfiles (rol por usuario)
create table if not exists public.profiles (
  id   uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'user'   -- 'user' o 'admin'
);
alter table public.profiles enable row level security;

drop policy if exists "read own profile" on public.profiles;
create policy "read own profile" on public.profiles
  for select to authenticated using (auth.uid() = id);

-- 5) Crear perfil automaticamente al alta de usuario
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, role) values (new.id, 'user')
  on conflict (id) do nothing;
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 6) Helper: es admin?
create or replace function public.is_admin()
returns boolean language sql security definer stable as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

-- 7) RLS sobre inspections
alter table public.inspections enable row level security;

-- cualquier logueado puede crear
drop policy if exists "auth insert" on public.inspections;
create policy "auth insert" on public.inspections
  for insert to authenticated with check (true);

-- solo ADMIN puede VER la base
drop policy if exists "admin select" on public.inspections;
create policy "admin select" on public.inspections
  for select to authenticated using (public.is_admin());

-- IMPORTANTE: cada uno actualiza lo que el mismo creo; los admin, todo.
-- (sin esto, el autoguardado de un surveyor no-admin seria rechazado)
drop policy if exists "admin update" on public.inspections;
drop policy if exists "update own or admin" on public.inspections;
create policy "update own or admin" on public.inspections
  for update to authenticated
  using       (created_by = auth.uid() or public.is_admin())
  with check  (created_by = auth.uid() or public.is_admin());

-- solo ADMIN borra
drop policy if exists "admin delete" on public.inspections;
create policy "admin delete" on public.inspections
  for delete to authenticated using (public.is_admin());

-- ============================================================
-- DESPUES: crear usuarios en Authentication > Users
-- ("Create new user", con "Auto Confirm User" tildado).
-- Luego marcar admins:
--
--   update public.profiles set role = 'admin'
--   where id = (select id from auth.users where email = 'TU_EMAIL_ADMIN');
--
-- Ver usuarios y roles:
--   select u.email, p.role from auth.users u
--   join public.profiles p on p.id = u.id order by u.email;
-- ============================================================
