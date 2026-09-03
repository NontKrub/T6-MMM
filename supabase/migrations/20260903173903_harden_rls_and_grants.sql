-- Keep the client-facing API limited to authenticated users. Each policy is
-- operation-specific so SELECT, INSERT, UPDATE, and DELETE are auditable.
alter table public.profiles enable row level security;
alter table public.style_preferences enable row level security;
alter table public.clothing_items enable row level security;
alter table public.outfits enable row level security;
alter table public.outfit_items enable row level security;
alter table public.wear_events enable row level security;
alter table public.missing_piece_recommendations enable row level security;
alter table public.chat_threads enable row level security;
alter table public.chat_messages enable row level security;
alter table public.outfit_preference_events enable row level security;
alter table public.recommendation_events enable row level security;

drop policy if exists "profiles are user owned" on public.profiles;
drop policy if exists mmm_profiles_select_own on public.profiles;
drop policy if exists mmm_profiles_insert_own on public.profiles;
drop policy if exists mmm_profiles_update_own on public.profiles;
drop policy if exists mmm_profiles_delete_own on public.profiles;
create policy mmm_profiles_select_own on public.profiles
for select to authenticated
using ((select auth.uid()) is not null and id = (select auth.uid()));
create policy mmm_profiles_insert_own on public.profiles
for insert to authenticated
with check ((select auth.uid()) is not null and id = (select auth.uid()));
create policy mmm_profiles_update_own on public.profiles
for update to authenticated
using ((select auth.uid()) is not null and id = (select auth.uid()))
with check ((select auth.uid()) is not null and id = (select auth.uid()));
create policy mmm_profiles_delete_own on public.profiles
for delete to authenticated
using ((select auth.uid()) is not null and id = (select auth.uid()));

drop policy if exists "style preferences are user owned" on public.style_preferences;
drop policy if exists mmm_style_preferences_select_own on public.style_preferences;
drop policy if exists mmm_style_preferences_insert_own on public.style_preferences;
drop policy if exists mmm_style_preferences_update_own on public.style_preferences;
drop policy if exists mmm_style_preferences_delete_own on public.style_preferences;
create policy mmm_style_preferences_select_own on public.style_preferences
for select to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()));
create policy mmm_style_preferences_insert_own on public.style_preferences
for insert to authenticated
with check ((select auth.uid()) is not null and user_id = (select auth.uid()));
create policy mmm_style_preferences_update_own on public.style_preferences
for update to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()))
with check ((select auth.uid()) is not null and user_id = (select auth.uid()));
create policy mmm_style_preferences_delete_own on public.style_preferences
for delete to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()));

drop policy if exists "clothing items are user owned" on public.clothing_items;
drop policy if exists mmm_clothing_items_select_own on public.clothing_items;
drop policy if exists mmm_clothing_items_insert_own on public.clothing_items;
drop policy if exists mmm_clothing_items_update_own on public.clothing_items;
drop policy if exists mmm_clothing_items_delete_own on public.clothing_items;
create policy mmm_clothing_items_select_own on public.clothing_items
for select to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()));
create policy mmm_clothing_items_insert_own on public.clothing_items
for insert to authenticated
with check ((select auth.uid()) is not null and user_id = (select auth.uid()));
create policy mmm_clothing_items_update_own on public.clothing_items
for update to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()))
with check ((select auth.uid()) is not null and user_id = (select auth.uid()));
create policy mmm_clothing_items_delete_own on public.clothing_items
for delete to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()));

drop policy if exists "outfits are user owned" on public.outfits;
drop policy if exists mmm_outfits_select_own on public.outfits;
drop policy if exists mmm_outfits_insert_own on public.outfits;
drop policy if exists mmm_outfits_update_own on public.outfits;
drop policy if exists mmm_outfits_delete_own on public.outfits;
create policy mmm_outfits_select_own on public.outfits
for select to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()));
create policy mmm_outfits_insert_own on public.outfits
for insert to authenticated
with check ((select auth.uid()) is not null and user_id = (select auth.uid()));
create policy mmm_outfits_update_own on public.outfits
for update to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()))
with check ((select auth.uid()) is not null and user_id = (select auth.uid()));
create policy mmm_outfits_delete_own on public.outfits
for delete to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()));

