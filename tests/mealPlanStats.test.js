import assert from 'node:assert/strict'
import test from 'node:test'
import { buildMealPlanStats } from '../src/mealPlanStats.js'

const eatenMeals = [
  { id: '2026-10-26-0', date: '2026-10-26', title: 'Yến mạch', kcal: 310, protein: 12 },
  { id: '2026-10-26-1', date: '2026-10-26', title: 'Cơm gà', kcal: 480, protein: 35 },
  { id: '2026-10-28-0', date: '2026-10-28', title: 'Yến mạch', kcal: 310, protein: 12 },
  { id: '2026-10-25-0', date: '2026-10-25', title: 'Ngoài tuần', kcal: 500, protein: 20 },
]

test('weekly totals include only explicitly recorded eaten meals in the selected week', () => {
  const stats = buildMealPlanStats({
    period: 'week',
    date: new Date(2026, 9, 26, 12),
    eatenMeals,
  })

  assert.equal(stats.calendarDayCount, 7)
  assert.equal(stats.dayCount, 2)
  assert.equal(stats.mealCount, 3)
  assert.equal(stats.totalKcal, 1100)
  assert.equal(stats.averageKcal, 550)
  assert.equal(stats.totalProtein, 59)
  assert.equal(stats.chart.length, 7)
  assert.equal(stats.chart[0].kcal, 790)
  assert.equal(stats.chart[1].kcal, 0)
  assert.deepEqual(stats.topRecipes, [{ title: 'Yến mạch', count: 2 }, { title: 'Cơm gà', count: 1 }])
  assert.equal(stats.days[0].date, '2026-10-26')
})

test('monthly totals count only logged meals on dates in the selected month', () => {
  const stats = buildMealPlanStats({
    period: 'month',
    date: new Date(2026, 9, 12, 12),
    eatenMeals: [
      ...eatenMeals,
      { id: '2026-11-01-0', date: '2026-11-01', title: 'Tháng sau', kcal: 600, protein: 30 },
    ],
  })

  assert.equal(stats.calendarDayCount, 31)
  assert.equal(stats.dayCount, 3)
  assert.equal(stats.mealCount, 4)
  assert.equal(stats.totalKcal, 1600)
  assert.equal(stats.chart.length, 5)
  assert.match(stats.periodLabel, /2026/u)
})

test('returns zero totals and empty top recipes when no meals were marked eaten', () => {
  const stats = buildMealPlanStats({
    period: 'week',
    date: new Date(2026, 9, 26, 12),
    eatenMeals: [],
  })

  assert.equal(stats.mealCount, 0)
  assert.equal(stats.dayCount, 0)
  assert.equal(stats.averageKcal, 0)
  assert.equal(stats.totalProtein, 0)
  assert.deepEqual(stats.topRecipes, [])
})

test('includes leap-day records in monthly totals', () => {
  const stats = buildMealPlanStats({
    period: 'month',
    date: new Date(2024, 1, 12, 12),
    eatenMeals: [
      { id: '2024-02-29-0', date: '2024-02-29', title: 'Bữa đã ăn', kcal: 400, protein: 25 },
    ],
  })

  assert.equal(stats.calendarDayCount, 29)
  assert.equal(stats.mealCount, 1)
  assert.equal(stats.totalKcal, 400)
})

test('rejects unsupported periods and invalid eaten meal input', () => {
  assert.throws(
    () => buildMealPlanStats({ period: 'year', eatenMeals: [] }),
    { name: 'RangeError' },
  )
  assert.throws(
    () => buildMealPlanStats({ period: 'week', eatenMeals: null }),
    { name: 'TypeError' },
  )
})
