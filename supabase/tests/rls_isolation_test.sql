BEGIN;
SELECT no_plan();

-- The test runner starts as postgres so it can create isolated fixtures. The
-- role and JWT claim are switched below to exercise the same RLS boundary as
-- an API request.
INSERT INTO auth.users (id, email)
VALUES
  ('10000000-0000-4000-8000-000000000001', 'mmm-owner@example.com'),
  ('20000000-0000-4000-8000-000000000002', 'mmm-other@example.com');

INSERT INTO public.style_preferences (user_id, kind, value)
VALUES
  ('10000000-0000-4000-8000-000000000001', 'style', 'casual'),
  ('20000000-0000-4000-8000-000000000002', 'style', 'formal');

INSERT INTO public.clothing_items (id, user_id, name, category, image_path)
VALUES
  (
    '30000000-0000-4000-8000-000000000003',
    '10000000-0000-4000-8000-000000000001',
    'Owner top',
    'top',
    '10000000-0000-4000-8000-000000000001/owner.png'
  ),
  (
    '40000000-0000-4000-8000-000000000004',
    '20000000-0000-4000-8000-000000000002',
    'Other top',
    'top',
    '20000000-0000-4000-8000-000000000002/other.png'
  );

INSERT INTO public.outfits (id, user_id, name)
VALUES
  (
    '50000000-0000-4000-8000-000000000005',
    '10000000-0000-4000-8000-000000000001',
    'Owner outfit'
  ),
  (
    '60000000-0000-4000-8000-000000000006',
    '20000000-0000-4000-8000-000000000002',
    'Other outfit'
  );

INSERT INTO public.outfit_items (outfit_id, clothing_item_id, slot)
VALUES
  (
    '50000000-0000-4000-8000-000000000005',
    '30000000-0000-4000-8000-000000000003',
    'top'
  ),
  (
    '60000000-0000-4000-8000-000000000006',
    '40000000-0000-4000-8000-000000000004',
    'top'
  );

INSERT INTO public.wear_events (id, user_id, outfit_id, clothing_item_ids)
VALUES
  (
    '70000000-0000-4000-8000-000000000007',
    '10000000-0000-4000-8000-000000000001',
    '50000000-0000-4000-8000-000000000005',
    ARRAY['30000000-0000-4000-8000-000000000003'::uuid]
  ),
  (
    '80000000-0000-4000-8000-000000000008',
    '20000000-0000-4000-8000-000000000002',
    '60000000-0000-4000-8000-000000000006',
    ARRAY['40000000-0000-4000-8000-000000000004'::uuid]
  );

INSERT INTO public.missing_piece_recommendations
  (id, user_id, category, title, reason, suggestion)
VALUES
  (
    '90000000-0000-4000-8000-000000000009',
    '10000000-0000-4000-8000-000000000001',
    'shoes',
    'Owner shoes',
    'Owner reason',
    'Owner suggestion'
  ),
  (
    'a0000000-0000-4000-8000-00000000000a',
    '20000000-0000-4000-8000-000000000002',
    'shoes',
    'Other shoes',
    'Other reason',
    'Other suggestion'
  );

INSERT INTO public.chat_threads (id, user_id, title)
VALUES
  (
    'b0000000-0000-4000-8000-00000000000b',
    '10000000-0000-4000-8000-000000000001',
    'Owner chat'
  ),
  (
    'c0000000-0000-4000-8000-00000000000c',
    '20000000-0000-4000-8000-000000000002',
    'Other chat'
  );

INSERT INTO public.chat_messages (id, thread_id, user_id, role, content)
VALUES
  (
    'd0000000-0000-4000-8000-00000000000d',
    'b0000000-0000-4000-8000-00000000000b',
    '10000000-0000-4000-8000-000000000001',
    'user',
    'Owner message'
  ),
  (
    'e0000000-0000-4000-8000-00000000000e',
    'c0000000-0000-4000-8000-00000000000c',
    '20000000-0000-4000-8000-000000000002',
    'user',
    'Other message'
  );

