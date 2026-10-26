import assert from 'node:assert/strict'
import test from 'node:test'
import { getNutritionEstimate } from '../src/nutrition.js'

function birthDateForAge(age) {
  const date = new Date()
  date.setFullYear(date.getFullYear() - age)
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${date.getFullYear()}-${month}-${day}`
}

function profile(overrides = {}) {
  return {
    sex: 'female',
    birthDate: birthDateForAge(30),
    heightCm: '165',
    weightKg: '60',
    goal: 'maintain',
    targetWeightKg: '',
    activity: 'light',
    conditions: [],
    diet: 'balanced',
    ...overrides,
  }
}

test('matches the Mifflin-St Jeor golden example and balanced macro split', () => {
  const result = getNutritionEstimate(profile())

  assert.equal(result.age, 30)
  assert.equal(result.bmi, 60 / (1.65 * 1.65))
  assert.equal(result.targets.bmr, 1320.25)
  assert.equal(result.targets.tdee, 1815.34375)
  assert.equal(result.targets.kcal, 1815)
  assert.deepEqual(
    [result.targets.proteinG, result.targets.carbG, result.targets.fatG],
    [91, 227, 61],
  )
})

test('applies the female and male minimum calorie floors', () => {
  const female = getNutritionEstimate(profile({
    birthDate: birthDateForAge(90),
    goal: 'lose',
    targetWeightKg: '59',
  }))
  const male = getNutritionEstimate(profile({
    sex: 'male',
    birthDate: birthDateForAge(90),
    goal: 'lose',
    targetWeightKg: '59',
  }))

  assert.equal(female.targets.kcal, 1200)
  assert.equal(female.targets.floorApplied, true)
  assert.equal(male.targets.kcal, 1500)
  assert.equal(male.targets.floorApplied, true)
})

test('does not calculate targets for a minor or a red-tier health condition', () => {
  const minor = getNutritionEstimate(profile({ birthDate: birthDateForAge(17) }))
  const kidneyCondition = getNutritionEstimate(profile({ conditions: ['kidney'] }))

  assert.equal(minor.targets, null)
  assert.equal(kidneyCondition.targets, null)
  assert.ok(minor.safetyReasons.some((reason) => reason.includes('dưới 18 tuổi')))
  assert.ok(kidneyCondition.safetyReasons.some((reason) => reason.includes('bệnh thận mạn')))
})

test('does not create weight-loss targets below the safe BMI threshold', () => {
  const result = getNutritionEstimate(profile({
    goal: 'lose',
    targetWeightKg: '49',
  }))

  assert.equal(result.targets, null)
  assert.ok(result.safetyReasons.some((reason) => reason.includes('BMI thấp hơn 18,5')))
})

test('blocks a keto estimate when diabetes is selected', () => {
  const result = getNutritionEstimate(profile({
    diet: 'keto',
    conditions: ['diabetes'],
  }))

  assert.equal(result.targets, null)
  assert.ok(result.safetyReasons.some((reason) => reason.includes('Không tự động áp dụng Keto')))
})
