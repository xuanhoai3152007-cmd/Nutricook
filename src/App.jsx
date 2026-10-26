import { Fragment, useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { activityOptions, dietOptions, getAge, getBodyMassIndex, getNutritionEstimate, healthOptions, redHealthConditions } from './nutrition.js'
import { formatIngredientAmount, getRecipeDetail, scaleRecipeIngredient } from './recipeData.js'
import { estimateIngredientPrice } from './ingredientPrices.js'
import { getSupabaseClient, isSupabaseConfigured } from './lib/supabase.js'
import { signInAsAdminWithEmail, signInWithEmail, signOut, signUpWithEmail } from './services/authService.js'
import { createAdminRecipe, getAdminAccounts, getAdminRecipes, getIngredientCatalog, getPublishedRecipes, manageAdminAccount } from './services/adminService.js'
import { getMealPlanAdvice } from './services/mealPlanAdviceService.js'
import { buildMealPlanStats } from './mealPlanStats.js'
import { loadUserProfile, saveUserProfile } from './services/profileService.js'
import { addRecipeIngredientsToShoppingList } from './shopping.js'
import './App.css'

const maxBirthDate = new Date(Date.now() - new Date().getTimezoneOffset() * 60000).toISOString().slice(0, 10)

const imageUrls = [
  'https://lh3.googleusercontent.com/aida-public/AB6AXuAhjezNgTj64-JH1T9KSR7j0ebVQeSyH3goBMqXF3GmTqrj-eclkvnjJZBGz9oyiLwKfgXfi5FresAK1oOgVcfKEduY9z3z8atONEodxWEQCvXvSCFUPyw27VbgDkA72AqRJBK-mVmYLVoU9TK3_W8xim-G-dvdS7Nyi5QJsXgdbEFqZwdkIEW6zsQfoJXYRZ-h-5pgQXmkUq7TPAI-sq6Mb8IctFuY61mnKGO_a9bZ0YeujvzNuyEs',
  'https://lh3.googleusercontent.com/aida-public/AB6AXuCDNXPGhvv4-y6-Pz3Rxh9-5v_cLaTRErl3_rGsZzpmXXigGVjMxX1i3T5OMD24Rjf9ZPiQgyT55xnvdlV5JHlmFAM0aovzWWYYqUBGKw83LKR_1KnYZjkd9xnT_KHT6DGyG6q1uCKyVd-NdAwP57ukdST1lTsKttdT3nMQI8wu1sJ3yswrRdkbOjjLYlAxvEeAO3lLrcgJZhuMHWDehK9CKFp14oXBuKOfWy4X1y6bPNIDvMKh7oRX',
  'https://lh3.googleusercontent.com/aida-public/AB6AXuBLZraBU8xuwN72nTRH46HNaytgvB13fLKA5bglzBA0tv5q4cHXOB33VPwnS8WXVdIpl6NoRQF7LhLlYakszx0cqhaSXFW7qJDEq9xW3bEI_mcy_ZEuiZIyXOuB-EljUyIMcL4AXnTidbIvmkjA8VR8qtC7NLgXiOInDRegXR7LHdGOvaZFCpfuwQw5qYgKNYaQHviVclnZymdu3jfYGTf7bM7zY2uCqK0S-xRY_YDtIychjXnIuukP',
  'https://lh3.googleusercontent.com/aida-public/AB6AXuBRkBfCZ_FCE8_67NKy5sYf4qb4rpq69-Wp-yaf0qR6m-8xoF7mevXB8-j5eBw74BEkuFT84u_CSTELj88XPs17dc5w3M4Md-bpxDo0bBUMxcF1_1TXNQ8GrekC4e6J9P7vNDnNbzoFpl4F1fT09OMbTo-D3eOQQGBazzjZOKfNcDTmHwdX-7NSwcgxRVaci54DUtUB3lAeXFvrStju_0_DTAHQsHViwhehY9qix-NrMCNcEbkhW34O',
  'https://lh3.googleusercontent.com/aida-public/AB6AXuB7uYpyNndf7PCh70p_9hzlVFM2irMaB0K2cHmC-OZoTRHos9XYJpShzbYgViK1s3v5oXWjrw2DN13QJ7pX4aNKjuIF9C8eIwWSnw7Q0a3Hb_E9xtNsXjXQdCB4ChmG4B1RblnOH8MVly51xmDzWMzQLhO3LSMoYFigrVFkB6ViMrAeb7nZW2FFZpIt6nXQF1kjivLNmULFpvGrDwrXw_0ox9SkJchwCizdePqO1Q2af4Tq32SM23d5',
]

const recipes = [
  { id: 1, title: 'Cá hồi áp chảo sốt chanh', category: 'Bữa trưa', time: 25, kcal: 420, protein: 32, tag: 'Món nổi bật', image: imageUrls[0], description: 'Cá hồi áp chảo ăn cùng rau xanh và sốt chanh dịu nhẹ.' },
  { id: 2, title: 'Bát cơm gạo lứt ức gà', category: 'Bữa trưa', time: 30, kcal: 480, protein: 35, tag: 'Giàu đạm', image: imageUrls[2], description: 'Một gợi ý bữa trưa cân bằng với cơm gạo lứt, ức gà và rau củ.' },
  { id: 3, title: 'Salad bơ trứng tươi', category: 'Bữa sáng', time: 15, kcal: 350, protein: 18, tag: 'Nhanh gọn', image: imageUrls[3], description: 'Rau xanh, trứng và bơ trong món salad dễ chuẩn bị.' },
  { id: 4, title: 'Canh bí đỏ nấu tôm', category: 'Bữa tối', time: 25, kcal: 320, protein: 22, tag: 'Món Việt', image: imageUrls[1], description: 'Món canh gia đình với bí đỏ, tôm và hành lá.' },
  { id: 5, title: 'Yến mạch chuối hạt', category: 'Bữa sáng', time: 10, kcal: 310, protein: 12, tag: 'Nhanh gọn', image: imageUrls[4], description: 'Yến mạch ăn cùng chuối và một ít hạt cho bữa sáng.' },
  { id: 6, title: 'Đậu hũ sốt cà chua', category: 'Bữa tối', time: 20, kcal: 390, protein: 20, tag: 'Món chay', image: imageUrls[3], description: 'Đậu hũ mềm trong sốt cà chua, dùng cùng cơm nóng.' },
]

const mealOptions = [
  { label: 'Bữa sáng', options: [recipes[4], recipes[2]], time: '07:30' },
  { label: 'Bữa trưa', options: [recipes[1], recipes[0]], time: '12:30' },
  { label: 'Bữa tối', options: [recipes[3], recipes[5]], time: '19:00' },
]

function normalizeText(value) {
  return value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[đĐ]/g, 'd')
    .toLocaleLowerCase('vi')
}

const initialGroceries = [
  { id: 1, name: 'Cá hồi phi lê', amount: '300 g', price: 66000, quantity: 1, group: 'Thịt cá', checked: false },
  { id: 2, name: 'Gạo lứt', amount: '500 g', price: 25000, quantity: 1, group: 'Ngũ cốc', checked: false },
  { id: 3, name: 'Bí đỏ', amount: '500 g', price: 12500, quantity: 2, group: 'Rau củ', checked: false },
  { id: 4, name: 'Rau xà lách', amount: '1 bó', price: 15000, quantity: 1, group: 'Rau củ', checked: true },
  { id: 5, name: 'Trứng gà', amount: '6 quả', price: 21000, quantity: 1, group: 'Thực phẩm khác', checked: false },
]

const navigation = [
  { id: 'dashboard', label: 'Tổng quan', icon: 'grid' },
  { id: 'recipes', label: 'Công thức', icon: 'book' },
  { id: 'meal-plan', label: 'Thực đơn tuần', icon: 'calendar' },
  { id: 'statistics', label: 'Thống kê', icon: 'chart' },
  { id: 'shopping-list', label: 'Giá đi chợ dự kiến', icon: 'basket' },
]
const adminNavigation = { id: 'admin', label: 'Quản trị', icon: 'shield' }

const shoppingPlaces = [
  {
    title: 'Siêu thị có quầy thực phẩm tươi',
    description: 'Ưu tiên khi mua thịt, cá, trứng và hàng đóng gói cần nhãn mác, hạn dùng rõ ràng.',
    query: 'siêu thị thực phẩm tươi gần tôi',
  },
  {
    title: 'Cửa hàng thực phẩm sạch / hợp tác xã',
    description: 'Phù hợp để tìm rau củ có thông tin nguồn gốc; xem kỹ nhãn và chứng nhận trên từng sản phẩm.',
    query: 'cửa hàng thực phẩm sạch gần tôi',
  },
  {
    title: 'Quầy thực phẩm uy tín tại chợ',
    description: 'Có thể mua lượng nhỏ theo đúng công thức; chọn quầy sạch, hàng tươi và bảo quản riêng thực phẩm sống.',
    query: 'chợ thực phẩm gần tôi',
  },
]

const buyingGuides = [
  { group: 'Thịt cá', title: 'Thịt, cá và hải sản', detail: 'Chọn nơi có tủ mát hoặc đá sạch; thực phẩm không có mùi lạ, bề mặt không nhớt. Giữ lạnh và tách riêng đồ sống trên đường về.' },
  { group: 'Rau củ', title: 'Rau củ quả', detail: 'Chọn rau nguyên vẹn, không dập úng; mua theo bó hoặc cân đúng lượng công thức. Rửa dưới vòi nước sạch trước khi chế biến.' },
  { group: 'Thực phẩm khác', title: 'Trứng, sữa và thực phẩm tươi', detail: 'Kiểm tra vỏ trứng nguyên vẹn, bao bì còn kín, hạn sử dụng và hướng dẫn bảo quản; ưu tiên hàng được giữ lạnh đúng cách.' },
  { group: 'Ngũ cốc', title: 'Gạo, yến mạch và đồ khô', detail: 'Chọn bao bì khô, kín, có ngày sản xuất và hạn dùng; chỉ mua lượng dùng được trong thời gian bảo quản phù hợp.' },
  { group: 'Gia vị', title: 'Gia vị và thực phẩm đóng gói', detail: 'Kiểm tra niêm phong, nhãn thành phần, hạn dùng và tình trạng bao bì; tránh sản phẩm ẩm, rách hoặc không rõ nguồn gốc.' },
  { group: 'Khác', title: 'Nguyên liệu khác', detail: 'Đối chiếu tên và lượng ghi trong công thức; hỏi người bán cách chọn, sơ chế và bảo quản nếu chưa quen nguyên liệu.' },
]

const emptyRecipeForm = {
  title: '',
  summary: '',
  image_url: '',
  meal: 'lunch',
  cuisine: 'viet',
  method: '',
  base_servings: '2',
  prep_minutes: '10',
  cook_minutes: '20',
  difficulty: '1',
  kcal: '',
  protein_g: '',
  carb_g: '',
  fat_g: '',
  equipment: '',
}

const makeIngredientRow = () => ({ ingredient_id: '', amount_g: '', display_amount: '', display_unit: 'g', group_name: 'Nguyên liệu chính' })
const makeStepRow = (stepNo) => ({ step_no: stepNo, phase: stepNo === 1 ? 'prep' : 'cook', title: '', instruction: '', heat: 'none' })

const storagePrefix = 'nutricook.'

function readStoredValue(key, fallback, isValid) {
  try {
    const stored = window.localStorage.getItem(`${storagePrefix}${key}`)
    if (stored === null) return fallback

    const value = JSON.parse(stored)
    if (isValid(value)) return value

    console.warn(`Ignoring invalid saved NutriCook data for "${key}".`)
  } catch (error) {
    console.error(`Could not read saved NutriCook data for "${key}".`, error)
  }
  return fallback
}

function usePersistentState(key, initialValue, isValid) {
  const [value, setValue] = useState(() => readStoredValue(key, initialValue, isValid))
  const [storageError, setStorageError] = useState(false)

  const updateValue = (nextValueOrUpdater) => {
    const nextValue = typeof nextValueOrUpdater === 'function'
      ? nextValueOrUpdater(value)
      : nextValueOrUpdater
    setValue(nextValue)
    try {
      window.localStorage.setItem(`${storagePrefix}${key}`, JSON.stringify(nextValue))
      setStorageError(false)
    } catch (error) {
      console.error(`Could not save NutriCook data for "${key}".`, error)
      setStorageError(true)
    }
  }

  return [value, updateValue, storageError]
}

const isFavoriteList = (value) => Array.isArray(value) && value.every((id) => recipes.some((recipe) => recipe.id === id) || (typeof id === 'string' && id.startsWith('database-')))
const isGroceryList = (value) => Array.isArray(value) && value.every((item) => item
  && (typeof item.id === 'string' || typeof item.id === 'number')
  && typeof item.name === 'string'
  && typeof item.amount === 'string'
  && typeof item.group === 'string'
  && typeof item.checked === 'boolean'
  && Number.isFinite(item.quantity)
  && item.quantity >= 1
  && (item.price === null || Number.isFinite(item.price)))
