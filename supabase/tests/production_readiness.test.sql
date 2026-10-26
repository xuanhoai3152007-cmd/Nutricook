begin;

select plan(18);

select is(public.app_setting_bool('demo_mode', false), true, 'demo mode defaults to enabled');
select is(public.app_setting_bool('payments_live', true), false, 'live payments default to disabled');
select is(public.app_setting_bool('shop_enabled', false), true, 'shop availability is initialized');
select is(public.app_setting_bool('ai_enabled', false), true, 'AI availability is initialized');

set local role anon;
select ok(
  not has_function_privilege('anon', 'public.rpc_set_app_setting(text,jsonb)', 'EXECUTE'),
  'anonymous users cannot change app settings'
);
select is(
  (select value from public.app_settings where key = 'demo_mode'),
  'true'::jsonb,
  'anonymous users can read public app settings'
);
reset role;
select ok(
  has_function_privilege('service_role', 'public.app_setting_bool(text,boolean)', 'EXECUTE'),
  'Edge Functions can read feature flags with the service role'
);

insert into public.ingredients (
  slug, name_vi, kcal, protein_g, carb_g, fat_g, sat_fat_g, fiber_g, sugar_g, sodium_mg,
  source, source_ref, source_version
) values (
  'readiness-test-chicken', 'Ức gà kiểm thử', 165, 31, 0, 3.6, 1, 0, 0, 74,
  'USDA FoodData Central', 'test-fdc-1', '2026'
);

select is(
  public.ingredient_sanity((select i from public.ingredients i where slug = 'readiness-test-chicken')),
  '',
  'ingredient sanity accepts plausible sourced nutrition data'
);

update public.ingredients
set data_status = 'verified'
where slug = 'readiness-test-chicken';

select is(
  (select data_status from public.ingredients where slug = 'readiness-test-chicken'),
  'verified',
  'valid ingredient data can be verified'
);
select ok(
  (select verified_at is not null from public.ingredients where slug = 'readiness-test-chicken'),
  'verification records a timestamp'
);

update public.ingredients
set source_version = '2027'
where slug = 'readiness-test-chicken';

select is(
  (select data_status from public.ingredients where slug = 'readiness-test-chicken'),
  'unverified',
  'changing the source version invalidates ingredient verification'
);

insert into public.products (sku, name, slug, unit, price_vnd)
values ('READINESS-TEST', 'Sản phẩm kiểm thử', 'readiness-test-product', 'gói', 10000);

select is(
  (select count(*)::integer from public.price_history h
   join public.products p on p.id = h.product_id
   where p.sku = 'READINESS-TEST'),
  1,
  'product creation records its initial price'
);

update public.products
set price_vnd = 12000
where sku = 'READINESS-TEST';

select is(
  (select price_status from public.products where sku = 'READINESS-TEST'),
  'unverified',
  'changing a product price requires reverification'
);
select is(
  (select count(*)::integer from public.price_history h
   join public.products p on p.id = h.product_id
   where p.sku = 'READINESS-TEST'),
  2,
  'product price changes append price history'
);

update public.products
set price_status = 'verified', net_weight_verified = true, allergen_verified = true
where sku = 'READINESS-TEST';
update public.products
set pack_size_g = 500
where sku = 'READINESS-TEST';

select is(
  (select net_weight_verified from public.products where sku = 'READINESS-TEST'),
  false,
  'changing package size requires net-weight reverification'
);

update public.products
set allergen_verified = true
where sku = 'READINESS-TEST';
update public.products
set label_note = 'Updated test label'
where sku = 'READINESS-TEST';

select is(
  (select allergen_verified from public.products where sku = 'READINESS-TEST'),
  false,
  'changing label details requires allergen reverification'
);

update public.app_settings
set value = 'false'::jsonb
where key = 'payments_live';

select throws_ok(
  $$insert into public.orders (payment_method, subtotal_vnd, total_vnd, ship_snapshot)
    values ('vnpay', 0, 0, '{}'::jsonb)$$,
  'P0001',
  'PAYMENTS_DISABLED',
  'VNPay orders are blocked until live payments are explicitly enabled'
);

update public.app_settings
set value = 'false'::jsonb
where key = 'shop_enabled';

select throws_ok(
  $$insert into public.orders (payment_method, subtotal_vnd, total_vnd, ship_snapshot)
    values ('cod', 0, 0, '{}'::jsonb)$$,
  'P0001',
  'SHOP_DISABLED',
  'orders cannot be created while the shop is paused'
);

select * from finish();
rollback;
