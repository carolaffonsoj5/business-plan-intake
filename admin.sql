-- ============================================================
-- DataControl Solutions — ADMIN access (run AFTER schema.sql)
-- Lets your team view every client's answers + download documents.
-- Run in: Supabase Dashboard > SQL Editor > New query > Run
-- ============================================================

-- 1) Store the ready-made report (HTML) of each submission
alter table public.intakes add column if not exists summary_html text;

-- 2) List of admin emails (your team)
create table if not exists public.admins ( email text primary key );

-- >>> EDIT THIS LINE: put YOUR admin login email here <<<
insert into public.admins (email) values ('carol.affonsoj5@yahoo.com')
on conflict (email) do nothing;

alter table public.admins enable row level security;
drop policy if exists "admins_self" on public.admins;
create policy "admins_self" on public.admins
  for select using ( (auth.jwt() ->> 'email') = email );

-- 3) Helper: is the current user an admin?
create or replace function public.is_admin() returns boolean
  language sql stable as $$
  select exists (
    select 1 from public.admins a where a.email = (auth.jwt() ->> 'email')
  );
$$;

-- 4) Admins can read ALL intakes (clients still see only their own)
drop policy if exists "intake_select_admin" on public.intakes;
create policy "intake_select_admin" on public.intakes
  for select using ( public.is_admin() );

-- 5) Admins can download any client's documents
drop policy if exists "docs_read_admin" on storage.objects;
create policy "docs_read_admin" on storage.objects
  for select using ( bucket_id = 'documents' and public.is_admin() );

-- After running: make sure an auth user exists with that admin email
-- (sign up through the form once, OR Authentication > Users > Add user).
