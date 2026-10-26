-- =====================================================================
-- NutriCook · Migration 2 · RLS (mặc định TỪ CHỐI) + Storage
-- =====================================================================

do $$ declare t text; begin
  for t in select tablename from pg_tables where schemaname = 'public' loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

-- ---------- profiles ----------
create policy profile_select on public.profiles for select to authenticated
  using (id = auth.uid() or public.has_role(array['admin','nutritionist']::app_role[]));
create policy profile_update on public.profiles for update to authenticated
  using (id = auth.uid() or public.has_role(array['admin']::app_role[]))
  with check (id = auth.uid() or public.has_role(array['admin']::app_role[]));
-- (cột role được bảo vệ bởi trigger profiles_guard; insert do trigger handle_new_user)
revoke update on public.profiles from authenticated;
grant update (
  full_name, avatar_url, sex, birth_date, height_cm, weight_kg, activity, goal, diet,
  target_weight_kg, spice_level, taste_prefs, preferred_cuisines, favorite_methods,
  cooking_skill, max_cook_minutes, default_servings, household, disliked_ingredient_ids,
  consent_health_at, ai_consent_at
) on public.profiles to authenticated;

-- ---------- dữ liệu cá nhân: chỉ chủ sở hữu ----------
do $$ declare t text; begin
  foreach t in array array['body_metrics','user_health_conditions','user_allergies','favorites',
                           'recipe_feedback','meal_plans','food_logs'] loop
    execute format('create policy own_rows on public.%I for all to authenticated
                    using (user_id = auth.uid()) with check (user_id = auth.uid())', t);
  end loop;
end $$;

create policy own_items on public.meal_plan_items for all to authenticated
  using (exists (select 1 from public.meal_plans m where m.id = plan_id and m.user_id = auth.uid()))
  with check (exists (select 1 from public.meal_plans m where m.id = plan_id and m.user_id = auth.uid()));

-- ---------- danh mục công khai (đọc) ----------
create policy pub_read on public.allergens          for select using (true);
create policy pub_read on public.health_conditions  for select using (true);
create policy pub_read on public.condition_rules    for select using (is_active and approved_at is not null);
create policy pub_read on public.ingredients        for select using (true);
create policy pub_read on public.ingredient_allergens for select using (true);

create policy pub_read on public.recipes for select
  using (status = 'published' or public.has_role(array['admin','nutritionist']::app_role[]));
create policy pub_read on public.recipe_ingredients for select
  using (exists (select 1 from public.recipes r where r.id = recipe_id
         and (r.status = 'published' or public.has_role(array['admin','nutritionist']::app_role[]))));
create policy pub_read on public.recipe_steps for select
  using (exists (select 1 from public.recipes r where r.id = recipe_id
         and (r.status = 'published' or public.has_role(array['admin','nutritionist']::app_role[]))));
create policy pub_read on public.reviews for select using (true);

-- ---------- ghi nội dung: nutritionist/admin ----------
do $$ declare t text; begin
  foreach t in array array['recipes','recipe_ingredients','recipe_steps','ingredients','ingredient_allergens'] loop
    execute format('create policy staff_write on public.%I for all to authenticated
      using (public.has_role(array[''admin'',''nutritionist'']::app_role[]))
      with check (public.has_role(array[''admin'',''nutritionist'']::app_role[]))', t);
  end loop;
end $$;
create policy admin_write on public.condition_rules for all to authenticated
  using (public.has_role(array['admin','nutritionist']::app_role[]))
  with check (public.has_role(array['admin','nutritionist']::app_role[]));

create policy review_insert on public.reviews for insert to authenticated with check (user_id = auth.uid());
create policy review_update on public.reviews for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy review_delete on public.reviews for delete to authenticated
  using (user_id = auth.uid() or public.has_role(array['admin']::app_role[]));

-- ---------- AI & audit ----------
create policy ai_runs_own_read on public.ai_runs for select to authenticated using (user_id = auth.uid());
-- ai_runs: KHÔNG có policy ghi → chỉ Edge Function (service role) ghi
create policy audit_admin_read on public.audit_log for select to authenticated
  using (public.has_role(array['admin']::app_role[]));

-- ---------- Storage ----------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('recipe-images','recipe-images', true, 2097152, '{image/webp,image/jpeg,image/png}'),
  ('avatars','avatars', true, 1048576, '{image/webp,image/jpeg,image/png}')
on conflict (id) do nothing;

create policy "img_public_read" on storage.objects for select
  using (bucket_id in ('recipe-images','avatars'));
create policy "recipe_img_staff_write" on storage.objects for insert to authenticated
  with check (bucket_id = 'recipe-images' and public.has_role(array['admin','nutritionist']::app_role[]));
create policy "recipe_img_staff_update" on storage.objects for update to authenticated
  using (bucket_id = 'recipe-images' and public.has_role(array['admin','nutritionist']::app_role[]));
create policy "avatar_own_write" on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "avatar_own_update" on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
