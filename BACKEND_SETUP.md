# Hướng dẫn dựng backend NutriCook trên Windows

Đây là đồ án học phần, không phải website bán hàng production. Bản trình diễn
frontend có thể chạy độc lập với Node.js; Docker/Supabase local là tùy chọn để
trình bày phần backend. Supabase cung cấp PostgreSQL, Auth, Storage, RPC và Edge
Functions; giao diện hỗ trợ đăng ký/đăng nhập email để lưu hồ sơ sức khỏe vào
backend. Không có đặt hàng thật.

## 1. Chuẩn bị

Cài Node.js 20+, npm và Docker Desktop. Mở Docker Desktop, chờ trạng thái
**Running**, sau đó mở PowerShell ở thư mục dự án.

Các migration, seed, cấu hình Supabase CLI và Edge Functions từ phụ lục A–J đã
được đặt dưới `supabase/`. Supabase CLI và `@supabase/supabase-js` được khai báo
trong `package.json`; dùng CLI cục bộ của dự án thay vì cài CLI toàn máy.

## 2. Khởi động Supabase local

```powershell
npm install
npm run supabase:start
npm run supabase:status
```

Lần đầu có thể mất vài phút để Docker tải các image. CLI hiển thị URL, khóa
`anon` và khóa `service_role`. Không chia sẻ ảnh chụp/toàn bộ output này. Chỉ
URL và khóa `anon` mới được dùng trong frontend.

Tạo file môi trường frontend:

```powershell
Copy-Item .env.example .env.local
notepad .env.local
```

Điền `VITE_SUPABASE_URL` và `VITE_SUPABASE_ANON_KEY` theo kết quả local từ
`npm run supabase:status`. Không đưa khóa `service_role`, khóa AI, VNPay hoặc
Resend vào `.env.local`, `VITE_*`, hay bất kỳ file nào được commit.

## 3. Tạo schema và dữ liệu thử

> Lệnh reset xóa và dựng lại database **local**. Chỉ chạy khi chấp nhận mất dữ
> liệu local hiện có; không chạy trên môi trường staging/production.

```powershell
npm run supabase:reset
```

Lệnh này áp dụng lần lượt 10 migration và `supabase/seed.sql`. Nếu local DB đã có
dữ liệu cần giữ, không reset; khởi động Supabase rồi dùng
`npm exec supabase -- migration up --local` để chỉ áp dụng migration đang chờ.
Mở Studio tại
`http://127.0.0.1:54323`, vào SQL Editor và xác nhận:

```sql
select slug, status, kcal, auto_tags, allergen_ids
from public.recipes
order by slug;

select count(*) as product_count from public.products;
```

Seed dùng dữ liệu dinh dưỡng ước tính, quy tắc bệnh lý chưa được duyệt và giá
sản phẩm giả lập. Không dùng dữ liệu này để tư vấn sức khỏe, vận hành bán hàng
hay đưa lên production.

Chạy các kiểm thử quyền cơ bản:

```powershell
npm exec supabase -- test db
```

Nếu reset thất bại, giữ nguyên log lỗi đầu tiên và dừng trước khi sửa schema.
Không sửa migration đã áp dụng; tạo migration mới bằng:

```powershell
npm exec supabase -- migration new describe_the_change
```

## 4. Đăng nhập và lưu hồ sơ

Chạy các migration mới nhất, cấu hình `.env.local` bằng URL local và khóa `anon`
từ `npm run supabase:status`, rồi khởi động lại Vite. Mở mục **Hồ sơ sức khỏe**
và đăng ký email/mật khẩu hoặc đăng nhập tài khoản đã có trong Supabase Auth.
Supabase local đặt `enable_confirmations = false`, nên đăng ký sẽ đăng nhập ngay.
Nếu dùng Supabase hosted, vào Authentication → Providers → Email và tắt
**Confirm email** để có hành vi tương tự. Khởi động lại Supabase local sau khi
đổi cấu hình.

Hồ sơ được lưu bằng RPC `rpc_save_user_profile`, dùng `auth.uid()` để xác định
chủ sở hữu; bệnh lý và dị ứng được ghi vào các bảng hồ sơ tương ứng. Người dùng
phải xác nhận đồng ý trước khi lưu dữ liệu sức khỏe. RLS giữ các bảng hồ sơ cá
nhân theo chính sách trong `supabase/migrations/20261020000002_rls.sql`. Không
đặt service-role key trong frontend.

## 5. Các tích hợp backend còn lại

`src/lib/supabase.js` tạo client khi có đủ biến môi trường, còn
`src/services/authService.js`, `recipeService.js` và `shoppingService.js` gọi
Auth/RPC theo hợp đồng trong tài liệu. Lỗi từ Supabase được ném lên để giao diện
xử lý rõ ràng, không bị chuyển thành dữ liệu thành công giả.

Sinh TypeScript database types sau khi có thay đổi schema:

```powershell
New-Item -ItemType Directory -Force src\types | Out-Null
npm exec supabase -- gen types typescript --local |
  Out-File -Encoding utf8 src\types\database.ts
```

Giao diện hiện đã hỗ trợ đăng ký/đăng nhập email và lưu hồ sơ qua RPC; vẫn đọc
công thức/danh sách mua sắm demo. Các lát cắt còn lại là danh sách công
thức/RPC, cuối cùng mới đến AI và cửa hàng. Khi kết nối, danh sách món phải lấy
qua `rpc_recommend_recipes`; không tự lọc dị ứng ở frontend.

