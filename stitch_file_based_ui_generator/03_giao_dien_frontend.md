# 03 — GIAO DIỆN (UI/UX) & FRONTEND
## Dự án: NutriCook

> Đọc cùng: `01_PRD_NGHIEP_VU.md`, `02_KY_THUAT.md`. Stack: React 18 + Vite + TypeScript + Tailwind + shadcn/ui + TanStack Query + Zustand.

---

## PHẦN A — THIẾT KẾ GIAO DIỆN

### A1. Nguyên tắc thiết kế
1. **Tươi – sạch – đáng tin**: màu xanh lá/cam ấm, ảnh món ăn lớn, nhiều khoảng trắng.
2. **An toàn trước tiên**: cảnh báo dị ứng/bệnh lý luôn nổi bật, không bao giờ ẩn trong menu.
3. **Ít thao tác**: từ công thức → giỏ hàng tối đa 2 chạm.
4. **Mobile-first**: 70% người dùng dự kiến dùng điện thoại; thao tác bằng một tay.
5. **Dễ đọc cho người lớn tuổi**: cỡ chữ gốc 16px, có tùy chọn "Chữ lớn" (18–20px), nút ≥ 44×44px.
6. **Không dùng màu làm tín hiệu duy nhất**: kèm icon + chữ (xanh ✓ / vàng ⚠ / đỏ ⛔).

### A2. Design tokens (Tailwind)

```ts
// tailwind.config.ts (trích)
export default {
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        brand:   { 50:'#F0FBF4',100:'#DCF5E5',200:'#B9EACB',300:'#86D8A9',400:'#4FBF84',500:'#27A468',600:'#1B8553',700:'#176A44',800:'#155439',900:'#124630' },
        accent:  { 50:'#FFF6ED',100:'#FFE9D3',300:'#FFB877',500:'#F58A2B',600:'#DC6D12' },   // cam ấm: CTA phụ, đặt hàng
        ink:     { 900:'#14201A',700:'#34443B',500:'#5E6F65',300:'#A5B3AA',100:'#E6ECE8' },
        surface: { DEFAULT:'#FFFFFF', muted:'#F7FAF8', sunken:'#EEF3F0' },
        ok:      { bg:'#E8F7EE', fg:'#15703F' },
        warn:    { bg:'#FFF4D6', fg:'#8A5A00' },
        danger:  { bg:'#FDE8E8', fg:'#A11A1A' },
        macro:   { protein:'#3B82F6', carb:'#F59E0B', fat:'#EC4899', fiber:'#10B981' },
      },
      fontFamily: { sans:['"Be Vietnam Pro"','Inter','system-ui','sans-serif'], display:['"Be Vietnam Pro"','sans-serif'] },
      borderRadius: { xl:'14px', '2xl':'20px' },
      boxShadow: { card:'0 1px 2px rgba(20,32,26,.06), 0 4px 16px rgba(20,32,26,.06)' },
    },
  },
};
```
- Font **Be Vietnam Pro** (hỗ trợ tiếng Việt tốt), `font-display: swap`, tải 400/500/600/700.
- Spacing theo lưới **4px**; bo góc thẻ `rounded-2xl`; ảnh món tỉ lệ **4:3**.
- Breakpoints: `sm 640 · md 768 · lg 1024 · xl 1280`.
- Dark mode: tùy chọn (P1), dùng biến CSS.

