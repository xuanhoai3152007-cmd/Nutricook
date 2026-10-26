# 01 — PRD & TÀI LIỆU NGHIỆP VỤ (v2)
## NutriCook — Công thức nấu ăn theo chế độ dinh dưỡng + AI gợi ý món

> **Thay đổi so với v1:** (1) **Giữ và nối** phần mua hàng với công thức: món ăn → danh sách nguyên liệu cần mua → giỏ hàng → đặt hàng giao tận nơi (COD + VNPay). (2) **Công thức nấu chi tiết** từng bước cho mỗi món. (3) **AI gợi ý** theo sở thích, chế độ dinh dưỡng, khẩu phần, độ tuổi, tình trạng sức khỏe.
> Tài liệu liên quan: `02_KY_THUAT.md` · `03_GIAO_DIEN_FRONTEND.md` · `04_AGENT.md` · `05_HUONG_DAN_BACKEND_SUPABASE.md` (toàn bộ SQL, seed, Edge Functions).

---

## 1. TỔNG QUAN

### 1.1 Vấn đề
- Người dùng muốn ăn lành mạnh nhưng không biết **nấu món nào** hợp với mục tiêu, bệnh lý, độ tuổi của mình và của cả gia đình.
- Công thức trên mạng thường **thiếu chi tiết** (không nói lửa lớn nhỏ, bao lâu, dấu hiệu chín, lỗi hay gặp) và **không gắn dinh dưỡng** theo khẩu phần.
- Gợi ý chung chung, không tính tới dị ứng, người cao tuổi/trẻ nhỏ cùng ăn.
- Chọn được món rồi vẫn phải tự tính cần mua gì, bao nhiêu, rồi đi chợ → tốn thời gian, mua thừa/thiếu.

### 1.2 Giải pháp
Web app giúp người dùng:
1. Khai báo hồ sơ: cơ thể, mục tiêu, bệnh lý, dị ứng, khẩu vị, người cùng ăn.
2. Tự tính nhu cầu năng lượng và macro.
3. Duyệt thư viện **công thức chi tiết** (sơ chế → nấu → hoàn thiện, hẹn giờ, mẹo, lỗi thường gặp, bảo quản, thay thế nguyên liệu).
4. Nhờ **AI gợi ý món** theo bối cảnh hôm nay (ăn cho ai, khẩu vị, thời gian, nguyên liệu đang có).
5. Điều chỉnh **khẩu phần**: nguyên liệu và dinh dưỡng tự scale.
6. Lập thực đơn tuần, theo dõi nhật ký ăn uống.
7. **Tạo danh sách nguyên liệu cần mua** (đã trừ đồ có sẵn), **thêm vào giỏ và đặt hàng** giao tận nhà.

### 1.3 Mục tiêu kinh doanh (12 tháng)
| Mục tiêu | Chỉ số |
|---|---|
| Người dùng | 10.000 tài khoản |
| Kích hoạt | ≥ 60% hoàn tất onboarding |
| Gắn kết | ≥ 40% người dùng hoạt động có "đã nấu" ≥ 1 món/tháng |
| Chất lượng AI | ≥ 70% gợi ý được 👍; ≥ 25% gợi ý dẫn tới mở công thức |
| Nội dung | ≥ 300 công thức đã duyệt bởi chuyên gia dinh dưỡng, 100% có hướng dẫn đủ chi tiết |
| Doanh thu | ≥ 8% người dùng có đơn hàng; giá trị đơn trung bình ≥ 250.000đ; tỉ lệ hủy đơn < 5% |

### 1.4 Phân tích đối thủ (nghiên cứu)
| Sản phẩm | Điểm mạnh | Khoảng trống NutriCook |
|---|---|---|
| Eat This Much | Tự lên thực đơn theo kcal/macro | Món Tây, không gắn bệnh lý/món Việt, ít hướng dẫn nấu |
| Cronometer | Theo dõi vi chất rất chi tiết | Không mạnh về công thức & gợi ý |
| MyFitnessPal | CSDL lớn, cộng đồng | Gợi ý món/thực đơn bị khóa phí, ít món Việt |
| Yummly | Khám phá công thức, lọc chế độ ăn | Dinh dưỡng yếu |
| ReciMe | Lưu công thức, meal planner, scale khẩu phần | Không đánh giá bệnh lý |

**Định vị:** *món Việt + dinh dưỡng theo bệnh lý phổ biến + hướng dẫn nấu từng bước + AI hiểu khẩu phần & độ tuổi cả nhà.*

---

## 2. NGƯỜI DÙNG

| Persona | Nhu cầu chính |
|---|---|
| **Lan, 28, văn phòng** | Giảm 5 kg, món ≤ 30 phút, AI gợi ý "tối nay ăn gì" |
| **Minh, 35, tập gym** | Giàu đạm, biết macro từng món |
| **Bác Hùng, 58, tiểu đường + huyết áp** | Món ít đường/ít muối, chữ to, hướng dẫn thật rõ ràng |
| **Chị Thu, 40, nội trợ** | Nấu cho 4 người gồm 1 em bé 6 tuổi và 1 ông 70 tuổi; AI chọn món hợp cả nhà |
| **Người mới tập nấu** | Hướng dẫn từng bước, hẹn giờ, mẹo & lỗi thường gặp |
| **Chuyên gia dinh dưỡng** | Soạn/duyệt công thức, quản lý quy tắc bệnh lý |
| **Admin** | Quản trị người dùng, nội dung, theo dõi AI |
| **Nhân viên kho/giao hàng** | Xem đơn, xác nhận, đóng gói, cập nhật trạng thái và mã vận đơn |

