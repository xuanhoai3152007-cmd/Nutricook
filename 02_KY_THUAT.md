# 02 — TÀI LIỆU KỸ THUẬT (Architecture & Backend)
## Dự án: NutriCook

> Đọc cùng: `01_PRD_NGHIEP_VU.md` (nghiệp vụ), `03_GIAO_DIEN_FRONTEND.md` (UI/FE), `04_AGENT.md` (quy trình cho AI agent).

---

## 1. QUYẾT ĐỊNH KIẾN TRÚC (ADR)

| # | Quyết định | Lý do | Đánh đổi |
|---|---|---|---|
| ADR-1 | **Frontend: React 18 + Vite + TypeScript** (SPA) | Nhanh, đơn giản, build tĩnh deploy Vercel | SEO công thức yếu hơn SSR → dùng prerender + meta + sitemap; nếu SEO thành ưu tiên, chuyển Next.js (cấu trúc thư mục giữ nguyên module) |
| ADR-2 | **Supabase** làm BaaS: Postgres, Auth, Storage, Realtime | Có sẵn auth/RLS/storage, giảm backend | Logic phức tạp cần Edge/Node |
| ADR-3 | **Node.js (TypeScript) trên Vercel Functions** thư mục `/api` cho logic cần bí mật: thanh toán, webhook, sinh thực đơn, gửi mail, admin | Giữ secret/service-role key ở server | Cold start; giữ function nhẹ |
| ADR-4 | Đọc dữ liệu công khai/cá nhân **trực tiếp từ Supabase qua RLS** (client SDK) | Ít code, nhanh | RLS phải chặt & có test |
| ADR-5 | Tính dinh dưỡng/gợi ý là **thư viện thuần TS dùng chung** (`packages/nutrition-core`) | Chạy ở cả FE (xem trước) và BE (nguồn sự thật), dễ unit test | Cần đồng bộ phiên bản |
| ADR-6 | Quy tắc bệnh lý là **dữ liệu** (`condition_rules`), không hard-code | Chuyên gia chỉnh không cần deploy | Cần versioning |
| ADR-7 | Tiền lưu **số nguyên VND** (bigint) | Tránh sai số | — |

---

## 2. KIẾN TRÚC TỔNG THỂ

```
┌────────────────────────────── Trình duyệt ──────────────────────────────┐
│  React SPA (Vite) · React Router · TanStack Query · Zustand · Tailwind  │
└───────┬─────────────────────────────────────────────────┬───────────────┘
        │ supabase-js (anon key + JWT, RLS)               │ fetch /api/* (Bearer JWT)
        ▼                                                 ▼
┌──────────────────────┐                       ┌───────────────────────────┐
│ SUPABASE             │◄──── service role ────│ VERCEL FUNCTIONS (Node)   │
│ • Auth (JWT, OAuth)  │                       │ • /api/mealplan/generate  │
│ • Postgres + RLS     │                       │ • /api/checkout           │
│ • Storage (ảnh)      │                       │ • /api/payments/*/webhook │
│ • Realtime (đơn)     │                       │ • /api/admin/*            │
│ • pg_cron / Triggers │                       │ • /api/email/*            │
└──────────────────────┘                       └───────┬───────────────────┘
                                                       ▼
                              VNPay/MoMo · Resend (email) · GHN/GHTK · Sentry
```

**Nguyên tắc:** (1) Client không bao giờ giữ `service_role`. (2) Mọi thao tác tiền/kho/trạng thái đơn đi qua server. (3) Mọi bảng bật RLS, mặc định từ chối.

---

## 3. CÔNG NGHỆ & PHIÊN BẢN

| Lớp | Công nghệ |
|---|---|
| Ngôn ngữ | TypeScript 5.x (strict) |
| Frontend | React 18, Vite 5, React Router 6, TanStack Query 5, Zustand, React Hook Form + Zod, Tailwind CSS 3, shadcn/ui (Radix), Recharts, dnd-kit, i18next, react-helmet-async |
| Backend | Node.js 20 LTS, Vercel Functions, Hono (router nhẹ) hoặc handler thuần, Zod |
| DB/Auth | Supabase (Postgres 15), `@supabase/supabase-js` v2 |
| Email | Resend (hoặc SendGrid) |
| Thanh toán | VNPay (sandbox → live), MoMo/ZaloPay (P1), COD, chuyển khoản QR VietQR |
| Vận chuyển | GHN/GHTK API (P1); MVP: nhập tay mã vận đơn |
| Test | Vitest, Testing Library, Playwright (E2E), pgTAP (RLS) |
| Chất lượng | ESLint, Prettier, Husky + lint-staged, commitlint |
| CI/CD | GitHub Actions + Vercel Git integration |
| Giám sát | Sentry, Vercel Analytics, PostHog/GA4 |

---

## 4. CẤU TRÚC MONOREPO

```
nutricook/
├─ apps/
│  └─ web/                         # React + Vite
│     ├─ src/
│     │  ├─ app/                   # router, providers, layouts
│     │  ├─ features/              # theo module nghiệp vụ (xem 03_...)
│     │  │   ├─ auth/ profile/ recipes/ mealplan/ shop/ cart/ orders/ journal/ admin/
│     │  ├─ components/ui/         # shadcn primitives
│     │  ├─ lib/                   # supabase.ts, api.ts, format.ts, analytics.ts
│     │  ├─ hooks/ stores/ types/ i18n/
│     │  └─ main.tsx
│     ├─ index.html · vite.config.ts · tailwind.config.ts
├─ api/                            # Vercel Functions (Node)
│  ├─ _lib/ (supabaseAdmin.ts, auth.ts, errors.ts, validate.ts, rateLimit.ts)
│  ├─ mealplan/generate.ts
│  ├─ recommendations.ts
│  ├─ checkout.ts
│  ├─ orders/[id]/cancel.ts
│  ├─ payments/vnpay/{create.ts,ipn.ts,return.ts}
│  ├─ admin/{recipes.ts,orders.ts,products.ts}
│  └─ email/send.ts
├─ packages/
│  └─ nutrition-core/              # thuần TS, không phụ thuộc DOM
│     ├─ src/{bmr.ts,macros.ts,scale.ts,evaluate.ts,recommend.ts,mealplan.ts,shopping.ts}
│     └─ tests/
├─ supabase/
│  ├─ migrations/                  # *.sql (đánh số thời gian)
│  ├─ seed.sql
│  ├─ tests/                       # pgTAP RLS
│  └─ config.toml
├─ .github/workflows/ci.yml
├─ vercel.json · package.json (pnpm workspaces) · .env.example
├─ AGENTS.md                       # xem 04_AGENT.md
└─ docs/ (4 file md này)
```

