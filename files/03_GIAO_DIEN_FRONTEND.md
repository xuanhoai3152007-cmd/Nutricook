# 03 — GIAO DIỆN (UI/UX) & FRONTEND (v2)
## NutriCook — React + Vite + TypeScript + Tailwind + shadcn/ui + Supabase

> **Thay đổi so với v1:** giữ và nối phần **mua hàng** với công thức (danh sách mua sắm → giỏ → checkout → theo dõi đơn). Thêm: **trang công thức chi tiết** (dụng cụ, nguyên liệu theo nhóm, bước có lửa/hẹn giờ/mẹo, lỗi thường gặp, thay thế, bảo quản), **chế độ nấu**, **trang AI gợi ý "Hôm nay nấu gì?"**, hồ sơ khẩu vị & người cùng ăn.
> Backend và hợp đồng API: `02_KY_THUAT.md`.

---

## PHẦN A — THIẾT KẾ GIAO DIỆN

### A1. Nguyên tắc
1. **Tươi – sạch – đáng tin**: xanh lá + cam ấm, ảnh món lớn, nhiều khoảng trắng.
2. **An toàn trước**: cảnh báo dị ứng/bệnh lý luôn nổi bật; nhãn Phù hợp/Lưu ý/Không nên có icon + chữ (không chỉ màu).
3. **Đang nấu thì tay bẩn**: chế độ nấu chữ rất lớn, nút bấm to, ít thao tác, màn hình luôn sáng.
4. **Mobile-first**, một tay; nút ≥ 44×44 px; chữ gốc 16 px, tùy chọn "Chữ lớn" 18–20 px.
5. **Giải thích được**: mỗi gợi ý có "Vì sao hợp với bạn".
6. **Minh bạch AI**: gắn nhãn "Gợi ý bởi AI", nói rõ dữ liệu nào được gửi, có nút tắt.

### A2. Design tokens (Tailwind)
```ts
colors: {
  brand:  { 50:'#F0FBF4',100:'#DCF5E5',300:'#86D8A9',500:'#27A468',600:'#1B8553',700:'#176A44',900:'#124630' },
  accent: { 100:'#FFE9D3',500:'#F58A2B',600:'#DC6D12' },              // cam: AI, điểm nhấn
  ink:    { 900:'#14201A',700:'#34443B',500:'#5E6F65',300:'#A5B3AA',100:'#E6ECE8' },
  surface:{ DEFAULT:'#FFFFFF', muted:'#F7FAF8', sunken:'#EEF3F0' },
  ok:{bg:'#E8F7EE',fg:'#15703F'}, warn:{bg:'#FFF4D6',fg:'#8A5A00'}, danger:{bg:'#FDE8E8',fg:'#A11A1A'},
  heat:{ low:'#60A5FA', medium:'#F59E0B', high:'#EF4444' },           // mức lửa
  macro:{ protein:'#3B82F6', carb:'#F59E0B', fat:'#EC4899', fiber:'#10B981' }
}
fontFamily: { sans:['"Be Vietnam Pro"','Inter','system-ui','sans-serif'] }
borderRadius: { xl:'14px','2xl':'20px' }
```
Lưới 4 px; ảnh món 4:3; breakpoints `sm 640 · md 768 · lg 1024 · xl 1280`.

### A3. Thành phần dùng chung
| Component | Ghi chú |
|---|---|
| `RecipeCard` | Ảnh, tên, thời gian, độ khó, kcal, 3 macro, ♥, `VerdictBadge` |
| `VerdictBadge` | ✓ Phù hợp / ⚠ Lưu ý / ⛔ Không nên (+ tooltip lý do) |
| `AllergyAlert` | Banner đỏ khi món chạm dị ứng (truy cập trực tiếp) |
| `NutritionFacts` | Bảng/khẩu phần + tổng theo số khẩu phần, % mục tiêu |
| `MacroRing` | Donut đạm/carb/béo + kcal |
| `ServingsStepper` | − / + (1–12) |
| `EquipmentChecklist` | Dụng cụ cần có, tick được |
| `IngredientGroups` | Nguyên liệu theo nhóm; số lượng scale; ghi chú sơ chế; tick "đã chuẩn bị"; badge "tùy chọn" |
| `StepCard` | Số bước, **chip giai đoạn** (Sơ chế/Nấu/Hoàn thiện), tiêu đề, hướng dẫn, `HeatBadge`, `TimerButton`, khối **Mẹo** |
| `HeatBadge` | 🔥 nhỏ/vừa/lớn (icon + chữ + màu) |
| `StepTimer` | Đếm ngược, rung/chuông, chạy nền, nhiều timer song song |
| `TipBox` / `MistakeList` / `SubstitutionList` | Mẹo / Lỗi thường gặp / Thay thế nguyên liệu |
| `AiSuggestForm` | Form gợi ý (mục A5.6) |
| `AiRecipeCard` | `RecipeCard` + "Vì sao hợp", gợi ý chia khẩu phần, 👍/👎, nút "Xem công thức (×N)" |
| `ShoppingListView` | Danh sách mua sắm theo nhóm hàng: nguyên liệu cần · đã có · mua · sản phẩm đề xuất · số lượng · giá; tick "đã có ở nhà"; cảnh báo hết hàng/dị ứng |
| `ProductCard` | Ảnh, tên, quy cách, giá, tồn kho, nhãn dị ứng, stepper số lượng |
| `CartDrawer` / `CartLine` | Danh sách dòng hàng, đổi số lượng, xóa, tạm tính, nút "Thanh toán" |
| `AllergyConfirmDialog` | Hộp thoại bắt buộc xác nhận khi sản phẩm chứa chất dị ứng |
| `AddressForm` / `AddressPicker` | Sổ địa chỉ, đặt mặc định |
| `CheckoutSummary` | Báo giá: tạm tính, phí ship, mã giảm giá, tổng |
| `PaymentMethodSelect` | COD / VNPay |
| `OrderTimeline` | Các mốc: đã đặt → xác nhận → chuẩn bị → đang giao → đã giao (+ hủy) |
| `OrderStatusBadge` | Trạng thái đơn (icon + chữ) |
| `FeedbackButtons` | 👍 / 👎 (mở chọn lý do) / ✔ Đã nấu |
| `EaterPicker` | Chọn nhóm tuổi + số người (trẻ em, thiếu niên, người lớn, cao tuổi) |
| `TasteChips`, `SpiceSlider` | Chọn vị, mức cay 0–3 |
| `MedicalDisclaimer`, `AiDisclaimer` | Khối chữ nhỏ bắt buộc |
| `EmptyState`, `Skeleton`, `Toast`, `Dialog`, `Sheet`, `Tabs`, `DataTable` (admin) | shadcn/ui |

