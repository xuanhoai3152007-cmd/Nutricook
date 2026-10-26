import { getSupabaseClient } from '../lib/supabase.js'

export async function getShoppingList(recipeServings) {
  const { data, error } = await getSupabaseClient().rpc('rpc_shopping_list', {
    p_items: recipeServings,
  })

  if (error) throw error
  return data
}
