import assert from 'node:assert/strict'
import test from 'node:test'
import { formatIngredientAmount, getRecipeDetail, scaleRecipeIngredient } from '../src/recipeData.js'

test('returns ingredient, cooking, nutrition, and allergen details for a known recipe', () => {
  const recipe = getRecipeDetail(1)

  assert.ok(recipe)
  assert.equal(recipe.ingredients.length, 5)
  assert.equal(recipe.steps.length, 4)
  assert.equal(recipe.nutrition.protein, 32)
  assert.deepEqual(recipe.allergens, ['Cá'])
})

test('returns null when a recipe has no demo detail', () => {
  assert.equal(getRecipeDetail(999), null)
})

test('scales ingredient quantities linearly from the two-serving base', () => {
  const ingredient = { amount: 250, unit: 'g' }

  assert.equal(scaleRecipeIngredient(ingredient, 4), 500)
  assert.equal(scaleRecipeIngredient(ingredient, 1), 125)
})

test('scales sublinear ingredients by the square root of the serving ratio', () => {
  const ingredient = { amount: 4, unit: 'g', scaleMode: 'sublinear' }

  assert.equal(scaleRecipeIngredient(ingredient, 8), 8)
  assert.equal(scaleRecipeIngredient(ingredient, 1), 2.8284271247461903)
})

test('accepts serving limits from one through twelve and rejects values outside them', () => {
  const ingredient = { amount: 100, unit: 'g' }

  assert.equal(scaleRecipeIngredient(ingredient, 1), 50)
  assert.equal(scaleRecipeIngredient(ingredient, 12), 600)
  assert.throws(() => scaleRecipeIngredient(ingredient, 0), RangeError)
  assert.throws(() => scaleRecipeIngredient(ingredient, 13), RangeError)
  assert.throws(() => scaleRecipeIngredient(ingredient, Number.NaN), RangeError)
})

test('formats scaled quantities using Vietnamese number formatting', () => {
  assert.equal(formatIngredientAmount(1.25), '1,3')
  assert.equal(formatIngredientAmount(250), '250')
})
