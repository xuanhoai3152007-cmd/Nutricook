# 01 — PRD & TÀI LIỆU NGHIỆP VỤ
## Dự án: **NutriCook** — Nền tảng công thức nấu ăn, thực đơn theo chế độ dinh dưỡng & đặt nguyên liệu

> Phiên bản: 1.0 · Ngày: 19/10/2026 · Trạng thái: Draft để phát triển
> Stack: React + Supabase + Node.js + Vercel (chi tiết xem `02_KY_THUAT.md`)

---

## 1. TỔNG QUAN

### 1.1 Vấn đề
- Người dùng Việt Nam muốn ăn uống lành mạnh nhưng **không biết ăn bao nhiêu, ăn gì** cho đúng mục tiêu (giảm cân, tăng cơ, kiểm soát bệnh).
- Công thức trên mạng **không gắn với tình trạng sức khỏe** (tiểu đường, huyết áp, gout...) và không tính được dinh dưỡng theo khẩu phần.
- Sau khi chọn được món, người dùng phải **tự đi chợ** → mất thời gian, mua thừa/thiếu.

### 1.2 Giải pháp
Một web app giúp người dùng:
1. Khai báo hồ sơ cơ thể, mục tiêu, bệnh lý, dị ứng, khẩu vị.
2. Tự tính **nhu cầu năng lượng và macro** hằng ngày.
3. Nhận **công thức & thực đơn phù hợp** (lọc cứng theo dị ứng/bệnh lý, xếp hạng theo mục tiêu).
4. Điều chỉnh **khẩu phần** (số người ăn, kcal/bữa) → nguyên liệu và dinh dưỡng tự scale.
5. **Đặt nguyên liệu / suất ăn** từ danh sách mua sắm tự sinh ra.
6. Theo dõi nhật ký ăn uống & cân nặng.

### 1.3 Mục tiêu kinh doanh (12 tháng đầu)
| Mục tiêu | Chỉ số |
|---|---|
| Thu hút người dùng | 10.000 tài khoản đăng ký |
| Kích hoạt | ≥ 60% hoàn tất onboarding hồ sơ sức khỏe |
| Giữ chân | D30 retention ≥ 25% |
| Doanh thu | ≥ 8% người dùng có đơn hàng; AOV ≥ 250.000đ |
| Chất lượng nội dung | 500+ công thức đã được duyệt bởi chuyên gia dinh dưỡng |

### 1.4 Phân tích đối thủ (nghiên cứu)
| Sản phẩm | Điểm mạnh | Điểm yếu / Khoảng trống NutriCook khai thác |
|---|---|---|
| **Eat This Much** | Tự tạo thực đơn theo kcal/macro, ngân sách, tạo danh sách mua sắm, tích hợp giao hàng tạp hóa (Instacart/AmazonFresh) | Món ăn Tây, không có món Việt, không gắn bệnh lý Việt Nam |
| **Cronometer** | Theo dõi vi chất rất chi tiết, CSDL thực phẩm xác thực | Ít tính năng lên thực đơn/đi chợ, không cộng đồng |
| **MyFitnessPal** | CSDL lớn, quét mã vạch, cộng đồng | Lên thực đơn phải trả phí cao, không tối ưu món Việt |
| **Yummly** | Khám phá công thức, lọc chế độ ăn, shopping list, giao hàng | Theo dõi dinh dưỡng yếu |
| **ReciMe** | Bắt đầu từ công thức, shopping list chia theo lối đi siêu thị, kéo-thả meal plan, scale khẩu phần | Không đánh giá bệnh lý |

**Định vị NutriCook:** *món Việt + dinh dưỡng theo bệnh lý phổ biến ở Việt Nam + từ thực đơn đến giỏ hàng nguyên liệu chỉ vài chạm.*

---

## 2. NGƯỜI DÙNG (PERSONA)

