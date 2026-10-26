-- =====================================================================
-- NutriCook · Migration 5 · RPC CỬA HÀNG (giỏ hàng · đặt hàng · thanh toán)
-- Quy ước: không hàm nào nhận user_id từ client; dùng auth.uid().
-- =====================================================================

-- ---------- 1. GIỎ HÀNG ----------
create or replace function public.rpc_ensure_cart() returns uuid
language plpgsql security definer set search_path = public as $$
declare v uuid;
begin
  if auth.uid() is null then raise exception 'UNAUTHENTICATED'; end if;
  insert into carts(user_id) values (auth.uid())
    on conflict (user_id) do update set updated_at = now() returning id into v;
  return v;
end $$;
revoke all on function public.rpc_ensure_cart() from public, anon;
grant execute on function public.rpc_ensure_cart() to authenticated;

-- ---------- 2. DANH SÁCH MUA SẮM TỪ CÔNG THỨC ----------
-- p_items = [{"recipe_id":"…","servings":4}, …]   (tối đa 30 món)
create or replace function public.rpc_shopping_list(p_items jsonb)
returns table (ingredient_id uuid, ingredient_name text, need_g numeric, pantry_g numeric, buy_g numeric,
               product_id uuid, product_name text, unit text, qty int, price_vnd bigint,
               line_total_vnd bigint, in_stock boolean, allergen_conflict boolean)
language plpgsql stable security definer set search_path = public as $$
#variable_conflict use_column
declare v_uid uuid := auth.uid(); v_alg smallint[] := '{}';
begin
  if v_uid is null then raise exception 'UNAUTHENTICATED'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) > 30 then raise exception 'INVALID_ITEMS'; end if;
  select coalesce(array_agg(allergen_id), '{}') into v_alg from user_allergies where user_id = v_uid;

  return query
  with items as (
    select (x->>'recipe_id')::uuid as rid, (x->>'servings')::numeric as sv from jsonb_array_elements(p_items) x
  ), need as (
    select ri.ingredient_id,
           sum(ri.amount_g * case ri.scale_mode when 'fixed' then 1::numeric
                 when 'sublinear' then sqrt(i.sv / r.base_servings) else i.sv / r.base_servings end) as need_g
    from items i
    join recipes r on r.id = i.rid and r.status = 'published'
    join recipe_ingredients ri on ri.recipe_id = r.id and not ri.optional
    where i.sv > 0 and i.sv <= 50
    group by ri.ingredient_id
  ), net as (
    select n.ingredient_id, n.need_g, coalesce(pi.amount_g, 0) as pantry_g,
           greatest(n.need_g - coalesce(pi.amount_g, 0), 0) as buy_g
    from need n left join pantry_items pi on pi.ingredient_id = n.ingredient_id and pi.user_id = v_uid
  )
  select ig.id, ig.name_vi, round(net.need_g, 1), net.pantry_g, round(net.buy_g, 1),
         pr.id, pr.name, pr.unit,
         case when pr.id is null then null else ceil(net.buy_g / pr.pack_size_g)::int end,
         pr.price_vnd,
         case when pr.id is null then null else ceil(net.buy_g / pr.pack_size_g)::int * pr.price_vnd end,
         case when pr.id is null then false
              else (pr.stock - pr.reserved) >= ceil(net.buy_g / pr.pack_size_g)::int end,
         coalesce(pr.allergen_ids && v_alg, false)
  from net
  join ingredients ig on ig.id = net.ingredient_id and not ('water' = any(ig.tags))
  left join lateral (
    select p.* from products p
    where p.ingredient_id = net.ingredient_id and p.is_active and p.pack_size_g is not null
    order by (p.stock - p.reserved > 0) desc, p.price_vnd / p.pack_size_g asc
    limit 1) pr on true
  order by ig.category nulls last, ig.name_vi;
end $$;
revoke all on function public.rpc_shopping_list(jsonb) from public, anon;
grant execute on function public.rpc_shopping_list(jsonb) to authenticated;

