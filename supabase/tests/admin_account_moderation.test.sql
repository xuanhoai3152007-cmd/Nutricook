begin;

select plan(6);

select has_column('public', 'profiles', 'blocked_at', 'profiles records when an account was blocked');
select has_column('public', 'profiles', 'blocked_until', 'profiles records an optional block expiry');
select has_column('public', 'profiles', 'block_reason', 'profiles records the moderation reason');
select ok(
  exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'orders'
      and c.conname = 'orders_user_id_fkey'
      and c.confdeltype = 'c'
  ),
  'deleting an account cascades to its associated orders'
);
select has_function('public', 'rpc_admin_list_accounts', array['text', 'integer', 'integer'], 'admin account listing RPC remains available');
select ok(
  not has_table_privilege('authenticated', 'public.profiles', 'UPDATE'),
  'authenticated users cannot directly update profile or moderation fields'
);

select * from finish();
rollback;