---

## 5. CƠ SỞ DỮ LIỆU (PostgreSQL / Supabase)

### 5.1 Sơ đồ quan hệ (rút gọn)
```
auth.users 1─1 profiles 1─* user_health_conditions *─1 health_conditions ─1─* condition_rules
profiles 1─* user_allergies *─1 allergens
profiles 1─* body_metrics | addresses | meal_plans | food_logs | carts | orders | favorites
recipes 1─* recipe_ingredients *─1 ingredients 1─* ingredient_allergens *─1 allergens
recipes 1─* recipe_steps | recipe_diet_tags | reviews
meal_plans 1─* meal_plan_items *─1 recipes
ingredients 1─* products (sản phẩm bán) ─* cart_items | order_items
orders 1─* order_items | payments | order_status_history
```

### 5.2 Migration cốt lõi (SQL)

```sql
-- ===== 0001_extensions_enums.sql =====
create extension if not exists "pgcrypto";
create extension if not exists "unaccent";
create extension if not exists "pg_trgm";

create type app_role        as enum ('customer','nutritionist','staff','admin');
create type sex_type        as enum ('male','female');
create type activity_level  as enum ('sedentary','light','moderate','active','very_active');
create type goal_type       as enum ('lose','maintain','gain','muscle','healthy');
create type diet_type       as enum ('normal','vegetarian','vegan','pescatarian','low_carb','keto','dash','mediterranean','halal');
create type meal_type       as enum ('breakfast','lunch','dinner','snack');
create type content_status  as enum ('draft','review','published','archived');
create type order_status    as enum ('pending','confirmed','preparing','shipping','delivered','completed','cancelled','refund_requested','refunded');
create type payment_method  as enum ('cod','bank_transfer','vnpay','momo');
create type payment_status  as enum ('unpaid','pending','paid','failed','refunded');
create type rule_severity   as enum ('caution','avoid');

-- ===== 0002_profiles.sql =====
create table public.profiles (
  id               uuid primary key references auth.users(id) on delete cascade,
  full_name        text,
  avatar_url       text,
  phone            text,
  role             app_role not null default 'customer',
  sex              sex_type,
  birth_date       date,
  height_cm        numeric(5,1) check (height_cm between 100 and 250),
  weight_kg        numeric(5,1) check (weight_kg between 25 and 300),
  activity         activity_level default 'light',
  goal             goal_type default 'healthy',
  diet             diet_type  default 'normal',
  target_weight_kg numeric(5,1),
  max_cook_minutes int,
  budget_per_meal  int,                         -- VND
  disliked_ingredient_ids uuid[] default '{}',
  -- chỉ số tính sẵn (server cập nhật qua nutrition-core)
  bmr              numeric(7,1),
  tdee             numeric(7,1),
  target_kcal      int,
  target_protein_g int, target_carb_g int, target_fat_g int,
  target_fiber_g   int, max_sodium_mg int, max_sugar_g int,
  risk_tier        text default 'green' check (risk_tier in ('green','yellow','red')),
  consent_health_at timestamptz,               -- bắt buộc trước khi lưu dữ liệu sức khỏe
  onboarding_done  boolean default false,
  created_at       timestamptz default now(),
  updated_at       timestamptz default now()
);

-- Tự tạo profile khi đăng ký
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id, full_name, avatar_url)
  values (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Hàm kiểm tra vai trò (dùng trong RLS), tránh đệ quy
create function public.has_role(r app_role[]) returns boolean
language sql stable security definer set search_path = public as $$
  select exists(select 1 from profiles where id = auth.uid() and role = any(r));
$$;

create table public.body_metrics (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  measured_on date not null default current_date,
  weight_kg numeric(5,1) not null, body_fat_pct numeric(4,1), waist_cm numeric(5,1),
  unique (user_id, measured_on)
);

create table public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  receiver_name text not null, phone text not null,
  province text not null, district text not null, ward text not null, street text not null,
  note text, is_default boolean default false, created_at timestamptz default now()
);
create unique index one_default_address on addresses(user_id) where is_default;

-- ===== 0003_health_master.sql =====
create table public.allergens (
  id smallserial primary key, code text unique not null, name_vi text not null
);  -- peanut, tree_nut, shellfish, fish, milk, egg, gluten, soy, sesame

create table public.health_conditions (
  id smallserial primary key, code text unique not null, name_vi text not null,
  risk_tier text not null default 'yellow',      -- 'red' => không tự tạo thực đơn
  description text
);  -- diabetes_t2, hypertension, dyslipidemia, gout, obesity, ckd, gastritis, anemia, pregnancy

create table public.user_health_conditions (
  user_id uuid references profiles(id) on delete cascade,
  condition_id smallint references health_conditions(id),
  doctor_note text,
  primary key (user_id, condition_id)
);
create table public.user_allergies (
  user_id uuid references profiles(id) on delete cascade,
  allergen_id smallint references allergens(id),
  primary key (user_id, allergen_id)
);

-- Quy tắc dạng dữ liệu, có phiên bản
create table public.condition_rules (
  id uuid primary key default gen_random_uuid(),
  condition_id smallint not null references health_conditions(id),
  version int not null default 1,
  is_active boolean default true,
  -- giới hạn theo ngày; null = không ràng buộc
  max_sodium_mg int, max_sugar_g int, max_sat_fat_pct numeric(4,1),
  min_fiber_g int, carb_pct_min int, carb_pct_max int,
  max_purine_level smallint,                    -- 0 thấp,1 vừa,2 cao
  max_gi smallint,
  -- ngưỡng mỗi khẩu phần (lọc công thức)
  per_serving_max_sodium_mg int, per_serving_max_sugar_g int,
  excluded_ingredient_tags text[] default '{}', -- vd {'organ_meat','alcohol','sugary_drink'}
  preferred_tags text[] default '{}',           -- vd {'high_fiber','low_gi'}
  severity rule_severity default 'caution',
  rationale text, source_url text,
  approved_by uuid references profiles(id), approved_at timestamptz,
  created_at timestamptz default now()
);

-- ===== 0004_catalog.sql =====
create table public.ingredients (
  id uuid primary key default gen_random_uuid(),
  name_vi text not null, name_en text, slug text unique not null,
  category text,                                -- rau, thit, ca, gia_vi, ngu_coc...
  -- dinh dưỡng trên 100g phần ăn được
  kcal numeric(6,1) not null, protein_g numeric(6,2), carb_g numeric(6,2), fat_g numeric(6,2),
  sat_fat_g numeric(6,2), fiber_g numeric(6,2), sugar_g numeric(6,2),
  sodium_mg numeric(8,1), potassium_mg numeric(8,1), cholesterol_mg numeric(7,1),
  iron_mg numeric(6,2), calcium_mg numeric(7,1), vit_c_mg numeric(6,1),
  purine_level smallint default 0, glycemic_index smallint,
  tags text[] default '{}',                     -- organ_meat, alcohol, high_sodium, sugary_drink...
  source text, search tsvector generated always as
    (to_tsvector('simple', unaccent(coalesce(name_vi,'')||' '||coalesce(name_en,'')))) stored
);
create index on ingredients using gin(search);

create table public.ingredient_allergens (
  ingredient_id uuid references ingredients(id) on delete cascade,
  allergen_id smallint references allergens(id), primary key (ingredient_id, allergen_id)
);

create table public.recipes (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null, title text not null, summary text,
  image_url text, video_url text,
  meal meal_type[] not null,
  base_servings int not null default 2 check (base_servings > 0),
  prep_minutes int, cook_minutes int, difficulty smallint default 1,
  diet_tags diet_type[] default '{}',
  tags text[] default '{}',                     -- low_sodium, low_gi, high_protein, high_fiber
  -- dinh dưỡng / 1 khẩu phần (cache, trigger tính lại)
  kcal int, protein_g numeric(6,1), carb_g numeric(6,1), fat_g numeric(6,1),
  sat_fat_g numeric(6,1), fiber_g numeric(6,1), sugar_g numeric(6,1),
  sodium_mg int, max_purine_level smallint default 0, max_gi smallint,
  allergen_ids smallint[] default '{}',         -- cache từ nguyên liệu
  est_cost_vnd int,
  status content_status default 'draft',
  author_id uuid references profiles(id), reviewed_by uuid references profiles(id),
  published_at timestamptz, source_url text,
  avg_rating numeric(2,1) default 0, rating_count int default 0,
  search tsvector,
  created_at timestamptz default now(), updated_at timestamptz default now()
);
create index recipes_status_idx on recipes(status);
create index recipes_search_idx on recipes using gin(search);
create index recipes_tags_idx   on recipes using gin(tags);
create index recipes_allergen_idx on recipes using gin(allergen_ids);

create table public.recipe_ingredients (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references recipes(id) on delete cascade,
  ingredient_id uuid not null references ingredients(id),
  amount_g numeric(8,1) not null,               -- quy đổi ra gram (nguồn sự thật cho dinh dưỡng)
  display_amount numeric(8,2), display_unit text, -- vd 2 'quả'
  note text, optional boolean default false,
  scale_mode text default 'linear' check (scale_mode in ('linear','sublinear','fixed')),
  sort_order int default 0
);
create table public.recipe_steps (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references recipes(id) on delete cascade,
  step_no int not null, instruction text not null, timer_seconds int, image_url text,
  unique (recipe_id, step_no)
);

create table public.favorites (
  user_id uuid references profiles(id) on delete cascade,
  recipe_id uuid references recipes(id) on delete cascade,
  created_at timestamptz default now(), primary key (user_id, recipe_id)
);
create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid references recipes(id) on delete cascade,
  user_id uuid references profiles(id) on delete cascade,
  rating smallint check (rating between 1 and 5), comment text,
  created_at timestamptz default now(), unique (recipe_id, user_id)
);

-- ===== 0005_mealplan_journal.sql =====
create table public.meal_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  name text, start_date date not null, days int not null default 7,
  target_snapshot jsonb not null,               -- ảnh chụp mục tiêu lúc tạo
  created_at timestamptz default now()
);
create table public.meal_plan_items (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references meal_plans(id) on delete cascade,
  day_index int not null, meal meal_type not null,
  recipe_id uuid not null references recipes(id),
  servings numeric(4,1) not null default 1, is_pinned boolean default false,
  unique (plan_id, day_index, meal, recipe_id)
);
create table public.food_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  eaten_at timestamptz not null default now(), meal meal_type,
  recipe_id uuid references recipes(id), ingredient_id uuid references ingredients(id),
  custom_name text, servings numeric(5,2) default 1,
  kcal int, protein_g numeric(6,1), carb_g numeric(6,1), fat_g numeric(6,1),
  sodium_mg int, sugar_g numeric(6,1)
);
create table public.pantry_items (               -- nguyên liệu đã có
  user_id uuid references profiles(id) on delete cascade,
  ingredient_id uuid references ingredients(id), amount_g numeric(8,1),
  primary key (user_id, ingredient_id)
);

-- ===== 0006_shop.sql =====
create table public.product_categories (
  id smallserial primary key, name text not null, slug text unique not null, parent_id smallint
);
create table public.products (
  id uuid primary key default gen_random_uuid(),
  sku text unique not null, name text not null, slug text unique not null,
  description text, image_url text, category_id smallint references product_categories(id),
  ingredient_id uuid references ingredients(id),   -- ánh xạ sang nguyên liệu (nullable với gói meal-kit)
  recipe_id uuid references recipes(id),           -- meal-kit theo công thức
  kind text not null default 'ingredient' check (kind in ('ingredient','meal_kit','ready_meal')),
  unit text not null,                              -- 'kg','bó','gói'
  pack_size_g numeric(8,1),                        -- 1 đơn vị bán = bao nhiêu gram
  price_vnd bigint not null check (price_vnd >= 0),
  stock int not null default 0 check (stock >= 0),
  reserved int not null default 0 check (reserved >= 0),
  allergen_ids smallint[] default '{}',
  is_active boolean default true, created_at timestamptz default now()
);
create table public.carts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references profiles(id) on delete cascade,
  updated_at timestamptz default now()
);
create table public.cart_items (
  cart_id uuid references carts(id) on delete cascade,
  product_id uuid references products(id), qty int not null check (qty > 0),
  primary key (cart_id, product_id)
);
create table public.coupons (
  code text primary key, discount_pct int, discount_vnd bigint, min_order_vnd bigint default 0,
  max_uses int, used_count int default 0, starts_at timestamptz, ends_at timestamptz, is_active boolean default true
);
create table public.shipping_rules (
  id serial primary key, province text, fee_vnd bigint not null, free_from_vnd bigint, is_active boolean default true
);

create sequence order_code_seq start 100000;
create table public.orders (
  id uuid primary key default gen_random_uuid(),
  code text unique not null default ('NC' || nextval('order_code_seq')),
  user_id uuid not null references profiles(id),
  status order_status not null default 'pending',
  payment_method payment_method not null, payment_status payment_status not null default 'unpaid',
  subtotal_vnd bigint not null, shipping_fee_vnd bigint not null default 0,
  discount_vnd bigint not null default 0, total_vnd bigint not null,
  coupon_code text, note text, delivery_slot tstzrange,
  ship_snapshot jsonb not null,                    -- địa chỉ tại thời điểm đặt
  tracking_code text, carrier text,
  created_at timestamptz default now(), updated_at timestamptz default now()
);
create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders(id) on delete cascade,
  product_id uuid not null references products(id),
  name_snapshot text not null, unit_price_vnd bigint not null, qty int not null check (qty > 0),
  line_total_vnd bigint generated always as (unit_price_vnd * qty) stored
);
create table public.order_status_history (
  id bigserial primary key, order_id uuid references orders(id) on delete cascade,
  from_status order_status, to_status order_status not null,
  changed_by uuid, note text, created_at timestamptz default now()
);
create table public.payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders(id), provider payment_method not null,
  amount_vnd bigint not null, status payment_status not null default 'pending',
  provider_txn_id text, raw_payload jsonb, created_at timestamptz default now(),
  unique (provider, provider_txn_id)               -- chống xử lý webhook lặp (idempotent)
);

create table public.audit_log (
  id bigserial primary key, actor uuid, action text not null, entity text, entity_id text,
  meta jsonb, created_at timestamptz default now()
);
```

