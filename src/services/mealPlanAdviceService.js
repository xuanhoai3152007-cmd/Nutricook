import { getSupabaseClient } from '../lib/supabase.js'

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
    if (error.context instanceof Response) {
      const responseBody = await error.context.clone().json().catch(() => null)
      const failure = responseBody?.error
      if (typeof failure?.message === 'string' && failure.message) {
        throw new MealPlanAdviceError(failure.message, failure.code)
      }
    }
    throw new Error(error.message || 'Không thể tạo lời khuyên AI.')
  }
  if (data?.error) {
    throw new MealPlanAdviceError(
      data.error.message || 'Không thể tạo lời khuyên AI.',
      data.error.code,
    )
  }
  return data
}
