-- ============================================================
-- DataControl Solutions — Client Intake · Supabase schema
-- Run this once in: Supabase Dashboard > SQL Editor > New query > Run
-- Safe to re-run (idempotent).
-- ============================================================

-- ---------- 1. Table that stores each client's questionnaire ----------
create table if not exists public.intakes (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  answers     jsonb not null default '{}'::jsonb,   -- every answer (incl. dependents, investors, file paths)
  lang        text  not null default 'pt',
  status      text  not null default 'draft',       -- 'draft' while filling, 'submitted' at the end
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (user_id)                                  -- one intake per user (upsert target)
);

-- ---------- 2. Row Level Security: each user sees ONLY their own row ----------
alter table public.intakes enable row level security;

drop policy if exists "intake_select_own" on public.intakes;
drop policy if exists "intake_insert_own" on public.intakes;
drop policy if exists "intake_update_own" on public.intakes;

create policy "intake_select_own" on public.intakes
  for select using (auth.uid() = user_id);

create policy "intake_insert_own" on public.intakes
  for insert with check (auth.uid() = user_id);

create policy "intake_update_own" on public.intakes
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------- 3. Keep updated_at fresh ----------
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_intakes_updated on public.intakes;
create trigger trg_intakes_updated
  before update on public.intakes
  for each row execute function public.set_updated_at();

-- ---------- 4. Private Storage bucket for uploaded documents ----------
insert into storage.buckets (id, name, public)
values ('documents', 'documents', false)
on conflict (id) do nothing;

-- ---------- 5. Storage RLS: files live under a folder named after the user's id ----------
--    e.g.  <user_id>/doc_passport/1700000000_passport.pdf
drop policy if exists "docs_read_own"   on storage.objects;
drop policy if exists "docs_insert_own" on storage.objects;
drop policy if exists "docs_update_own" on storage.objects;
drop policy if exists "docs_delete_own" on storage.objects;

create policy "docs_read_own" on storage.objects
  for select using (
    bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "docs_insert_own" on storage.objects
  for insert with check (
    bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "docs_update_own" on storage.objects
  for update using (
    bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "docs_delete_own" on storage.objects
  for delete using (
    bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Done. Check: Table editor > intakes  |  Storage > documents
