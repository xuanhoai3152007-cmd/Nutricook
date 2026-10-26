# 06 — LỘ TRÌNH PRODUCTION THAM KHẢO (KHÔNG BẮT BUỘC CHO ĐỒ ÁN)
## NutriCook — kế hoạch xác minh dữ liệu (công thức · dinh dưỡng · giá) và phát hành thật

> **Phạm vi đồ án:** NutriCook là sản phẩm học phần được trình diễn bằng dữ liệu mẫu. Không yêu cầu mở website công khai, xử lý dữ liệu sức khỏe thật, vận hành bán hàng hoặc qua các cổng G1–G8 để nộp bài.
> **Mục tiêu tùy chọn của file này:** ghi lại các điều kiện cần cân nhắc nếu nhóm phát triển NutriCook thành dịch vụ production trong tương lai. Các nội dung phía dưới không phải checklist nghiệm thu đồ án.
> Cập nhật theo thông tin tra cứu ngày 25/10/2026. Phần pháp lý chỉ mang tính định hướng, **cần luật sư/kế toán/cơ quan có thẩm quyền xác nhận** (mục 8).
> Đọc cùng: `00_AI_EXECUTION_BRIEF.md` (quy tắc demo) · `01`–`05` (nghiệp vụ, kỹ thuật, UI, agent, backend).

---

## 1. TÓM TẮT: 8 CỔNG PHẢI QUA

Bản chính thức chỉ được bật khi **cả 8 cổng** (Gate) đạt. Hệ thống chặn bằng kỹ thuật ở các cổng G1–G4 và G7 (mục 7): quản trị viên **không thể tắt `demo_mode`** khi còn việc chặn.

| Cổng | Nội dung | Người chịu trách nhiệm | Bằng chứng cần có |
|---|---|---|---|
| **G1** Dữ liệu dinh dưỡng | Mọi nguyên liệu dùng trong công thức công khai có số liệu **có nguồn, đã đối chiếu, đã qua kiểm tra hợp lý** | Chuyên gia dinh dưỡng + nhập liệu | `data_status = 'verified'`, `source_ref`, `source_version`, người xác minh |
| **G2** Công thức | Mỗi công thức đã **nấu thử thật**, biên tập, **được chuyên gia duyệt**, đủ chi tiết, có ảnh thật | Biên tập + bếp thử + chuyên gia dinh dưỡng | `test_cooked_at/by`, `reviewed_by`, ảnh, ghi chú nấu thử |
| **G3** Quy tắc y khoa | Mọi `condition_rules` đang bật được **bác sĩ/chuyên gia có chuyên môn** duyệt, ghi nguồn khuyến nghị | Bác sĩ/chuyên gia dinh dưỡng lâm sàng | `approved_by`, `approved_at`, `source_url`, biên bản duyệt |
| **G4** Giá & sản phẩm | Giá, khối lượng tịnh, chất gây dị ứng, nhà cung cấp, ảnh **đã xác nhận với nhà cung cấp thật** | Vận hành/mua hàng | `price_status = 'verified'`, `net_weight_verified`, `allergen_verified`, báo giá/hợp đồng |
| **G5** Pháp lý & tuân thủ | Đăng ký kinh doanh, TMĐT, an toàn thực phẩm, dữ liệu cá nhân, thuế, chính sách | Chủ sở hữu + luật sư/kế toán | Giấy tờ/biên nhận, chính sách đã đăng |
| **G6** Thanh toán thật | Hợp đồng và tích hợp VNPay môi trường thật, đối soát, hoàn tiền | Tài chính + dev | Merchant production, test giao dịch thật nhỏ, quy trình đối soát |
| **G7** Kỹ thuật & bảo mật | Môi trường production, sao lưu, giám sát, kiểm thử tự động, rà soát bảo mật | Dev/DevOps | CI xanh, `rpc_go_live_check()` hết blocker, kết quả pgTAP/Deno/E2E |
| **G8** Vận hành & hỗ trợ | Quy trình xử lý đơn, hoàn tiền, khiếu nại, báo lỗi dữ liệu, sự cố | Vận hành | Tài liệu quy trình, người trực, kênh hỗ trợ |

**Nguyên tắc:** *không có gì "tạm duyệt"*. Thiếu bằng chứng = chưa đạt. Dữ liệu không xác minh được thì **không đưa lên bản chính thức** (ẩn món/ẩn sản phẩm), chứ không "để tạm".

---

## 2. KHOẢNG CÁCH GIỮA DEMO VÀ CHÍNH THỨC

| Hạng mục | Demo hiện tại | Bản chính thức cần |
|---|---|---|
| Dinh dưỡng nguyên liệu | 28 mục **ước tính** (`source = 'seed_estimate'`) | Số liệu có nguồn công bố, kèm mã tham chiếu và phiên bản |
| Công thức | 6 món viết sẵn, chưa nấu thử, chưa chuyên gia duyệt | ≥ 50 món cho thử nghiệm kín, ≥ 150 cho mở công khai, mục tiêu 300; **mỗi món đã nấu thử** |
| Quy tắc bệnh lý | 7 bộ nháp, `approved_at = NULL` | Được bác sĩ/chuyên gia duyệt, có nguồn, có phiên bản và lịch rà soát |
| Sản phẩm & giá | 27 sản phẩm, giá/quy cách minh họa, kho 100 | Sản phẩm của nhà cung cấp thật, giá chốt, khối lượng tịnh, dị ứng theo nhãn, kho thật |
| Ảnh | Đường dẫn giả | Ảnh món đã nấu thật và ảnh sản phẩm thật, có bản quyền |
| Thanh toán | VNPay **sandbox**, COD thử | VNPay production, đối soát, hoàn tiền; COD có quy trình thu tiền |
| Pháp lý | Chưa | Đăng ký/thông báo, ATTP, dữ liệu cá nhân, thuế, chính sách |
| Hạ tầng | Local/staging | Production (Supabase Pro, sao lưu PITR), giám sát, cảnh báo, CAPTCHA, SMTP riêng |
| Kiểm thử | Thử tay 28 kịch bản (SQL) | pgTAP + Deno + Vitest + Playwright, chạy trong CI |
| Vận hành | Chưa | Đội xử lý đơn/hoàn tiền/hỗ trợ, quy trình sự cố |

---

## 3. NHÂN SỰ & PHÂN VAI

| Vai trò | Việc chính | Quyền trong hệ thống |
|---|---|---|
| **Chủ sản phẩm** | Quyết định phạm vi, ngân sách, chịu trách nhiệm cuối cùng; ký duyệt từng Gate | `admin` |
| **Chuyên gia dinh dưỡng** (có chứng chỉ/đào tạo phù hợp) | Xác minh số liệu nguyên liệu, duyệt công thức, soạn/duyệt quy tắc bệnh lý (cùng bác sĩ) | `nutritionist` |
| **Bác sĩ/chuyên gia lâm sàng** | Duyệt quy tắc cho tiểu đường, huyết áp, mỡ máu, gout, thận…; xác định giới hạn an toàn và nhóm "đỏ" | Ký biên bản; có thể giữ `nutritionist` |
| **Đầu bếp/biên tập công thức** | Soạn, **nấu thử**, chụp ảnh, ghi thời gian/khối lượng thực tế | `nutritionist` (soạn nháp) |
| **Nhập liệu dữ liệu** | Nhập nguyên liệu từ nguồn theo mẫu CSV, đối chiếu lần 2 | Nhập qua bảng tạm; không tự xác minh |
| **Vận hành/mua hàng** | Chọn nhà cung cấp, báo giá, quy cách, kho, đóng gói, giao hàng, đổi trả | `staff` |
| **Kế toán** | Thuế, hóa đơn, đối soát thanh toán, giá vốn | Không cần tài khoản hệ thống |
| **Dev/DevOps** | Triển khai, kiểm thử, bảo mật, giám sát, import dữ liệu | Quyền hạ tầng |
| **Luật sư/tư vấn tuân thủ** | Xác nhận mục 8, soạn chính sách | — |

**Nguyên tắc hai người (four-eyes):** người nhập dữ liệu **không** được là người xác minh; người soạn công thức **không** được là người duyệt xuất bản.

---

## 4. DỮ LIỆU DINH DƯỠNG NGUYÊN LIỆU (Gate G1)

### 4.1 Nguồn số liệu (thứ tự ưu tiên)
| Ưu tiên | Nguồn | Ghi chú |
|---|---|---|
| 1 | **Bảng thành phần thực phẩm Việt Nam** (Viện Dinh dưỡng, Bộ Y tế) | Phù hợp thực phẩm Việt. **Chưa xác minh** phiên bản mới nhất và điều khoản sử dụng/thương mại → liên hệ Viện Dinh dưỡng xin xác nhận bằng văn bản trước khi nhập số lượng lớn |
| 2 | **USDA FoodData Central** (dữ liệu của Chính phủ Hoa Kỳ, công khai miễn phí, có API, cập nhật định kỳ) | Dùng bù cho nguyên liệu nhập khẩu/không có ở bảng Việt Nam; nên ghi nguồn và phiên bản. Xác nhận lại điều khoản sử dụng hiện hành trên trang chính thức khi bắt đầu nhập |
| 3 | Cơ sở dữ liệu FAO/INFOODS hoặc bảng của nước lân cận (ASEAN) | Khi hai nguồn trên thiếu |
| 4 | **Nhãn dinh dưỡng của chính sản phẩm bán** | Bắt buộc với sản phẩm chế biến/đóng gói (nước mắm, nước tương, sữa chua…); natri khác nhau rất lớn giữa các thương hiệu |
| 5 | Phân tích phòng thí nghiệm | Cho món đặc trưng/nhãn hiệu riêng hoặc khi hai nguồn lệch nhau |