### A4. Sitemap
```
CÔNG KHAI
/                       Trang chủ
/recipes                Thư viện (tìm kiếm + lọc)
/recipes/:slug          Chi tiết công thức
/about/method           Nguồn & Phương pháp
/legal/terms | privacy
/login /register /forgot-password /reset-password /auth/callback

NGƯỜI DÙNG (đăng nhập)
/onboarding             Wizard 6 bước
/dashboard              Tổng quan
/ai                     ★ Hôm nay nấu gì? (AI gợi ý)
/for-you                Gợi ý theo hồ sơ (quy tắc)
/recipes/:slug/cook     ★ Chế độ nấu từng bước
/meal-plan              Thực đơn tuần
/favorites              Yêu thích & đã nấu
/shop                   Cửa hàng nguyên liệu (lọc theo danh mục)
/shop/:slug             Chi tiết sản phẩm
/shopping-list          ★ Danh sách mua sắm (từ công thức/thực đơn)
/cart                   Giỏ hàng
/checkout               Thanh toán
/orders  /orders/:id    Lịch sử & chi tiết đơn (theo dõi trạng thái)
/journal                Nhật ký (P1)
/account                Hồ sơ · Sức khỏe · Khẩu vị · Người cùng ăn · **Địa chỉ giao hàng** · Nguyên liệu đang có · AI & quyền riêng tư · Xuất/Xóa dữ liệu

QUẢN TRỊ (nutritionist/admin)
/admin  /admin/recipes (+/new, /:id)  /admin/ingredients  /admin/rules  /admin/users  /admin/ai
/admin/products  /admin/orders (+/:id)  /admin/coupons  /admin/shipping     (staff/admin)
```

### A5. Wireframe

**A5.1 Onboarding (6 bước)**
```
1/6 Về bạn        giới tính · ngày sinh · chiều cao · cân nặng
2/6 Mục tiêu      giảm/duy trì/tăng cân/tăng cơ/ăn lành mạnh · mức vận động
3/6 Sức khỏe      ☐ tiểu đường ☐ huyết áp ☐ mỡ máu ☐ gout ☐ dạ dày ☐ thiếu máu ☐ thận⚠ ☐ mang thai⚠
                  (⚠ nhóm đỏ: hộp cảnh báo, không tạo thực đơn tự động)
4/6 Ăn uống       dị ứng (chip) · chế độ ăn · nguyên liệu không thích
5/6 Khẩu vị       mức cay [0───●──3] · vị: [thanh đạm][ít mặn][ngọt][chua][đậm đà][tươi mát]
                  ẩm thực: [Việt][Á][Âu][Địa Trung Hải] · kiểu nấu: [xào][hấp][kho][canh][nướng]…
                  thời gian nấu tối đa · trình độ · khẩu phần mặc định
6/6 Người cùng ăn + Xác nhận
                  [− 2 +] Người lớn  [− 1 +] Trẻ em  [− 0 +] Thiếu niên  [− 1 +] Cao tuổi
                  Kết quả: BMI · kcal/ngày · macro (donut) · natri/đường tối đa
                  ☑ Đồng ý xử lý dữ liệu sức khỏe (bắt buộc)
                  ☐ Bật gợi ý AI (tùy chọn) — xem dữ liệu nào được gửi
                  MedicalDisclaimer                              [ Bắt đầu ]
```

**A5.2 Thư viện công thức**
```
[🔎 Tìm món, nguyên liệu…]                         [Bộ lọc ▾]
Chip: Sáng|Trưa|Tối|Phụ · Việt|Á|Âu · Xào|Hấp|Canh|Nướng · ≤20′|≤40′ · Không cay · Ít natri · Giàu đạm
[✓] Chỉ hiện món phù hợp với tôi (mặc định BẬT khi đã có hồ sơ)
┌────────┐ ┌────────┐ ┌────────┐
│ ảnh ♥  │ │ ảnh ♥  │ │ ảnh ♥  │
│ Tên món│ │        │ │        │
│ 25′ ★2 · 320 kcal │ P22 C30 B8
│ ✓Phù hợp │ ⚠Lưu ý: natri
└────────┘
```