### A3. Thành phần giao diện chung (UI kit)
| Component | Biến thể / Ghi chú |
|---|---|
| `Button` | primary (brand), secondary (outline), accent (cam – "Đặt hàng"), ghost, destructive; trạng thái loading |
| `Input/Select/Textarea/Checkbox/Radio/Switch/Slider` | Nhãn luôn hiển thị, lỗi dưới ô, `aria-describedby` |
| `Chip/Badge` | Nhãn chế độ ăn, bệnh lý, `VerdictBadge` (Phù hợp/Lưu ý/Không nên) |
| `RecipeCard` | Ảnh, tiêu đề, thời gian, kcal, 3 macro, nút ♥, `VerdictBadge` |
| `NutritionFacts` | Bảng dinh dưỡng/khẩu phần + % mục tiêu ngày, thanh tiến trình |
| `MacroRing` | Vòng donut P/C/F + số kcal giữa |
| `ServingsStepper` | − / + (1–12), cập nhật tức thì |
| `IngredientList` | Checkbox "đã có", số lượng scale, nút "Thay thế" |
| `StepList` | Số bước, hẹn giờ |
| `ProductCard` | Ảnh, giá, đơn vị, stepper số lượng, tình trạng kho |
| `CartDrawer` | Danh sách, tổng, nút "Thanh toán" |
| `OrderTimeline` | Các mốc trạng thái đơn |
| `AllergyAlert` | Banner đỏ khi chạm tới chất dị ứng |
| `MedicalDisclaimer` | Khối chữ nhỏ bắt buộc |
| `EmptyState/Skeleton/Toast/Dialog/Sheet/Tabs/Breadcrumb/Pagination` | Dùng shadcn/ui |
| `DataTable` (admin) | Sắp xếp, lọc, phân trang server-side |

### A4. Sitemap

```
PUBLIC
/                       Trang chủ (marketing hoặc dashboard nếu đã đăng nhập)
/recipes                Thư viện công thức (tìm kiếm + lọc)
/recipes/:slug          Chi tiết công thức
/shop                   Cửa hàng nguyên liệu
/shop/:slug             Chi tiết sản phẩm
/about/method           Nguồn & Phương pháp (công thức tính, tài liệu tham khảo)
/legal/terms | privacy | returns | shipping
/login  /register  /forgot-password  /reset-password  /auth/callback

CUSTOMER (đăng nhập)
/onboarding             Wizard hồ sơ sức khỏe (5 bước)
/dashboard              Tổng quan: kcal hôm nay, thực đơn, gợi ý
/for-you                Gợi ý theo hồ sơ
/meal-plan              Thực đơn tuần (lịch)
/meal-plan/:id
/shopping-list          Danh sách mua sắm
/favorites              Công thức yêu thích
/journal                Nhật ký ăn uống & cân nặng (P1)
/cart  /checkout        Giỏ hàng & thanh toán
/orders  /orders/:id    Lịch sử & chi tiết đơn
/account                Hồ sơ, sức khỏe, địa chỉ, bảo mật, quyền riêng tư (xuất/xóa dữ liệu)

ADMIN / STAFF / NUTRITIONIST
/admin                  Dashboard
/admin/recipes (+/new, /:id)   CRUD + quy trình duyệt
/admin/ingredients      CRUD nguyên liệu
/admin/products         Sản phẩm & kho
/admin/orders (+/:id)   Xử lý đơn
/admin/users            Người dùng & quyền
/admin/rules            Quy tắc bệnh lý (versioning)
```

### A5. Wireframe các màn hình chính (ASCII)

**A5.1 Đăng nhập / Đăng ký**
```
┌─────────────────────────────┐
│         🥗 NutriCook         │
│   Ăn đúng – Sống khỏe        │
│ ┌─────────────────────────┐ │
│ │ Email                   │ │
│ │ Mật khẩu          👁    │ │
│ └─────────────────────────┘ │
│ [        Đăng nhập        ] │
│ Quên mật khẩu?              │
│ ───────── hoặc ───────────  │
│ [ G  Tiếp tục với Google ]  │
│ Chưa có tài khoản? Đăng ký  │
└─────────────────────────────┘
```

**A5.2 Onboarding (5 bước, thanh tiến trình)**
```
Bước 1/5  Về bạn           → Giới tính · Ngày sinh · Chiều cao · Cân nặng
Bước 2/5  Mục tiêu         → ○Giảm cân ○Duy trì ○Tăng cân ○Tăng cơ ○Ăn lành mạnh
                             Cân nặng mục tiêu · Mức vận động (5 thẻ có mô tả)
Bước 3/5  Sức khỏe         → ☐Tiểu đường ☐Huyết áp ☐Mỡ máu ☐Gout ☐Thận ☐Dạ dày ☐Thiếu máu ☐Mang thai
                             ⚠ Nếu chọn nhóm đỏ: hộp cảnh báo + chỉ xem nội dung chung
Bước 4/5  Ăn uống          → Dị ứng (chip) · Chế độ ăn · Không thích · Thời gian nấu · Ngân sách
Bước 5/5  Xác nhận         → Kết quả: BMI, kcal/ngày, macro (donut), natri/đường tối đa
                             ☑ Tôi đồng ý xử lý dữ liệu sức khỏe  (bắt buộc)
                             MedicalDisclaimer            [ Bắt đầu ]
```