| Persona | Mô tả | Nhu cầu chính |
|---|---|---|
| **Lan, 28, nhân viên VP** | Muốn giảm 5 kg, ít thời gian | Thực đơn 7 ngày, món ≤ 30 phút, đặt nguyên liệu giao tận nhà |
| **Minh, 35, dân gym** | Tăng cơ | Protein cao, đếm macro, nhật ký |
| **Bác Hùng, 58, tiểu đường type 2 + cao huyết áp** | Cần ăn đúng bệnh | Món ít đường/ít muối, cảnh báo thực phẩm không nên ăn, chữ to dễ đọc |
| **Chị Thu, 40, nội trợ** | Nấu cho gia đình 4 người | Scale khẩu phần, danh sách đi chợ gộp |
| **Admin / Chuyên gia dinh dưỡng** | Quản trị nội dung | Duyệt công thức, quản lý nguyên liệu, đơn hàng |
| **Nhân viên kho/giao hàng** | Xử lý đơn | Xem đơn, cập nhật trạng thái |

---

## 3. PHẠM VI (SCOPE)

### 3.1 MVP (Phase 1 – 8 tuần)
- Đăng ký/đăng nhập/đăng xuất, quên mật khẩu, đăng nhập Google.
- Onboarding hồ sơ sức khỏe + tính BMR/TDEE/macro.
- Thư viện công thức (tìm kiếm, lọc, chi tiết, scale khẩu phần, yêu thích).
- Gợi ý công thức theo hồ sơ (lọc cứng + xếp hạng).
- Thực đơn tuần (tự sinh + chỉnh tay).
- Danh sách mua sắm từ thực đơn/công thức.
- Giỏ hàng, đặt hàng nguyên liệu (COD + chuyển khoản/VNPay sandbox).
- Lịch sử đơn hàng.
- Admin cơ bản: công thức, nguyên liệu, sản phẩm, đơn hàng.

### 3.2 Phase 2 (tuần 9–16)
- Nhật ký ăn uống + biểu đồ cân nặng/macro.
- Đặt **suất ăn nấu sẵn** (meal box).
- Đánh giá & bình luận công thức.
- Thông báo (email, push web) nhắc bữa ăn, nhắc đơn.
- Trợ lý AI hỏi đáp dinh dưỡng (xem `04_AGENT.md` mục 9).
- Mã giảm giá, điểm thưởng.

### 3.3 Phase 3 (sau đó)
- App mobile (React Native/PWA), quét mã vạch, đồng bộ thiết bị đeo.
- Gói đăng ký Premium, cộng đồng, tư vấn trực tiếp chuyên gia.
- Đa ngôn ngữ (EN).

### 3.4 Ngoài phạm vi
- Chẩn đoán/điều trị y tế. Ứng dụng **không thay thế bác sĩ**.
- Vận hành đội giao hàng riêng (dùng đối tác: GHN/GHTK/Ahamove).

---

## 4. YÊU CẦU CHỨC NĂNG (FUNCTIONAL REQUIREMENTS)

Ký hiệu ưu tiên: **P0** = bắt buộc MVP · **P1** = Phase 2 · **P2** = sau.

### 4.1 Module A — Tài khoản & xác thực
| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| A1 | Đăng ký bằng email + mật khẩu (≥ 8 ký tự), xác thực email | P0 |
| A2 | Đăng nhập, đăng xuất, giữ phiên (refresh token) | P0 |
| A3 | Quên/đặt lại mật khẩu qua email | P0 |
| A4 | Đăng nhập Google OAuth | P0 |
| A5 | Xem/sửa hồ sơ cá nhân, đổi mật khẩu, xóa tài khoản (xóa dữ liệu theo yêu cầu) | P0 |
| A6 | Quản lý sổ địa chỉ giao hàng (nhiều địa chỉ, 1 mặc định) | P0 |
| A7 | Phân quyền: `customer`, `nutritionist`, `admin`, `staff` | P0 |
| A8 | Đăng nhập số điện thoại OTP | P2 |

### 4.2 Module B — Hồ sơ sức khỏe & mục tiêu
| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| B1 | Onboarding nhiều bước: giới tính, ngày sinh, chiều cao, cân nặng, mức vận động | P0 |
| B2 | Chọn mục tiêu: giảm cân / duy trì / tăng cân / tăng cơ / ăn lành mạnh | P0 |
| B3 | Chọn tình trạng sức khỏe (nhiều lựa chọn): tiểu đường type 2, tăng huyết áp, mỡ máu cao, gout, béo phì, thừa cân, bệnh thận (có cảnh báo), dạ dày, thiếu máu, mang thai/cho con bú (có cảnh báo) | P0 |
| B4 | Chọn dị ứng/không dung nạp: đậu phộng, hải sản, tôm cua, sữa, trứng, gluten, đậu nành, vừng... | P0 |
| B5 | Chế độ ăn: thường, ăn chay, thuần chay, pescatarian, low-carb, keto, DASH, Địa Trung Hải, halal | P0 |
| B6 | Không thích nguyên liệu (blacklist), ngân sách/bữa, thời gian nấu tối đa, trình độ nấu | P0 |
| B7 | Hệ thống tự tính BMI, BMR, TDEE, kcal mục tiêu, macro, giới hạn natri/đường (hiển thị công khai công thức) | P0 |
| B8 | Cập nhật cân nặng định kỳ, lưu lịch sử `body_metrics` | P1 |
| B9 | **Màn hình đồng ý (consent)** xử lý dữ liệu sức khỏe + disclaimer y tế | P0 |
| B10 | Tải/xóa toàn bộ dữ liệu sức khỏe | P1 |

