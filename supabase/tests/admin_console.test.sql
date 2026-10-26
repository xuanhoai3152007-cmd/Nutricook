begin;

select plan(12);

select ok(
  not has_function_privilege('anon', 'public.rpc_admin_list_accounts(text,integer,integer)', 'EXECUTE'),
  'anonymous users cannot list accounts'
);
select ok(
  not has_function_privilege('anon', 'public.rpc_admin_create_recipe(jsonb,jsonb,jsonb,boolean)', 'EXECUTE'),
  'anonymous users cannot create recipes'
);
select ok(
  has_function_privilege('authenticated', 'public.rpc_admin_list_accounts(text,integer,integer)', 'EXECUTE'),
  'signed-in users can call the account RPC, which enforces admin role'
);
select ok(
  has_function_privilege('authenticated', 'public.rpc_admin_create_recipe(jsonb,jsonb,jsonb,boolean)', 'EXECUTE'),
  'signed-in users can call the recipe RPC, which enforces admin role'
);

insert into auth.users (id, aud, role, email, encrypted_password, email_confirmed_at)
values (
  'd10a1000-0000-4000-8000-000000000008',
  'authenticated',
  'authenticated',
  'test-admin-console@nutricook.local',
  'test-password-hash',
  now()
);
update public.profiles
set full_name = 'Admin Console Test', role = 'admin'
where id = 'd10a1000-0000-4000-8000-000000000008';

select set_config('request.jwt.claim.sub', 'd10a1000-0000-4000-8000-000000000008', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
update public.profiles
set blocked_at = now(), blocked_until = now() + interval '1 day', block_reason = 'moderation test'
where id = 'd10a1000-0000-4000-8000-000000000008';
set local role authenticated;
select is(
  (select count(*)::integer from public.rpc_admin_list_accounts('test-admin-console@nutricook.local', 50, 0)),
  1,
  'admins can search accounts using basic account fields'
);
select is(
  (select is_blocked from public.rpc_admin_list_accounts('test-admin-console@nutricook.local', 50, 0)),
  true,
  'account listing includes active moderation state'
);
select ok(
  public.rpc_admin_create_recipe(
      jsonb_build_object(
        'slug', 'admin-console-test-recipe',
        'title', 'Admin console test recipe',
        'meal', jsonb_build_array('lunch'),
        'diet_tags', jsonb_build_array('normal'),
        'equipment', jsonb_build_array('pan'),
        'kcal', 220
      ),
      jsonb_build_array(jsonb_build_object(
        'ingredient_id', (select id::text from public.ingredients where slug = 'gao-lut'),
        'amount_g', 100,
        'display_amount', 100,
        'display_unit', 'g'
      )),
      jsonb_build_array(jsonb_build_object(
        'step_no', 1,
        'phase', 'prep',
        'title', 'Prepare ingredients',
        'instruction', 'Wash and prepare the ingredients before cooking.'
      )),
      false
  ) is not null,
  'admins can create a recipe'
);
select is(
  (select count(*)::integer from public.recipes where slug = 'admin-console-test-recipe'),
  1,
  'new recipes are stored as a single database record'
);
select is(
  (select count(*)::integer
   from public.recipe_ingredients ri
   join public.recipes r on r.id = ri.recipe_id
   where r.slug = 'admin-console-test-recipe'),
  1,
  'recipe ingredients are saved with the recipe'
);
select is(
  (select count(*)::integer
   from public.recipe_steps rs
   join public.recipes r on r.id = rs.recipe_id
   where r.slug = 'admin-console-test-recipe'),
  1,
  'recipe steps are saved with the recipe'
);
reset role;

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000000', true);
set local role authenticated;
select throws_ok(
  $$select * from public.rpc_admin_list_accounts()$$,
  'P0001',
  'FORBIDDEN',
  'non-admin users cannot list accounts'
);
select throws_ok(
  $$select public.rpc_admin_create_recipe('{}'::jsonb, '[]'::jsonb, '[]'::jsonb, false)$$,
  'P0001',
  'FORBIDDEN',
  'non-admin users cannot create recipes'
);
reset role;

select * from finish();
rollback;
