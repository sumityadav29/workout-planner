-- One-time Supabase setup for workout-planner.
-- Run in the Supabase dashboard: SQL Editor -> New query -> paste -> Run.

create table public.progress (
  user_id    uuid        not null default auth.uid() references auth.users (id) on delete cascade,
  week       text        not null,                          -- ISO week, e.g. '2026-W29'
  day        smallint    not null check (day between 0 and 6), -- 0 = Monday
  done       boolean[]   not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, week, day)
);

alter table public.progress enable row level security;

create policy "select own rows" on public.progress for select using (auth.uid() = user_id);
create policy "insert own rows" on public.progress for insert with check (auth.uid() = user_id);
create policy "update own rows" on public.progress for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "delete own rows" on public.progress for delete using (auth.uid() = user_id);