**A5.3 Chi tiết công thức (trang dài, có thanh mục lục dính)**
```
[ảnh lớn]  Cá diêu hồng hấp gừng hành                      ♥  ⤴  🖨
✓ Phù hợp với bạn — Ít natri · Mềm, dễ ăn            (Vì sao?)
⚠/⛔ Banner cảnh báo (dị ứng / bệnh lý / nhóm tuổi) nếu có
⏱ Sơ chế 15′ · Nấu 15′ · Tổng 30′   ⭐ Độ khó 2/3   🍽 Việt · Hấp   🌶 Không cay
Khẩu phần: [−] 2 [+]            (đổi → nguyên liệu & dinh dưỡng tự tính lại)
──────────────────────────────────────────────────────────────
Giới thiệu    (đoạn ngắn)
Dụng cụ       ☐ Nồi hấp  ☐ Đĩa sâu lòng  ☐ Dao thớt  ☐ Chảo nhỏ
Nguyên liệu
  ▸ Cá                    ☐ 450 g  Cá diêu hồng (1 con nhỏ)  — Cạo vảy, bỏ ruột; rạch 2–3 đường sâu 5 mm
                          ☐ 1/4 muỗng cà phê  Tiêu
  ▸ Hấp                   ☐ 3 lát  Gừng — thái lát mỏng lót đáy đĩa …
  ▸ Nước sốt              …
  ▸ Trang trí             ☐ 1 quả Ớt (tùy chọn)
Cách làm
  ┌ Bước 1 · SƠ CHẾ · Làm sạch cá ─────────────────────────┐
  │ Cạo sạch vảy, bỏ ruột và mang, rửa kỹ …                  │
  │ 💡 Nhờ cửa hàng làm sạch cá sẽ nhanh hơn …              │
  └──────────────────────────────────────────────────────────┘
  ┌ Bước 6 · NẤU · Hấp cá     🔥 Lửa lớn   ⏱ 11:00 [▶ Hẹn giờ] ┐
  │ …                                                          │
  │ 💡 Cá chín khi chọc đũa thấy thịt trắng đục …             │
  └────────────────────────────────────────────────────────────┘
Mẹo nấu ngon · Lỗi thường gặp (✗ + cách tránh) · Thay thế nguyên liệu · Bảo quản & hâm lại · Ăn kèm
Dinh dưỡng / khẩu phần (NutritionFacts + MacroRing)  ·  Lưu ý sức khỏe
Phản hồi: [👍] [👎] [✔ Tôi đã nấu]     Đánh giá ★ (P1)
MedicalDisclaimer
[ ▶ Bắt đầu nấu ]  [ 🛒 Mua nguyên liệu (×khẩu phần) ]   (nút dính ở đáy trên mobile)
```

**A5.4 Chế độ nấu (toàn màn hình)**
```
┌──────────────────────────────────────────┐
│ ✕   Cá diêu hồng hấp          Bước 6/8   │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░  75%               │
│                                          │
│   HẤP CÁ        🔥 Lửa lớn               │
│   Xếp gừng lát lót đáy đĩa, đặt cá lên,  │   (chữ ≥ 20 px)
│   phủ gừng sợi. Cho vào xửng, đậy nắp    │
│   hấp 10–12 phút.                        │
│   💡 Chọc đũa chỗ dày nhất…              │
│                                          │
│        ⏱  10:59       [⏸] [↺]            │
│  Cần: 450 g cá · 3 lát gừng · 15 g gừng  │   (nguyên liệu của bước, đã scale)
│  [◀ Trước]                     [Tiếp ▶]  │
└──────────────────────────────────────────┘
Trước bước 1: màn "Chuẩn bị" (tick dụng cụ & nguyên liệu).
Cuối: "Hoàn thành!" → [✔ Tôi đã nấu] [👍][👎 lý do] [Bảo quản & hâm lại].
Giữ màn hình sáng (Wake Lock API); timer vẫn chạy khi chuyển bước; thông báo khi hết giờ.
```

**A5.5 Dashboard**
```
Xin chào, Lan 👋
┌ Mục tiêu hôm nay ──────────┐  ┌ ✨ Hôm nay nấu gì? ────────────┐
│ (MacroRing) 1.480/1.650    │  │ Hỏi AI gợi ý theo khẩu vị,    │
│ P78 C160 B42               │  │ người cùng ăn, thời gian…      │
└────────────────────────────┘  │ [ Gợi ý cho tôi ]              │
                                └────────────────────────────────┘
Gợi ý cho bạn (quy tắc) →  [RecipeCard][RecipeCard][RecipeCard]
Thực đơn tuần này [Tạo thực đơn]    Món bạn đã nấu gần đây    Đơn gần đây: NC100123 · Đang giao →
```

**A5.6 AI gợi ý — "Hôm nay nấu gì?"** (`/ai`)
```
✨ Gợi ý bởi AI                                         [ⓘ Dữ liệu gửi đi] [Tắt AI]
Bữa:         (Sáng) (Trưa) (●Tối) (Phụ)
Ăn cho ai:   Người lớn [−2+]  Trẻ em [−1+]  Thiếu niên [−0+]  Cao tuổi [−1+]
Nấu bao nhiêu khẩu phần: [−] 4 [+]
Khẩu vị:     [Thanh đạm ✓][Ít mặn ✓][Ngọt][Chua][Đậm đà][Tươi mát]     Mức cay [●──────] 1
Phong cách:  [Việt ✓][Á][Âu][Địa Trung Hải]     Kiểu nấu: [Hấp ✓][Canh ✓][Xào][Kho][Nướng]
Thời gian tối đa: [ 40 phút ▾ ]
Đang có / muốn dùng:  [cá ✕][gừng ✕] [+ thêm]        Không muốn:  [tôm ✕] [+ thêm]
Ghi chú (≤ 300 ký tự): "Ông ăn nhạt, bé thích món ngọt nhẹ"
ⓘ Hệ thống tự loại món chứa dị ứng/không hợp hồ sơ trước khi AI chọn.
[ ✨ Gợi ý món ]
─────────────────────────────────────────────────
Mình chọn các món mềm, ít cay cho cả nhà.                 (hoặc: "AI đang bận, đây là gợi ý theo hồ sơ")
┌ ảnh ┐ Cá diêu hồng hấp gừng hành        ✓ Phù hợp
│     │ 30′ · Độ khó 2 · 196 kcal · P41 · natri 398 mg
│     │ ✨ Cá hấp mềm, ít muối, không cay — hợp ông và bé.
│     │ 🍽 Chia khẩu phần: gỡ kỹ xương cho bé và ông, rưới ít sốt.
│     │ Nấu 4 khẩu phần = nguyên liệu ×2
│     │ [Xem công thức (×2)] [▶ Nấu ngay] [🛒 Mua nguyên liệu]  [👍] [👎]
└─────┘ …
```
Trạng thái: đang tải (skeleton + "AI đang chọn món…" ≤ 12 s), không có kết quả (gợi ý nới điều kiện), lỗi `RATE_LIMITED`, chưa bật AI (hiện consent), `fallback = true` (nhãn "Gợi ý theo hồ sơ").