Vai trò hệ thống: `customer`, `nutritionist`, `staff`, `admin`.

---

## 3. PHẠM VI

### 3.1 MVP (8 tuần)
Tài khoản (đăng ký/đăng nhập/đăng xuất/quên mật khẩu/Google) · Hồ sơ sức khỏe & khẩu vị · Tính kcal/macro · Thư viện công thức chi tiết · Scale khẩu phần · Chế độ nấu từng bước · Gợi ý theo hồ sơ · **AI gợi ý món** · Thực đơn tuần · Yêu thích/phản hồi · **Danh sách mua sắm · Giỏ hàng · Đặt hàng (COD + VNPay) · Theo dõi đơn · Sổ địa chỉ · Mã giảm giá** · Admin nội dung và đơn hàng.

### 3.2 Phase 2
Nhật ký ăn uống & biểu đồ cân nặng · Đánh giá/bình luận · AI hỏi đáp và thay nguyên liệu · AI lập thực đơn tuần có giải thích · Thông báo nhắc bữa · Tự tạo công thức riêng · Xuất PDF/in · **Gói nguyên liệu theo công thức (meal kit) & suất ăn nấu sẵn · Hoàn tiền/đổi trả · MoMo/chuyển khoản QR**.

### 3.3 Phase 3
App mobile/PWA · Gói Premium · Đa ngôn ngữ · Video hướng dẫn.

### 3.4 Ngoài phạm vi
Vận hành đội giao hàng riêng (dùng đối tác GHN/GHTK/Ahamove); sàn nhiều người bán; thanh toán bằng thẻ lưu trên hệ thống (không lưu thẻ). Ứng dụng **không chẩn đoán/điều trị** và không thay thế bác sĩ.

---

## 4. YÊU CẦU CHỨC NĂNG

Ưu tiên: **P0** MVP · **P1** Phase 2 · **P2** sau.

### 4.1 Module A — Tài khoản
| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| A1 | Đăng ký email + mật khẩu (≥ 8 ký tự), xác thực email | P0 |
| A2 | Đăng nhập, **đăng xuất**, giữ phiên | P0 |
| A3 | Quên/đặt lại mật khẩu | P0 |
| A4 | Đăng nhập Google | P0 |
| A5 | Sửa hồ sơ, đổi mật khẩu, **xuất dữ liệu**, **xóa tài khoản** | P0 |
| A6 | Phân quyền `customer / nutritionist / staff / admin` | P0 |
| A7 | Sổ địa chỉ giao hàng (nhiều địa chỉ, 1 mặc định) | P0 |

### 4.2 Module B — Hồ sơ sức khỏe, khẩu vị & người cùng ăn
| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| B1 | Wizard: giới tính, ngày sinh, chiều cao, cân nặng, mức vận động | P0 |
| B2 | Mục tiêu: giảm cân / duy trì / tăng cân / tăng cơ / ăn lành mạnh | P0 |
| B3 | Tình trạng sức khỏe (nhiều lựa chọn): tiểu đường type 2, huyết áp, mỡ máu, gout, thừa cân, dạ dày, thiếu máu, **bệnh thận\***, **mang thai/cho con bú\*** (\*nhóm đỏ) | P0 |
| B4 | Dị ứng: đậu phộng, hạt cây, giáp xác, cá, sữa, trứng, gluten, đậu nành, vừng | P0 |
| B5 | Chế độ ăn: thường, chay, thuần chay, pescatarian, low-carb, keto, DASH, Địa Trung Hải, halal | P0 |
| B6 | **Khẩu vị**: mức cay (0–3), vị ưa thích (thanh đạm, ít mặn, ngọt, chua, đậm đà, tươi mát), ẩm thực (Việt/Á/Âu/Địa Trung Hải), kiểu nấu ưa thích (xào, hấp, kho, canh, nướng…) | P0 |
| B7 | **Thói quen nấu**: thời gian tối đa, trình độ (1–3), khẩu phần mặc định | P0 |
| B8 | **Người cùng ăn**: số người và nhóm tuổi (trẻ em <13, thiếu niên 13–17, người lớn 18–59, cao tuổi ≥60) | P0 |
| B9 | Nguyên liệu không thích (blacklist) | P0 |
| B10 | Tự tính BMI, BMR, TDEE, kcal, macro, natri/đường tối đa (hiện công thức công khai) | P0 |
| B11 | **Đồng ý** xử lý dữ liệu sức khỏe + disclaimer y tế; **đồng ý riêng** cho tính năng AI | P0 |
| B12 | Lịch sử cân nặng | P1 |

### 4.3 Module C — Công thức nấu chi tiết (trọng tâm)
Mỗi công thức **bắt buộc** có các phần sau (hệ thống chặn xuất bản nếu thiếu):

