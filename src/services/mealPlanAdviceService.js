import { getSupabaseClient } from '../lib/supabase.js'
import { getEdgeFunctionError } from './edgeFunctionError.js'

class MealPlanAdviceError extends Error {
  constructor(message, code) {
    super(message)
    this.name = 'MealPlanAdviceError'
    this.code = code
  }
}

export async function getMealPlanAdvice(stats) {
  const { data, error } = await getSupabaseClient().functions.invoke('meal-plan-advice', {
    body: { consent: true, stats },
  })

  if (error) {
    const details = await getEdgeFunctionError(error)
    const adviceError = new MealPlanAdviceError(details.message, details.code)
    adviceError.status = details.status
    throw adviceError
  }
  if (data?.error) {
    throw new MealPlanAdviceError(
      data.error.message || 'Không thể tạo lời khuyên AI.',
      data.error.code,
    )
  }
  return data
}
