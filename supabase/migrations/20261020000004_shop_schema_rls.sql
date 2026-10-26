-- =====================================================================
-- NutriCook · Migration 4 · CỬA HÀNG NGUYÊN LIỆU, GIỎ HÀNG, ĐƠN HÀNG, THANH TOÁN
-- Liên kết với công thức: nguyên liệu (ingredients) → sản phẩm bán (products)
-- Nguyên tắc: khách KHÔNG ghi trực tiếp orders/payments/products.stock;
--             mọi thay đổi tiền/kho/trạng thái đi qua RPC (migration 005) hoặc service role.
-- =====================================================================

create type order_status   as enum ('pending','confirmed','preparing','shipping','delivered','completed','cancelled','refund_requested','refunded');
create type payment_method as enum ('cod','bank_transfer','vnpay','momo');
create type payment_status as enum ('unpaid','pending','paid','failed','refunded');

-- ---------- ĐỊA CHỈ & NGUYÊN LIỆU ĐANG CÓ ----------
create table public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  receiver_name text not null check (char_length(receiver_name) between 1 and 100),
  phone text not null check (phone ~ '^[0-9+ ()-]{8,20}$'),
  province text not null, district text not null, ward text not null,
  street text not null check (char_length(street) <= 200),
  note text check (note is null or char_length(note) <= 300),
  is_default boolean not null default false,
  created_at timestamptz default now()
);
create unique index one_default_address on public.addresses(user_id) where is_default;

create table public.pantry_items (                    -- nguyên liệu người dùng đã có ở nhà (trừ khỏi danh sách cần mua)
  user_id uuid references public.profiles(id) on delete cascade,
  ingredient_id uuid references public.ingredients(id) on delete cascade,
  amount_g numeric(8,1) not null check (amount_g >= 0),
  primary key (user_id, ingredient_id)
);

-- ---------- SẢN PHẨM ----------
create table public.product_categories (
  id smallserial primary key, name text not null, slug text unique not null
);
create table public.products (
  id uuid primary key default gen_random_uuid(),
  sku text unique not null, name text not null, slug text unique not null,
  description text, image_url text,
  category_id smallint references public.product_categories(id),
  ingredient_id uuid references public.ingredients(id),     -- ánh xạ sang nguyên liệu công thức
  recipe_id uuid references public.recipes(id),             -- gói nguyên liệu theo công thức (meal kit)
  kind text not null default 'ingredient' check (kind in ('ingredient','meal_kit','ready_meal')),
  unit text not null,                                       -- 'túi 1 kg', 'bó', 'khay'
  pack_size_g numeric(8,1) check (pack_size_g is null or pack_size_g > 0),  -- 1 đơn vị bán = bao nhiêu gram
  price_vnd bigint not null check (price_vnd >= 0),
  stock int not null default 0 check (stock >= 0),
  reserved int not null default 0 check (reserved >= 0),
  allergen_ids smallint[] not null default '{}',            -- tự đồng bộ từ nguyên liệu/công thức
  is_active boolean not null default true,
  created_at timestamptz default now(), updated_at timestamptz default now(),
  check (stock >= reserved)
);
create index products_ingredient_idx on public.products(ingredient_id) where is_active;
create trigger t_products_upd before update on public.products
  for each row execute function public.set_updated_at();

create or replace function public.products_sync_allergens() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.ingredient_id is not null then
    select coalesce(array_agg(allergen_id), '{}')::smallint[] into new.allergen_ids
      from ingredient_allergens where ingredient_id = new.ingredient_id;
  elsif new.recipe_id is not null then
    select coalesce(allergen_ids, '{}') into new.allergen_ids from recipes where id = new.recipe_id;
  end if;
  return new;
end $$;
create trigger t_products_allergens before insert or update of ingredient_id, recipe_id on public.products
  for each row execute function public.products_sync_allergens();

-- ---------- GIỎ HÀNG ----------
create table public.carts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references public.profiles(id) on delete cascade,
  updated_at timestamptz default now()
);
create table public.cart_items (
  cart_id uuid references public.carts(id) on delete cascade,
  product_id uuid references public.products(id) on delete cascade,
  qty int not null check (qty between 1 and 99),
  primary key (cart_id, product_id)
);

-- ---------- MÃ GIẢM GIÁ & PHÍ VẬN CHUYỂN ----------
create table public.coupons (
  code text primary key check (code = upper(code)),
  discount_pct int check (discount_pct between 1 and 100),
  discount_vnd bigint check (discount_vnd >= 0),
  max_discount_vnd bigint,                               -- trần cho giảm theo %
  min_order_vnd bigint not null default 0,
  max_uses int, used_count int not null default 0,
  starts_at timestamptz, ends_at timestamptz, is_active boolean not null default true,
  check (discount_pct is not null or discount_vnd is not null)
);
create table public.shipping_rules (
  id serial primary key,
  province text not null,                                -- '*' = mặc định
  fee_vnd bigint not null check (fee_vnd >= 0), free_from_vnd bigint,
  is_active boolean not null default true
);