> Số liệu hiện có của **nước mắm (≈ 7.000 mg natri/100 g)** và **nước tương (≈ 5.500 mg/100 g)** chỉ là ước tính — natri là chỉ số then chốt cho người tăng huyết áp, **phải lấy theo nhãn sản phẩm bán thật**.

### 4.2 Quy tắc nhập
- Giá trị tính trên **100 g phần ăn được, trạng thái sống/chưa chế biến** (công thức cũng dùng khối lượng sống để nhất quán). Ghi rõ nếu nguồn là nấu chín và quy đổi.
- Mỗi dòng bắt buộc: `source`, `source_ref` (mã thực phẩm trong nguồn), `source_version` (năm/phiên bản). **Không có nguồn = không xác minh được.**
- Tag (`meat`, `fish`, `shellfish`, `animal`, `soy`, `high_sodium`, `organ_meat`, `alcohol`…), mức purine (0–2), GI: ghi nguồn tham chiếu trong `source`; nếu chưa có thì để trống/0 **và** không dùng để gắn nhãn "an toàn" cho bệnh tương ứng.
- **Dị ứng** (`ingredient_allergens`) phải được người xác minh đối chiếu độc lập; với sản phẩm chế biến, dị ứng theo **nhãn thật** (thành phần, "có thể chứa…").

### 4.3 Quy trình
```
Lập danh sách nguyên liệu cần (từ các công thức dự kiến)
→ Tra nguồn ưu tiên, nhập vào CSV mẫu (4.4) → import vào bảng tạm staging_ingredients
→ Người nhập đối chiếu lần 2 (người khác) → upsert vào ingredients (data_status = 'unverified')
→ Chạy ingredient_sanity() lọc số liệu vô lý
→ Chuyên gia dinh dưỡng xác minh: đặt data_status = 'verified'  (trigger tự ghi người xác minh + thời điểm)
→ Đổi bất kỳ số liệu dinh dưỡng nào của dòng đã xác minh → tự về 'unverified' (phải xác minh lại)
```
**Kiểm tra hợp lý tự động (`ingredient_sanity`)** — chặn xác minh nếu: kcal lệch > 15% so với ước tính từ đạm/béo/carb/xơ; tổng đạm+carb+béo > 100 g/100 g; béo bão hòa > tổng béo; đường hoặc xơ > carb; natri ngoài 0–40.000 mg. Đây chỉ là **lưới chặn lỗi nhập**, không thay thế việc đối chiếu nguồn.

### 4.4 Mẫu CSV & câu lệnh import (đã chạy thử trên PostgreSQL)
Cột CSV: `slug,name_vi,name_en,category,kcal,protein_g,carb_g,fat_g,sat_fat_g,fiber_g,sugar_g,sodium_mg,purine_level,glycemic_index,tags,source,source_ref,source_version` (`tags` phân tách bằng `;`).
```sql
create table if not exists public.staging_ingredients (
  slug text, name_vi text, name_en text, category text,
  kcal numeric, protein_g numeric, carb_g numeric, fat_g numeric, sat_fat_g numeric, fiber_g numeric, sugar_g numeric,
  sodium_mg numeric, purine_level smallint, glycemic_index smallint, tags text,
  source text, source_ref text, source_version text);
-- (Supabase Studio → Table editor → Import CSV vào staging_ingredients)

insert into ingredients (slug,name_vi,name_en,category,kcal,protein_g,carb_g,fat_g,sat_fat_g,fiber_g,sugar_g,sodium_mg,
                         purine_level,glycemic_index,tags,source,source_ref,source_version,data_status)
select s.slug,s.name_vi,s.name_en,s.category,s.kcal,s.protein_g,s.carb_g,s.fat_g,s.sat_fat_g,s.fiber_g,s.sugar_g,s.sodium_mg,
       coalesce(s.purine_level,0),s.glycemic_index,string_to_array(s.tags,';'),s.source,s.source_ref,s.source_version,'unverified'
from staging_ingredients s
on conflict (slug) do update set
  name_vi=excluded.name_vi, kcal=excluded.kcal, protein_g=excluded.protein_g, carb_g=excluded.carb_g, fat_g=excluded.fat_g,
  sat_fat_g=excluded.sat_fat_g, fiber_g=excluded.fiber_g, sugar_g=excluded.sugar_g, sodium_mg=excluded.sodium_mg,
  purine_level=excluded.purine_level, glycemic_index=excluded.glycemic_index, tags=excluded.tags,
  source=excluded.source, source_ref=excluded.source_ref, source_version=excluded.source_version,
  data_status='unverified', verified_by=null, verified_at=null;

-- xem dòng có vấn đề trước khi xác minh
select slug, ingredient_sanity(i) as van_de from ingredients i where data_status='unverified' and ingredient_sanity(i) <> '';
-- (chuyên gia dinh dưỡng) xác minh các dòng đã đối chiếu và sạch
update ingredients i set data_status='verified' where slug = any(:'danh_sach_slug') and ingredient_sanity(i) = '';
```
Sau khi xác minh xong **chuyển mọi `source = 'seed_estimate'` còn lại sang trạng thái không dùng** (xóa khỏi công thức hoặc thay số liệu).

### 4.5 Dinh dưỡng của công thức
- Hệ thống tự tính từ nguyên liệu **sống** (trigger `recompute_recipe_nutrition`). Hiển thị nhãn: *"Giá trị ước tính theo nguyên liệu sống; thực tế thay đổi theo cách nấu và lượng gia vị."*
- Với món chủ lực/nhóm bệnh nhạy cảm, nên đối chiếu một lần bằng phân tích phòng thí nghiệm hoặc bằng phần mềm dinh dưỡng đã được cấp phép, ghi vào `test_notes`.
- Chưa mô hình hóa: hao hụt/hấp thụ dầu khi chiên, nước nấu bỏ đi, nước dùng không ăn hết. Món nhạy cảm (natri, đường) cần ghi chú rõ phần nước dùng/nước sốt có tính vào khẩu phần hay không.

**Tiêu chí đạt G1:** mọi nguyên liệu trong công thức đã xuất bản có `data_status = 'verified'`; không còn `seed_estimate`; tỉ lệ mẫu kiểm chéo ngẫu nhiên (10% dòng, người thứ ba tra lại nguồn) sai lệch ≤ 5%.

---

## 5. CÔNG THỨC (Gate G2)

### 5.1 Quy trình biên tập
```
Đề xuất món (theo kế hoạch phủ: bữa × bệnh lý × dị ứng × độ tuổi × ngân sách)
→ Soạn nháp (đủ mục theo PRD 4.3) trong trình soạn của admin  [draft]
→ NẤU THỬ thật tại bếp thử: ghi thời gian sơ chế/nấu thực tế, khối lượng thành phẩm, điều chỉnh, ảnh
   → ghi test_cooked_by / test_cooked_at / cooked_yield_g / test_notes
→ Biên tập nội dung (câu chữ, chính tả, an toàn thao tác)               [review]
→ Chuyên gia dinh dưỡng duyệt (số liệu, nhãn dị ứng/chế độ ăn, lưu ý sức khỏe) → Xuất bản   [published]
```
**Ở chế độ chính thức (`demo_mode = false`) cơ sở dữ liệu tự chặn xuất bản nếu:** còn nguyên liệu chưa xác minh (`INGREDIENT_NOT_VERIFIED`), chưa nấu thử (`NEED_TEST_COOK`), không có người duyệt (`NEED_REVIEWER`), cộng các ràng buộc cũ (≥ 3 nguyên liệu, ≥ 4 bước, có bước sơ chế, bước ≥ 20 ký tự, ảnh, dụng cụ).
**Sửa công thức đã xuất bản** (nguyên liệu hoặc bước) ở chế độ chính thức → công thức tự quay về `review` và mất người duyệt, phải duyệt lại.

### 5.2 Chuẩn nội dung
- Mỗi bước nêu **mức lửa, thời gian, dấu hiệu đã đạt**; mẹo và lỗi thường gặp là kinh nghiệm thật từ lần nấu thử, không chép chung chung.
- **An toàn thực phẩm trong hướng dẫn:** nhiệt độ chín an toàn, rửa tay/dụng cụ khi chạm thịt sống, bảo quản (thời gian tối đa, nhiệt độ tủ lạnh), cảnh báo cho thai phụ/trẻ nhỏ/người cao tuổi khi dùng đồ tái/sống.
- **Dị ứng & chế độ ăn:** do hệ thống suy ra từ nguyên liệu; người duyệt đối chiếu lại bằng mắt với từng công thức.
- **Bản quyền:** công thức, ảnh và lời văn phải **do bạn tự soạn hoặc có giấy phép**. Không sao chép từ trang khác; công thức dân gian vẫn cần tự viết lại bằng lời của mình và nấu thử.
- **Ảnh:** ảnh món thật đã nấu; WebP ≤ 2 MB; có chủ quyền/hợp đồng với người chụp.

