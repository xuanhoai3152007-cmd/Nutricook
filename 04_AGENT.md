# 04 — AGENT.md (Hướng dẫn cho AI coding agent)
## Dự án: NutriCook — đặt tên file khi dùng thật: `AGENTS.md` (gốc repo) hoặc `CLAUDE.md`

> Tệp này dành cho AI agent (Claude Code, Cursor, Copilot, Codex...) và cho lập trình viên mới. **Đọc hết trước khi viết code.**
> Tài liệu liên quan: `01_PRD_NGHIEP_VU.md` (cái gì & vì sao) · `02_KY_THUAT.md` (kiến trúc, DB, API) · `03_GIAO_DIEN_FRONTEND.md` (UI & FE).

---

## 1. SỨ MỆNH & NGỮ CẢNH
Xây dựng **NutriCook**: web app công thức nấu ăn & thực đơn theo chế độ dinh dưỡng/tình trạng sức khỏe, có tài khoản (đăng ký/đăng nhập/đăng xuất), giỏ hàng và đặt nguyên liệu.

- **Stack:** React 18 + Vite + TypeScript · Supabase (Postgres/Auth/Storage/RLS) · Node.js 20 trên Vercel Functions · Vercel hosting.
- **Ngôn ngữ giao diện:** tiếng Việt (`vi-VN`); code, tên biến, commit: tiếng Anh.
- **Tiền tệ:** VND, lưu số nguyên (`bigint`). **Múi giờ:** `Asia/Ho_Chi_Minh`.
- **Nguồn sự thật:** PRD (nghiệp vụ) > Kỹ thuật (thiết kế) > Frontend (UI). Nếu mâu thuẫn → **dừng lại và hỏi**, không tự đoán.

---

## 2. QUY TẮC BẤT BIẾN (KHÔNG ĐƯỢC VI PHẠM)

### 2.1 An toàn sức khỏe (ưu tiên cao nhất)
1. **Không bao giờ** đưa ra gợi ý/thực đơn chứa chất người dùng đã khai dị ứng. Lọc cứng ở **cả** SQL và `evaluateRecipe`; có test property-based.
2. Người dùng thuộc **nhóm đỏ** (bệnh thận mạn, mang thai/cho con bú, < 18 tuổi, BMI < 18.5, tiền sử rối loạn ăn uống) → **không tự động tạo thực đơn giảm cân**; trả `403 PLAN_NOT_ALLOWED` và nội dung chung + khuyên gặp chuyên gia.
3. Sàn năng lượng: **Nữ ≥ 1.200 kcal, Nam ≥ 1.500 kcal**. Không cho mục tiêu làm BMI < 18.5.
4. **Không chẩn đoán, không kê đơn.** Mọi nội dung sức khỏe kèm `MedicalDisclaimer`.
5. Quy tắc bệnh lý nằm trong bảng `condition_rules` (dữ liệu), **không hard-code** ngưỡng trong component/route. Chỉ dùng quy tắc có `approved_by` khi chạy production.
6. Không bịa số liệu dinh dưỡng. Nguyên liệu/công thức phải có `source`. Thiếu dữ liệu → để `null` và báo, không tự điền.

### 2.2 Bảo mật
1. `SUPABASE_SERVICE_ROLE_KEY`, `VNP_HASH_SECRET`, `RESEND_API_KEY` **chỉ** ở server (`/api`, biến môi trường Vercel). **Cấm** đưa vào `apps/web` hoặc biến `VITE_*`. Kiểm tra: `grep -r "service_role" apps/web` phải rỗng.
2. **Mọi bảng bật RLS**, mặc định từ chối. Khi tạo bảng mới → viết policy + test pgTAP trong cùng PR.
3. Khách **không** được ghi trực tiếp `orders`, `order_items`, `payments`, `products.stock`. Mọi thay đổi tiền/kho/trạng thái đơn qua server.
4. Webhook thanh toán: kiểm chữ ký + số tiền + mã đơn, **idempotent**; không tin redirect trình duyệt.
5. Server dùng `supabase.auth.getUser(token)` để xác thực, không tin `getSession()` ở server. Kiểm quyền sở hữu tài nguyên mọi endpoint.
6. Validate đầu vào bằng **Zod** ở mọi endpoint. Không nối chuỗi SQL; dùng tham số/RPC.
7. Không log token, mật khẩu, hồ sơ sức khỏe; Sentry/analytics phải scrub PII.
8. Không dùng `dangerouslySetInnerHTML` với dữ liệu người dùng.
9. Hàm `security definer` luôn `set search_path = public`.