### 4.3 Module C — Công thức & nguyên liệu
| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| C1 | Danh sách công thức: phân trang/cuộn vô hạn, ảnh, thời gian, kcal/khẩu phần, nhãn chế độ ăn | P0 |
| C2 | Tìm kiếm full-text (tiếng Việt không dấu), lọc: bữa, chế độ ăn, thời gian, kcal, protein, nguyên liệu có/không | P0 |
| C3 | Trang chi tiết: nguyên liệu, các bước, mẹo, bảng dinh dưỡng, cảnh báo theo hồ sơ | P0 |
| C4 | **Scale khẩu phần**: đổi số người ăn → nguyên liệu & dinh dưỡng tính lại | P0 |
| C5 | **Thay thế nguyên liệu** (VD: đường → chất tạo ngọt, thịt heo → ức gà) kèm tính lại dinh dưỡng | P1 |
| C6 | Yêu thích / lưu vào bộ sưu tập | P0 |
| C7 | Chế độ nấu từng bước (cooking mode, màn hình luôn sáng, hẹn giờ) | P1 |
| C8 | Người dùng tự tạo công thức riêng (private), tự tính dinh dưỡng | P1 |
| C9 | Đánh giá sao + bình luận | P1 |
| C10 | In/Chia sẻ công thức | P1 |

### 4.4 Module D — Gợi ý theo hồ sơ (Recommendation)
| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| D1 | **Lọc cứng**: loại công thức chứa dị ứng, vi phạm chế độ ăn, vi phạm quy tắc bệnh lý (mục 5.4) | P0 |
| D2 | **Xếp hạng điểm** theo: khớp mục tiêu kcal/macro, thành phần hạn chế, thời gian nấu, sở thích, ngân sách | P0 |
| D3 | Hiển thị "Vì sao gợi ý?" (giải thích: *ít natri, giàu chất xơ, phù hợp tiểu đường*) | P0 |
| D4 | Nhãn **Phù hợp / Cần lưu ý / Không nên** trên mỗi công thức theo hồ sơ | P0 |
| D5 | Gợi ý "món từ nguyên liệu đang có" | P1 |

### 4.5 Module E — Thực đơn (Meal Plan)
| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| E1 | Tạo thực đơn 1 ngày / 7 ngày, 3 bữa chính + 1–2 bữa phụ, bám kcal ±5% và macro ±10% | P0 |
| E2 | Kéo-thả hoán đổi món; nút "Đổi món khác" giữ nguyên ràng buộc | P0 |
| E3 | Khóa món yêu thích/không đổi (pin) | P1 |
| E4 | Tổng hợp dinh dưỡng theo bữa/ngày/tuần, so với mục tiêu | P0 |
| E5 | Tránh lặp món (không trùng trong 3 ngày) | P0 |
| E6 | Sinh **danh sách mua sắm** gộp nguyên liệu, trừ nguyên liệu đã có | P0 |
| E7 | Lưu/nhân bản/chia sẻ thực đơn | P1 |

