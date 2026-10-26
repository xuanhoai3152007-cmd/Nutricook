-- =====================================================================
-- NutriCook · Migration 6 · CHUYỂN TỪ DEMO SANG CHÍNH THỨC
-- - app_settings: cờ demo_mode / payments_live / shop_enabled / ai_enabled (nguồn sự thật DUY NHẤT)
-- - Trạng thái XÁC MINH cho nguyên liệu (dinh dưỡng), công thức (nấu thử), sản phẩm (giá, khối lượng tịnh, dị ứng)
-- - Lịch sử giá
-- - rpc_go_live_check(): danh sách việc chặn phát hành
-- - rpc_set_app_setting(): chỉ tắt demo_mode khi KHÔNG còn việc chặn
-- Không sửa migration cũ; chỉ thêm và thay hàm bằng CREATE OR REPLACE.
-- =====================================================================

-- ---------- 1. CỜ CẤU HÌNH ----------
create table public.app_settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id)
);
insert into public.app_settings(key, value) values
  ('demo_mode', 'true'), ('payments_live', 'false'), ('shop_enabled', 'true'), ('ai_enabled', 'true')
on conflict (key) do nothing;
alter table public.app_settings enable row level security;
create policy pub_read on public.app_settings for select using (true);   -- không có policy ghi: chỉ qua RPC
revoke all on table public.app_settings from public, anon, authenticated;
grant select on table public.app_settings to anon, authenticated;

create or replace function public.app_setting_bool(p_key text, p_default boolean default false) returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select (value)::text::boolean from app_settings where key = p_key), p_default)
$$;
revoke all on function public.app_setting_bool(text, boolean) from public;
grant execute on function public.app_setting_bool(text, boolean) to anon, authenticated, service_role;

-- ---------- 2. XÁC MINH DINH DƯỠNG NGUYÊN LIỆU ----------
alter table public.ingredients
  add column if not exists source_ref     text,          -- mã/ID thực phẩm trong nguồn (vd FDC ID, mã bảng TPTP VN)
  add column if not exists source_version text,          -- phiên bản/năm của nguồn
  add column if not exists data_status    text not null default 'unverified'
        check (data_status in ('unverified','verified','rejected')),
  add column if not exists verified_by    uuid references public.profiles(id),
  add column if not exists verified_at    timestamptz;

alter table public.ingredients drop constraint if exists ingredients_verified_needs_source;
alter table public.ingredients add constraint ingredients_verified_needs_source check (
  data_status <> 'verified' or (
    nullif(btrim(source_ref), '') is not null
    and nullif(btrim(source_version), '') is not null
    and nullif(btrim(source), '') is not null
    and source <> 'seed_estimate'
  ));

-- Kiểm tra tính hợp lý của số liệu (trả về mô tả lỗi, rỗng nếu ổn)
create or replace function public.ingredient_sanity(i public.ingredients) returns text
language plpgsql immutable as $$
declare issues text[] := '{}'; atwater numeric;
begin
  -- carb "theo hiệu số" đã gồm chất xơ (≈ 2 kcal/g) nên điều chỉnh: 4·đạm + 9·béo + 4·(carb − xơ) + 2·xơ
  atwater := 4*coalesce(i.protein_g,0) + 9*coalesce(i.fat_g,0)
           + 4*greatest(coalesce(i.carb_g,0) - coalesce(i.fiber_g,0), 0) + 2*least(coalesce(i.fiber_g,0), coalesce(i.carb_g,0));
  if abs(i.kcal - atwater) > greatest(0.15 * i.kcal, 15) then
    issues := issues || format('kcal %s lệch quá 15%% so với ước tính theo đạm/béo/carb/xơ = %s', i.kcal, round(atwater,1)); end if;
  if coalesce(i.protein_g,0) + coalesce(i.carb_g,0) + coalesce(i.fat_g,0) > 100.5 then
    issues := issues || 'tổng đạm+carb+béo vượt 100 g/100 g'; end if;
  if coalesce(i.sat_fat_g,0) > coalesce(i.fat_g,0) + 0.05 then issues := issues || 'béo bão hòa lớn hơn tổng béo'; end if;
  if coalesce(i.sugar_g,0)   > coalesce(i.carb_g,0) + 0.05 then issues := issues || 'đường lớn hơn tổng carb'; end if;
  if coalesce(i.fiber_g,0)   > coalesce(i.carb_g,0) + 0.05 then issues := issues || 'chất xơ lớn hơn tổng carb'; end if;
  if coalesce(i.sodium_mg,0) < 0 or coalesce(i.sodium_mg,0) > 40000 then issues := issues || 'natri ngoài khoảng 0–40.000 mg'; end if;
  return array_to_string(issues, '; ');
