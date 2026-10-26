begin;

select plan(4);

select ok(
  not has_column_privilege('authenticated', 'public.profiles', 'role', 'UPDATE'),
  'authenticated users cannot update their role'
);

select ok(
  not has_column_privilege('authenticated', 'public.profiles', 'target_kcal', 'UPDATE'),
  'authenticated users cannot update calculated nutrition targets'
);

select ok(
  has_column_privilege('authenticated', 'public.profiles', 'taste_prefs', 'UPDATE'),
  'authenticated users can update their preferences'
);

set local role anon;
select is(
  (select count(*)::integer from public.condition_rules where approved_at is null),
  0,
  'anonymous users cannot read unapproved health rules'
);
reset role;

select * from finish();
rollback;
