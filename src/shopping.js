import { formatIngredientAmount, scaleRecipeIngredient } from './recipeData.js'
import { estimateIngredientPrice } from './ingredientPrices.js'

function parseAmount(value) {
  const match = /^([\d.,]+)\s*(.*?)\s*$/u.exec(value)
  if (!match) return null

  const [numberText, unit] = [match[1], match[2].trim()]
  const normalizedNumber = numberText.includes(',')
    ? numberText.replace(/\./g, '').replace(',', '.')
    : /^\d{1,3}(?:\.\d{3})+$/.test(numberText)
      ? numberText.replace(/\./g, '')
      : numberText
  const amount = Number(normalizedNumber)

  return Number.isFinite(amount) ? { amount, unit } : null
}

function formatAmount(amount, unit) {
  return `${formatIngredientAmount(amount)} ${unit}`
}

function createUniqueId(items, recipeId, ingredientIndex) {
  const baseId = `recipe-${recipeId}-${ingredientIndex}`
  let id = baseId
  let suffix = 2

  while (items.some((item) => item.id === id)) {
    id = `${baseId}-${suffix}`
    suffix += 1
  }

  return id
}

export function addRecipeIngredientsToShoppingList(items, ingredients, servings, recipeId, baseServings = 2, recipeName = '') {
  const nextItems = [...items]

  ingredients.forEach((ingredient, index) => {
    const amount = scaleRecipeIngredient(ingredient, servings, baseServings)
    const unit = ingredient.unit.trim()
    const matchingIndex = nextItems.findIndex((item) => {
      const existingAmount = parseAmount(item.amount)
      return item.recipeId === recipeId
        && item.name.trim().toLocaleLowerCase('vi') === ingredient.name.trim().toLocaleLowerCase('vi')
        && existingAmount?.unit.toLocaleLowerCase('vi') === unit.toLocaleLowerCase('vi')
    })
    const existing = matchingIndex >= 0 ? parseAmount(nextItems[matchingIndex].amount) : null

    if (matchingIndex >= 0 && existing) {
      const mergedAmount = existing.amount + amount
      const amountText = formatAmount(mergedAmount, unit)
      nextItems[matchingIndex] = {
        ...nextItems[matchingIndex],
        amount: amountText,
        checked: false,
        price: estimateIngredientPrice(ingredient.name, amountText, ingredient.group),
      }
      return
    }

    const amountText = formatAmount(amount, unit)
    nextItems.push({
      id: createUniqueId(nextItems, recipeId, index),
      recipeId,
      recipeName,
      name: ingredient.name,
      amount: amountText,
      price: estimateIngredientPrice(ingredient.name, amountText, ingredient.group),
      quantity: 1,
      group: ingredient.group,
      checked: false,
    })
  })

  return nextItems
}
