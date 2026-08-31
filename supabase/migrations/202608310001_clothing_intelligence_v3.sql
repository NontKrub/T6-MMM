-- Core Intelligence V3 keeps legacy detected_attributes for older clients while
-- giving new analysis fields stable, queryable columns.

alter type public.clothing_category add value if not exists 'outerwear';
alter type public.clothing_category add value if not exists 'dress';
alter type public.clothing_category add value if not exists 'bag';
alter type public.clothing_category add value if not exists 'unknown';

alter table public.clothing_items
  add column if not exists subtype text,
  add column if not exists pattern text,
  add column if not exists material text,
  add column if not exists fit text,
  add column if not exists silhouette text,
  add column if not exists styles jsonb not null default '[]'::jsonb,
  add column if not exists formality text,
  add column if not exists seasons jsonb not null default '[]'::jsonb,
  add column if not exists weather_suitability jsonb not null default '[]'::jsonb,
  add column if not exists warmth_level numeric(3,2),
  add column if not exists analysis_confidence numeric(4,3),
  add column if not exists analysis_source text not null default 'unknown',
  add column if not exists analysis_status text not null default 'pending',
  add column if not exists analysis_version text not null default 'legacy',
  add column if not exists user_corrected boolean not null default false,
  add column if not exists analyzed_at timestamptz;

alter table public.clothing_items
  drop constraint if exists clothing_items_warmth_level_check,
  add constraint clothing_items_warmth_level_check
    check (warmth_level is null or (warmth_level >= 0 and warmth_level <= 1)),
  drop constraint if exists clothing_items_analysis_confidence_check,
  add constraint clothing_items_analysis_confidence_check
    check (
      analysis_confidence is null or
      (analysis_confidence >= 0 and analysis_confidence <= 1)
    ),
  drop constraint if exists clothing_items_analysis_status_check,
  add constraint clothing_items_analysis_status_check
    check (analysis_status in ('pending', 'analyzing', 'complete', 'partial', 'failed')),
  drop constraint if exists clothing_items_analysis_source_check,
  add constraint clothing_items_analysis_source_check
    check (analysis_source in ('localVision', 'serverAI', 'merged', 'manual', 'unknown'));

create index if not exists clothing_items_analysis_status_idx
  on public.clothing_items(user_id, analysis_status)
  where archived_at is null;

create table if not exists public.recommendation_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  outfit_id uuid references public.outfits(id) on delete set null,
  event_type text not null check (
    event_type in (
      'generated', 'shown', 'accepted', 'skipped', 'regenerated',
      'liked', 'disliked', 'worn'
    )
  ),
  clothing_item_ids uuid[] not null default '{}',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists recommendation_events_user_created_idx
  on public.recommendation_events(user_id, created_at desc);

alter table public.recommendation_events enable row level security;

drop policy if exists "recommendation events are user owned"
  on public.recommendation_events;
create policy "recommendation events are user owned"
  on public.recommendation_events
  for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