end $$;

create or replace function public.trg_ingredient_verify() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_issue text;
begin
  if new.data_status = 'verified' and (tg_op = 'INSERT' or old.data_status is distinct from 'verified') then
    if auth.uid() is not null and not has_role(array['admin','nutritionist']::app_role[]) then raise exception 'FORBIDDEN'; end if;
    v_issue := ingredient_sanity(new);
    if v_issue <> '' then raise exception 'INGREDIENT_SANITY: %', v_issue; end if;
    new.verified_by := coalesce(auth.uid(), new.verified_by);
    new.verified_at := now();
  elsif tg_op = 'UPDATE' and old.data_status = 'verified' and new.data_status = 'verified'
        and (row(new.name_vi,new.name_en,new.category,new.kcal,new.protein_g,new.carb_g,new.fat_g,new.sat_fat_g,
                 new.fiber_g,new.sugar_g,new.sodium_mg,new.purine_level,new.glycemic_index,new.tags,new.source,
                 new.source_ref,new.source_version)
             is distinct from
             row(old.name_vi,old.name_en,old.category,old.kcal,old.protein_g,old.carb_g,old.fat_g,old.sat_fat_g,
                 old.fiber_g,old.sugar_g,old.sodium_mg,old.purine_level,old.glycemic_index,old.tags,old.source,
                 old.source_ref,old.source_version)) then
    new.data_status := 'unverified';          -- đổi số liệu đã xác minh → phải xác minh lại
    new.verified_by := null; new.verified_at := null;
  elsif tg_op = 'UPDATE' and old.data_status = 'verified' and new.data_status = 'verified' then
    new.verified_by := old.verified_by;
    new.verified_at := old.verified_at;
  elsif new.data_status <> 'verified' then
    new.verified_by := null;
    new.verified_at := null;
  end if;
  return new;
end $$;
create trigger t_ingredient_verify before insert or update on public.ingredients
  for each row execute function public.trg_ingredient_verify();

-- ---------- 3. CÔNG THỨC: NẤU THỬ + XUẤT BẢN THEO CHẾ ĐỘ ----------
alter table public.recipes
  add column if not exists test_cooked_by uuid references public.profiles(id),
  add column if not exists test_cooked_at timestamptz,
  add column if not exists test_notes     text,           -- ghi chú nấu thử: thời gian thực tế, khối lượng sau nấu, điều chỉnh
  add column if not exists cooked_yield_g numeric(8,1);   -- khối lượng thành phẩm khi nấu thử