| Thành phần | Nội dung | Ràng buộc |
|---|---|---|
| Giới thiệu | Tóm tắt 1–2 câu, giới thiệu món, hương vị, lợi ích | Có |
| Thông tin nhanh | Thời gian sơ chế/nấu/tổng, độ khó (1–3), khẩu phần gốc, ẩm thực, kiểu nấu, độ cay | Có |
| **Dụng cụ** | Danh sách dụng cụ cần chuẩn bị | ≥ 1 mục |
| **Nguyên liệu theo nhóm** | Nhóm ("Nước sốt", "Rau hấp"…), khối lượng (g) **và** đơn vị đời thường (2 tép, 1 muỗng cà phê), **ghi chú sơ chế** (thái, ngâm, ướp), ghi chú, nguyên liệu tùy chọn | ≥ 3 nguyên liệu |
| **Các bước chi tiết** | Mỗi bước: giai đoạn (**sơ chế / nấu / hoàn thiện**), tiêu đề, hướng dẫn cụ thể, **hẹn giờ**, **mức lửa** (không/nhỏ/vừa/lớn), **mẹo & dấu hiệu nhận biết đã đạt** | ≥ 4 bước, ≥ 1 bước sơ chế, mỗi hướng dẫn ≥ 20 ký tự |
| Mẹo nấu ngon | 2–3 mẹo | Khuyến khích |
| **Lỗi thường gặp** | Lỗi hay mắc + cách tránh | Khuyến khích |
| **Thay thế nguyên liệu** | Thay thế theo dị ứng/chế độ ăn, kèm lưu ý | Khuyến khích |
| Bảo quản & hâm lại | Thời gian, cách hâm | Có |
| Gợi ý ăn kèm | Món/rau ăn kèm | Có |
| Lưu ý sức khỏe | Dị ứng, bệnh lý cần lưu ý (do chuyên gia viết) | Có |
| Dinh dưỡng / khẩu phần | kcal, đạm, carb, béo, chất xơ, đường, natri — **tự tính** từ nguyên liệu | Tự động |
| Cờ tự động | Dị ứng, chế độ ăn (chay/thuần chay…), mức purine, tag (ít natri, giàu đạm, giàu chất xơ…) | Tự động |

**Chức năng:**
| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| C1 | Danh sách: tìm kiếm không dấu, lọc (bữa, ẩm thực, kiểu nấu, thời gian, độ cay, chế độ ăn), cuộn vô hạn | P0 |
| C2 | Trang chi tiết đủ các phần trên + nhãn **Phù hợp / Lưu ý / Không nên** cho riêng người dùng | P0 |
| C3 | **Scale khẩu phần** (1–12): nguyên liệu và tổng dinh dưỡng tính lại | P0 |
| C4 | **Chế độ nấu**: từng bước toàn màn hình, màn hình luôn sáng, hẹn giờ theo bước, tick nguyên liệu đã chuẩn bị | P0 |
| C5 | Yêu thích; 👍/👎 kèm lý do ("quá mặn", "khó làm"); "Tôi đã nấu" | P0 |
| C6 | Đánh giá sao + bình luận | P1 |
| C7 | Tự tạo công thức riêng | P1 |
| C8 | In/chia sẻ/xuất PDF | P1 |

### 4.4 Module D — Gợi ý theo hồ sơ (quy tắc, không AI)
| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| D1 | **Lọc cứng**: dị ứng, chế độ ăn, nguyên liệu không thích, loại trừ theo bệnh lý, độ cay/độ tuổi | P0 |
| D2 | **Chấm điểm**: khớp kcal bữa, ưu tiên theo bệnh lý, thời gian, ẩm thực/kiểu nấu ưa thích, đánh giá, yêu thích | P0 |
| D3 | Hiển thị lý do ("ít natri", "giàu chất xơ") | P0 |
| D4 | Ẩn món người dùng đã 👎 | P0 |

### 4.5 Module E — AI gợi ý món (mới)
**Mục đích:** "Hôm nay nấu gì?" — AI hiểu bối cảnh và đề xuất vài món kèm lý do cá nhân hóa.

**Đầu vào (form 1 màn hình, mặc định lấy từ hồ sơ):**
| Nhóm | Trường |
|---|---|
| Bữa | Sáng / trưa / tối / phụ |
| **Ăn cho ai** | Nhóm tuổi + số người (vd 2 người lớn + 1 trẻ em + 1 cao tuổi) |
| **Khẩu phần** | Số khẩu phần muốn nấu (1–12) |
| Khẩu vị | Vị ưa thích (tối đa 4), mức cay tối đa |
| Phong cách | Ẩm thực, kiểu nấu |
| Ràng buộc | Thời gian tối đa |
| Nguyên liệu | "Đang có/muốn dùng", "không muốn" |
| Ghi chú | Văn bản tự do ≤ 300 ký tự |
| Ngầm lấy từ hồ sơ | Mục tiêu, chế độ ăn, bệnh lý, dị ứng, lịch sử thích/không thích |

**Đầu ra:** 3–8 món; mỗi món có ảnh, thời gian, độ khó, dinh dưỡng/khẩu phần, nhãn phù hợp, **"Vì sao hợp với bạn"** (1–2 câu), **gợi ý chia khẩu phần theo nhóm tuổi**, **hệ số scale** (số khẩu phần muốn nấu ÷ khẩu phần gốc), nút "Xem công thức", 👍/👎.