### 4.6 Module F — Cửa hàng & đặt hàng
| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| F1 | Danh mục sản phẩm nguyên liệu (rau, thịt, cá, gia vị, ngũ cốc...) + gói nguyên liệu theo công thức ("Meal kit") | P0 |
| F2 | Ánh xạ nguyên liệu công thức → sản phẩm bán (ưu tiên giá/quy cách phù hợp) | P0 |
| F3 | Giỏ hàng (lưu DB khi đăng nhập), cập nhật số lượng, xóa | P0 |
| F4 | "Thêm tất cả nguyên liệu vào giỏ" từ công thức/thực đơn/shopping list | P0 |
| F5 | Checkout: chọn địa chỉ, khung giờ giao, phương thức thanh toán, ghi chú, mã giảm giá | P0 |
| F6 | Thanh toán: COD, chuyển khoản QR, VNPay/MoMo (sandbox → production) | P0 (COD+1 cổng) |
| F7 | Tính phí vận chuyển theo khu vực/đơn tối thiểu | P0 |
| F8 | Theo dõi trạng thái đơn, lịch sử, hủy đơn khi còn `pending/confirmed`, mua lại | P0 |
| F9 | Email xác nhận đơn + cập nhật trạng thái | P0 |
| F10 | Quản lý tồn kho, cảnh báo hết hàng, khóa số lượng khi đặt | P0 |
| F11 | Suất ăn nấu sẵn (đặt theo ngày/tuần, đăng ký định kỳ) | P1 |
| F12 | Hoàn tiền/đổi trả | P1 |

### 4.7 Module G — Nhật ký & theo dõi
| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| G1 | Ghi món đã ăn (từ công thức, nguyên liệu, nhập tay) | P1 |
| G2 | Vòng kcal/macro còn lại trong ngày, uống nước | P1 |
| G3 | Biểu đồ cân nặng, BMI, trung bình tuần | P1 |
| G4 | Cảnh báo vượt natri/đường theo bệnh lý | P1 |

### 4.8 Module H — Quản trị (Admin/CMS)
| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| H1 | CRUD nguyên liệu (dinh dưỡng /100g, dị ứng, purine, GI...) | P0 |
| H2 | CRUD công thức + tự tính dinh dưỡng từ nguyên liệu + upload ảnh | P0 |
| H3 | Quy trình duyệt: `draft → review → published` bởi chuyên gia dinh dưỡng | P0 |
| H4 | Quản lý sản phẩm, giá, tồn kho, danh mục | P0 |
| H5 | Quản lý đơn hàng, cập nhật trạng thái, in phiếu | P0 |
| H6 | Quản lý người dùng, phân quyền | P0 |
| H7 | Dashboard: doanh thu, đơn, người dùng mới, top công thức | P1 |
| H8 | Quản lý bảng quy tắc bệnh lý (`condition_rules`) có versioning | P1 |

---

## 5. QUY TẮC NGHIỆP VỤ (BUSINESS RULES)

### 5.1 Công thức tính năng lượng
**BMR – Mifflin-St Jeor (1990)**, W = kg, H = cm, A = tuổi:
- Nam: `BMR = 10W + 6.25H − 5A + 5`
- Nữ: `BMR = 10W + 6.25H − 5A − 161`

**TDEE = BMR × hệ số vận động**
| Mức | Mô tả | Hệ số |
|---|---|---|
| sedentary | Ít vận động, ngồi văn phòng | 1.2 |
| light | Tập nhẹ 1–3 buổi/tuần | 1.375 |
| moderate | Tập vừa 3–5 buổi/tuần | 1.55 |
| active | Tập nặng 6–7 buổi/tuần | 1.725 |
| very_active | Vận động viên/lao động nặng | 1.9 |

*Ghi chú:* Mifflin-St Jeor được xác thực trên người trưởng thành khỏe mạnh, sai số khoảng ±10%; kém chính xác hơn ở người cao tuổi, trẻ em hoặc rối loạn chuyển hóa → app phải hiển thị "ước tính".

### 5.2 Điều chỉnh theo mục tiêu
| Mục tiêu | Điều chỉnh kcal |
|---|---|
| Giảm cân nhẹ (~0.25 kg/tuần) | TDEE − 250 |
| Giảm cân (~0.5 kg/tuần) | TDEE − 500 |
| Duy trì | TDEE |
| Tăng cân/tăng cơ (~0.25–0.5 kg/tuần) | TDEE + 250 đến + 500 |

**Giới hạn an toàn (bắt buộc):**
- Sàn kcal: **Nữ ≥ 1.200**, **Nam ≥ 1.500** (nếu công thức cho kết quả thấp hơn → nâng lên sàn và hiển thị lý do).
- Tốc độ giảm cân tối đa ≤ 1% cân nặng/tuần; không cho chọn mục tiêu làm BMI < 18.5.
- Dưới 18 tuổi, mang thai, cho con bú, BMI < 18.5, có tiền sử rối loạn ăn uống → **không tạo kế hoạch giảm cân**; chỉ hiển thị nội dung chung + khuyên gặp chuyên gia.