**A5.3 Dashboard (customer)**
```
┌ Xin chào, Lan 👋                              [🛒2] [Avatar] ┐
│ ┌── Mục tiêu hôm nay ───────┐ ┌── Bữa tiếp theo ──────────┐ │
│ │  (MacroRing) 1.480/1.650  │ │ [ảnh] Cá hồi áp chảo…     │ │
│ │  P 78g  C 160g  F 42g     │ │ 520 kcal · 25′  [Xem]     │ │
│ └───────────────────────────┘ └───────────────────────────┘ │
│ Gợi ý cho bạn ──────────────────────────────  Xem tất cả → │
│ [RecipeCard][RecipeCard][RecipeCard] →                      │
│ Thực đơn tuần này  [Tạo thực đơn tuần]  → Danh sách mua sắm │
└──────────────────────────────────────────────────────────────┘
```

**A5.3 Thư viện công thức**
```
[🔎 Tìm món, nguyên liệu…]            [Bộ lọc ▾] [Sắp xếp ▾]
Chip: Sáng | Trưa | Tối | Phụ | ≤30′ | Ít natri | Giàu đạm | Chay
Bật "Chỉ hiện món phù hợp với tôi" (mặc định BẬT khi đã có hồ sơ)
┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│ ảnh    │ │ ảnh    │ │ ảnh    │ │ ảnh    │
│ Tên    │ │ Tên    │ │ Tên    │ │ Tên    │
│ 25′ 420kcal ♥ │ ...    ✓Phù hợp  ⚠Lưu ý
└────────┘ └────────┘ └────────┘ └────────┘
                 [ Tải thêm ]
```

**A5.4 Chi tiết công thức**
```
[ảnh lớn]   Canh bí đỏ nấu tôm                     ♥  ⤴ Chia sẻ
✓ Phù hợp với bạn — Ít natri · Giàu chất xơ     (Vì sao?)
⚠/⛔ Banner cảnh báo nếu có (dị ứng/bệnh lý)
⏱ 25′ · 👤 Khẩu phần: [−] 2 [+] · Độ khó: Dễ
┌ Dinh dưỡng / khẩu phần ──────────────────────────────┐
│ 320 kcal | Đạm 22g | Carb 30g | Béo 8g | Natri 410mg │
│ % mục tiêu bữa: ▓▓▓▓▓░░ …   (MacroRing)             │
└──────────────────────────────────────────────────────┘
Tabs: [Nguyên liệu] [Cách làm] [Dinh dưỡng chi tiết] [Đánh giá]
Nguyên liệu (scale theo khẩu phần)  ☐ đã có  [Thay thế]
  • Tôm 200 g       • Bí đỏ 300 g       • Hành 10 g …
[ 🛒 Thêm nguyên liệu vào giỏ ]   [ + Thêm vào thực đơn ]   [ Chế độ nấu ]
MedicalDisclaimer
```

**A5.5 Thực đơn tuần**
```
Tuần 20–26/10   [◀][▶]   [Tạo lại] [Lưu]       Mục tiêu: 1.650 kcal
        T2     T3     T4     T5     T6     T7     CN
Sáng  [Card] [Card] [Card] …   (kéo-thả, ghim 📌, đổi 🔄)
Trưa  [Card] …
Tối   [Card] …
Phụ   [Card] …
Σ     1.640  1.670  1.625 …   ← thanh so sánh với mục tiêu (xanh ±5%, vàng, đỏ)
Cột phải/Drawer: Tổng hợp tuần (macro, natri, chất xơ)  [Tạo danh sách mua sắm →]
```

**A5.6 Danh sách mua sắm → Giỏ hàng**
```
Nhóm: Rau củ | Thịt cá | Gia vị | Ngũ cốc
☐ Bí đỏ — cần 900 g → Sản phẩm: Bí đỏ 500g × 2   45.000đ  [−2+] 
☑ Đã có ở nhà (gạch ngang)
Tổng tạm tính: 385.000đ
[ Thêm tất cả vào giỏ ]
```