INSERT INTO public.outfit_preference_events
  (id, user_id, outfit_id, clothing_item_ids, source)
VALUES
  (
    'f0000000-0000-4000-8000-00000000000f',
    '10000000-0000-4000-8000-000000000001',
    '50000000-0000-4000-8000-000000000005',
    ARRAY['30000000-0000-4000-8000-000000000003'::uuid],
    'generated'
  ),
  (
    '11000000-0000-4000-8000-000000000011',
    '20000000-0000-4000-8000-000000000002',
    '60000000-0000-4000-8000-000000000006',
    ARRAY['40000000-0000-4000-8000-000000000004'::uuid],
    'generated'
  );

INSERT INTO public.recommendation_events
  (id, user_id, outfit_id, clothing_item_ids, event_type)
VALUES
  (
    '12000000-0000-4000-8000-000000000012',
    '10000000-0000-4000-8000-000000000001',
    '50000000-0000-4000-8000-000000000005',
    ARRAY['30000000-0000-4000-8000-000000000003'::uuid],
    'generated'
  ),
  (
    '13000000-0000-4000-8000-000000000013',
    '20000000-0000-4000-8000-000000000002',
    '60000000-0000-4000-8000-000000000006',
    ARRAY['40000000-0000-4000-8000-000000000004'::uuid],
    'generated'
  );

INSERT INTO storage.objects (bucket_id, name, owner_id, metadata)
VALUES (
  'wardrobe-images',
  '10000000-0000-4000-8000-000000000001/owner.png',
  '10000000-0000-4000-8000-000000000001',
  '{"mimetype":"image/png","size":1}'::jsonb
);

-- Owner A can read each of their rows and create a new row in each table
-- whose API surface supports direct user writes.
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';

SELECT is((SELECT count(*) FROM public.profiles), 1::bigint, 'A reads own profile');
SELECT is((SELECT count(*) FROM public.style_preferences), 1::bigint, 'A reads own style preferences');
SELECT is((SELECT count(*) FROM public.clothing_items), 1::bigint, 'A reads own clothing');
SELECT is((SELECT count(*) FROM public.outfits), 1::bigint, 'A reads own outfits');
SELECT is((SELECT count(*) FROM public.outfit_items), 1::bigint, 'A reads own outfit items');
SELECT is((SELECT count(*) FROM public.wear_events), 1::bigint, 'A reads own wear events');
SELECT is((SELECT count(*) FROM public.missing_piece_recommendations), 1::bigint, 'A reads own missing pieces');
SELECT is((SELECT count(*) FROM public.chat_threads), 1::bigint, 'A reads own chat threads');
SELECT is((SELECT count(*) FROM public.chat_messages), 1::bigint, 'A reads own chat messages');
SELECT is((SELECT count(*) FROM public.outfit_preference_events), 1::bigint, 'A reads own preference events');
SELECT is((SELECT count(*) FROM public.recommendation_events), 1::bigint, 'A reads own recommendation events');

