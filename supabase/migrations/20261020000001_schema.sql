-- =====================================================================
-- NutriCook · Migration 1 · SCHEMA
-- Phạm vi: tài khoản, hồ sơ sức khỏe & khẩu vị, công thức chi tiết,
--          thực đơn, nhật ký, phản hồi, AI gợi ý.  (Cửa hàng & đặt hàng: xem migration 004–005)
-- =====================================================================

create extension if not exists pgcrypto;
create extension if not exists pg_trgm;
create extension if not exists unaccent with schema extensions;

-- unaccent không IMMUTABLE → bọc lại để dùng trong index/trigger
create or replace function public.f_unaccent(t text) returns text
language sql immutable parallel safe strict as
$$ select extensions.unaccent('extensions.unaccent'::regdictionary, t) $$;

-- ---------- ENUMS ----------
create type app_role       as enum ('customer','nutritionist','staff','admin');
create type sex_type       as enum ('male','female');
create type activity_level as enum ('sedentary','light','moderate','active','very_active');
create type goal_type      as enum ('lose','maintain','gain','muscle','healthy');
create type diet_type      as enum ('normal','vegetarian','vegan','pescatarian','low_carb','keto','dash','mediterranean','halal');
create type meal_type      as enum ('breakfast','lunch','dinner','snack');
create type content_status as enum ('draft','review','published','archived');

-- ---------- TIỆN ÍCH ----------
create or replace function public.set_updated_at() returns trigger
language plpgsql as $$ begin new.updated_at = now(); return new; end $$;

-- nhóm tuổi: child <13, teen 13–17, adult 18–59, senior ≥60
create or replace function public.age_group_of(b date) returns text
language sql immutable as $$
  select case when b is null then null
              when date_part('year', age(b)) < 13 then 'child'
              when date_part('year', age(b)) < 18 then 'teen'
              when date_part('year', age(b)) >= 60 then 'senior'
              else 'adult' end
$$;

-- ---------- HỒ SƠ ----------
create table public.profiles (
  id               uuid primary key references auth.users(id) on delete cascade,
  full_name        text,
  avatar_url       text,
  role             app_role not null default 'customer',
  -- cơ thể & mục tiêu
  sex              sex_type,
  birth_date       date,
  height_cm        numeric(5,1) check (height_cm between 100 and 250),
  weight_kg        numeric(5,1) check (weight_kg between 25 and 300),
  activity         activity_level default 'light',
  goal             goal_type default 'healthy',
  diet             diet_type default 'normal',
  target_weight_kg numeric(5,1),
  -- khẩu vị & thói quen nấu (dùng cho gợi ý & AI)
  spice_level      smallint default 1 check (spice_level between 0 and 3),   -- 0 không cay … 3 rất cay
  taste_prefs      text[] default '{}',          -- light, salty_light, sweet, sour, umami, rich, fresh
  preferred_cuisines text[] default '{}',        -- viet, asian, western, mediterranean
  favorite_methods text[] default '{}',          -- xào, hấp, kho, canh, nướng, luộc, áp chảo, trộn
  cooking_skill    smallint default 1 check (cooking_skill between 1 and 3),
  max_cook_minutes int check (max_cook_minutes is null or max_cook_minutes between 5 and 240),
  default_servings int default 2 check (default_servings between 1 and 12),
  household        jsonb not null default '[]',  -- [{"group":"child","count":2}]
  disliked_ingredient_ids uuid[] default '{}',
  -- chỉ số tính sẵn (do rpc_compute_targets cập nhật)
  bmr numeric(7,1), tdee numeric(7,1), target_kcal int,
  target_protein_g int, target_carb_g int, target_fat_g int,
  target_fiber_g int, max_sodium_mg int, max_sugar_g int,
  risk_tier        text not null default 'green' check (risk_tier in ('green','yellow','red')),
  -- đồng ý
  consent_health_at timestamptz,                 -- xử lý dữ liệu sức khỏe
  ai_consent_at     timestamptz,                 -- gửi dữ liệu ẩn danh cho nhà cung cấp AI
  onboarding_done  boolean not null default false,
  created_at timestamptz default now(), updated_at timestamptz default now()
);
create trigger t_profiles_upd before update on public.profiles
  for each row execute function public.set_updated_at();

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id, full_name, avatar_url)
  values (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.has_role(r app_role[]) returns boolean
language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role = any(r));
$$;