**Quy tắc theo nhóm tuổi (do hệ thống áp dụng, AI không được vượt qua):**
| Nhóm ăn | Quy tắc |
|---|---|
| Trẻ em < 13 | Độ cay tối đa 1; loại món có rượu/caffeine; **không** dùng khớp kcal người lớn; **không** nội dung giảm cân |
| Thiếu niên 13–17 | Loại rượu; không nội dung giảm cân (nhóm đỏ) |
| Người lớn 18–59 | Áp dụng đầy đủ mục tiêu kcal/macro |
| Cao tuổi ≥ 60 | Natri mỗi khẩu phần ≤ 600 mg (hoặc chặt hơn nếu có bệnh), ưu tiên món mềm |
| Nhiều nhóm cùng ăn | Lấy **ràng buộc chặt nhất** của tất cả người ăn; không dùng khớp kcal cá nhân |

**Biên an toàn của AI:**
1. AI **chỉ chọn trong danh sách ứng viên** đã được database lọc cứng. Món có dị ứng/vi phạm chế độ ăn/loại trừ bệnh lý **không bao giờ** tới được AI.
2. Mọi id AI trả về bị kiểm lại; id lạ bị loại.
3. Số liệu dinh dưỡng và hệ số khẩu phần do hệ thống tính; AI không tự đưa số.
4. Không chẩn đoán, không kê thuốc; câu hỏi y tế → khuyên gặp bác sĩ.
5. Nhóm đỏ hoặc có trẻ em/thiếu niên: không nói chuyện giảm cân/hạn chế năng lượng.
6. Nội dung người dùng nhập (ghi chú, nguyên liệu) chỉ là **dữ liệu sở thích**, không thể thay đổi quy tắc (chống prompt injection).
7. Không gửi họ tên/email/ngày sinh/địa chỉ cho nhà cung cấp AI; chỉ nhóm tuổi, mã bệnh, mục tiêu.
8. AI lỗi/quá thời gian → **fallback** theo điểm của quy tắc, vẫn có kết quả.
9. Giới hạn: 20 lượt/giờ/người (cấu hình); lưu log (ẩn danh hóa sau 90 ngày).

**Học từ phản hồi:** 👍/👎/"đã nấu" (kèm lý do) → tín hiệu khẩu vị cho lần gợi ý sau (loại/ẩm thực/kiểu nấu hay thích, lý do không thích).

| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| E1 | Form gợi ý + kết quả có lý do cá nhân hóa | P0 |
| E2 | Nhận biết nhóm tuổi & số người, áp dụng quy tắc chặt nhất | P0 |
| E3 | Hệ số scale khẩu phần hiển thị và truyền sang trang công thức | P0 |
| E4 | Dùng nguyên liệu đang có (ưu tiên), loại nguyên liệu không muốn | P0 |
| E5 | Phản hồi 👍/👎 kèm lý do; ẩn món bị 👎 | P0 |
| E6 | Đồng ý riêng cho AI, tắt/bật được; hiển thị rõ dữ liệu nào được gửi | P0 |
| E7 | Fallback khi AI lỗi; giới hạn tần suất | P0 |
| E8 | AI giải thích "vì sao món này bị gắn Lưu ý/Không nên" | P1 |
| E9 | AI đề xuất **thay nguyên liệu** (qua kiểm tra an toàn lại) | P1 |
| E10 | AI hỏi đáp trong trang công thức (RAG trên chính công thức) | P1 |
| E11 | AI lập thực đơn tuần có giải thích | P1 |

### 4.6 Module F — Thực đơn
| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| F1 | Tạo thực đơn 1–14 ngày; 3 bữa chính (+ bữa phụ tùy chọn); không lặp món trong 3 ngày; chỉnh khẩu phần 0,75–1,5 để sát kcal | P0 |
| F2 | Đổi món, ghim món, kéo-thả | P0 |
| F3 | Tổng hợp dinh dưỡng theo bữa/ngày so với mục tiêu | P0 |
| F4 | **Nhóm đỏ không được tạo thực đơn tự động** | P0 |