create or replace function public.trg_recipe_publish_guard() returns trigger
language plpgsql security definer set search_path = public as $$
declare n_steps int; n_ing int; n_short int; n_prep int; n_unverified int; v_demo boolean;
begin
  if new.status = 'published' and old.status is distinct from 'published' then
    if auth.uid() is not null and not has_role(array['admin','nutritionist']::app_role[]) then
      raise exception 'FORBIDDEN'; end if;
    select count(*), count(*) filter (where char_length(instruction) < 20), count(*) filter (where phase = 'prep')
      into n_steps, n_short, n_prep from recipe_steps where recipe_id = new.id;
    select count(*) into n_ing from recipe_ingredients where recipe_id = new.id;
    if n_ing < 3   then raise exception 'NEED_3_INGREDIENTS'; end if;
    if n_steps < 4 then raise exception 'NEED_4_STEPS'; end if;
    if n_prep < 1  then raise exception 'NEED_PREP_STEP'; end if;
    if n_short > 0 then raise exception 'STEP_TOO_SHORT'; end if;
    if new.image_url is null then raise exception 'NEED_IMAGE'; end if;
    if new.kcal is null then raise exception 'NUTRITION_MISSING'; end if;
    if cardinality(new.equipment) = 0 then raise exception 'NEED_EQUIPMENT'; end if;

    v_demo := app_setting_bool('demo_mode', true);
    if not v_demo then                                   -- CHẾ ĐỘ CHÍNH THỨC: yêu cầu chặt hơn
      select count(*) into n_unverified from recipe_ingredients ri join ingredients i on i.id = ri.ingredient_id
       where ri.recipe_id = new.id and i.data_status <> 'verified';
      if n_unverified > 0 then raise exception 'INGREDIENT_NOT_VERIFIED:%', n_unverified; end if;
      if new.test_cooked_at is null or new.test_cooked_by is null then raise exception 'NEED_TEST_COOK'; end if;
      if auth.uid() is null then raise exception 'NEED_REVIEWER'; end if;     -- bắt buộc có người duyệt thật
      if new.test_cooked_by = auth.uid() then raise exception 'NEED_INDEPENDENT_REVIEWER'; end if;
    end if;
    new.reviewed_by := auth.uid(); new.published_at := now();
  end if;
  return new;
end $$;

-- Sửa nguyên liệu/bước của công thức ĐÃ XUẤT BẢN (ở chế độ chính thức) → đưa về 'review' để duyệt lại
create or replace function public.trg_recipe_content_changed() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if not app_setting_bool('demo_mode', true) then
    if tg_op <> 'INSERT' then
      update recipes set status = 'review', reviewed_by = null where id = old.recipe_id and status = 'published';
    end if;
    if tg_op <> 'DELETE' and (tg_op <> 'UPDATE' or new.recipe_id is distinct from old.recipe_id) then
      update recipes set status = 'review', reviewed_by = null where id = new.recipe_id and status = 'published';
    end if;
  end if;
  return null;
end $$;
create trigger t_ri_changed after insert or update or delete on public.recipe_ingredients
  for each row execute function public.trg_recipe_content_changed();
create trigger t_rs_changed after insert or update or delete on public.recipe_steps
  for each row execute function public.trg_recipe_content_changed();

-- ---------- 4. SẢN PHẨM: GIÁ, KHỐI LƯỢNG TỊNH, DỊ ỨNG ĐÃ XÁC NHẬN ----------
alter table public.products
  add column if not exists supplier text,
  add column if not exists cost_vnd bigint check (cost_vnd is null or cost_vnd >= 0),   -- giá vốn
  add column if not exists vat_rate numeric(4,2) check (vat_rate is null or vat_rate between 0 and 1),
  add column if not exists price_source text,                      -- báo giá/hóa đơn/hợp đồng nhà cung cấp
  add column if not exists price_updated_at timestamptz,
  add column if not exists price_status text not null default 'unverified' check (price_status in ('unverified','verified')),
  add column if not exists net_weight_verified boolean not null default false,   -- pack_size_g là khối lượng tịnh đã cân/ghi trên nhãn
  add column if not exists allergen_verified boolean not null default false,     -- dị ứng đã đối chiếu nhãn nhà cung cấp
  add column if not exists label_note text;                         -- nguồn gốc, hạn dùng, bảo quản

create table public.price_history (
  id bigserial primary key,
  product_id uuid not null references public.products(id) on delete cascade,
  old_price_vnd bigint, new_price_vnd bigint not null,
  changed_by uuid, changed_at timestamptz not null default now()
);
alter table public.price_history enable row level security;
create policy staff_read on public.price_history for select to authenticated
  using (public.has_role(array['admin','staff']::app_role[]));
revoke all on table public.price_history from public, anon, authenticated;
grant select on table public.price_history to authenticated;

