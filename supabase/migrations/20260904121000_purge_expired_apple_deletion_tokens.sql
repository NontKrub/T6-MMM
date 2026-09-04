create extension if not exists pg_cron;

create or replace function public.purge_expired_account_deletion_tokens()
returns integer
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  affected_rows integer;
begin
  update public.account_deletion_attempts
  set
    apple_refresh_token = null,
    apple_refresh_token_expires_at = null,
    updated_at = now()
  where apple_refresh_token is not null
    and (
      apple_refresh_token_expires_at is null
      or apple_refresh_token_expires_at <= now()
    );
  get diagnostics affected_rows = row_count;
  return affected_rows;
end;
$$;

revoke all on function public.purge_expired_account_deletion_tokens() from public;
revoke all on function public.purge_expired_account_deletion_tokens() from anon;
revoke all on function public.purge_expired_account_deletion_tokens() from authenticated;
grant execute on function public.purge_expired_account_deletion_tokens() to service_role;

do $$
declare
  existing_job_id bigint;
begin
  select jobid
  into existing_job_id
  from cron.job
  where jobname = 'purge-expired-apple-deletion-tokens';

  if existing_job_id is not null then
    perform cron.unschedule(existing_job_id);
  end if;

  perform cron.schedule(
    'purge-expired-apple-deletion-tokens',
    '* * * * *',
    'select public.purge_expired_account_deletion_tokens();'
  );
end;
$$;
