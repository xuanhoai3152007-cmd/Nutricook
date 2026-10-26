import assert from 'node:assert/strict'
import test from 'node:test'
import { estimateIngredientPrice } from '../src/ingredientPrices.js'

test('estimates ingredient prices using Vietnamese names and scaled amounts', () => {
  assert.equal(estimateIngredientPrice('Cá hồi phi lê', '250 g', 'Thịt cá'), 55000)
  assert.equal(estimateIngredientPrice('Gạo lứt', '0,5 kg', 'Ngũ cốc'), 25000)
  assert.equal(estimateIngredientPrice('Trứng gà', '6 quả', 'Thực phẩm khác'), 21000)
  assert.equal(estimateIngredientPrice('Rau xà lách', '1 bó', 'Rau củ'), 15000)
})

test('provides a category estimate for a custom ingredient without a known price rule', () => {
  assert.equal(estimateIngredientPrice('Rau thơm', '100 g', 'Rau củ'), 4000)
  assert.equal(estimateIngredientPrice('Nguyên liệu lạ', '1 món', 'Khác'), 5000)
})

test('does not overstate the cost of small quantities of basic seasonings', () => {
  assert.equal(estimateIngredientPrice('Muối', '1 g', 'Gia vị'), 0)
  assert.equal(estimateIngredientPrice('Dầu ăn', '10 ml', 'Gia vị'), 500)
})