**A5.7 Thực đơn tuần**
```
Tuần 20–26/10   [◀][▶]   [Tạo lại] [Lưu]     Mục tiêu 1.650 kcal
        T2     T3     T4 …
Sáng  [Card] [Card] [Card]   kéo-thả · ghim 📌 · đổi 🔄 · "Chuyển sang…"
Trưa  [Card] …
Tối   [Card] …
Σ     1.640  1.670  …   (xanh ±5%, vàng, đỏ)
[ 🛒 Tạo danh sách mua sắm cho cả tuần ]   (gộp nguyên liệu 7 ngày, trừ đồ đã có)
Nhóm đỏ: thay bằng hộp "Cần tư vấn chuyên gia trước khi lập thực đơn tự động".
```

**A5.8 Admin — Soạn công thức (tab)**
```
Thông tin | Nguyên liệu | Các bước | Hướng dẫn thêm | Dinh dưỡng (tự tính) | Xuất bản
Nguyên liệu: bảng [Nhóm][Nguyên liệu (tìm kiếm)][g][Số lượng + đơn vị][Sơ chế][Ghi chú][Tùy chọn][Scale]
Các bước:   thẻ kéo-thả [Giai đoạn][Tiêu đề][Hướng dẫn][Hẹn giờ][Mức lửa][Mẹo][Ảnh]
Hướng dẫn thêm: Dụng cụ · Mẹo · Lỗi thường gặp · Thay thế · Bảo quản · Ăn kèm · Lưu ý sức khỏe
Xuất bản: checklist realtime  ✓≥3 nguyên liệu ✓≥4 bước ✓có bước sơ chế ✓bước ≥20 ký tự ✓ảnh ✓dụng cụ ✓dinh dưỡng
          [Gửi duyệt] → [Duyệt & xuất bản] (nutritionist)  — lỗi từ DB hiển thị: NEED_PREP_STEP, STEP_TOO_SHORT…
```

**A5.9 Cửa hàng**
```
[🔎 Tìm sản phẩm]   Danh mục: Tất cả | Rau củ quả | Thịt-cá-hải sản | Ngũ cốc-đậu-hạt | Gia vị-dầu ăn | Sữa
┌────────┐ ┌────────┐ ┌────────┐
│ ảnh    │ │ ảnh    │ │ ảnh    │
│ Ức gà phi lê  khay 500 g     │
│ 55.000đ   Còn 98   ⚠ Chứa: cá │      ← nhãn dị ứng khớp hồ sơ
│ [−1+] [Thêm vào giỏ]         │
└────────┘
```

**A5.10 Danh sách mua sắm** (từ công thức hoặc thực đơn)
```
Danh sách mua sắm cho: ✓ Cá diêu hồng hấp (4 khẩu phần)  ✓ Cơm gạo lứt ức gà (2 khẩu phần)     [+ Thêm món]
Nguyên liệu đã có ở nhà: ☐ Dầu ô liu  ☐ Muối  ☐ Tiêu          (tick → tự trừ khỏi lượng cần mua)
─ Thịt - cá ──────────────────────────────────────────────────
 Cá diêu hồng   cần 900 g   → Cá diêu hồng làm sạch (con ~500 g) × 2          120.000đ
 Ức gà          cần 300 g   → Ức gà phi lê (khay 500 g) × 1                    55.000đ
─ Gia vị ─────────────────────────────────────────────────────
 Gừng           cần 58 g    → Gừng (túi 100 g) × 1                              8.000đ
 Nước mắm       cần 8 g     → Nước mắm (chai 500 ml) × 1     ⚠ Chứa cá         35.000đ
 Nước tương     …           ⛔ Hết hàng — gợi ý thay thế
 Nguyên liệu chưa có sản phẩm: (liệt kê để người dùng tự mua)
──────────────────────────────────────────────────────────────
Tạm tính: 385.000đ                    [ 🛒 Thêm tất cả vào giỏ ]
```

**A5.11 Giỏ hàng & Checkout**
```
GIỎ (drawer / trang)                         CHECKOUT (3 bước)
 [ảnh] Gừng  túi 100 g  [−1+]  8.000đ  🗑     1 Địa chỉ giao   (○ Nhà · ○ Cơ quan · + Thêm)
 …                                            2 Thanh toán     ○ COD   ○ VNPay
 Tạm tính 385.000đ                            3 Mã giảm giá [WELCOME10][Áp dụng]  Ghi chú [        ]
 [ Thanh toán ]                              ┌ Tóm tắt ───────────────┐
                                             │ Tạm tính     385.000đ │
 ⚠ Dị ứng: 1 sản phẩm chứa cá → xác nhận      │ Phí ship      20.000đ │
                                             │ Giảm giá     −38.500đ │
                                             │ Tổng        366.500đ  │
                                             │ [ Đặt hàng ]          │
                                             └───────────────────────┘
```