SELECT results_eq(
  $$INSERT INTO public.style_preferences (user_id, kind, value)
    VALUES (auth.uid(), 'occasion', 'work') RETURNING user_id$$,
  $$VALUES ('10000000-0000-4000-8000-000000000001'::uuid)$$,
  'A creates own style preference'
);
SELECT results_eq(
  $$INSERT INTO public.clothing_items (id, user_id, name, category, image_path)
    VALUES ('a1000000-0000-4000-8000-000000000010', auth.uid(), 'Owner jacket', 'outerwear',
      '10000000-0000-4000-8000-000000000001/jacket.png')
    RETURNING user_id$$,
  $$VALUES ('10000000-0000-4000-8000-000000000001'::uuid)$$,
  'A creates own clothing item'
);
SELECT results_eq(
  $$INSERT INTO public.outfits (user_id, name)
    VALUES (auth.uid(), 'Owner new outfit') RETURNING user_id$$,
  $$VALUES ('10000000-0000-4000-8000-000000000001'::uuid)$$,
  'A creates own outfit'
);
SELECT results_eq(
  $$INSERT INTO public.wear_events (user_id, clothing_item_ids)
    VALUES (auth.uid(), ARRAY['30000000-0000-4000-8000-000000000003'::uuid])
    RETURNING user_id$$,
  $$VALUES ('10000000-0000-4000-8000-000000000001'::uuid)$$,
  'A creates own wear event'
);
SELECT results_eq(
  $$INSERT INTO public.missing_piece_recommendations
      (user_id, category, title, reason, suggestion)
    VALUES (auth.uid(), 'bag', 'Owner bag', 'Owner reason', 'Owner suggestion')
    RETURNING user_id$$,
  $$VALUES ('10000000-0000-4000-8000-000000000001'::uuid)$$,
  'A creates own missing-piece recommendation'
);
SELECT results_eq(
  $$INSERT INTO public.chat_threads (user_id, title)
    VALUES (auth.uid(), 'Owner new chat') RETURNING user_id$$,
  $$VALUES ('10000000-0000-4000-8000-000000000001'::uuid)$$,
  'A creates own chat thread'
);
SELECT results_eq(
  $$INSERT INTO public.chat_messages (thread_id, user_id, role, content)
    VALUES ('b0000000-0000-4000-8000-00000000000b', auth.uid(), 'user', 'New owner message')
    RETURNING user_id$$,
  $$VALUES ('10000000-0000-4000-8000-000000000001'::uuid)$$,
  'A creates own chat message'
);
SELECT results_eq(
  $$INSERT INTO public.outfit_preference_events (user_id, outfit_id, clothing_item_ids)
    VALUES (auth.uid(), '50000000-0000-4000-8000-000000000005',
      ARRAY['30000000-0000-4000-8000-000000000003'::uuid])
    RETURNING user_id$$,
  $$VALUES ('10000000-0000-4000-8000-000000000001'::uuid)$$,
  'A creates own preference event'
);
SELECT results_eq(
  $$INSERT INTO public.recommendation_events (user_id, outfit_id, clothing_item_ids, event_type)
    VALUES (auth.uid(), '50000000-0000-4000-8000-000000000005',
      ARRAY['30000000-0000-4000-8000-000000000003'::uuid], 'shown')
    RETURNING user_id$$,
  $$VALUES ('10000000-0000-4000-8000-000000000001'::uuid)$$,
  'A creates own recommendation event'
);

SELECT results_eq(
  $$INSERT INTO public.outfit_items (outfit_id, clothing_item_id, slot)
    VALUES ('50000000-0000-4000-8000-000000000005',
      'a1000000-0000-4000-8000-000000000010', 'outerwear')
    RETURNING outfit_id$$,
  $$VALUES ('50000000-0000-4000-8000-000000000005'::uuid)$$,
  'A creates an owned outfit-item link'
);