### 5.3 Trigger & hàm quan trọng
```sql
-- updated_at tự động
create function set_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;
create trigger t_profiles_upd before update on profiles for each row execute function set_updated_at();
create trigger t_recipes_upd  before update on recipes  for each row execute function set_updated_at();
create trigger t_orders_upd   before update on orders   for each row execute function set_updated_at();

-- Tính lại dinh dưỡng/1 khẩu phần + allergen + purine cho công thức
create function recompute_recipe_nutrition(p_recipe uuid) returns void
language plpgsql security definer set search_path = public as $$
declare s int;
begin
  select base_servings into s from recipes where id = p_recipe;
  update recipes r set
    kcal       = round(x.kcal / s),
    protein_g  = round(x.protein / s, 1), carb_g = round(x.carb / s, 1), fat_g = round(x.fat / s, 1),
    sat_fat_g  = round(x.sat / s, 1), fiber_g = round(x.fiber / s, 1), sugar_g = round(x.sugar / s, 1),
    sodium_mg  = round(x.sodium / s),
    max_purine_level = x.purine,
    allergen_ids = coalesce(x.allergens, '{}')
  from (
    select sum(i.kcal*ri.amount_g/100) kcal, sum(i.protein_g*ri.amount_g/100) protein,
           sum(i.carb_g*ri.amount_g/100) carb, sum(i.fat_g*ri.amount_g/100) fat,
           sum(i.sat_fat_g*ri.amount_g/100) sat, sum(i.fiber_g*ri.amount_g/100) fiber,
           sum(i.sugar_g*ri.amount_g/100) sugar, sum(i.sodium_mg*ri.amount_g/100) sodium,
           max(i.purine_level) purine,
           (select array_agg(distinct ia.allergen_id) from recipe_ingredients ri2
              join ingredient_allergens ia on ia.ingredient_id = ri2.ingredient_id
             where ri2.recipe_id = p_recipe) allergens
    from recipe_ingredients ri join ingredients i on i.id = ri.ingredient_id
    where ri.recipe_id = p_recipe
  ) x where r.id = p_recipe;
end $$;

-- Đặt hàng nguyên tử: kiểm kho + trừ/giữ kho + tạo order (gọi từ /api/checkout bằng service role)
create function place_order(p_user uuid, p_address jsonb, p_method payment_method,
                            p_coupon text, p_note text) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_cart uuid; v_order uuid; v_sub bigint; v_ship bigint; v_disc bigint := 0; r record;
begin
  select id into v_cart from carts where user_id = p_user;
  if not exists (select 1 from cart_items where cart_id = v_cart) then raise exception 'EMPTY_CART'; end if;

  -- khóa hàng & kiểm tồn
  for r in select ci.product_id, ci.qty, p.stock, p.reserved, p.price_vnd, p.name
           from cart_items ci join products p on p.id = ci.product_id
           where ci.cart_id = v_cart for update of p loop
    if r.stock - r.reserved < r.qty then raise exception 'OUT_OF_STOCK:%', r.name; end if;
  end loop;

  select sum(p.price_vnd * ci.qty) into v_sub from cart_items ci join products p on p.id = ci.product_id where ci.cart_id = v_cart;
  select coalesce((select case when v_sub >= free_from_vnd then 0 else fee_vnd end
                   from shipping_rules where is_active and province = p_address->>'province' limit 1), 30000) into v_ship;
  -- TODO: áp coupon (kiểm hạn, lượt, min_order) -> v_disc

  insert into orders(user_id, payment_method, subtotal_vnd, shipping_fee_vnd, discount_vnd, total_vnd,
                     coupon_code, note, ship_snapshot)
  values (p_user, p_method, v_sub, v_ship, v_disc, v_sub + v_ship - v_disc, p_coupon, p_note, p_address)
  returning id into v_order;

  insert into order_items(order_id, product_id, name_snapshot, unit_price_vnd, qty)
  select v_order, p.id, p.name, p.price_vnd, ci.qty
  from cart_items ci join products p on p.id = ci.product_id where ci.cart_id = v_cart;

  update products p set reserved = reserved + ci.qty
  from cart_items ci where ci.cart_id = v_cart and p.id = ci.product_id;

  delete from cart_items where cart_id = v_cart;
  insert into order_status_history(order_id, to_status, changed_by) values (v_order, 'pending', p_user);
  return v_order;
end $$;
```