### 2.3 Chất lượng code
1. TypeScript `strict`; cấm `any` trừ khi có comment lý do; không `// @ts-ignore` tùy tiện.
2. Logic nghiệp vụ thuần (tính toán, lọc, chấm điểm) đặt trong `packages/nutrition-core`, **không** phụ thuộc React/DOM/Supabase → dễ test.
3. Mỗi thay đổi hành vi phải có test. Không giảm độ phủ của `nutrition-core` dưới 90%.
4. Không sửa migration đã áp dụng; luôn tạo migration mới (`supabase migration new <name>`).
5. Component ≤ ~200 dòng; tách hook khi logic dữ liệu phức tạp.
6. Không thêm thư viện mới khi chưa cần; nếu thêm, nêu lý do + kích thước bundle.
7. Chuỗi UI qua i18n (`vi.json`); không hard-code tiếng Việt trong JSX (trừ prototype).
8. Truy cập: nhãn form, `alt`, focus, tương phản (xem tài liệu 03, mục A8).

---

## 3. LỆNH THƯỜNG DÙNG
```bash
pnpm install                         # cài phụ thuộc (pnpm workspaces)
pnpm dev                             # chạy web (Vite) ở :5173
vercel dev                           # chạy web + /api cục bộ (cần Vercel CLI)
supabase start                       # DB/Auth/Storage cục bộ (Docker)
supabase db reset                    # chạy lại migrations + seed
supabase migration new <name>        # tạo migration mới
supabase gen types typescript --local > apps/web/src/types/database.ts
supabase test db                     # chạy pgTAP (RLS)
pnpm lint && pnpm typecheck          # ESLint + tsc
pnpm --filter nutrition-core test    # unit test lõi dinh dưỡng
pnpm --filter web test               # test component/hook
pnpm e2e                             # Playwright
pnpm --filter web build              # build production
```

---

## 4. QUY TRÌNH LÀM VIỆC CỦA AGENT
Với **mỗi** nhiệm vụ:
1. **Đọc**: xác định mục liên quan trong PRD (mã yêu cầu như `B3`, `F6`), kỹ thuật, UI.
2. **Lập kế hoạch ngắn** (≤ 10 dòng): file sẽ tạo/sửa, migration, test.
3. **Làm từng lát nhỏ** (vertical slice: DB → API → UI → test), commit nhỏ.
4. **Tự kiểm**: `lint`, `typecheck`, test liên quan, chạy thử trên trình duyệt.
5. **Báo cáo**: tóm tắt đã làm, file thay đổi, cách kiểm thử, rủi ro/việc còn lại.
6. **Hỏi lại** khi: thiếu quy tắc nghiệp vụ, mâu thuẫn tài liệu, hành động phá hủy dữ liệu, thay đổi quy tắc y khoa.

**Không tự ý:** đổi schema đã chạy production, xóa dữ liệu, tắt RLS, nới ngưỡng an toàn, thêm dịch vụ trả phí.

### 4.1 Quy ước Git
- Nhánh: `feat/<module>-<mô-tả>`, `fix/…`, `chore/…`.
- Commit (Conventional Commits): `feat(cart): add allergy confirm dialog`.
- PR phải có: mô tả, mã yêu cầu PRD, ảnh/GIF UI, checklist DoD (mục 8).

### 4.2 Đặt tên
| Đối tượng | Quy ước |
|---|---|
| Bảng/cột DB | `snake_case`, số nhiều cho bảng |
| File React component | `PascalCase.tsx` |
| Hook | `useXxx.ts` |
| Hàm/biến | `camelCase` |
| Hằng số | `UPPER_SNAKE_CASE` |
| Endpoint | `kebab-case`, REST |
| Mã lỗi API | `UPPER_SNAKE_CASE` (`OUT_OF_STOCK`) |

---

## 5. LỘ TRÌNH TRIỂN KHAI — DANH SÁCH TASK CHO AGENT

> Đánh dấu `[x]` khi xong. Mỗi task kèm **mã yêu cầu PRD** và **tiêu chí xong**.