-- BEFORE: đóng dấu thời gian và đưa về "chưa xác minh" khi đổi giá
create or replace function public.trg_product_price_stamp() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    new.price_updated_at := now();
    new.price_status := 'unverified';
    new.net_weight_verified := false;
    new.allergen_verified := false;
  elsif row(new.price_vnd,new.cost_vnd,new.vat_rate,new.price_source,new.supplier)
        is distinct from row(old.price_vnd,old.cost_vnd,old.vat_rate,old.price_source,old.supplier) then
    new.price_updated_at := now();
    new.price_status := 'unverified';
  end if;
  if tg_op = 'UPDATE' and row(new.pack_size_g,new.unit) is distinct from row(old.pack_size_g,old.unit) then
    new.net_weight_verified := false;
  end if;
  if tg_op = 'UPDATE' and row(new.ingredient_id,new.allergen_ids,new.label_note)
        is distinct from row(old.ingredient_id,old.allergen_ids,old.label_note) then
    new.allergen_verified := false;
  end if;
  return new;
end $$;
create trigger t_product_price_stamp before insert or update on public.products
  for each row execute function public.trg_product_price_stamp();

-- AFTER: ghi lịch sử giá (sau khi dòng sản phẩm đã tồn tại để thỏa khóa ngoại)
create or replace function public.trg_product_price_log() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' or new.price_vnd is distinct from old.price_vnd then
    insert into price_history(product_id, old_price_vnd, new_price_vnd, changed_by)
    values (new.id, case when tg_op = 'UPDATE' then old.price_vnd end, new.price_vnd, auth.uid());
  end if;
  return null;
end $$;
create trigger t_product_price_log after insert or update on public.products
  for each row execute function public.trg_product_price_log();

-- Chế độ chính thức: KHÔNG cho đặt sản phẩm chưa xác minh giá/khối lượng/dị ứng
create or replace function public.trg_order_item_verified() returns trigger
language plpgsql security definer set search_path = public as $$
declare p products%rowtype;
begin
  if not app_setting_bool('demo_mode', true) then
    select * into p from products where id = new.product_id;
    if p.price_status <> 'verified' or not p.net_weight_verified or not p.allergen_verified then
      raise exception 'PRODUCT_NOT_VERIFIED:%', p.name;
    end if;
  end if;
  return new;
end $$;
create trigger t_order_item_verified before insert on public.order_items
  for each row execute function public.trg_order_item_verified();

create or replace function public.trg_shop_enabled() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if not app_setting_bool('shop_enabled', false) then
    raise exception 'SHOP_DISABLED';
  end if;
  if new.payment_method = 'vnpay' and not app_setting_bool('payments_live', false) then
    raise exception 'PAYMENTS_DISABLED';
  end if;
  return new;
end $$;
create trigger t_shop_enabled before insert on public.orders
  for each row execute function public.trg_shop_enabled();

