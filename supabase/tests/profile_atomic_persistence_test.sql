BEGIN;
SELECT no_plan();

INSERT INTO auth.users (id, email)
VALUES
  ('10000000-0000-4000-8000-000000000001', 'atomic-owner@example.com'),
  ('20000000-0000-4000-8000-000000000002', 'atomic-other@example.com');

UPDATE public.profiles
SET display_name = 'Other unchanged'
WHERE id = '20000000-0000-4000-8000-000000000002';

INSERT INTO public.style_preferences (user_id, kind, value)
VALUES
  ('10000000-0000-4000-8000-000000000001', 'style', 'old-style'),
  ('20000000-0000-4000-8000-000000000002', 'style', 'formal'),
  ('20000000-0000-4000-8000-000000000002', 'occasion', 'travel');

SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';

SELECT public.save_profile_with_preferences(
  'Owner updated',
  NULL,
  NULL,
  'none',
  'winter',
  'human',
  true,
  'athletic',
  0.7,
  '1990-01-02'::date,
  2,
  'female',
  2,
  3,
  4,
  ARRAY['casual', 'casual', ' ', 'street'],
  ARRAY['work', 'work', ' ']
);

SELECT is(
  (SELECT display_name FROM public.profiles WHERE id = auth.uid()),
  'Owner updated',
  'authenticated owner profile is updated'
);
SELECT is(
  (SELECT color_season::text FROM public.profiles WHERE id = auth.uid()),
  'winter',
  'typed profile fields are persisted'
);
SELECT results_eq(
  $$SELECT kind, value FROM public.style_preferences
    WHERE user_id = auth.uid() ORDER BY kind, value$$,
  $$VALUES ('occasion', 'work'), ('style', 'casual'), ('style', 'street')$$,
  'preferences are replaced, trimmed, and deduplicated'
);

SET LOCAL ROLE postgres;
SELECT is(
  (SELECT display_name FROM public.profiles
    WHERE id = '20000000-0000-4000-8000-000000000002'),
  'Other unchanged',
  'another user profile is unchanged'
);
SELECT results_eq(
  $$SELECT kind, value FROM public.style_preferences
    WHERE user_id = '20000000-0000-4000-8000-000000000002'
    ORDER BY kind, value$$,
  $$VALUES ('occasion', 'travel'), ('style', 'formal')$$,
  'another user preferences are unchanged'
);

SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';

SELECT public.save_profile_with_preferences(
  'Owner empty', NULL, NULL, 'none', 'spring', 'human', false, NULL,
  0.3, NULL::date, NULL::integer, 'female', 1, 1, 3,
  ARRAY[]::text[], ARRAY[]::text[]
);
SELECT is(
  (SELECT count(*) FROM public.style_preferences WHERE user_id = auth.uid()),
  0::bigint,
  'empty preference arrays intentionally remove preferences'
);

SET LOCAL ROLE anon;
SELECT throws_ok(
  $$SELECT public.save_profile_with_preferences(
    'Anonymous', NULL, NULL, 'none', 'spring', 'human', false, NULL,
    0.3, NULL::date, NULL::integer, 'female', 1, 1, 3,
    ARRAY[]::text[], ARRAY[]::text[]
  )$$,
  '42501',
  NULL,
  'anonymous callers cannot execute the profile RPC'
);

SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';

SELECT public.save_profile_with_preferences(
  'Before failure', NULL, NULL, 'none', 'spring', 'human', false, NULL,
  0.3, NULL::date, NULL::integer, 'female', 1, 1, 3,
  ARRAY['baseline-style'], ARRAY['baseline-occasion']
);

SET LOCAL ROLE postgres;
CREATE OR REPLACE FUNCTION public.test_profile_atomic_failure()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.value = '__force_failure__' THEN
    RAISE EXCEPTION 'forced atomic failure' USING errcode = 'P0001';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER test_profile_atomic_failure_trigger
BEFORE INSERT ON public.style_preferences
FOR EACH ROW EXECUTE FUNCTION public.test_profile_atomic_failure();

SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';

SELECT throws_ok(
  $$SELECT public.save_profile_with_preferences(
    'Should roll back', NULL, NULL, 'none', 'winter', 'human', true,
    'should-not-persist', 0.9, NULL::date, NULL::integer, 'female', 2, 3, 4,
    ARRAY['__force_failure__'], ARRAY['new-occasion']
  )$$,
  'P0001',
  NULL,
  'profile RPC failure is surfaced'
);
SELECT is(
  (SELECT display_name FROM public.profiles WHERE id = auth.uid()),
  'Before failure',
  'profile update rolls back with preference failure'
);
SELECT results_eq(
  $$SELECT kind, value FROM public.style_preferences
    WHERE user_id = auth.uid() ORDER BY kind, value$$,
  $$VALUES ('occasion', 'baseline-occasion'), ('style', 'baseline-style')$$,
  'preference delete and insert roll back atomically'
);

SELECT finish();
ROLLBACK;