### Phase 0 — Khởi tạo (Tuần 1)
- [ ] **T0.1** Tạo monorepo pnpm: `apps/web`, `api`, `packages/nutrition-core`, `supabase`. *Xong khi:* `pnpm dev` chạy, CI xanh.
- [ ] **T0.2** Vite + React + TS + Tailwind + shadcn/ui + ESLint/Prettier/Husky. Cấu hình token (tài liệu 03, A2).
- [ ] **T0.3** Supabase local + migrations 0001–0006 (tài liệu 02, mục 5). *Xong khi:* `supabase db reset` không lỗi.
- [ ] **T0.4** RLS (mục 5.4) + pgTAP cơ bản. *Xong khi:* test "A không đọc dữ liệu B" xanh.
- [ ] **T0.5** Vercel project + biến môi trường + `vercel.json`; deploy "Hello" + `/api/health`.
- [ ] **T0.6** GitHub Actions CI (lint, typecheck, test, build, `supabase test db`).

### Phase 1 — Tài khoản (Tuần 2) — PRD A1–A7
- [ ] **T1.1** `AuthProvider`, `useAuth`, `ProtectedRoute`, `RoleRoute`.
- [ ] **T1.2** Trang đăng ký (xác thực email), đăng nhập, **đăng xuất**, quên/đặt lại mật khẩu, Google OAuth, `/auth/callback`.
- [ ] **T1.3** Trigger `handle_new_user`; trang `/account` (sửa hồ sơ, đổi mật khẩu, địa chỉ).
- [ ] **T1.4** `DELETE /api/account` + `GET /api/account/export`.
- [ ] **T1.5** E2E: đăng ký → đăng nhập → đăng xuất → bị chặn khi vào route bảo vệ.

### Phase 2 — Lõi dinh dưỡng & Onboarding (Tuần 3) — PRD B1–B9, mục 5.1–5.4
- [ ] **T2.1** `nutrition-core`: `computeTargets`, `mergeRules`, `scaleRecipe`, `evaluateRecipe` + **golden tests** (nữ 30t 60kg 165cm light → BMR 1320,25; TDEE ≈ 1815,3).
- [ ] **T2.2** Seed `allergens`, `health_conditions`, `condition_rules` (v1, chưa duyệt).
- [ ] **T2.3** `POST /api/profile/compute` + lưu `risk_tier`, consent.
- [ ] **T2.4** `OnboardingWizard` 5 bước + màn hình kết quả + `RedTierNotice`.
- [ ] **T2.5** Property test: 10.000 hồ sơ ngẫu nhiên → 0 vi phạm sàn kcal & 0 allergen lọt qua.

### Phase 3 — Công thức (Tuần 4–5) — PRD C1–C6, H1–H3
- [ ] **T3.1** Seed ~300 nguyên liệu (có `source`) + 50 công thức; trigger `recompute_recipe_nutrition`.
- [ ] **T3.2** `RecipeListPage` (tìm kiếm không dấu, lọc, vô hạn) + `RecipeCard`.
- [ ] **T3.3** `RecipeDetailPage`: tabs, scale khẩu phần, `NutritionFacts`, ♥ yêu thích, JSON-LD.
- [ ] **T3.4** `GET /api/recommendations` + `VerdictBadge` + "Vì sao gợi ý".
- [ ] **T3.5** Admin CRUD công thức/nguyên liệu + quy trình `draft→review→published` + upload ảnh.

### Phase 4 — Thực đơn & Mua sắm (Tuần 6) — PRD E1–E6
- [ ] **T4.1** `generateMealPlan` trong `nutrition-core` (mục 6.5 tài liệu 02) + test (±5% kcal, không lặp 3 ngày).
- [ ] **T4.2** `POST /api/mealplan/generate`, `/swap`; `MealPlanPage` (kéo-thả dnd-kit + nút thay thế).
- [ ] **T4.3** `buildShoppingList` + `POST /api/shopping-list` + `ShoppingListPage`.