const isMealRotation = (value) => value !== null && typeof value === 'object' && !Array.isArray(value)
const isWeekDay = (value) => Number.isInteger(value) && value >= 0 && value < 7
const isEatenMealList = (value) => Array.isArray(value) && value.every((meal) => meal
  && typeof meal.id === 'string'
  && typeof meal.date === 'string'
  && /^\d{4}-\d{2}-\d{2}$/u.test(meal.date)
  && Number.isInteger(meal.mealIndex)
  && meal.mealIndex >= 0
  && meal.mealIndex < mealOptions.length
  && typeof meal.mealLabel === 'string'
  && typeof meal.title === 'string'
  && meal.title.length > 0
  && Number.isFinite(meal.kcal)
  && meal.kcal >= 0
  && Number.isFinite(meal.protein)
  && meal.protein >= 0)

const iconPaths = {
  grid: <><rect x="3" y="3" width="7" height="7" rx="1.5" /><rect x="14" y="3" width="7" height="7" rx="1.5" /><rect x="3" y="14" width="7" height="7" rx="1.5" /><rect x="14" y="14" width="7" height="7" rx="1.5" /></>,
  book: <><path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H20v17H6.5A2.5 2.5 0 0 0 4 22z" /><path d="M4 5.5v14A2.5 2.5 0 0 1 6.5 17H20" /><path d="M8 7h8" /></>,
  calendar: <><rect x="3" y="5" width="18" height="16" rx="2" /><path d="M16 3v4M8 3v4M3 10h18" /><path d="m9 15 2 2 4-4" /></>,
  basket: <><path d="m5 10 2 10h10l2-10" /><path d="M3 10h18M8 10l4-7 4 7" /><path d="m10 14 2 2 2-2" /></>,
  shield: <><path d="M12 22s8-4 8-11V5l-8-3-8 3v6c0 7 8 11 8 11Z" /><path d="m9 12 2 2 4-4" /></>,
  search: <><circle cx="11" cy="11" r="7" /><path d="m20 20-4-4" /></>,
  bell: <><path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9" /><path d="M10 21h4" /></>,
  heart: <path d="M20.8 8.8c0 5.5-8.8 11-8.8 11s-8.8-5.5-8.8-11a4.8 4.8 0 0 1 8.8-2.6 4.8 4.8 0 0 1 8.8 2.6Z" />,
  clock: <><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" /></>,
  fire: <path d="M12 22c4.4 0 7-3.2 7-7.2 0-2.5-1.1-4.8-3.6-7.3.1 2.5-1 3.6-2.1 4.2.3-4.2-1.4-7.2-4.3-9.7.3 4.4-4 7.3-4 12.1C5 18.7 7.8 22 12 22Z" />,
  arrow: <><path d="M5 12h14" /><path d="m13 6 6 6-6 6" /></>,
  plus: <><path d="M12 5v14M5 12h14" /></>,
  minus: <path d="M5 12h14" />,
  close: <><path d="m18 6-12 12M6 6l12 12" /></>,
  refresh: <><path d="M20 7v5h-5" /><path d="M4.9 16a8 8 0 0 0 13.5 2L20 16M4 17v-5h5" /><path d="M19.1 8A8 8 0 0 0 5.6 6L4 8" /></>,
  check: <path d="m5 12 4 4L19 6" />,
  leaf: <><path d="M20 4c-8 0-14 3-14 10a6 6 0 0 0 6 6c7 0 10-7 8-16Z" /><path d="M4 21c3-6 7-9 13-12" /></>,
  user: <><circle cx="12" cy="8" r="4" /><path d="M5 21a7 7 0 0 1 14 0" /></>,
  chevron: <path d="m9 18 6-6-6-6" />,
  chart: <><path d="M4 19V5" /><path d="M4 19h17" /><path d="m7 15 4-4 3 2 6-7" /><path d="M20 6v4h-4" /></>,
  sparkles: <><path d="m12 3 1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8L12 3Z" /><path d="m19 14 1 2.5 2.5 1-2.5 1L19 21l-1-2.5-2.5-1 2.5-1L19 14Z" /></>,
}

function Icon({ name, size = 20, className = '' }) {
  return (
    <svg aria-hidden="true" className={className} width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      {iconPaths[name]}
    </svg>
  )
}

function RecipeCard({ recipe, favorite, onFavorite, onOpen }) {
  return (
    <article className="recipe-card">
      <button className="recipe-image-button" type="button" onClick={() => onOpen(recipe)} aria-label={`Xem ${recipe.title}`}>
        <img className="recipe-image" src={recipe.image} alt={recipe.title} loading="lazy" />
        <span className="recipe-tag">{recipe.tag}</span>
      </button>
      <div className="recipe-card-content">
        <div className="recipe-meta"><span>{recipe.category}</span><span><Icon name="clock" size={14} /> {recipe.time} phút</span></div>
        <button className="recipe-title-button" type="button" onClick={() => onOpen(recipe)}>{recipe.title}</button>
        <div className="recipe-card-bottom">
          <span className="recipe-kcal"><Icon name="fire" size={15} /> {recipe.kcal} kcal <i>·</i> {recipe.protein}g đạm</span>
          <button type="button" className={`icon-button favorite-button ${favorite ? 'is-favorite' : ''}`} onClick={() => onFavorite(recipe.id)} aria-label={favorite ? `Bỏ lưu ${recipe.title}` : `Lưu ${recipe.title}`}>
            <Icon name="heart" size={18} />
          </button>
        </div>
      </div>
    </article>
  )
}

function Dashboard({ setPage, onOpenRecipe, favorites, onFavorite }) {
  const currentDate = new Intl.DateTimeFormat('vi-VN', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
  }).format(new Date())

  return (
    <>
      <section className="welcome-row">
        <div><p className="eyebrow">{currentDate.toLocaleUpperCase('vi-VN')}</p><h1>Chào bạn <span className="wave">☀️</span></h1><p className="welcome-copy">Một ngày mới, thêm một cơ hội để chăm sóc bản thân.</p></div>
        <button className="button button-primary" onClick={() => setPage('meal-plan')}><Icon name="calendar" size={17} /> Xem thực đơn tuần</button>
      </section>

      <section className="summary-grid" aria-label="Tóm tắt hôm nay">
        <div className="panel calorie-panel">
          <div className="panel-heading"><div><p className="panel-kicker">TỔNG QUAN HÔM NAY</p><h2>Mục tiêu năng lượng</h2></div><span className="round-icon green"><Icon name="fire" /></span></div>
          <div className="calorie-content">
            <div className="calorie-ring"><div><strong>1.240</strong><span>/ 1.650 kcal</span></div></div>
            <div className="macro-list">
              <div className="macro-row"><span><i className="macro-dot protein-dot" />Đạm</span><strong>68 <small>/ 100g</small></strong></div>
              <div className="macro-row"><span><i className="macro-dot carb-dot" />Tinh bột</span><strong>142 <small>/ 206g</small></strong></div>
              <div className="macro-row"><span><i className="macro-dot fat-dot" />Chất béo</span><strong>38 <small>/ 55g</small></strong></div>
            </div>
          </div>
        </div>

        <div className="panel next-meal-panel">
          <div className="panel-heading"><div><p className="panel-kicker">GỢI Ý CHO BẠN</p><h2>Bữa tiếp theo</h2></div><span className="meal-time">12:30</span></div>
          <button className="next-meal-card" type="button" onClick={() => onOpenRecipe(recipes[0])}>
            <img src={recipes[0].image} alt="" />
            <span className="next-meal-info"><strong>{recipes[0].title}</strong><span><Icon name="clock" size={14} /> 25 phút <i>·</i> 420 kcal</span><span className="text-link">Xem công thức <Icon name="arrow" size={15} /></span></span>
          </button>
        </div>
      </section>

      <section className="section-block">
        <div className="section-heading"><div><p className="panel-kicker">KHÁM PHÁ MÓN NGON</p><h2>Công thức được yêu thích</h2></div><button className="text-button" onClick={() => setPage('recipes')}>Xem tất cả <Icon name="arrow" size={16} /></button></div>
        <div className="recipe-grid">
          {recipes.slice(0, 3).map((recipe) => <RecipeCard key={recipe.id} recipe={recipe} favorite={favorites.includes(recipe.id)} onFavorite={onFavorite} onOpen={onOpenRecipe} />)}
        </div>
      </section>

      <section className="week-banner">
        <div className="week-banner-icon"><Icon name="calendar" size={24} /></div>
        <div><p className="panel-kicker">LÊN KẾ HOẠCH DỄ DÀNG</p><h2>Tuần này mình ăn gì?</h2><p>Lên thực đơn và gom nguyên liệu cần mua trong một nơi.</p></div>
        <button className="button button-dark" onClick={() => setPage('meal-plan')}>Mở thực đơn <Icon name="arrow" size={16} /></button>
      </section>
    </>
  )
}

function RecipesPage({ recipes: allRecipes, favorites, onFavorite, onOpenRecipe }) {
  const [query, setQuery] = useState('')
  const [category, setCategory] = useState('Tất cả')
  const [favoritesOnly, setFavoritesOnly] = useState(false)
  const searchInput = useRef(null)
  const categories = ['Tất cả', 'Bữa sáng', 'Bữa trưa', 'Bữa tối']

  useEffect(() => {
    const handleShortcut = (event) => {
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') {
        event.preventDefault()
        searchInput.current?.focus()
      }
    }

    window.addEventListener('keydown', handleShortcut)
    return () => window.removeEventListener('keydown', handleShortcut)
  }, [])

  const filteredRecipes = useMemo(() => {
    const normalizedQuery = normalizeText(query.trim())
    return allRecipes.filter((recipe) => {
      const matchesCategory = category === 'Tất cả' || recipe.category === category
      const matchesQuery = !normalizedQuery || normalizeText(`${recipe.title} ${recipe.description} ${recipe.tag}`).includes(normalizedQuery)
      const matchesFavorite = !favoritesOnly || favorites.includes(recipe.id)
      return matchesCategory && matchesQuery && matchesFavorite
    })
  }, [allRecipes, category, favorites, favoritesOnly, query])

  return (
    <section className="page-section">
      <div className="page-title-row"><div><p className="eyebrow">TÌM CẢM HỨNG CHO BỮA ĂN</p><h1>Khám phá công thức</h1><p className="page-subtitle">Những món ngon để bạn tham khảo và thêm vào thực đơn.</p></div><span className="result-count">{filteredRecipes.length} công thức</span></div>
      <label className="search-field"><Icon name="search" size={20} /><input ref={searchInput} value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Tìm món ăn, nguyên liệu..." aria-label="Tìm công thức" /><kbd>Ctrl K</kbd></label>
      <div className="filter-row" role="group" aria-label="Lọc theo bữa ăn">{categories.map((item) => <button key={item} type="button" className={`filter-chip ${category === item ? 'active' : ''}`} onClick={() => setCategory(item)}>{item}</button>)}</div>
      <div className="filter-row" role="group" aria-label="Lọc công thức đã lưu"><button type="button" className={`filter-chip ${favoritesOnly ? 'active' : ''}`} aria-pressed={favoritesOnly} onClick={() => setFavoritesOnly((current) => !current)}>♡ Món đã lưu ({favorites.length})</button></div>
      {filteredRecipes.length ? <div className="recipe-grid recipe-grid-wide">{filteredRecipes.map((recipe) => <RecipeCard key={recipe.id} recipe={recipe} favorite={favorites.includes(recipe.id)} onFavorite={onFavorite} onOpen={onOpenRecipe} />)}</div> : <div className="empty-state"><span className="empty-icon"><Icon name="search" size={28} /></span><h2>{favoritesOnly && favorites.length === 0 ? 'Bạn chưa lưu công thức nào' : 'Chưa tìm thấy món phù hợp'}</h2><p>{favoritesOnly && favorites.length === 0 ? 'Nhấn biểu tượng trái tim trên món ăn để lưu công thức yêu thích.' : 'Thử tìm bằng tên món khác hoặc chọn bộ lọc khác nhé.'}</p><button className="button button-secondary" onClick={() => { setQuery(''); setCategory('Tất cả'); setFavoritesOnly(false) }}>Xóa bộ lọc</button></div>}
    </section>
  )
}