-- B receives no A rows and cannot update or delete A rows.
SET LOCAL request.jwt.claim.sub = '20000000-0000-4000-8000-000000000002';
SELECT is_empty($$SELECT * FROM public.profiles WHERE id = '10000000-0000-4000-8000-000000000001'$$, 'B cannot read A profile');
SELECT is_empty($$SELECT * FROM public.style_preferences WHERE user_id = '10000000-0000-4000-8000-000000000001'$$, 'B cannot read A style preferences');
SELECT is_empty($$SELECT * FROM public.clothing_items WHERE user_id = '10000000-0000-4000-8000-000000000001'$$, 'B cannot read A clothing');
SELECT is_empty($$SELECT * FROM public.outfits WHERE user_id = '10000000-0000-4000-8000-000000000001'$$, 'B cannot read A outfits');
SELECT is_empty($$SELECT * FROM public.outfit_items WHERE outfit_id = '50000000-0000-4000-8000-000000000005'$$, 'B cannot read A outfit items');
SELECT is_empty($$SELECT * FROM public.wear_events WHERE user_id = '10000000-0000-4000-8000-000000000001'$$, 'B cannot read A wear events');
SELECT is_empty($$SELECT * FROM public.missing_piece_recommendations WHERE user_id = '10000000-0000-4000-8000-000000000001'$$, 'B cannot read A missing pieces');
SELECT is_empty($$SELECT * FROM public.chat_threads WHERE user_id = '10000000-0000-4000-8000-000000000001'$$, 'B cannot read A chat threads');
SELECT is_empty($$SELECT * FROM public.chat_messages WHERE thread_id = 'b0000000-0000-4000-8000-00000000000b'$$, 'B cannot read A chat messages');
SELECT is_empty($$SELECT * FROM public.outfit_preference_events WHERE user_id = '10000000-0000-4000-8000-000000000001'$$, 'B cannot read A preference events');
SELECT is_empty($$SELECT * FROM public.recommendation_events WHERE user_id = '10000000-0000-4000-8000-000000000001'$$, 'B cannot read A recommendation events');

SELECT is_empty($$UPDATE public.profiles SET display_name = 'hacked' WHERE id = '10000000-0000-4000-8000-000000000001' RETURNING id$$, 'B cannot update A profile');
SELECT is_empty($$UPDATE public.style_preferences SET value = 'hacked' WHERE user_id = '10000000-0000-4000-8000-000000000001' RETURNING id$$, 'B cannot update A style preferences');
SELECT is_empty($$UPDATE public.clothing_items SET name = 'hacked' WHERE user_id = '10000000-0000-4000-8000-000000000001' RETURNING id$$, 'B cannot update A clothing');
SELECT is_empty($$UPDATE public.outfits SET name = 'hacked' WHERE user_id = '10000000-0000-4000-8000-000000000001' RETURNING id$$, 'B cannot update A outfits');
SELECT is_empty($$UPDATE public.outfit_items SET position = 99 WHERE outfit_id = '50000000-0000-4000-8000-000000000005' RETURNING outfit_id$$, 'B cannot update A outfit items');
SELECT is_empty($$UPDATE public.wear_events SET style = 'hacked' WHERE user_id = '10000000-0000-4000-8000-000000000001' RETURNING id$$, 'B cannot update A wear events');
SELECT is_empty($$UPDATE public.missing_piece_recommendations SET title = 'hacked' WHERE user_id = '10000000-0000-4000-8000-000000000001' RETURNING id$$, 'B cannot update A missing pieces');
SELECT is_empty($$UPDATE public.chat_threads SET title = 'hacked' WHERE user_id = '10000000-0000-4000-8000-000000000001' RETURNING id$$, 'B cannot update A chat threads');
SELECT is_empty($$UPDATE public.chat_messages SET content = 'hacked' WHERE thread_id = 'b0000000-0000-4000-8000-00000000000b' RETURNING id$$, 'B cannot update A chat messages');
SELECT is_empty($$UPDATE public.outfit_preference_events SET style = 'hacked' WHERE user_id = '10000000-0000-4000-8000-000000000001' RETURNING id$$, 'B cannot update A preference events');
SELECT is_empty($$UPDATE public.recommendation_events SET metadata = '{"hacked":true}'::jsonb WHERE user_id = '10000000-0000-4000-8000-000000000001' RETURNING id$$, 'B cannot update A recommendation events');