### 5.3 Phân bổ macro
Mặc định theo khoảng AMDR: **Đạm 10–35%, Béo 20–35%, Tinh bột 45–65%** tổng năng lượng. 1 g đạm = 4 kcal, 1 g tinh bột = 4 kcal, 1 g béo = 9 kcal.

| Mục tiêu / chế độ | Đạm | Béo | Tinh bột | Ghi chú |
|---|---|---|---|---|
| Cân bằng (mặc định) | 20% | 30% | 50% | |
| Giảm cân | 25–30% | 25–30% | 40–50% | Đạm ≈ 1.2–1.6 g/kg |
| Tăng cơ | 25–30% | 25% | 45–50% | Đạm ≈ 1.6–2.0 g/kg |
| Low-carb | 25–30% | 35–40% | 25–30% | |
| Keto | 20% | 70% | 5–10% | Chỉ cho người khỏe mạnh; cảnh báo; không áp dụng cho tiểu đường/thận |
| DASH / tim mạch | 18–20% | 25–27% | 55% | Natri thấp |

Chất xơ ≥ 25 g/ngày (nữ), ≥ 30 g/ngày (nam) khi không có chống chỉ định. Đường tự do < 10% kcal. Chất béo bão hòa < 10% kcal. Natri < 2.000 mg/ngày (≈ 5 g muối) với người khỏe; **1.500 mg** khi tăng huyết áp (theo khuyến nghị AHA/WHO; cần duyệt bởi chuyên gia).

### 5.4 Quy tắc theo tình trạng sức khỏe (`condition_rules`)
> ⚠️ **Toàn bộ bảng này là cấu hình dạng dữ liệu, cần chuyên gia dinh dưỡng/bác sĩ thẩm định trước khi phát hành. Không hard-code trong source.**

| Tình trạng | Ràng buộc/Ưu tiên | Loại trừ cứng | Mức cảnh báo |
|---|---|---|---|
| **Tiểu đường type 2** | Tinh bột chia đều các bữa (≈ 40–50% kcal), chất xơ ≥ 25–30 g, ưu tiên GI thấp (≤ 55), đường tự do < 5–10% kcal, bữa phụ nhỏ | Nước ngọt, bánh kẹo ngọt, nước ép đóng chai, món có đường > 10 g/khẩu phần | Vàng + khuyên theo dõi đường huyết, người dùng insulin/thuốc hạ đường phải hỏi bác sĩ |
| **Tăng huyết áp** | Natri ≤ 1.500–2.000 mg/ngày, kali từ rau/quả, mô hình DASH, hạn chế nước mắm/muối/đồ muối/đồ chế biến | Dưa muối, cá khô mặn, mì gói, nước dùng cô đặc, món > 800 mg natri/khẩu phần | Vàng |
| **Mỡ máu cao** | Béo bão hòa < 7–10% kcal, cholesterol < 300 mg, nhiều chất xơ hòa tan, cá béo | Nội tạng, da/mỡ động vật, đồ chiên ngập dầu | Vàng |
| **Gout** | Hạn chế purine cao, tránh bia rượu, tránh đồ uống nhiều fructose, uống đủ nước, giảm thịt đỏ/hải sản/nội tạng, trứng và sữa ít béo thường chấp nhận được | Nội tạng, bia rượu, cá mòi/cá cơm, nước hầm xương đậm đặc, hải sản purine cao | Vàng |
| **Béo phì/thừa cân** | Thâm hụt kcal vừa phải, đạm cao, mật độ năng lượng thấp | Đồ chiên, đồ uống có đường | Xanh/Vàng |
| **Bệnh thận mạn** | Đạm, kali, phospho, natri, dịch phụ thuộc giai đoạn và có/không lọc máu | — | 🔴 **ĐỎ: không tự động tạo thực đơn**. Chỉ hiển thị thông tin chung + yêu cầu nhập chỉ định của bác sĩ |
| **Dạ dày/trào ngược** | Món mềm, ít dầu mỡ, ít cay chua, chia nhỏ bữa | Cay nóng, cà phê, rượu bia, đồ chua | Vàng |
| **Thiếu máu** | Tăng sắt (thịt đỏ nạc, rau xanh đậm), kèm vitamin C | — | Xanh |
| **Mang thai/cho con bú** | Nhu cầu đặc biệt | Cá sống, trứng/thịt tái, phô mai chưa tiệt trùng, rượu, cá thủy ngân cao | 🔴 Đỏ: chỉ gợi ý nội dung chung, khuyên gặp bác sĩ |