drop policy if exists "outfit items follow outfit ownership" on public.outfit_items;
drop policy if exists mmm_outfit_items_select_own on public.outfit_items;
drop policy if exists mmm_outfit_items_insert_own on public.outfit_items;
drop policy if exists mmm_outfit_items_update_own on public.outfit_items;
drop policy if exists mmm_outfit_items_delete_own on public.outfit_items;
create policy mmm_outfit_items_select_own on public.outfit_items
for select to authenticated
using (
  (select auth.uid()) is not null
  and exists (
    select 1
    from public.outfits as outfit
    join public.clothing_items as item on item.id = outfit_items.clothing_item_id
    where outfit.id = outfit_items.outfit_id
      and outfit.user_id = (select auth.uid())
      and item.user_id = (select auth.uid())
  )
);
create policy mmm_outfit_items_insert_own on public.outfit_items
for insert to authenticated
with check (
  (select auth.uid()) is not null
  and exists (
    select 1 from public.outfits as outfit
    where outfit.id = outfit_items.outfit_id
      and outfit.user_id = (select auth.uid())
  )
  and exists (
    select 1 from public.clothing_items as item
    where item.id = outfit_items.clothing_item_id
      and item.user_id = (select auth.uid())
      and item.archived_at is null
  )
);
create policy mmm_outfit_items_update_own on public.outfit_items
for update to authenticated
using (
  (select auth.uid()) is not null
  and exists (
    select 1
    from public.outfits as outfit
    join public.clothing_items as item on item.id = outfit_items.clothing_item_id
    where outfit.id = outfit_items.outfit_id
      and outfit.user_id = (select auth.uid())
      and item.user_id = (select auth.uid())
  )
)
with check (
  (select auth.uid()) is not null
  and exists (
    select 1 from public.outfits as outfit
    where outfit.id = outfit_items.outfit_id
      and outfit.user_id = (select auth.uid())
  )
  and exists (
    select 1 from public.clothing_items as item
    where item.id = outfit_items.clothing_item_id
      and item.user_id = (select auth.uid())
      and item.archived_at is null
  )
);
create policy mmm_outfit_items_delete_own on public.outfit_items
for delete to authenticated
using (
  (select auth.uid()) is not null
  and exists (
    select 1
    from public.outfits as outfit
    join public.clothing_items as item on item.id = outfit_items.clothing_item_id
    where outfit.id = outfit_items.outfit_id
      and outfit.user_id = (select auth.uid())
      and item.user_id = (select auth.uid())
  )
);

drop policy if exists "wear events are user owned" on public.wear_events;
drop policy if exists mmm_wear_events_select_own on public.wear_events;
drop policy if exists mmm_wear_events_insert_own on public.wear_events;
drop policy if exists mmm_wear_events_update_own on public.wear_events;
drop policy if exists mmm_wear_events_delete_own on public.wear_events;
create policy mmm_wear_events_select_own on public.wear_events
for select to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()));
create policy mmm_wear_events_insert_own on public.wear_events
for insert to authenticated
with check (
  (select auth.uid()) is not null
  and user_id = (select auth.uid())
  and (
    outfit_id is null
    or exists (
      select 1 from public.outfits as outfit
      where outfit.id = wear_events.outfit_id
        and outfit.user_id = (select auth.uid())
    )
  )
  and not exists (
    select 1
    from unnest(wear_events.clothing_item_ids) as reference(item_id)
    where not exists (
      select 1 from public.clothing_items as item
      where item.id = reference.item_id
        and item.user_id = (select auth.uid())
    )
  )
);
create policy mmm_wear_events_update_own on public.wear_events
for update to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()))
with check (
  (select auth.uid()) is not null
  and user_id = (select auth.uid())
  and (
    outfit_id is null
    or exists (
      select 1 from public.outfits as outfit
      where outfit.id = wear_events.outfit_id
        and outfit.user_id = (select auth.uid())
    )
  )
  and not exists (
    select 1
    from unnest(wear_events.clothing_item_ids) as reference(item_id)
    where not exists (
      select 1 from public.clothing_items as item
      where item.id = reference.item_id
        and item.user_id = (select auth.uid())
    )
  )
);
create policy mmm_wear_events_delete_own on public.wear_events
for delete to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()));

