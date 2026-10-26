const ingredientPriceRules = [
  { names: ['cá hồi phi lê', 'cá hồi'], unit: 'g', pricePerUnit: 220 },
  { names: ['măng tây'], unit: 'g', pricePerUnit: 180 },
  { names: ['chanh tươi', 'chanh'], unit: 'quả', pricePerUnit: 5000 },
  { names: ['dầu ô liu'], unit: 'ml', pricePerUnit: 320 },
  { names: ['muối'], unit: 'g', pricePerUnit: 0.05 },
  { names: ['ức gà'], unit: 'g', pricePerUnit: 120 },
  { names: ['gạo lứt khô', 'gạo lứt'], unit: 'g', pricePerUnit: 50 },
  { names: ['bông cải xanh', 'súp lơ xanh'], unit: 'g', pricePerUnit: 65 },
  { names: ['cà rốt'], unit: 'g', pricePerUnit: 30 },
  { names: ['dầu ăn'], unit: 'ml', pricePerUnit: 70 },
  { names: ['bơ tươi', 'bơ'], unit: 'g', pricePerUnit: 80 },
  { names: ['trứng gà', 'trứng'], unit: 'quả', pricePerUnit: 3500 },
  { names: ['rau xà lách', 'xà lách'], unit: 'g', pricePerUnit: 55, bunchPrice: 15000 },
  { names: ['cà chua bi'], unit: 'g', pricePerUnit: 100 },
  { names: ['tôm tươi', 'tôm'], unit: 'g', pricePerUnit: 250 },
  { names: ['bí đỏ'], unit: 'g', pricePerUnit: 25 },
  { names: ['hành lá'], unit: 'g', pricePerUnit: 60 },
  { names: ['nước'], unit: 'ml', pricePerUnit: 0 },
  { names: ['yến mạch cán', 'yến mạch'], unit: 'g', pricePerUnit: 100 },
  { names: ['chuối chín', 'chuối'], unit: 'quả', pricePerUnit: 4000 },
  { names: ['sữa tươi'], unit: 'ml', pricePerUnit: 35 },
  { names: ['hạt chia'], unit: 'g', pricePerUnit: 180 },
  { names: ['đậu hũ'], unit: 'g', pricePerUnit: 50 },
  { names: ['cà chua'], unit: 'g', pricePerUnit: 40 },
  { names: ['hành tím'], unit: 'g', pricePerUnit: 45 },
]

const groupPriceRules = {
  'Thịt cá': 140,
  'Rau củ': 40,
  'Ngũ cốc': 70,
  'Gia vị': 100,
  'Thực phẩm khác': 60,
  Khác: 5000,
}

const groupUnitPriceRules = {
  'Thịt cá': 140,
  'Rau củ': 40,
  'Ngũ cốc': 70,
  'Gia vị': 100,
  'Thực phẩm khác': 60,
  Khác: 50,
}

function normalizeName(value) {
  return value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[đĐ]/g, 'd')
    .trim()
    .toLocaleLowerCase('vi')
}

function parseAmount(value) {
  const match = /^([\d.,]+)\s*(.*?)\s*$/u.exec(value.trim())
  if (!match) return null
  const numberText = match[1]
  const normalizedNumber = numberText.includes(',')
    ? numberText.replace(/\./g, '').replace(',', '.')
    : /^\d{1,3}(?:\.\d{3})+$/.test(numberText)
      ? numberText.replace(/\./g, '')
      : numberText
  const amount = Number(normalizedNumber)
  return Number.isFinite(amount) ? { amount, unit: normalizeName(match[2]) } : null
}

function roundMarketPrice(value) {
  return value > 0 ? Math.round(value / 500) * 500 : 0
}

export function estimateIngredientPrice(name, amount, group = 'Khác') {
  const parsed = parseAmount(amount)
  if (!parsed) return roundMarketPrice(groupPriceRules[group] ?? groupPriceRules.Khác)

  const normalizedName = normalizeName(name)
  const rule = ingredientPriceRules.find((item) => item.names.some((candidate) => normalizeName(candidate) === normalizedName))
  if (parsed.unit === 'bo' && rule?.bunchPrice) return rule.bunchPrice
  if (parsed.unit === 'muong') return roundMarketPrice(rule?.pricePerUnit ? rule.pricePerUnit * 15 : groupPriceRules[group] ?? groupPriceRules.Khác)

  const ruleUnit = rule ? normalizeName(rule.unit) : ''
  if (rule && (parsed.unit === ruleUnit || (ruleUnit === 'g' && parsed.unit === 'kg') || (ruleUnit === 'ml' && parsed.unit === 'l'))) {
    const normalizedAmount = parsed.unit === 'kg' || parsed.unit === 'l' ? parsed.amount * 1000 : parsed.amount
    return roundMarketPrice(normalizedAmount * rule.pricePerUnit)
  }

  if (parsed.unit === 'g' || parsed.unit === 'ml') {
    return roundMarketPrice(parsed.amount * (groupUnitPriceRules[group] ?? groupUnitPriceRules.Khác))
  }
  if (parsed.unit === 'kg' || parsed.unit === 'l') {
    return roundMarketPrice(parsed.amount * 1000 * (groupUnitPriceRules[group] ?? groupUnitPriceRules.Khác))
  }
  return roundMarketPrice(groupPriceRules[group] ?? groupPriceRules.Khác)
}