-- ---------- ĐƠN HÀNG ----------
create sequence public.order_code_seq start 100000;
create table public.orders (
  id uuid primary key default gen_random_uuid(),
  code text unique not null default ('NC' || nextval('public.order_code_seq')),
  user_id uuid references public.profiles(id) on delete set null,   -- giữ đơn làm chứng từ khi xóa tài khoản
  status order_status not null default 'pending',
  payment_method payment_method not null,
  payment_status payment_status not null default 'unpaid',
  subtotal_vnd bigint not null check (subtotal_vnd >= 0),
  shipping_fee_vnd bigint not null default 0 check (shipping_fee_vnd >= 0),
  discount_vnd bigint not null default 0 check (discount_vnd >= 0),
  total_vnd bigint not null check (total_vnd >= 0),
  coupon_code text, note text check (note is null or char_length(note) <= 500),
  ship_snapshot jsonb not null,                          -- địa chỉ tại thời điểm đặt (ẩn danh hóa khi xóa tài khoản)
  tracking_code text, carrier text,
  created_at timestamptz default now(), updated_at timestamptz default now()
);
create index orders_user_idx on public.orders(user_id, created_at desc);
create index orders_status_idx on public.orders(status, created_at);
create trigger t_orders_upd before update on public.orders
  for each row execute function public.set_updated_at();

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid not null references public.products(id),
  name_snapshot text not null, unit_price_vnd bigint not null check (unit_price_vnd >= 0),
  qty int not null check (qty > 0),
  line_total_vnd bigint generated always as (unit_price_vnd * qty) stored
);
create table public.order_status_history (
  id bigserial primary key,
  order_id uuid not null references public.orders(id) on delete cascade,
  from_status order_status, to_status order_status not null,
  changed_by uuid, note text, created_at timestamptz default now()
);
create table public.payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  provider payment_method not null,
  amount_vnd bigint not null check (amount_vnd >= 0),
  status payment_status not null default 'pending',
  provider_txn_id text, raw_payload jsonb,
  created_at timestamptz default now(),
  unique (provider, provider_txn_id)                     -- chống xử lý webhook lặp (idempotent)
);

-- =====================================================================
-- RLS
-- =====================================================================
alter table public.addresses            enable row level security;
alter table public.pantry_items         enable row level security;
alter table public.product_categories   enable row level security;
alter table public.products             enable row level security;
alter table public.carts                enable row level security;
alter table public.cart_items           enable row level security;
alter table public.coupons              enable row level security;
alter table public.shipping_rules       enable row level security;
alter table public.orders               enable row level security;
alter table public.order_items          enable row level security;
alter table public.order_status_history enable row level security;
alter table public.payments             enable row level security;

create policy own_rows on public.addresses    for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_rows on public.pantry_items for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy pub_read on public.product_categories for select using (true);
create policy staff_write on public.product_categories for all to authenticated
  using (public.has_role(array['admin','staff']::app_role[])) with check (public.has_role(array['admin','staff']::app_role[]));

create policy pub_read on public.products for select
  using (is_active or public.has_role(array['admin','staff']::app_role[]));
create policy staff_write on public.products for all to authenticated
  using (public.has_role(array['admin','staff']::app_role[])) with check (public.has_role(array['admin','staff']::app_role[]));

create policy own_cart on public.carts for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_cart_items on public.cart_items for all to authenticated
  using (exists (select 1 from public.carts c where c.id = cart_id and c.user_id = auth.uid()))
  with check (exists (select 1 from public.carts c where c.id = cart_id and c.user_id = auth.uid()));

-- mã giảm giá: khách KHÔNG đọc được danh sách (chỉ qua RPC); admin quản lý
create policy admin_all on public.coupons for all to authenticated
  using (public.has_role(array['admin']::app_role[])) with check (public.has_role(array['admin']::app_role[]));
create policy pub_read on public.shipping_rules for select using (is_active);
create policy admin_write on public.shipping_rules for all to authenticated
  using (public.has_role(array['admin']::app_role[])) with check (public.has_role(array['admin']::app_role[]));

-- đơn hàng: khách chỉ ĐỌC đơn của mình; staff/admin đọc tất cả. KHÔNG có policy ghi.
create policy read_own_or_staff on public.orders for select to authenticated
  using (user_id = auth.uid() or public.has_role(array['admin','staff']::app_role[]));
create policy read_own_or_staff on public.order_items for select to authenticated
  using (exists (select 1 from public.orders o where o.id = order_id
         and (o.user_id = auth.uid() or public.has_role(array['admin','staff']::app_role[]))));
create policy read_own_or_staff on public.order_status_history for select to authenticated
  using (exists (select 1 from public.orders o where o.id = order_id
         and (o.user_id = auth.uid() or public.has_role(array['admin','staff']::app_role[]))));
create policy read_own_or_staff on public.payments for select to authenticated
  using (exists (select 1 from public.orders o where o.id = order_id
         and (o.user_id = auth.uid() or public.has_role(array['admin','staff']::app_role[]))));

-- Storage: ảnh sản phẩm
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('product-images','product-images', true, 2097152, '{image/webp,image/jpeg,image/png}')
on conflict (id) do nothing;
create policy "product_img_public_read" on storage.objects for select using (bucket_id = 'product-images');
create policy "product_img_staff_write" on storage.objects for insert to authenticated
  with check (bucket_id = 'product-images' and public.has_role(array['admin','staff']::app_role[]));
create policy "product_img_staff_update" on storage.objects for update to authenticated
  using (bucket_id = 'product-images' and public.has_role(array['admin','staff']::app_role[]));

-- Realtime: khách nhận cập nhật trạng thái đơn của mình (RLS vẫn áp dụng)
do $$ begin
  alter publication supabase_realtime add table public.orders;
exception when others then raise notice 'Bỏ qua realtime: %', sqlerrm;
end $$;