**Cơ chế đánh giá công thức theo hồ sơ** (trả về một trong 3 mức):
- `SUITABLE` (xanh): không vi phạm, đạt ≥ 1 ưu tiên.
- `CAUTION` (vàng): vượt ngưỡng mềm hoặc cần điều chỉnh khẩu phần/thay nguyên liệu.
- `AVOID` (đỏ): chứa dị ứng/loại trừ cứng → **ẩn khỏi gợi ý**, nếu truy cập trực tiếp thì hiển thị cảnh báo nổi bật.

Khi người dùng chọn nhiều bệnh: lấy **ràng buộc chặt nhất** cho từng chất dinh dưỡng và **hợp** các danh sách loại trừ.

### 5.5 Quy tắc khẩu phần & scale
- `quantity_scaled = quantity_base × (servings_target / servings_base)`.
- Gia vị/muối: scale phi tuyến (hệ số `√ratio`) nếu `scale_mode = 'sublinear'`.
- Dinh dưỡng mỗi khẩu phần = Σ(nguyên liệu × dinh dưỡng/100g × g / 100) ÷ servings_base; có hệ số giữ lại sau nấu (`yield_factor`) nếu cần.
- Làm tròn hiển thị: kcal nguyên; g 1 số lẻ; thìa/muỗng theo 0.25.

### 5.6 Quy tắc đặt hàng
**Vòng đời đơn hàng**
```
pending ──► confirmed ──► preparing ──► shipping ──► delivered ──► (completed)
   │            │              │
   └────────────┴──────────────┴──► cancelled
                                   delivered ──► refund_requested ──► refunded
```
| Trạng thái | Ai đổi | Điều kiện |
|---|---|---|
| pending | Hệ thống | Tạo đơn; COD hoặc chờ thanh toán |
| confirmed | Hệ thống/Staff | Đã thanh toán online hoặc staff xác nhận COD |
| preparing | Staff | Đang lấy hàng/đóng gói |
| shipping | Staff | Đã bàn giao vận chuyển (có mã vận đơn) |
| delivered | Staff/Webhook | Giao thành công |
| cancelled | Khách (trước `preparing`) / Staff | Hoàn kho, hoàn tiền nếu đã trả |

- **Tồn kho:** trừ khi đơn chuyển `confirmed`; giữ chỗ (`reserved`) 15 phút khi thanh toán online, quá hạn → hủy giữ chỗ.
- **Giá:** lưu snapshot giá/tên sản phẩm tại thời điểm đặt (`order_items`).
- **Phí ship:** miễn phí từ 300.000đ nội thành (cấu hình `shipping_rules`).
- **Mã giảm giá:** hạn dùng, giới hạn lượt, đơn tối thiểu, không cộng dồn (mặc định).
- **Cảnh báo dị ứng ở giỏ hàng:** nếu sản phẩm chứa chất dị ứng người dùng đã khai → bắt buộc xác nhận trước khi thêm.
- **Thanh toán online:** xác nhận thành công **chỉ dựa vào webhook đã kiểm chữ ký**, không tin kết quả redirect từ trình duyệt.

### 5.7 Quy tắc nội dung
- Công thức chỉ `published` sau khi nhân sự có vai trò `nutritionist` duyệt.
- Mỗi công thức phải có: ≥ 1 ảnh, ≥ 3 bước, nguyên liệu có đơn vị chuẩn, dinh dưỡng tính tự động, cờ dị ứng, cờ chế độ ăn.
- Mọi nội dung sức khỏe cần có nguồn tham khảo ở trang "Nguồn & Phương pháp".

---

## 6. LUỒNG NGHIỆP VỤ CHÍNH

### 6.1 Onboarding → Gợi ý
```
Đăng ký → Xác thực email → Consent + disclaimer → Nhập cơ thể & mục tiêu
→ Chọn bệnh lý/dị ứng/chế độ ăn → Hệ thống tính TDEE/macro/giới hạn
→ Hiển thị tóm tắt mục tiêu (có thể sửa) → Trang chủ cá nhân hóa
```