**A5.7 Checkout**
```
1 Địa chỉ giao   (chọn/thêm)         ┌ Tóm tắt đơn ──────────┐
2 Thời gian giao (khung giờ)         │ 8 sản phẩm   385.000đ │
3 Thanh toán ○COD ○Chuyển khoản QR   │ Phí ship      20.000đ │
              ○VNPay                 │ Giảm giá     −0       │
4 Ghi chú, mã giảm giá [Áp dụng]     │ Tổng        405.000đ │
⚠ Cảnh báo dị ứng (nếu có)           │ [ Đặt hàng ]          │
                                     └───────────────────────┘
```

**A5.8 Đơn hàng**
```
Đơn NC100123 · 19/10/2026 · 405.000đ     [Mua lại] [Hủy đơn*]
●─────●─────●─────○─────○
Đã đặt  Xác nhận  Đang chuẩn bị  Đang giao  Đã giao
Danh sách sản phẩm · Địa chỉ · Thanh toán · Mã vận đơn
```

**A5.9 Admin – Công thức (form)**
```
Thông tin | Nguyên liệu | Các bước | Dinh dưỡng (tự tính, xem trước) | Cờ & Tag | Xuất bản
Trạng thái: draft → [Gửi duyệt] → review → [Duyệt & Xuất bản] (nutritionist)
```

### A6. Trạng thái & vi tương tác
- **Loading:** skeleton theo hình thẻ; nút có spinner; không block toàn trang.
- **Empty:** minh họa + CTA ("Chưa có thực đơn — Tạo thực đơn tuần").
- **Error:** thông báo thân thiện + nút thử lại; lỗi hết hàng chỉ rõ sản phẩm.
- **Optimistic UI:** ♥ yêu thích, thêm giỏ, tick "đã có".
- **Toast** 4s cho thành công; **Dialog** xác nhận cho hành động phá hủy (hủy đơn, xóa tài khoản).
- Chuyển cảnh ≤ 200ms; tôn trọng `prefers-reduced-motion`.

### A7. Nội dung & ngôn ngữ (microcopy)
- Giọng thân thiện, tôn trọng, không phán xét cân nặng ("Mục tiêu sức khỏe của bạn", không dùng "béo/gầy").
- Cảnh báo y tế: *"Thông tin mang tính tham khảo. Hãy hỏi bác sĩ nếu bạn đang dùng thuốc hoặc có bệnh nền."*
- Định dạng: `1.234.567đ`, `dd/MM/yyyy`, `kcal`, `g`, `mg`; hiển thị tháng/ngày tiếng Việt.

### A8. Khả năng truy cập (WCAG 2.1 AA)
- Tương phản chữ ≥ 4.5:1; focus ring rõ (`ring-2 ring-brand-500`).
- Điều hướng bàn phím đầy đủ; kéo-thả có **phương án thay thế bằng nút** ("Chuyển sang…").
- `alt` cho ảnh món; `aria-live="polite"` khi cập nhật tổng giỏ/khẩu phần; label cho mọi form.
- Biểu đồ có bảng số liệu thay thế; không chỉ dùng màu.
- Tùy chọn "Chữ lớn" lưu ở `localStorage`.

---

## PHẦN B — FRONTEND (React)