### 5.3 Kế hoạch phủ nội dung
| Mốc | Số món | Yêu cầu phân bố tối thiểu |
|---|---|---|
| Beta kín | ≥ 50 | Mỗi bữa (sáng/trưa/tối/phụ) ≥ 8 món; ≥ 8 món "ít natri"; ≥ 8 món phù hợp tiểu đường (ít đường, giàu xơ); ≥ 5 món cho người cao tuổi (mềm, ít muối); ≥ 5 món thân thiện trẻ em; ≥ 8 món không chứa mỗi nhóm dị ứng chính (cá, giáp xác, sữa, trứng, đậu nành, gluten) |
| Mở công khai | ≥ 150 | Tăng độ đa dạng vùng miền, thời gian nấu, ngân sách |
| Mục tiêu | 300 | Theo PRD |
**Ghi nhận độ phủ nguyên liệu → sản phẩm:** mọi nguyên liệu (không tùy chọn) của công thức công khai phải có sản phẩm đang bán, nếu không danh sách mua sắm sẽ thiếu (kiểm ở `rpc_go_live_check`: `ING_NO_PRODUCT`).

**Tiêu chí đạt G2:** 100% công thức công khai có `test_cooked_at`, `reviewed_by`, ảnh thật; không còn công thức "mẫu" của bản demo (nếu giữ lại thì phải được nấu thử và duyệt như mọi món khác).

---

## 6. QUY TẮC Y KHOA (Gate G3)

1. **Người duyệt:** bác sĩ hoặc chuyên gia dinh dưỡng lâm sàng có chuyên môn phù hợp với từng bệnh. Không dùng AI hay người không chuyên để "duyệt".
2. **Nguồn:** chỉ dùng khuyến nghị công bố bởi tổ chức uy tín (Bộ Y tế/Viện Dinh dưỡng Việt Nam, WHO, các hội chuyên ngành tương ứng như tim mạch, nội tiết/tiểu đường, thận…) — **ghi URL và phiên bản vào `source_url`** và biên bản duyệt.
3. **Nội dung cần chốt bằng văn bản:**
   - Ngưỡng cho từng bệnh: natri/ngày và /khẩu phần, đường/khẩu phần, chất xơ, mức purine, nhóm nguyên liệu loại trừ, nhóm ưu tiên.
   - **Nhóm "đỏ"** (không tự lập thực đơn): bệnh thận mạn, mang thai/cho con bú, dưới 18 tuổi, BMI < 18,5, rối loạn ăn uống… và cách hiển thị.
   - Quy tắc **nhiều bệnh cùng lúc** (lấy ngưỡng chặt nhất — xác nhận có phù hợp lâm sàng không).
   - Quy tắc theo **nhóm tuổi người ăn** (trẻ em/thiếu niên/cao tuổi) đang dùng trong `rpc_recommend_recipes`.
   - Sàn năng lượng (nữ 1.200 / nam 1.500 kcal) và giới hạn tốc độ giảm cân.
   - Nội dung cảnh báo "người đang dùng thuốc (insulin, thuốc hạ áp, lợi tiểu, warfarin…) phải hỏi bác sĩ".
4. **Thử nghiệm kịch bản:** bộ hồ sơ giả (persona) do người duyệt chọn (vd 10–20 hồ sơ gồm đa bệnh, dị ứng, người cao tuổi, trẻ em, nhóm đỏ). Với mỗi hồ sơ, chuyên gia xem kết quả gợi ý/thực đơn/AI và xác nhận **không có món nào gây hại**; ghi lại.
5. **Nhật ký thay đổi:** mỗi lần sửa quy tắc là một phiên bản mới (`version`), người duyệt mới, ngày duyệt. Rà soát định kỳ 6–12 tháng hoặc khi nguồn khuyến nghị cập nhật.
6. **Ngôn từ:** không dùng "điều trị", "chữa", "thay thế thuốc"; dùng "tham khảo", "hỗ trợ lựa chọn món". Giữ `MedicalDisclaimer` ở mọi nơi.
7. **AI:** giữ nguyên biên an toàn; thêm kiểm thử nhắm vào các hồ sơ ở bước 4 (dị ứng, nhóm đỏ, trẻ em, prompt-injection).

**Tiêu chí đạt G3:** `rpc_go_live_check` không còn `RULES_UNAPPROVED`; có biên bản duyệt lưu trữ; bộ kịch bản ở bước 4 đạt 100%.

---

## 7. GIÁ, SẢN PHẨM, VẬN HÀNH BÁN HÀNG (Gate G4)

### 7.1 Nhà cung cấp & sản phẩm
- Chọn nhà cung cấp thật (hợp đồng/báo giá), ghi vào `products.supplier` và nguồn giá vào `price_source`.
- **Quy cách:** `pack_size_g` phải là **khối lượng tịnh** (đã cân hoặc ghi trên nhãn), không phải "ước chừng". Đánh dấu `net_weight_verified = true` sau khi cân/đối chiếu.
- **Sản phẩm tươi sống bán theo cân** (thịt, cá, rau): giá và khối lượng thực tế thay đổi → chọn mô hình: (a) **bán theo gói cố định** (vd khay 500 g) với sai số công bố, hoặc (b) bán theo cân + điều chỉnh tiền khi cân thực tế. Mô hình (b) cần thêm chức năng điều chỉnh đơn (chưa có trong hệ thống).
- **Dị ứng:** đối chiếu thành phần trên nhãn từng sản phẩm; dị ứng của sản phẩm tự đồng bộ từ nguyên liệu gắn kèm, nên nếu nhãn sản phẩm bán khác (thêm đậu nành, gluten, "có thể chứa…") phải sửa liên kết ở `ingredient_allergens` hoặc tạo nguyên liệu riêng cho sản phẩm đó rồi đánh dấu `allergen_verified = true`.
- **Truy xuất & hạn dùng:** ghi nguồn gốc, hạn dùng, cách bảo quản vào `label_note`; thực phẩm lạnh/tươi cần quy trình chuỗi lạnh khi giao.
- **Ảnh thật** của sản phẩm đã cân/đóng gói.

### 7.2 Giá
| Hạng mục | Việc cần làm |
|---|---|
| Giá vốn | Nhập `cost_vnd` từ báo giá/hóa đơn nhà cung cấp |
| Giá bán | Giá vốn + chi phí đóng gói/lạnh/giao + biên lợi nhuận + thuế; quyết định hiển thị giá **đã gồm VAT** hay chưa (kế toán xác nhận), `vat_rate` |
| Phí vận chuyển | Thay quy tắc mẫu bằng bảng phí thật theo khu vực; ngưỡng miễn phí do bài toán lãi/lỗ |
| Mã giảm giá | Xóa mã mẫu `WELCOME10`; chỉ tạo mã có kế hoạch và ngân sách |
| Cập nhật giá | Theo chu kỳ (vd hằng tuần cho rau/thịt/cá); mỗi lần đổi giá hệ thống **ghi `price_history` và đưa sản phẩm về `unverified`** để người có thẩm quyền xác nhận lại |
| Kiểm tra hợp lý | So sánh giá/gram với thị trường; cảnh báo biến động > ngưỡng (vd 20%) trước khi xác nhận |

**Mẫu CSV giá** (nhập qua bảng tạm, đã chạy thử): `sku,name,supplier,unit,pack_size_g,price_vnd,cost_vnd,vat_rate,price_source,net_weight_verified,allergen_verified`
```sql
create table if not exists public.staging_products (
  sku text, name text, supplier text, unit text, pack_size_g numeric, price_vnd bigint, cost_vnd bigint,
  vat_rate numeric, price_source text, net_weight_verified boolean, allergen_verified boolean);
update products p set
  name=s.name, supplier=s.supplier, unit=s.unit, pack_size_g=s.pack_size_g, price_vnd=s.price_vnd, cost_vnd=s.cost_vnd,
  vat_rate=s.vat_rate, price_source=s.price_source, net_weight_verified=s.net_weight_verified,
  allergen_verified=s.allergen_verified, price_status='unverified'
from staging_products s where p.sku = s.sku;
-- sau khi vận hành đối chiếu báo giá/cân thực tế:
update products set price_status='verified' where sku = any(:'danh_sach_sku') and price_source is not null and supplier is not null;
```
Sản phẩm mới: thêm bằng `insert` (kèm `ingredient_id`, `pack_size_g`, danh mục) rồi xác minh như trên.

### 7.3 Vận hành
- **Kho:** kiểm kê định kỳ, đối chiếu `stock`/`reserved`; đơn COD tồn đọng ở trạng thái `pending` giữ chỗ → có quy trình xác nhận/hủy trong ngày.
- **Giao hàng:** chọn đối tác (GHN/GHTK/Ahamove hoặc đội riêng); khung giờ; thực phẩm lạnh; chính sách hàng hỏng/thiếu.
- **Đổi trả/hoàn tiền:** `rpc_cancel_order` chỉ hoàn kho và ghi "cần hoàn tiền"; **nhân viên hoàn tiền thật** với cổng thanh toán rồi gọi `rpc_mark_refunded`.
- **Hỗ trợ:** kênh liên hệ, thời gian phản hồi, mẫu trả lời, quy trình khiếu nại chất lượng.

**Ở chế độ chính thức**, trigger chặn **đặt hàng** nếu sản phẩm chưa `price_status = 'verified'`, chưa `net_weight_verified` hoặc chưa `allergen_verified` (`PRODUCT_NOT_VERIFIED`).

**Tiêu chí đạt G4:** `rpc_go_live_check` không còn `PROD_UNVERIFIED`, `ING_NO_PRODUCT` (nguyên liệu chính), `PROD_NO_IMAGE`; có hợp đồng/báo giá nhà cung cấp; thử đặt, đóng gói, giao 5–10 đơn nội bộ thành công.

---

## 8. PHÁP LÝ & TUÂN THỦ (Gate G5) — *định hướng, cần chuyên gia xác nhận*

