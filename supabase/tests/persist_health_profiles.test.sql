begin;

select plan(12);

select ok(
  exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'profiles' and column_name = 'budget_level'
  ),
  'profiles store the budget preference'
);

select ok(
  exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'profiles' and column_name = 'disliked_ingredients'
  ),
  'profiles store disliked ingredients'
);

select is(
  (select count(*)::integer from public.health_conditions
   where code in ('overweight', 'breastfeeding', 'eating_disorder')),
  3,
  'all profile health choices have database condition codes'
);

select ok(
  has_function_privilege('authenticated', 'public.rpc_save_user_profile(jsonb,text[],text[],boolean)', 'EXECUTE'),
  'authenticated users can save a profile through the scoped RPC'
);

select ok(
  not has_function_privilege('anon', 'public.rpc_save_user_profile(jsonb,text[],text[],boolean)', 'EXECUTE'),
  'anonymous users cannot save a health profile'
);

select ok(
  has_column_privilege('authenticated', 'public.profiles', 'consent_health_at', 'UPDATE'),
  'authenticated profile updates can record health-data consent'
);

select ok(
  has_column_privilege('authenticated', 'public.profiles', 'onboarding_done', 'UPDATE'),
  'authenticated profile updates can mark onboarding complete'
);

insert into auth.users (id, aud, role, email, encrypted_password, email_confirmed_at)
values (
  'a62f1070-b199-4da1-b738-cbbd406e2f54',
  'authenticated',
  'authenticated',
  'profile-save-test@nutricook.local',
  'test-password-hash',
  now()
);

select set_config('request.jwt.claim.sub', 'a62f1070-b199-4da1-b738-cbbd406e2f54', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select throws_ok(
  $$select public.rpc_save_user_profile(
    '{"sex":"female","birth_date":"1999-01-01","height_cm":165,"weight_kg":60,"goal":"healthy","activity":"light","diet":"normal"}'::jsonb,
    '{}',
    '{}',
    false
  )$$,
  'P0001',
  'CONSENT_REQUIRED',
  'the backend rejects health-profile saves without explicit consent'
);

select lives_ok(
  $$select public.rpc_save_user_profile(
    '{"sex":"female","birth_date":"1999-01-01","height_cm":165,"weight_kg":60,"goal":"healthy","activity":"light","diet":"normal","max_cook_minutes":30,"budget_level":"medium","cooking_skill":1,"disliked_ingredients":"rau mùi"}'::jsonb,
    array['diabetes_t2','pregnancy'],
    array['fish','shellfish'],
    true
  )$$,
  'the authenticated account can save its profile and health selections'
);

select is(
  (select count(*)::integer from public.user_health_conditions
   where user_id = 'a62f1070-b199-4da1-b738-cbbd406e2f54'),
  2,
  'health condition selections are persisted for the account'
);

select is(
  (select count(*)::integer from public.user_allergies
   where user_id = 'a62f1070-b199-4da1-b738-cbbd406e2f54'),
  2,
  'allergy selections are persisted for the account'
);

select is(
  (select budget_level from public.profiles
   where id = 'a62f1070-b199-4da1-b738-cbbd406e2f54'),
  'medium',
  'preference fields are stored on the account profile'
);

reset role;
select * from finish();
rollback;
