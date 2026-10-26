-- =====================================================================
-- NutriCook · Migration 3 · LOGIC TRONG DATABASE (RPC + trigger)
-- Quy ước: hàm security definer luôn set search_path và dùng auth.uid();
--          không nhận user_id từ client.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. TÍNH LẠI DINH DƯỠNG / ALLERGEN / TAG CHO CÔNG THỨC
-- ---------------------------------------------------------------------
create or replace function public.recompute_recipe_nutrition(p_recipe uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  s int; n record; v_itags text[]; v_alg smallint[]; v_diets diet_type[] := array['normal']::diet_type[];
  v_auto text[] := '{}'; r recipes%rowtype;
begin
  select * into r from recipes where id = p_recipe;
  if r.id is null then return; end if;
  s := r.base_servings;

  -- dinh dưỡng: chỉ nguyên liệu KHÔNG tùy chọn
  select coalesce(sum(i.kcal*ri.amount_g/100),0) kcal, coalesce(sum(i.protein_g*ri.amount_g/100),0) protein,
         coalesce(sum(i.carb_g*ri.amount_g/100),0) carb, coalesce(sum(i.fat_g*ri.amount_g/100),0) fat,
         coalesce(sum(i.sat_fat_g*ri.amount_g/100),0) sat, coalesce(sum(i.fiber_g*ri.amount_g/100),0) fiber,
         coalesce(sum(i.sugar_g*ri.amount_g/100),0) sugar, coalesce(sum(i.sodium_mg*ri.amount_g/100),0) sodium,
         coalesce(max(i.purine_level),0) purine
    into n
  from recipe_ingredients ri join ingredients i on i.id = ri.ingredient_id
  where ri.recipe_id = p_recipe and not ri.optional;

  -- tag & dị ứng: tính CẢ nguyên liệu tùy chọn (an toàn hơn)
  select coalesce(array_agg(distinct t), '{}') into v_itags from (
    select unnest(i.tags) t from recipe_ingredients ri join ingredients i on i.id = ri.ingredient_id
    where ri.recipe_id = p_recipe) q;
  select coalesce(array_agg(distinct ia.allergen_id), '{}')::smallint[] into v_alg
  from recipe_ingredients ri join ingredient_allergens ia on ia.ingredient_id = ri.ingredient_id
  where ri.recipe_id = p_recipe;

  if not ('meat' = any(v_itags)) then v_diets := v_diets || 'pescatarian'::diet_type; end if;
  if not (v_itags && array['meat','fish','shellfish']) then v_diets := v_diets || 'vegetarian'::diet_type; end if;
  if not ('animal' = any(v_itags)) then v_diets := v_diets || 'vegan'::diet_type; end if;
  if n.kcal > 0 and (n.carb*4 / n.kcal) <= 0.30 then v_diets := v_diets || 'low_carb'::diet_type; end if;

  if s > 0 then
    if n.sodium/s <= 400 then v_auto := array_append(v_auto, 'low_sodium'::text); end if;
    if n.protein/s >= 25 then v_auto := array_append(v_auto, 'high_protein'::text); end if;
    if n.fiber/s   >= 6  then v_auto := array_append(v_auto, 'high_fiber'::text);   end if;
    if n.sugar/s   <= 5  then v_auto := array_append(v_auto, 'low_sugar'::text);    end if;
    if n.kcal/s    <= 400 then v_auto := array_append(v_auto, 'low_calorie'::text); end if;
  end if;
  if r.total_minutes <= 20 then v_auto := array_append(v_auto, 'quick'::text); end if;

  update recipes set
    kcal = round(n.kcal/s), protein_g = round(n.protein/s,1), carb_g = round(n.carb/s,1), fat_g = round(n.fat/s,1),
    sat_fat_g = round(n.sat/s,1), fiber_g = round(n.fiber/s,1), sugar_g = round(n.sugar/s,1),
    sodium_mg = round(n.sodium/s), max_purine_level = n.purine,
    ingredient_tags = v_itags, allergen_ids = v_alg, diet_tags = v_diets, auto_tags = v_auto
  where id = p_recipe;
end $$;
revoke all on function public.recompute_recipe_nutrition(uuid) from public, anon, authenticated;

create or replace function public.trg_recipe_ing_recompute() returns trigger
language plpgsql security definer set search_path = public as $$
begin perform recompute_recipe_nutrition(coalesce(new.recipe_id, old.recipe_id)); return null; end $$;
create trigger t_recipe_ing_recompute after insert or update or delete on public.recipe_ingredients
  for each row execute function public.trg_recipe_ing_recompute();

create or replace function public.trg_recipe_servings_recompute() returns trigger
language plpgsql security definer set search_path = public as $$
begin perform recompute_recipe_nutrition(new.id); return null; end $$;
create trigger t_recipe_servings after update of base_servings, prep_minutes, cook_minutes on public.recipes
  for each row execute function public.trg_recipe_servings_recompute();

-- Chặn xuất bản khi công thức chưa đủ chi tiết
create or replace function public.trg_recipe_publish_guard() returns trigger
language plpgsql security definer set search_path = public as $$
declare n_steps int; n_ing int; n_short int; n_prep int;
begin
  if new.status = 'published' and old.status is distinct from 'published' then
    if auth.uid() is not null and not has_role(array['admin','nutritionist']::app_role[]) then
      raise exception 'FORBIDDEN'; end if;
    select count(*), count(*) filter (where char_length(instruction) < 20), count(*) filter (where phase = 'prep')
      into n_steps, n_short, n_prep from recipe_steps where recipe_id = new.id;
    select count(*) into n_ing from recipe_ingredients where recipe_id = new.id;
    if n_ing < 3   then raise exception 'NEED_3_INGREDIENTS'; end if;
    if n_steps < 4 then raise exception 'NEED_4_STEPS'; end if;
    if n_prep < 1  then raise exception 'NEED_PREP_STEP'; end if;        -- phải có bước sơ chế
    if n_short > 0 then raise exception 'STEP_TOO_SHORT'; end if;        -- mỗi bước ≥ 20 ký tự
    if new.image_url is null then raise exception 'NEED_IMAGE'; end if;
    if new.kcal is null then raise exception 'NUTRITION_MISSING'; end if;
    if cardinality(new.equipment) = 0 then raise exception 'NEED_EQUIPMENT'; end if;
    new.reviewed_by := auth.uid(); new.published_at := now();
  end if;
  return new;
end $$;
create trigger t_recipe_publish_guard before update on public.recipes
  for each row execute function public.trg_recipe_publish_guard();

-- ---------------------------------------------------------------------
-- 2. TÍNH MỤC TIÊU DINH DƯỠNG & NHÓM NGUY CƠ
-- ---------------------------------------------------------------------
create or replace function public.rpc_compute_targets() returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  p profiles%rowtype; v_age int; v_bmr numeric; v_tdee numeric; v_kcal numeric; v_act numeric; v_delta int;
  pp numeric; pc numeric; pf numeric; v_tier text := 'green'; v_sodium int; v_fiber int; v_bmi numeric;
begin
  select * into p from profiles where id = auth.uid();
  if p.id is null then raise exception 'NO_PROFILE'; end if;
  if p.consent_health_at is null then raise exception 'CONSENT_REQUIRED'; end if;
  if p.sex is null or p.birth_date is null or p.height_cm is null or p.weight_kg is null then
    raise exception 'PROFILE_INCOMPLETE'; end if;

  v_age := date_part('year', age(p.birth_date));
  v_bmi := p.weight_kg / power(p.height_cm/100, 2);
  v_bmr := 10*p.weight_kg + 6.25*p.height_cm - 5*v_age + case p.sex when 'male' then 5 else -161 end;
  v_act := case p.activity when 'sedentary' then 1.2 when 'light' then 1.375 when 'moderate' then 1.55
                           when 'active' then 1.725 else 1.9 end;
  v_tdee := v_bmr * v_act;
  v_delta := case p.goal when 'lose' then -500 when 'gain' then 300 when 'muscle' then 300 else 0 end;
  v_kcal := greatest(v_tdee + v_delta, case p.sex when 'male' then 1500 else 1200 end);   -- sàn an toàn

  pp := case p.goal when 'lose' then .28 when 'muscle' then .28 else .20 end;
  pc := case p.goal when 'lose' then .42 when 'muscle' then .47 else .50 end;
  pf := 1 - pp - pc;

  select min(r.max_sodium_mg), max(r.min_fiber_g) into v_sodium, v_fiber
  from user_health_conditions uc join condition_rules r on r.condition_id = uc.condition_id
    and r.is_active and r.approved_at is not null
  where uc.user_id = p.id;

  if v_age < 18 or v_bmi < 18.5
     or exists (select 1 from user_health_conditions uc join health_conditions h on h.id = uc.condition_id
                where uc.user_id = p.id and h.risk_tier = 'red') then v_tier := 'red';
  elsif exists (select 1 from user_health_conditions where user_id = p.id) then v_tier := 'yellow'; end if;

  update profiles set bmr = round(v_bmr,1), tdee = round(v_tdee,1), target_kcal = round(v_kcal),
    target_protein_g = round(v_kcal*pp/4), target_carb_g = round(v_kcal*pc/4), target_fat_g = round(v_kcal*pf/9),
    target_fiber_g = coalesce(v_fiber, case p.sex when 'male' then 30 else 25 end),
    max_sodium_mg = coalesce(v_sodium, 2000), max_sugar_g = round(v_kcal*0.10/4),
    risk_tier = v_tier, onboarding_done = true
  where id = p.id;

  return jsonb_build_object('bmr', round(v_bmr,1), 'tdee', round(v_tdee,1), 'kcal', round(v_kcal),
                            'bmi', round(v_bmi,1), 'risk_tier', v_tier, 'can_auto_plan', v_tier <> 'red');
end $$;
revoke all on function public.rpc_compute_targets() from public, anon;
grant execute on function public.rpc_compute_targets() to authenticated;

-- ---------------------------------------------------------------------
-- 3. GỢI Ý / TÌM KIẾM CÔNG THỨC (lọc cứng + chấm điểm) — dùng chung cho UI & AI
-- ---------------------------------------------------------------------
create or replace function public.rpc_recommend_recipes(
  p_q text default null, p_meal meal_type default null, p_max_minutes int default null,
  p_cuisines text[] default null, p_methods text[] default null, p_spice_max smallint default null,
  p_eater_groups text[] default null,           -- {'child','teen','adult','senior'}: người sẽ ăn
  p_include_avoid boolean default false,
  p_limit int default 24, p_offset int default 0)
returns table (
  id uuid, slug text, title text, summary text, image_url text, meal meal_type[], cuisine text, method text,
  spice_level smallint, difficulty smallint, total_minutes int, base_servings int,
  kcal int, protein_g numeric, carb_g numeric, fat_g numeric, fiber_g numeric, sodium_mg int,
  tags text[], verdict text, score numeric, reasons text[])
language plpgsql stable security definer set search_path = public as $$
#variable_conflict use_column
declare
  v_uid uuid := auth.uid(); p profiles%rowtype;
  v_allergens smallint[] := '{}'; v_excl text[] := '{}'; v_pref text[] := '{}';
  v_ps_sodium int; v_ps_sugar int; v_max_purine smallint;
  v_spice int; v_groups text[]; v_self text; v_use_kcal boolean; v_meal_kcal numeric; v_tsq tsquery;
begin
  if v_uid is not null then select * into p from profiles where id = v_uid; end if;

  if p.id is not null then
    select coalesce(array_agg(allergen_id), '{}') into v_allergens from user_allergies where user_id = p.id;
    select coalesce(array_agg(distinct t), '{}') into v_excl
      from user_health_conditions uc join condition_rules r on r.condition_id = uc.condition_id
        and r.is_active and r.approved_at is not null
      cross join lateral unnest(r.excluded_ingredient_tags) t where uc.user_id = p.id;
    select coalesce(array_agg(distinct t), '{}') into v_pref
      from user_health_conditions uc join condition_rules r on r.condition_id = uc.condition_id
        and r.is_active and r.approved_at is not null
      cross join lateral unnest(r.preferred_tags) t where uc.user_id = p.id;
    select min(r.per_serving_max_sodium_mg), min(r.per_serving_max_sugar_g), min(r.max_purine_level)
      into v_ps_sodium, v_ps_sugar, v_max_purine
      from user_health_conditions uc join condition_rules r on r.condition_id = uc.condition_id
        and r.is_active and r.approved_at is not null
      where uc.user_id = p.id;
  end if;

  -- người ăn: mặc định là chính người dùng
  v_self := age_group_of(p.birth_date);
  v_groups := coalesce(p_eater_groups, case when v_self is null then '{}'::text[] else array[v_self] end);

  v_spice := least(coalesce(p_spice_max, 3), coalesce(p.spice_level, 3));
  if 'child' = any(v_groups) then v_spice := least(v_spice, 1); v_excl := v_excl || array['alcohol','caffeine']; end if;
  if 'teen'  = any(v_groups) then v_excl := v_excl || array['alcohol']; end if;
  if 'senior' = any(v_groups) then v_ps_sodium := least(coalesce(v_ps_sodium, 600), 600); end if;

  -- chỉ dùng "khớp kcal" khi tất cả người ăn là người lớn & không thuộc nhóm đỏ
  v_use_kcal := coalesce(p.risk_tier, 'green') <> 'red' and v_groups <@ array['adult'];
  v_meal_kcal := coalesce(p.target_kcal, 2000) * case p_meal when 'breakfast' then .25 when 'lunch' then .35
                                                 when 'dinner' then .30 when 'snack' then .10 else .30 end;
  v_tsq := case when p_q is null or btrim(p_q) = '' then null
                else websearch_to_tsquery('simple', public.f_unaccent(p_q)) end;

  return query
  with cand as (
    select r.*, (r.tags || r.auto_tags) as all_tags,
      array_remove(array[
        case when r.allergen_ids && v_allergens then 'ALLERGEN' end,
        case when p.diet is not null and p.diet <> 'normal' and not (p.diet = any(r.diet_tags)) then 'DIET' end,
        case when r.ingredient_tags && v_excl or (r.tags || r.auto_tags) && v_excl then 'CONDITION_EXCLUDED' end,
        case when exists (select 1 from recipe_ingredients ri where ri.recipe_id = r.id
                          and ri.ingredient_id = any(coalesce(p.disliked_ingredient_ids, '{}'))) then 'DISLIKE' end,
        case when r.spice_level > v_spice then 'TOO_SPICY' end
      ]::text[], null) as avoid_r,
      array_remove(array[
        case when v_ps_sodium  is not null and r.sodium_mg > v_ps_sodium then 'SODIUM_HIGH' end,
        case when v_ps_sugar   is not null and r.sugar_g   > v_ps_sugar  then 'SUGAR_HIGH'  end,
        case when v_max_purine is not null and r.max_purine_level > v_max_purine then 'PURINE_HIGH' end
      ]::text[], null) as warn_r
    from recipes r
    where r.status = 'published'
      and (p_meal is null or p_meal = any(r.meal))
      and (v_tsq is null or r.search @@ v_tsq)
      and (p_cuisines is null or r.cuisine = any(p_cuisines))
      and (p_methods  is null or r.method  = any(p_methods))
      and r.total_minutes <= least(coalesce(p_max_minutes, 100000), coalesce(p.max_cook_minutes, 100000))
      and not exists (select 1 from recipe_feedback f
                      where f.user_id = v_uid and f.recipe_id = r.id and f.reaction = 'dislike')
  ), scored as (
    select c.*,
      round((
          case when v_use_kcal and v_meal_kcal > 0
               then 30 * (1 - least(1, abs(coalesce(c.kcal,0) - v_meal_kcal) / v_meal_kcal)) else 15 end
        + 20 * case when cardinality(v_pref) = 0 then 0.5
               else cardinality(array(select unnest(c.all_tags) intersect select unnest(v_pref)))::numeric / cardinality(v_pref) end
        + 10 * greatest(0, 1 - c.total_minutes::numeric / 90)
        + 15 * case when cardinality(coalesce(p.preferred_cuisines, '{}')) = 0
                      or c.cuisine = any(p.preferred_cuisines) then 1 else 0.4 end
        +  5 * case when coalesce(c.method = any(p.favorite_methods), false) then 1 else 0 end
        + 10 * (c.avg_rating / 5)
        +  5 * case when exists (select 1 from favorites fv where fv.user_id = v_uid and fv.recipe_id = c.id) then 1 else 0 end
        +  5 * case when exists (select 1 from recipe_feedback f where f.user_id = v_uid and f.recipe_id = c.id
                                 and f.reaction in ('like','cooked')) then 1 else 0 end
        - 10 * cardinality(c.warn_r)
        - 50 * cardinality(c.avoid_r)
      )::numeric, 1) as sc
    from cand c
  )
  select s.id, s.slug, s.title, s.summary, s.image_url, s.meal, s.cuisine, s.method, s.spice_level, s.difficulty,
         s.total_minutes, s.base_servings, s.kcal, s.protein_g, s.carb_g, s.fat_g, s.fiber_g, s.sodium_mg, s.all_tags,
         (case when cardinality(s.avoid_r) > 0 then 'avoid' when cardinality(s.warn_r) > 0 then 'caution' else 'suitable' end)::text,
         s.sc, s.avoid_r || s.warn_r
  from scored s
  where cardinality(s.avoid_r) = 0 or p_include_avoid
  order by s.sc desc, s.published_at desc nulls last
  limit least(p_limit, 100) offset greatest(p_offset, 0);
end $$;
revoke all on function public.rpc_recommend_recipes(text,meal_type,int,text[],text[],smallint,text[],boolean,int,int) from public;
grant execute on function public.rpc_recommend_recipes(text,meal_type,int,text[],text[],smallint,text[],boolean,int,int) to anon, authenticated;

-- ---------------------------------------------------------------------
-- 4. TÍNH LẠI NGUYÊN LIỆU THEO SỐ KHẨU PHẦN
-- ---------------------------------------------------------------------
create or replace function public.rpc_scale_recipe(p_recipe uuid, p_servings numeric) returns jsonb
language plpgsql stable security invoker set search_path = public as $$
declare r recipes%rowtype; ratio numeric; res jsonb;
begin
  if p_servings is null or p_servings <= 0 or p_servings > 50 then raise exception 'INVALID_SERVINGS'; end if;
  select * into r from recipes where id = p_recipe;           -- RLS: chỉ thấy bản đã xuất bản
  if r.id is null then raise exception 'RECIPE_NOT_FOUND'; end if;
  ratio := p_servings / r.base_servings;

  select jsonb_build_object(
    'servings', p_servings, 'base_servings', r.base_servings,
    'ingredients', coalesce(jsonb_agg(jsonb_build_object(
      'id', ri.id, 'name', i.name_vi, 'group', ri.group_name,
      'amount_g', round(ri.amount_g * f.k, 1),
      'display_amount', case when ri.display_amount is null then null else round(ri.display_amount * f.k * 4) / 4 end,
      'display_unit', ri.display_unit, 'prep_note', ri.prep_note, 'note', ri.note, 'optional', ri.optional)
      order by ri.group_name, ri.sort_order), '[]'::jsonb),
    'nutrition_per_serving', jsonb_build_object('kcal', r.kcal, 'protein_g', r.protein_g, 'carb_g', r.carb_g,
       'fat_g', r.fat_g, 'fiber_g', r.fiber_g, 'sodium_mg', r.sodium_mg),
    'nutrition_total', jsonb_build_object('kcal', round(r.kcal * p_servings), 'protein_g', round(r.protein_g * p_servings, 1),
       'carb_g', round(r.carb_g * p_servings, 1), 'fat_g', round(r.fat_g * p_servings, 1)))
  into res
  from recipe_ingredients ri join ingredients i on i.id = ri.ingredient_id
  cross join lateral (select case ri.scale_mode when 'fixed' then 1::numeric
                                                when 'sublinear' then sqrt(ratio) else ratio end as k) f
  where ri.recipe_id = p_recipe;
  return res;
end $$;
grant execute on function public.rpc_scale_recipe(uuid, numeric) to anon, authenticated;

-- ---------------------------------------------------------------------
-- 5. TÍN HIỆU KHẨU VỊ (từ like/dislike/đã nấu) — dùng cá nhân hóa AI
-- ---------------------------------------------------------------------
create or replace function public.rpc_taste_signals() returns jsonb
language sql stable security definer set search_path = public as $$
  with fb as (
    select (r.tags || r.auto_tags) as t, r.cuisine, r.method, r.title, f.reaction, f.reason, f.created_at
    from recipe_feedback f join recipes r on r.id = f.recipe_id
    where f.user_id = auth.uid() and f.created_at > now() - interval '120 days')
  select jsonb_build_object(
    'liked_tags', coalesce((select jsonb_agg(x.tag) from (
        select tag from fb, unnest(fb.t) as tag where fb.reaction in ('like','cooked')
        group by tag order by count(*) desc limit 8) x), '[]'::jsonb),
    'liked_cuisines', coalesce((select jsonb_agg(x.cuisine) from (
        select cuisine from fb where reaction in ('like','cooked') group by cuisine order by count(*) desc limit 3) x), '[]'::jsonb),
    'liked_methods', coalesce((select jsonb_agg(x.method) from (
        select method from fb where reaction in ('like','cooked') and method is not null
        group by method order by count(*) desc limit 3) x), '[]'::jsonb),
    'disliked_reasons', coalesce((select jsonb_agg(x.reason) from (
        select reason from fb where reaction = 'dislike' and reason is not null order by created_at desc limit 5) x), '[]'::jsonb),
    'disliked_titles', coalesce((select jsonb_agg(x.title) from (
        select title from fb where reaction = 'dislike' order by created_at desc limit 5) x), '[]'::jsonb));
$$;
revoke all on function public.rpc_taste_signals() from public, anon;
grant execute on function public.rpc_taste_signals() to authenticated;

-- ---------------------------------------------------------------------
-- 6. SINH THỰC ĐƠN (không lặp 3 ngày gần nhất, chỉnh khẩu phần theo kcal)
-- ---------------------------------------------------------------------
create or replace function public.rpc_generate_meal_plan(
  p_start date default current_date, p_days int default 7,
  p_meals meal_type[] default array['breakfast','lunch','dinner']::meal_type[]) returns uuid
language plpgsql security invoker set search_path = public as $$
declare
  v_uid uuid := auth.uid(); p profiles%rowtype; v_plan uuid; d int; m meal_type;
  pick record; used uuid[] := '{}'; v_sum numeric; v_f numeric;
begin
  select * into p from profiles where id = v_uid;
  if p.id is null then raise exception 'NO_PROFILE'; end if;
  if p.consent_health_at is null then raise exception 'CONSENT_REQUIRED'; end if;
  if p.risk_tier = 'red' then raise exception 'PLAN_NOT_ALLOWED'; end if;
  if p.target_kcal is null then raise exception 'PROFILE_INCOMPLETE'; end if;
  if p_days < 1 or p_days > 14 then raise exception 'INVALID_DAYS'; end if;

  insert into meal_plans(user_id, start_date, days, target_snapshot)
  values (v_uid, p_start, p_days, jsonb_build_object('kcal', p.target_kcal, 'protein_g', p.target_protein_g,
          'carb_g', p.target_carb_g, 'fat_g', p.target_fat_g)) returning id into v_plan;

  for d in 0 .. p_days - 1 loop
    foreach m in array p_meals loop
      select rr.id into pick from public.rpc_recommend_recipes(p_meal => m, p_limit => 40) rr
       where rr.id <> all(used)
       order by rr.score + random() * 12 desc limit 1;
      if pick.id is null then       -- hết món mới → cho phép lặp
        select rr.id into pick from public.rpc_recommend_recipes(p_meal => m, p_limit => 40) rr
         order by random() limit 1;
      end if;
      if pick.id is not null then
        insert into meal_plan_items(plan_id, day_index, meal, recipe_id, servings)
        values (v_plan, d, m, pick.id, 1) on conflict do nothing;
        used := used || pick.id;
      end if;
    end loop;

    select sum(r.kcal * i.servings) into v_sum
      from meal_plan_items i join recipes r on r.id = i.recipe_id where i.plan_id = v_plan and i.day_index = d;
    if coalesce(v_sum, 0) > 0 then
      v_f := least(1.5, greatest(0.75, round((p.target_kcal / v_sum) * 4) / 4));
      update meal_plan_items set servings = v_f where plan_id = v_plan and day_index = d;
    end if;
    if cardinality(used) > 9 then used := used[cardinality(used) - 8 : cardinality(used)]; end if;
  end loop;
  return v_plan;
end $$;
grant execute on function public.rpc_generate_meal_plan(date, int, meal_type[]) to authenticated;

-- ---------------------------------------------------------------------
-- 7. QUYỀN RIÊNG TƯ: xuất dữ liệu
-- ---------------------------------------------------------------------
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
    'ai_runs',      (select coalesce(jsonb_agg(jsonb_build_object('at', r.created_at, 'input', r.input)), '[]')
                       from ai_runs r where r.user_id = auth.uid()));
$$;
revoke all on function public.rpc_export_my_data() from public, anon;
grant execute on function public.rpc_export_my_data() to authenticated;

-- ---------------------------------------------------------------------
-- 8. DỌN DẸP ĐỊNH KỲ (bỏ qua nếu pg_cron chưa bật)
-- ---------------------------------------------------------------------
do $$ begin
  create extension if not exists pg_cron;
  perform cron.schedule('purge-ai-runs', '15 3 * * *',
    $q$delete from public.ai_runs where created_at < now() - interval '90 days'$q$);
  perform cron.schedule('purge-audit', '30 3 * * 0',
    $q$delete from public.audit_log where created_at < now() - interval '180 days'$q$);
exception when others then raise notice 'pg_cron chưa khả dụng: %', sqlerrm;
end $$;