### 6.2 Từ thực đơn đến giao hàng
```
Tạo thực đơn tuần → Xem tổng hợp dinh dưỡng → Sinh shopping list
→ Đánh dấu "đã có" → Ánh xạ sang sản phẩm → Giỏ hàng → Checkout
→ Thanh toán → Xác nhận đơn (email) → Đóng gói → Giao → Hoàn tất → Đánh giá
```

### 6.3 Xử lý thanh toán online
```
Tạo order(pending) → Tạo payment_intent → Redirect cổng thanh toán
→ Cổng gọi webhook (server) → Verify chữ ký + số tiền + order_id
→ Cập nhật payments=paid, orders=confirmed (idempotent) → Gửi email
```

---

## 7. YÊU CẦU PHI CHỨC NĂNG (NFR)

| Nhóm | Yêu cầu |
|---|---|
| Hiệu năng | LCP < 2.5s (4G), API p95 < 500ms, sinh thực đơn 7 ngày < 3s |
| Khả dụng | 99.5%/tháng; lỗi hiển thị thân thiện, retry |
| Bảo mật | HTTPS, RLS mọi bảng, OWASP Top 10, rate limit auth & checkout, không lưu thẻ |
| Quyền riêng tư | Dữ liệu sức khỏe là dữ liệu nhạy cảm: consent rõ ràng, mã hóa truyền tải/lưu trữ, xóa theo yêu cầu, tuân thủ **Nghị định 13/2023/NĐ-CP** về bảo vệ dữ liệu cá nhân |
| Khả năng truy cập | WCAG 2.1 AA; chữ có thể phóng 200%; tương phản ≥ 4.5:1 |
| Tương thích | Chrome/Safari/Edge/Firefox 2 bản mới nhất; iOS 15+; Android 9+ |
| i18n | Mặc định `vi-VN`, sẵn sàng `en`; tiền `VND`, múi giờ `Asia/Ho_Chi_Minh` |
| SEO | SSR/prerender trang công thức (schema.org `Recipe`), sitemap, meta, Open Graph |
| Quan sát | Log lỗi (Sentry), analytics (PostHog/GA4), uptime check |

---

## 8. MIỄN TRỪ TRÁCH NHIỆM & PHÁP LÝ
- Hiển thị cố định ở onboarding, trang gợi ý, footer: *"Thông tin chỉ mang tính tham khảo, không thay thế tư vấn của bác sĩ/chuyên gia dinh dưỡng. Nếu bạn đang dùng thuốc, mang thai, có bệnh thận hoặc bệnh nặng, hãy hỏi ý kiến bác sĩ trước khi thay đổi chế độ ăn."*
- Điều khoản sử dụng, Chính sách bảo mật, Chính sách đổi trả, Chính sách vận chuyển.
- Thương mại điện tử: đăng ký/thông báo website TMĐT với Bộ Công Thương khi vận hành thật.
- Thực phẩm: tuân thủ quy định an toàn thực phẩm; nguồn gốc, hạn dùng, nhãn mác nhà cung cấp.

---

## 9. KPI & ĐO LƯỜNG
| Nhóm | Chỉ số | Sự kiện analytics |
|---|---|---|
| Acquisition | Đăng ký/ngày | `sign_up` |
| Activation | % hoàn tất onboarding | `onboarding_completed` |
| Engagement | Thực đơn tạo/tuần, công thức xem | `meal_plan_generated`, `recipe_viewed` |
| Conversion | Shopping list → giỏ → đơn | `add_to_cart`, `begin_checkout`, `purchase` |
| Retention | D1/D7/D30 | — |
| Chất lượng | % công thức bị báo lỗi, tỷ lệ hủy đơn | `recipe_reported`, `order_cancelled` |

---