### 4.6b Module S — Cửa hàng nguyên liệu & đặt hàng
| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| S1 | Danh mục sản phẩm nguyên liệu (rau củ, thịt cá, ngũ cốc, gia vị…) **gắn với nguyên liệu của công thức**; tìm/lọc; hiển thị giá, quy cách, tồn kho | P0 |
| S2 | **Danh sách mua sắm** từ 1 hoặc nhiều công thức (kèm khẩu phần) hoặc từ thực đơn tuần: gộp nguyên liệu, **trừ nguyên liệu đã có ở nhà**, ánh xạ sang sản phẩm rẻ nhất còn hàng, tính số lượng theo quy cách đóng gói | P0 |
| S3 | "Thêm tất cả vào giỏ" từ công thức/thực đơn; báo rõ mục hết hàng hoặc chưa có sản phẩm | P0 |
| S4 | Giỏ hàng lưu trong DB khi đăng nhập: đổi số lượng, xóa, tạm tính; khách chưa đăng nhập giữ giỏ tạm rồi gộp khi đăng nhập | P0 |
| S5 | **Cảnh báo dị ứng**: sản phẩm chứa chất người dùng dị ứng → bắt buộc xác nhận trước khi thêm/đặt | P0 |
| S6 | Checkout: chọn địa chỉ, phương thức thanh toán (COD, VNPay), mã giảm giá, ghi chú; **báo giá** (tạm tính, phí ship, giảm giá, tổng) trước khi đặt | P0 |
| S7 | Thanh toán online VNPay (sandbox → live); trạng thái thanh toán **chỉ** xác nhận qua webhook đã kiểm chữ ký | P0 |
| S8 | Theo dõi trạng thái đơn theo thời gian thực, lịch sử đơn, **hủy đơn** khi còn `pending/confirmed`, **mua lại** | P0 |
| S9 | Email xác nhận/cập nhật trạng thái đơn | P0 |
| S10 | Tồn kho: **giữ chỗ** khi đặt, **trừ kho** khi xác nhận, **hoàn kho** khi hủy | P0 |
| S11 | Phí vận chuyển theo khu vực; miễn phí từ ngưỡng đơn | P0 |
| S12 | Tự hủy đơn thanh toán online quá 15 phút chưa trả và nhả kho giữ chỗ | P0 |
| S13 | Gói nguyên liệu theo công thức (meal kit), suất ăn nấu sẵn | P1 |
| S14 | Hoàn tiền/đổi trả có quy trình | P1 |
| S15 | Tích hợp GHN/GHTK (tạo vận đơn, đồng bộ trạng thái) | P2 |

### 4.7 Module G — Nhật ký & theo dõi
Ghi món đã ăn (từ công thức/nhập tay), vòng kcal/macro trong ngày, biểu đồ cân nặng, cảnh báo vượt natri/đường theo bệnh lý — **P1**.

### 4.8 Module H — Quản trị
| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| H1 | CRUD nguyên liệu (dinh dưỡng/100 g, dị ứng, purine, GI, tag, nguồn số liệu) | P0 |
| H2 | **Trình soạn công thức**: nhóm nguyên liệu, bước (giai đoạn/lửa/hẹn giờ/mẹo), dụng cụ, mẹo, lỗi thường gặp, thay thế; xem trước dinh dưỡng tự tính | P0 |
| H3 | Quy trình `draft → review → published`; hệ thống **chặn** xuất bản nếu thiếu thành phần bắt buộc (mục 4.3) | P0 |
| H4 | Quản lý người dùng/vai trò | P0 |
| H5 | Quản lý quy tắc bệnh lý (versioning, người duyệt) | P1 |
| H6 | Theo dõi AI: số lượt, tỉ lệ fallback, tỉ lệ 👍, token | P1 |
| H7 | Quản lý sản phẩm: giá, quy cách, tồn kho, ánh xạ sang nguyên liệu, ảnh, bật/tắt bán | P0 |
| H8 | Quản lý đơn hàng: danh sách, lọc theo trạng thái, đổi trạng thái hợp lệ, mã vận đơn, in phiếu, đánh dấu đã hoàn tiền | P0 |
| H9 | Quản lý mã giảm giá và phí vận chuyển | P0 |
| H10 | Dashboard: doanh thu, số đơn, tỉ lệ hủy, sản phẩm bán chạy, công thức dẫn tới đơn | P1 |

---

## 5. QUY TẮC NGHIỆP VỤ

### 5.1 Năng lượng
**BMR (Mifflin-St Jeor):** Nam `10W + 6,25H − 5A + 5`; Nữ `10W + 6,25H − 5A − 161` (W kg, H cm, A tuổi).
**TDEE = BMR × hệ số vận động:** ít vận động 1,2 · nhẹ 1,375 · vừa 1,55 · nhiều 1,725 · rất nhiều 1,9. Kết quả là **ước tính** (sai số khoảng ±10%).

**Mục tiêu:** giảm cân TDEE − 500 · duy trì TDEE · tăng cân/tăng cơ TDEE + 300.
**Giới hạn an toàn:** sàn **Nữ ≥ 1.200**, **Nam ≥ 1.500** kcal. Không cho mục tiêu làm BMI < 18,5.
**Nhóm đỏ:** dưới 18 tuổi, BMI < 18,5, bệnh thận mạn, mang thai/cho con bú → không tạo kế hoạch giảm cân/thực đơn tự động; chỉ nội dung chung + khuyên gặp chuyên gia.

### 5.2 Macro
Khoảng AMDR: đạm 10–35%, béo 20–35%, tinh bột 45–65%. Mặc định đạm 20% · tinh bột 50% · béo 30%; giảm cân/tăng cơ: đạm 28%. 1 g đạm/tinh bột = 4 kcal, 1 g béo = 9 kcal. Chất xơ ≥ 25 g (nữ)/30 g (nam). Đường tự do < 10% kcal. Natri < 2.000 mg/ngày; 1.500 mg khi tăng huyết áp (cần chuyên gia duyệt).

### 5.3 Quy tắc theo bệnh lý (dữ liệu trong `condition_rules`)
> ⚠ Các ngưỡng trong seed là **bản nháp chưa duyệt**. Chuyên gia dinh dưỡng/bác sĩ phải rà soát và ký duyệt trước khi công khai.

