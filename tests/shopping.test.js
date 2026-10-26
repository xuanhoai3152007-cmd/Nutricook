import assert from 'node:assert/strict'
import test from 'node:test'
import { addRecipeIngredientsToShoppingList } from '../src/shopping.js'

test('adds scaled recipe ingredients with estimated market prices', () => {
  const items = []
  const ingredients = [
    { name: 'Cá hồi phi lê', amount: 250, unit: 'g', group: 'Thịt cá' },
    { name: 'Chanh tươi', amount: 0.5, unit: 'quả', group: 'Rau củ' },
  ]

  const result = addRecipeIngredientsToShoppingList(items, ingredients, 3, 1)

  assert.deepEqual(result.map(({ name, amount, price, group }) => ({ name, amount, price, group })), [
    { name: 'Cá hồi phi lê', amount: '375 g', price: 82500, group: 'Thịt cá' },
    { name: 'Chanh tươi', amount: '0,8 quả', price: 4000, group: 'Rau củ' },
  ])
})

test('sums recipe amounts and refreshes the estimated price', () => {
  const items = [
    { id: 1, recipeId: 1, recipeName: 'Cá hồi áp chảo', name: 'Cá hồi phi lê', amount: '300 g', price: 89000, quantity: 1, group: 'Thịt cá', checked: true },
  ]
  const ingredients = [{ name: 'Cá hồi phi lê', amount: 250, unit: 'g', group: 'Thịt cá' }]

  const result = addRecipeIngredientsToShoppingList(items, ingredients, 3, 1)

  assert.equal(result.length, 1)
  assert.equal(result[0].amount, '675 g')
  assert.equal(result[0].price, 148500)
  assert.equal(result[0].checked, false)
})

test('repeated recipe additions accumulate amounts without duplicating matching items', () => {
  const ingredient = [{ name: 'Bí đỏ', amount: 300, unit: 'g', group: 'Rau củ' }]
  const once = addRecipeIngredientsToShoppingList([], ingredient, 2, 4, 2, 'Canh bí đỏ')
  const twice = addRecipeIngredientsToShoppingList(once, ingredient, 2, 4)

  assert.equal(twice.length, 1)
  assert.equal(twice[0].amount, '600 g')
  assert.equal(twice[0].recipeName, 'Canh bí đỏ')
})

test('keeps identical ingredients separate between different recipes', () => {
  const ingredient = [{ name: 'Bí đỏ', amount: 300, unit: 'g', group: 'Rau củ' }]
  const first = addRecipeIngredientsToShoppingList([], ingredient, 2, 4, 2, 'Canh bí đỏ')
  const result = addRecipeIngredientsToShoppingList(first, ingredient, 2, 5, 2, 'Bí đỏ hấp')

  assert.equal(result.length, 2)
  assert.deepEqual(result.map(({ recipeId, recipeName, amount }) => ({ recipeId, recipeName, amount })), [
    { recipeId: 4, recipeName: 'Canh bí đỏ', amount: '300 g' },
    { recipeId: 5, recipeName: 'Bí đỏ hấp', amount: '300 g' },
  ])
})

test('scales database recipe ingredients from their configured base serving count', () => {
  const ingredient = [{ name: 'Ức gà', amount: 300, unit: 'g', group: 'Thịt cá' }]

  const result = addRecipeIngredientsToShoppingList([], ingredient, 4, 'database-recipe', 4)

  assert.equal(result[0].amount, '300 g')
})

test('keeps same-name ingredients separate when their units do not match', () => {
  const items = [
    { id: 1, name: 'Dầu ăn', amount: '1 muỗng', price: null, quantity: 1, group: 'Gia vị', checked: false },
  ]
  const ingredients = [{ name: 'Dầu ăn', amount: 10, unit: 'ml', group: 'Gia vị' }]

  const result = addRecipeIngredientsToShoppingList(items, ingredients, 2, 2)

  assert.equal(result.length, 2)
  assert.equal(result[1].amount, '10 ml')
  assert.notEqual(result[0].id, result[1].id)
})