## 6. Edge Functions và secrets

Chỉ cấu hình khóa khi bạn có tài khoản dịch vụ tương ứng. Không cần khóa thật
để chạy schema local. Các Edge Function AI, VNPay và email chưa được xác nhận
trên Supabase/Deno thật; chữ ký VNPay cần đối chiếu tài liệu sandbox hiện hành.

Tạo file local riêng cho secrets:

```powershell
Copy-Item supabase\.env.example supabase\.env.local
notepad supabase\.env.local
```

Điền các giá trị cần thiết từ nhà cung cấp (không chia sẻ file này). Khởi chạy
function cụ thể:

```powershell
npm exec supabase -- functions serve ai-suggest --env-file supabase/.env.local
```

Lời khuyên AI cho thống kê thực đơn dùng Edge Function riêng. Thêm khóa
`ANTHROPIC_API_KEY` vào `supabase/.env.local` khi chạy local (không commit file
này), hoặc đặt secret trên project hosted:

```powershell
npm exec supabase -- secrets set ANTHROPIC_API_KEY=YOUR_ANTHROPIC_API_KEY
npm exec supabase -- functions deploy meal-plan-advice
```

Thay `YOUR_ANTHROPIC_API_KEY` bằng khóa của bạn trong terminal; không gửi khóa
này trong chat hoặc đưa vào mã frontend.
Người dùng phải đăng nhập và đồng ý rõ ràng trước khi gửi thống kê các món đã
xác nhận là đã ăn. Nhật ký món đã ăn lưu trên trình duyệt, không đồng bộ giữa
các thiết bị. Function chỉ nhận số liệu tổng hợp từ các món đã xác nhận, giới
hạn 10 lượt mỗi giờ/tài khoản, không đọc hồ sơ sức khỏe và không gửi tên/email
tới nhà cung cấp AI. Khi chạy local, phục vụ function với file secrets:

```powershell
npm exec supabase -- functions serve meal-plan-advice --env-file supabase/.env.local
```

Sau khi cập nhật khóa trong `.env.local`, hãy khởi động lại lệnh `functions serve`
đang chạy để function nhận secret mới. Nếu giao diện vẫn báo chưa cấu hình trên
môi trường hosted, đặt secret trong đúng project Supabase mà ứng dụng đang dùng
rồi deploy lại `meal-plan-advice`.

Khi deploy staging, dùng `supabase secrets set` và chỉ deploy các function đã
được kiểm thử. `vnpay-ipn` không dùng JWT vì cổng thanh toán gọi trực tiếp; tính
đúng đắn phụ thuộc hoàn toàn vào kiểm chữ ký, số tiền và tính idempotent trong
function.

Sau khi áp dụng migration quản trị tài khoản, deploy function bằng:

```powershell
npm exec supabase -- functions deploy admin-account-management
```

Function xác minh JWT và role admin trước khi chặn/khôi phục đăng nhập hoặc xóa
tài khoản. Khóa service role chỉ được sử dụng phía Edge Function. Chặn có thời
hạn sẽ tự hết hiệu lực theo Auth; để trống thời hạn sẽ chặn vô thời hạn. Xóa
tài khoản là thao tác không thể hoàn tác và xóa các bản ghi liên quan, bao gồm
đơn hàng trong database của đồ án.

## 6. Production (tham khảo, không cần cho đồ án)

Tạo hai Supabase project riêng. Thử nghiệm trên staging trước:

```powershell
npm exec supabase -- login
npm exec supabase -- link --project-ref <staging-project-ref>
npm exec supabase -- db push
```

`db push` chỉ áp migration; không tự chạy seed. Không đưa seed mặc định, giá,
tồn kho hoặc mã giảm giá mẫu lên production. Trước khi mở production cần ít
nhất: kiểm thử RLS/RPC bằng pgTAP, Edge Functions bằng `deno test`, xác nhận
Auth/Storage/Realtime/pg_cron, thay dữ liệu dinh dưỡng bằng dữ liệu có nguồn và
được duyệt, cấu hình CAPTCHA/SMTP, rà soát chính sách riêng tư và vận chuyển.

Frontend deploy trên Vercel chỉ cần `VITE_SUPABASE_URL` và
`VITE_SUPABASE_ANON_KEY`. Không thêm service-role hoặc khóa nhà cung cấp AI vào
Vercel.

## 7. Kiểm tra hiện có

```powershell
npm run lint
npm run build
node --test
```

Các lệnh kiểm tra frontend. Supabase local hiện đã áp dụng 10 migrations, có 6
công thức và 27 sản phẩm seed; năm file pgTAP chạy thành công với tổng cộng 52
kiểm thử. Edge Runtime, AI, VNPay, email và Deno chưa được kiểm thử đầu-cuối.
Không dùng dữ liệu seed hoặc cờ demo để xử lý khách hàng/đơn hàng thật.

Tài liệu nghiệp vụ, kỹ thuật và mã nguồn backend đầy đủ:

- `files/01_PRD_NGHIEP_VU.md`
- `files/02_KY_THUAT.md`
- `files/04_AGENT.md`
- `files/05_HUONG_DAN_BACKEND_SUPABASE.md`