**A5.12 Đơn hàng**
```
Đơn NC100123 · 19/10/2026 · 366.500đ · COD            [Mua lại] [Hủy đơn*]   (*chỉ khi chờ xử lý/đã xác nhận)
●──────●──────●──────○──────○
Đã đặt  Xác nhận  Chuẩn bị  Đang giao  Đã giao       ← cập nhật realtime
Sản phẩm · Địa chỉ · Thanh toán · Mã vận đơn · Lịch sử trạng thái
VNPay chờ thanh toán: đếm ngược 15:00 [Thanh toán lại]
```

**A5.13 Admin — Sản phẩm & Đơn hàng**
```
Sản phẩm: bảng [Ảnh][SKU][Tên][Nguyên liệu gắn][Quy cách (g)][Giá][Tồn][Giữ chỗ][Bật/tắt]  — sửa nhanh tại dòng
Đơn hàng: tab [Chờ xử lý][Đã xác nhận][Chuẩn bị][Đang giao][Đã giao][Đã hủy][Cần hoàn tiền]
  Chi tiết: danh sách hàng · địa chỉ · thanh toán · [Xác nhận] [Chuẩn bị] [Giao + mã vận đơn] [Đã giao] [Hủy] [Đã hoàn tiền]
  Chỉ hiện nút chuyển trạng thái hợp lệ theo máy trạng thái.
```

### A6. Trạng thái & vi tương tác
Loading = skeleton; empty có CTA; lỗi thân thiện + thử lại; optimistic UI cho ♥/👍; toast 4 s; dialog xác nhận hành động phá hủy; chuyển cảnh ≤ 200 ms, tôn trọng `prefers-reduced-motion`.

### A7. Giọng văn
Thân thiện, không phán xét cân nặng ("mục tiêu sức khỏe", tránh "béo/gầy"). Nhãn AI rõ ràng; không hứa chữa bệnh. Định dạng `vi-VN`: `1.234`, `dd/MM/yyyy`, kcal/g/mg.

### A8. Truy cập (WCAG 2.1 AA)
Tương phản ≥ 4,5:1; focus ring rõ; điều hướng bàn phím đầy đủ; kéo-thả có nút thay thế; `alt` cho ảnh; `aria-live="polite"` khi đổi khẩu phần/timer; timer có thông báo âm thanh **và** hình ảnh; mức lửa/nhãn an toàn có icon + chữ; "Chữ lớn" lưu ở `localStorage`.

---

## PHẦN B — FRONTEND

### B1. Cấu trúc `apps/web/src`
```
app/        App.tsx · router.tsx · providers.tsx · layouts/{Public,App,Admin}Layout.tsx
features/
  auth/       AuthProvider · useAuth · guards · Login/Register/Forgot/Reset/Callback
  profile/    OnboardingWizard · steps/* · AccountPage · EaterPicker · useProfile
  recipes/    RecipeListPage · RecipeDetailPage · CookModePage · components/* · hooks/*
  ai/         AiPage · AiSuggestForm · AiRecipeCard · useAiSuggest · useFeedback
  recommend/  ForYouPage · useRecommendations
  mealplan/   MealPlanPage · PlanGrid · useMealPlan
  journal/    JournalPage (P1)
  shop/       ShopPage · ProductPage · ShoppingListPage · hooks/{useProducts,useShoppingList}
  cart/       CartDrawer · CartPage · hooks/useCart · guestCart.ts
  checkout/   CheckoutPage · AddressForm · PaymentMethodSelect · hooks/{useQuote,useCheckout}
  orders/     OrdersPage · OrderDetailPage · OrderTimeline · hooks/{useOrders,useOrderRealtime}
  admin/      Recipes/RecipeEditor/* · Ingredients · Rules · Users · AiStats · Products · Orders · Coupons · Shipping
components/ui/ (shadcn) · components/shared/ (NutritionFacts, MacroRing, VerdictBadge, Timer, Disclaimers…)
lib/  supabase.ts · rpc.ts · format.ts · wakeLock.ts · analytics.ts
stores/ uiStore.ts (chữ lớn, timers đang chạy)
types/ database.ts (sinh tự động) · domain.ts
i18n/ vi.json
```

### B2. Router (rút gọn)
```tsx
export const router = createBrowserRouter([
  { element: <PublicLayout/>, children: [
    { path:'/', element:<HomePage/> }, { path:'/recipes', element:<RecipeListPage/> },
    { path:'/recipes/:slug', element:<RecipeDetailPage/> },
    { path:'/login', element:<LoginPage/> }, { path:'/register', element:<RegisterPage/> },
    { path:'/forgot-password', element:<ForgotPage/> }, { path:'/reset-password', element:<ResetPage/> },
    { path:'/auth/callback', element:<AuthCallback/> } ]},
  { element:<ProtectedRoute><AppLayout/></ProtectedRoute>, children: [
    { path:'/onboarding', element:<OnboardingWizard/> },
    { element:<RequireOnboarding/>, children: [
      { path:'/dashboard', element:<DashboardPage/> }, { path:'/ai', element:<AiPage/> },
      { path:'/for-you', element:<ForYouPage/> }, { path:'/recipes/:slug/cook', element:<CookModePage/> },
      { path:'/meal-plan', element:<MealPlanPage/> }, { path:'/favorites', element:<FavoritesPage/> },
      { path:'/shop', element:<ShopPage/> }, { path:'/shop/:slug', element:<ProductPage/> },
      { path:'/shopping-list', element:<ShoppingListPage/> }, { path:'/cart', element:<CartPage/> },
      { path:'/checkout', element:<CheckoutPage/> }, { path:'/orders', element:<OrdersPage/> },
      { path:'/orders/:id', element:<OrderDetailPage/> }, { path:'/account', element:<AccountPage/> } ]}]},
  { path:'/admin', element:<RoleRoute roles={['admin','nutritionist','staff']}><AdminLayout/></RoleRoute>, children:[ /* … */ ] },
]);
```