function MealPlanPage({ onOpenRecipe, onAddDayToList, mealRotation, setMealRotation, eatenMeals, setEatenMeals }) {
  const [selectedDay, setSelectedDay] = usePersistentState('selected-day', (new Date().getDay() + 6) % 7, isWeekDay)
  const days = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật']
  const today = new Date()
  const weekStart = new Date(today.getFullYear(), today.getMonth(), today.getDate() - ((today.getDay() + 6) % 7))
  const weekDates = days.map((_, index) => new Date(weekStart.getFullYear(), weekStart.getMonth(), weekStart.getDate() + index))
  const selectedDate = `${weekDates[selectedDay].getFullYear()}-${String(weekDates[selectedDay].getMonth() + 1).padStart(2, '0')}-${String(weekDates[selectedDay].getDate()).padStart(2, '0')}`
  const changeMeal = (key) => setMealRotation((current) => ({ ...current, [key]: !current[key] }))
  const selectedMeals = mealOptions.map((meal, index) => {
    const key = `${selectedDay}-${index}`
    const defaultOption = selectedDay % 2
    const option = (defaultOption + (mealRotation[key] ? 1 : 0)) % meal.options.length
    return { ...meal, recipe: meal.options[option] }
  })
  const plannedCalories = selectedMeals.reduce((total, meal) => total + meal.recipe.kcal, 0)
  const weekLabel = weekDates[0].getMonth() === weekDates[6].getMonth()
    ? `${weekDates[0].getDate()} – ${weekDates[6].getDate()} tháng ${weekDates[6].getMonth() + 1}, ${weekDates[6].getFullYear()}`
    : `${weekDates[0].getDate()} tháng ${weekDates[0].getMonth() + 1} – ${weekDates[6].getDate()} tháng ${weekDates[6].getMonth() + 1}, ${weekDates[6].getFullYear()}`

  return (
    <section className="page-section">
      <div className="page-title-row"><div><p className="eyebrow">LỊCH ĂN UỐNG CỦA BẠN</p><h1>Thực đơn tuần</h1><p className="page-subtitle">{weekLabel} <span className="subtle-dot">·</span> Thực đơn tuần</p></div><div className="title-actions"><button className="button button-secondary" onClick={() => setMealRotation({})}><Icon name="refresh" size={17} /> Tạo lại</button><button className="button button-primary" onClick={() => onAddDayToList(selectedMeals.map((meal) => meal.recipe))}><Icon name="basket" size={17} /> Gom nguyên liệu</button></div></div>
      <div className="week-strip" role="tablist" aria-label="Chọn ngày trong tuần">{days.map((day, index) => <button key={day} type="button" role="tab" aria-selected={selectedDay === index} className={`day-tab ${selectedDay === index ? 'selected' : ''}`} onClick={() => setSelectedDay(index)}><span>{day}</span><strong>{weekDates[index].getDate()}</strong>{weekDates[index].toDateString() === today.toDateString() && <i className="today-dot" />}</button>)}</div>
      <div className="plan-overview"><div className="plan-overview-icon"><Icon name="fire" size={20} /></div><div><strong>Năng lượng thực đơn: {plannedCalories.toLocaleString('vi-VN')} kcal / ngày</strong></div><span className="plan-status"><Icon name="check" size={15} /> Đã lên lịch</span></div>
      <div className="meal-list">{selectedMeals.map((meal, index) => {
        const key = `${selectedDay}-${index}`
        const recipe = meal.recipe
        const loggedMeal = eatenMeals.find((item) => item.id === `${selectedDate}-${index}`)
        const recipeNutrition = getRecipeDetail(recipe.id)?.nutrition ?? {}
        const logMealAsEaten = () => setEatenMeals((items) => [
          ...items.filter((item) => item.id !== `${selectedDate}-${index}`),
          {
            id: `${selectedDate}-${index}`,
            date: selectedDate,
            mealIndex: index,
            mealLabel: meal.label,
            recipeId: recipe.id,
            title: recipe.title,
            kcal: Number(recipe.kcal) || 0,
            protein: Number(recipeNutrition.protein) || Number(recipe.protein) || 0,
          },
        ])
        const removeEatenMeal = () => setEatenMeals((items) => items.filter((item) => item.id !== `${selectedDate}-${index}`))
        return <article className={`meal-row ${loggedMeal ? 'meal-row-eaten' : ''}`} key={meal.label}>
          <div className="meal-label"><span className="meal-emoji">{['🌤️', '☀️', '🌙'][index]}</span><span><strong>{meal.label}</strong><small>{meal.time}</small></span></div>
          <button className="meal-recipe" type="button" onClick={() => onOpenRecipe(recipe)}><img src={recipe.image} alt="" /><span><strong>{recipe.title}</strong><small><Icon name="clock" size={13} /> {recipe.time} phút <i>·</i> {recipe.kcal} kcal</small></span><Icon name="chevron" size={18} /></button>
          <div className="meal-row-actions">
            <button className="swap-button" type="button" onClick={() => changeMeal(key)}><Icon name="refresh" size={16} /><span>Đổi món</span></button>
            {loggedMeal ? <div className="meal-eaten-controls"><span className="meal-eaten-status"><Icon name="check" size={14} /> Đã ăn: {loggedMeal.title}</span>{loggedMeal.title !== recipe.title && <button className="meal-eaten-undo" type="button" onClick={logMealAsEaten}>Ghi nhận món này thay thế</button>}<button className="meal-eaten-undo" type="button" onClick={removeEatenMeal}>Bỏ ghi nhận</button></div> : <button className="meal-eaten-button" type="button" onClick={logMealAsEaten}><Icon name="check" size={15} /><span>Đã ăn món này</span></button>}
          </div>
        </article>
      })}</div>
    </section>
  )
}

function MealStatisticsPage({ eatenMeals, auth, configured, setPage }) {
  const [period, setPeriod] = useState('week')
  const [consent, setConsent] = useState(false)
  const [loadingAdvice, setLoadingAdvice] = useState(false)
  const [advice, setAdvice] = useState(null)
  const [error, setError] = useState('')
  const [aiConfigurationMissing, setAiConfigurationMissing] = useState(false)
  const stats = useMemo(() => buildMealPlanStats({
    period,
    eatenMeals,
  }), [period, eatenMeals])
  const maxChartKcal = Math.max(...stats.chart.map((item) => item.kcal), 1)

  const generateAdvice = async () => {
    if (!consent) {
      setError('Hãy xác nhận đồng ý chia sẻ thống kê thực đơn để tiếp tục.')
      return
    }
    if (!auth.session) {
      setError('Đăng nhập tài khoản để sử dụng lời khuyên AI.')
      return
    }
    setLoadingAdvice(true)
    setError('')
    setAiConfigurationMissing(false)
    setAdvice(null)
    try {
      setAdvice(await getMealPlanAdvice(stats))
    } catch (adviceError) {
      setError(adviceError.message || 'Không thể tạo lời khuyên AI.')
      setAiConfigurationMissing(adviceError.code === 'AI_NOT_CONFIGURED')
    } finally {
      setLoadingAdvice(false)
    }
  }

  return (
    <section className="page-section meal-statistics-page">
      <div className="page-title-row">
        <div><p className="eyebrow">NHẬT KÝ MÓN ĐÃ ĂN</p><h1>Thống kê món đã ăn</h1><p className="page-subtitle">Chỉ tính các món bạn đã xác nhận là đã ăn trong thực đơn tuần.</p></div>
        <div className="period-switch" role="group" aria-label="Khoảng thời gian thống kê">
          <button type="button" className={period === 'week' ? 'active' : ''} aria-pressed={period === 'week'} onClick={() => { setPeriod('week'); setAdvice(null); setError(''); setAiConfigurationMissing(false) }}>Tuần</button>
          <button type="button" className={period === 'month' ? 'active' : ''} aria-pressed={period === 'month'} onClick={() => { setPeriod('month'); setAdvice(null); setError(''); setAiConfigurationMissing(false) }}>Tháng</button>
        </div>
      </div>
      <div className="statistics-kpi-grid">
        <article className="statistics-kpi"><span className="statistics-kpi-icon"><Icon name="fire" size={19} /></span><small>Kcal đã ghi nhận trung bình / ngày</small><strong>{stats.averageKcal.toLocaleString('vi-VN')}</strong><span>kcal · {stats.periodLabel}</span></article>
        <article className="statistics-kpi"><span className="statistics-kpi-icon protein"><Icon name="leaf" size={19} /></span><small>Đạm đã ghi nhận trung bình / ngày</small><strong>{stats.averageProtein.toLocaleString('vi-VN')}</strong><span>g · theo công thức mẫu</span></article>
        <article className="statistics-kpi"><span className="statistics-kpi-icon meals"><Icon name="calendar" size={19} /></span><small>Món đã xác nhận là đã ăn</small><strong>{stats.mealCount}</strong><span>{stats.dayCount} ngày có ghi nhận · {stats.recipeCount} món khác nhau</span></article>
      </div>

      {stats.mealCount === 0 && <div className="statistics-empty-note"><h2>Chưa có món ăn được ghi nhận</h2><p>Vào mục Thực đơn tuần, chọn ngày và bấm “Đã ăn món này” sau khi ăn. Chỉ các món đã xác nhận mới xuất hiện trong thống kê.</p><button className="button button-secondary" type="button" onClick={() => setPage('meal-plan')}>Mở thực đơn tuần</button></div>}

      <div className="statistics-content-grid">
        <section className="statistics-panel">
          <div className="statistics-panel-heading"><div><h2>Kcal đã ghi nhận theo {period === 'week' ? 'ngày trong tuần' : 'tuần trong tháng'}</h2><p>Chỉ tính những món đã được xác nhận là đã ăn.</p></div><strong>{stats.totalKcal.toLocaleString('vi-VN')} kcal</strong></div>
          <div className={`statistics-chart ${period === 'month' ? 'monthly-chart' : ''}`} aria-label={`Biểu đồ kcal theo ${period === 'week' ? 'ngày' : 'tuần'}`}>
            {stats.chart.map((item) => <div className="statistics-bar-column" key={item.label} title={`${item.label}: ${item.kcal.toLocaleString('vi-VN')} kcal`}>
              <strong>{item.kcal.toLocaleString('vi-VN')}</strong>
              <div className="statistics-bar-track"><span style={{ height: `${Math.max(item.kcal / maxChartKcal * 100, 4)}%` }} /></div>
              <small>{item.label}</small>
            </div>)}
          </div>
          <div className="statistics-panel-heading statistics-recipes-heading"><div><h2>Món đã ăn nhiều nhất</h2><p>Số lần được xác nhận đã ăn trong khoảng thời gian.</p></div></div>
          <ul className="statistics-recipe-list">{stats.topRecipes.map((recipe) => <li key={recipe.title}><span>{recipe.title}</span><strong>{recipe.count} lần</strong></li>)}</ul>
        </section>

        <section className="statistics-ai-panel">
          <div className="statistics-ai-heading"><span className="statistics-ai-icon"><Icon name="sparkles" size={21} /></span><div><p className="eyebrow">TRỢ LÝ DINH DƯỠNG</p><h2>Lời khuyên từ AI</h2></div></div>
          <p className="statistics-ai-intro">AI chỉ nhận xét các món bạn đã xác nhận là đã ăn trong khoảng thời gian này.</p>
          {!configured && <div className="wizard-error" role="alert">Cần cấu hình Supabase và dịch vụ AI để sử dụng tính năng này.</div>}
          {configured && !auth.session && <div className="statistics-login-note">Bạn cần đăng nhập để gửi yêu cầu tới AI. <button className="text-button" type="button" onClick={() => setPage('onboarding')}>Đăng nhập</button></div>}
          <label className="statistics-consent"><input type="checkbox" checked={consent} onChange={(event) => { setConsent(event.target.checked); setError(''); setAiConfigurationMissing(false); setAdvice(null) }} /><span>Tôi đồng ý gửi thống kê các món đã xác nhận là đã ăn (không gồm tên, email hay hồ sơ sức khỏe) tới dịch vụ AI.</span></label>
          <button className="button button-primary statistics-ai-button" type="button" disabled={!configured || !auth.session || !consent || stats.mealCount === 0 || loadingAdvice} onClick={generateAdvice}><Icon name="sparkles" size={17} />{loadingAdvice ? 'Đang phân tích…' : 'Nhận lời khuyên AI'}</button>
          {error && <div className="wizard-error" role="alert">{error}</div>}
          {aiConfigurationMissing && <div className="statistics-ai-setup-note">Quản trị viên cần thêm <code>ANTHROPIC_API_KEY</code> vào Supabase Secrets rồi triển khai lại function <code>meal-plan-advice</code>. Khi chạy local, thêm khóa vào <code>supabase/.env.local</code> và khởi động lại function. Không nhập khóa tại trang này.</div>}
          {advice && <div className="statistics-advice" role="status"><h3>{advice.summary}</h3><ul>{advice.advice.map((item, index) => <li key={`${index}-${item}`}>{item}</li>)}</ul><p>{advice.reminder}</p></div>}
          <small className="statistics-ai-disclaimer">Lời khuyên mang tính tham khảo, không thay thế tư vấn của bác sĩ hoặc chuyên gia dinh dưỡng. Nếu AI chưa được cấu hình, trang sẽ thông báo rõ.</small>
        </section>
      </div>
    </section>
  )
}

