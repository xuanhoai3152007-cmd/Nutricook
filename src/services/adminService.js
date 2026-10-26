import { getSupabaseClient } from '../lib/supabase.js'

export async function getAdminAccounts(query = '') {
  const { data, error } = await getSupabaseClient().rpc('rpc_admin_list_accounts', {
    p_query: query.trim() || null,
    p_limit: 100,
    p_offset: 0,
  })

  if (error) throw error
  return data
}

export async function manageAdminAccount({ action, userId, reason, blockedUntil }) {
  const { data, error } = await getSupabaseClient().functions.invoke('admin-account-management', {
    body: { action, userId, reason, blockedUntil },
  })

  if (error) throw error
  if (data?.error) throw new Error(data.error.message || 'Không thể cập nhật tài khoản.')
  return data
}

export async function getAdminRecipes() {
  const { data, error } = await getSupabaseClient()
    .from('recipes')
    .select('id, title, status, meal, created_at')
    .order('created_at', { ascending: false })
    .limit(100)

  if (error) throw error
  return data
}

export async function getIngredientCatalog() {
  const { data, error } = await getSupabaseClient()
    .from('ingredients')
    .select('id, name_vi, category')
    .order('name_vi')
    .limit(500)

  if (error) throw error
  return data
}

export async function createAdminRecipe({ recipe, ingredients, steps, publish }) {
  const { data, error } = await getSupabaseClient().rpc('rpc_admin_create_recipe', {
    p_recipe: recipe,
    p_ingredients: ingredients,
    p_steps: steps,
    p_publish: publish,
  })

  if (error) throw error
  return data
}

export async function getPublishedRecipes() {
  const { data, error } = await getSupabaseClient()
    .from('recipes')
    .select(`
      id, title, summary, image_url, meal, base_servings, total_minutes, kcal, protein_g, carb_g, fat_g, sodium_mg,
      recipe_ingredients(amount_g, display_amount, display_unit, group_name, optional, scale_mode, ingredient:ingredients(name_vi, ingredient_allergens(allergen:allergens(name_vi)))),
      recipe_steps(step_no, phase, title, instruction, heat)
    `)
    .eq('status', 'published')
    .order('title')
    .limit(100)

  if (error) throw error

  return data.map((row) => {
    const meal = row.meal?.[0]
    const category = {
      breakfast: 'Bữa sáng',
      lunch: 'Bữa trưa',
      dinner: 'Bữa tối',
      snack: 'Bữa phụ',
    }[meal] ?? 'Món ăn'
    const imagePath = row.image_url?.startsWith('recipe-images/')
      ? row.image_url.slice('recipe-images/'.length)
      : row.image_url
    const image = imagePath?.startsWith('http')
      ? imagePath
      : imagePath
        ? getSupabaseClient().storage.from('recipe-images').getPublicUrl(imagePath).data.publicUrl
        : ''

    return {
      id: `database-${row.id}`,
      databaseId: row.id,
      title: row.title,
      description: row.summary ?? '',
      category,
      time: row.total_minutes ?? 0,
      baseServings: row.base_servings ?? 2,
      kcal: row.kcal ?? 0,
      protein: Number(row.protein_g ?? 0),
      tag: 'Công thức mới',
      image,
      detail: {
        ingredients: (row.recipe_ingredients ?? []).map((item) => ({
          name: item.ingredient?.name_vi ?? 'Nguyên liệu',
          amount: Number(item.display_amount ?? item.amount_g ?? 0),
          unit: item.display_unit ?? 'g',
          group: item.group_name ?? 'Nguyên liệu chính',
          scaleMode: item.scale_mode === 'sublinear' ? 'sublinear' : 'linear',
        })),
        steps: [...(row.recipe_steps ?? [])]
          .sort((left, right) => left.step_no - right.step_no)
          .map((step) => step.instruction),
        nutrition: {
          protein: Number(row.protein_g ?? 0),
          carb: Number(row.carb_g ?? 0),
          fat: Number(row.fat_g ?? 0),
          sodium: Number(row.sodium_mg ?? 0),
        },
        allergens: [...new Set((row.recipe_ingredients ?? []).flatMap((item) => (
          item.ingredient?.ingredient_allergens?.map((entry) => entry.allergen?.name_vi).filter(Boolean) ?? []
        )))],
      },
    }
  })
}