### B3. Supabase client & Auth (đăng ký / đăng nhập / đăng xuất)
```ts
// lib/supabase.ts
export const supabase = createClient<Database>(
  import.meta.env.VITE_SUPABASE_URL, import.meta.env.VITE_SUPABASE_ANON_KEY,
  { auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true, flowType: 'pkce' } });
```
```tsx
// features/auth/AuthProvider.tsx (rút gọn)
useEffect(() => {
  supabase.auth.getSession().then(async ({ data }) => { setUser(data.session?.user ?? null);
    if (data.session?.user) await loadProfile(data.session.user.id); setLoading(false); });
  const { data: sub } = supabase.auth.onAuthStateChange((_e, s) => {
    setUser(s?.user ?? null);
    if (s?.user) setTimeout(() => loadProfile(s.user.id), 0);   // tránh deadlock trong callback
    else { setProfile(null); queryClient.clear(); } });
  return () => sub.subscription.unsubscribe();
}, []);
const signUp  = (email, password, full_name) => supabase.auth.signUp({ email, password,
  options: { data: { full_name }, emailRedirectTo: `${location.origin}/auth/callback` } });
const signIn  = (email, password) => supabase.auth.signInWithPassword({ email, password });
const signInGoogle = () => supabase.auth.signInWithOAuth({ provider: 'google', options: { redirectTo: `${location.origin}/auth/callback` } });
const signOut = async () => { await supabase.auth.signOut(); queryClient.clear(); };
```
Guards: `ProtectedRoute` (chưa đăng nhập → `/login`), `RequireOnboarding` (chưa xong → `/onboarding`), `RoleRoute`.

### B4. Gọi RPC & Edge Function
```ts
// lib/rpc.ts
export async function rpc<T>(fn: string, args?: Record<string, unknown>): Promise<T> {
  const { data, error } = await supabase.rpc(fn, args); if (error) throw mapPgError(error); return data as T;
}
export async function edge<T>(name: string, body?: unknown): Promise<T> {
  const { data, error } = await supabase.functions.invoke(name, { body });
  if (error) { const ctx = await (error as any).context?.json?.().catch(() => null); throw new AppError(ctx?.error?.code ?? 'UNKNOWN', ctx?.error?.message ?? 'Có lỗi xảy ra'); }
  return data as T;
}
// Bảng ánh xạ lỗi → tiếng Việt: CONSENT_REQUIRED, AI_CONSENT_REQUIRED, RATE_LIMITED, PLAN_NOT_ALLOWED, NEED_PREP_STEP…
```

### B5. Công thức
```ts
// Danh sách + tìm kiếm: dùng cùng RPC với gợi ý (đã lọc theo hồ sơ)
export const useRecipes = (f: Filters) => useInfiniteQuery({
  queryKey: ['recipes', f],
  queryFn: ({ pageParam = 0 }) => rpc<RecipeCard[]>('rpc_recommend_recipes', {
    p_q: f.q || null, p_meal: f.meal ?? null, p_max_minutes: f.maxMinutes ?? null,
    p_cuisines: f.cuisines?.length ? f.cuisines : null, p_methods: f.methods?.length ? f.methods : null,
    p_include_avoid: !f.onlyForMe, p_limit: 12, p_offset: pageParam }),
  getNextPageParam: (last, all) => last.length === 12 ? all.length * 12 : undefined, initialPageParam: 0 });

// Chi tiết: công thức + nguyên liệu + bước
export const useRecipe = (slug: string) => useQuery({ queryKey: ['recipe', slug], queryFn: async () => {
  const { data: r } = await supabase.from('recipes').select('*').eq('slug', slug).single();
  const [steps, scaled] = await Promise.all([
    supabase.from('recipe_steps').select('*').eq('recipe_id', r.id).order('step_no'),
    rpc<Scaled>('rpc_scale_recipe', { p_recipe: r.id, p_servings: r.base_servings })]);
  return { recipe: r, steps: steps.data!, scaled }; } });

// Đổi khẩu phần → gọi lại RPC (debounce 250 ms), giữ dữ liệu cũ khi đang tải
export const useScaled = (id: string, servings: number) => useQuery({
  queryKey: ['scaled', id, servings], queryFn: () => rpc<Scaled>('rpc_scale_recipe', { p_recipe: id, p_servings: servings }),
  placeholderData: keepPreviousData });
```
Trang chi tiết nhận `?servings=4` (từ AI: `scale_factor × base_servings`) để mở sẵn đúng khẩu phần.

### B6. Chế độ nấu
- Trạng thái: `stepIndex`, danh sách timer `{stepNo, endsAt}` (lưu `endsAt` thay vì đếm lùi để không trôi khi tab nền) trong Zustand; khôi phục khi tải lại trang.
- **Wake Lock:** `navigator.wakeLock.request('screen')`, xin lại khi tab hiện lại; nếu không hỗ trợ → hiển thị gợi ý "giữ màn hình sáng".
- Hết giờ: `Notification` (nếu cho phép) + âm báo + rung (`navigator.vibrate`) + banner trong trang.
- Màn "Chuẩn bị": tick dụng cụ & nguyên liệu (`IngredientGroups` dạng checklist).
- Cuối: gọi `recipe_feedback` upsert `reaction='cooked'`.

