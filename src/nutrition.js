export const activityOptions = [
  { value: 'sedentary', label: 'Ít vận động', detail: 'Chủ yếu ngồi, ít tập luyện', multiplier: 1.2 },
  { value: 'light', label: 'Vận động nhẹ', detail: 'Tập nhẹ khoảng 1–3 buổi/tuần', multiplier: 1.375 },
  { value: 'moderate', label: 'Vận động vừa', detail: 'Tập khoảng 3–5 buổi/tuần', multiplier: 1.55 },
  { value: 'active', label: 'Vận động nhiều', detail: 'Tập nặng khoảng 6–7 buổi/tuần', multiplier: 1.725 },
  { value: 'very_active', label: 'Rất năng động', detail: 'Vận động viên hoặc lao động nặng', multiplier: 1.9 },
]

export const dietOptions = [
  { value: 'balanced', label: 'Cân bằng', split: { protein: 20, fat: 30, carb: 50 } },
  { value: 'vegetarian', label: 'Ăn chay', split: { protein: 20, fat: 30, carb: 50 } },
  { value: 'vegan', label: 'Thuần chay', split: { protein: 20, fat: 30, carb: 50 } },
  { value: 'pescatarian', label: 'Pescatarian', split: { protein: 20, fat: 30, carb: 50 } },
  { value: 'low-carb', label: 'Low-carb', split: { protein: 30, fat: 40, carb: 30 } },
  { value: 'keto', label: 'Keto', split: { protein: 20, fat: 70, carb: 10 } },
  { value: 'dash', label: 'DASH', split: { protein: 19, fat: 26, carb: 55 } },
  { value: 'mediterranean', label: 'Địa Trung Hải', split: { protein: 20, fat: 30, carb: 50 } },
  { value: 'halal', label: 'Halal', split: { protein: 20, fat: 30, carb: 50 } },
]

export const healthOptions = [
  { value: 'diabetes', label: 'Tiểu đường type 2' },
  { value: 'hypertension', label: 'Tăng huyết áp' },
  { value: 'high-cholesterol', label: 'Mỡ máu cao' },
  { value: 'gout', label: 'Gout' },
  { value: 'kidney', label: 'Bệnh thận mạn', red: true },
  { value: 'stomach', label: 'Dạ dày / trào ngược' },
  { value: 'anemia', label: 'Thiếu máu' },
  { value: 'overweight', label: 'Thừa cân' },
  { value: 'obesity', label: 'Béo phì' },
  { value: 'pregnancy', label: 'Đang mang thai', red: true },
  { value: 'breastfeeding', label: 'Đang cho con bú', red: true },
  { value: 'eating-disorder', label: 'Tiền sử rối loạn ăn uống', red: true },
]

export const redHealthConditions = new Set(['kidney', 'pregnancy', 'breastfeeding', 'eating-disorder'])

export function getAge(birthDate) {
  if (!birthDate) return null
  const date = new Date(`${birthDate}T00:00:00`)
  if (Number.isNaN(date.getTime())) return null
  const today = new Date()
  let age = today.getFullYear() - date.getFullYear()
  if (today.getMonth() < date.getMonth() || (today.getMonth() === date.getMonth() && today.getDate() < date.getDate())) age -= 1
  return age
}

export function getBodyMassIndex(weightKg, heightCm) {
  const heightMeters = Number(heightCm) / 100
  return Number(weightKg) / (heightMeters * heightMeters)
}

export function getNutritionEstimate(profile) {
  const age = getAge(profile.birthDate)
  const heightCm = Number(profile.heightCm)
  const weightKg = Number(profile.weightKg)
  const bmi = getBodyMassIndex(weightKg, heightCm)
  const activity = activityOptions.find((option) => option.value === profile.activity)
  const diet = dietOptions.find((option) => option.value === profile.diet)
  if (!activity || !diet) throw new RangeError('Unsupported activity or diet selection.')

  const targetWeightKg = Number(profile.targetWeightKg)
  const targetBmi = getBodyMassIndex(targetWeightKg, heightCm)
  const redConditions = profile.conditions.filter((condition) => redHealthConditions.has(condition))
  const safetyReasons = []

  if (age < 18) safetyReasons.push('Mifflin-St Jeor chỉ dùng làm ước tính cho người trưởng thành; bạn dưới 18 tuổi.')
  if (bmi < 18.5) safetyReasons.push('BMI hiện tại dưới 18,5; không tạo mục tiêu giảm cân tự động.')
  if (redConditions.length) {
    const labels = healthOptions.filter((option) => redConditions.includes(option.value)).map((option) => option.label.toLowerCase())
    safetyReasons.push(`Bạn đã chọn ${labels.join(', ')}; cần chuyên gia y tế hướng dẫn riêng.`)
  }
  if (profile.goal === 'lose' && targetBmi < 18.5) safetyReasons.push('Cân nặng mục tiêu sẽ làm BMI thấp hơn 18,5.')
  if (profile.diet === 'keto' && profile.conditions.includes('diabetes')) safetyReasons.push('Không tự động áp dụng Keto khi đã khai báo tiểu đường.')

  if (safetyReasons.length) return { age, bmi, safetyReasons, targets: null }

  const bmr = 10 * weightKg + 6.25 * heightCm - 5 * age + (profile.sex === 'male' ? 5 : -161)
  const tdee = bmr * activity.multiplier
  const adjustment = { lose: -250, maintain: 0, gain: 250, muscle: 350, healthy: 0 }[profile.goal]
  const floor = profile.sex === 'male' ? 1500 : 1200
  const estimatedBeforeFloor = tdee + adjustment
  const kcal = Math.round(Math.max(estimatedBeforeFloor, floor))
  const split = diet.split

  return {
    age,
    bmi,
    safetyReasons: [],
    targets: {
      bmr,
      tdee,
      kcal,
      floorApplied: estimatedBeforeFloor < floor,
      proteinG: Math.round(kcal * (split.protein / 100) / 4),
      carbG: Math.round(kcal * (split.carb / 100) / 4),
      fatG: Math.round(kcal * (split.fat / 100) / 9),
      fiberG: profile.sex === 'male' ? 30 : 25,
      sodiumMg: 2000,
      maxSugarG: Math.floor(kcal * 0.1 / 4),
      split,
    },
  }
}
