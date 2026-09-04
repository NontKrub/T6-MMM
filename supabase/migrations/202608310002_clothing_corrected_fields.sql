alter table public.clothing_items
  add column if not exists corrected_fields text[] not null default '{}';

update public.clothing_items
set corrected_fields = array[
  'category',
  'subtype',
  'primary_color',
  'dominant_colors',
  'pattern',
  'material',
  'fit',
  'silhouette',
  'styles',
  'formality',
  'seasons',
  'weather_suitability',
  'warmth_level',
  'tags'
]
where user_corrected = true
  and cardinality(corrected_fields) = 0;
