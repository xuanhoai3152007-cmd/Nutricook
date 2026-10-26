# NutriCook — Đồ án học phần

NutriCook là ứng dụng web tiếng Việt minh họa việc khám phá công thức nấu ăn,
lập thực đơn và chuẩn bị danh sách nguyên liệu. Repository này là **bản hoàn
thiện để trình diễn và nộp đồ án học phần**, không phải dịch vụ thương mại đang
hoạt động.

## Chạy bản trình diễn

Yêu cầu: Node.js 20 trở lên và npm.

```powershell
npm install
npm run dev
```

Mở URL Vite hiển thị trong terminal (thường là `http://localhost:5173`). Các
màn hình trình diễn thông thường không cần Docker hay Supabase. Để lưu hồ sơ sức
khỏe, cần cấu hình và chạy Supabase, sau đó đăng nhập tài khoản có sẵn. Món yêu
thích, thực đơn và danh sách nguyên liệu được lưu cục bộ trên trình duyệt đang
sử dụng; dữ liệu đó không đồng bộ giữa thiết bị hoặc tài khoản.

## Chức năng trình diễn

- Tổng quan với các chỉ số và gợi ý bữa ăn mẫu.
- Thư viện công thức có lọc danh mục, tìm kiếm tiếng Việt không dấu, lưu món
  yêu thích và xem chi tiết; món đã lưu còn nguyên sau khi tải lại trang.
- Điều chỉnh khẩu phần, xem nguyên liệu/cách nấu và thêm nguyên liệu vào danh
  sách chuẩn bị cho bữa ăn.
- Lập thực đơn tuần, đổi món và lưu lựa chọn theo ngày; danh sách nguyên liệu
  có thể thêm, xóa, đánh dấu đã có và được lưu trên trình duyệt.
- Đánh dấu món đã ăn trong thực đơn tuần; thống kê kcal, đạm và độ đa dạng
  theo tuần/tháng chỉ tính những món đã xác nhận, có thể bỏ ghi nhận hoặc thay
  bằng món đã ăn thực tế. Nhật ký lưu trên trình duyệt này.
- Có thể xin AI nhận xét thống kê các món đã xác nhận sau khi đăng nhập và
  đồng ý chia sẻ số liệu.
- Ước tính tiền đi chợ theo nguyên liệu, gợi ý nơi tìm điểm bán gần bạn và
  hướng dẫn chọn, kiểm tra, bảo quản nguyên liệu; nguyên liệu được nhóm theo
  từng công thức có thể thu gọn/mở rộng, và xóa toàn bộ danh sách cần xác nhận.
- Khu vực admin để thêm công thức, xem trạng thái nội dung, tìm tài khoản theo
  tên/email, chặn đăng nhập có lý do/thời hạn và xóa vĩnh viễn dữ liệu tài khoản.
- Wizard hồ sơ dinh dưỡng 5 bước với các phép tính minh họa BMI, BMR, TDEE và
  macro; đăng nhập Supabase để lưu hồ sơ, sở thích, dị ứng và tình trạng sức
  khỏe vào backend sau khi đồng ý rõ ràng.
- Giao diện responsive cho màn hình máy tính và điện thoại.

## Phạm vi và giới hạn

- Công thức, ảnh và chỉ số dinh dưỡng là dữ liệu minh họa. Giá đi chợ là ước
  tính, có thể khác giá thực tế theo nơi bán và thời điểm.
- Ứng dụng chỉ gợi ý điểm bán qua tìm kiếm bản đồ; không bán hàng, thu tiền hay
  tạo đơn hàng.
- Hồ sơ backend gắn với tài khoản Supabase đang đăng nhập và được bảo vệ bằng
  quyền truy cập database. Món yêu thích, thực đơn và danh sách nguyên liệu
  vẫn lưu cục bộ trên trình duyệt; chưa đồng bộ các dữ liệu đó lên backend.
- Quyền admin do quản trị viên gán trực tiếp trong database; không có chức năng
  tự nâng quyền trong giao diện. Admin không xem hồ sơ sức khỏe người dùng tại
  trang quản trị.
- Admin có thể chặn tài khoản đến thời điểm chọn hoặc vô thời hạn; tài khoản
  admin và tài khoản đang thao tác được bảo vệ khỏi chặn/xóa. Xóa tài khoản qua
  Edge Function sẽ xóa tài khoản Auth và dữ liệu gắn với hồ sơ, bao gồm đơn
  hàng trong cơ sở dữ liệu đồ án.
