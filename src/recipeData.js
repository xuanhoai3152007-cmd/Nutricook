const recipeDetails = {
  1: {
    ingredients: [
      { name: 'Cá hồi phi lê', amount: 250, unit: 'g', group: 'Thịt cá' },
      { name: 'Măng tây', amount: 150, unit: 'g', group: 'Rau củ' },
      { name: 'Chanh tươi', amount: 0.5, unit: 'quả', group: 'Rau củ' },
      { name: 'Dầu ô liu', amount: 10, unit: 'ml', group: 'Gia vị' },
      { name: 'Muối', amount: 1, unit: 'g', group: 'Gia vị', scaleMode: 'sublinear' },
    ],
    steps: [
      'Rửa và thấm khô cá hồi. Sơ chế măng tây, bỏ phần gốc già và cắt chanh thành lát.',
      'Làm nóng chảo với một phần dầu. Áp chảo cá hồi đến khi chín theo mức độ phù hợp với bạn.',
      'Xào măng tây với phần dầu còn lại đến khi vừa mềm; nêm nhẹ theo khẩu vị.',
      'Dùng cá hồi cùng măng tây và chanh. Kiểm tra cá đã chín kỹ trước khi dùng.',
    ],
    nutrition: { protein: 32, carb: 18, fat: 21, sodium: 390 },
    allergens: ['Cá'],
  },
  2: {
    ingredients: [
      { name: 'Ức gà', amount: 250, unit: 'g', group: 'Thịt cá' },
      { name: 'Gạo lứt khô', amount: 120, unit: 'g', group: 'Ngũ cốc' },
      { name: 'Bông cải xanh', amount: 150, unit: 'g', group: 'Rau củ' },
      { name: 'Cà rốt', amount: 80, unit: 'g', group: 'Rau củ' },
      { name: 'Dầu ăn', amount: 10, unit: 'ml', group: 'Gia vị' },
    ],
    steps: [
      'Vo gạo lứt và nấu chín theo hướng dẫn trên bao bì.',
      'Rửa sạch ức gà và rau củ; cắt thành miếng vừa ăn.',
      'Nấu chín ức gà trong chảo với một ít dầu; làm chín rau củ riêng.',
      'Chia cơm, thịt gà và rau củ ra bát. Bảo đảm thịt gà chín hoàn toàn.',
    ],
    nutrition: { protein: 35, carb: 48, fat: 11, sodium: 440 },
    allergens: [],
  },
  3: {
    ingredients: [
      { name: 'Bơ tươi', amount: 100, unit: 'g', group: 'Rau củ' },
      { name: 'Trứng gà', amount: 2, unit: 'quả', group: 'Thực phẩm khác' },
      { name: 'Rau xà lách', amount: 100, unit: 'g', group: 'Rau củ' },
      { name: 'Cà chua bi', amount: 100, unit: 'g', group: 'Rau củ' },
      { name: 'Dầu ô liu', amount: 5, unit: 'ml', group: 'Gia vị' },
    ],
    steps: [
      'Rửa rau xà lách và cà chua bi dưới vòi nước sạch; để ráo.',
      'Luộc trứng đến độ chín mong muốn, để nguội rồi bóc vỏ.',
      'Cắt bơ, cà chua và trứng thành miếng vừa ăn.',
      'Trộn nhẹ với rau và dầu ô liu; dùng ngay sau khi chuẩn bị.',
    ],
    nutrition: { protein: 18, carb: 24, fat: 20, sodium: 280 },
    allergens: ['Trứng'],
  },
  4: {
    ingredients: [
      { name: 'Tôm tươi', amount: 150, unit: 'g', group: 'Thịt cá' },
      { name: 'Bí đỏ', amount: 300, unit: 'g', group: 'Rau củ' },
      { name: 'Hành lá', amount: 10, unit: 'g', group: 'Rau củ' },
      { name: 'Nước', amount: 500, unit: 'ml', group: 'Thực phẩm khác' },
      { name: 'Muối', amount: 1, unit: 'g', group: 'Gia vị', scaleMode: 'sublinear' },
    ],
    steps: [
      'Gọt vỏ bí đỏ, bỏ hạt và cắt thành miếng vừa ăn. Sơ chế tôm và hành lá.',
      'Đun sôi nước, cho bí đỏ vào nấu đến khi gần mềm.',
      'Thêm tôm và nấu đến khi tôm chín hoàn toàn; nêm vừa khẩu vị.',
      'Tắt bếp, thêm hành lá và dùng khi còn ấm.',
    ],
    nutrition: { protein: 22, carb: 31, fat: 7, sodium: 410 },
    allergens: ['Tôm', 'Giáp xác'],
  },
  5: {
    ingredients: [
      { name: 'Yến mạch cán', amount: 80, unit: 'g', group: 'Ngũ cốc' },
      { name: 'Chuối chín', amount: 1, unit: 'quả', group: 'Rau củ' },
      { name: 'Sữa tươi', amount: 200, unit: 'ml', group: 'Thực phẩm khác' },
      { name: 'Hạt chia', amount: 10, unit: 'g', group: 'Ngũ cốc' },
    ],
    steps: [
      'Cho yến mạch và sữa vào nồi, nấu lửa nhỏ và khuấy đều.',
      'Nấu đến khi yến mạch mềm và đạt độ sánh mong muốn.',
      'Cắt chuối thành lát, chuẩn bị hạt chia.',
      'Cho yến mạch ra bát, thêm chuối và hạt chia trước khi dùng.',
    ],
    nutrition: { protein: 12, carb: 48, fat: 9, sodium: 150 },
    allergens: ['Sữa'],
  },
  6: {
    ingredients: [
      { name: 'Đậu hũ', amount: 300, unit: 'g', group: 'Thực phẩm khác' },
      { name: 'Cà chua', amount: 200, unit: 'g', group: 'Rau củ' },
      { name: 'Hành tím', amount: 30, unit: 'g', group: 'Rau củ' },
      { name: 'Dầu ăn', amount: 10, unit: 'ml', group: 'Gia vị' },
      { name: 'Hành lá', amount: 10, unit: 'g', group: 'Rau củ' },
    ],
    steps: [
      'Cắt đậu hũ thành miếng vừa ăn; rửa cà chua và cắt múi cau.',
      'Phi thơm hành tím với dầu ăn, thêm cà chua và nấu đến khi mềm.',
      'Cho đậu hũ vào chảo, đảo nhẹ và nấu thêm vài phút.',
      'Thêm hành lá, nêm theo khẩu vị và dùng khi còn nóng.',
    ],
    nutrition: { protein: 20, carb: 22, fat: 18, sodium: 360 },
    allergens: ['Đậu nành'],
  },
}

export function getRecipeDetail(recipeId) {
  return recipeDetails[recipeId] ?? null
}

export function scaleRecipeIngredient(ingredient, servings, baseServings = 2) {
  if (!Number.isFinite(servings) || servings < 1 || servings > 12) {
    throw new RangeError('Servings must be between 1 and 12.')
  }

  const ratio = servings / baseServings
  const scale = ingredient.scaleMode === 'sublinear' ? Math.sqrt(ratio) : ratio
  return ingredient.amount * scale
}

export function formatIngredientAmount(amount) {
  return Number(amount.toFixed(1)).toLocaleString('vi-VN', { maximumFractionDigits: 1 })
}
