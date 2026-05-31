alter table public.outfits
  add column if not exists selection_factors jsonb not null default '{}'::jsonb;