### 5.4 Row Level Security (bắt buộc)
```sql
-- Bật RLS tất cả bảng
do $$ declare t text; begin
  for t in select tablename from pg_tables where schemaname='public' loop
    execute format('alter table public.%I enable row level security', t);
  end loop; end $$;

-- profiles: chỉ chủ sở hữu; staff/admin đọc được
create policy "profile_self_select" on profiles for select using (id = auth.uid() or has_role(array['admin','staff','nutritionist']::app_role[]));
create policy "profile_self_update" on profiles for update using (id = auth.uid())
  with check (id = auth.uid() and role = (select role from profiles where id = auth.uid())); -- không tự nâng quyền

-- dữ liệu cá nhân: user_id = auth.uid()
create policy own_rows on body_metrics         for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_rows on addresses            for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_rows on user_health_conditions for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_rows on user_allergies       for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_rows on meal_plans           for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_rows on food_logs            for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_rows on favorites            for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_rows on pantry_items         for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_items on meal_plan_items for all
  using (exists (select 1 from meal_plans m where m.id = plan_id and m.user_id = auth.uid()))
  with check (exists (select 1 from meal_plans m where m.id = plan_id and m.user_id = auth.uid()));

-- danh mục công khai (chỉ đọc), ghi bởi admin/nutritionist
create policy pub_read on recipes for select using (status = 'published' or has_role(array['admin','nutritionist']::app_role[]));
create policy rw_staff on recipes for all using (has_role(array['admin','nutritionist']::app_role[])) with check (has_role(array['admin','nutritionist']::app_role[]));
create policy pub_read on ingredients for select using (true);
create policy rw_admin on ingredients for all using (has_role(array['admin','nutritionist']::app_role[]));
create policy pub_read on recipe_ingredients for select using (exists (select 1 from recipes r where r.id = recipe_id and (r.status='published' or has_role(array['admin','nutritionist']::app_role[]))));
create policy pub_read on recipe_steps       for select using (exists (select 1 from recipes r where r.id = recipe_id and (r.status='published' or has_role(array['admin','nutritionist']::app_role[]))));
create policy pub_read on products      for select using (is_active or has_role(array['admin','staff']::app_role[]));
create policy rw_admin on products      for all using (has_role(array['admin','staff']::app_role[]));
create policy pub_read on health_conditions for select using (true);
create policy pub_read on allergens          for select using (true);
create policy pub_read on condition_rules    for select using (is_active);
create policy pub_read on reviews            for select using (true);
create policy own_write on reviews           for insert with check (user_id = auth.uid());

-- giỏ hàng
create policy own_cart on carts      for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_cart_items on cart_items for all
  using (exists (select 1 from carts c where c.id = cart_id and c.user_id = auth.uid()))
  with check (exists (select 1 from carts c where c.id = cart_id and c.user_id = auth.uid()));

-- đơn hàng: khách chỉ ĐỌC đơn của mình; ghi/đổi trạng thái chỉ qua server (service role)
create policy own_read on orders      for select using (user_id = auth.uid() or has_role(array['admin','staff']::app_role[]));
create policy own_read on order_items for select using (exists (select 1 from orders o where o.id = order_id and (o.user_id = auth.uid() or has_role(array['admin','staff']::app_role[]))));
create policy own_read on order_status_history for select using (exists (select 1 from orders o where o.id = order_id and o.user_id = auth.uid()));
create policy own_read on payments    for select using (exists (select 1 from orders o where o.id = order_id and o.user_id = auth.uid()));
-- KHÔNG tạo policy insert/update/delete cho orders/payments => client không thể tự sửa
```