-- không cho người dùng tự nâng quyền / tự sửa chỉ số hệ thống
create or replace function public.profiles_guard() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null and not has_role(array['admin']::app_role[]) then
    new.role := old.role;
  end if;
  return new;
end $$;
create trigger t_profiles_guard before update on public.profiles
  for each row execute function public.profiles_guard();

create table public.body_metrics (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  measured_on date not null default current_date,
  weight_kg numeric(5,1) not null check (weight_kg between 25 and 300),
  waist_cm numeric(5,1),
  unique (user_id, measured_on)
);

-- ---------- DANH MỤC SỨC KHỎE ----------
create table public.allergens (
  id smallserial primary key, code text unique not null, name_vi text not null
);
create table public.health_conditions (
  id smallserial primary key, code text unique not null, name_vi text not null,
  risk_tier text not null default 'yellow' check (risk_tier in ('yellow','red')),
  description text
);
create table public.user_health_conditions (
  user_id uuid references public.profiles(id) on delete cascade,
  condition_id smallint references public.health_conditions(id),
  doctor_note text,
  primary key (user_id, condition_id)
);
create table public.user_allergies (
  user_id uuid references public.profiles(id) on delete cascade,
  allergen_id smallint references public.allergens(id),
  primary key (user_id, allergen_id)
);
-- Quy tắc bệnh lý = DỮ LIỆU (không hard-code). Chỉ dùng bản có approved_at khi chạy thật.
create table public.condition_rules (
  id uuid primary key default gen_random_uuid(),
  condition_id smallint not null references public.health_conditions(id),
  version int not null default 1,
  is_active boolean not null default true,
  max_sodium_mg int,                 -- giới hạn cả ngày
  min_fiber_g int,
  max_purine_level smallint,         -- 0 thấp, 1 vừa, 2 cao
  per_serving_max_sodium_mg int,     -- ngưỡng 1 khẩu phần → CAUTION
  per_serving_max_sugar_g int,
  excluded_ingredient_tags text[] not null default '{}',   -- → AVOID
  preferred_tags text[] not null default '{}',             -- → cộng điểm
  rationale text, source_url text,
  approved_by uuid references public.profiles(id), approved_at timestamptz,
  created_at timestamptz default now()
);

-- ---------- NGUYÊN LIỆU ----------
create table public.ingredients (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null, name_vi text not null, name_en text, category text,
  -- dinh dưỡng / 100 g phần ăn được
  kcal numeric(6,1) not null, protein_g numeric(6,2), carb_g numeric(6,2), fat_g numeric(6,2),
  sat_fat_g numeric(6,2), fiber_g numeric(6,2), sugar_g numeric(6,2), sodium_mg numeric(8,1),
  purine_level smallint not null default 0 check (purine_level between 0 and 2),
  glycemic_index smallint,
  -- tag: meat, fish, shellfish, egg, dairy, animal, soy, high_sodium, organ_meat, alcohol, added_sugar, spicy_hot ...
  tags text[] not null default '{}',
  source text not null default 'seed_estimate',      -- nguồn số liệu (bắt buộc minh bạch)
  search tsvector,
  created_at timestamptz default now()
);
create index ingredients_search_idx on public.ingredients using gin(search);
create or replace function public.ingredients_search_trg() returns trigger language plpgsql as $$
begin new.search := to_tsvector('simple', public.f_unaccent(coalesce(new.name_vi,'')||' '||coalesce(new.name_en,''))); return new; end $$;
create trigger t_ing_search before insert or update on public.ingredients
  for each row execute function public.ingredients_search_trg();

create table public.ingredient_allergens (
  ingredient_id uuid references public.ingredients(id) on delete cascade,
  allergen_id smallint references public.allergens(id),
  primary key (ingredient_id, allergen_id)
);

