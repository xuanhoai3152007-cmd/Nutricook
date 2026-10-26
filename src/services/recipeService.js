import { getSupabaseClient } from '../lib/supabase.js'

export async function getRecommendedRecipes({
  query = null,
  meal = null,
  maxMinutes = null,
  cuisines = null,
  methods = null,
  spiceMax = null,
  eaterGroups = null,
  includeAvoid = false,
  limit = 24,
  offset = 0,
} = {}) {
  const { data, error } = await getSupabaseClient().rpc('rpc_recommend_recipes', {
    p_q: query,
    p_meal: meal,
    p_max_minutes: maxMinutes,
    p_cuisines: cuisines,
    p_methods: methods,
    p_spice_max: spiceMax,
    p_eater_groups: eaterGroups,
    p_include_avoid: includeAvoid,
    p_limit: limit,
    p_offset: offset,
  })

  if (error) throw error
  return data
}

export async function getRecipeBySlug(slug) {
  const client = getSupabaseClient()
  const { data: recipe, error: recipeError } = await client
    .from('recipes')
    .select('*')
    .eq('slug', slug)
    .single()

  if (recipeError) throw recipeError

  const [ingredientsResult, stepsResult] = await Promise.all([
    client
      .from('recipe_ingredients')
      .select('*, ingredient:ingredients(*)')
      .eq('recipe_id', recipe.id)
      .order('sort_order'),
    client
      .from('recipe_steps')
      .select('*')
      .eq('recipe_id', recipe.id)
      .order('step_no'),
  ])

  if (ingredientsResult.error) throw ingredientsResult.error
  if (stepsResult.error) throw stepsResult.error

  return { recipe, ingredients: ingredientsResult.data, steps: stepsResult.data }
}

export async function scaleRecipe(recipeId, servings) {
  const { data, error } = await getSupabaseClient().rpc('rpc_scale_recipe', {
    p_recipe: recipeId,
    p_servings: servings,
  })

  if (error) throw error
  return data
}