SELECT is_empty($$DELETE FROM public.profiles WHERE id = '10000000-0000-4000-8000-000000000001' RETURNING id$$, 'B cannot delete A profile');
SELECT is_empty($$DELETE FROM public.style_preferences WHERE user_id = '10000000-0000-4000-8000-000000000001' RETURNING id$$, 'B cannot delete A style preferences');
SELECT is_empty($$DELETE FROM public.clothing_items WHERE user_id = '10000000-0000-4000-8000-000000000001' RETURNING id$$, 'B cannot delete A clothing');
SELECT is_empty($$DELETE FROM public.outfits WHERE user_id = '10000000-0000-4000-8000-000000000001' RETURNING id$$, 'B cannot delete A outfits');
SELECT is_empty($$DELETE FROM public.outfit_items WHERE outfit_id = '50000000-0000-4000-8000-000000000005' RETURNING outfit_id$$, 'B cannot delete A outfit items');
SELECT is_empty($$DELETE FROM public.wear_events WHERE user_id = '10000000-0000-4000-8000-000000000001' RETURNING id$$, 'B cannot delete A wear events');
SELECT is_empty($$DELETE FROM public.missing_piece_recommendations WHERE user_id = '10000000-0000-4000-8000-000000000001' RETURNING id$$, 'B cannot delete A missing pieces');
SELECT is_empty($$DELETE FROM public.chat_threads WHERE user_id = '10000000-0000-4000-8000-000000000001' RETURNING id$$, 'B cannot delete A chat threads');
SELECT is_empty($$DELETE FROM public.chat_messages WHERE thread_id = 'b0000000-0000-4000-8000-00000000000b' RETURNING id$$, 'B cannot delete A chat messages');
SELECT is_empty($$DELETE FROM public.outfit_preference_events WHERE user_id = '10000000-0000-4000-8000-000000000001' RETURNING id$$, 'B cannot delete A preference events');
SELECT is_empty($$DELETE FROM public.recommendation_events WHERE user_id = '10000000-0000-4000-8000-000000000001' RETURNING id$$, 'B cannot delete A recommendation events');

-- with-check policies reject attempts to create rows owned by A.
SELECT throws_ok(
  $$INSERT INTO public.style_preferences (user_id, kind, value)
    VALUES ('10000000-0000-4000-8000-000000000001', 'occasion', 'stolen')$$,
  '42501', null, 'B cannot create A style preferences'
);
SELECT throws_ok(
  $$INSERT INTO public.clothing_items (user_id, name, category, image_path)
    VALUES ('10000000-0000-4000-8000-000000000001', 'Stolen', 'top', 'stolen.png')$$,
  '42501', null, 'B cannot create A clothing'
);
SELECT throws_ok(
  $$INSERT INTO public.outfits (user_id, name)
    VALUES ('10000000-0000-4000-8000-000000000001', 'Stolen')$$,
  '42501', null, 'B cannot create A outfits'
);
SELECT throws_ok(
  $$INSERT INTO public.outfit_items (outfit_id, clothing_item_id, slot)
    VALUES ('50000000-0000-4000-8000-000000000005',
      '30000000-0000-4000-8000-000000000003', 'top')$$,
  '42501', null, 'B cannot create A outfit items'
);
SELECT throws_ok(
  $$INSERT INTO public.wear_events (user_id, clothing_item_ids)
    VALUES ('10000000-0000-4000-8000-000000000001',
      ARRAY['30000000-0000-4000-8000-000000000003'::uuid])$$,
  '42501', null, 'B cannot create A wear events'
);
SELECT throws_ok(
  $$INSERT INTO public.missing_piece_recommendations
      (user_id, category, title, reason, suggestion)
    VALUES ('10000000-0000-4000-8000-000000000001', 'bag', 'Stolen', 'x', 'y')$$,
  '42501', null, 'B cannot create A missing pieces'
);
SELECT throws_ok(
  $$INSERT INTO public.chat_threads (user_id, title)
    VALUES ('10000000-0000-4000-8000-000000000001', 'Stolen')$$,
  '42501', null, 'B cannot create A chat threads'
);
SELECT throws_ok(
  $$INSERT INTO public.chat_messages (thread_id, user_id, role, content)
    VALUES ('b0000000-0000-4000-8000-00000000000b',
      '10000000-0000-4000-8000-000000000001', 'user', 'Stolen')$$,
  '42501', null, 'B cannot create A chat messages'
);
SELECT throws_ok(
  $$INSERT INTO public.outfit_preference_events (user_id, outfit_id, clothing_item_ids)
    VALUES ('10000000-0000-4000-8000-000000000001',
      '50000000-0000-4000-8000-000000000005',
      ARRAY['30000000-0000-4000-8000-000000000003'::uuid])$$,
  '42501', null, 'B cannot create A preference events'
);
SELECT throws_ok(
  $$INSERT INTO public.recommendation_events (user_id, outfit_id, clothing_item_ids, event_type)
    VALUES ('10000000-0000-4000-8000-000000000001',
      '50000000-0000-4000-8000-000000000005',
      ARRAY['30000000-0000-4000-8000-000000000003'::uuid], 'shown')$$,
  '42501', null, 'B cannot create A recommendation events'
);

