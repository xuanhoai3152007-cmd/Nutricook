alter table public.profiles
  add column blocked_at timestamptz,
  add column blocked_until timestamptz,
  add column block_reason text,
  add column blocked_by uuid;

alter table public.orders
  drop constraint orders_user_id_fkey,
  add constraint orders_user_id_fkey
    foreign key (user_id) references public.profiles(id) on delete cascade;

alter table public.recipes
  drop constraint recipes_author_id_fkey,
  add constraint recipes_author_id_fkey
    foreign key (author_id) references public.profiles(id) on delete set null,
  drop constraint recipes_reviewed_by_fkey,
  add constraint recipes_reviewed_by_fkey
    foreign key (reviewed_by) references public.profiles(id) on delete set null;

alter table public.condition_rules
  drop constraint condition_rules_approved_by_fkey,
  add constraint condition_rules_approved_by_fkey
    foreign key (approved_by) references public.profiles(id) on delete set null;

drop function public.rpc_admin_list_accounts(text, integer, integer);

create function public.rpc_admin_list_accounts(
  p_query text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table (
  id uuid,
  email text,
  full_name text,
  role public.app_role,
  created_at timestamptz,
  is_blocked boolean,
  blocked_at timestamptz,
  blocked_until timestamptz,
  block_reason text
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.has_role(array['admin']::public.app_role[]) then
    raise exception 'FORBIDDEN';
  end if;

  return query
  select p.id, u.email::text, p.full_name, p.role, p.created_at,
         p.blocked_at is not null and (p.blocked_until is null or p.blocked_until > now()),
         p.blocked_at, p.blocked_until, p.block_reason
  from public.profiles p
  join auth.users u on u.id = p.id
  where nullif(trim(p_query), '') is null
     or coalesce(p.full_name, '') ilike '%' || trim(p_query) || '%'
     or coalesce(u.email, '') ilike '%' || trim(p_query) || '%'
  order by p.created_at desc
  limit least(greatest(coalesce(p_limit, 50), 1), 100)
  offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

revoke all on function public.rpc_admin_list_accounts(text, integer, integer) from public, anon;
grant execute on function public.rpc_admin_list_accounts(text, integer, integer) to authenticated;