### Phase 5 — Cửa hàng & Đặt hàng (Tuần 7–8) — PRD F1–F10
- [ ] **T5.1** Seed sản phẩm; `ShopPage`, `ProductPage`.
- [ ] **T5.2** Giỏ hàng (DB + hợp nhất giỏ khách), `CartDrawer`, `AllergyAlert`.
- [ ] **T5.3** `place_order` (SQL) + `POST /api/checkout` + trang `CheckoutPage` (COD).
- [ ] **T5.4** VNPay sandbox: `create`, `ipn` (verify HMAC-SHA512, idempotent), `return`; job hủy đơn quá hạn.
- [ ] **T5.5** `OrdersPage`, `OrderDetailPage`, hủy đơn, mua lại; email xác nhận (Resend).
- [ ] **T5.6** Admin đơn hàng: máy trạng thái, nhật ký trạng thái, mã vận đơn.
- [ ] **T5.7** Test: tranh chấp tồn kho (2 đơn cùng lúc), webhook giả mạo, khách không sửa được `orders`.

### Phase 6 — Hoàn thiện MVP (Tuần 8)
- [ ] **T6.1** SEO (Helmet, sitemap, prerender), tối ưu ảnh/bundle, Lighthouse ≥ 85/90.
- [ ] **T6.2** Trang pháp lý, "Nguồn & Phương pháp", Sentry, analytics (không PII).
- [ ] **T6.3** Rà soát bảo mật (mục 9), UAT theo tiêu chí nghiệm thu PRD mục 11.
- [ ] **T6.4** Go-live: domain, Supabase prod, VNPay production, backup.

### Phase 7+ (P1/P2) — theo PRD mục 3.2–3.3
Nhật ký ăn uống & biểu đồ; suất ăn nấu sẵn; đánh giá; thông báo; thay thế nguyên liệu; mã giảm giá; trợ lý AI (mục 7).

---

## 6. MẪU PROMPT CHO AGENT (copy–dán)

**Khởi động dự án**
```
Đọc AGENTS.md và 4 tài liệu trong /docs. Thực hiện Phase 0 (T0.1–T0.6).
Làm theo từng task, chạy lint/test sau mỗi task, tóm tắt kết quả. Hỏi tôi nếu thiếu thông tin.
```
**Một tính năng**
```
Thực hiện T2.1 (nutrition-core). Tham chiếu PRD mục 5.1–5.4 và kỹ thuật mục 6.
Viết test trước (golden + property-based). Không hard-code ngưỡng bệnh lý; đọc từ condition_rules.
```
**Migration an toàn**
```
Tạo migration thêm bảng <X>. Bắt buộc: RLS bật, policy theo mô hình tài liệu 02 mục 5.4,
test pgTAP, cập nhật types (supabase gen types). Không sửa migration cũ.
```
**Review bảo mật**
```
Rà soát PR theo AGENTS.md mục 2.2 và 9. Liệt kê vi phạm theo mức Critical/High/Medium kèm cách sửa.
```
**Sửa lỗi**
```
Tái hiện lỗi <mô tả>, viết test thất bại trước, sửa nguyên nhân gốc, chạy toàn bộ test liên quan, báo cáo.
```

---

## 7. (PHASE 2) TRỢ LÝ AI DINH DƯỠNG — ĐẶC TẢ
> Tính năng tùy chọn, **chỉ** triển khai sau MVP. Dùng Claude API qua `/api/assistant` (server), không gọi từ trình duyệt.

**Mục đích:** trả lời câu hỏi về món ăn, thay thế nguyên liệu, giải thích "vì sao gợi ý", dựa trên dữ liệu của app.

**Nguyên tắc:**
1. LLM **không** là nguồn quyết định an toàn. Mọi lọc dị ứng/bệnh lý vẫn do `evaluateRecipe`. LLM chỉ diễn giải và đề xuất, kết quả đề xuất **phải qua `evaluateRecipe`** trước khi hiển thị.
2. Cung cấp ngữ cảnh tối thiểu (mục tiêu, dị ứng, nhóm bệnh dạng mã) — không gửi họ tên/email/địa chỉ.
3. Có consent riêng cho tính năng AI; cho phép tắt.
4. Từ chối chẩn đoán/kê thuốc; câu hỏi nguy cơ (mang thai, bệnh thận, thuốc, triệu chứng nặng) → khuyên gặp bác sĩ.
5. Dùng **tool calling** có cấu trúc: `search_recipes(filters)`, `get_recipe(id)`, `suggest_substitute(ingredient_id)`, `explain_verdict(recipe_id)`; tất cả tool kiểm quyền theo `auth.uid()`.
6. Giới hạn tốc độ (20 tin/giờ/user), ghi log ẩn danh để cải thiện.