drop policy if exists "missing pieces are user owned" on public.missing_piece_recommendations;
drop policy if exists mmm_missing_pieces_select_own on public.missing_piece_recommendations;
drop policy if exists mmm_missing_pieces_insert_own on public.missing_piece_recommendations;
drop policy if exists mmm_missing_pieces_update_own on public.missing_piece_recommendations;
drop policy if exists mmm_missing_pieces_delete_own on public.missing_piece_recommendations;
create policy mmm_missing_pieces_select_own on public.missing_piece_recommendations
for select to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()));
create policy mmm_missing_pieces_insert_own on public.missing_piece_recommendations
for insert to authenticated
with check ((select auth.uid()) is not null and user_id = (select auth.uid()));
create policy mmm_missing_pieces_update_own on public.missing_piece_recommendations
for update to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()))
with check ((select auth.uid()) is not null and user_id = (select auth.uid()));
create policy mmm_missing_pieces_delete_own on public.missing_piece_recommendations
for delete to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()));

drop policy if exists "chat threads are user owned" on public.chat_threads;
drop policy if exists mmm_chat_threads_select_own on public.chat_threads;
drop policy if exists mmm_chat_threads_insert_own on public.chat_threads;
drop policy if exists mmm_chat_threads_update_own on public.chat_threads;
drop policy if exists mmm_chat_threads_delete_own on public.chat_threads;
create policy mmm_chat_threads_select_own on public.chat_threads
for select to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()));
create policy mmm_chat_threads_insert_own on public.chat_threads
for insert to authenticated
with check ((select auth.uid()) is not null and user_id = (select auth.uid()));
create policy mmm_chat_threads_update_own on public.chat_threads
for update to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()))
with check ((select auth.uid()) is not null and user_id = (select auth.uid()));
create policy mmm_chat_threads_delete_own on public.chat_threads
for delete to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()));

drop policy if exists "chat messages are user owned" on public.chat_messages;
drop policy if exists mmm_chat_messages_select_own on public.chat_messages;
drop policy if exists mmm_chat_messages_insert_own on public.chat_messages;
drop policy if exists mmm_chat_messages_update_own on public.chat_messages;
drop policy if exists mmm_chat_messages_delete_own on public.chat_messages;
create policy mmm_chat_messages_select_own on public.chat_messages
for select to authenticated
using (
  (select auth.uid()) is not null
  and user_id = (select auth.uid())
  and exists (
    select 1 from public.chat_threads as thread
    where thread.id = chat_messages.thread_id
      and thread.user_id = (select auth.uid())
  )
);
create policy mmm_chat_messages_insert_own on public.chat_messages
for insert to authenticated
with check (
  (select auth.uid()) is not null
  and user_id = (select auth.uid())
  and exists (
    select 1 from public.chat_threads as thread
    where thread.id = chat_messages.thread_id
      and thread.user_id = (select auth.uid())
  )
);
create policy mmm_chat_messages_update_own on public.chat_messages
for update to authenticated
using (
  (select auth.uid()) is not null
  and user_id = (select auth.uid())
  and exists (
    select 1 from public.chat_threads as thread
    where thread.id = chat_messages.thread_id
      and thread.user_id = (select auth.uid())
  )
)
with check (
  (select auth.uid()) is not null
  and user_id = (select auth.uid())
  and exists (
    select 1 from public.chat_threads as thread
    where thread.id = chat_messages.thread_id
      and thread.user_id = (select auth.uid())
  )
);
create policy mmm_chat_messages_delete_own on public.chat_messages
for delete to authenticated
using (
  (select auth.uid()) is not null
  and user_id = (select auth.uid())
  and exists (
    select 1 from public.chat_threads as thread
    where thread.id = chat_messages.thread_id
      and thread.user_id = (select auth.uid())
  )
);