### B7. AI gợi ý
```ts
const AiInput = z.object({
  meal: z.enum(['breakfast','lunch','dinner','snack']).optional(),
  eaters: z.array(z.object({ group: z.enum(['child','teen','adult','senior']), count: z.number().int().min(1).max(10) })).min(1),
  servings: z.number().min(1).max(12),
  tastes: z.array(z.string()).max(4), spice: z.number().int().min(0).max(3).optional(),
  cuisines: z.array(z.string()).max(3), methods: z.array(z.string()).max(5),
  maxMinutes: z.number().int().min(5).max(240).optional(),
  haveIngredients: z.array(z.string().max(40)).max(15), avoidIngredients: z.array(z.string().max(40)).max(15),
  note: z.string().max(300).optional(), count: z.number().int().min(1).max(8).default(5) });

export const useAiSuggest = () => useMutation({
  mutationFn: (v: z.infer<typeof AiInput>) => edge<AiResponse>('ai-suggest', v) });
```
- Mặc định form lấy từ hồ sơ (`household`, `default_servings`, `spice_level`, `taste_prefs`, `preferred_cuisines`, `favorite_methods`, `max_cook_minutes`); lưu "lần chọn gần nhất" vào `sessionStorage`.
- Lỗi `AI_CONSENT_REQUIRED` → mở hộp thoại đồng ý (ghi `profiles.ai_consent_at = now()`); `RATE_LIMITED` → thông báo + gợi ý dùng `/for-you`.
- `fallback === true` → hiện nhãn "Gợi ý theo hồ sơ (AI tạm thời không khả dụng)".
- Nhấn 👍/👎: upsert `recipe_feedback` (xóa phản hồi đối nghịch); 👎 mở chọn lý do nhanh ("quá mặn", "khó làm", "không hợp khẩu vị", "tốn thời gian", khác…).
- Không bao giờ hiển thị `reason` bằng `dangerouslySetInnerHTML`; luôn render text.
- **Không** gọi API Anthropic từ trình duyệt.

### B8. Onboarding & hồ sơ
Wizard `useReducer` + lưu nháp `sessionStorage`; mỗi bước có schema Zod. Kết thúc: `update profiles …` + upsert `user_health_conditions`, `user_allergies` → `rpc('rpc_compute_targets')` → `refreshProfile()` → `/dashboard`. `household` lưu dạng `[{group,count}]`. Nhóm đỏ: `RedTierNotice`, ẩn nút tạo thực đơn tự động, **vẫn** cho xem công thức và dùng AI ở chế độ "ăn đủ chất".

### B9. Thực đơn
`rpc('rpc_generate_meal_plan', { p_start, p_days })` → đọc `meal_plans` + `meal_plan_items` + công thức; kéo-thả bằng dnd-kit, ghi `meal_plan_items` (RLS), tính lại tổng ngày ở client; có menu "Chuyển sang…" thay kéo-thả.

### B9b. Danh sách mua sắm, giỏ hàng, đặt hàng
```ts
// Danh sách mua sắm từ nhiều công thức (khẩu phần do người dùng chọn)
export const useShoppingList = (items: { recipe_id: string; servings: number }[]) => useQuery({
  queryKey: ['shopping-list', items], enabled: items.length > 0,
  queryFn: () => rpc<ShoppingLine[]>('rpc_shopping_list', { p_items: items }), placeholderData: keepPreviousData });

// Thêm tất cả vào giỏ (server tự cộng dồn, bỏ mục hết hàng, trả cảnh báo dị ứng)
export const useAddListToCart = () => { const qc = useQueryClient(); return useMutation({
  mutationFn: (items: ListItem[]) => rpc<{ added: number; skipped: number; allergen_flags: string[] }>('rpc_cart_add_from_recipes', { p_items: items }),
  onSuccess: () => qc.invalidateQueries({ queryKey: ['cart'] }) }); };

// Giỏ hàng (DB, theo RLS)
export const useCart = () => useQuery({ queryKey: ['cart'], queryFn: async () =>
  (await supabase.from('cart_items').select('qty, product:products(id,name,image_url,unit,price_vnd,stock,reserved,allergen_ids)')).data ?? [] });
export const useSetQty = () => useMutation({ mutationFn: async ({ productId, qty }: { productId: string; qty: number }) => {
  const cartId = await rpc<string>('rpc_ensure_cart');
  const q = qty <= 0 ? supabase.from('cart_items').delete().match({ cart_id: cartId, product_id: productId })
                     : supabase.from('cart_items').upsert({ cart_id: cartId, product_id: productId, qty });
  const { error } = await q; if (error) throw error; } });

// Báo giá & đặt hàng
export const useQuote = (province?: string, coupon?: string) => useQuery({ queryKey: ['quote', province, coupon], enabled: !!province,
  queryFn: () => rpc<Quote>('rpc_quote_order', { p_province: province, p_coupon: coupon || null }) });

export async function checkout(i: { addressId: string; method: 'cod' | 'vnpay'; coupon?: string; note?: string }) {
  const o = await rpc<{ order_id: string; code: string; total_vnd: number }>('rpc_place_order',
    { p_address_id: i.addressId, p_method: i.method, p_coupon: i.coupon ?? null, p_note: i.note ?? null });
  if (i.method === 'vnpay') {                           // thanh toán online
    const { payUrl } = await edge<{ payUrl: string }>('vnpay-create', { orderId: o.order_id });
    location.href = payUrl; return;
  }
  navigate(`/orders/${o.order_id}?placed=1`);
}
export const cancelOrder = (id: string) => rpc('rpc_cancel_order', { p_order: id });

// Theo dõi đơn theo thời gian thực
supabase.channel('my-orders')
  .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'orders', filter: `user_id=eq.${user.id}` },
      () => queryClient.invalidateQueries({ queryKey: ['orders'] }))
  .subscribe();
```
- **Giỏ khách chưa đăng nhập:** giữ trong Zustand (`persist`); sau đăng nhập, gộp vào DB bằng `setQty`.
- **Cảnh báo dị ứng:** nếu `product.allergen_ids ∩ allergens người dùng ≠ ∅` → `AllergyConfirmDialog` trước khi thêm; `rpc_cart_add_from_recipes` trả `allergen_flags` để hiển thị.
- **Trang kết quả VNPay:** chỉ **đọc** `orders.payment_status` (Realtime hoặc poll 3 s, tối đa 60 s); **không** tin tham số URL.
- **Lỗi RPC cần ánh xạ sang tiếng Việt:** `OUT_OF_STOCK:<tên>` ("<tên> không đủ hàng"), `PRODUCT_INACTIVE`, `COUPON_INVALID`, `EMPTY_CART`, `ADDRESS_NOT_FOUND`, `CANNOT_CANCEL`, `HAS_ACTIVE_ORDERS`.
- **Admin đơn hàng:** `rpc('rpc_set_order_status', { p_order, p_to, p_note, p_tracking, p_carrier })`; chỉ hiện nút cho chuyển trạng thái hợp lệ; `rpc('rpc_mark_refunded')` sau khi hoàn tiền thực tế.