> **Test RLS bắt buộc (pgTAP):** user A không `select` được bản ghi của B; khách không `update orders`; `customer` không tự đổi `role`; anon chỉ đọc recipe `published`.

### 5.5 Storage buckets
| Bucket | Public | Quy tắc |
|---|---|---|
| `recipe-images` | Đọc công khai | Ghi: admin/nutritionist; giới hạn 2MB, `image/webp|jpeg|png` |
| `product-images` | Đọc công khai | Ghi: admin/staff |
| `avatars` | Đọc công khai | Ghi: chủ sở hữu, thư mục `avatars/{uid}/` |

---

## 6. THUẬT TOÁN LÕI (`packages/nutrition-core`)

### 6.1 Tính mục tiêu
```ts
export function computeTargets(p: ProfileInput, rules: MergedRules): Targets {
  const bmr = 10*p.weightKg + 6.25*p.heightCm - 5*p.age + (p.sex==='male' ? 5 : -161);
  const tdee = bmr * ACTIVITY[p.activity];                       // 1.2…1.9
  let kcal = tdee + GOAL_DELTA[p.goal];                          // -500 … +500
  kcal = Math.max(kcal, p.sex==='male' ? 1500 : 1200);           // sàn an toàn
  const macro = pickMacroSplit(p.goal, p.diet, rules);           // % theo bảng PRD 5.3
  return {
    bmr, tdee, kcal: Math.round(kcal),
    proteinG: Math.round(kcal*macro.p/4), carbG: Math.round(kcal*macro.c/4), fatG: Math.round(kcal*macro.f/9),
    fiberG: rules.minFiber ?? (p.sex==='male' ? 30 : 25),
    maxSodiumMg: rules.maxSodium ?? 2000, maxSugarG: rules.maxSugar ?? Math.round(kcal*0.10/4),
  };
}
```