function ShoppingListPage({ groceries, setGroceries }) {
  const [customName, setCustomName] = useState('')
  const [customAmount, setCustomAmount] = useState('')
  const [confirmClear, setConfirmClear] = useState(false)
  const updateItem = (id, change) => setGroceries((items) => items.map((item) => item.id === id ? { ...item, ...change } : item))
  const addCustomItem = (event) => {
    event.preventDefault()
    const name = customName.trim()
    if (!name) return
    setGroceries((items) => [...items, {
      id: `custom-${Date.now()}`,
      name,
      amount: customAmount.trim() || '1 món',
      price: estimateIngredientPrice(name, customAmount.trim() || '1 món'),
      quantity: 1,
      group: 'Khác',
      checked: false,
    }])
    setCustomName('')
    setCustomAmount('')
  }
  const pricedGroceries = groceries.map((item) => ({
    ...item,
    price: estimateIngredientPrice(item.name, item.amount, item.group),
  }))
  const subtotal = pricedGroceries.filter((item) => !item.checked).reduce((sum, item) => sum + item.price * item.quantity, 0)
  const groups = [...new Set(groceries.map((item) => item.group))]
  const remainingCount = pricedGroceries.filter((item) => !item.checked).reduce((sum, item) => sum + item.quantity, 0)
  const recipeGroups = pricedGroceries.reduce((result, item) => {
    const key = item.recipeId === undefined ? 'custom-items' : `recipe-${item.recipeId}`
    const recipeGroup = result.find((group) => group.key === key)
    if (recipeGroup) recipeGroup.items.push(item)
    else result.push({ key, title: item.recipeName || (key === 'custom-items' ? 'Nguyên liệu thêm' : 'Công thức'), items: [item] })
    return result
  }, [])
  const clearShoppingList = () => {
    setGroceries([])
    setConfirmClear(false)
  }

  return (
    <section className="page-section">
      <div className="page-title-row"><div><p className="eyebrow">CHUẨN BỊ CHO BỮA ĂN</p><h1>Giá đi chợ dự kiến</h1><p className="page-subtitle">Ước tính chi phí và chuẩn bị đúng nguyên liệu cho thực đơn của bạn.</p></div><div className="title-actions">{confirmClear ? <><span className="shopping-clear-confirm-copy">Xóa toàn bộ nguyên liệu?</span><button className="button button-danger" type="button" onClick={clearShoppingList}>Xác nhận xóa</button><button className="button button-secondary" type="button" onClick={() => setConfirmClear(false)}>Hủy</button></> : <button className="button button-secondary" type="button" onClick={() => setConfirmClear(true)}><Icon name="refresh" size={17} /> Tạo lại danh sách</button>}</div></div>
      <form className="shopping-add-form" onSubmit={addCustomItem}><label><span>Thêm nguyên liệu</span><input value={customName} onChange={(event) => setCustomName(event.target.value)} placeholder="Ví dụ: Rau thơm" aria-label="Tên nguyên liệu" /></label><label><span>Số lượng</span><input value={customAmount} onChange={(event) => setCustomAmount(event.target.value)} placeholder="Ví dụ: 1 bó" aria-label="Số lượng nguyên liệu" /></label><button className="button button-secondary" type="submit"><Icon name="plus" size={16} /> Thêm món</button></form>
      <div className="shopping-layout">
        <div className="grocery-groups">{groceries.length === 0 ? <div className="empty-state"><h2>Chưa có nguyên liệu</h2><p>Chọn công thức hoặc thêm nguyên liệu để ước tính chi phí cho bữa ăn.</p></div> : recipeGroups.map((recipeGroup) => <details className="grocery-group recipe-grocery-group" key={recipeGroup.key} open><summary className="grocery-group-title"><h2>{recipeGroup.title}</h2><span>{recipeGroup.items.length} nguyên liệu <i>·</i> {recipeGroup.items.reduce((sum, item) => sum + item.price * item.quantity, 0).toLocaleString('vi-VN')}đ</span></summary>{recipeGroup.items.map((item) => <article className={`grocery-item ${item.checked ? 'checked' : ''}`} key={item.id}><label className="check-label"><input type="checkbox" checked={item.checked} onChange={(event) => updateItem(item.id, { checked: event.target.checked })} /><span className="custom-check"><Icon name="check" size={14} /></span><span className="grocery-name-wrap"><strong>{item.name}</strong><small>{item.amount}{item.quantity > 1 ? ` × ${item.quantity}` : ''}{item.checked ? ' · Đã có' : ' · Cần mua'}</small></span></label><div className="grocery-actions"><strong className="grocery-price">{(item.price * item.quantity).toLocaleString('vi-VN')}đ</strong><div className="quantity-stepper" aria-label={`Số lượng phần mua ${item.name}`}><button type="button" aria-label={`Giảm số lượng ${item.name}`} onClick={() => updateItem(item.id, { quantity: Math.max(1, item.quantity - 1) })}><Icon name="minus" size={15} /></button><span>{item.quantity}</span><button type="button" aria-label={`Tăng số lượng ${item.name}`} onClick={() => updateItem(item.id, { quantity: item.quantity + 1 })}><Icon name="plus" size={15} /></button></div><button type="button" className="grocery-remove" aria-label={`Xóa ${item.name}`} onClick={() => setGroceries((items) => items.filter((entry) => entry.id !== item.id))}>×</button></div></article>)}</details>)}
          <section className="buying-guide"><div className="buying-guide-heading"><span className="summary-icon"><Icon name="check" size={20} /></span><div><p className="eyebrow">MUA ĐÚNG, DÙNG AN TÂM</p><h2>Chọn nguyên liệu sao cho đúng</h2></div></div><div className="buying-guide-grid">{buyingGuides.filter((guide) => groups.includes(guide.group)).map((guide) => <article className="buying-guide-card" key={guide.group}><strong>{guide.title}</strong><p>{guide.detail}</p></article>)}</div></section>
        </div>
        <aside className="shopping-aside">
          <section className="shopping-summary"><div className="summary-icon"><Icon name="basket" size={22} /></div><h2>Dự kiến tiền đi chợ</h2><p>{remainingCount} phần nguyên liệu cần mua</p><div className="summary-line"><span>Chi phí nguyên liệu</span><strong>{subtotal.toLocaleString('vi-VN')}đ</strong></div><div className="summary-total"><span>Tổng dự kiến</span><strong>{subtotal.toLocaleString('vi-VN')}đ</strong></div><p className="price-estimate-note">Giá ước tính theo lượng đã chọn; giá thực tế có thể khác theo nơi bán và thời điểm.</p></section>
          <section className="shopping-places"><p className="eyebrow">GỢI Ý NƠI MUA</p><h2>Chọn nơi mua phù hợp</h2>{shoppingPlaces.map((place) => <article className="shopping-place" key={place.title}><strong>{place.title}</strong><p>{place.description}</p><a href={`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(place.query)}`} target="_blank" rel="noreferrer">Tìm gần bạn <Icon name="arrow" size={14} /></a></article>)}</section>
        </aside>
      </div>
    </section>
  )
}