> Các điểm dưới đây dựa trên thông tin công khai tra cứu ngày 25/10/2026 từ báo/cổng pháp luật thứ cấp. Quy định đang thay đổi nhanh (nhiều văn bản mới có hiệu lực 2026). **Phải xác nhận với luật sư/kế toán và cơ quan có thẩm quyền trước khi nộp hồ sơ hoặc công bố.**

### 8.1 Tư cách kinh doanh
- Đăng ký **doanh nghiệp hoặc hộ kinh doanh** với ngành nghề bán lẻ thực phẩm/thương mại điện tử phù hợp; có tài khoản ngân hàng đứng tên pháp nhân/hộ kinh doanh (cần cho VNPay).

### 8.2 Thương mại điện tử
- **Luật Thương mại điện tử 2025 (số 122/2025/QH15)** có hiệu lực từ **01/07/2026**, cùng **Nghị định 248/2026/NĐ-CP** hướng dẫn thi hành (cùng hiệu lực). Người bán online **không thể ẩn danh**; phải cung cấp thông tin định danh và thông tin bán hàng minh bạch.
- Website bán hàng tự vận hành thường thuộc diện **thông báo** (sàn nhiều người bán thuộc diện **đăng ký**). Từ 01/07/2025 thẩm quyền tiếp nhận hồ sơ thông báo website bán hàng được phân cấp cho **UBND cấp tỉnh**; **cần kiểm tra thủ tục hiện hành sau khi Luật mới có hiệu lực** (cổng của Bộ Công Thương và Sở Công Thương địa phương).
- Công bố đầy đủ trên website: thông tin đơn vị bán, điều khoản sử dụng, **chính sách đổi trả/hoàn tiền, vận chuyển, bảo mật**, cách thanh toán, cơ chế giải quyết khiếu nại; hiển thị **giá cuối cùng** (gồm thuế/phí) rõ ràng.

### 8.3 Dữ liệu cá nhân (dữ liệu sức khỏe là dữ liệu nhạy cảm)
- **Luật Bảo vệ dữ liệu cá nhân 2025 (số 91/2025/QH15)** và **Nghị định 356/2025/NĐ-CP** có hiệu lực từ **01/01/2026**, thay thế Nghị định 13/2023/NĐ-CP. *(Các tài liệu 01, 02, 04, 05 trước đây tham chiếu Nghị định 13/2023 — nay đã cập nhật.)*
- Thông tin về **tình trạng sức khỏe** thuộc **dữ liệu cá nhân nhạy cảm**: đồng ý phải rõ ràng, được thông báo là dữ liệu nhạy cảm, **không tick sẵn**, có thể rút lại; chỉ thu thập những gì cần thiết.
- Việc cần làm: chính sách bảo mật tiếng Việt (mục đích, loại dữ liệu, thời hạn lưu, bên nhận); quyền của chủ thể dữ liệu (xem, sửa, xóa, rút đồng ý → đã có `rpc_export_my_data`, `account-delete`; cần quy trình xử lý yêu cầu trong thời hạn luật định); **hồ sơ đánh giá tác động xử lý dữ liệu**; quy trình **thông báo sự cố** lộ lọt dữ liệu; hợp đồng xử lý dữ liệu với bên thứ ba (Supabase, nhà cung cấp AI, Resend, VNPay).
- **Chuyển dữ liệu ra nước ngoài:** Supabase, nhà cung cấp AI và email đặt máy chủ ngoài Việt Nam → cần đánh giá/hồ sơ chuyển dữ liệu xuyên biên giới theo luật. Chọn vùng (region) gần nhất và ghi rõ trong chính sách.
- Doanh nghiệp nhỏ/khởi nghiệp có thể được miễn một số nghĩa vụ (vd đánh giá tác động) trong thời hạn nhất định theo Luật — **nhưng với dữ liệu sức khỏe nên vẫn thực hiện**.
- **Consent AI** (`ai_consent_at`) tách riêng, mô tả đúng dữ liệu gửi đi (xem PRD mục 4.5).

### 8.4 An toàn thực phẩm
- Bán thực phẩm (đặc biệt **tươi sống, đồ lạnh**) có thể phải đáp ứng điều kiện an toàn thực phẩm (giấy chứng nhận cơ sở đủ điều kiện hoặc thủ tục tương đương tùy loại hình và quy mô), nhãn hàng hóa, truy xuất nguồn gốc, bảo quản/vận chuyển.
- **Quy định đang biến động:** thông tin công khai cho thấy một nghị định mới về điều kiện an toàn thực phẩm đã được ban hành đầu năm 2026 rồi **tạm dừng áp dụng**; các nguồn trái chiều → **hỏi trực tiếp Sở/Chi cục An toàn thực phẩm địa phương** về giấy tờ cần thiết cho mô hình của bạn (tự đóng gói, hay chỉ phân phối hàng của nhà cung cấp đã có giấy phép). Cách an toàn nhất: **chỉ bán hàng của nhà cung cấp có đủ giấy tờ ATTP**, lưu bản sao hồ sơ, nhãn và hóa đơn đầu vào.

### 8.5 Thuế & hóa đơn
- Hộ kinh doanh/doanh nghiệp: kê khai, nộp thuế, **hóa đơn điện tử**; thông tin công khai cho thấy chế độ thuế khoán của hộ kinh doanh đã thay đổi từ 01/01/2026 (tự kê khai; có ngưỡng doanh thu miễn một số thuế) — **kế toán xác nhận** quy định áp dụng cho bạn.
- Đối soát doanh thu theo cổng thanh toán và COD hằng ngày.

### 8.6 Quảng cáo & tuyên bố sức khỏe
- Không quảng cáo chữa bệnh hoặc hiệu quả y tế; không dùng cụm "thực đơn trị tiểu đường/huyết áp". Dùng "gợi ý món phù hợp khẩu phần ít đường/ít muối". Mọi tuyên bố dinh dưỡng phải có cơ sở và nằm trong mục "Nguồn & Phương pháp".
- Dùng ảnh/nhạc/nội dung có bản quyền hợp lệ.

### 8.7 Điều khoản người dùng
Điều khoản sử dụng, Chính sách bảo mật, Chính sách đổi trả/hoàn tiền, Chính sách vận chuyển, Quy chế hoạt động (do luật sư soạn), đặt ở chân trang và ở bước checkout (tick đồng ý, **không tick sẵn**).

**Tiêu chí đạt G5:** có giấy tờ kinh doanh, xác nhận thủ tục TMĐT (thông báo/đăng ký) và ATTP bằng văn bản/biên nhận, chính sách đã đăng, hồ sơ dữ liệu cá nhân hoàn tất, kế toán xác nhận thuế/hóa đơn.

---

## 9. THANH TOÁN THẬT (Gate G6)

1. **Đăng ký merchant VNPay môi trường production** (hồ sơ pháp lý, tài khoản ngân hàng, website đáp ứng yêu cầu hiển thị chính sách). VNPay có quy trình tích hợp: nhận mã sandbox → tích hợp → kiểm thử → **go-live**; **IPN URL môi trường thật phải đăng ký với VNPay**.
2. Đổi cấu hình: `VNP_TMN_CODE`, `VNP_HASH_SECRET`, `VNP_URL` sang **thật** (secret đặt bằng `supabase secrets set`, không commit); IPN URL = `https://<project>.supabase.co/functions/v1/vnpay-ipn`.
3. **Điểm cần hỏi VNPay bằng văn bản:** (a) môi trường thật có yêu cầu **IP whitelist** cho webhook hoặc API hoàn tiền/truy vấn giao dịch không — Edge Function của Supabase **không có IP cố định**, nếu bắt buộc thì cần một máy chủ trung gian có IP tĩnh; (b) quy trình **hoàn tiền** (qua API hay qua cổng quản trị); (c) quy trình **đối soát**.
4. **Kiểm thử trước go-live:** giao dịch thật giá trị nhỏ → thành công, thất bại, hủy giữa chừng, webhook lặp, sai chữ ký; kiểm tra đơn chuyển `confirmed`, kho trừ đúng; hủy đơn đã trả → "cần hoàn tiền" → hoàn tiền thật → `rpc_mark_refunded`.
5. **Đối soát hằng ngày:** so sánh `payments`/`orders` với báo cáo VNPay; xử lý chênh lệch trong 24 giờ.
6. **Bật cờ `payments_live`** chỉ sau khi `demo_mode = false` (hệ thống bắt buộc thứ tự này).
7. COD: quy trình thu tiền, đối soát với đơn vị giao hàng, giới hạn giá trị COD/đơn.

**Tiêu chí đạt G6:** giao dịch thật thành công và hoàn tiền thật thành công; đối soát khớp; tài liệu quy trình sự cố thanh toán.

---

## 10. KỸ THUẬT & BẢO MẬT (Gate G7)

