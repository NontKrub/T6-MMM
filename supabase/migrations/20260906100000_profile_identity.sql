alter table public.profiles
  add column if not exists avatar_path text,
  add column if not exists avatar_mode text;

update public.profiles
set avatar_mode = case
  when avatar_url is not null and btrim(avatar_url) <> '' then 'provider'
  else 'none'
end
where avatar_mode is null;

alter table public.profiles
  alter column avatar_mode set default 'none',
  alter column avatar_mode set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_avatar_mode_check'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_avatar_mode_check
      check (avatar_mode in ('provider', 'custom', 'none'));
  end if;
end;
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  provider_avatar_url text := new.raw_user_meta_data->>'avatar_url';
begin
  insert into public.profiles (
    id,
    display_name,
    avatar_url,
    avatar_mode
  ) values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'full_name', 'MMM User'),
    provider_avatar_url,
    case
      when provider_avatar_url is not null and btrim(provider_avatar_url) <> ''
        then 'provider'
      else 'none'
    end
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