### B1. Cấu trúc thư mục `apps/web/src`
```
app/
  App.tsx · router.tsx · providers.tsx (QueryClient, Auth, Theme, i18n, Toaster)
  layouts/ PublicLayout.tsx · AppLayout.tsx · AdminLayout.tsx
features/
  auth/        LoginPage · RegisterPage · ForgotPage · ResetPage · AuthCallback · useAuth.ts · AuthProvider.tsx · guards.tsx
  profile/     OnboardingWizard · steps/* · AccountPage · hooks/useProfile.ts · schema.ts
  recipes/     RecipeListPage · RecipeDetailPage · components/* · hooks/useRecipes.ts · api.ts
  recommend/   ForYouPage · hooks/useRecommendations.ts · VerdictBadge.tsx
  mealplan/    MealPlanPage · PlanGrid · hooks/useMealPlan.ts
  shop/        ShopPage · ProductPage · ShoppingListPage · hooks/*
  cart/        CartDrawer · CartPage · store.ts · hooks/useCart.ts
  checkout/    CheckoutPage · AddressForm · PaymentSelect · hooks/useCheckout.ts
  orders/      OrdersPage · OrderDetailPage · OrderTimeline.tsx
  journal/     JournalPage · WeightChart · hooks/*
  admin/       Dashboard · Recipes/* · Ingredients/* · Products/* · Orders/* · Users/* · Rules/*
components/ui/    (shadcn) button, input, dialog, sheet, tabs, toast, ...
components/shared/ NutritionFacts · MacroRing · ServingsStepper · MedicalDisclaimer · EmptyState · Skeletons
lib/  supabase.ts · api.ts · queryClient.ts · format.ts · analytics.ts · cn.ts
hooks/ useDebounce · useMediaQuery · useLocalStorage
stores/ uiStore.ts (Zustand: chữ lớn, theme, cartOpen)
types/ database.ts (sinh tự động) · domain.ts
i18n/  vi.json · en.json
```

### B2. Router & guard
```tsx
// app/router.tsx
import { createBrowserRouter } from 'react-router-dom';
export const router = createBrowserRouter([
  { element: <PublicLayout/>, children: [
    { path: '/', element: <HomePage/> },
    { path: '/recipes', element: <RecipeListPage/> },
    { path: '/recipes/:slug', element: <RecipeDetailPage/> },
    { path: '/shop', element: <ShopPage/> },
    { path: '/login', element: <LoginPage/> }, { path: '/register', element: <RegisterPage/> },
    { path: '/forgot-password', element: <ForgotPage/> }, { path: '/reset-password', element: <ResetPage/> },
    { path: '/auth/callback', element: <AuthCallback/> },
  ]},
  { element: <ProtectedRoute><AppLayout/></ProtectedRoute>, children: [
    { path: '/onboarding', element: <OnboardingWizard/> },
    { element: <RequireOnboarding/>, children: [
      { path: '/dashboard', element: <DashboardPage/> },
      { path: '/for-you', element: <ForYouPage/> },
      { path: '/meal-plan', element: <MealPlanPage/> },
      { path: '/shopping-list', element: <ShoppingListPage/> },
      { path: '/cart', element: <CartPage/> }, { path: '/checkout', element: <CheckoutPage/> },
      { path: '/orders', element: <OrdersPage/> }, { path: '/orders/:id', element: <OrderDetailPage/> },
      { path: '/favorites', element: <FavoritesPage/> }, { path: '/account', element: <AccountPage/> },
    ]},
  ]},
  { element: <RoleRoute roles={['admin','staff','nutritionist']}><AdminLayout/></RoleRoute>,
    path: '/admin', children: [ /* … */ ] },
]);
```