-- An unauthenticated role has no table grant.
SET LOCAL ROLE anon;
SELECT throws_ok($$SELECT * FROM public.profiles$$, '42501', null, 'anon cannot read profiles');
SELECT throws_ok($$SELECT * FROM public.style_preferences$$, '42501', null, 'anon cannot read style preferences');
SELECT throws_ok($$SELECT * FROM public.clothing_items$$, '42501', null, 'anon cannot read clothing');
SELECT throws_ok($$SELECT * FROM public.outfits$$, '42501', null, 'anon cannot read outfits');
SELECT throws_ok($$SELECT * FROM public.outfit_items$$, '42501', null, 'anon cannot read outfit items');
SELECT throws_ok($$SELECT * FROM public.wear_events$$, '42501', null, 'anon cannot read wear events');
SELECT throws_ok($$SELECT * FROM public.missing_piece_recommendations$$, '42501', null, 'anon cannot read missing pieces');
SELECT throws_ok($$SELECT * FROM public.chat_threads$$, '42501', null, 'anon cannot read chat threads');
SELECT throws_ok($$SELECT * FROM public.chat_messages$$, '42501', null, 'anon cannot read chat messages');
SELECT throws_ok($$SELECT * FROM public.outfit_preference_events$$, '42501', null, 'anon cannot read preference events');
SELECT throws_ok($$SELECT * FROM public.recommendation_events$$, '42501', null, 'anon cannot read recommendation events');

-- Storage follows both the UID folder and owner_id.
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';
SELECT is((SELECT count(*) FROM storage.objects WHERE name LIKE '10000000-%'), 1::bigint, 'A reads own wardrobe image metadata');

SET LOCAL request.jwt.claim.sub = '20000000-0000-4000-8000-000000000002';
SELECT is_empty($$SELECT * FROM storage.objects WHERE name = '10000000-0000-4000-8000-000000000001/owner.png'$$, 'B cannot read A wardrobe image metadata');
SELECT is_empty($$UPDATE storage.objects SET metadata = '{"hacked":true}'::jsonb WHERE name = '10000000-0000-4000-8000-000000000001/owner.png' RETURNING name$$, 'B cannot update A wardrobe image metadata');
-- Supabase deliberately blocks direct SQL deletes from storage.objects; the
-- Storage API is the supported delete path and must apply the same policy.
SELECT throws_ok(
  $$DELETE FROM storage.objects WHERE name = '10000000-0000-4000-8000-000000000001/owner.png'$$,
  '42501', null,
  'direct storage deletion is blocked'
);
SELECT throws_ok(
  $$INSERT INTO storage.objects (bucket_id, name, owner_id, metadata)
    VALUES ('wardrobe-images', '10000000-0000-4000-8000-000000000001/stolen.png',
      '20000000-0000-4000-8000-000000000002', '{}'::jsonb)$$,
  '42501', null, 'B cannot create an object in A folder'
);

SET LOCAL ROLE anon;
SELECT is_empty($$SELECT * FROM storage.objects$$, 'anon cannot read wardrobe image metadata');

SELECT * FROM finish();
ROLLBACK;