-- ---------- CÔNG THỨC (CHI TIẾT) ----------
create table public.recipes (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null, title text not null,
  summary text,                      -- 1–2 câu mô tả
  intro text,                        -- giới thiệu món, lợi ích, hương vị
  image_url text, video_url text,
  meal meal_type[] not null,
  cuisine text not null default 'viet' check (cuisine in ('viet','asian','western','mediterranean')),
  method text,                       -- xào, hấp, kho, canh, nướng, luộc, áp chảo, trộn, nấu cháo...
  spice_level smallint not null default 0 check (spice_level between 0 and 3),
  texture text[] not null default '{}',     -- soft, crunchy, creamy, liquid
  base_servings int not null default 2 check (base_servings > 0),
  prep_minutes int not null default 0, cook_minutes int not null default 0,
  total_minutes int generated always as (prep_minutes + cook_minutes) stored,
  difficulty smallint not null default 1 check (difficulty between 1 and 3),
  -- hướng dẫn mở rộng
  equipment text[] not null default '{}',          -- dụng cụ cần có
  tips text[] not null default '{}',               -- mẹo nấu ngon
  common_mistakes text[] not null default '{}',    -- lỗi hay gặp & cách tránh
  substitutions jsonb not null default '[]',       -- [{"ingredient":"tôm","alternatives":["đậu hũ"],"note":"…"}]
  storage_note text,                               -- bảo quản / hâm lại
  serving_suggestion text,                         -- gợi ý ăn kèm
  health_notes text,                               -- lưu ý sức khỏe (do chuyên gia viết)
  -- phân loại
  diet_tags diet_type[] not null default '{normal}',
  tags text[] not null default '{}',               -- thủ công: omega3, soft, low_gi ...
  auto_tags text[] not null default '{}',          -- tự tính: low_sodium, high_protein, high_fiber ...
  ingredient_tags text[] not null default '{}',    -- hợp tag nguyên liệu (tự tính)
  allergen_ids smallint[] not null default '{}',   -- tự tính
  -- dinh dưỡng / 1 khẩu phần (tự tính từ nguyên liệu)
  kcal int, protein_g numeric(6,1), carb_g numeric(6,1), fat_g numeric(6,1),
  sat_fat_g numeric(6,1), fiber_g numeric(6,1), sugar_g numeric(6,1), sodium_mg int,
  max_purine_level smallint not null default 0,
  -- quản trị nội dung
  status content_status not null default 'draft',
  author_id uuid references public.profiles(id), reviewed_by uuid references public.profiles(id),
  published_at timestamptz, source_url text,
  avg_rating numeric(2,1) not null default 0, rating_count int not null default 0,
  search tsvector,
  created_at timestamptz default now(), updated_at timestamptz default now()
);
create index recipes_status_idx  on public.recipes(status);
create index recipes_search_idx  on public.recipes using gin(search);
create index recipes_tags_idx    on public.recipes using gin(tags);
create index recipes_allerg_idx  on public.recipes using gin(allergen_ids);
create trigger t_recipes_upd before update on public.recipes
  for each row execute function public.set_updated_at();
create or replace function public.recipes_search_trg() returns trigger language plpgsql as $$
begin new.search := to_tsvector('simple', public.f_unaccent(
  coalesce(new.title,'')||' '||coalesce(new.summary,'')||' '||coalesce(new.method,'')||' '||coalesce(array_to_string(new.tags,' '),'')));
  return new; end $$;
create trigger t_rec_search before insert or update of title, summary, method, tags on public.recipes
  for each row execute function public.recipes_search_trg();

create table public.recipe_ingredients (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  ingredient_id uuid not null references public.ingredients(id),
  group_name text not null default 'Nguyên liệu chính',   -- vd: "Nước sốt", "Rau ăn kèm"
  amount_g numeric(8,1) not null check (amount_g >= 0),   -- gram (nguồn tính dinh dưỡng)
  display_amount numeric(8,2), display_unit text,         -- vd 2 'quả', 1 'muỗng canh'
  prep_note text,                                         -- sơ chế: "thái lát mỏng 3 mm"
  note text,                                              -- ghi chú: "có thể thay bằng…"
  optional boolean not null default false,
  scale_mode text not null default 'linear' check (scale_mode in ('linear','sublinear','fixed')),
  sort_order int not null default 0
);
create index recipe_ing_recipe_idx on public.recipe_ingredients(recipe_id);