-- ---------- 5. KIỂM TRA SẴN SÀNG PHÁT HÀNH ----------
create or replace function public.rpc_go_live_check()
returns table (code text, label text, severity text, bad_count bigint)
language plpgsql stable security definer set search_path = public as $$
begin
  if not has_role(array['admin']::app_role[]) then raise exception 'FORBIDDEN'; end if;
  return query
  select 'ING_UNVERIFIED'::text, 'Nguyên liệu dùng trong công thức đã xuất bản nhưng CHƯA xác minh dinh dưỡng'::text, 'blocker'::text,
         (select count(distinct i.id) from ingredients i
           join recipe_ingredients ri on ri.ingredient_id = i.id join recipes r on r.id = ri.recipe_id and r.status = 'published'
          where i.data_status <> 'verified')
  union all
  select 'REC_NOT_REVIEWED', 'Công thức đã xuất bản nhưng chưa có người duyệt hoặc chưa nấu thử', 'blocker',
         (select count(*) from recipes where status = 'published' and (reviewed_by is null or test_cooked_at is null))
  union all
  select 'RULES_UNAPPROVED', 'Quy tắc bệnh lý đang bật nhưng chưa được chuyên gia duyệt', 'blocker',
         (select count(*) from condition_rules where is_active and (approved_at is null or approved_by is null))
  union all
  select 'PROD_UNVERIFIED', 'Sản phẩm đang bán chưa xác minh giá/khối lượng tịnh/dị ứng', 'blocker',
         (select count(*) from products where is_active and (price_status <> 'verified' or not net_weight_verified or not allergen_verified))
  union all
  select 'SHIPPING_MISSING', 'Chưa có quy tắc phí vận chuyển mặc định (province = *)', 'blocker',
         (select case when exists (select 1 from shipping_rules where is_active and province = '*') then 0 else 1 end)
  union all
  select 'NO_ADMIN', 'Chưa có tài khoản admin', 'blocker',
         (select case when exists (select 1 from profiles where role = 'admin') then 0 else 1 end)
  union all
  select 'NO_NUTRITIONIST', 'Chưa có tài khoản nutritionist để duyệt nội dung', 'blocker',
         (select case when exists (select 1 from profiles where role = 'nutritionist') then 0 else 1 end)
  union all
  select 'ING_NO_PRODUCT', 'Nguyên liệu (không tùy chọn) trong công thức đã xuất bản chưa có sản phẩm đang bán', 'warning',
         (select count(distinct i.id) from ingredients i
           join recipe_ingredients ri on ri.ingredient_id = i.id and not ri.optional
           join recipes r on r.id = ri.recipe_id and r.status = 'published'
          where not ('water' = any(i.tags))
            and not exists (select 1 from products p where p.ingredient_id = i.id and p.is_active))
  union all
  select 'PROD_NO_IMAGE', 'Sản phẩm đang bán chưa có ảnh', 'warning',
         (select count(*) from products where is_active and image_url is null)
  union all
  select 'RECIPE_COUNT_LOW', 'Số công thức đã xuất bản dưới 50', 'warning',
         (select case when count(*) < 50 then 50 - count(*) else 0 end from recipes where status = 'published')
  union all
  select 'PAYMENTS_NOT_LIVE', 'Cổng thanh toán chưa bật chế độ thật (payments_live = false)', 'warning',
         (select case when app_setting_bool('payments_live', false) then 0 else 1 end);
end $$;
revoke all on function public.rpc_go_live_check() from public, anon;
grant execute on function public.rpc_go_live_check() to authenticated;

-- ---------- 6. ĐỔI CỜ CẤU HÌNH (CÓ CỔNG KIỂM TRA) ----------
create or replace function public.rpc_set_app_setting(p_key text, p_value jsonb) returns void
language plpgsql security definer set search_path = public as $$
declare v_blockers text;
begin
  if not has_role(array['admin']::app_role[]) then raise exception 'FORBIDDEN'; end if;
  if p_key not in ('demo_mode','payments_live','shop_enabled','ai_enabled') then raise exception 'UNKNOWN_SETTING'; end if;
  if jsonb_typeof(p_value) <> 'boolean' then raise exception 'INVALID_VALUE'; end if;

  if p_key = 'demo_mode' and p_value = 'true'::jsonb and not app_setting_bool('demo_mode', true) then
    raise exception 'DEMO_MODE_CANNOT_BE_REENABLED';
  end if;
  if p_key = 'demo_mode' and p_value = 'false'::jsonb then            -- tắt demo = phát hành chính thức
    select string_agg(g.code || '(' || g.bad_count || ')', ', ') into v_blockers
      from public.rpc_go_live_check() g where g.severity = 'blocker' and g.bad_count > 0;
    if v_blockers is not null then raise exception 'GO_LIVE_BLOCKED: %', v_blockers; end if;
  end if;
  if p_key = 'payments_live' and p_value = 'true'::jsonb and app_setting_bool('demo_mode', true) then
    raise exception 'DEMO_MODE_STILL_ON';                              -- chỉ bật thanh toán thật sau khi tắt demo
  end if;

  insert into app_settings(key, value, updated_by) values (p_key, p_value, auth.uid())
  on conflict (key) do update set value = excluded.value, updated_at = now(), updated_by = auth.uid();
  insert into audit_log(actor, action, entity, entity_id, meta)
  values (auth.uid(), 'setting.change', 'app_settings', p_key, jsonb_build_object('value', p_value));
end $$;
revoke all on function public.rpc_set_app_setting(text, jsonb) from public, anon;
grant execute on function public.rpc_set_app_setting(text, jsonb) to authenticated;