### B3. Supabase client & Auth (đăng ký / đăng nhập / đăng xuất)
```ts
// lib/supabase.ts
import { createClient } from '@supabase/supabase-js';
import type { Database } from '@/types/database';
export const supabase = createClient<Database>(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY,
  { auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true, flowType: 'pkce' } }
);
```
```tsx
// features/auth/AuthProvider.tsx
type Ctx = { user: User | null; profile: Profile | null; loading: boolean;
  signUp(e:string,p:string,name:string):Promise<void>; signIn(e:string,p:string):Promise<void>;
  signInGoogle():Promise<void>; signOut():Promise<void>; refreshProfile():Promise<void> };

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User|null>(null);
  const [profile, setProfile] = useState<Profile|null>(null);
  const [loading, setLoading] = useState(true);
  const qc = useQueryClient();

  const loadProfile = useCallback(async (uid: string) => {
    const { data } = await supabase.from('profiles').select('*').eq('id', uid).single();
    setProfile(data);
  }, []);

  useEffect(() => {
    supabase.auth.getSession().then(async ({ data }) => {
      setUser(data.session?.user ?? null);
      if (data.session?.user) await loadProfile(data.session.user.id);
      setLoading(false);
    });
    const { data: sub } = supabase.auth.onAuthStateChange((_evt, session) => {
      setUser(session?.user ?? null);
      if (session?.user) setTimeout(() => loadProfile(session.user.id), 0); // tránh deadlock trong callback
      else { setProfile(null); qc.clear(); }
    });
    return () => sub.subscription.unsubscribe();
  }, [loadProfile, qc]);

  const value: Ctx = {
    user, profile, loading,
    signUp: async (email, password, full_name) => {
      const { error } = await supabase.auth.signUp({ email, password,
        options: { data: { full_name }, emailRedirectTo: `${location.origin}/auth/callback` } });
      if (error) throw error;
    },
    signIn: async (email, password) => {
      const { error } = await supabase.auth.signInWithPassword({ email, password }); if (error) throw error;
    },
    signInGoogle: async () => { await supabase.auth.signInWithOAuth({ provider: 'google',
      options: { redirectTo: `${location.origin}/auth/callback` } }); },
    signOut: async () => { await supabase.auth.signOut(); qc.clear(); },
    refreshProfile: async () => { if (user) await loadProfile(user.id); },
  };
  return <AuthCtx.Provider value={value}>{children}</AuthCtx.Provider>;
}
```
```tsx
// features/auth/guards.tsx
export function ProtectedRoute({ children }: { children: ReactNode }) {
  const { user, loading } = useAuth(); const loc = useLocation();
  if (loading) return <FullPageSpinner/>;
  return user ? <>{children}</> : <Navigate to="/login" state={{ from: loc }} replace/>;
}
export function RequireOnboarding() {
  const { profile } = useAuth();
  return profile?.onboarding_done ? <Outlet/> : <Navigate to="/onboarding" replace/>;
}
export function RoleRoute({ roles, children }: { roles: Role[]; children: ReactNode }) {
  const { profile, loading } = useAuth();
  if (loading) return <FullPageSpinner/>;
  return profile && roles.includes(profile.role) ? <>{children}</> : <Navigate to="/" replace/>;
}
```

### B4. Form đăng nhập (React Hook Form + Zod)
```tsx
const schema = z.object({
  email: z.string().email('Email không hợp lệ'),
  password: z.string().min(8, 'Tối thiểu 8 ký tự'),
});
export function LoginPage() {
  const { signIn, signInGoogle } = useAuth(); const nav = useNavigate();
  const { register, handleSubmit, setError, formState:{ errors, isSubmitting } } =
    useForm<z.infer<typeof schema>>({ resolver: zodResolver(schema) });
  const onSubmit = handleSubmit(async v => {
    try { await signIn(v.email, v.password); nav('/dashboard'); }
    catch { setError('root', { message: 'Email hoặc mật khẩu không đúng' }); }
  });
  /* render: <form onSubmit={onSubmit}> … <Button loading={isSubmitting}>Đăng nhập</Button> … */
}
```

### B5. Gọi API & Query
```ts
// lib/api.ts — gọi Vercel Functions kèm JWT
export async function api<T>(path: string, init: RequestInit = {}): Promise<T> {
  const { data } = await supabase.auth.getSession();
  const res = await fetch(`/api${path}`, { ...init, headers: {
    'Content-Type': 'application/json',
    ...(data.session ? { Authorization: `Bearer ${data.session.access_token}` } : {}),
    ...init.headers } });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) throw new ApiError(json?.error?.code ?? 'UNKNOWN', json?.error?.message ?? 'Có lỗi xảy ra', res.status);
  return json as T;
}
```
```ts
// features/recipes/hooks/useRecipes.ts
export function useRecipes(filters: RecipeFilters) {
  return useInfiniteQuery({
    queryKey: ['recipes', filters],
    queryFn: async ({ pageParam = 0 }) => {
      let q = supabase.from('recipes')
        .select('id,slug,title,image_url,kcal,protein_g,carb_g,fat_g,sodium_mg,cook_minutes,tags,allergen_ids', { count: 'exact' })
        .eq('status','published').range(pageParam, pageParam + 11);
      if (filters.meal)      q = q.contains('meal', [filters.meal]);
      if (filters.maxMinutes) q = q.lte('cook_minutes', filters.maxMinutes);
      if (filters.tags?.length) q = q.contains('tags', filters.tags);
      if (filters.search)    q = q.textSearch('search', filters.search, { type: 'websearch', config: 'simple' });
      const { data, error } = await q; if (error) throw error; return data;
    },
    getNextPageParam: (last, all) => last.length === 12 ? all.length * 12 : undefined,
    initialPageParam: 0, staleTime: 60_000,
  });
}
export const useRecommendations = (meal?: Meal) =>
  useQuery({ queryKey: ['recs', meal], queryFn: () => api<RecResponse>(`/recommendations?meal=${meal ?? ''}`), staleTime: 5*60_000 });
```
> **Chiến lược cache:** `['recipes',…]` 1 phút; `['recs']` 5 phút, vô hiệu hóa khi hồ sơ đổi; giỏ hàng/đơn: `staleTime: 0` + `invalidateQueries` sau mutation; Realtime cho `orders` (subscribe theo `user_id`).