create table public.recipe_steps (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  step_no int not null,
  phase text not null default 'cook' check (phase in ('prep','cook','finish')),  -- sơ chế / nấu / hoàn thiện
  title text not null,                                    -- "Áp chảo ức gà"
  instruction text not null,                              -- hướng dẫn chi tiết
  timer_seconds int,                                      -- hẹn giờ
  heat text not null default 'none' check (heat in ('none','low','medium','high')),
  tip text,                                               -- mẹo của bước / dấu hiệu nhận biết đã đạt
  image_url text,
  unique (recipe_id, step_no)
);

-- ---------- TƯƠNG TÁC & PHẢN HỒI ----------
create table public.favorites (
  user_id uuid references public.profiles(id) on delete cascade,
  recipe_id uuid references public.recipes(id) on delete cascade,
  created_at timestamptz default now(), primary key (user_id, recipe_id)
);
-- phản hồi dùng để cá nhân hóa gợi ý & AI
create table public.recipe_feedback (
  user_id uuid references public.profiles(id) on delete cascade,
  recipe_id uuid references public.recipes(id) on delete cascade,
  reaction text not null check (reaction in ('like','dislike','cooked')),
  reason text check (reason is null or char_length(reason) <= 200),  -- vd: "quá mặn", "khó làm"
  created_at timestamptz default now(),
  primary key (user_id, recipe_id, reaction)
);
create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  rating smallint not null check (rating between 1 and 5),
  comment text check (comment is null or char_length(comment) <= 1000),
  created_at timestamptz default now(), unique (recipe_id, user_id)
);
create or replace function public.reviews_agg() returns trigger language plpgsql security definer set search_path = public as $$
declare rid uuid := coalesce(new.recipe_id, old.recipe_id);
begin
  update recipes set avg_rating = coalesce((select round(avg(rating)::numeric,1) from reviews where recipe_id = rid),0),
                     rating_count = (select count(*) from reviews where recipe_id = rid)
  where id = rid;
  return null;
end $$;
create trigger t_reviews_agg after insert or update or delete on public.reviews
  for each row execute function public.reviews_agg();

-- ---------- THỰC ĐƠN & NHẬT KÝ ----------
create table public.meal_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text, start_date date not null, days int not null default 7 check (days between 1 and 14),
  target_snapshot jsonb not null default '{}',
  created_at timestamptz default now()
);
create table public.meal_plan_items (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.meal_plans(id) on delete cascade,
  day_index int not null check (day_index >= 0), meal meal_type not null,
  recipe_id uuid not null references public.recipes(id),
  servings numeric(4,2) not null default 1 check (servings > 0),
  is_pinned boolean not null default false,
  unique (plan_id, day_index, meal, recipe_id)
);
create table public.food_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  eaten_at timestamptz not null default now(), meal meal_type,
  recipe_id uuid references public.recipes(id), custom_name text,
  servings numeric(5,2) not null default 1,
  kcal int, protein_g numeric(6,1), carb_g numeric(6,1), fat_g numeric(6,1),
  sodium_mg int, sugar_g numeric(6,1)
);
create index food_logs_user_idx on public.food_logs(user_id, eaten_at desc);

-- ---------- AI ----------
create table public.ai_runs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  mode text not null default 'suggest',
  input jsonb not null, output jsonb,
  candidate_ids uuid[] default '{}',
  model text, input_tokens int, output_tokens int, latency_ms int,
  used_fallback boolean not null default false,
  error text,
  created_at timestamptz default now()
);
create index ai_runs_user_time_idx on public.ai_runs(user_id, created_at desc);

create table public.audit_log (
  id bigserial primary key, actor uuid, action text not null, entity text, entity_id text,
  meta jsonb, created_at timestamptz default now()
);