function AdminPage({ user, isAdmin, onRecipePublished }) {
  const [activeTab, setActiveTab] = useState('recipes')
  const [accounts, setAccounts] = useState([])
  const [accountQuery, setAccountQuery] = useState('')
  const [recipesAdmin, setRecipesAdmin] = useState([])
  const [ingredientCatalog, setIngredientCatalog] = useState([])
  const [recipeForm, setRecipeForm] = useState(emptyRecipeForm)
  const [ingredientRows, setIngredientRows] = useState([makeIngredientRow(), makeIngredientRow(), makeIngredientRow()])
  const [stepRows, setStepRows] = useState([1, 2, 3, 4].map(makeStepRow))
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [publishNow, setPublishNow] = useState(false)
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')
  const [blockFormAccountId, setBlockFormAccountId] = useState('')
  const [blockReason, setBlockReason] = useState('')
  const [blockUntil, setBlockUntil] = useState('')
  const [accountActionId, setAccountActionId] = useState('')

  const loadAdminData = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const [nextRecipes, nextIngredients, nextAccounts] = await Promise.all([
        getAdminRecipes(),
        getIngredientCatalog(),
        getAdminAccounts(),
      ])
      setRecipesAdmin(nextRecipes)
      setIngredientCatalog(nextIngredients)
      setAccounts(nextAccounts)
    } catch (loadError) {
      setError(`Không thể tải dữ liệu quản trị: ${loadError.message}`)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    if (!isAdmin) return undefined
    const timer = window.setTimeout(() => { loadAdminData() }, 0)
    return () => window.clearTimeout(timer)
  }, [isAdmin, loadAdminData])

  const searchAccounts = async (event) => {
    event.preventDefault()
    setLoading(true)
    setError('')
    try {
      setAccounts(await getAdminAccounts(accountQuery))
    } catch (loadError) {
      setError(`Không thể tìm tài khoản: ${loadError.message}`)
    } finally {
      setLoading(false)
    }
  }

  const submitAccountBlock = async (event, account) => {
    event.preventDefault()
    setError('')
    setNotice('')
    setAccountActionId(account.id)
    try {
      await manageAdminAccount({
        action: 'block',
        userId: account.id,
        reason: blockReason,
        blockedUntil: blockUntil ? new Date(blockUntil).toISOString() : null,
      })
      setNotice(`Đã chặn tài khoản ${account.email}.`)
      setBlockFormAccountId('')
      setBlockReason('')
      setBlockUntil('')
      setAccounts(await getAdminAccounts(accountQuery))
    } catch (actionError) {
      setError(`Kết quả thao tác chặn: ${actionError.message}`)
    } finally {
      setAccountActionId('')
    }
  }

  const handleAccountAction = async (action, account) => {
    const actionLabel = action === 'delete' ? 'xóa vĩnh viễn' : 'bỏ chặn'
    if (action === 'delete' && !window.confirm(`Xóa vĩnh viễn tài khoản ${account.email} cùng toàn bộ dữ liệu liên quan? Thao tác này không thể hoàn tác.`)) return
    setError('')
    setNotice('')
    setAccountActionId(account.id)
    try {
      await manageAdminAccount({ action, userId: account.id })
      setNotice(action === 'delete' ? `Đã xóa tài khoản ${account.email} và dữ liệu liên quan.` : `Đã bỏ chặn tài khoản ${account.email}.`)
      setAccounts(await getAdminAccounts(accountQuery))
    } catch (actionError) {
      setError(`Kết quả thao tác ${actionLabel} tài khoản: ${actionError.message}`)
    } finally {
      setAccountActionId('')
    }
  }

  const setRecipeField = (field, value) => setRecipeForm((current) => ({ ...current, [field]: value }))
  const setIngredientField = (index, field, value) => setIngredientRows((current) => current.map((row, rowIndex) => rowIndex === index ? { ...row, [field]: value } : row))
  const setStepField = (index, field, value) => setStepRows((current) => current.map((row, rowIndex) => rowIndex === index ? { ...row, [field]: value } : row))

  const submitRecipe = async (event) => {
    event.preventDefault()
    setError('')
    setNotice('')
    const selectedIngredients = ingredientRows.filter((row) => row.ingredient_id && row.amount_g)
    const completeSteps = stepRows.filter((step) => step.title.trim() && step.instruction.trim())
    const slug = normalizeText(recipeForm.title).replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')
    if (selectedIngredients.length === 0 || completeSteps.length === 0) {
      setError('Hãy thêm ít nhất một nguyên liệu và một bước nấu.')
      return
    }
    if (publishNow && (selectedIngredients.length < 3 || completeSteps.length < 4 || completeSteps.some((step) => step.instruction.trim().length < 20) || !recipeForm.image_url.trim() || !recipeForm.kcal || !recipeForm.equipment.trim())) {
      setError('Để xuất bản, cần ít nhất 3 nguyên liệu, 4 bước hướng dẫn chi tiết, ảnh, kcal và dụng cụ nấu.')
      return
    }

    setSaving(true)
    try {
      await createAdminRecipe({
        recipe: {
          ...recipeForm,
          slug,
          base_servings: Number(recipeForm.base_servings),
          prep_minutes: Number(recipeForm.prep_minutes),
          cook_minutes: Number(recipeForm.cook_minutes),
          difficulty: Number(recipeForm.difficulty),
          kcal: recipeForm.kcal ? Number(recipeForm.kcal) : null,
          protein_g: recipeForm.protein_g ? Number(recipeForm.protein_g) : null,
          carb_g: recipeForm.carb_g ? Number(recipeForm.carb_g) : null,
          fat_g: recipeForm.fat_g ? Number(recipeForm.fat_g) : null,
          equipment: recipeForm.equipment.split(',').map((item) => item.trim()).filter(Boolean),
          meal: [recipeForm.meal],
          diet_tags: ['normal'],
        },
        ingredients: selectedIngredients.map((row, index) => ({
          ...row,
          amount_g: Number(row.amount_g),
          display_amount: row.display_amount ? Number(row.display_amount) : Number(row.amount_g),
          sort_order: index + 1,
        })),
        steps: completeSteps.map((step, index) => ({ ...step, step_no: index + 1 })),
        publish: publishNow,
      })
      setRecipeForm(emptyRecipeForm)
      setIngredientRows([makeIngredientRow(), makeIngredientRow(), makeIngredientRow()])
      setStepRows([1, 2, 3, 4].map(makeStepRow))
      setPublishNow(false)
      setNotice(publishNow ? 'Đã thêm và xuất bản công thức.' : 'Đã lưu công thức ở trạng thái bản nháp.')
      await loadAdminData()
      if (publishNow) await onRecipePublished()
    } catch (saveError) {
      setError(`Không thể lưu công thức: ${saveError.message}`)
    } finally {
      setSaving(false)
    }
  }

  if (!isAdmin) {
    return <section className="page-section"><div className="empty-state"><h1>Không có quyền truy cập</h1><p>Khu vực quản trị chỉ dành cho tài khoản admin.</p></div></section>
  }

  return (
    <section className="page-section admin-page">
      <div className="page-title-row"><div><p className="eyebrow">QUẢN TRỊ NUTRICOOK</p><h1>Bảng điều khiển admin</h1><p className="page-subtitle">Đang đăng nhập: {user.email}</p></div><button className="button button-secondary" type="button" onClick={loadAdminData} disabled={loading}><Icon name="refresh" size={17} /> Làm mới</button></div>
      <div className="admin-tabs" role="tablist" aria-label="Khu vực quản trị">
        <button type="button" role="tab" aria-selected={activeTab === 'recipes'} className={activeTab === 'recipes' ? 'active' : ''} onClick={() => setActiveTab('recipes')}>Công thức ({recipesAdmin.length})</button>
        <button type="button" role="tab" aria-selected={activeTab === 'accounts'} className={activeTab === 'accounts' ? 'active' : ''} onClick={() => setActiveTab('accounts')}>Tài khoản ({accounts.length})</button>
      </div>
      {error && <div className="wizard-error" role="alert">{error}</div>}
      {notice && <div className="profile-saved-message" role="status">{notice}</div>}
      {loading ? <div className="profile-access-card" role="status">Đang tải dữ liệu quản trị…</div> : activeTab === 'accounts' ? (
        <div className="admin-panel">
          <div className="admin-panel-heading"><div><h2>Tài khoản người dùng</h2><p>Hồ sơ sức khỏe không hiển thị. Có thể chặn đăng nhập theo lý do/thời hạn hoặc xóa vĩnh viễn tài khoản.</p></div></div>
          <form className="admin-search-form" onSubmit={searchAccounts}><label className="search-field"><Icon name="search" size={18} /><input value={accountQuery} onChange={(event) => setAccountQuery(event.target.value)} placeholder="Tìm theo tên hoặc email" aria-label="Tìm tài khoản theo tên hoặc email" /></label><button className="button button-secondary" type="submit">Tìm kiếm</button></form>
          {accounts.length ? <div className="admin-table-wrap"><table className="admin-table"><thead><tr><th>Họ tên</th><th>Email</th><th>Vai trò</th><th>Ngày tạo</th><th>Trạng thái</th><th>Thao tác</th></tr></thead><tbody>{accounts.map((account) => {
            const protectedAccount = account.role === 'admin' || account.id === user?.id
            const currentlyBlocked = account.is_blocked
            return <Fragment key={account.id}>
              <tr>
                <td>{account.full_name || 'Chưa cập nhật'}</td>
                <td>{account.email || '—'}</td>
                <td><span className={`admin-role role-${account.role}`}>{account.role}</span></td>
                <td>{account.created_at ? new Date(account.created_at).toLocaleDateString('vi-VN') : '—'}</td>
                <td><span className={`admin-account-status ${currentlyBlocked ? 'blocked' : ''}`}>{currentlyBlocked ? account.blocked_until ? `Bị chặn đến ${new Date(account.blocked_until).toLocaleString('vi-VN')}` : 'Bị chặn vô thời hạn' : account.blocked_at ? 'Đã hết hạn chặn' : 'Hoạt động'}</span>{currentlyBlocked && account.block_reason && <small className="admin-block-reason">{account.block_reason}</small>}</td>
                <td><div className="admin-account-actions">
                  {!protectedAccount && (currentlyBlocked
                    ? <button className="button button-secondary" type="button" disabled={accountActionId === account.id} onClick={() => handleAccountAction('unblock', account)}>Bỏ chặn</button>
                    : <button className="button button-secondary" type="button" disabled={accountActionId === account.id} onClick={() => { setBlockFormAccountId(blockFormAccountId === account.id ? '' : account.id); setBlockReason(''); setBlockUntil('') }}>Chặn</button>)}
                  {!protectedAccount && <button className="button button-danger" type="button" disabled={accountActionId === account.id} onClick={() => handleAccountAction('delete', account)}>Xóa</button>}
                  {protectedAccount && <span className="admin-empty-copy">{account.id === user?.id ? 'Tài khoản hiện tại' : 'Admin được bảo vệ'}</span>}
                </div></td>
              </tr>
              {blockFormAccountId === account.id && <tr><td colSpan="6"><form className="admin-account-block-form" onSubmit={(event) => submitAccountBlock(event, account)}>
                <label className="form-control"><span>Lý do chặn</span><textarea required maxLength={500} rows={2} value={blockReason} onChange={(event) => setBlockReason(event.target.value)} /></label>
                <label className="form-control"><span>Chặn đến (để trống để chặn vô thời hạn)</span><input type="datetime-local" value={blockUntil} onChange={(event) => setBlockUntil(event.target.value)} /></label>
                <div className="admin-account-block-actions"><button className="button button-primary" type="submit" disabled={accountActionId === account.id}>{accountActionId === account.id ? 'Đang chặn…' : 'Xác nhận chặn'}</button><button className="button button-secondary" type="button" onClick={() => setBlockFormAccountId('')}>Hủy</button></div>
              </form></td></tr>}
            </Fragment>
          })}</tbody></table></div> : <div className="empty-state"><h3>Không tìm thấy tài khoản</h3><p>Thử từ khóa tên hoặc email khác.</p></div>}
        </div>
      ) : (
        <div className="admin-content-grid">
          <form className="admin-panel admin-recipe-form" onSubmit={submitRecipe}>
            <div className="admin-panel-heading"><div><h2>Thêm công thức mới</h2><p>Chọn nguyên liệu trong danh mục để tính lượng và dinh dưỡng.</p></div></div>
            <div className="admin-form-grid">
              <label className="form-control admin-span-two"><span>Tên món</span><input required maxLength={120} value={recipeForm.title} onChange={(event) => setRecipeField('title', event.target.value)} /></label>
              <label className="form-control admin-span-two"><span>Mô tả ngắn</span><textarea maxLength={500} rows={2} value={recipeForm.summary} onChange={(event) => setRecipeField('summary', event.target.value)} /></label>
              <label className="form-control admin-span-two"><span>Đường dẫn ảnh</span><input type="url" placeholder="https://..." value={recipeForm.image_url} onChange={(event) => setRecipeField('image_url', event.target.value)} /></label>
              <label className="form-control"><span>Bữa ăn</span><select value={recipeForm.meal} onChange={(event) => setRecipeField('meal', event.target.value)}><option value="breakfast">Bữa sáng</option><option value="lunch">Bữa trưa</option><option value="dinner">Bữa tối</option><option value="snack">Bữa phụ</option></select></label>
              <label className="form-control"><span>Cách nấu</span><input value={recipeForm.method} onChange={(event) => setRecipeField('method', event.target.value)} placeholder="Ví dụ: áp chảo" /></label>
              <label className="form-control"><span>Thời gian sơ chế (phút)</span><input type="number" min="0" value={recipeForm.prep_minutes} onChange={(event) => setRecipeField('prep_minutes', event.target.value)} /></label>
              <label className="form-control"><span>Thời gian nấu (phút)</span><input type="number" min="0" value={recipeForm.cook_minutes} onChange={(event) => setRecipeField('cook_minutes', event.target.value)} /></label>
              <label className="form-control"><span>Khẩu phần</span><input type="number" min="1" max="12" value={recipeForm.base_servings} onChange={(event) => setRecipeField('base_servings', event.target.value)} /></label>
              <label className="form-control"><span>Độ khó</span><select value={recipeForm.difficulty} onChange={(event) => setRecipeField('difficulty', event.target.value)}><option value="1">Dễ</option><option value="2">Trung bình</option><option value="3">Khó</option></select></label>
              <label className="form-control"><span>Năng lượng (kcal)</span><input type="number" min="0" value={recipeForm.kcal} onChange={(event) => setRecipeField('kcal', event.target.value)} /></label>
              <label className="form-control"><span>Đạm (g)</span><input type="number" min="0" step="0.1" value={recipeForm.protein_g} onChange={(event) => setRecipeField('protein_g', event.target.value)} /></label>
              <label className="form-control"><span>Tinh bột (g)</span><input type="number" min="0" step="0.1" value={recipeForm.carb_g} onChange={(event) => setRecipeField('carb_g', event.target.value)} /></label>
              <label className="form-control"><span>Chất béo (g)</span><input type="number" min="0" step="0.1" value={recipeForm.fat_g} onChange={(event) => setRecipeField('fat_g', event.target.value)} /></label>
              <label className="form-control admin-span-two"><span>Dụng cụ (phân cách bằng dấu phẩy)</span><input value={recipeForm.equipment} onChange={(event) => setRecipeField('equipment', event.target.value)} placeholder="Chảo, nồi, dao" /></label>
            </div>
            <div className="admin-section-heading"><h3>Nguyên liệu</h3><button className="text-button" type="button" onClick={() => setIngredientRows((current) => [...current, makeIngredientRow()])}><Icon name="plus" size={15} /> Thêm dòng</button></div>
            {ingredientRows.map((row, index) => <div className="admin-ingredient-row" key={`ingredient-${index}`}>
              <label className="form-control"><span>Nguyên liệu</span><select value={row.ingredient_id} onChange={(event) => setIngredientField(index, 'ingredient_id', event.target.value)}><option value="">Chọn nguyên liệu</option>{ingredientCatalog.map((ingredient) => <option value={ingredient.id} key={ingredient.id}>{ingredient.name_vi}</option>)}</select></label>
              <label className="form-control"><span>Lượng quy đổi (g)</span><input type="number" min="0.1" step="0.1" value={row.amount_g} onChange={(event) => setIngredientField(index, 'amount_g', event.target.value)} /></label>
              <label className="form-control"><span>Lượng hiển thị</span><input type="number" min="0.1" step="0.1" value={row.display_amount} onChange={(event) => setIngredientField(index, 'display_amount', event.target.value)} /></label>
              <label className="form-control"><span>Đơn vị</span><input value={row.display_unit} onChange={(event) => setIngredientField(index, 'display_unit', event.target.value)} /></label>
              <button className="grocery-remove" type="button" aria-label={`Xóa dòng nguyên liệu ${index + 1}`} disabled={ingredientRows.length <= 1} onClick={() => setIngredientRows((current) => current.filter((_, rowIndex) => rowIndex !== index))}>×</button>
            </div>)}
            <div className="admin-section-heading"><h3>Các bước nấu</h3><button className="text-button" type="button" onClick={() => setStepRows((current) => [...current, makeStepRow(current.length + 1)])}><Icon name="plus" size={15} /> Thêm bước</button></div>
            {stepRows.map((step, index) => <div className="admin-step-row" key={`step-${index}`}>
              <div className="admin-step-row-heading"><strong>Bước {index + 1}</strong><button className="text-button" type="button" disabled={stepRows.length <= 1} onClick={() => setStepRows((current) => current.filter((_, rowIndex) => rowIndex !== index))}>Xóa bước</button></div>
              <div className="admin-form-grid">
                <label className="form-control"><span>Giai đoạn</span><select value={step.phase} onChange={(event) => setStepField(index, 'phase', event.target.value)}><option value="prep">Sơ chế</option><option value="cook">Nấu</option><option value="finish">Hoàn thiện</option></select></label>
                <label className="form-control"><span>Tên bước</span><input value={step.title} onChange={(event) => setStepField(index, 'title', event.target.value)} /></label>
                <label className="form-control admin-span-two"><span>Hướng dẫn chi tiết</span><textarea rows={2} value={step.instruction} onChange={(event) => setStepField(index, 'instruction', event.target.value)} /></label>
              </div>
            </div>)}
            <label className="admin-publish-check"><input type="checkbox" checked={publishNow} onChange={(event) => setPublishNow(event.target.checked)} /><span>Xuất bản sau khi lưu (công thức phải đáp ứng điều kiện an toàn và nội dung).</span></label>
            <button className="button button-primary" type="submit" disabled={saving}>{saving ? 'Đang lưu…' : 'Lưu công thức'}</button>
          </form>
          <aside className="admin-panel admin-recipe-list"><div className="admin-panel-heading"><div><h2>Công thức trong hệ thống</h2><p>{recipesAdmin.length} công thức gần đây</p></div></div>{recipesAdmin.length ? recipesAdmin.map((recipe) => <article className="admin-recipe-item" key={recipe.id}><div><strong>{recipe.title}</strong><small>{recipe.meal?.map((meal) => ({ breakfast: 'Sáng', lunch: 'Trưa', dinner: 'Tối', snack: 'Bữa phụ' }[meal] ?? meal)).join(', ')}</small></div><span className={`admin-status status-${recipe.status}`}>{recipe.status}</span></article>) : <p className="admin-empty-copy">Chưa có công thức nào trong hệ thống.</p>}</aside>
        </div>
      )}
    </section>
  )
}