### 6.2 Gộp quy tắc nhiều bệnh (`mergeRules`)
- Các giới hạn **max\*** → lấy `min()`; các giới hạn **min\*** → lấy `max()`.
- `excluded_ingredient_tags` → hợp tập; `severity` → lấy mức cao nhất.
- Nếu có bất kỳ bệnh `risk_tier = 'red'` → `riskTier = 'red'` ⇒ `canAutoPlan = false`.

### 6.3 Đánh giá công thức theo hồ sơ
```ts
export function evaluateRecipe(r: Recipe, u: UserCtx): Verdict {
  // 1) LỌC CỨNG – AVOID
  if (r.allergenIds.some(a => u.allergenIds.includes(a)))      return avoid('ALLERGEN');
  if (!dietCompatible(r, u.diet))                              return avoid('DIET');
  if (r.ingredientIds.some(i => u.dislikedIds.includes(i)))    return avoid('DISLIKE');
  if (r.tags.some(t => u.rules.excludedTags.includes(t)))      return avoid('CONDITION_EXCLUDED');
  // 2) NGƯỠNG MỀM – CAUTION
  const reasons: string[] = [];
  if (u.rules.perServingMaxSodium && r.sodiumMg > u.rules.perServingMaxSodium) reasons.push('SODIUM_HIGH');
  if (u.rules.perServingMaxSugar  && r.sugarG   > u.rules.perServingMaxSugar)  reasons.push('SUGAR_HIGH');
  if (u.rules.maxPurine !== undefined && r.maxPurineLevel > u.rules.maxPurine) reasons.push('PURINE_HIGH');
  return reasons.length ? caution(reasons) : suitable(matchedPreferredTags(r, u.rules));
}
```

### 6.4 Chấm điểm xếp hạng (0–100)
```
score = 35·macroFit + 20·preferenceTags + 15·timeFit + 10·budgetFit + 10·variety + 10·rating
macroFit  = 1 − min(1, |kcal_r − kcal_meal_target| / kcal_meal_target)·0.6 − |protein% lệch|·0.4
variety   = phạt nếu cùng nguyên liệu chính/tag đã dùng trong 3 ngày gần nhất
```
Chia kcal bữa: sáng 25% · trưa 35% · tối 30% · phụ 10%.

### 6.5 Sinh thực đơn (`generateMealPlan`)
1. Nếu `riskTier === 'red'` → trả `403 PLAN_NOT_ALLOWED` kèm hướng dẫn.
2. Lấy ứng viên `published` qua DB (lọc allergen/diet bằng SQL `&&` cho nhanh), sau đó `evaluateRecipe` lọc `AVOID`.
3. Với mỗi ngày × bữa: chọn top-K theo điểm → chọn ngẫu nhiên có trọng số (seed theo `user_id+date`) tránh trùng 3 ngày.
4. **Điều chỉnh khẩu phần** (0.75–1.5, bước 0.25) để tổng kcal ngày ≈ mục tiêu ±5%; nếu vẫn lệch, hoán đổi 1 món (local search tối đa 200 vòng).
5. Kiểm tra ràng buộc ngày (natri, đường, chất xơ). Không đạt → thử lại ≤ 5 lần, rồi trả kết quả tốt nhất kèm cờ `warnings`.
6. Lưu `meal_plans` + `meal_plan_items` và trả về.

### 6.6 Danh sách mua sắm
```
need[ingredient] = Σ amount_g × servings/base_servings   (theo scale_mode)
need -= pantry[ingredient]
product = chọn sản phẩm active theo ingredient_id có chi phí/đơn vị thấp nhất, còn hàng
qty = ceil(need / product.pack_size_g)
```

---

## 7. THIẾT KẾ API (Vercel Functions)

Quy ước: Base `/api`, JSON, `Authorization: Bearer <supabase_access_token>`, lỗi chuẩn:
```json
{ "error": { "code": "OUT_OF_STOCK", "message": "Cà chua hết hàng", "details": {} } }
```
Validate đầu vào bằng **Zod**; rate limit theo IP+user (Upstash Ratelimit hoặc bảng Postgres).

