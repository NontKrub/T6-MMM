create or replace function public.create_outfit_with_items(
  p_name text,
  p_style text,
  p_reason text,
  p_score numeric,
  p_selection_factors jsonb,
  p_generation_context jsonb,
  p_item_ids uuid[]
)
returns jsonb
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_outfit public.outfits%rowtype;
  v_item_count bigint;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if p_name is null or btrim(p_name) = '' then
    raise exception 'Outfit name is required';
  end if;

  if p_item_ids is null or cardinality(p_item_ids) = 0 then
    raise exception 'At least one clothing item is required';
  end if;

  if exists (
    select 1
    from unnest(p_item_ids) as input(item_id)
    where input.item_id is null
  ) then
    raise exception 'Clothing item IDs cannot be null';
  end if;

  select count(*) into v_item_count
  from (
    select distinct input.item_id
    from unnest(p_item_ids) as input(item_id)
  ) as distinct_items;

  if v_item_count <> cardinality(p_item_ids) then
    raise exception 'Duplicate clothing item IDs are not allowed';
  end if;

  select count(*) into v_item_count
  from public.clothing_items as item
  where item.id = any(p_item_ids)
    and item.user_id = v_user_id
    and item.archived_at is null;

  if v_item_count <> cardinality(p_item_ids) then
    raise exception 'Every clothing item must belong to the current user and be active';
  end if;

  insert into public.outfits (
    user_id,
    name,
    style,
    reason,
    score,
    selection_factors,
    generation_context
  ) values (
    v_user_id,
    p_name,
    p_style,
    p_reason,
    p_score,
    coalesce(p_selection_factors, '{}'::jsonb),
    coalesce(p_generation_context, '{}'::jsonb)
  )
  returning * into v_outfit;

  insert into public.outfit_items (
    outfit_id,
    clothing_item_id,
    slot,
    position
  )
  select
    v_outfit.id,
    item.id,
    item.category,
    (input.position - 1)::integer
  from unnest(p_item_ids) with ordinality as input(item_id, position)
  join public.clothing_items as item on item.id = input.item_id
  where item.user_id = v_user_id
    and item.archived_at is null;

  return jsonb_build_object(
    'id', v_outfit.id,
    'user_id', v_outfit.user_id,
    'name', v_outfit.name,
    'style', v_outfit.style,
    'reason', v_outfit.reason,
    'score', v_outfit.score,
    'selection_factors', v_outfit.selection_factors,
    'generation_context', v_outfit.generation_context,
    'worn_on', v_outfit.worn_on,
    'saved', v_outfit.saved,
    'created_at', v_outfit.created_at,
    'item_ids', p_item_ids
  );
end;
$$;

revoke all on function public.create_outfit_with_items(
  text,
  text,
  text,
  numeric,
  jsonb,
  jsonb,
  uuid[]
) from public, anon, authenticated;

grant execute on function public.create_outfit_with_items(
  text,
  text,
  text,
  numeric,
  jsonb,
  jsonb,
  uuid[]
) to authenticated;
