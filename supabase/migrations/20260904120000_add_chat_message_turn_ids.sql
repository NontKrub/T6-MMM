alter table public.chat_messages
  add column if not exists turn_id uuid;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'chat_messages_user_turn_role_key'
      and conrelid = 'public.chat_messages'::regclass
  ) then
    alter table public.chat_messages
      add constraint chat_messages_user_turn_role_key
      unique (user_id, turn_id, role);
  end if;
end;
$$;
