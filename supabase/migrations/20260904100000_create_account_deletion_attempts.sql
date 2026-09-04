create table if not exists public.account_deletion_attempts (
  user_id uuid primary key references auth.users(id) on delete cascade,
  apple_revoked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.account_deletion_attempts enable row level security;

revoke all on table public.account_deletion_attempts from public, anon, authenticated;
grant all on table public.account_deletion_attempts to service_role;