### 10.1 Cơ chế "cổng" trong hệ thống (migration 006 — Phụ lục A)
| Thành phần | Tác dụng |
|---|---|
| `app_settings` (`demo_mode`, `payments_live`, `shop_enabled`, `ai_enabled`) | **Nguồn sự thật duy nhất** cho chế độ demo/chính thức; đọc công khai, ghi chỉ qua RPC |
| `rpc_go_live_check()` (admin) | Liệt kê việc **chặn** (`blocker`) và **cảnh báo** (`warning`): nguyên liệu chưa xác minh, công thức chưa duyệt/nấu thử, quy tắc chưa duyệt, sản phẩm chưa xác minh, thiếu phí ship, thiếu admin/nutritionist, nguyên liệu chưa có sản phẩm, thiếu ảnh, ít hơn 50 món, thanh toán chưa live |
| `rpc_set_app_setting('demo_mode', false)` | **Từ chối (`GO_LIVE_BLOCKED: …`)** nếu còn bất kỳ blocker; ghi `audit_log` khi đổi |
| `rpc_set_app_setting('payments_live', true)` | Chỉ cho phép khi đã tắt demo (`DEMO_MODE_STILL_ON`) |
| Trigger xác minh nguyên liệu | Cần nguồn thật + qua `ingredient_sanity` + người có quyền; đổi số liệu → hủy xác minh |
| Trigger xuất bản công thức (chế độ chính thức) | Cần nguyên liệu đã xác minh, đã nấu thử, có người duyệt; sửa nội dung → về `review` |
| Trigger đặt hàng (chế độ chính thức) | Chặn sản phẩm chưa xác minh giá/khối lượng/dị ứng |
| `price_history` + trigger | Ghi lịch sử giá; đổi giá → `unverified` |

**Frontend:** banner/nhãn demo đọc `app_settings.demo_mode` từ DB, thay cho biến môi trường `VITE_DEMO_MODE`. Chỉ được ẩn banner, bỏ `noindex`, sinh `sitemap.xml` và bật JSON-LD sau khi giao diện đã thay toàn bộ dữ liệu demo bằng dữ liệu backend đã kiểm soát. Nếu cờ DB đã tắt nhưng frontend còn dữ liệu minh họa, phải giữ cảnh báo và `noindex`; **vẫn giữ** `MedicalDisclaimer` và nhãn "ước tính" cho dinh dưỡng.

### 10.2 Môi trường production
- Dự án Supabase **production riêng** (gói Pro: sao lưu PITR, không bị tạm dừng), vùng gần Việt Nam (vd Singapore), **tên miền riêng + HTTPS**, SMTP riêng (Resend) cho mail xác thực, CAPTCHA đăng ký, Google OAuth production, `Redirect URLs` chỉ gồm domain thật.
- **Không chạy `seed.sql` trên production.** Dữ liệu production đến từ quy trình mục 4–7 (CSV → bảng tạm → kiểm tra → xác minh). Nếu cần dữ liệu nền (dị ứng, bệnh lý), chạy riêng phần đó từ seed.
- Secrets: `ANTHROPIC_API_KEY`, `VNP_*`, `RESEND_API_KEY` ở `supabase secrets`; xoay khóa định kỳ; không dùng chung giữa staging và production.
- Vercel: biến môi trường production (`VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`); bật header bảo mật/CSP; gỡ `noindex` chỉ khi `demo_mode = false`.

### 10.3 Kiểm thử bắt buộc trước phát hành
| Loại | Phạm vi |
|---|---|
| pgTAP | Toàn bộ kịch bản ở file 05 mục 9.1 + migration 006: gate go-live, xác minh nguyên liệu, chặn xuất bản/đặt hàng, lịch sử giá, tranh chấp tồn kho (2 kết nối) |
| Deno test | 5 Edge Function với mock; **chạy lần đầu trên staging thật** (hiện chưa chạy lần nào) |
| E2E (Playwright + axe) | Luồng đầy đủ: đăng ký → onboarding → AI → công thức → nấu → mua sắm → giỏ → checkout → đơn → đăng xuất |
| Bộ kịch bản y khoa | Mục 6, bước 4 |
| Bảo mật | Rà soát RLS, quyền hàm, secrets; thử khai thác cơ bản (IDOR, mass assignment, webhook giả mạo, prompt injection); `pnpm audit` |
| Tải | `rpc_recommend_recipes`, `ai-suggest`, `rpc_place_order` với dữ liệu ~ 300 công thức/500 sản phẩm; kiểm tra index |
| Thảm họa | Khôi phục sao lưu thử; kịch bản lộ khóa → xoay khóa |

### 10.4 Giám sát & cảnh báo
Sentry (loại dữ liệu sức khỏe), uptime check, cảnh báo: tỉ lệ lỗi Edge Function, `used_fallback` của AI > 20%, webhook thanh toán lỗi, đơn `pending` quá hạn, tồn kho âm/bất thường, chi phí AI/ngày vượt ngưỡng. Bảng điều khiển: số đơn, tỉ lệ hủy, doanh thu, lượt AI, 👍/👎.

**Tiêu chí đạt G7:** CI (pgTAP, Deno, Vitest, Playwright) xanh; `rpc_go_live_check` **không còn blocker**; báo cáo rà soát bảo mật không còn mức High/Critical; khôi phục sao lưu thành công.

---

## 11. VẬN HÀNH & HỖ TRỢ (Gate G8)
- **Quy trình xử lý đơn:** ai xác nhận COD, ai đóng gói, ai nhập mã vận đơn, cut-off giờ; mục tiêu thời gian xác nhận/giao.
- **Quy trình hoàn tiền & khiếu nại:** biểu mẫu, thời hạn, người phê duyệt.
- **Báo lỗi dữ liệu:** nút "Báo lỗi công thức/giá/dinh dưỡng" trên giao diện → hàng đợi cho chuyên gia; công thức bị báo lỗi nghiêm trọng (an toàn) → **gỡ ngay** (`update recipes set status = 'archived'`) rồi điều tra.
- **Sự cố an toàn thực phẩm/dị ứng:** quy trình thu hồi, thông báo người đã mua, báo cơ quan khi cần.
- **Sự cố dữ liệu cá nhân:** quy trình đánh giá, thông báo cơ quan/người dùng theo luật.
- **Trực & kênh hỗ trợ:** giờ làm việc, email/điện thoại/chat, SLA.
- **Đào tạo** nhân viên về máy trạng thái đơn, hoàn tiền, nhận diện hàng/ghi chú dị ứng.

---

## 12. KẾ HOẠCH THEO GIAI ĐOẠN (tham khảo 14–18 tuần; tùy nguồn lực)

| Giai đoạn | Tuần | Việc chính | Thoát giai đoạn khi |
|---|---|---|---|
| **P0 Chuẩn bị** | 1–2 | Chốt nhân sự (mục 3), nguồn dữ liệu, nhà cung cấp, luật sư/kế toán; hỏi cơ quan về TMĐT/ATTP/VNPay; dựng staging thật và chạy backend lần đầu (đối chiếu 05) | Có đủ người ký duyệt; staging chạy; danh sách câu hỏi pháp lý đã gửi |
| **P1 Dinh dưỡng** | 2–8 | Nhập/đối chiếu/xác minh nguyên liệu (mục 4) | **G1** |
| **P2 Công thức** | 3–10 (song song) | Soạn, nấu thử, chụp ảnh, duyệt (mục 5) — mốc 50 món | **G2** (50 món) |
| **P3 Y khoa** | 6–10 | Duyệt `condition_rules`, bộ kịch bản (mục 6) | **G3** |
| **P4 Giá & sản phẩm** | 4–10 | Nhà cung cấp, báo giá, quy cách, dị ứng, ảnh, phí ship (mục 7) | **G4** |
| **P5 Pháp lý & thanh toán** | 4–12 | Giấy tờ, chính sách, VNPay production (mục 8–9) | **G5, G6** |
| **P6 Kỹ thuật** | 8–13 | Production, test tự động, bảo mật, giám sát, `rpc_go_live_check` sạch (mục 10) | **G7** |
| **P7 Beta kín** | 13–15 | 20–100 người dùng mời, một khu vực giao hàng, **giới hạn số đơn/ngày**, đơn giá trị nhỏ, xác nhận đơn thủ công, theo dõi sát lỗi dữ liệu/an toàn | 2 tuần liên tiếp không có sự cố an toàn; tỉ lệ lỗi đơn < 2%; phản hồi AI/công thức đạt ngưỡng |
| **P8 Mở công khai** | 16–18 | Tăng nội dung ≥ 150 món, mở rộng khu vực, tắt giới hạn dần; chiến dịch | **G8** + quyết định của chủ sản phẩm |

Phát hành theo **từng bước nhỏ** (khu vực, số lượng, nhóm bệnh): ví dụ lần đầu chỉ bật cho người dùng **không thuộc nhóm bệnh nhạy cảm** và chỉ hiển thị nhóm món đã được duyệt kỹ.

---

## 13. QUY TRÌNH TẮT CHẾ ĐỘ DEMO (checklist cuối)
1. Chạy `rpc_go_live_check()`; xử lý toàn bộ **blocker** (`bad_count = 0`), cân nhắc các **warning**.
2. Rà soát mục 8 (pháp lý) và mục 9 (thanh toán) — **các cổng không tự động kiểm** (G5, G6, G8) do chủ sản phẩm ký xác nhận bằng văn bản.
3. Sao lưu dữ liệu; chụp lại cấu hình; đảm bảo người trực sẵn sàng.
4. `select rpc_set_app_setting('demo_mode', 'false'::jsonb);` (admin) → nếu bị `GO_LIVE_BLOCKED` thì xử lý theo thông báo.
5. `select rpc_set_app_setting('payments_live', 'true'::jsonb);` sau khi VNPay production sẵn sàng.
6. Frontend tự ẩn banner demo, bỏ `noindex`; tạo `sitemap.xml`; kiểm tra thủ công các trang chính.
7. Thực hiện **đơn thật đầu tiên** do nội bộ đặt và hoàn tiền thử; theo dõi 48 giờ đầu.
8. Mở cho nhóm beta kín (P7); chỉ mở rộng khi đạt tiêu chí.