-- Thêm toàn bộ nguyên liệu cần mua của các công thức vào giỏ
create or replace function public.rpc_cart_add_from_recipes(p_items jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_cart uuid; v_added int := 0; v_skipped int; v_flags jsonb;
begin
  v_cart := public.rpc_ensure_cart();
  with src as (
    select sl.product_id, sum(sl.qty)::int as q
    from public.rpc_shopping_list(p_items) sl
    where sl.product_id is not null and sl.qty > 0 and sl.in_stock
    group by sl.product_id)
  insert into cart_items(cart_id, product_id, qty)
  select v_cart, s.product_id, least(s.q, 99) from src s
  on conflict (cart_id, product_id) do update set qty = least(cart_items.qty + excluded.qty, 99);
  get diagnostics v_added = row_count;

  select count(*) into v_skipped from public.rpc_shopping_list(p_items) sl
   where sl.qty > 0 and (sl.product_id is null or not sl.in_stock);
  select coalesce(jsonb_agg(sl.ingredient_name), '[]'::jsonb) into v_flags
    from public.rpc_shopping_list(p_items) sl where sl.allergen_conflict;
  return jsonb_build_object('added', v_added, 'skipped', v_skipped, 'allergen_flags', v_flags);
end $$;
revoke all on function public.rpc_cart_add_from_recipes(jsonb) from public, anon;
grant execute on function public.rpc_cart_add_from_recipes(jsonb) to authenticated;

-- ---------- 3. BÁO GIÁ (phí ship + mã giảm giá) ----------
create or replace function public._calc_quote(p_cart uuid, p_province text, p_coupon text)
returns table (subtotal bigint, shipping bigint, discount bigint, coupon_code text, coupon_error text)
language plpgsql stable security definer set search_path = public as $$
#variable_conflict use_column
declare v_sub bigint; v_ship bigint; v_disc bigint := 0; cp coupons%rowtype; v_err text := null;
begin
  select coalesce(sum(p.price_vnd * ci.qty), 0) into v_sub
    from cart_items ci join products p on p.id = ci.product_id where ci.cart_id = p_cart;

  select case when v_sub >= coalesce(r.free_from_vnd, 9223372036854775807) then 0 else r.fee_vnd end into v_ship
    from shipping_rules r where r.is_active and (r.province = p_province or r.province = '*')
    order by (r.province = '*') limit 1;
  v_ship := coalesce(v_ship, 30000);

  if p_coupon is not null and btrim(p_coupon) <> '' then
    select * into cp from coupons c
     where c.code = upper(btrim(p_coupon)) and c.is_active
       and (c.starts_at is null or c.starts_at <= now()) and (c.ends_at is null or c.ends_at >= now())
       and (c.max_uses is null or c.used_count < c.max_uses) and v_sub >= c.min_order_vnd;
    if cp.code is null then v_err := 'COUPON_INVALID';
    else
      v_disc := least(v_sub, coalesce(cp.discount_vnd, 0)
                 + coalesce(least(v_sub * cp.discount_pct / 100, coalesce(cp.max_discount_vnd, 9223372036854775807)), 0));
    end if;
  end if;
  return query select v_sub, v_ship, v_disc, cp.code, v_err;
end $$;
revoke all on function public._calc_quote(uuid, text, text) from public, anon, authenticated;

create or replace function public.rpc_quote_order(p_province text, p_coupon text default null) returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_cart uuid; q record;
begin
  if auth.uid() is null then raise exception 'UNAUTHENTICATED'; end if;
  select id into v_cart from carts where user_id = auth.uid();
  if v_cart is null then raise exception 'EMPTY_CART'; end if;
  select * into q from public._calc_quote(v_cart, p_province, p_coupon);
  return jsonb_build_object('subtotal_vnd', q.subtotal, 'shipping_fee_vnd', q.shipping, 'discount_vnd', q.discount,
                            'total_vnd', q.subtotal + q.shipping - q.discount, 'coupon_error', q.coupon_error);
end $$;
revoke all on function public.rpc_quote_order(text, text) from public, anon;
grant execute on function public.rpc_quote_order(text, text) to authenticated;

-- ---------- 4. ĐẶT HÀNG (nguyên tử: khóa kho → tạo đơn → giữ chỗ) ----------
create or replace function public.rpc_place_order(p_address_id uuid, p_method payment_method,
                                                  p_coupon text default null, p_note text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_user uuid := auth.uid(); v_cart uuid; v_addr jsonb; v_order uuid; v_code text; r record; q record;
        v_total bigint;
begin
  if v_user is null then raise exception 'UNAUTHENTICATED'; end if;

  select to_jsonb(a) - 'user_id' - 'created_at' into v_addr
    from addresses a where a.id = p_address_id and a.user_id = v_user;
  if v_addr is null then raise exception 'ADDRESS_NOT_FOUND'; end if;

  select id into v_cart from carts where user_id = v_user;
  if v_cart is null or not exists (select 1 from cart_items where cart_id = v_cart) then raise exception 'EMPTY_CART'; end if;

  -- khóa sản phẩm theo thứ tự id (tránh deadlock) rồi kiểm tồn
  for r in select p.id, p.name, p.stock, p.reserved, p.is_active, ci.qty
           from cart_items ci join products p on p.id = ci.product_id
           where ci.cart_id = v_cart order by p.id for update of p loop
    if not r.is_active then raise exception 'PRODUCT_INACTIVE:%', r.name; end if;
    if r.stock - r.reserved < r.qty then raise exception 'OUT_OF_STOCK:%', r.name; end if;
  end loop;

  if p_coupon is not null and btrim(p_coupon) <> '' then
    perform 1 from coupons where code = upper(btrim(p_coupon)) for update;     -- tránh vượt lượt dùng
  end if;
  select * into q from public._calc_quote(v_cart, v_addr->>'province', p_coupon);
  if q.coupon_error is not null then raise exception '%', q.coupon_error; end if;
  v_total := q.subtotal + q.shipping - q.discount;

  insert into orders(user_id, payment_method, subtotal_vnd, shipping_fee_vnd, discount_vnd, total_vnd,
                     coupon_code, note, ship_snapshot)
  values (v_user, p_method, q.subtotal, q.shipping, q.discount, v_total, q.coupon_code, p_note, v_addr)
  returning id, code into v_order, v_code;

  insert into order_items(order_id, product_id, name_snapshot, unit_price_vnd, qty)
  select v_order, p.id, p.name, p.price_vnd, ci.qty
  from cart_items ci join products p on p.id = ci.product_id where ci.cart_id = v_cart;

  update products p set reserved = p.reserved + ci.qty
  from cart_items ci where ci.cart_id = v_cart and p.id = ci.product_id;

  if q.coupon_code is not null then update coupons set used_count = used_count + 1 where code = q.coupon_code; end if;

  insert into payments(order_id, provider, amount_vnd, status)
  values (v_order, p_method, v_total, case when p_method = 'cod' then 'unpaid' else 'pending' end::payment_status);

  delete from cart_items where cart_id = v_cart;
  insert into order_status_history(order_id, to_status, changed_by, note) values (v_order, 'pending', v_user, 'Khách đặt hàng');

  return jsonb_build_object('order_id', v_order, 'code', v_code, 'total_vnd', v_total, 'payment_method', p_method);
end $$;
revoke all on function public.rpc_place_order(uuid, payment_method, text, text) from public, anon;
grant execute on function public.rpc_place_order(uuid, payment_method, text, text) to authenticated;

-- ---------- 5. MÁY TRẠNG THÁI ĐƠN ----------
create or replace function public._order_transition_ok(a order_status, b order_status) returns boolean
language sql immutable as $$
  select (a, b) in (
    ('pending','confirmed'), ('pending','cancelled'),
    ('confirmed','preparing'), ('confirmed','cancelled'),
    ('preparing','shipping'), ('preparing','cancelled'),
    ('shipping','delivered'), ('delivered','completed'), ('delivered','refund_requested'),
    ('refund_requested','refunded'), ('refund_requested','completed'));
$$;

create or replace function public._apply_order_status(p_order uuid, p_to order_status, p_actor uuid, p_note text)
returns void language plpgsql security definer set search_path = public as $$
declare o orders%rowtype; v_note text := p_note;
begin
  select * into o from orders where id = p_order for update;
  if o.id is null then raise exception 'ORDER_NOT_FOUND'; end if;
  if o.status = p_to then return; end if;                                     -- idempotent
  if not _order_transition_ok(o.status, p_to) then raise exception 'INVALID_TRANSITION:%->%', o.status, p_to; end if;

  if p_to = 'confirmed' then              -- giữ chỗ → trừ kho thật
    update products p set stock = p.stock - oi.qty, reserved = p.reserved - oi.qty
      from order_items oi where oi.order_id = p_order and oi.product_id = p.id;
  elsif p_to = 'cancelled' then
    if o.status = 'pending' then          -- mới giữ chỗ
      update products p set reserved = p.reserved - oi.qty
        from order_items oi where oi.order_id = p_order and oi.product_id = p.id;
    else                                  -- đã trừ kho → hoàn kho
      update products p set stock = p.stock + oi.qty
        from order_items oi where oi.order_id = p_order and oi.product_id = p.id;
    end if;
    if o.payment_status = 'paid' then v_note := coalesce(p_note, '') || ' [CẦN HOÀN TIỀN thủ công]'; end if;
  elsif p_to = 'refunded' then
    update orders set payment_status = 'refunded' where id = p_order;
    update payments set status = 'refunded' where order_id = p_order and status = 'paid';
  elsif p_to = 'delivered' and o.payment_method = 'cod' then
    update orders set payment_status = 'paid' where id = p_order;             -- COD: thu tiền khi giao
    update payments set status = 'paid' where order_id = p_order and status <> 'paid';
  end if;

  update orders set status = p_to where id = p_order;
  insert into order_status_history(order_id, from_status, to_status, changed_by, note)
  values (p_order, o.status, p_to, p_actor, v_note);
end $$;
revoke all on function public._apply_order_status(uuid, order_status, uuid, text) from public, anon, authenticated;

create or replace function public.rpc_set_order_status(p_order uuid, p_to order_status, p_note text default null,
                                                       p_tracking text default null, p_carrier text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.has_role(array['admin','staff']::app_role[]) then raise exception 'FORBIDDEN'; end if;
  perform public._apply_order_status(p_order, p_to, auth.uid(), p_note);
  if p_tracking is not null then update orders set tracking_code = p_tracking, carrier = p_carrier where id = p_order; end if;
  insert into audit_log(actor, action, entity, entity_id, meta)
  values (auth.uid(), 'order.status', 'orders', p_order::text, jsonb_build_object('to', p_to));
end $$;
revoke all on function public.rpc_set_order_status(uuid, order_status, text, text, text) from public, anon;
grant execute on function public.rpc_set_order_status(uuid, order_status, text, text, text) to authenticated;

create or replace function public.rpc_cancel_order(p_order uuid) returns void
language plpgsql security definer set search_path = public as $$
declare o orders%rowtype;
begin
  select * into o from orders where id = p_order and user_id = auth.uid();
  if o.id is null then raise exception 'ORDER_NOT_FOUND'; end if;
  if o.status not in ('pending','confirmed') then raise exception 'CANNOT_CANCEL'; end if;
  perform public._apply_order_status(p_order, 'cancelled', auth.uid(), 'Khách hủy đơn');
end $$;
revoke all on function public.rpc_cancel_order(uuid) from public, anon;
grant execute on function public.rpc_cancel_order(uuid) to authenticated;

-- Nhân viên xác nhận ĐÃ hoàn tiền cho đơn hủy đã thanh toán
create or replace function public.rpc_mark_refunded(p_order uuid, p_note text default null) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.has_role(array['admin','staff']::app_role[]) then raise exception 'FORBIDDEN'; end if;
  update orders set payment_status = 'refunded' where id = p_order and payment_status = 'paid';
  update payments set status = 'refunded' where order_id = p_order and status = 'paid';
  insert into order_status_history(order_id, from_status, to_status, changed_by, note)
    select id, status, status, auth.uid(), coalesce(p_note, 'Đã hoàn tiền') from orders where id = p_order;
  insert into audit_log(actor, action, entity, entity_id) values (auth.uid(), 'order.refund', 'orders', p_order::text);
end $$;
revoke all on function public.rpc_mark_refunded(uuid, text) from public, anon;
grant execute on function public.rpc_mark_refunded(uuid, text) to authenticated;

-- ---------- 6. XÁC NHẬN THANH TOÁN ONLINE (CHỈ service role gọi từ Edge Function IPN) ----------
create or replace function public.rpc_mark_paid(p_order_code text, p_provider payment_method,
                                                p_txn_id text, p_amount bigint, p_raw jsonb) returns text
language plpgsql security definer set search_path = public as $$
declare o orders%rowtype;
begin
  select * into o from orders where code = p_order_code for update;
  if o.id is null then return 'ORDER_NOT_FOUND'; end if;
  if o.total_vnd <> p_amount then return 'AMOUNT_MISMATCH'; end if;
  if o.payment_status = 'paid' or exists (select 1 from payments where provider = p_provider and provider_txn_id = p_txn_id)
    then return 'ALREADY_PROCESSED'; end if;                                  -- idempotent
  if o.status <> 'pending' then return 'INVALID_STATE'; end if;

  update payments set status = 'paid', provider_txn_id = p_txn_id, raw_payload = p_raw
   where order_id = o.id and provider = p_provider;
  update orders set payment_status = 'paid' where id = o.id;
  perform public._apply_order_status(o.id, 'confirmed', null, 'Thanh toán online thành công');
  return 'OK';
end $$;
revoke all on function public.rpc_mark_paid(text, payment_method, text, bigint, jsonb) from public, anon, authenticated;
grant execute on function public.rpc_mark_paid(text, payment_method, text, bigint, jsonb) to service_role;

-- ---------- 7. TỰ HỦY ĐƠN ONLINE QUÁ HẠN THANH TOÁN (15 phút) ----------
create or replace function public.job_expire_unpaid_orders() returns int
language plpgsql security definer set search_path = public as $$
declare r record; n int := 0;
begin
  for r in select id from orders
           where status = 'pending' and payment_method in ('vnpay','momo','bank_transfer')
             and payment_status <> 'paid' and created_at < now() - interval '15 minutes' loop
    perform public._apply_order_status(r.id, 'cancelled', null, 'Quá hạn thanh toán');
    n := n + 1;
  end loop;
  return n;
end $$;
revoke all on function public.job_expire_unpaid_orders() from public, anon, authenticated;

do $$ begin
  perform cron.schedule('expire-unpaid-orders', '*/5 * * * *', $q$select public.job_expire_unpaid_orders()$q$);
exception when others then raise notice 'pg_cron chưa khả dụng: %', sqlerrm;
end $$;

-- ---------- 8. QUYỀN RIÊNG TƯ ----------
-- Xuất dữ liệu: bổ sung địa chỉ & đơn hàng
create or replace function public.rpc_export_my_data() returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'profile',      (select to_jsonb(p) from profiles p where p.id = auth.uid()),
    'conditions',   (select coalesce(jsonb_agg(to_jsonb(c)), '[]') from user_health_conditions c where c.user_id = auth.uid()),
    'allergies',    (select coalesce(jsonb_agg(to_jsonb(a)), '[]') from user_allergies a where a.user_id = auth.uid()),
    'body_metrics', (select coalesce(jsonb_agg(to_jsonb(b)), '[]') from body_metrics b where b.user_id = auth.uid()),
    'favorites',    (select coalesce(jsonb_agg(to_jsonb(f)), '[]') from favorites f where f.user_id = auth.uid()),
    'feedback',     (select coalesce(jsonb_agg(to_jsonb(f)), '[]') from recipe_feedback f where f.user_id = auth.uid()),
    'food_logs',    (select coalesce(jsonb_agg(to_jsonb(l)), '[]') from food_logs l where l.user_id = auth.uid()),
    'addresses',    (select coalesce(jsonb_agg(to_jsonb(a)), '[]') from addresses a where a.user_id = auth.uid()),
    'orders',       (select coalesce(jsonb_agg(to_jsonb(o)), '[]') from orders o where o.user_id = auth.uid()),
    'ai_runs',      (select coalesce(jsonb_agg(jsonb_build_object('at', r.created_at, 'input', r.input)), '[]')
                       from ai_runs r where r.user_id = auth.uid()));
$$;
revoke all on function public.rpc_export_my_data() from public, anon;
grant execute on function public.rpc_export_my_data() to authenticated;

-- Ẩn danh hóa đơn hàng trước khi xóa tài khoản (đơn được giữ làm chứng từ, bỏ thông tin cá nhân)
create or replace function public.rpc_anonymize_user_orders(p_user uuid) returns int
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  update orders set ship_snapshot = jsonb_build_object('anonymized', true, 'province', ship_snapshot->>'province'),
                    note = null
   where user_id = p_user;
  get diagnostics n = row_count;
  return n;
end $$;
revoke all on function public.rpc_anonymize_user_orders(uuid) from public, anon, authenticated;
grant execute on function public.rpc_anonymize_user_orders(uuid) to service_role;

