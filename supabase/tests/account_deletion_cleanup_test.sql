BEGIN;
SELECT plan(7);

INSERT INTO auth.users (id, email)
VALUES
  ('11111111-1111-4111-8111-111111111111', 'expired-token@example.com'),
  ('22222222-2222-4222-8222-222222222222', 'valid-token@example.com'),
  ('33333333-3333-4333-8333-333333333333', 'empty-token@example.com');

INSERT INTO public.account_deletion_attempts
  (user_id, apple_refresh_token, apple_refresh_token_expires_at)
VALUES
  ('11111111-1111-4111-8111-111111111111', 'expired', now() - interval '1 minute'),
  ('22222222-2222-4222-8222-222222222222', 'valid', now() + interval '1 minute'),
  ('33333333-3333-4333-8333-333333333333', null, null);

SELECT is(
  public.purge_expired_account_deletion_tokens(),
  1,
  'purge reports the expired token it cleared'
);
SELECT is(
  (SELECT apple_refresh_token FROM public.account_deletion_attempts
   WHERE user_id = '11111111-1111-4111-8111-111111111111'),
  null,
  'expired token is cleared'
);
SELECT is(
  (SELECT apple_refresh_token_expires_at FROM public.account_deletion_attempts
   WHERE user_id = '11111111-1111-4111-8111-111111111111'),
  null,
  'expired token expiry is cleared'
);
SELECT is(
  (SELECT apple_refresh_token FROM public.account_deletion_attempts
   WHERE user_id = '22222222-2222-4222-8222-222222222222'),
  'valid',
  'valid token remains available for retry'
);

SET LOCAL ROLE authenticated;
SELECT throws_ok(
  $$SELECT public.purge_expired_account_deletion_tokens()$$,
  '42501', null, 'authenticated cannot execute the purge'
);
SET LOCAL ROLE anon;
SELECT throws_ok(
  $$SELECT public.purge_expired_account_deletion_tokens()$$,
  '42501', null, 'anon cannot execute the purge'
);
SET LOCAL ROLE postgres;
SELECT ok(
  exists(
    select 1 from cron.job
    where jobname = 'purge-expired-apple-deletion-tokens'
      and schedule = '* * * * *'
      and command = 'select public.purge_expired_account_deletion_tokens();'
  ),
  'minute cron cleanup job is registered'
);

SELECT * FROM finish();
ROLLBACK;