**Quay lại demo khi có sự cố:** `rpc_set_app_setting('shop_enabled', false)` (tạm dừng bán), `ai_enabled = false` (tắt AI), hoặc gỡ món/sản phẩm có vấn đề; **không bật lại** `demo_mode = true` để "che" dữ liệu sai — hãy sửa dữ liệu.

---

## 14. SAU PHÁT HÀNH — DUY TRÌ ĐỘ TIN CẬY
| Tần suất | Việc |
|---|---|
| Hằng ngày | Đối soát thanh toán/COD; xử lý đơn quá hạn; xem cảnh báo lỗi; hàng đợi báo lỗi dữ liệu |
| Hằng tuần | Cập nhật giá rau/thịt/cá (`staging_products` → xác minh); kiểm kho; xem chỉ số AI (fallback, 👍/👎, chi phí) |
| Hằng tháng | Kiểm chéo ngẫu nhiên 5% công thức/nguyên liệu; rà soát đơn hủy/hoàn tiền; cập nhật nhà cung cấp |
| Mỗi 6–12 tháng | Rà soát `condition_rules` với nguồn khuyến nghị mới; cập nhật phiên bản nguồn dinh dưỡng; kiểm tra lại pháp lý |
| Khi có thay đổi | Đổi nhà cung cấp/thương hiệu → cập nhật nhãn, dị ứng, natri, xác minh lại; công thức sửa → duyệt lại (hệ thống tự yêu cầu) |

**Chỉ số tin cậy dữ liệu để theo dõi:** % công thức đã xác minh/nấu thử; số báo lỗi dữ liệu và thời gian xử lý; % sản phẩm có giá xác minh trong 14 ngày gần nhất; số đơn bị chặn do `PRODUCT_NOT_VERIFIED`.

---

## 15. VIỆC KỸ THUẬT CHO AI/DEV THỰC THI (từ bản demo)

1. Đưa **Phụ lục A** vào `supabase/migrations/20261020000006_production_readiness.sql`, rồi áp dụng migration đang chờ bằng `npm exec supabase -- migration up --local` và chạy `npm exec supabase -- test db`. Chỉ dùng `supabase db reset` trên database local có thể xóa và dựng lại; tuyệt đối không reset staging/production.
2. Viết **pgTAP** cho: `rpc_go_live_check` (đủ blocker → sạch), `rpc_set_app_setting` (bị chặn/được phép/`DEMO_MODE_STILL_ON`), trigger xác minh nguyên liệu (`INGREDIENT_SANITY`, hủy xác minh khi đổi số liệu), trigger xuất bản ở chế độ chính thức (`INGREDIENT_NOT_VERIFIED`, `NEED_TEST_COOK`, `NEED_REVIEWER`, sửa nội dung → `review`), trigger đặt hàng (`PRODUCT_NOT_VERIFIED`), `price_history`.
3. **Frontend:** đọc `app_settings` (public) → `useAppSettings()`; `DemoBanner`, nhãn "Giá minh họa/Dinh dưỡng ước tính chưa xác minh" hiển thị theo `demo_mode`; ẩn khi chính thức nhưng giữ nhãn "ước tính" cho dinh dưỡng; `noindex` theo cờ; `sitemap.xml` khi chính thức.
4. **Admin (UI):** màn **"Sẵn sàng phát hành"** hiển thị `rpc_go_live_check()` (blocker đỏ, warning vàng, liên kết tới danh sách vi phạm) và nút bật/tắt cờ (gọi `rpc_set_app_setting`, hiển thị lỗi `GO_LIVE_BLOCKED` dễ hiểu); màn **nhập CSV** nguyên liệu và giá (dùng bảng tạm, hiển thị `ingredient_sanity`); màn **xác minh nguyên liệu/sản phẩm** (bộ lọc `unverified`); form **nấu thử** của công thức (`test_cooked_by/at`, `cooked_yield_g`, `test_notes`); **lịch sử giá**.
5. **Nút "Báo lỗi dữ liệu"** (bảng `data_reports` mới: loại, đối tượng, mô tả, trạng thái) và hàng đợi cho chuyên gia — *chưa có trong thiết kế hiện tại*.
6. Chức năng bán theo cân/điều chỉnh đơn nếu chọn mô hình 7.1(b) — *chưa có*.
7. Hoàn thiện, chạy lần đầu và kiểm thử 5 **Edge Function** trên staging; thiết lập Database Webhook cho `send-email`; kiểm thử VNPay sandbox đầu–cuối.
8. Chuẩn bị môi trường production (mục 10.2) và CI/CD.

**Prompt cho AI thực thi:**
```
Đọc docs/00_AI_EXECUTION_BRIEF.md và docs/06_LEN_BAN_CHINH_THUC.md. NutriCook hiện là bản DEMO, dữ liệu công thức/dinh dưỡng/giá
CHƯA xác minh. Thực hiện mục 15 theo thứ tự, không bao giờ tự đặt data_status/price_status = 'verified', không tự gán
approved_by/reviewed_by, không tắt demo_mode, không dùng VNPay live. Những việc cần con người (nhập số liệu có nguồn, nấu thử,
duyệt y khoa, giấy tờ pháp lý, hợp đồng nhà cung cấp, đăng ký VNPay) hãy liệt kê thành danh sách cho người phụ trách thay vì tự làm.
Báo cáo sau mỗi bước theo định dạng trong brief.
```
**Điều AI không được làm thay con người:** xác minh số liệu dinh dưỡng, duyệt quy tắc y khoa, xác nhận giá/nhà cung cấp, ký giấy tờ pháp lý, bật thanh toán thật, tắt chế độ demo.

### Trạng thái triển khai trong repository
- [x] Đã thêm migration 006 và kiểm tra kỹ các cổng xác minh; thay đổi giá, quy cách hoặc nhãn sản phẩm làm mất xác minh tương ứng.
- [x] Đã thêm kiểm thử pgTAP cho cờ mặc định, xác minh nguyên liệu, lịch sử giá và tạm dừng bán hàng.
- [x] Frontend đọc cờ backend nhưng luôn giữ nhãn demo và `noindex` vì dữ liệu/luồng giao diện vẫn là minh họa.
- [x] Edge Function AI và tạo thanh toán kiểm tra cờ bật/tắt; database chặn đơn mới khi cửa hàng tạm dừng.
- [x] Migration 006 đã áp dụng lên Supabase local bằng `npm exec supabase -- migration up --local` (không reset); 22 bài pgTAP trên cả hai file test đã đạt.
- [ ] Edge Runtime, Image Proxy và Pooler vẫn được Supabase CLI báo dừng; cần khởi động/kiểm tra trước khi thử Edge Functions và toàn bộ tích hợp.
- [ ] Chưa có Deno để type-check/chạy Edge Functions; Node chỉ xác nhận cú pháp cơ bản.
- [ ] G1–G8 production chưa được thực hiện và **nằm ngoài phạm vi nộp đồ án**: không có dữ liệu dinh dưỡng được chuyên gia xác minh, duyệt y khoa, nhà cung cấp/giá thật, hồ sơ pháp lý, VNPay production hoặc vận hành hỗ trợ. Không sử dụng demo như dịch vụ công khai.

---

## 16. NGUỒN THAM KHẢO (tra cứu 25/10/2026 — cần đối chiếu bản gốc)
- Luật Thương mại điện tử 2025 (122/2025/QH15), hiệu lực 01/07/2026; Nghị định 248/2026/NĐ-CP: https://thuvienphapluat.vn/van-ban/Thuong-mai/Luat-Thuong-mai-dien-tu-2025-so-122-2025-QH15-662035.aspx · https://baolaocai.vn/tu-hom-nay-172026-ban-hang-online-khong-the-an-danh-nguoi-ban-can-lam-gi-post902924.html
- Quản lý website TMĐT (văn bản hợp nhất 09/VBHN-BCT năm 2026) và thẩm quyền thông báo cấp tỉnh: https://luatvietnam.vn/linh-vuc-khac/van-ban-hop-nhat-09-vbhn-bct-2026-quy-dinh-quan-ly-website-thuong-mai-dien-tu-426040-d5.html · https://tapchicongthuong.vn/bo-cong-thuong-hop-nhat-cac-quy-dinh-ve-quan-ly-website-thuong-mai-dien-tu-525323.htm
- Luật Bảo vệ dữ liệu cá nhân 2025 (91/2025/QH15), hiệu lực 01/01/2026; Nghị định 356/2025/NĐ-CP; sức khỏe là dữ liệu nhạy cảm: https://thuvienphapluat.vn/van-ban/Bo-may-hanh-chinh/Luat-Bao-ve-du-lieu-ca-nhan-2025-so-91-2025-QH15-625628.aspx · https://luatvietnam.vn/tin-van-ban-moi/thong-tin-ve-suc-khoe-la-du-lieu-ca-nhan-nhay-cam-186-106394-article.html · https://luatvietnam.vn/dan-su/nghi-dinh-huong-dan-luat-bao-ve-du-lieu-ca-nhan-2025-la-nghi-dinh-nao-568-103658-article.html
- An toàn thực phẩm (điều kiện cơ sở kinh doanh, thay đổi quy định 2026): https://thuehaiquan.tapchikinhtetaichinh.vn/quy-dinh-moi-ve-dieu-kien-san-xuat-thuc-pham-bao-ve-suc-khoe-144163.html · https://www.careerlink.vn/cam-nang-viec-lam/?p=30051
- USDA FoodData Central: https://fdc.nal.usda.gov/
- VNPay (tài liệu tích hợp, IPN, hoàn tiền): https://sandbox.vnpayment.vn/apis/docs/gioi-thieu/ · https://vnpay.js.org/ipn/config-ipn · https://vnpay.js.org/refund · https://vnpay.js.org/troubleshooting
- Dinh dưỡng theo bệnh lý (tham khảo ban đầu, cần chuyên gia đối chiếu): các nguồn ở `01_PRD_NGHIEP_VU.md` mục 12.

