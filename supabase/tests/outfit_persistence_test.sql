BEGIN;
SELECT plan(3);

SELECT has_function(
  'public',
  'create_outfit_with_items',
  ARRAY['text', 'text', 'text', 'numeric', 'jsonb', 'jsonb', 'uuid[]'],
  'atomic outfit RPC exists'
);

SELECT set_config(
  'request.jwt.claims',
  json_build_object(
    'sub', '11111111-1111-4111-8111-111111111111',
    'role', 'authenticated'
  )::text,
  true
);
SET LOCAL ROLE authenticated;

SELECT throws_ok(
  $$SELECT public.create_outfit_with_items(
    'Invalid item',
    'casual',
    'fault injection',
    0,
    '{}'::jsonb,
    '{}'::jsonb,
    ARRAY['22222222-2222-4222-8222-222222222222'::uuid]
  )$$,
  'P0001',
  'Every clothing item must belong to the current user and be active',
  'invalid clothing item rejects the whole RPC'
);

SET LOCAL ROLE postgres;

SELECT is(
  (SELECT count(*) FROM public.outfits
   WHERE user_id = '11111111-1111-4111-8111-111111111111'::uuid),
  0::bigint,
  'failed RPC creates no orphaned parent outfit'
);

SELECT * FROM finish();
ROLLBACK;