drop policy if exists "outfit preference events are user owned" on public.outfit_preference_events;
drop policy if exists mmm_outfit_preference_events_select_own on public.outfit_preference_events;
drop policy if exists mmm_outfit_preference_events_insert_own on public.outfit_preference_events;
drop policy if exists mmm_outfit_preference_events_update_own on public.outfit_preference_events;
drop policy if exists mmm_outfit_preference_events_delete_own on public.outfit_preference_events;
create policy mmm_outfit_preference_events_select_own on public.outfit_preference_events
for select to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()));
create policy mmm_outfit_preference_events_insert_own on public.outfit_preference_events
for insert to authenticated
with check (
  (select auth.uid()) is not null
  and user_id = (select auth.uid())
  and (
    outfit_id is null
    or exists (
      select 1 from public.outfits as outfit
      where outfit.id = outfit_preference_events.outfit_id
        and outfit.user_id = (select auth.uid())
    )
  )
  and not exists (
    select 1
    from unnest(outfit_preference_events.clothing_item_ids) as reference(item_id)
    where not exists (
      select 1 from public.clothing_items as item
      where item.id = reference.item_id
        and item.user_id = (select auth.uid())
    )
  )
);
create policy mmm_outfit_preference_events_update_own on public.outfit_preference_events
for update to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()))
with check (
  (select auth.uid()) is not null
  and user_id = (select auth.uid())
  and (
    outfit_id is null
    or exists (
      select 1 from public.outfits as outfit
      where outfit.id = outfit_preference_events.outfit_id
        and outfit.user_id = (select auth.uid())
    )
  )
  and not exists (
    select 1
    from unnest(outfit_preference_events.clothing_item_ids) as reference(item_id)
    where not exists (
      select 1 from public.clothing_items as item
      where item.id = reference.item_id
        and item.user_id = (select auth.uid())
    )
  )
);
create policy mmm_outfit_preference_events_delete_own on public.outfit_preference_events
for delete to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()));

drop policy if exists "recommendation events are user owned" on public.recommendation_events;
drop policy if exists mmm_recommendation_events_select_own on public.recommendation_events;
drop policy if exists mmm_recommendation_events_insert_own on public.recommendation_events;
drop policy if exists mmm_recommendation_events_update_own on public.recommendation_events;
drop policy if exists mmm_recommendation_events_delete_own on public.recommendation_events;
create policy mmm_recommendation_events_select_own on public.recommendation_events
for select to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()));
create policy mmm_recommendation_events_insert_own on public.recommendation_events
for insert to authenticated
with check (
  (select auth.uid()) is not null
  and user_id = (select auth.uid())
  and (
    outfit_id is null
    or exists (
      select 1 from public.outfits as outfit
      where outfit.id = recommendation_events.outfit_id
        and outfit.user_id = (select auth.uid())
    )
  )
  and not exists (
    select 1
    from unnest(recommendation_events.clothing_item_ids) as reference(item_id)
    where not exists (
      select 1 from public.clothing_items as item
      where item.id = reference.item_id
        and item.user_id = (select auth.uid())
    )
  )
);
create policy mmm_recommendation_events_update_own on public.recommendation_events
for update to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()))
with check (
  (select auth.uid()) is not null
  and user_id = (select auth.uid())
  and (
    outfit_id is null
    or exists (
      select 1 from public.outfits as outfit
      where outfit.id = recommendation_events.outfit_id
        and outfit.user_id = (select auth.uid())
    )
  )
  and not exists (
    select 1
    from unnest(recommendation_events.clothing_item_ids) as reference(item_id)
    where not exists (
      select 1 from public.clothing_items as item
      where item.id = reference.item_id
        and item.user_id = (select auth.uid())
    )
  )
);
create policy mmm_recommendation_events_delete_own on public.recommendation_events
for delete to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()));

create index if not exists style_preferences_user_id_idx
  on public.style_preferences(user_id);
create index if not exists missing_piece_recommendations_user_id_idx
  on public.missing_piece_recommendations(user_id);
create index if not exists chat_threads_user_id_idx
  on public.chat_threads(user_id);
create index if not exists chat_messages_user_id_idx
  on public.chat_messages(user_id);
create index if not exists chat_messages_thread_id_idx
  on public.chat_messages(thread_id);
create index if not exists outfit_items_clothing_item_id_idx
  on public.outfit_items(clothing_item_id);

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'profiles',
    'style_preferences',
    'clothing_items',
    'outfits',
    'outfit_items',
    'wear_events',
    'missing_piece_recommendations',
    'chat_threads',
    'chat_messages',
    'outfit_preference_events',
    'recommendation_events'
  ] loop
    execute format(
      'revoke all on table public.%I from public, anon, authenticated; grant select, insert, update, delete on table public.%I to authenticated; grant all on table public.%I to service_role',
      table_name,
      table_name,
      table_name
    );
  end loop;