### B6. Giỏ hàng (store + đồng bộ DB)
```ts
// features/cart/hooks/useCart.ts — nguồn sự thật là DB khi đã đăng nhập
export const useCart = () => useQuery({ queryKey:['cart'], queryFn: async () => {
  const { data } = await supabase.from('cart_items')
    .select('qty, product:products(id,name,image_url,unit,price_vnd,stock,reserved,allergen_ids)'); return data ?? []; } });

export const useAddToCart = () => { const qc = useQueryClient(); return useMutation({
  mutationFn: async ({ productId, qty }: { productId: string; qty: number }) => {
    const cartId = await ensureCart();                    // select/insert carts theo user
    const { error } = await supabase.from('cart_items').upsert({ cart_id: cartId, product_id: productId, qty });
    if (error) throw error;
  },
  onMutate: async v => { /* optimistic update */ },
  onSuccess: () => qc.invalidateQueries({ queryKey: ['cart'] }),
}); };
```
- Khách chưa đăng nhập: giữ giỏ tạm trong Zustand (`persist`), **gộp vào DB** sau khi đăng nhập.
- Trước khi thêm: nếu `product.allergen_ids ∩ profile.allergens ≠ ∅` → hiển thị `AllergyAlert` yêu cầu xác nhận.

### B7. Tính dinh dưỡng phía client (xem trước)
```tsx
import { scaleRecipe, evaluateRecipe } from '@nutricook/nutrition-core';
const [servings, setServings] = useState(recipe.base_servings);
const scaled = useMemo(() => scaleRecipe(recipe, servings), [recipe, servings]);
const verdict = useMemo(() => evaluateRecipe(recipe, userCtx), [recipe, userCtx]);
```
Server vẫn là nguồn sự thật cho thực đơn/đơn hàng; client chỉ để hiển thị tức thời.

### B8. Thực đơn tuần — kéo thả
- Dùng **dnd-kit** (`DndContext`, `SortableContext`); thả → gọi `PATCH meal_plan_items` (RLS) + tính lại tổng ngày bằng `nutrition-core`.
- Cung cấp menu "Chuyển sang…" bằng bàn phím/điện thoại thay cho kéo thả.
- Nút 🔄 gọi `POST /api/mealplan/:id/swap`.

### B9. Onboarding wizard
- Trạng thái bằng `useReducer` + lưu nháp `sessionStorage`; mỗi bước có schema Zod riêng.
- Kết thúc: `POST /api/profile/compute` → cập nhật `profiles`, `user_health_conditions`, `user_allergies` → `refreshProfile()` → `/dashboard`.
- Nếu chọn nhóm đỏ: hiển thị `RedTierNotice`, chặn nút "Tạo thực đơn giảm cân", vẫn cho xem công thức chung.

### B10. Đặt hàng
```ts
export const useCheckout = () => useMutation({
  mutationFn: (p: CheckoutInput) => api<{ orderId: string; payUrl?: string }>('/checkout', { method:'POST', body: JSON.stringify(p) }),
  onSuccess: ({ orderId, payUrl }) => payUrl ? (location.href = payUrl) : nav(`/orders/${orderId}?placed=1`),
});
```
Trang kết quả thanh toán đọc `orders.payment_status` (poll 3s tối đa 60s) — **không** tin tham số URL.