function RecipeDialog({ recipe, servings, setServings, onClose, onAdd }) {
  const [activeTab, setActiveTab] = useState('ingredients')
  if (!recipe) return null
  const detail = recipe.detail ?? getRecipeDetail(recipe.id)
  if (!detail) return null
  const tabs = [
    { id: 'ingredients', label: 'Nguyên liệu' },
    { id: 'steps', label: 'Cách làm' },
    { id: 'nutrition', label: 'Dinh dưỡng' },
  ]

  return (
    <div className="dialog-backdrop" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose() }}>
      <section className="recipe-dialog" role="dialog" aria-modal="true" aria-labelledby="dialog-title">
        <button className="dialog-close icon-button" type="button" onClick={onClose} aria-label="Đóng"><Icon name="close" /></button>
        <img className="dialog-image" src={recipe.image} alt={recipe.title} />
        <div className="dialog-content"><p className="eyebrow">{recipe.category} <span className="subtle-dot">·</span> {recipe.time} phút</p><h2 id="dialog-title">{recipe.title}</h2><p>{recipe.description}</p>
          <div className="detail-stats"><span><Icon name="fire" size={17} /> {recipe.kcal} kcal / khẩu phần</span><span><Icon name="leaf" size={17} /> {recipe.protein}g đạm</span><span><Icon name="clock" size={17} /> {recipe.time} phút</span></div>
          <div className="recipe-detail-tabs" role="tablist" aria-label="Thông tin công thức">{tabs.map((tab) => <button key={tab.id} className={activeTab === tab.id ? 'active' : ''} type="button" role="tab" aria-selected={activeTab === tab.id} aria-controls={`recipe-tab-${tab.id}`} onClick={() => setActiveTab(tab.id)}>{tab.label}</button>)}</div>
          {activeTab === 'ingredients' && <div className="recipe-tab-content" id="recipe-tab-ingredients" role="tabpanel"><div className="servings-row"><span><strong>Khẩu phần</strong><small>Lượng cơ bản cho {recipe.baseServings ?? 2} người</small></span><div className="quantity-stepper"><button onClick={() => setServings(Math.max(1, servings - 1))} aria-label="Giảm khẩu phần"><Icon name="minus" size={15} /></button><span>{servings}</span><button onClick={() => setServings(Math.min(12, servings + 1))} aria-label="Tăng khẩu phần"><Icon name="plus" size={15} /></button></div></div><ul className="recipe-ingredient-list">{detail.ingredients.map((ingredient) => { const amount = `${formatIngredientAmount(scaleRecipeIngredient(ingredient, servings, recipe.baseServings ?? 2))} ${ingredient.unit}`; const price = estimateIngredientPrice(ingredient.name, amount, ingredient.group); return <li key={ingredient.name}><span><Icon name="leaf" size={15} />{ingredient.name}</span><strong>{amount} · {price.toLocaleString('vi-VN')}đ</strong></li> })}</ul></div>}
          {activeTab === 'steps' && <div className="recipe-tab-content" id="recipe-tab-steps" role="tabpanel"><ol className="recipe-step-list">{detail.steps.map((step, index) => <li key={step}><span>{index + 1}</span><p>{step}</p></li>)}</ol></div>}
          {activeTab === 'nutrition' && <div className="recipe-tab-content" id="recipe-tab-nutrition" role="tabpanel"><div className="nutrition-detail-grid"><div><span>Năng lượng</span><strong>{recipe.kcal} <small>kcal</small></strong></div><div><span>Đạm</span><strong>{detail.nutrition.protein} <small>g</small></strong></div><div><span>Tinh bột</span><strong>{detail.nutrition.carb} <small>g</small></strong></div><div><span>Chất béo</span><strong>{detail.nutrition.fat} <small>g</small></strong></div><div><span>Natri</span><strong>{detail.nutrition.sodium} <small>mg</small></strong></div></div>          <div className="allergen-notice"><strong>Thành phần dị ứng</strong><span>{detail.allergens.length ? detail.allergens.join(', ') : 'Không có dữ liệu'}.</span></div></div>}
          <button className="button button-primary full-width recipe-add-button" onClick={() => onAdd(recipe, servings)}><Icon name="basket" size={17} /> Thêm nguyên liệu vào danh sách</button>
        </div>
      </section>
    </div>
  )
}

const goals = [
  { value: 'lose', label: 'Giảm cân nhẹ', detail: 'Tham khảo mức điều chỉnh nhỏ' },
  { value: 'maintain', label: 'Duy trì', detail: 'Tập trung vào thói quen cân bằng' },
  { value: 'gain', label: 'Tăng cân', detail: 'Tham khảo mức điều chỉnh nhỏ' },
  { value: 'muscle', label: 'Tăng cơ', detail: 'Kết hợp vận động phù hợp' },
  { value: 'healthy', label: 'Ăn lành mạnh', detail: 'Không đặt mục tiêu cân nặng' },
]

const allergenOptions = ['Đậu phộng', 'Hải sản', 'Tôm cua', 'Sữa', 'Trứng', 'Gluten', 'Đậu nành', 'Vừng']

const emptyProfile = {
  sex: '',
  birthDate: '',
  heightCm: '',
  weightKg: '',
  goal: '',
  targetWeightKg: '',
  activity: '',
  conditions: [],
  diet: 'balanced',
  allergies: [],
  dislikedIngredients: '',
  cookingTime: '30',
  budget: 'medium',
  cookingSkill: 'beginner',
}

function ProfileLoginPage({ configured, authError, onAdminLogin }) {
  const [mode, setMode] = useState('login')
  const [email, setEmail] = useState('')
  const [fullName, setFullName] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [error, setError] = useState(authError)
  const [message, setMessage] = useState('')
  const [submitting, setSubmitting] = useState(false)

  const submit = async (event) => {
    event.preventDefault()
    setError('')
    setMessage('')
    if (mode === 'signup' && password !== confirmPassword) {
      setError('Mật khẩu xác nhận chưa khớp.')
      return
    }
    setSubmitting(true)
    try {
      if (mode === 'signup') {
        const { session } = await signUpWithEmail({ email: email.trim(), password, fullName: fullName.trim() })
        if (session) {
          setMessage('Đăng ký thành công. Bạn đã được đăng nhập, không cần xác nhận email.')
        } else {
          setMessage('Tài khoản đã được tạo. Hãy đăng nhập để tiếp tục.')
        }
      } else {
        if (mode === 'admin') {
          const { user } = await signInAsAdminWithEmail({ email: email.trim(), password })
          onAdminLogin(user.id)
        } else {
          await signInWithEmail({ email: email.trim(), password })
        }
      }
    } catch (authError) {
      setError(authError.message || (mode === 'signup' ? 'Không thể tạo tài khoản.' : 'Không thể đăng nhập. Hãy kiểm tra email và mật khẩu.'))
    } finally {
      setSubmitting(false)
    }
  }

  const changeMode = (nextMode) => {
    setMode(nextMode)
    setError('')
    setMessage('')
  }

  return (
    <section className="onboarding-page">
      <div className="onboarding-heading"><div><p className="eyebrow">HỒ SƠ TÀI KHOẢN</p><h1>{mode === 'login' ? 'Đăng nhập để tiếp tục' : 'Tạo tài khoản'}</h1><p className="page-subtitle">Quản lý thông tin sức khỏe và sở thích của bạn.</p></div></div>
      <div className="profile-access-card">
        {!configured ? <>
          <h2>Tài khoản hiện chưa khả dụng</h2>
          <p>Vui lòng thử lại sau.</p>
        </> : <>
          {mode === 'admin' ? <button className="profile-admin-back" type="button" onClick={() => changeMode('login')}>← Quay lại đăng nhập tài khoản</button> : <div className="profile-auth-tabs" role="tablist" aria-label="Tài khoản">
            <button type="button" role="tab" aria-selected={mode === 'login'} className={mode === 'login' ? 'active' : ''} onClick={() => changeMode('login')}>Đăng nhập</button>
            <button type="button" role="tab" aria-selected={mode === 'signup'} className={mode === 'signup' ? 'active' : ''} onClick={() => changeMode('signup')}>Đăng ký</button>
          </div>}
          <h2>{mode === 'admin' ? 'Đăng nhập quản trị viên' : mode === 'login' ? 'Đăng nhập tài khoản' : 'Tạo tài khoản mới'}</h2>
          <p>{mode === 'admin' ? 'Chỉ tài khoản đã được cấp quyền quản trị mới có thể tiếp tục.' : mode === 'login' ? 'Nhập thông tin tài khoản để mở hồ sơ đã lưu.' : 'Tạo tài khoản và đăng nhập ngay bằng email, không cần xác nhận email.'}</p>
          <form className="profile-login-form" onSubmit={submit}>
            {mode === 'signup' && <label className="form-control"><span>Họ và tên</span><input type="text" autoComplete="name" maxLength={120} required value={fullName} onChange={(event) => setFullName(event.target.value)} /></label>}
            <label className="form-control"><span>Email</span><input type="email" autoComplete="username" required value={email} onChange={(event) => setEmail(event.target.value)} /></label>
            <label className="form-control"><span>Mật khẩu</span><input type="password" autoComplete={mode === 'signup' ? 'new-password' : 'current-password'} minLength={8} required value={password} onChange={(event) => setPassword(event.target.value)} /><small>{mode === 'signup' ? 'Tối thiểu 8 ký tự.' : ''}</small></label>
            {mode === 'signup' && <label className="form-control"><span>Xác nhận mật khẩu</span><input type="password" autoComplete="new-password" minLength={8} required value={confirmPassword} onChange={(event) => setConfirmPassword(event.target.value)} /></label>}
            {error && <div className="wizard-error" role="alert">{error}</div>}
            {message && <div className="profile-auth-message" role="status">{message}</div>}
            <button className="button button-primary" type="submit" disabled={submitting}>{submitting ? 'Đang xử lý…' : mode === 'signup' ? 'Tạo tài khoản' : mode === 'admin' ? 'Đăng nhập quản trị' : 'Đăng nhập'}</button>
            {mode === 'login' && <button className="profile-admin-login-link" type="button" onClick={() => { setEmail('xuanhoai3152007@gmail.com'); changeMode('admin') }}>Đăng nhập dành cho quản trị viên</button>}
          </form>
        </>}
      </div>
    </section>
  )
}

