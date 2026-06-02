create or replace function public.set_profile_birth_weekday()
returns trigger
language plpgsql
as $$
begin
  if new.birth_date is null then
    new.birth_weekday = null;
    return new;
  end if;

  if tg_op = 'INSERT' then
    if new.birth_weekday is null then
      new.birth_weekday = extract(isodow from new.birth_date)::int;
    end if;
    return new;
  end if;

  if new.birth_date is distinct from old.birth_date
    or new.birth_weekday is null then
    new.birth_weekday = extract(isodow from new.birth_date)::int;
  end if;

  return new;
end;
$$;
