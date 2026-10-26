create or replace function public.rpc_admin_list_accounts(
  p_query text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table (
  id uuid,
  email text,
  full_name text,
  role public.app_role,
  created_at timestamptz
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
  select p.id, u.email::text, p.full_name, p.role, p.created_at
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

create or replace function public.rpc_admin_create_recipe(
  p_recipe jsonb,
  p_ingredients jsonb,
  p_steps jsonb,
  p_publish boolean default false
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_recipe_id uuid;
  v_ingredient jsonb;
  v_step jsonb;
  v_meals public.meal_type[];
  v_diet_tags public.diet_type[];
begin
  if not public.has_role(array['admin']::public.app_role[]) then
    raise exception 'FORBIDDEN';
  end if;
  if jsonb_typeof(p_recipe) <> 'object'
     or jsonb_typeof(p_ingredients) <> 'array'
     or jsonb_typeof(p_steps) <> 'array' then
    raise exception 'INVALID_RECIPE_PAYLOAD';
  end if;
  if nullif(trim(p_recipe->>'title'), '') is null
     or nullif(trim(p_recipe->>'slug'), '') is null
     or jsonb_array_length(p_ingredients) = 0
     or jsonb_array_length(p_steps) = 0 then
    raise exception 'RECIPE_FIELDS_REQUIRED';
  end if;

  select array_agg(value::public.meal_type)
  into v_meals
  from jsonb_array_elements_text(coalesce(p_recipe->'meal', '[]'::jsonb)) as item(value);
  select array_agg(value::public.diet_type)
  into v_diet_tags
  from jsonb_array_elements_text(coalesce(p_recipe->'diet_tags', '["normal"]'::jsonb)) as item(value);

  insert into public.recipes (
    slug, title, summary, intro, image_url, meal, cuisine, method, base_servings,
    prep_minutes, cook_minutes, difficulty, equipment, tips, diet_tags, tags,
    kcal, protein_g, carb_g, fat_g, status, author_id
  ) values (
    trim(p_recipe->>'slug'),
    trim(p_recipe->>'title'),
    nullif(trim(p_recipe->>'summary'), ''),
    nullif(trim(p_recipe->>'intro'), ''),
    nullif(trim(p_recipe->>'image_url'), ''),
    coalesce(v_meals, array['lunch']::public.meal_type[]),
    coalesce(nullif(p_recipe->>'cuisine', ''), 'viet'),
    nullif(trim(p_recipe->>'method'), ''),
    coalesce(nullif(p_recipe->>'base_servings', '')::integer, 2),
    coalesce(nullif(p_recipe->>'prep_minutes', '')::integer, 0),
    coalesce(nullif(p_recipe->>'cook_minutes', '')::integer, 0),
    coalesce(nullif(p_recipe->>'difficulty', '')::smallint, 1),
    array(select jsonb_array_elements_text(coalesce(p_recipe->'equipment', '[]'::jsonb))),
    array(select jsonb_array_elements_text(coalesce(p_recipe->'tips', '[]'::jsonb))),
    coalesce(v_diet_tags, array['normal']::public.diet_type[]),
    array(select jsonb_array_elements_text(coalesce(p_recipe->'tags', '[]'::jsonb))),
    nullif(p_recipe->>'kcal', '')::integer,
    nullif(p_recipe->>'protein_g', '')::numeric,
    nullif(p_recipe->>'carb_g', '')::numeric,
    nullif(p_recipe->>'fat_g', '')::numeric,
    'draft',
    auth.uid()
  )
  returning id into v_recipe_id;

  for v_ingredient in select value from jsonb_array_elements(p_ingredients)
  loop
    insert into public.recipe_ingredients (
      recipe_id, ingredient_id, group_name, amount_g, display_amount,
      display_unit, optional, sort_order
    ) values (
      v_recipe_id,
      (v_ingredient->>'ingredient_id')::uuid,
      coalesce(nullif(trim(v_ingredient->>'group_name'), ''), 'Nguyên liệu chính'),
      (v_ingredient->>'amount_g')::numeric,
      nullif(v_ingredient->>'display_amount', '')::numeric,
      nullif(trim(v_ingredient->>'display_unit'), ''),
      coalesce((v_ingredient->>'optional')::boolean, false),
      coalesce((v_ingredient->>'sort_order')::integer, 0)
    );
  end loop;

  for v_step in select value from jsonb_array_elements(p_steps)
  loop
    insert into public.recipe_steps (
      recipe_id, step_no, phase, title, instruction, heat
    ) values (
      v_recipe_id,
      (v_step->>'step_no')::integer,
      coalesce(nullif(v_step->>'phase', ''), 'cook'),
      trim(v_step->>'title'),
      trim(v_step->>'instruction'),
      coalesce(nullif(v_step->>'heat', ''), 'none')
    );
  end loop;

  if coalesce(p_publish, false) then
    update public.recipes set status = 'published' where id = v_recipe_id;
  end if;

  return v_recipe_id;
end;
$$;

revoke all on function public.rpc_admin_create_recipe(jsonb, jsonb, jsonb, boolean) from public, anon;
grant execute on function public.rpc_admin_create_recipe(jsonb, jsonb, jsonb, boolean) to authenticated;
