create extension if not exists "pgcrypto";

do $$ begin
  create type public.clothing_category as enum ('hat', 'top', 'pants', 'shoes', 'accessory');
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type public.avatar_type as enum ('human', 'dog', 'cat');
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type public.color_season as enum ('spring', 'summer', 'autumn', 'winter');
exception
  when duplicate_object then null;
end $$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Wardrobly User',
  avatar_url text,
  avatar_type public.avatar_type not null default 'human',
  color_season public.color_season not null default 'spring',
  body_type text,
  brand_tier numeric(3,2) not null default 0.30 check (brand_tier >= 0 and brand_tier <= 1),
  birth_date date,
  birth_weekday int check (birth_weekday between 1 and 7),
  onboarding_complete boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.style_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null check (kind in ('style', 'occasion')),
  value text not null,
  created_at timestamptz not null default now(),
  unique (user_id, kind, value)
);

create table if not exists public.clothing_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  brand text,
  category public.clothing_category not null,
  image_path text not null,
  image_url text,
  tags text[] not null default '{}',
  dominant_colors text[] not null default '{}',
  primary_color text,
  detected_attributes jsonb not null default '{}'::jsonb,
  ai_confidence numeric(4,3) check (ai_confidence is null or (ai_confidence >= 0 and ai_confidence <= 1)),
  wear_count int not null default 0 check (wear_count >= 0),
  last_worn timestamptz,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.outfits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  style text,
  reason text,
  generation_context jsonb not null default '{}'::jsonb,
  score numeric(5,2),
  worn_on timestamptz,
  saved boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.outfit_items (
  outfit_id uuid not null references public.outfits(id) on delete cascade,
  clothing_item_id uuid not null references public.clothing_items(id) on delete cascade,
  slot public.clothing_category not null,
  position int not null default 0,
  primary key (outfit_id, clothing_item_id)
);

create table if not exists public.wear_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  outfit_id uuid references public.outfits(id) on delete set null,
  clothing_item_ids uuid[] not null default '{}',
  style text,
  colors text[] not null default '{}',
  worn_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.missing_piece_recommendations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  category public.clothing_category not null,
  title text not null,
  reason text not null,
  suggestion text not null,
  priority text not null default 'nice_to_have',
  metadata jsonb not null default '{}'::jsonb,
  dismissed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.chat_threads (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null default 'Fashion chat',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.chat_threads(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('user', 'assistant', 'system')),
  content text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists clothing_items_user_category_idx on public.clothing_items(user_id, category) where archived_at is null;
create index if not exists clothing_items_search_idx on public.clothing_items using gin (
  to_tsvector('simple', coalesce(name, '') || ' ' || coalesce(brand, '') || ' ' || array_to_string(tags, ' '))
);
create index if not exists outfits_user_created_idx on public.outfits(user_id, created_at desc);
create index if not exists wear_events_user_worn_idx on public.wear_events(user_id, worn_at desc);
create index if not exists chat_messages_thread_created_idx on public.chat_messages(thread_id, created_at);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_clothing_items_updated_at on public.clothing_items;
create trigger set_clothing_items_updated_at
before update on public.clothing_items
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'full_name', 'Wardrobly User'),
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.record_wear_event(
  p_outfit_id uuid,
  p_clothing_item_ids uuid[],
  p_style text default null
)
returns public.wear_events
language plpgsql
security invoker
as $$
declare
  inserted_event public.wear_events;
  item_colors text[];
begin
  select coalesce(array_agg(distinct primary_color) filter (where primary_color is not null), '{}')
  into item_colors
  from public.clothing_items
  where user_id = auth.uid()
    and id = any(p_clothing_item_ids)
    and archived_at is null;

  update public.clothing_items
  set wear_count = wear_count + 1,
      last_worn = now()
  where user_id = auth.uid()
    and id = any(p_clothing_item_ids)
    and archived_at is null;

  if p_outfit_id is not null then
    update public.outfits
    set worn_on = now()
    where id = p_outfit_id
      and user_id = auth.uid();
  end if;

  insert into public.wear_events (user_id, outfit_id, clothing_item_ids, style, colors)
  values (auth.uid(), p_outfit_id, p_clothing_item_ids, p_style, coalesce(item_colors, '{}'))
  returning * into inserted_event;

  return inserted_event;
end;
$$;

alter table public.profiles enable row level security;
alter table public.style_preferences enable row level security;
alter table public.clothing_items enable row level security;
alter table public.outfits enable row level security;
alter table public.outfit_items enable row level security;
alter table public.wear_events enable row level security;
alter table public.missing_piece_recommendations enable row level security;
alter table public.chat_threads enable row level security;
alter table public.chat_messages enable row level security;

drop policy if exists "profiles are user owned" on public.profiles;
create policy "profiles are user owned" on public.profiles
for all using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "style preferences are user owned" on public.style_preferences;
create policy "style preferences are user owned" on public.style_preferences
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "clothing items are user owned" on public.clothing_items;
create policy "clothing items are user owned" on public.clothing_items
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "outfits are user owned" on public.outfits;
create policy "outfits are user owned" on public.outfits
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "outfit items follow outfit ownership" on public.outfit_items;
create policy "outfit items follow outfit ownership" on public.outfit_items
for all using (
  exists (
    select 1 from public.outfits
    where outfits.id = outfit_items.outfit_id
      and outfits.user_id = auth.uid()
  )
) with check (
  exists (
    select 1 from public.outfits
    where outfits.id = outfit_items.outfit_id
      and outfits.user_id = auth.uid()
  )
);

drop policy if exists "wear events are user owned" on public.wear_events;
create policy "wear events are user owned" on public.wear_events
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "missing pieces are user owned" on public.missing_piece_recommendations;
create policy "missing pieces are user owned" on public.missing_piece_recommendations
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "chat threads are user owned" on public.chat_threads;
create policy "chat threads are user owned" on public.chat_threads
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "chat messages are user owned" on public.chat_messages;
create policy "chat messages are user owned" on public.chat_messages
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'wardrobe-images',
  'wardrobe-images',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "users can read own wardrobe images" on storage.objects;
create policy "users can read own wardrobe images" on storage.objects
for select using (
  bucket_id = 'wardrobe-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "users can upload own wardrobe images" on storage.objects;
create policy "users can upload own wardrobe images" on storage.objects
for insert with check (
  bucket_id = 'wardrobe-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "users can update own wardrobe images" on storage.objects;
create policy "users can update own wardrobe images" on storage.objects
for update using (
  bucket_id = 'wardrobe-images'
  and (storage.foldername(name))[1] = auth.uid()::text
) with check (
  bucket_id = 'wardrobe-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "users can delete own wardrobe images" on storage.objects;
create policy "users can delete own wardrobe images" on storage.objects
for delete using (
  bucket_id = 'wardrobe-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);