**Giới hạn của file này:** mình không thể xác minh thay bạn các quy định pháp lý hiện hành, điều khoản sử dụng nguồn dữ liệu (đặc biệt Bảng thành phần thực phẩm Việt Nam), yêu cầu của VNPay, hay các ngưỡng y khoa. Mọi mục đánh dấu "cần xác nhận" phải được người có chuyên môn kiểm tra trước khi phát hành.

---

# PHỤ LỤC A — Migration 006 (cổng chuyển sang bản chính thức)
Đường dẫn: `supabase/migrations/20261020000006_production_readiness.sql` — chạy **sau** 5 migration trước. Đã chạy thử trên PostgreSQL 16 (xác minh nguyên liệu, nấu thử/duyệt công thức, kiểm tra go-live, tắt demo, chặn xuất bản và đặt hàng ở chế độ chính thức, lịch sử giá).

```sql
-- =====================================================================
-- NutriCook · Migration 6 · CHUYỂN TỪ DEMO SANG CHÍNH THỨC
-- - app_settings: cờ demo_mode / payments_live / shop_enabled / ai_enabled (nguồn sự thật DUY NHẤT)
-- - Trạng thái XÁC MINH cho nguyên liệu (dinh dưỡng), công thức (nấu thử), sản phẩm (giá, khối lượng tịnh, dị ứng)
-- - Lịch sử giá
-- - rpc_go_live_check(): danh sách việc chặn phát hành
-- - rpc_set_app_setting(): chỉ tắt demo_mode khi KHÔNG còn việc chặn
-- Không sửa migration cũ; chỉ thêm và thay hàm bằng CREATE OR REPLACE.
-- =====================================================================

-- ---------- 1. CỜ CẤU HÌNH ----------
create table public.app_settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id)
);
insert into public.app_settings(key, value) values
  ('demo_mode', 'true'), ('payments_live', 'false'), ('shop_enabled', 'true'), ('ai_enabled', 'true')
on conflict (key) do nothing;
alter table public.app_settings enable row level security;
create policy pub_read on public.app_settings for select using (true);   -- không có policy ghi: chỉ qua RPC

create or replace function public.app_setting_bool(p_key text, p_default boolean default false) returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select (value)::text::boolean from app_settings where key = p_key), p_default)
$$;
grant execute on function public.app_setting_bool(text, boolean) to anon, authenticated;

-- ---------- 2. XÁC MINH DINH DƯỠNG NGUYÊN LIỆU ----------
alter table public.ingredients
  add column if not exists source_ref     text,          -- mã/ID thực phẩm trong nguồn (vd FDC ID, mã bảng TPTP VN)
  add column if not exists source_version text,          -- phiên bản/năm của nguồn
  add column if not exists data_status    text not null default 'unverified'
        check (data_status in ('unverified','verified','rejected')),
  add column if not exists verified_by    uuid references public.profiles(id),
  add column if not exists verified_at    timestamptz;

alter table public.ingredients drop constraint if exists ingredients_verified_needs_source;
alter table public.ingredients add constraint ingredients_verified_needs_source check (
  data_status <> 'verified' or (source_ref is not null and source_version is not null and source <> 'seed_estimate'));

-- Kiểm tra tính hợp lý của số liệu (trả về mô tả lỗi, rỗng nếu ổn)
create or replace function public.ingredient_sanity(i public.ingredients) returns text
language plpgsql immutable as $$
declare issues text[] := '{}'; atwater numeric;
begin
  -- carb "theo hiệu số" đã gồm chất xơ (≈ 2 kcal/g) nên điều chỉnh: 4·đạm + 9·béo + 4·(carb − xơ) + 2·xơ
  atwater := 4*coalesce(i.protein_g,0) + 9*coalesce(i.fat_g,0)
           + 4*greatest(coalesce(i.carb_g,0) - coalesce(i.fiber_g,0), 0) + 2*least(coalesce(i.fiber_g,0), coalesce(i.carb_g,0));
  if abs(i.kcal - atwater) > greatest(0.15 * i.kcal, 15) then
    issues := issues || format('kcal %s lệch quá 15%% so với ước tính theo đạm/béo/carb/xơ = %s', i.kcal, round(atwater,1)); end if;
  if coalesce(i.protein_g,0) + coalesce(i.carb_g,0) + coalesce(i.fat_g,0) > 100.5 then
    issues := issues || 'tổng đạm+carb+béo vượt 100 g/100 g'; end if;
  if coalesce(i.sat_fat_g,0) > coalesce(i.fat_g,0) + 0.05 then issues := issues || 'béo bão hòa lớn hơn tổng béo'; end if;
  if coalesce(i.sugar_g,0)   > coalesce(i.carb_g,0) + 0.05 then issues := issues || 'đường lớn hơn tổng carb'; end if;
  if coalesce(i.fiber_g,0)   > coalesce(i.carb_g,0) + 0.05 then issues := issues || 'chất xơ lớn hơn tổng carb'; end if;
  if coalesce(i.sodium_mg,0) < 0 or coalesce(i.sodium_mg,0) > 40000 then issues := issues || 'natri ngoài khoảng 0–40.000 mg'; end if;
  return array_to_string(issues, '; ');
end $$;

create or replace function public.trg_ingredient_verify() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_issue text;
begin
  if new.data_status = 'verified' and (tg_op = 'INSERT' or old.data_status is distinct from 'verified') then
    if auth.uid() is not null and not has_role(array['admin','nutritionist']::app_role[]) then raise exception 'FORBIDDEN'; end if;
    v_issue := ingredient_sanity(new);
    if v_issue <> '' then raise exception 'INGREDIENT_SANITY: %', v_issue; end if;
    new.verified_by := coalesce(auth.uid(), new.verified_by);
    new.verified_at := now();
  elsif tg_op = 'UPDATE' and old.data_status = 'verified' and new.data_status = 'verified'
        and (row(new.kcal,new.protein_g,new.carb_g,new.fat_g,new.sat_fat_g,new.fiber_g,new.sugar_g,new.sodium_mg,new.purine_level)
             is distinct from
             row(old.kcal,old.protein_g,old.carb_g,old.fat_g,old.sat_fat_g,old.fiber_g,old.sugar_g,old.sodium_mg,old.purine_level)) then
    new.data_status := 'unverified';          -- đổi số liệu đã xác minh → phải xác minh lại
    new.verified_by := null; new.verified_at := null;
  end if;
  return new;
end $$;
create trigger t_ingredient_verify before insert or update on public.ingredients
  for each row execute function public.trg_ingredient_verify();

-- ---------- 3. CÔNG THỨC: NẤU THỬ + XUẤT BẢN THEO CHẾ ĐỘ ----------
alter table public.recipes
  add column if not exists test_cooked_by uuid references public.profiles(id),
  add column if not exists test_cooked_at timestamptz,
  add column if not exists test_notes     text,           -- ghi chú nấu thử: thời gian thực tế, khối lượng sau nấu, điều chỉnh
  add column if not exists cooked_yield_g numeric(8,1);   -- khối lượng thành phẩm khi nấu thử

create or replace function public.trg_recipe_publish_guard() returns trigger
language plpgsql security definer set search_path = public as $$
declare n_steps int; n_ing int; n_short int; n_prep int; n_unverified int; v_demo boolean;
begin
  if new.status = 'published' and old.status is distinct from 'published' then
    if auth.uid() is not null and not has_role(array['admin','nutritionist']::app_role[]) then
      raise exception 'FORBIDDEN'; end if;
    select count(*), count(*) filter (where char_length(instruction) < 20), count(*) filter (where phase = 'prep')
      into n_steps, n_short, n_prep from recipe_steps where recipe_id = new.id;
    select count(*) into n_ing from recipe_ingredients where recipe_id = new.id;
    if n_ing < 3   then raise exception 'NEED_3_INGREDIENTS'; end if;
    if n_steps < 4 then raise exception 'NEED_4_STEPS'; end if;
    if n_prep < 1  then raise exception 'NEED_PREP_STEP'; end if;
    if n_short > 0 then raise exception 'STEP_TOO_SHORT'; end if;
    if new.image_url is null then raise exception 'NEED_IMAGE'; end if;
    if new.kcal is null then raise exception 'NUTRITION_MISSING'; end if;
    if cardinality(new.equipment) = 0 then raise exception 'NEED_EQUIPMENT'; end if;

    v_demo := app_setting_bool('demo_mode', true);
    if not v_demo then                                   -- CHẾ ĐỘ CHÍNH THỨC: yêu cầu chặt hơn
      select count(*) into n_unverified from recipe_ingredients ri join ingredients i on i.id = ri.ingredient_id
       where ri.recipe_id = new.id and i.data_status <> 'verified';
      if n_unverified > 0 then raise exception 'INGREDIENT_NOT_VERIFIED:%', n_unverified; end if;
      if new.test_cooked_at is null or new.test_cooked_by is null then raise exception 'NEED_TEST_COOK'; end if;
      if auth.uid() is null then raise exception 'NEED_REVIEWER'; end if;     -- bắt buộc có người duyệt thật
    end if;
    new.reviewed_by := auth.uid(); new.published_at := now();
  end if;
  return new;
end $$;

-- Sửa nguyên liệu/bước của công thức ĐÃ XUẤT BẢN (ở chế độ chính thức) → đưa về 'review' để duyệt lại
create or replace function public.trg_recipe_content_changed() returns trigger
language plpgsql security definer set search_path = public as $$
declare rid uuid := coalesce(new.recipe_id, old.recipe_id);
begin
  if not app_setting_bool('demo_mode', true) then
    update recipes set status = 'review', reviewed_by = null where id = rid and status = 'published';
  end if;
  return null;
end $$;
create trigger t_ri_changed after insert or update or delete on public.recipe_ingredients
  for each row execute function public.trg_recipe_content_changed();
create trigger t_rs_changed after insert or update or delete on public.recipe_steps
  for each row execute function public.trg_recipe_content_changed();

-- ---------- 4. SẢN PHẨM: GIÁ, KHỐI LƯỢNG TỊNH, DỊ ỨNG ĐÃ XÁC NHẬN ----------
alter table public.products
  add column if not exists supplier text,
  add column if not exists cost_vnd bigint check (cost_vnd is null or cost_vnd >= 0),   -- giá vốn
  add column if not exists vat_rate numeric(4,2) check (vat_rate is null or vat_rate between 0 and 1),
  add column if not exists price_source text,                      -- báo giá/hóa đơn/hợp đồng nhà cung cấp
  add column if not exists price_updated_at timestamptz,
  add column if not exists price_status text not null default 'unverified' check (price_status in ('unverified','verified')),
  add column if not exists net_weight_verified boolean not null default false,   -- pack_size_g là khối lượng tịnh đã cân/ghi trên nhãn
  add column if not exists allergen_verified boolean not null default false,     -- dị ứng đã đối chiếu nhãn nhà cung cấp
  add column if not exists label_note text;                         -- nguồn gốc, hạn dùng, bảo quản

create table public.price_history (
  id bigserial primary key,
  product_id uuid not null references public.products(id) on delete cascade,
  old_price_vnd bigint, new_price_vnd bigint not null,
  changed_by uuid, changed_at timestamptz not null default now()
);
alter table public.price_history enable row level security;
create policy staff_read on public.price_history for select to authenticated
  using (public.has_role(array['admin','staff']::app_role[]));

-- BEFORE: đóng dấu thời gian và đưa về "chưa xác minh" khi đổi giá
create or replace function public.trg_product_price_stamp() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' or new.price_vnd is distinct from old.price_vnd then
    new.price_updated_at := now();
    if tg_op = 'UPDATE' then new.price_status := 'unverified'; end if;    -- đổi giá → phải xác minh lại
  end if;
  return new;
end $$;
create trigger t_product_price_stamp before insert or update on public.products
  for each row execute function public.trg_product_price_stamp();

-- AFTER: ghi lịch sử giá (sau khi dòng sản phẩm đã tồn tại để thỏa khóa ngoại)
create or replace function public.trg_product_price_log() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' or new.price_vnd is distinct from old.price_vnd then
    insert into price_history(product_id, old_price_vnd, new_price_vnd, changed_by)
    values (new.id, case when tg_op = 'UPDATE' then old.price_vnd end, new.price_vnd, auth.uid());
  end if;
  return null;
end $$;
create trigger t_product_price_log after insert or update on public.products
  for each row execute function public.trg_product_price_log();

-- Chế độ chính thức: KHÔNG cho đặt sản phẩm chưa xác minh giá/khối lượng/dị ứng
create or replace function public.trg_order_item_verified() returns trigger
language plpgsql security definer set search_path = public as $$
declare p products%rowtype;
begin
  if not app_setting_bool('demo_mode', true) then
    select * into p from products where id = new.product_id;
    if p.price_status <> 'verified' or not p.net_weight_verified or not p.allergen_verified then
      raise exception 'PRODUCT_NOT_VERIFIED:%', p.name;
    end if;
  end if;
  return new;
end $$;
create trigger t_order_item_verified before insert on public.order_items
  for each row execute function public.trg_order_item_verified();

-- ---------- 5. KIỂM TRA SẴN SÀNG PHÁT HÀNH ----------
create or replace function public.rpc_go_live_check()
returns table (code text, label text, severity text, bad_count bigint)
language plpgsql stable security definer set search_path = public as $$
begin
  if not has_role(array['admin']::app_role[]) then raise exception 'FORBIDDEN'; end if;
  return query
  select 'ING_UNVERIFIED'::text, 'Nguyên liệu dùng trong công thức đã xuất bản nhưng CHƯA xác minh dinh dưỡng'::text, 'blocker'::text,
         (select count(distinct i.id) from ingredients i
           join recipe_ingredients ri on ri.ingredient_id = i.id join recipes r on r.id = ri.recipe_id and r.status = 'published'
          where i.data_status <> 'verified')
  union all
  select 'REC_NOT_REVIEWED', 'Công thức đã xuất bản nhưng chưa có người duyệt hoặc chưa nấu thử', 'blocker',
         (select count(*) from recipes where status = 'published' and (reviewed_by is null or test_cooked_at is null))
  union all
  select 'RULES_UNAPPROVED', 'Quy tắc bệnh lý đang bật nhưng chưa được chuyên gia duyệt', 'blocker',
         (select count(*) from condition_rules where is_active and (approved_at is null or approved_by is null))
  union all
  select 'PROD_UNVERIFIED', 'Sản phẩm đang bán chưa xác minh giá/khối lượng tịnh/dị ứng', 'blocker',
         (select count(*) from products where is_active and (price_status <> 'verified' or not net_weight_verified or not allergen_verified))
  union all
  select 'SHIPPING_MISSING', 'Chưa có quy tắc phí vận chuyển mặc định (province = *)', 'blocker',
         (select case when exists (select 1 from shipping_rules where is_active and province = '*') then 0 else 1 end)
  union all
  select 'NO_ADMIN', 'Chưa có tài khoản admin', 'blocker',
         (select case when exists (select 1 from profiles where role = 'admin') then 0 else 1 end)
  union all
  select 'NO_NUTRITIONIST', 'Chưa có tài khoản nutritionist để duyệt nội dung', 'blocker',
         (select case when exists (select 1 from profiles where role = 'nutritionist') then 0 else 1 end)
  union all
  select 'ING_NO_PRODUCT', 'Nguyên liệu (không tùy chọn) trong công thức đã xuất bản chưa có sản phẩm đang bán', 'warning',
         (select count(distinct i.id) from ingredients i
           join recipe_ingredients ri on ri.ingredient_id = i.id and not ri.optional
           join recipes r on r.id = ri.recipe_id and r.status = 'published'
          where not ('water' = any(i.tags))
            and not exists (select 1 from products p where p.ingredient_id = i.id and p.is_active))
  union all
  select 'PROD_NO_IMAGE', 'Sản phẩm đang bán chưa có ảnh', 'warning',
         (select count(*) from products where is_active and image_url is null)
  union all
  select 'RECIPE_COUNT_LOW', 'Số công thức đã xuất bản dưới 50', 'warning',
         (select case when count(*) < 50 then 50 - count(*) else 0 end from recipes where status = 'published')
  union all
  select 'PAYMENTS_NOT_LIVE', 'Cổng thanh toán chưa bật chế độ thật (payments_live = false)', 'warning',
         (select case when app_setting_bool('payments_live', false) then 0 else 1 end);
end $$;
revoke all on function public.rpc_go_live_check() from public, anon;
grant execute on function public.rpc_go_live_check() to authenticated;

-- ---------- 6. ĐỔI CỜ CẤU HÌNH (CÓ CỔNG KIỂM TRA) ----------
create or replace function public.rpc_set_app_setting(p_key text, p_value jsonb) returns void
language plpgsql security definer set search_path = public as $$
declare v_blockers text;
begin
  if not has_role(array['admin']::app_role[]) then raise exception 'FORBIDDEN'; end if;
  if p_key not in ('demo_mode','payments_live','shop_enabled','ai_enabled') then raise exception 'UNKNOWN_SETTING'; end if;
  if jsonb_typeof(p_value) <> 'boolean' then raise exception 'INVALID_VALUE'; end if;

  if p_key = 'demo_mode' and p_value = 'false'::jsonb then            -- tắt demo = phát hành chính thức
    select string_agg(g.code || '(' || g.bad_count || ')', ', ') into v_blockers
      from public.rpc_go_live_check() g where g.severity = 'blocker' and g.bad_count > 0;
    if v_blockers is not null then raise exception 'GO_LIVE_BLOCKED: %', v_blockers; end if;
  end if;
  if p_key = 'payments_live' and p_value = 'true'::jsonb and app_setting_bool('demo_mode', true) then
    raise exception 'DEMO_MODE_STILL_ON';                              -- chỉ bật thanh toán thật sau khi tắt demo
  end if;

  insert into app_settings(key, value, updated_by) values (p_key, p_value, auth.uid())
  on conflict (key) do update set value = excluded.value, updated_at = now(), updated_by = auth.uid();
  insert into audit_log(actor, action, entity, entity_id, meta)
  values (auth.uid(), 'setting.change', 'app_settings', p_key, jsonb_build_object('value', p_value));
end $$;
revoke all on function public.rpc_set_app_setting(text, jsonb) from public, anon;
grant execute on function public.rpc_set_app_setting(text, jsonb) to authenticated;

```
