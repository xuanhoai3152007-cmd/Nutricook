alter table public.profiles
  add column budget_level text not null default 'medium'
    check (budget_level in ('low', 'medium', 'high')),
  add column disliked_ingredients text not null default ''
    check (char_length(disliked_ingredients) <= 500);

grant update (
  sex, birth_date, height_cm, weight_kg, activity, goal, diet,
  target_weight_kg, max_cook_minutes, cooking_skill, budget_level,
  disliked_ingredients, consent_health_at, onboarding_done
) on public.profiles to authenticated;

insert into public.health_conditions (code, name_vi, risk_tier, description) values
  ('overweight', 'Thừa cân', 'yellow', 'Tình trạng cân nặng do người dùng tự khai báo.'),
  ('breastfeeding', 'Đang cho con bú', 'red', 'Nhu cầu dinh dưỡng đặc biệt; cần chuyên gia y tế hướng dẫn.'),
  ('eating_disorder', 'Tiền sử rối loạn ăn uống', 'red', 'Cần chuyên gia y tế hướng dẫn; không tạo mục tiêu tự động.')
on conflict (code) do nothing;

comment on column public.profiles.budget_level is 'Ngân sách mỗi bữa do chủ tài khoản lựa chọn.';
comment on column public.profiles.disliked_ingredients is 'Nguyên liệu không thích, văn bản do chủ tài khoản nhập.';

create or replace function public.rpc_save_user_profile(
  p_profile jsonb,
  p_condition_codes text[] default '{}',
  p_allergen_codes text[] default '{}',
  p_consent boolean default false
) returns void
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_requested_conditions int;
  v_saved_conditions int;
  v_requested_allergens int;
  v_saved_allergens int;
begin
  if v_user_id is null then raise exception 'UNAUTHENTICATED'; end if;
  if jsonb_typeof(p_profile) is distinct from 'object' then raise exception 'PROFILE_REQUIRED'; end if;
  if p_consent is distinct from true then raise exception 'CONSENT_REQUIRED'; end if;
  if coalesce(p_profile->>'sex', '') = ''
     or coalesce(p_profile->>'birth_date', '') = ''
     or coalesce(p_profile->>'height_cm', '') = ''
     or coalesce(p_profile->>'weight_kg', '') = ''
     or coalesce(p_profile->>'activity', '') = ''
     or coalesce(p_profile->>'goal', '') = ''
     or coalesce(p_profile->>'diet', '') = '' then
    raise exception 'PROFILE_INCOMPLETE';
  end if;
  if coalesce(cardinality(p_condition_codes), 0) > 50
     or coalesce(cardinality(p_allergen_codes), 0) > 50 then
    raise exception 'PROFILE_SELECTION_LIMIT';
  end if;

  update public.profiles
  set sex = (p_profile->>'sex')::public.sex_type,
      birth_date = (p_profile->>'birth_date')::date,
      height_cm = (p_profile->>'height_cm')::numeric,
      weight_kg = (p_profile->>'weight_kg')::numeric,
      goal = (p_profile->>'goal')::public.goal_type,
      target_weight_kg = nullif(p_profile->>'target_weight_kg', '')::numeric,
      activity = (p_profile->>'activity')::public.activity_level,
      diet = (p_profile->>'diet')::public.diet_type,
      max_cook_minutes = nullif(p_profile->>'max_cook_minutes', '')::integer,
      budget_level = p_profile->>'budget_level',
      cooking_skill = (p_profile->>'cooking_skill')::smallint,
      disliked_ingredients = coalesce(p_profile->>'disliked_ingredients', ''),
      consent_health_at = now(),
      onboarding_done = true
  where id = v_user_id;

  if not found then raise exception 'PROFILE_NOT_FOUND'; end if;

  select count(distinct code) into v_requested_conditions
  from unnest(coalesce(p_condition_codes, '{}')) as requested(code);

  insert into public.user_health_conditions (user_id, condition_id)
  select v_user_id, condition.id
  from public.health_conditions as condition
  where condition.code = any(coalesce(p_condition_codes, '{}'))
  on conflict do nothing;

  select count(*) into v_saved_conditions
  from public.health_conditions as condition
  where condition.code = any(coalesce(p_condition_codes, '{}'));
  if v_saved_conditions <> v_requested_conditions then
    raise exception 'UNKNOWN_HEALTH_CONDITION';
  end if;

  select count(distinct code) into v_requested_allergens
  from unnest(coalesce(p_allergen_codes, '{}')) as requested(code);

  insert into public.user_allergies (user_id, allergen_id)
  select v_user_id, allergen.id
  from public.allergens as allergen
  where allergen.code = any(coalesce(p_allergen_codes, '{}'))
  on conflict do nothing;

  select count(*) into v_saved_allergens
  from public.allergens as allergen
  where allergen.code = any(coalesce(p_allergen_codes, '{}'));
  if v_saved_allergens <> v_requested_allergens then
    raise exception 'UNKNOWN_ALLERGEN';
  end if;

  delete from public.user_health_conditions
  where user_id = v_user_id
    and condition_id not in (
      select condition.id from public.health_conditions as condition
      where condition.code = any(coalesce(p_condition_codes, '{}'))
    );
  delete from public.user_allergies
  where user_id = v_user_id
    and allergen_id not in (
      select allergen.id from public.allergens as allergen
      where allergen.code = any(coalesce(p_allergen_codes, '{}'))
    );
end;
$$;

comment on function public.rpc_save_user_profile(jsonb, text[], text[], boolean) is
  'Lưu hồ sơ cho auth.uid() cùng các tình trạng sức khỏe và dị ứng; yêu cầu đồng ý xử lý dữ liệu sức khỏe.';
revoke all on function public.rpc_save_user_profile(jsonb, text[], text[], boolean) from public, anon;
grant execute on function public.rpc_save_user_profile(jsonb, text[], text[], boolean) to authenticated;