function OnboardingPage({ user, onSignOut, onSaved }) {
  const [step, setStep] = useState(0)
  const [error, setError] = useState('')
  const [consent, setConsent] = useState(false)
  const [profile, setProfile] = useState(emptyProfile)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [saved, setSaved] = useState(false)
  const estimate = step === 4 ? getNutritionEstimate(profile) : null
  const steps = ['Về bạn', 'Mục tiêu', 'Sức khỏe', 'Ăn uống', 'Xác nhận']

  useEffect(() => {
    let active = true
    loadUserProfile(user.id)
      .then((storedProfile) => {
        if (!active) return
        if (storedProfile) {
          const { saved: hasSavedProfile, ...values } = storedProfile
          setProfile({ ...emptyProfile, ...values })
          setConsent(hasSavedProfile)
          setSaved(hasSavedProfile)
        }
        setLoading(false)
      })
      .catch((loadError) => {
        if (!active) return
        setError(`Không thể tải hồ sơ: ${loadError.message}`)
        setLoading(false)
      })
    return () => { active = false }
  }, [user.id])

  const updateProfile = (field, value) => {
    setProfile((current) => ({ ...current, [field]: value }))
    setSaved(false)
    setError('')
  }
  const toggleSelection = (field, value) => {
    setProfile((current) => ({
      ...current,
      [field]: current[field].includes(value) ? current[field].filter((item) => item !== value) : [...current[field], value],
    }))
    setSaved(false)
    setError('')
  }
  const validateStep = () => {
    if (step === 0) {
      const age = getAge(profile.birthDate)
      if (!profile.sex || !profile.birthDate || !profile.heightCm || !profile.weightKg) return 'Vui lòng hoàn tất giới tính, ngày sinh, chiều cao và cân nặng.'
      if (age === null || age < 0 || age > 120) return 'Ngày sinh không hợp lệ.'
      if (Number(profile.heightCm) < 100 || Number(profile.heightCm) > 250) return 'Chiều cao cần nằm trong khoảng 100–250 cm.'
      if (Number(profile.weightKg) < 25 || Number(profile.weightKg) > 300) return 'Cân nặng cần nằm trong khoảng 25–300 kg.'
    }
    if (step === 1) {
      if (!profile.goal || !profile.activity) return 'Vui lòng chọn mục tiêu và mức vận động.'
      if (profile.goal === 'lose') {
        const age = getAge(profile.birthDate)
        const bmi = getBodyMassIndex(profile.weightKg, profile.heightCm)
        const targetWeight = Number(profile.targetWeightKg)
        if (age < 18) return 'Không thiết lập mục tiêu giảm cân tự động cho người dưới 18 tuổi. Hãy chọn mục tiêu khác và trao đổi với chuyên gia.'
        if (bmi < 18.5) return 'BMI hiện tại dưới 18,5 nên không thể chọn mục tiêu giảm cân tự động.'
        if (!profile.targetWeightKg || targetWeight <= 0) return 'Vui lòng nhập cân nặng mục tiêu để kiểm tra an toàn.'
        if (getBodyMassIndex(targetWeight, profile.heightCm) < 18.5) return 'Cân nặng mục tiêu sẽ làm BMI thấp hơn 18,5. Hãy điều chỉnh mục tiêu hoặc chọn mục tiêu khác.'
        if (targetWeight >= Number(profile.weightKg)) return 'Cân nặng mục tiêu cần thấp hơn cân nặng hiện tại khi chọn giảm cân.'
      }
    }
    if (step === 4 && !consent) return 'Vui lòng xác nhận đồng ý lưu thông tin sức khỏe trước khi tiếp tục.'
    return ''
  }
  const goNext = () => {
    const message = validateStep()
    if (message) {
      setError(message)
      return
    }
    setError('')
    setStep((current) => Math.min(4, current + 1))
  }
  const goBack = () => {
    setError('')
    setStep((current) => Math.max(0, current - 1))
  }
  const persistProfile = async () => {
    const message = validateStep()
    if (message) {
      setError(message)
      return
    }
    setSaving(true)
    setError('')
    try {
      await saveUserProfile(profile)
      setSaved(true)
      onSaved()
    } catch (saveError) {
      setError(`Không thể lưu hồ sơ: ${saveError.message}`)
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return <section className="onboarding-page"><div className="profile-access-card" role="status">Đang tải hồ sơ…</div></section>
  }

  return (
    <section className="onboarding-page">
      <div className="onboarding-heading">
        <div><p className="eyebrow">HỒ SƠ SỨC KHỎE</p><h1>Hồ sơ của bạn</h1><p className="page-subtitle">Tài khoản: {user.email ?? user.id}</p></div>
        <span className="step-count">Bước {step + 1} / 5</span>
      </div>
      <div className="profile-account-bar"><span>{saved ? 'Hồ sơ đã được lưu.' : 'Các thay đổi chưa được lưu.'}</span><button className="text-button" type="button" onClick={onSignOut}>Đăng xuất</button></div>
      <div className="wizard-progress" aria-label={`Tiến độ ${step + 1} trên 5 bước`}><span style={{ width: `${((step + 1) / 5) * 100}%` }} /></div>
      <div className="wizard-step-labels">{steps.map((label, index) => <span className={index <= step ? 'current' : ''} key={label}>{label}</span>)}</div>
      <div className="wizard-card">
        {step === 0 && <div className="wizard-panel">
          <div className="wizard-section-heading"><span className="wizard-step-number">01</span><div><h2>Về bạn</h2><p>Nhập thông tin cơ bản để tính toán các chỉ số.</p></div></div>
          <fieldset className="form-fieldset"><legend>Giới tính dùng trong công thức Mifflin–St Jeor</legend><div className="choice-grid two-column">
            {[['female', 'Nữ'], ['male', 'Nam']].map(([value, label]) => <button className={`choice-card compact-choice ${profile.sex === value ? 'selected' : ''}`} key={value} type="button" aria-pressed={profile.sex === value} onClick={() => updateProfile('sex', value)}><span className="choice-radio" />{label}</button>)}
          </div></fieldset>
          <div className="form-grid two-column">
            <label className="form-control"><span>Ngày sinh</span><input type="date" max={maxBirthDate} value={profile.birthDate} onChange={(event) => updateProfile('birthDate', event.target.value)} /></label>
            <label className="form-control"><span>Chiều cao <small>cm</small></span><input type="number" min="100" max="250" step="0.1" inputMode="decimal" placeholder="Ví dụ: 165" value={profile.heightCm} onChange={(event) => updateProfile('heightCm', event.target.value)} /></label>
            <label className="form-control"><span>Cân nặng hiện tại <small>kg</small></span><input type="number" min="25" max="300" step="0.1" inputMode="decimal" placeholder="Ví dụ: 60" value={profile.weightKg} onChange={(event) => updateProfile('weightKg', event.target.value)} /></label>
          </div>
        </div>}

        {step === 1 && <div className="wizard-panel">
          <div className="wizard-section-heading"><span className="wizard-step-number">02</span><div><h2>Mục tiêu & mức vận động</h2><p>Chọn mục tiêu muốn tìm hiểu; đây không phải chỉ định về cân nặng.</p></div></div>
          <fieldset className="form-fieldset"><legend>Mục tiêu tham khảo</legend><div className="choice-grid">
            {goals.map((goal) => <button className={`choice-card ${profile.goal === goal.value ? 'selected' : ''}`} key={goal.value} type="button" aria-pressed={profile.goal === goal.value} onClick={() => updateProfile('goal', goal.value)}><span className="choice-radio" /><span className="choice-copy"><strong>{goal.label}</strong><small>{goal.detail}</small></span></button>)}
          </div></fieldset>
          {profile.goal === 'lose' && <label className="form-control target-weight-control"><span>Cân nặng mục tiêu <small>kg</small></span><input type="number" min="25" max="300" step="0.1" inputMode="decimal" placeholder="Ví dụ: 58" value={profile.targetWeightKg} onChange={(event) => updateProfile('targetWeightKg', event.target.value)} /><small>Mục tiêu tạo ra BMI dưới 18,5 sẽ không được chấp nhận.</small></label>}
          <fieldset className="form-fieldset activity-fieldset"><legend>Mức vận động thường ngày</legend><div className="activity-grid">{activityOptions.map((option) => <button className={`activity-option ${profile.activity === option.value ? 'selected' : ''}`} key={option.value} type="button" aria-pressed={profile.activity === option.value} onClick={() => updateProfile('activity', option.value)}><span className="choice-radio" /><span><strong>{option.label}</strong><small>{option.detail}</small></span></button>)}</div></fieldset>
        </div>}

        {step === 2 && <div className="wizard-panel">
          <div className="wizard-section-heading"><span className="wizard-step-number">03</span><div><h2>Tình trạng sức khỏe</h2><p>Chọn các tình trạng sức khỏe phù hợp với bạn.</p></div></div>
          <div className="health-choice-grid">{healthOptions.map((option) => <label className={`health-choice ${profile.conditions.includes(option.value) ? 'checked' : ''} ${option.red ? 'red-choice' : ''}`} key={option.value}><input type="checkbox" checked={profile.conditions.includes(option.value)} onChange={() => toggleSelection('conditions', option.value)} /><span className="custom-check"><Icon name="check" size={14} /></span><span>{option.label}</span></label>)}</div>
          {profile.conditions.some((condition) => redHealthConditions.has(condition)) && <div className="safety-alert red-alert"><strong>Cần lưu ý an toàn</strong><span>Với các tình trạng được chọn, NutriCook không tạo mục tiêu hoặc thực đơn tự động. Hãy trao đổi với bác sĩ/chuyên gia dinh dưỡng.</span></div>}
        </div>}

        {step === 3 && <div className="wizard-panel">
          <div className="wizard-section-heading"><span className="wizard-step-number">04</span><div><h2>Ăn uống & sở thích</h2><p>Chọn chế độ ăn, dị ứng và sở thích của bạn.</p></div></div>
          <fieldset className="form-fieldset"><legend>Chế độ ăn muốn tham khảo</legend><div className="diet-grid">{dietOptions.map((diet) => <button className={`diet-option ${profile.diet === diet.value ? 'selected' : ''}`} type="button" key={diet.value} aria-pressed={profile.diet === diet.value} onClick={() => updateProfile('diet', diet.value)}><span className="choice-radio" />{diet.label}</button>)}</div></fieldset>
          {profile.diet === 'keto' && <div className="safety-alert"><strong>Keto cần thận trọng</strong><span>Không áp dụng lựa chọn này cùng tình trạng tiểu đường hoặc bệnh thận. Chế độ ăn cần được chuyên gia thẩm định trước khi dùng.</span></div>}
          <fieldset className="form-fieldset allergy-fieldset"><legend>Dị ứng / không dung nạp (tùy chọn)</legend><div className="allergy-grid">{allergenOptions.map((allergen) => <label className={`allergy-chip ${profile.allergies.includes(allergen) ? 'selected' : ''}`} key={allergen}><input type="checkbox" checked={profile.allergies.includes(allergen)} onChange={() => toggleSelection('allergies', allergen)} /><span className="choice-radio" />{allergen}</label>)}</div></fieldset>
          <label className="form-control disliked-control"><span>Nguyên liệu bạn không thích <small>tùy chọn</small></span><input type="text" placeholder="Ví dụ: hành, rau mùi" value={profile.dislikedIngredients} onChange={(event) => updateProfile('dislikedIngredients', event.target.value)} /></label>
          <div className="form-grid three-column preference-fields">
            <label className="form-control"><span>Thời gian nấu tối đa</span><select value={profile.cookingTime} onChange={(event) => updateProfile('cookingTime', event.target.value)}><option value="15">15 phút</option><option value="30">30 phút</option><option value="45">45 phút</option><option value="60">Trên 45 phút</option></select></label>
            <label className="form-control"><span>Ngân sách mỗi bữa</span><select value={profile.budget} onChange={(event) => updateProfile('budget', event.target.value)}><option value="low">Tiết kiệm</option><option value="medium">Vừa phải</option><option value="high">Linh hoạt</option></select></label>
            <label className="form-control"><span>Kinh nghiệm nấu ăn</span><select value={profile.cookingSkill} onChange={(event) => updateProfile('cookingSkill', event.target.value)}><option value="beginner">Mới bắt đầu</option><option value="intermediate">Cơ bản</option><option value="advanced">Thành thạo</option></select></label>
          </div>
          {profile.conditions.includes('diabetes') && profile.diet === 'keto' && <div className="safety-alert red-alert"><strong>Không thể dùng lựa chọn kết hợp này</strong><span>Keto không được áp dụng khi đã đánh dấu tiểu đường. Hãy chọn chế độ ăn khác hoặc bỏ qua phép tính tự động.</span></div>}
        </div>}

        {step === 4 && <div className="wizard-panel results-panel">
          <div className="wizard-section-heading"><span className="wizard-step-number">05</span><div><h2>Kết quả ước tính</h2><p>Các chỉ số được tính dựa trên thông tin bạn đã nhập.</p></div></div>
          <div className="profile-summary-strip"><span>{profile.sex === 'female' ? 'Nữ' : 'Nam'} · {estimate.age} tuổi</span><span>{profile.heightCm} cm · {profile.weightKg} kg</span><span>BMI {estimate.bmi.toFixed(1)}</span></div>
          {estimate.safetyReasons.length > 0 ? <div className="safety-alert red-alert result-safety"><strong>Không tạo mục tiêu tự động</strong><ul>{estimate.safetyReasons.map((reason) => <li key={reason}>{reason}</li>)}</ul><span>Hãy trao đổi với bác sĩ hoặc chuyên gia dinh dưỡng.</span></div> : <>
            <div className="estimate-grid">
              <div className="estimate-card"><span>BMR ước tính</span><strong>{Math.round(estimate.targets.bmr).toLocaleString('vi-VN')} <small>kcal/ngày</small></strong><small>Năng lượng nghỉ ngơi theo công thức Mifflin–St Jeor</small></div>
              <div className="estimate-card"><span>TDEE ước tính</span><strong>{Math.round(estimate.targets.tdee).toLocaleString('vi-VN')} <small>kcal/ngày</small></strong><small>BMR × hệ số vận động {activityOptions.find((item) => item.value === profile.activity).multiplier}</small></div>
              <div className="estimate-card highlighted"><span>Mức tham khảo theo lựa chọn</span><strong>{estimate.targets.kcal.toLocaleString('vi-VN')} <small>kcal/ngày</small></strong><small>{goals.find((item) => item.value === profile.goal).label} · chưa cá nhân hóa theo bệnh lý</small></div>
            </div>
            <div className="macro-result-card"><div className="macro-result-heading"><div><strong>Phân bổ macro tham khảo</strong><span>{dietOptions.find((item) => item.value === profile.diet).label} · tỷ lệ P/C/F theo tài liệu</span></div><span className="macro-percentages">{estimate.targets.split.protein}/{estimate.targets.split.carb}/{estimate.targets.split.fat}%</span></div><div className="macro-bars"><span className="protein-bar" style={{ width: `${estimate.targets.split.protein}%` }} /><span className="carb-bar" style={{ width: `${estimate.targets.split.carb}%` }} /><span className="fat-bar" style={{ width: `${estimate.targets.split.fat}%` }} /></div><div className="macro-result-values"><span><i className="macro-dot protein-dot" />Đạm <strong>{estimate.targets.proteinG}g</strong></span><span><i className="macro-dot carb-dot" />Tinh bột <strong>{estimate.targets.carbG}g</strong></span><span><i className="macro-dot fat-dot" />Chất béo <strong>{estimate.targets.fatG}g</strong></span></div></div>
            <div className="secondary-targets"><span>Chất xơ tham khảo <strong>{estimate.targets.fiberG}g/ngày</strong></span><span>Natri tham khảo <strong>≤ {estimate.targets.sodiumMg.toLocaleString('vi-VN')}mg/ngày</strong></span><span>Đường tự do tham khảo <strong>&lt; {estimate.targets.maxSugarG}g/ngày</strong></span></div>
            {profile.conditions.length > 0 && <div className="safety-alert"><strong>Điều kiện sức khỏe chưa được áp dụng</strong><span>Các phép tính trên không kết hợp quy tắc bệnh lý hoặc hồ sơ đã được chuyên gia phê duyệt. Hãy hỏi bác sĩ/chuyên gia trước khi thay đổi chế độ ăn.</span></div>}
          </>}
          <details className="formula-details"><summary>Cách tính và giả định</summary><p>BMR nữ = 10 × cân nặng + 6,25 × chiều cao − 5 × tuổi − 161. BMR nam dùng +5 thay cho −161. TDEE = BMR × hệ số vận động; giảm cân −250, tăng cân +250, tăng cơ +350 kcal trong bản minh họa.</p><p>Macro được quy đổi theo 4 kcal/g đạm, 4 kcal/g tinh bột và 9 kcal/g chất béo. Các giá trị được làm tròn để hiển thị.</p></details>
          <label className="consent-check"><input type="checkbox" checked={consent} onChange={(event) => { setConsent(event.target.checked); setSaved(false); setError('') }} /><span className="custom-check"><Icon name="check" size={14} /></span><span>Tôi đồng ý lưu thông tin sức khỏe, dị ứng và sở thích vào hồ sơ tài khoản để sử dụng lại.</span></label>
          {saved && <div className="profile-saved-message" role="status">Hồ sơ đã được lưu thành công.</div>}
        </div>}
        {error && <div className="wizard-error" role="alert">{error}</div>}
        <div className="wizard-actions">{step > 0 ? <button className="button button-secondary" type="button" onClick={goBack}>Quay lại</button> : <span className="wizard-action-spacer" />}{step < 4 ? <button className="button button-primary" type="button" onClick={goNext}>Tiếp tục <Icon name="arrow" size={16} /></button> : <button className="button button-primary" type="button" disabled={!consent || saving} onClick={persistProfile}>{saving ? 'Đang lưu…' : saved ? 'Lưu thay đổi' : 'Lưu hồ sơ'} <Icon name="check" size={16} /></button>}</div>
      </div>
    </section>
  )
}

function AccountProfilePage({ auth, configured, onSignOut, onSaved, onAdminLogin }) {
  if (auth.loading) {
    return <section className="onboarding-page"><div className="profile-access-card" role="status">Đang kiểm tra đăng nhập…</div></section>
  }
  if (!auth.session) {
    return <ProfileLoginPage configured={configured} authError={auth.error} onAdminLogin={onAdminLogin} />
  }
  return <OnboardingPage key={auth.session.user.id} user={auth.session.user} onSignOut={onSignOut} onSaved={onSaved} />
}

function App() {
  const configured = isSupabaseConfigured()
  const [auth, setAuth] = useState(() => ({ loading: configured, session: null, error: '' }))
  const [roleState, setRoleState] = useState({ loading: false, role: '' })
  const [databaseRecipes, setDatabaseRecipes] = useState([])
  const [recipeLoadError, setRecipeLoadError] = useState('')
  const [page, setPage] = useState('dashboard')
  const [favorites, setFavorites, favoritesStorageError] = usePersistentState('favorites', [], isFavoriteList)
  const [groceries, setGroceries, groceriesStorageError] = usePersistentState('groceries', initialGroceries, isGroceryList)
  const [mealRotation, setMealRotation] = usePersistentState('meal-rotation', {}, isMealRotation)
  const [eatenMeals, setEatenMeals, eatenMealsStorageError] = usePersistentState('eaten-meals', [], isEatenMealList)
  const [selectedRecipe, setSelectedRecipe] = useState(null)
  const [servings, setServings] = useState(2)
  const [toast, setToast] = useState('')
  const hasStorageError = favoritesStorageError || groceriesStorageError || eatenMealsStorageError

  const refreshDatabaseRecipes = useCallback(async () => {
    if (!configured) return
    try {
      setDatabaseRecipes(await getPublishedRecipes())
      setRecipeLoadError('')
    } catch (error) {
      console.error('Could not load published NutriCook recipes.', error)
      setRecipeLoadError('Không thể tải một số công thức mới. Hãy thử tải lại trang.')
    }
  }, [configured])

  useEffect(() => {
    if (!configured) return undefined

    const client = getSupabaseClient()
    let active = true
    const { data: { subscription } } = client.auth.onAuthStateChange((_event, session) => {
      setAuth({ loading: false, session, error: '' })
    })
    client.auth.getSession()
      .then(({ data, error }) => {
        if (!active) return
        if (error) throw error
        setAuth({ loading: false, session: data.session, error: '' })
      })
      .catch((error) => {
        if (active) setAuth({ loading: false, session: null, error: error.message })
      })
    return () => {
      active = false
      subscription.unsubscribe()
    }
  }, [configured])

  useEffect(() => {
    const userId = auth.session?.user.id
    if (!configured || !userId) return undefined

    let active = true
    Promise.resolve().then(() => getSupabaseClient().from('profiles').select('role').eq('id', userId).single())
      .then(({ data, error }) => {
        if (error) throw error
        if (active) setRoleState({ userId, role: data.role })
      })
      .catch((error) => {
        console.error('Could not load the signed-in user role.', error)
        if (active) setRoleState({ userId, role: '' })
      })

    return () => { active = false }
  }, [auth.session?.user.id, configured])

  useEffect(() => {
    if (!configured) return undefined
    const timer = window.setTimeout(() => { refreshDatabaseRecipes() }, 0)
    return () => window.clearTimeout(timer)
  }, [configured, refreshDatabaseRecipes])

  const notify = (message) => {
    setToast(message)
    window.setTimeout(() => setToast(''), 2800)
  }
  const openRecipe = (recipe) => {
    setSelectedRecipe(recipe)
    setServings(2)
  }
  const handleSignOut = async () => {
    try {
      await signOut()
      notify('Đã đăng xuất tài khoản.')
    } catch (error) {
      notify(`Không thể đăng xuất: ${error.message}`)
    }
  }
  const toggleFavorite = (id) => setFavorites((current) => current.includes(id) ? current.filter((item) => item !== id) : [...current, id])
  const addDayToList = (dayRecipes) => {
    const ingredients = dayRecipes.reduce((currentItems, recipe) => {
      const detail = getRecipeDetail(recipe.id)
      return detail ? addRecipeIngredientsToShoppingList(currentItems, detail.ingredients, 2, recipe.id, recipe.baseServings ?? 2, recipe.title) : currentItems
    }, groceries)
    setGroceries(ingredients)
    setPage('shopping-list')
    notify(`Đã gom nguyên liệu cho ${dayRecipes.length} món trong ngày.`)
  }
  const addRecipeToList = (recipe, recipeServings) => {
    const detail = recipe.detail ?? getRecipeDetail(recipe.id)
    if (!detail) {
      notify('Không tìm thấy dữ liệu nguyên liệu cho công thức này.')
      return
    }
    setGroceries((items) => addRecipeIngredientsToShoppingList(items, detail.ingredients, recipeServings, recipe.id, recipe.baseServings ?? 2, recipe.title))
    setSelectedRecipe(null)
    setPage('shopping-list')
    notify(`Đã thêm ${detail.ingredients.length} nguyên liệu từ “${recipe.title}”.`)
  }
  const isCurrentAdmin = roleState.userId === auth.session?.user.id && roleState.role === 'admin'
  const visibleNavigation = isCurrentAdmin ? [...navigation, adminNavigation] : navigation
  const visibleRecipes = [...recipes, ...databaseRecipes.filter((dbRecipe) => !recipes.some((recipe) => normalizeText(recipe.title) === normalizeText(dbRecipe.title)))]
  const activePage = visibleNavigation.find((item) => item.id === page)
  const pageTitle = activePage?.label ?? (page === 'onboarding' ? 'Hồ sơ & mục tiêu' : 'Tổng quan')

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <button className="brand-lockup" type="button" onClick={() => setPage('dashboard')} aria-label="NutriCook, về tổng quan"><span className="brand-mark"><Icon name="leaf" size={23} /></span><span><strong>NutriCook</strong><small>Ăn ngon, sống khỏe</small></span></button>
        <div className="sidebar-label">MENU</div>
        <nav className="primary-nav" aria-label="Điều hướng chính">{visibleNavigation.map((item) => <button className={`nav-item ${page === item.id ? 'active' : ''}`} key={item.id} onClick={() => setPage(item.id)}><Icon name={item.icon} size={19} /><span>{item.label}</span></button>)}</nav>
        <div className="sidebar-bottom"><div className="help-card"><span className="help-illustration">🥬</span><strong>Bữa ăn tốt bắt đầu từ đây</strong><p>Khám phá công thức mới mỗi ngày.</p><button onClick={() => setPage('recipes')}>Khám phá ngay <Icon name="arrow" size={14} /></button></div><button className={`profile-button ${page === 'onboarding' ? 'profile-current' : ''}`} onClick={() => setPage('onboarding')}><span className="avatar"><Icon name="user" size={18} /></span><span><strong>Hồ sơ sức khỏe</strong><small>Lưu vào tài khoản</small></span><Icon name="chevron" size={16} /></button></div>
      </aside>

      <div className="main-column">
        <header className="topbar"><div className="breadcrumb"><span>NutriCook</span><Icon name="chevron" size={15} /><strong>{pageTitle}</strong></div><div className="topbar-actions"><button className="icon-button notification-button" aria-label="Thông báo"><Icon name="bell" size={19} /><i /></button><button className={`header-profile ${page === 'onboarding' ? 'active' : ''}`} onClick={() => setPage('onboarding')} aria-label="Mở hồ sơ sức khỏe"><Icon name="user" size={17} /><span>Hồ sơ</span></button></div></header>
        {hasStorageError && <div className="storage-warning" role="status">Trình duyệt không cho phép lưu dữ liệu. Hãy bật quyền lưu trữ trang web hoặc dùng cửa sổ trình duyệt thông thường.</div>}
        {recipeLoadError && <div className="storage-warning" role="status">{recipeLoadError}</div>}
        <main className="main-content">
          {page === 'dashboard' && <Dashboard setPage={setPage} onOpenRecipe={openRecipe} favorites={favorites} onFavorite={toggleFavorite} />}
          {page === 'recipes' && <RecipesPage recipes={visibleRecipes} favorites={favorites} onFavorite={toggleFavorite} onOpenRecipe={openRecipe} />}
          {page === 'meal-plan' && <MealPlanPage onOpenRecipe={openRecipe} onAddDayToList={addDayToList} mealRotation={mealRotation} setMealRotation={setMealRotation} eatenMeals={eatenMeals} setEatenMeals={setEatenMeals} />}
          {page === 'statistics' && <MealStatisticsPage eatenMeals={eatenMeals} auth={auth} configured={configured} setPage={setPage} />}
          {page === 'shopping-list' && <ShoppingListPage groceries={groceries} setGroceries={setGroceries} />}
          {page === 'onboarding' && <AccountProfilePage auth={auth} configured={configured} onSignOut={handleSignOut} onSaved={() => notify('Hồ sơ sức khỏe đã được lưu.')} onAdminLogin={(userId) => { setRoleState({ userId, role: 'admin' }); setPage('admin') }} />}
          {page === 'admin' && <AdminPage user={auth.session?.user} isAdmin={isCurrentAdmin} onRecipePublished={refreshDatabaseRecipes} />}
          <footer className="app-footer"><span>© 2026 NutriCook</span></footer>
        </main>
      </div>

      <nav className={`mobile-nav ${isCurrentAdmin ? 'mobile-nav-admin' : ''}`} aria-label="Điều hướng di động">{visibleNavigation.map((item) => <button className={page === item.id ? 'active' : ''} key={item.id} onClick={() => setPage(item.id)}><Icon name={item.icon} size={20} /><span>{item.label === 'Giá đi chợ dự kiến' ? 'Giá đi chợ' : item.label === 'Thực đơn tuần' ? 'Thực đơn' : item.label === 'Tổng quan' ? 'Trang chủ' : item.label}</span></button>)}</nav>
      <RecipeDialog key={selectedRecipe?.id ?? 'recipe-dialog'} recipe={selectedRecipe} servings={servings} setServings={setServings} onClose={() => setSelectedRecipe(null)} onAdd={addRecipeToList} />
      {toast && <div className="toast" role="status"><Icon name="check" size={17} />{toast}</div>}
    </div>
  )
}

export default App
