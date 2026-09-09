create or replace function public.save_profile_with_preferences(
  p_display_name text,
  p_avatar_url text,
  p_avatar_path text,
  p_avatar_mode text,
  p_color_season text,
  p_avatar_type text,
  p_onboarding_complete boolean,
  p_body_type text,
  p_brand_tier numeric,
  p_birth_date date,
  p_birth_weekday integer,
  p_body_shape text,
  p_skin_tone_index integer,
  p_hair_color_index integer,
  p_hair_style_index integer,
  p_styles text[],
  p_occasions text[]
)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Authentication is required to save a profile'
      using errcode = '42501';
  end if;

  insert into public.profiles (
    id,
    display_name,
    avatar_url,
    avatar_path,
    avatar_mode,
    color_season,
    avatar_type,
    onboarding_complete,
    body_type,
    brand_tier,
    birth_date,
    birth_weekday,
    body_shape,
    skin_tone_index,
    hair_color_index,
    hair_style_index
  ) values (
    v_user_id,
    coalesce(p_display_name, 'MMM User'),
    p_avatar_url,
    p_avatar_path,
    p_avatar_mode,
    p_color_season::public.color_season,
    p_avatar_type::public.avatar_type,
    coalesce(p_onboarding_complete, false),
    p_body_type,
    coalesce(p_brand_tier, 0.30),
    p_birth_date,
    p_birth_weekday,
    coalesce(p_body_shape, 'female'),
    coalesce(p_skin_tone_index, 1),
    coalesce(p_hair_color_index, 1),
    coalesce(p_hair_style_index, 3)
  )
  on conflict (id) do update set
    display_name = excluded.display_name,
    avatar_url = excluded.avatar_url,
    avatar_path = excluded.avatar_path,
    avatar_mode = excluded.avatar_mode,
    color_season = excluded.color_season,
    avatar_type = excluded.avatar_type,
    onboarding_complete = excluded.onboarding_complete,
    body_type = excluded.body_type,
    brand_tier = excluded.brand_tier,
    birth_date = excluded.birth_date,
    birth_weekday = excluded.birth_weekday,
    body_shape = excluded.body_shape,
    skin_tone_index = excluded.skin_tone_index,
    hair_color_index = excluded.hair_color_index,
    hair_style_index = excluded.hair_style_index;

  delete from public.style_preferences
  where user_id = v_user_id;

  insert into public.style_preferences (user_id, kind, value)
  select v_user_id, 'style', btrim(preference_value)
  from unnest(coalesce(p_styles, '{}'::text[])) as styles(preference_value)
  where btrim(preference_value) <> ''
  group by btrim(preference_value)
  union
  select v_user_id, 'occasion', btrim(preference_value)
  from unnest(coalesce(p_occasions, '{}'::text[])) as occasions(preference_value)
  where btrim(preference_value) <> ''
  group by btrim(preference_value);
end;
$$;

revoke execute on function public.save_profile_with_preferences(
  text, text, text, text, text, text, boolean, text, numeric, date,
  integer, text, integer, integer, integer, text[], text[]
) from public, anon, authenticated;
grant execute on function public.save_profile_with_preferences(
  text, text, text, text, text, text, boolean, text, numeric, date,
  integer, text, integer, integer, integer, text[], text[]
) to authenticated;
