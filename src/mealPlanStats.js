const DAY_NAMES = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']

function formatLocalDate(date) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

function getMonday(date) {
  const monday = new Date(date.getFullYear(), date.getMonth(), date.getDate())
  monday.setDate(monday.getDate() - ((monday.getDay() + 6) % 7))
  return monday
}

function summarizeDays(days, period, periodLabel) {
  const mealCount = days.reduce((total, day) => total + day.mealCount, 0)
  const totalKcal = days.reduce((total, day) => total + day.kcal, 0)
  const totalProtein = days.reduce((total, day) => total + day.protein, 0)
  const recordedDays = days.filter((day) => day.mealCount > 0).length
  const recipeCounts = new Map()

  days.forEach((day) => day.meals.forEach((meal) => {
    recipeCounts.set(meal.title, (recipeCounts.get(meal.title) ?? 0) + 1)
  }))

  const weekGroups = new Map()
  const monthStart = period === 'month' && days.length
    ? new Date(`${days[0].date}T00:00:00`)
    : null
  const firstWeekOffset = monthStart ? (monthStart.getDay() + 6) % 7 : 0
  days.forEach((day, index) => {
    const weekNumber = period === 'month'
      ? Math.floor((index + firstWeekOffset) / 7) + 1
      : Math.floor(index / 7) + 1
    const week = weekGroups.get(weekNumber) ?? { label: `Tuần ${weekNumber}`, kcal: 0, meals: 0 }
    week.kcal += day.kcal
    week.meals += day.mealCount
    weekGroups.set(weekNumber, week)
  })

  return {
    period,
    periodLabel,
    dayCount: recordedDays,
    calendarDayCount: days.length,
    mealCount,
    totalKcal,
    averageKcal: recordedDays ? Math.round(totalKcal / recordedDays) : 0,
    totalProtein: Math.round(totalProtein),
    averageProtein: recordedDays ? Math.round(totalProtein / recordedDays) : 0,
    recipeCount: recipeCounts.size,
    topRecipes: [...recipeCounts.entries()]
      .map(([title, count]) => ({ title, count }))
      .sort((left, right) => right.count - left.count || left.title.localeCompare(right.title, 'vi'))
      .slice(0, 8),
    chart: period === 'week'
      ? days.map((day) => ({ label: day.label, kcal: day.kcal, meals: day.mealCount }))
      : [...weekGroups.values()],
    days: days.map(({ date, kcal, protein, mealCount: dayMeals }) => ({
      date, kcal, protein, mealCount: dayMeals,
    })),
  }
}

export function buildMealPlanStats({ period, date = new Date(), eatenMeals }) {
  if (!Array.isArray(eatenMeals)) throw new TypeError('eatenMeals must be an array.')

  let start
  let dayCount
  let periodLabel
  if (period === 'week') {
    start = getMonday(date)
    dayCount = 7
    const sunday = new Date(start)
    sunday.setDate(start.getDate() + 6)
    periodLabel = `${start.toLocaleDateString('vi-VN')} – ${sunday.toLocaleDateString('vi-VN')}`
  } else if (period === 'month') {
    start = new Date(date.getFullYear(), date.getMonth(), 1)
    dayCount = new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate()
    periodLabel = new Intl.DateTimeFormat('vi-VN', { month: 'long', year: 'numeric' }).format(date)
  } else {
    throw new RangeError('Period must be either "week" or "month".')
  }

  const days = Array.from({ length: dayCount }, (_, index) => {
    const current = new Date(start.getFullYear(), start.getMonth(), start.getDate() + index)
    const dateKey = formatLocalDate(current)
    const meals = eatenMeals
      .filter((meal) => meal.date === dateKey)
      .map((meal) => ({
        title: meal.title,
        kcal: meal.kcal,
        protein: meal.protein,
      }))
    return {
      date: dateKey,
      label: period === 'week' ? DAY_NAMES[(current.getDay() + 6) % 7] : dateKey,
      mealCount: meals.length,
      kcal: meals.reduce((total, meal) => total + meal.kcal, 0),
      protein: meals.reduce((total, meal) => total + meal.protein, 0),
      meals,
    }
  })

  return summarizeDays(days, period, periodLabel)
}