| Tình trạng | Ưu tiên | Loại trừ cứng | Cảnh báo mềm (mỗi khẩu phần) |
|---|---|---|---|
| Tiểu đường type 2 | Chất xơ, ít đường, ngũ cốc nguyên hạt | Đồ uống có đường | Đường > 10 g |
| Tăng huyết áp | Ít natri, DASH | Đồ muối chua, mì ăn liền | Natri > 600 mg |
| Mỡ máu cao | Chất xơ, cá béo | Nội tạng, chiên ngập dầu | — |
| Gout | — | Nội tạng, bia rượu, nước ngọt | Purine > mức vừa |
| Thừa cân/béo phì | Đạm, chất xơ, ít năng lượng | Chiên ngập dầu, nước ngọt | — |
| Dạ dày/trào ngược | Món mềm, nhẹ | Rượu, caffeine, ớt cay | — |
| Thiếu máu | Giàu sắt | — | — |
| Bệnh thận mạn, mang thai | Nhóm đỏ | — | — |

Nhiều bệnh: lấy ngưỡng **chặt nhất**, **hợp** các danh sách loại trừ. Kết quả mỗi món: `suitable` (xanh) / `caution` (vàng) / `avoid` (đỏ, bị ẩn khỏi gợi ý).

### 5.3b Quy tắc tự động tính trên công thức
- Dinh dưỡng/khẩu phần = Σ(nguyên liệu không tùy chọn) ÷ khẩu phần gốc.
- **Dị ứng và tag tính cả nguyên liệu tùy chọn** (ví dụ ớt, tương) để an toàn.
- Chế độ ăn suy ra từ tag nguyên liệu: *chay* = không thịt/cá/hải sản; *thuần chay* = không sản phẩm động vật; *pescatarian* = không thịt.
- Tag tự động: ít natri (≤ 400 mg), giàu đạm (≥ 25 g), giàu chất xơ (≥ 6 g), ít đường (≤ 5 g), ít calo (≤ 400 kcal), nấu nhanh (≤ 20 phút).

### 5.4 Khẩu phần
`lượng = lượng_gốc × (khẩu_phần_muốn / khẩu_phần_gốc)`; gia vị/muối có thể scale dưới tuyến tính (`√tỉ lệ`); nguyên liệu trang trí cố định. Hiển thị làm tròn 0,25. Dinh dưỡng mỗi khẩu phần không đổi; tổng = × số khẩu phần.

### 5.5 Nội dung
Chỉ `nutritionist`/`admin` xuất bản. Số liệu nguyên liệu phải ghi **nguồn**; số liệu `seed_estimate` không dùng cho bản công khai. Nội dung sức khỏe có mục "Nguồn & Phương pháp".

### 5.6 Quy tắc đơn hàng

**Vòng đời đơn**
```
pending ─► confirmed ─► preparing ─► shipping ─► delivered ─► completed
   │           │             │                        └─► refund_requested ─► refunded
   └───────────┴─────────────┴─► cancelled
```
| Trạng thái | Ai đổi | Điều kiện / tác dụng phụ |
|---|---|---|
| `pending` | Hệ thống | Tạo đơn; **giữ chỗ** kho (`reserved`) |
| `confirmed` | Hệ thống (VNPay thành công) hoặc nhân viên (COD) | **Trừ kho thật**, nhả giữ chỗ |
| `preparing` | Nhân viên | Đóng gói |
| `shipping` | Nhân viên | Có mã vận đơn |
| `delivered` | Nhân viên | COD: tự ghi **đã thu tiền** |
| `cancelled` | Khách (khi `pending/confirmed`) hoặc nhân viên | `pending` → nhả giữ chỗ; sau khi trừ kho → **hoàn kho**; nếu đã thanh toán → ghi **"cần hoàn tiền thủ công"** |
| `refunded` | Nhân viên | Đánh dấu đã hoàn tiền với cổng thanh toán |

**Quy tắc khác**
- **Giá chốt tại thời điểm đặt** (snapshot tên, đơn giá); đổi giá sau này không ảnh hưởng đơn cũ.
- **Danh sách mua sắm:** `cần = Σ lượng nguyên liệu (đã scale theo khẩu phần) − đã có ở nhà`; `số lượng = ⌈cần ÷ quy cách đóng gói⌉`; chọn sản phẩm còn hàng có **giá/gram thấp nhất**; nguyên liệu tùy chọn và nước lọc không đưa vào danh sách.
- **Phí ship:** theo tỉnh/thành, quy tắc mặc định `*`; miễn phí khi đạt ngưỡng của quy tắc.
- **Mã giảm giá:** còn hạn, còn lượt, đạt đơn tối thiểu; giảm theo % có **trần**; không cộng dồn; khách không xem được danh sách mã.
- **Dị ứng:** sản phẩm có chất người dùng đã khai → hiển thị cảnh báo và yêu cầu xác nhận.
- **Hết hàng:** khi đặt, nếu `tồn − giữ chỗ < số lượng` → từ chối cả đơn, nêu rõ tên sản phẩm.
- **Thanh toán online:** xác nhận thành công **chỉ dựa vào webhook** có chữ ký hợp lệ + khớp mã đơn + khớp số tiền + xử lý lặp an toàn (idempotent). Không tin kết quả redirect từ trình duyệt.
- **Chỉ** server/RPC được ghi đơn, thanh toán, tồn kho; khách chỉ đọc đơn của mình.
- **Xóa tài khoản:** đơn hàng được **giữ làm chứng từ**, địa chỉ/ghi chú bị ẩn danh hóa; không cho xóa khi còn đơn đang xử lý.

