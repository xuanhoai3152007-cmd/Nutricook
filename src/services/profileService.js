import { getSupabaseClient } from '../lib/supabase.js'

const conditionCodeByValue = {
  diabetes: 'diabetes_t2',
  hypertension: 'hypertension',
  'high-cholesterol': 'dyslipidemia',
  gout: 'gout',
  kidney: 'ckd',
  stomach: 'gastritis',
  anemia: 'anemia',
  overweight: 'overweight',
  obesity: 'obesity',
  pregnancy: 'pregnancy',
  breastfeeding: 'breastfeeding',
  'eating-disorder': 'eating_disorder',
}

const allergenCodeByValue = {
  'Đậu phộng': ['peanut'],
  'Hải sản': ['fish', 'shellfish'],
  'Tôm cua': ['shellfish'],
  'Sữa': ['milk'],
  'Trứng': ['egg'],
  Gluten: ['gluten'],
  'Đậu nành': ['soy'],
  'Vừng': ['sesame'],
}

function throwIfError({ error }) {
  if (error) throw error
}

export async function loadUserProfile(userId) {
  const client = getSupabaseClient()
  const [profileResult, conditionsResult, allergiesResult] = await Promise.all([
    client.from('profiles')
      .select('sex, birth_date, height_cm, weight_kg, goal, target_weight_kg, activity, diet, max_cook_minutes, budget_level, cooking_skill, disliked_ingredients, onboarding_done, consent_health_at')
      .eq('id', userId)
      .maybeSingle(),
    client.from('user_health_conditions')
      .select('health_conditions(code)')
      .eq('user_id', userId),
    client.from('user_allergies')
      .select('allergens(code)')
      .eq('user_id', userId),
  ])

  throwIfError(profileResult)
  throwIfError(conditionsResult)
  throwIfError(allergiesResult)

  const row = profileResult.data
  if (!row) return null

  const conditionValues = new Map(Object.entries(conditionCodeByValue).map(([value, code]) => [code, value]))
  const allergenValues = new Map(Object.entries(allergenCodeByValue).flatMap(([value, codes]) => codes.map((code) => [code, value])))
  const conditions = [...new Set((conditionsResult.data ?? [])
    .map((item) => conditionValues.get(item.health_conditions?.code))
    .filter(Boolean))]
  const allergenCodes = new Set((allergiesResult.data ?? []).map((item) => item.allergens?.code))
  const allergies = allergenCodes.has('fish') && allergenCodes.has('shellfish')
    ? ['Hải sản', ...[...allergenCodes].filter((code) => !['fish', 'shellfish'].includes(code)).map((code) => allergenValues.get(code)).filter(Boolean)]
    : [...allergenCodes].map((code) => allergenValues.get(code)).filter(Boolean)

  return {
    sex: row.sex ?? '',
    birthDate: row.birth_date ?? '',
    heightCm: row.height_cm?.toString() ?? '',
    weightKg: row.weight_kg?.toString() ?? '',
    goal: row.goal ?? '',
    targetWeightKg: row.target_weight_kg?.toString() ?? '',
    activity: row.activity ?? '',
    conditions,
    diet: row.diet === 'normal' ? 'balanced' : row.diet === 'low_carb' ? 'low-carb' : row.diet ?? 'balanced',
    allergies,
    dislikedIngredients: row.disliked_ingredients ?? '',
    cookingTime: row.max_cook_minutes?.toString() ?? '30',
    budget: row.budget_level ?? 'medium',
    cookingSkill: row.cooking_skill === 1 ? 'beginner' : row.cooking_skill === 3 ? 'advanced' : 'intermediate',
    saved: Boolean(row.onboarding_done && row.consent_health_at),
  }
}

export async function saveUserProfile(profile) {
  const client = getSupabaseClient()
  const conditionCodes = [...new Set(profile.conditions.map((value) => conditionCodeByValue[value]).filter(Boolean))]
  const allergenCodes = [...new Set(profile.allergies.flatMap((value) => allergenCodeByValue[value] ?? []))]

  const { data, error } = await client.rpc('rpc_save_user_profile', {
    p_profile: {
      sex: profile.sex,
      birth_date: profile.birthDate,
      height_cm: Number(profile.heightCm),
      weight_kg: Number(profile.weightKg),
      goal: profile.goal,
      target_weight_kg: profile.targetWeightKg ? Number(profile.targetWeightKg) : null,
      activity: profile.activity,
      diet: profile.diet === 'balanced' ? 'normal' : profile.diet === 'low-carb' ? 'low_carb' : profile.diet,
      max_cook_minutes: Number(profile.cookingTime),
      budget_level: profile.budget,
      cooking_skill: profile.cookingSkill === 'beginner' ? 1 : profile.cookingSkill === 'advanced' ? 3 : 2,
      disliked_ingredients: profile.dislikedIngredients.trim(),
    },
    p_condition_codes: conditionCodes,
    p_allergen_codes: allergenCodes,
    p_consent: true,
  })

  if (error) throw error
  return data
}