## 10. RỦI RO & GIẢM THIỂU
| Rủi ro | Mức | Giảm thiểu |
|---|---|---|
| Gợi ý sai gây hại sức khỏe | Cao | Lọc cứng, duyệt chuyên gia, mức đỏ cho nhóm nguy cơ, disclaimer, log quyết định |
| Dữ liệu dinh dưỡng sai | Cao | CSDL thành phần thực phẩm Việt Nam (Viện Dinh dưỡng), kiểm duyệt, nguồn minh bạch |
| Lộ dữ liệu sức khỏe | Cao | RLS, consent, mã hóa, audit log, tối thiểu hóa dữ liệu |
| Thiếu nội dung ban đầu | TB | Seed 150 công thức, thuê chuyên gia, nhập khẩu có kiểm soát |
| Vận hành giao hàng thực phẩm tươi | TB | Giới hạn khu vực, khung giờ, đối tác lạnh |
| Gian lận thanh toán | TB | Webhook có chữ ký, idempotency, giới hạn COD |

---

## 11. TIÊU CHÍ NGHIỆM THU (MVP)
1. Người mới đăng ký xong, hoàn tất onboarding ≤ 3 phút và thấy kcal/macro mục tiêu đúng với tính tay (sai số ≤ 1 kcal).
2. Với hồ sơ "dị ứng đậu phộng", **0** công thức chứa đậu phộng xuất hiện trong gợi ý hoặc thực đơn (kiểm thử tự động 100%).
3. Hồ sơ "tiểu đường + huyết áp" chỉ nhận món thỏa ràng buộc chặt nhất của cả hai.
4. Hồ sơ nhóm đỏ (thận, mang thai, < 18 tuổi) không nhận thực đơn giảm cân tự động.
5. Đổi khẩu phần 2 → 6 người: nguyên liệu và dinh dưỡng cập nhật đúng.
6. Thực đơn 7 ngày: tổng kcal mỗi ngày trong ±5% mục tiêu, không lặp món trong 3 ngày.
7. Từ thực đơn bấm "Thêm vào giỏ" → đặt hàng COD thành công, email gửi đi, tồn kho trừ đúng.
8. Thanh toán online sandbox: webhook hợp lệ → đơn `confirmed`; webhook giả mạo → bị từ chối.
9. Người dùng A không đọc được dữ liệu/đơn hàng của người dùng B (kiểm thử RLS).
10. Điểm Lighthouse mobile: Performance ≥ 85, Accessibility ≥ 90.

---

## 12. THUẬT NGỮ
**BMR** chuyển hóa cơ bản · **TDEE** tổng năng lượng tiêu hao/ngày · **Macro** đạm/béo/tinh bột · **GI** chỉ số đường huyết · **DASH** chế độ ăn chống tăng huyết áp · **AMDR** khoảng phân bố macro chấp nhận được · **RLS** bảo mật mức hàng của Postgres.

---

## 13. NGUỒN THAM KHẢO (nghiên cứu)
- Mifflin M.D. et al., *A new predictive equation for resting energy expenditure in healthy individuals*, 1990 — công thức BMR, hệ số vận động 1.2–1.9: https://inchcalculator.com/mifflin-st-jeor-calculator · https://calcfyi.com/calculator/calorie/ · https://metricgate.com/docs/total-daily-energy-expenditure/
- Công thức kcal/macro (4–4–9) và AMDR: https://calculatequick.com/health/calorie-calculator/
- Đối thủ: Eat This Much https://www.stork.ai/en/eat-this-much · so sánh Cronometer/MyFitnessPal/ReciMe https://www.recime.app/blog/?p=13754 · so sánh Yummly/Cronometer https://www.compsmag.com/?p=422642
- Viện Dinh dưỡng Quốc gia (Bộ Y tế 2016, *Nhu cầu dinh dưỡng khuyến nghị cho người Việt Nam*): https://viendinhduong.vn
- Natri/Kali & tăng huyết áp (Viện Dinh dưỡng): https://viendinhduong.vn/en/lookup/de-tai-nghien-cuu-khoa-hoc/68035d58359ef722321fcf77
- Dinh dưỡng phòng bệnh (SGGP): https://www.sggp.org.vn/phong-benh-hieu-qua-bang-dinh-duong-post244009.html
- Gout (Vinmec): https://www.vinmec.com/vie/bai-viet/che-do-dinh-duong-cho-benh-nhan-gout-vi
- Bệnh thận & dinh dưỡng (VnExpress): https://vnexpress.net/cac-benh-than-thuong-gap-va-che-do-dinh-duong-4150780.html
- WHO (natri < 2 g/ngày, đường tự do < 10%), AHA (natri 1.500 mg cho THA), ADA Standards of Care (tiểu đường) — **cần chuyên gia đối chiếu bản mới nhất trước khi phát hành**.
