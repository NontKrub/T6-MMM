create table if not exists public.user_consents (
  user_id uuid not null references public.profiles(id) on delete cascade,
  consent_type text not null,
  policy_version text not null,
  granted_at timestamptz not null default now(),
  revoked_at timestamptz,
  primary key (user_id, consent_type, policy_version)
);

alter table public.user_consents enable row level security;

drop policy if exists mmm_user_consents_manage_own on public.user_consents;
create policy mmm_user_consents_manage_own on public.user_consents
for all to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

revoke all on table public.user_consents from public, anon, authenticated;
grant select, insert, update, delete on table public.user_consents to authenticated;
grant all on table public.user_consents to service_role;
