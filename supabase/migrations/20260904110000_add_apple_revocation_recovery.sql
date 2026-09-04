alter table public.account_deletion_attempts
  add column if not exists apple_refresh_token text,
  add column if not exists apple_refresh_token_expires_at timestamptz;