---

## 6. LUỒNG CHÍNH

**Onboarding:** Đăng ký → xác thực email → đồng ý dữ liệu sức khỏe → cơ thể & mục tiêu → bệnh lý/dị ứng/chế độ ăn → khẩu vị & người cùng ăn → xem kết quả kcal/macro → (tùy chọn) bật AI.

**AI gợi ý:** Mở "Hôm nay nấu gì?" → form (mặc định từ hồ sơ) → hệ thống lọc ứng viên an toàn → AI chọn & giải thích → hiển thị món + lý do + hệ số khẩu phần → mở công thức (đã scale) → chế độ nấu → "Tôi đã nấu" + 👍/👎.

**Nấu theo hướng dẫn:** Chọn khẩu phần → tick dụng cụ & nguyên liệu → bước sơ chế → bước nấu (hẹn giờ, mức lửa, mẹo) → hoàn thiện → bảo quản.

**Từ món ăn đến giao hàng:** Chọn công thức/thực đơn tuần → chọn khẩu phần → **Danh sách mua sắm** (trừ đồ đã có, ánh xạ sản phẩm, cảnh báo dị ứng) → "Thêm tất cả vào giỏ" → xem giỏ → Checkout (địa chỉ, thanh toán, mã giảm giá, báo giá) → đặt hàng (giữ chỗ kho) → *COD:* nhân viên xác nhận · *VNPay:* chuyển sang cổng → webhook xác nhận → `confirmed` → đóng gói → giao → hoàn tất → mua lại.

---

## 7. YÊU CẦU PHI CHỨC NĂNG
| Nhóm | Yêu cầu |
|---|---|
| Hiệu năng | LCP < 2,5 s (4G); danh sách/gợi ý < 500 ms (p95); AI < 12 s (p95) |
| Bảo mật | HTTPS; RLS mọi bảng; secret chỉ ở server; giới hạn tần suất AI; webhook thanh toán kiểm chữ ký; khách không ghi trực tiếp đơn/thanh toán/kho; không lưu thẻ |
| Riêng tư | Dữ liệu sức khỏe nhạy cảm: đồng ý rõ ràng, xóa/xuất theo yêu cầu, tuân thủ Nghị định 13/2023/NĐ-CP; đồng ý riêng khi dùng AI |
| Truy cập | WCAG 2.1 AA; chữ phóng 200%; có "Chữ lớn" |
| Tương thích | Trình duyệt 2 bản mới nhất; iOS 15+, Android 9+ |
| SEO | Prerender trang công thức, JSON-LD `Recipe`, sitemap |
| Quan sát | Sentry (loại dữ liệu sức khỏe), analytics không PII |

---

## 8. MIỄN TRỪ TRÁCH NHIỆM
Hiển thị ở onboarding, trang gợi ý/AI, chi tiết công thức, thực đơn, footer:
*"Thông tin chỉ mang tính tham khảo, không thay thế tư vấn của bác sĩ/chuyên gia dinh dưỡng. Nếu bạn đang dùng thuốc, mang thai, có bệnh thận hoặc bệnh nặng, hãy hỏi ý kiến bác sĩ trước khi thay đổi chế độ ăn."*
Trang AI thêm: *"Gợi ý do AI tạo ra từ danh sách món đã được kiểm duyệt; hệ thống tự lọc dị ứng và hạn chế theo hồ sơ nhưng bạn vẫn nên kiểm tra thành phần món."*

---

## 9. KPI
| Nhóm | Chỉ số | Sự kiện |
|---|---|---|
| Kích hoạt | % hoàn tất onboarding | `onboarding_completed` |
| Gắn kết | Món đã nấu/tuần, lượt dùng chế độ nấu | `cooked`, `cooking_mode_started` |
| AI | Lượt gợi ý, % 👍, % mở công thức, % fallback, độ trễ | `ai_suggest_run`, `ai_feedback` |
| Nội dung | % công thức đủ hướng dẫn, % báo lỗi | `recipe_reported` |
| Giữ chân | D1/D7/D30 | — |
| Chuyển đổi | Danh sách mua sắm → giỏ → đơn; tỉ lệ bỏ giỏ | `shopping_list_built`, `add_to_cart`, `begin_checkout`, `purchase` |
| Vận hành | Tỉ lệ hủy đơn, đơn thanh toán lỗi, thời gian xử lý đơn | `order_cancelled`, `payment_failed` |

---