| Method | Endpoint | Auth | Mô tả |
|---|---|---|---|
| POST | `/api/profile/compute` | user | Nhận hồ sơ → tính & lưu mục tiêu, `risk_tier` |
| GET | `/api/recommendations?meal=&limit=&cursor=` | user | Công thức đã lọc + điểm + lý do |
| POST | `/api/mealplan/generate` | user | `{startDate, days, meals[], excludeRecipeIds[]}` → plan |
| POST | `/api/mealplan/:id/swap` | user | `{itemId}` → đổi món theo ràng buộc |
| POST | `/api/shopping-list` | user | `{planId? \| recipeIds[]+servings}` → danh sách + sản phẩm gợi ý |
| POST | `/api/cart/add-from-list` | user | Thêm các sản phẩm vào giỏ |
| POST | `/api/checkout` | user | `{addressId, method, couponCode?, note?, slot?}` → gọi `place_order`, trả `{orderId, payUrl?}` |
| POST | `/api/orders/:id/cancel` | user | Chỉ khi `pending/confirmed`; hoàn kho |
| POST | `/api/payments/vnpay/create` | user | Tạo URL thanh toán đã ký HMAC |
| GET | `/api/payments/vnpay/ipn` | công khai (ký) | **Webhook**: verify `vnp_SecureHash`, số tiền, `orderId`; idempotent |
| GET | `/api/payments/vnpay/return` | công khai | Chỉ hiển thị kết quả, **không** đổi trạng thái |
| PATCH | `/api/admin/orders/:id/status` | staff/admin | Chuyển trạng thái hợp lệ (máy trạng thái), ghi history, gửi mail |
| POST | `/api/admin/recipes/:id/publish` | nutritionist/admin | Kiểm đủ điều kiện → `published` |
| POST | `/api/admin/recipes/:id/recompute` | admin | Tính lại dinh dưỡng |
| DELETE | `/api/account` | user | Xóa tài khoản & dữ liệu (gọi `auth.admin.deleteUser`) |
| GET | `/api/account/export` | user | Xuất dữ liệu cá nhân JSON |

**Truy cập trực tiếp qua Supabase (RLS):** danh sách/chi tiết công thức, nguyên liệu, sản phẩm, yêu thích, hồ sơ, địa chỉ, giỏ hàng, nhật ký, xem đơn.

**Máy trạng thái đơn (server)**
```ts
const NEXT: Record<OrderStatus, OrderStatus[]> = {
  pending:['confirmed','cancelled'], confirmed:['preparing','cancelled'],
  preparing:['shipping','cancelled'], shipping:['delivered'],
  delivered:['completed','refund_requested'], refund_requested:['refunded','completed'],
  completed:[], cancelled:[], refunded:[],
};
```
Khi `→ confirmed`: `stock -= qty, reserved -= qty`. Khi `→ cancelled`: `reserved -= qty` (nếu chưa trừ) hoặc `stock += qty`.

---

## 8. XÁC THỰC & PHÂN QUYỀN

| Luồng | Chi tiết |
|---|---|
| Đăng ký | `supabase.auth.signUp({email,password,options:{data:{full_name}}})` → email xác thực → trigger tạo `profiles` |
| Đăng nhập | `signInWithPassword` / `signInWithOAuth({provider:'google'})` (PKCE) |
| Đăng xuất | `supabase.auth.signOut()` → xóa cache TanStack Query & store |
| Quên mật khẩu | `resetPasswordForEmail(email,{redirectTo:'/reset-password'})` → `updateUser({password})` |
| Phiên | Access token ngắn hạn + refresh tự động (supabase-js) |
| API server | Hàm `requireUser(req)`: lấy Bearer → `supabaseAdmin.auth.getUser(token)` (luôn dùng `getUser`, không tin chỉ `getSession`) → đọc `role` từ `profiles` |
| Guard client | `<ProtectedRoute>`, `<RoleRoute roles={['admin']}>` (chỉ UX; bảo mật thật nằm ở RLS + API) |
| Cấu hình Supabase | Bật Email confirm; Site URL & Redirect URLs gồm domain Vercel + preview; Google OAuth client; mật khẩu tối thiểu 8; CAPTCHA (hCaptcha/Turnstile) cho đăng ký |

---

## 9. THANH TOÁN (VNPay — mẫu)
1. `/api/checkout` tạo order `pending` + `payments(pending)`.
2. `/api/payments/vnpay/create`: dựng tham số `vnp_*` (`vnp_Amount = total×100`, `vnp_TxnRef = order.code`, `vnp_ReturnUrl`, `vnp_IpnUrl`), sắp xếp khóa, ký **HMAC-SHA512** bằng `VNP_HASH_SECRET`, trả URL.
3. Cổng gọi **IPN** → verify chữ ký → khớp `order.code` & `amount` → nếu `payments.provider_txn_id` đã tồn tại thì trả OK (idempotent) → cập nhật `paid`, order `confirmed`, trừ kho, gửi email.
4. Trang `return` chỉ gọi API đọc trạng thái hiện tại.
5. Job `pg_cron` mỗi 5 phút: hủy đơn online `pending` quá 15 phút, nhả `reserved`.
6. COD: order `pending` → staff gọi xác nhận → `confirmed`.

---

## 10. BẢO MẬT
- **RLS mọi bảng**; hàm `security definer` luôn `set search_path = public`.
- `service_role` & secrets chỉ ở biến môi trường **Vercel (Server)**; không prefix `VITE_`.
- Validate Zod ở mọi endpoint; kiểm tra quyền sở hữu tài nguyên ở server.
- Rate limit: `/auth/*` 10/phút/IP, `/checkout` 5/phút/user, `/mealplan/generate` 10/giờ/user.
- Header bảo mật (`vercel.json`): CSP, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`, HSTS.
- Chống XSS: không dùng `dangerouslySetInnerHTML` với nội dung người dùng (nếu cần dùng DOMPurify).
- Upload ảnh: kiểm MIME & kích thước; tên file ngẫu nhiên.
- Dữ liệu sức khỏe: chỉ lưu khi có `consent_health_at`; log truy cập admin vào `audit_log`; không đưa dữ liệu sức khỏe vào analytics/Sentry (scrub PII).
- Sao lưu: Supabase PITR (gói Pro) hoặc dump hằng ngày; kiểm thử khôi phục hàng quý.
- Phụ thuộc: `pnpm audit`, Dependabot; khóa version.

---

## 11. BIẾN MÔI TRƯỜNG (`.env.example`)
```bash
# --- Client (an toàn để lộ) ---
VITE_SUPABASE_URL=https://xxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...
VITE_APP_URL=http://localhost:5173
VITE_SENTRY_DSN=
VITE_POSTHOG_KEY=