### B11. SEO & hiệu năng
- `react-helmet-async`: title/description/OG; JSON-LD `Recipe` cho trang chi tiết (name, image, recipeIngredient, recipeInstructions, nutrition).
- Prerender các trang công khai (`vite-plugin-ssr`/script prerender chạy khi build) + `sitemap.xml` sinh từ DB.
- Ảnh: WebP/AVIF, `loading="lazy"`, `srcset`, kích thước cố định tránh CLS; transform ảnh qua Supabase Storage (`?width=400`).
- Code-splitting theo route (`React.lazy`), tách chunk admin; `manualChunks` cho `recharts`.
- Ngân sách: JS ban đầu < 180 KB gzip; LCP < 2.5s.

### B12. i18n & định dạng
```ts
export const vnd = (n: number) => new Intl.NumberFormat('vi-VN',{style:'currency',currency:'VND'}).format(n);
export const kcal = (n: number) => `${Math.round(n).toLocaleString('vi-VN')} kcal`;
```
Chuỗi UI trong `i18n/vi.json`; tránh nối chuỗi thủ công.

### B13. Xử lý lỗi & an toàn
- `ErrorBoundary` bao từng route; `Sentry.captureException` (loại dữ liệu sức khỏe).
- Map mã lỗi API → thông điệp tiếng Việt (`OUT_OF_STOCK`, `PLAN_NOT_ALLOWED`, `RATE_LIMITED`, …).
- Không log token/hồ sơ sức khỏe ra console.
- Không dùng `dangerouslySetInnerHTML` cho dữ liệu người dùng.

### B14. Kiểm thử frontend
| Loại | Gợi ý |
|---|---|
| Component | `NutritionFacts`, `ServingsStepper`, `VerdictBadge`, `AllergyAlert` (Testing Library) |
| Hook | `useCart` (mock supabase), `useRecipes` |
| E2E (Playwright) | `register→onboarding→for-you→add-to-cart→checkout(COD)`; `login/logout`; guard chuyển hướng; hồ sơ dị ứng không thấy món chứa chất đó |
| Visual | Storybook + Chromatic (P1) |
| A11y | `@axe-core/playwright` trên các trang chính |

### B15. Checklist hoàn thành Frontend (Definition of Done)
- [ ] Responsive 360px → 1440px, không cuộn ngang.
- [ ] Đủ trạng thái loading/empty/error.
- [ ] Axe không có lỗi mức serious/critical.
- [ ] Mọi chuỗi qua i18n; định dạng tiền/ngày đúng `vi-VN`.
- [ ] Không có `any` không giải thích; `tsc --noEmit` sạch; ESLint sạch.
- [ ] Có test cho logic mới; E2E luồng chính xanh.
- [ ] Không rò secret (`grep service_role` trong `apps/web` = 0).
- [ ] Hiển thị `MedicalDisclaimer` ở onboarding, trang gợi ý, chi tiết công thức, thực đơn.

---

## PHẦN C — THỨ TỰ XÂY DỰNG UI ĐỀ XUẤT
1. Khởi tạo Vite + Tailwind + shadcn + router + AuthProvider.
2. Layouts + trang Auth (đăng ký/đăng nhập/đăng xuất/quên mật khẩu/Google).
3. Onboarding + `nutrition-core` (tính mục tiêu).
4. Thư viện công thức + chi tiết + scale + yêu thích.
5. Gợi ý (`VerdictBadge`, "Vì sao gợi ý").
6. Thực đơn tuần + danh sách mua sắm.
7. Cửa hàng + giỏ hàng + checkout + đơn hàng.
8. Admin (công thức, nguyên liệu, sản phẩm, đơn, người dùng).
9. Nhật ký & biểu đồ, thông báo, đánh giá.
10. Tối ưu SEO/hiệu năng/a11y, E2E, go-live.

---

## NGUỒN THAM KHẢO UI
- Mô hình sản phẩm tham chiếu: Eat This Much (thực đơn tự động + shopping list), ReciMe (shopping list theo khu vực, meal planner kéo-thả, scale khẩu phần), Cronometer (chi tiết vi chất), Yummly (lọc chế độ ăn).
- WCAG 2.1: https://www.w3.org/TR/WCAG21/ · shadcn/ui: https://ui.shadcn.com · TanStack Query: https://tanstack.com/query · dnd-kit: https://dndkit.com