## 10. RỦI RO
| Rủi ro | Mức | Giảm thiểu |
|---|---|---|
| Gợi ý gây hại sức khỏe | Cao | Lọc cứng ở DB trước khi tới AI, nhóm đỏ, duyệt chuyên gia, kiểm lại đầu ra AI, disclaimer |
| AI "bịa" món/số liệu | Cao | Chỉ chọn trong danh sách; số liệu do hệ thống tính; loại id lạ |
| Prompt injection qua ghi chú | TB | Coi ghi chú là dữ liệu; quy tắc an toàn không phụ thuộc AI |
| Lộ dữ liệu sức khỏe qua AI | Cao | Chỉ gửi dữ liệu ẩn danh tối thiểu; đồng ý riêng; log có hạn |
| Số liệu dinh dưỡng sai | Cao | Ghi nguồn; đối chiếu Bảng thành phần thực phẩm VN; duyệt |
| Chi phí AI tăng | TB | Model nhỏ; giới hạn lượt; ứng viên rút gọn; cache (P1) |
| Công thức thiếu chi tiết | TB | Trigger chặn xuất bản; mẫu soạn chuẩn |
| Gian lận/lỗi thanh toán | Cao | Webhook kiểm chữ ký + số tiền + idempotent; chỉ RPC ghi đơn; giới hạn COD |
| Hết hàng/bán vượt tồn | TB | Khóa dòng khi đặt, giữ chỗ, hoàn kho khi hủy; tự hủy đơn quá hạn thanh toán |
| Giao thực phẩm tươi | TB | Giới hạn khu vực/khung giờ; đối tác vận chuyển lạnh; chính sách đổi trả |
| Dị ứng khi mua nguyên liệu | Cao | Cảnh báo ở danh sách/giỏ/checkout; xác nhận bắt buộc |

---

## 11. TIÊU CHÍ NGHIỆM THU MVP
1. Onboarding ≤ 3 phút; kcal/macro khớp tính tay (golden: nữ 30 tuổi, 60 kg, 165 cm, vận động nhẹ → BMR 1.320,3; TDEE 1.815,3).
2. Hồ sơ dị ứng đậu phộng/cá/giáp xác: **0** món chứa chất đó xuất hiện ở danh sách, gợi ý, AI, thực đơn (test tự động).
3. Hồ sơ "tiểu đường + huyết áp": món vượt ngưỡng chặt nhất bị gắn Lưu ý.
4. Nhóm đỏ: không tạo được thực đơn tự động; AI không nhắc giảm cân.
5. AI với "2 người lớn + 1 trẻ em": mọi món độ cay ≤ 1; không có món chứa rượu/caffeine.
6. AI với người cao tuổi: natri/khẩu phần ≤ 600 mg.
7. Mọi `recipe_id` trong kết quả AI đều nằm trong danh sách ứng viên (test với AI giả trả id bịa).
8. Tắt mạng tới AI → vẫn nhận kết quả fallback.
9. Đổi khẩu phần 2 → 6: nguyên liệu và tổng dinh dưỡng cập nhật đúng; `scale_factor` từ AI khớp.
10. Công thức thiếu bước sơ chế/dụng cụ/ảnh không thể xuất bản.
11. Người dùng A không đọc được dữ liệu của B (RLS); không đọc được `ai_runs` của người khác.
12. Lighthouse mobile: Performance ≥ 85, Accessibility ≥ 90.
13. Danh sách mua sắm từ 2 công thức (tổng 6 khẩu phần) gộp đúng nguyên liệu trùng, trừ đúng đồ đã có, số lượng = ⌈cần ÷ quy cách⌉.
14. Từ công thức → "Thêm tất cả vào giỏ" → đặt COD thành công; giỏ rỗng sau khi đặt; kho giữ chỗ đúng.
15. Hai khách cùng đặt món còn 1: chỉ một đơn thành công, đơn còn lại báo `OUT_OF_STOCK`.
16. VNPay sandbox: webhook hợp lệ → đơn `confirmed` và trừ kho; webhook sai chữ ký/sai số tiền → bị từ chối; webhook lặp → không trừ kho hai lần.
17. Khách không đọc/sửa được đơn của người khác; không tự đổi trạng thái đơn, không tự ghi thanh toán, không sửa tồn kho/giá.
18. Hủy đơn đã thanh toán: hoàn kho và ghi "cần hoàn tiền"; đơn online quá 15 phút chưa trả tự hủy và nhả kho.
19. Sản phẩm chứa chất dị ứng của người dùng: có cảnh báo và yêu cầu xác nhận.

---

## 12. NGUỒN THAM KHẢO
- Mifflin-St Jeor, hệ số vận động: https://inchcalculator.com/mifflin-st-jeor-calculator · https://calcfyi.com/calculator/calorie/ · https://metricgate.com/docs/total-daily-energy-expenditure/
- kcal/macro 4–4–9, AMDR: https://calculatequick.com/health/calorie-calculator/
- Đối thủ: https://www.stork.ai/en/eat-this-much · https://www.recime.app/blog/?p=13754 · https://www.compsmag.com/?p=422642
- VNPay (tích hợp thanh toán, IPN, chữ ký HMAC-SHA512): https://sandbox.vnpayment.vn/apis/
- Natri & huyết áp (Viện Dinh dưỡng): https://viendinhduong.vn/en/lookup/de-tai-nghien-cuu-khoa-hoc/68035d58359ef722321fcf77
- Gout (Vinmec): https://www.vinmec.com/vie/bai-viet/che-do-dinh-duong-cho-benh-nhan-gout-vi · Thận (VnExpress): https://vnexpress.net/cac-benh-than-thuong-gap-va-che-do-dinh-duong-4150780.html · Dinh dưỡng phòng bệnh: https://www.sggp.org.vn/phong-benh-hieu-qua-bang-dinh-duong-post244009.html
- WHO (natri, đường tự do), AHA, ADA: **cần chuyên gia đối chiếu bản mới nhất trước khi phát hành.**