# --- Server (CHỈ trên Vercel / .env.local, KHÔNG commit) ---
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
VNP_TMN_CODE=
VNP_HASH_SECRET=
VNP_URL=https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
RESEND_API_KEY=
MAIL_FROM="NutriCook <no-reply@yourdomain.com>"
UPSTASH_REDIS_REST_URL=
UPSTASH_REDIS_REST_TOKEN=
```

---

## 12. TRIỂN KHAI (VERCEL + SUPABASE)

### 12.1 `vercel.json`
```json
{
  "buildCommand": "pnpm --filter web build",
  "outputDirectory": "apps/web/dist",
  "rewrites": [
    { "source": "/api/(.*)", "destination": "/api/$1" },
    { "source": "/(.*)", "destination": "/index.html" }
  ],
  "headers": [{
    "source": "/(.*)",
    "headers": [
      { "key": "X-Content-Type-Options", "value": "nosniff" },
      { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" },
      { "key": "Permissions-Policy", "value": "camera=(), microphone=(), geolocation=()" },
      { "key": "Strict-Transport-Security", "value": "max-age=63072000; includeSubDomains" }
    ]
  }],
  "functions": { "api/**/*.ts": { "maxDuration": 15, "memory": 512 } }
}
```

### 12.2 Môi trường
| Môi trường | Nhánh | Supabase | Ghi chú |
|---|---|---|---|
| Local | — | `supabase start` (Docker) | `.env.local` |
| Preview | PR | Project `nutricook-staging` | Mỗi PR có URL preview |
| Production | `main` | Project `nutricook-prod` | Domain riêng |

### 12.3 Quy trình
1. Tạo 2 project Supabase (staging/prod) → chạy `supabase link` → `supabase db push` migrations.
2. Kết nối GitHub repo với Vercel; thêm env theo môi trường.
3. Thêm domain Vercel vào Supabase **Auth → URL Configuration**.
4. Cấu hình webhook IPN VNPay trỏ tới `https://<domain>/api/payments/vnpay/ipn`.
5. Chạy `supabase gen types typescript --linked > apps/web/src/types/database.ts` sau mỗi migration.

### 12.4 CI (`.github/workflows/ci.yml`)
```yaml
name: CI
on: [pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - run: pnpm lint && pnpm typecheck
      - run: pnpm --filter nutrition-core test
      - run: pnpm --filter web test
      - uses: supabase/setup-cli@v1
      - run: supabase start && supabase test db   # pgTAP RLS
      - run: pnpm --filter web build
```

---

## 13. KIỂM THỬ

| Loại | Phạm vi | Công cụ |
|---|---|---|
| Unit | BMR/TDEE (so với giá trị tay), macro, scale khẩu phần, mergeRules, evaluateRecipe, shopping list | Vitest |
| Property-based | "Không bao giờ trả công thức chứa allergen đã khai" với 10.000 hồ sơ ngẫu nhiên | fast-check |
| DB | RLS, trigger tính dinh dưỡng, `place_order` (tranh chấp kho) | pgTAP |
| API | Zod, auth, rate limit, webhook giả mạo | Vitest + supertest |
| E2E | Đăng ký → onboarding → gợi ý → thực đơn → giỏ → COD; đăng nhập/đăng xuất | Playwright |
| Accessibility | axe-core trong E2E | Playwright + axe |
| Tải | `/api/mealplan/generate`, `/api/checkout` | k6 |

**Bộ test vàng (golden tests) cho dinh dưỡng**: nữ 30 tuổi 60 kg 165 cm, light → BMR = 10·60+6.25·165−5·30−161 = **1.320,25**; TDEE = **1.815,3** (×1.375).

---

## 14. SEED DATA
- `allergens`, `health_conditions`, `condition_rules` (v1, `approved_by = null` cho đến khi chuyên gia duyệt).
- ~300 nguyên liệu phổ biến (nhập từ Bảng thành phần thực phẩm Việt Nam — Viện Dinh dưỡng; ghi `source`).
- 50 công thức mẫu (món Việt: canh, kho, luộc, hấp, salad, cháo, yến mạch...), đủ ảnh WebP.
- ~150 sản phẩm gắn `ingredient_id` & `pack_size_g`.
- Tài khoản demo: `admin@`, `nutritionist@`, `staff@`, `customer@` (chỉ ở staging).

---

## 15. QUAN SÁT & VẬN HÀNH
- **Sentry** (FE + API) với `beforeSend` loại PII/health data.
- **Log** có cấu trúc `{requestId,userId(hash),route,ms}` trong Vercel Logs.
- **Alert:** tỷ lệ 5xx > 2%, webhook thanh toán lỗi, tồn kho âm, job hủy đơn không chạy.
- **Backup/Restore** runbook; **Incident** runbook (lộ key → xoay khóa Supabase/VNPay, thu hồi session).

---

## 16. NGUỒN KỸ THUẬT
- Supabase RLS, Auth (`getUser()`), SSR/`@supabase/ssr`, Vercel + pooling: https://supabase.com/docs · mẫu tham khảo https://playbooks.com/skills/bjornmelin/dev-skills/supabase-ts
- Biến môi trường theo framework (`VITE_` / `NEXT_PUBLIC_`), anon key tôn trọng RLS: https://www.rapidevelopers.com/md/supabase-tutorial/how-to-set-environment-variables-in-supabase
- Kiến trúc React (Vite) + API + Supabase RLS + Vercel: https://makerkit.dev/docs/supamode/installation/technical-details
- VNPay tài liệu tích hợp: https://sandbox.vnpayment.vn/apis/