- Các service Auth, công thức và mua sắm cùng Supabase migrations/Edge Functions
  có trong repository như phần backend của đồ án; AI chỉ được tích hợp cho lời
  khuyên thực đơn nếu Edge Function và khóa nhà cung cấp được cấu hình. AI không
  ghi nhận bữa ăn thực tế, và đặt hàng thật chưa được tích hợp.
- Các phép tính và gợi ý sức khỏe chỉ mang tính tham khảo, không dùng thay cho
  tư vấn của bác sĩ/chuyên gia. Hồ sơ sức khỏe được gửi tới Supabase đã cấu hình
  và lưu theo tài khoản sau khi người dùng xác nhận đồng ý.

## Backend local (tùy chọn khi trình bày phần kỹ thuật)

Yêu cầu Docker Desktop đang chạy. Từ PowerShell:

```powershell
npm run supabase:start
npm exec supabase -- migration up --local
npm exec supabase -- test db
```

Migration áp dụng bổ sung mà không reset database. Trạng thái đã kiểm thử trên
môi trường local: 10 migrations, 6 công thức mẫu, 27 sản phẩm; 52 bài pgTAP đạt.
Nếu cần dựng mới toàn bộ dữ liệu local, `npm run supabase:reset` sẽ xóa dữ liệu
local hiện tại rồi chạy migrations và seed lại.

Để dùng hồ sơ backend, khởi động Supabase, áp dụng migrations, cấu hình
`.env.local` với `VITE_SUPABASE_URL` và `VITE_SUPABASE_ANON_KEY`, rồi đăng ký
bằng email hoặc đăng nhập tài khoản Supabase hiện có. Supabase local đã tắt xác
minh email nên đăng ký sẽ đăng nhập ngay. Với Supabase hosted, tắt **Confirm
email** tại Authentication → Providers → Email.
Không đưa service-role key hoặc secrets của nhà cung cấp vào frontend.

Để dùng lời khuyên AI cho thống kê thực đơn, đăng nhập, cấu hình
`ANTHROPIC_API_KEY` trong secrets của Supabase, rồi deploy
`meal-plan-advice`. AI chỉ nhận số liệu tổng hợp từ các món người dùng đã xác
nhận là đã ăn, sau khi đồng ý; không gửi email, tên hoặc hồ sơ sức khỏe. Nhật
ký đã ăn lưu cục bộ trong trình duyệt và không tự đồng bộ giữa các thiết bị.

Để cấp quyền admin lần đầu, trước tiên đăng ký tài khoản và đăng nhập ít nhất
một lần. Sau đó chạy câu lệnh sau trong SQL Editor của môi trường đang dùng:

```sql
update public.profiles
set role = 'admin'
where id = (
  select id
  from auth.users
  where lower(email) = lower('xuanhoai3152007@gmail.com')
);
```

Đăng xuất/đăng nhập lại sau khi cấp role. Trên trang hồ sơ có lựa chọn đăng nhập
dành riêng cho quản trị viên; lựa chọn này xác minh role trong database và từ
chối tài khoản chưa được cấp quyền. Không đặt mật khẩu admin trong mã nguồn;
dùng mật khẩu đã đăng ký hoặc đặt lại mật khẩu qua Supabase nếu cần.

Công thức có thể dùng nguyên liệu từ danh mục
hiện có; công thức mới mặc định lưu ở dạng bản nháp. Chỉ xuất bản khi nội dung
đạt các điều kiện kiểm tra của database.

Để dùng chức năng chặn/xóa tài khoản, áp dụng migration mới nhất và deploy Edge
Function `admin-account-management`. Function dùng `SUPABASE_SERVICE_ROLE_KEY`
ở phía server; tuyệt đối không đặt khóa này trong frontend.

## Kiểm tra

```powershell
npm run lint
npm run build
node --test
```

## Tài liệu

- [Hướng dẫn chạy ứng dụng và backend local](./BACKEND_SETUP.md)
- [Yêu cầu nghiệp vụ](./files/01_PRD_NGHIEP_VU.md)
- [Kiến trúc kỹ thuật](./files/02_KY_THUAT.md)
- [Hướng dẫn backend Supabase](./files/05_HUONG_DAN_BACKEND_SUPABASE.md)
- [Lộ trình production tham khảo, không bắt buộc cho đồ án](./06_LEN_BAN_CHINH_THUC.md)

Trước khi nộp, bổ sung tên sinh viên/nhóm, mã học phần và giảng viên theo mẫu
bìa hoặc quy định nộp bài của lớp.
