-- ── LaunchPad Lead Machine — Supabase Schema ──────────────────────────────────
-- Run this in the Supabase SQL editor (Dashboard → SQL Editor → New Query)

-- 1. User settings table (one row per user, stores their Google API key)
create table if not exists public.user_settings (
  user_id   uuid primary key references auth.users(id) on delete cascade,
  api_key   text not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 2. Row Level Security — users can only read/write their own row
alter table public.user_settings enable row level security;

create policy "Users can read own settings"
  on public.user_settings for select
  using (auth.uid() = user_id);

create policy "Users can insert own settings"
  on public.user_settings for insert
  with check (auth.uid() = user_id);

create policy "Users can update own settings"
  on public.user_settings for update
  using (auth.uid() = user_id);

create policy "Users can delete own settings"
  on public.user_settings for delete
  using (auth.uid() = user_id);

-- 3. Auto-update updated_at on row changes
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger set_user_settings_updated_at
  before update on public.user_settings
  for each row execute function public.set_updated_at();