end;
$$;

create or replace function public.record_wear_event(
  p_outfit_id uuid,
  p_clothing_item_ids uuid[],
  p_style text default null
)
returns public.wear_events
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  inserted_event public.wear_events;
  item_colors text[];
  item_count bigint;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if p_clothing_item_ids is null or cardinality(p_clothing_item_ids) = 0 then
    raise exception 'At least one clothing item is required';
  end if;
  if exists (
    select 1 from unnest(p_clothing_item_ids) as input(item_id)
    where input.item_id is null
  ) then
    raise exception 'Clothing item IDs cannot be null';
  end if;

  select count(*) into item_count
  from (
    select distinct input.item_id
    from unnest(p_clothing_item_ids) as input(item_id)
  ) as distinct_items;
  if item_count <> cardinality(p_clothing_item_ids) then
    raise exception 'Duplicate clothing item IDs are not allowed';
  end if;

  select count(*) into item_count
  from public.clothing_items as item
  where item.id = any(p_clothing_item_ids)
    and item.user_id = v_user_id
    and item.archived_at is null;
  if item_count <> cardinality(p_clothing_item_ids) then
    raise exception 'Every clothing item must belong to the current user and be active';
  end if;

  if p_outfit_id is not null and not exists (
    select 1 from public.outfits as outfit
    where outfit.id = p_outfit_id
      and outfit.user_id = v_user_id
  ) then
    raise exception 'Outfit must belong to the current user';
  end if;

  select coalesce(
    array_agg(distinct item.primary_color)
      filter (where item.primary_color is not null),
    '{}'
  )
  into item_colors
  from public.clothing_items as item
  where item.user_id = v_user_id
    and item.id = any(p_clothing_item_ids)
    and item.archived_at is null;

  update public.clothing_items
  set wear_count = wear_count + 1,
      last_worn = now()
  where user_id = v_user_id
    and id = any(p_clothing_item_ids)
    and archived_at is null;

  if p_outfit_id is not null then
    update public.outfits
    set worn_on = now()
    where id = p_outfit_id
      and user_id = v_user_id;
  end if;

  insert into public.wear_events (user_id, outfit_id, clothing_item_ids, style, colors)
  values (v_user_id, p_outfit_id, p_clothing_item_ids, p_style, coalesce(item_colors, '{}'))
  returning * into inserted_event;

  return inserted_event;
end;
$$;

revoke all on function public.record_wear_event(uuid, uuid[], text)
  from public, anon, authenticated;
grant execute on function public.record_wear_event(uuid, uuid[], text)
  to authenticated;

-- Storage ownership is checked both by the authenticated UID folder and by
-- Storage's non-deprecated owner_id metadata.
drop policy if exists "users can read own wardrobe images" on storage.objects;
drop policy if exists "users can upload own wardrobe images" on storage.objects;
drop policy if exists "users can update own wardrobe images" on storage.objects;
drop policy if exists "users can delete own wardrobe images" on storage.objects;
drop policy if exists mmm_wardrobe_images_select_own on storage.objects;
drop policy if exists mmm_wardrobe_images_insert_own on storage.objects;
drop policy if exists mmm_wardrobe_images_update_own on storage.objects;
drop policy if exists mmm_wardrobe_images_delete_own on storage.objects;
create policy mmm_wardrobe_images_select_own on storage.objects
for select to authenticated
using (
  bucket_id = 'wardrobe-images'
  and owner_id = (select auth.uid()::text)
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
create policy mmm_wardrobe_images_insert_own on storage.objects
for insert to authenticated
with check (
  bucket_id = 'wardrobe-images'
  and owner_id = (select auth.uid()::text)
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
create policy mmm_wardrobe_images_update_own on storage.objects
for update to authenticated
using (
  bucket_id = 'wardrobe-images'
  and owner_id = (select auth.uid()::text)
  and (storage.foldername(name))[1] = (select auth.uid()::text)
)
with check (
  bucket_id = 'wardrobe-images'
  and owner_id = (select auth.uid()::text)
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
create policy mmm_wardrobe_images_delete_own on storage.objects
for delete to authenticated
using (
  bucket_id = 'wardrobe-images'
  and owner_id = (select auth.uid()::text)
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
