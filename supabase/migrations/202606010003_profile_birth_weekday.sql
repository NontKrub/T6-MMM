create or replace function public.set_profile_birth_weekday()
returns trigger
language plpgsql
as $$
begin
  if new.birth_date is null then
    new.birth_weekday = null;
  elsif tg_op = 'INSERT'
    or new.birth_date is distinct from old.birth_date
    or new.birth_weekday is null then
    new.birth_weekday = extract(isodow from new.birth_date)::int;
  end if;

  return new;
end;
$$;

update public.profiles
set birth_weekday = extract(isodow from birth_date)::int
where birth_date is not null
  and birth_weekday is null;

drop trigger if exists set_profiles_birth_weekday on public.profiles;
create trigger set_profiles_birth_weekday
before insert or update of birth_date, birth_weekday on public.profiles
for each row execute function public.set_profile_birth_weekday();