**System prompt mẫu:**
```
Bạn là trợ lý dinh dưỡng của NutriCook. Trả lời bằng tiếng Việt, ngắn gọn, thân thiện.
Chỉ dùng dữ liệu từ công cụ; không bịa số liệu dinh dưỡng. Không chẩn đoán hay kê thuốc.
Nếu người dùng nhắc tới bệnh thận, mang thai, dùng insulin/thuốc, trẻ em hoặc triệu chứng nặng:
hãy khuyên họ hỏi bác sĩ/chuyên gia dinh dưỡng. Luôn tôn trọng danh sách dị ứng do hệ thống cung cấp.
```

---

## 8. DEFINITION OF DONE (mỗi PR/task)
- [ ] Đáp ứng mã yêu cầu PRD liên quan và tiêu chí "xong khi".
- [ ] `pnpm lint`, `pnpm typecheck`, test liên quan **xanh**.
- [ ] Có test mới cho hành vi mới (unit/DB/E2E tùy lớp).
- [ ] Bảng mới → có RLS + test pgTAP; types đã sinh lại.
- [ ] Không rò secret; không vi phạm mục 2 (an toàn/bảo mật).
- [ ] UI: loading/empty/error, responsive, a11y, i18n, `MedicalDisclaimer` nếu liên quan sức khỏe.
- [ ] Có ảnh chụp/GIF cho thay đổi UI; mô tả cách kiểm thử thủ công.
- [ ] Cập nhật tài liệu nếu thay đổi thiết kế/nghiệp vụ.

---

## 9. CHECKLIST BẢO MẬT TRƯỚC GO-LIVE
- [ ] RLS bật 100% bảng `public`; pgTAP xanh; `anon` chỉ đọc dữ liệu công khai.
- [ ] Không có `service_role` trong bundle FE (`grep` + kiểm `dist`).
- [ ] Webhook VNPay: sai chữ ký/sai số tiền/lặp → xử lý đúng.
- [ ] Rate limit auth/checkout/mealplan hoạt động; CAPTCHA đăng ký.
- [ ] Header bảo mật, CSP; HTTPS only.
- [ ] Email confirm bật; Redirect URLs Supabase chỉ gồm domain hợp lệ.
- [ ] Consent sức khỏe, chính sách bảo mật, xuất/xóa dữ liệu hoạt động (Nghị định 13/2023/NĐ-CP).
- [ ] Backup & thử khôi phục; kế hoạch xoay khóa khi sự cố.
- [ ] `pnpm audit` không còn lỗi High/Critical.
- [ ] `condition_rules` đã được chuyên gia dinh dưỡng/bác sĩ **ký duyệt** (`approved_by`, `approved_at`).

---

## 10. BẢN ĐỒ TÀI LIỆU → TÍNH NĂNG
| Cần biết | Xem |
|---|---|
| Yêu cầu, quy tắc dinh dưỡng, trạng thái đơn, tiêu chí nghiệm thu | `01_PRD_NGHIEP_VU.md` mục 4, 5, 11 |
| Schema SQL, RLS, trigger, `place_order` | `02_KY_THUAT.md` mục 5 |
| Thuật toán gợi ý/thực đơn/mua sắm | `02_KY_THUAT.md` mục 6 |
| API & thanh toán VNPay | `02_KY_THUAT.md` mục 7, 9 |
| Triển khai Vercel/Supabase, CI | `02_KY_THUAT.md` mục 11–12 |
| Design tokens, wireframe, sitemap | `03_GIAO_DIEN_FRONTEND.md` Phần A |
| Code mẫu Auth/Query/Cart/Checkout | `03_GIAO_DIEN_FRONTEND.md` Phần B |

---

## 11. KHI GẶP TÌNH HUỐNG KHÔNG RÕ
1. Tìm trong 3 tài liệu; 2. Chọn phương án **an toàn hơn** (về sức khỏe/bảo mật); 3. Ghi giả định vào mô tả PR; 4. Nếu ảnh hưởng người dùng hoặc tiền → **hỏi người phụ trách trước khi làm**.
