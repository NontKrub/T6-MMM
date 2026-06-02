create table if not exists public.outfit_preference_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  outfit_id uuid references public.outfits(id) on delete set null,
  style text,
  clothing_item_ids uuid[] not null default '{}',
  tags text[] not null default '{}',
  colors text[] not null default '{}',
  selection_factors text[] not null default '{}',
  score numeric(5,2),
  source text not null default 'generated',
  created_at timestamptz not null default now()
);

create index if not exists outfit_preference_events_user_created_idx
  on public.outfit_preference_events(user_id, created_at desc);

alter table public.outfit_preference_events enable row level security;

drop policy if exists "outfit preference events are user owned" on public.outfit_preference_events;
create policy "outfit preference events are user owned" on public.outfit_preference_events
for all using (user_id = auth.uid()) with check (user_id = auth.uid());