### B10. Admin — soạn công thức
Form chia tab, lưu nháp tự động; sau mỗi thay đổi nguyên liệu, đọc lại cột dinh dưỡng đã **tự tính** để xem trước; nút "Xuất bản" gọi `update recipes set status='published'` và hiển thị lỗi từ trigger (`NEED_PREP_STEP`, `NEED_4_STEPS`, `STEP_TOO_SHORT`, `NEED_IMAGE`, `NEED_EQUIPMENT`, `FORBIDDEN`…) bằng tiếng Việt. Tải ảnh lên bucket `recipe-images` (WebP, ≤ 2 MB).

### B11. SEO & hiệu năng
`react-helmet-async` (title/description/OG); **JSON-LD `Recipe`** gồm `recipeIngredient`, `recipeInstructions` (HowToStep có `name`, `text`), `prepTime`, `cookTime`, `totalTime`, `recipeYield`, `nutrition`; prerender trang công thức khi build + `sitemap.xml`; ảnh WebP lazy, `width/height` cố định; chia mã theo route (tách admin, recharts); mục tiêu JS đầu < 180 KB gzip, LCP < 2,5 s.

### B12. Lỗi & an toàn
`ErrorBoundary` theo route; Sentry loại dữ liệu sức khỏe; không log token/hồ sơ; map mã lỗi sang tiếng Việt; hiển thị `MedicalDisclaimer` ở onboarding, chi tiết công thức, thực đơn và `AiDisclaimer` ở `/ai`.

### B13. Kiểm thử frontend
| Loại | Gợi ý |
|---|---|
| Component | `StepCard`, `StepTimer`, `IngredientGroups`, `VerdictBadge`, `EaterPicker`, `AiRecipeCard` |
| Hook | `useScaled` (đổi khẩu phần), `useAiSuggest` (mock lỗi `RATE_LIMITED`, `fallback`) |
| E2E | đăng ký → onboarding → `/ai` → mở công thức `?servings=4` → chế độ nấu → danh sách mua sắm → giỏ → checkout COD → xem đơn → đăng xuất |
| An toàn | Hồ sơ dị ứng cá: `/recipes` và `/ai` không có món cá; truy cập trực tiếp món cá → `AllergyAlert` |
| A11y | `@axe-core/playwright`; timer có thông báo không chỉ bằng âm thanh |

### B14. Definition of Done (Frontend)
- [ ] Responsive 360 → 1440 px, không cuộn ngang; chế độ nấu dùng được một tay.
- [ ] Đủ loading/empty/error; trạng thái AI (consent, rate limit, fallback).
- [ ] Axe không có lỗi serious/critical; mọi chuỗi qua i18n.
- [ ] `tsc --noEmit`, ESLint sạch; test logic mới; E2E luồng chính xanh.
- [ ] `grep -r "service_role\|sk-ant\|ANTHROPIC\|VNP_HASH" apps/web` rỗng.
- [ ] Đặt hàng: hiển thị báo giá trước khi đặt; xử lý đủ lỗi hết hàng/mã giảm giá; cảnh báo dị ứng; không dựa vào tham số URL để xác nhận thanh toán.
- [ ] `MedicalDisclaimer`/`AiDisclaimer` hiển thị đúng chỗ.

---

## PHẦN C — THỨ TỰ XÂY DỰNG UI
1. Vite + Tailwind + shadcn + router + AuthProvider.
2. Trang Auth (đăng ký, đăng nhập, **đăng xuất**, quên mật khẩu, Google).
3. Onboarding (6 bước) + `rpc_compute_targets`.
4. Thư viện công thức + `RecipeCard` + `VerdictBadge`.
5. Trang chi tiết công thức đầy đủ + scale khẩu phần.
6. Chế độ nấu (timer, Wake Lock, hoàn thành + phản hồi).
7. Trang AI `/ai` + consent + phản hồi.
8. Thực đơn tuần.
9. **Cửa hàng + danh sách mua sắm + giỏ hàng.**
10. **Checkout (COD) → đơn hàng + theo dõi realtime → VNPay.**
11. Admin: soạn công thức + duyệt; **sản phẩm, đơn hàng, mã giảm giá**.
12. SEO/JSON-LD, a11y, hiệu năng, E2E, go-live.
