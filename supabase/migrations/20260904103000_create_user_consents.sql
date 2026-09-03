create table if not exists public.user_consents (
  user_id uuid not null references public.profiles(id) on delete cascade,
  consent_type text not null,
  policy_version text not null,
  granted_at timestamptz not null default now(),
  revoked_at timestamptz,
  primary key (user_id, consent_type, policy_version)
);

alter table public.user_consents enable row level security;

drop policy if exists mmm_user_consents_select_own on public.user_consents;
drop policy if exists mmm_user_consents_insert_own on public.user_consents;
drop policy if exists mmm_user_consents_update_own on public.user_consents;
drop policy if exists mmm_user_consents_delete_own on public.user_consents;
create policy mmm_user_consents_select_own on public.user_consents
for select to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()));
create policy mmm_user_consents_insert_own on public.user_consents
for insert to authenticated
with check ((select auth.uid()) is not null and user_id = (select auth.uid()));
create policy mmm_user_consents_update_own on public.user_consents
for update to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()))
with check ((select auth.uid()) is not null and user_id = (select auth.uid()));
create policy mmm_user_consents_delete_own on public.user_consents
for delete to authenticated
using ((select auth.uid()) is not null and user_id = (select auth.uid()));

revoke all on table public.user_consents from public, anon, authenticated;
grant select, insert, update, delete on table public.user_consents to authenticated;
grant all on table public.user_consents to service_role;
