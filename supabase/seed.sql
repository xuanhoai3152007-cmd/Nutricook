-- =====================================================================
-- NutriCook · SEED
-- ⚠ Số liệu dinh dưỡng ở đây là ƯỚC TÍNH (source = 'seed_estimate') để chạy thử.
--   TRƯỚC KHI CÔNG KHAI: đối chiếu với Bảng thành phần thực phẩm Việt Nam (Viện Dinh dưỡng)
--   hoặc CSDL được cấp phép, rồi cập nhật cột source.
-- ⚠ condition_rules để approved_at = NULL: cần chuyên gia dinh dưỡng/bác sĩ duyệt.
-- =====================================================================

-- ---------- 1. DỊ ỨNG ----------
insert into allergens(code, name_vi) values
 ('peanut','Đậu phộng'),('tree_nut','Hạt cây (óc chó, hạnh nhân, điều…)'),('shellfish','Giáp xác (tôm, cua…)'),
 ('fish','Cá'),('milk','Sữa'),('egg','Trứng'),('gluten','Gluten (lúa mì…)'),('soy','Đậu nành'),('sesame','Vừng (mè)')
on conflict (code) do nothing;

-- ---------- 2. TÌNH TRẠNG SỨC KHỎE ----------
insert into health_conditions(code, name_vi, risk_tier, description) values
 ('diabetes_t2','Tiểu đường type 2','yellow','Kiểm soát đường và tinh bột; hỏi bác sĩ nếu dùng insulin/thuốc hạ đường.'),
 ('hypertension','Tăng huyết áp','yellow','Hạn chế natri (muối, nước mắm, đồ chế biến).'),
 ('dyslipidemia','Mỡ máu cao','yellow','Giảm chất béo bão hòa, tăng chất xơ.'),
 ('gout','Gout','yellow','Hạn chế thực phẩm nhiều purine, tránh bia rượu.'),
 ('obesity','Thừa cân / béo phì','yellow','Thâm hụt năng lượng vừa phải, đạm và chất xơ cao.'),
 ('gastritis','Dạ dày / trào ngược','yellow','Món mềm, ít dầu mỡ, ít cay chua.'),
 ('anemia','Thiếu máu','yellow','Tăng thực phẩm giàu sắt kèm vitamin C.'),
 ('ckd','Bệnh thận mạn','red','Đạm, kali, phospho, natri phụ thuộc giai đoạn → cần bác sĩ chỉ định.'),
 ('pregnancy','Mang thai / cho con bú','red','Nhu cầu và hạn chế đặc biệt → cần bác sĩ/chuyên gia.')
on conflict (code) do nothing;

-- ---------- 3. QUY TẮC (CHƯA DUYỆT) ----------
insert into condition_rules(condition_id, max_sodium_mg, min_fiber_g, max_purine_level,
   per_serving_max_sodium_mg, per_serving_max_sugar_g, excluded_ingredient_tags, preferred_tags, rationale, source_url)
select h.id, v.ms, v.mf, v.mp, v.pss, v.psg, v.ex, v.pr, v.ra, v.src
from (values
 ('diabetes_t2', null::int, 25, null::smallint, null::int, 10, '{sugary_drink,added_sugar_heavy}'::text[], '{high_fiber,low_sugar,whole_grain}'::text[],
   'Ưu tiên chất xơ, hạn chế đường tự do; chia đều tinh bột các bữa.', 'https://hellobacsi.com/community/tieu-duong/'),
 ('hypertension', 1500, null, null, 600, null, '{pickled,instant_noodle}', '{low_sodium}',
   'Giảm natri; tăng rau củ giàu kali (theo mô hình DASH).', 'https://viendinhduong.vn/en/lookup/de-tai-nghien-cuu-khoa-hoc/68035d58359ef722321fcf77'),
 ('dyslipidemia', null, 25, null, null, null, '{organ_meat,deep_fried}', '{high_fiber,omega3}',
   'Hạn chế mỡ động vật, nội tạng; tăng cá béo và chất xơ.', 'https://www.sggp.org.vn/phong-benh-hieu-qua-bang-dinh-duong-post244009.html'),
 ('gout', null, null, 1, null, null, '{organ_meat,alcohol,sugary_drink}', '{low_calorie}',
   'Tránh bia rượu, nội tạng; hạn chế hải sản/thịt đỏ nhiều purine.', 'https://www.vinmec.com/vie/bai-viet/che-do-dinh-duong-cho-benh-nhan-gout-vi'),
 ('obesity', null, 25, null, null, null, '{deep_fried,sugary_drink}', '{high_protein,high_fiber,low_calorie}',
   'Mật độ năng lượng thấp, no lâu.', null),
 ('gastritis', null, null, null, null, null, '{alcohol,caffeine,spicy_hot}', '{soft,gentle}',
   'Món mềm, ít cay, ít dầu mỡ, chia nhỏ bữa.', null),
 ('anemia', null, null, null, null, null, '{}', '{iron_rich}',
   'Tăng thực phẩm giàu sắt kèm vitamin C.', null)
) v(code, ms, mf, mp, pss, psg, ex, pr, ra, src)
join health_conditions h on h.code = v.code
where not exists (select 1 from condition_rules r where r.condition_id = h.id);

-- ---------- 4. NGUYÊN LIỆU (/100 g, ước tính) ----------
insert into ingredients
 (slug, name_vi, name_en, category, kcal, protein_g, carb_g, fat_g, sat_fat_g, fiber_g, sugar_g, sodium_mg, purine_level, glycemic_index, tags)
values
 ('gao-lut','Gạo lứt (sống)','Brown rice, raw','ngu_coc',350,7.5,73,2.7,0.6,3.5,0.7,5,0,66,'{grain,whole_grain,high_fiber}'),
 ('yen-mach','Yến mạch cán','Rolled oats','ngu_coc',389,16.9,66.3,6.9,1.2,10.6,1.0,2,0,55,'{grain,whole_grain,high_fiber}'),
 ('chuoi','Chuối','Banana','trai_cay',89,1.1,22.8,0.3,0.1,2.6,12.2,1,0,51,'{fruit}'),
 ('sua-chua-khong-duong','Sữa chua không đường','Plain yogurt','sua',61,3.5,4.7,3.3,2.1,0,4.7,46,0,35,'{dairy,animal}'),
 ('hat-chia','Hạt chia','Chia seeds','hat',486,16.5,42.1,30.7,3.3,34.4,0,16,0,null,'{seed,high_fiber,omega3}'),
 ('uc-ga','Ức gà (sống, bỏ da)','Chicken breast','thit',120,22.5,0,2.6,0.6,0,0,45,1,null,'{meat,animal,poultry,lean}'),
 ('ca-hoi','Cá hồi (sống)','Salmon','ca',208,20.4,0,13.4,3.1,0,0,59,1,null,'{fish,animal,omega3}'),
 ('ca-dieu-hong','Cá diêu hồng (sống)','Tilapia','ca',96,20.1,0,1.7,0.6,0,0,52,1,null,'{fish,animal,lean}'),
 ('tom','Tôm (sống)','Shrimp','hai_san',85,20.1,0,0.5,0.1,0,0,119,2,null,'{shellfish,animal,seafood}'),
 ('dau-hu','Đậu hũ','Tofu','dau',76,8.1,1.9,4.8,0.7,0.3,0.6,7,1,15,'{soy,plant_protein}'),
 ('bi-do','Bí đỏ','Pumpkin','rau_cu',26,1.0,6.5,0.1,0,0.5,2.8,1,0,75,'{vegetable}'),
 ('ca-chua','Cà chua','Tomato','rau_cu',18,0.9,3.9,0.2,0,1.2,2.6,5,0,30,'{vegetable}'),
 ('ca-rot','Cà rốt','Carrot','rau_cu',41,0.9,9.6,0.2,0,2.8,4.7,69,0,39,'{vegetable}'),
 ('bong-cai-xanh','Bông cải xanh','Broccoli','rau_cu',34,2.8,6.6,0.4,0.1,2.6,1.7,33,0,15,'{vegetable,high_fiber}'),
 ('hanh-tay','Hành tây','Onion','rau_cu',40,1.1,9.3,0.1,0,1.7,4.2,4,0,10,'{vegetable}'),
 ('hanh-la','Hành lá','Spring onion','rau_cu',32,1.8,7.3,0.2,0,2.6,2.3,16,0,null,'{vegetable,herb}'),
 ('rau-mui','Rau mùi (ngò rí)','Coriander','rau_cu',23,2.1,3.7,0.5,0,2.8,0.9,46,0,null,'{herb}'),
 ('toi','Tỏi','Garlic','gia_vi',149,6.4,33.1,0.5,0.1,2.1,1,17,0,null,'{herb}'),
 ('gung','Gừng','Ginger','gia_vi',80,1.8,17.8,0.8,0.2,2,1.7,13,0,null,'{herb}'),
 ('chanh','Chanh (nước vắt)','Lime','trai_cay',29,1.1,9.3,0.3,0,2.8,2.5,2,0,null,'{fruit,sour}'),
 ('ot','Ớt','Chili','gia_vi',40,1.9,8.8,0.4,0.1,1.5,5.3,9,0,null,'{vegetable,spicy_hot}'),
 ('dau-oliu','Dầu ô liu','Olive oil','dau_mo',884,0,0,100,13.8,0,0,2,0,null,'{oil}'),
 ('nuoc-mam','Nước mắm','Fish sauce','gia_vi',35,5.1,3.6,0,0,0,3.6,7000,1,null,'{condiment,high_sodium,fish}'),
 ('nuoc-tuong','Nước tương (xì dầu)','Soy sauce','gia_vi',53,8.1,4.9,0.6,0.1,0.8,0.4,5500,0,null,'{condiment,high_sodium,soy}'),
 ('muoi','Muối','Salt','gia_vi',0,0,0,0,0,0,0,38758,0,null,'{condiment,high_sodium}'),
 ('tieu-den','Tiêu đen','Black pepper','gia_vi',251,10.4,64,3.3,1.4,25.3,0.6,20,0,null,'{spice}'),
 ('duong','Đường','Sugar','gia_vi',387,0,100,0,0,0,100,1,0,65,'{sweetener,added_sugar}'),
 ('nuoc-loc','Nước lọc','Water','khac',0,0,0,0,0,0,0,0,0,null,'{water}')
on conflict (slug) do nothing;

insert into ingredient_allergens(ingredient_id, allergen_id)
select i.id, a.id from (values
  ('yen-mach','gluten'),('sua-chua-khong-duong','milk'),('ca-hoi','fish'),('ca-dieu-hong','fish'),
  ('tom','shellfish'),('dau-hu','soy'),('nuoc-mam','fish'),('nuoc-tuong','soy'),('nuoc-tuong','gluten')
) v(ing, alg)
join ingredients i on i.slug = v.ing join allergens a on a.code = v.alg
on conflict do nothing;

-- =====================================================================
-- 5. CÔNG THỨC CHI TIẾT (6 món). Tạo ở trạng thái draft → xuất bản ở cuối.
-- =====================================================================

-- ---------------------------------------------------------------------
-- R1. Cháo yến mạch chuối & sữa chua  (bữa sáng, 1 khẩu phần)
-- ---------------------------------------------------------------------
insert into recipes (slug,title,summary,intro,image_url,meal,cuisine,method,spice_level,texture,base_servings,
  prep_minutes,cook_minutes,difficulty,equipment,tips,common_mistakes,substitutions,storage_note,serving_suggestion,
  health_notes,tags,source_url)
values ('chao-yen-mach-chuoi','Cháo yến mạch chuối & sữa chua',
 'Bữa sáng ấm, mềm, ngọt tự nhiên từ chuối, xong trong 15 phút.',
 'Yến mạch nấu với nước tạo thành bát cháo sánh mịn, kết hợp chuối chín và sữa chua mát béo nhẹ. Món phù hợp người bận rộn, dạ dày nhạy cảm hoặc cần bữa sáng nhiều chất xơ.',
 'recipe-images/chao-yen-mach-chuoi.webp','{breakfast}','western','nấu cháo',0,'{soft,creamy}',1,5,8,1,
 array['Nồi nhỏ','Muỗng gỗ','Bát','Nĩa','Cân bếp'],
 array['Ngâm yến mạch trong nước lạnh 10 phút trước khi nấu để cháo mềm mịn hơn.','Chuối chín vàng có đốm nâu nhẹ ngọt hơn, không cần thêm đường.','Có thể thay nước bằng sữa hạt không đường nếu không dị ứng.'],
 array['Nấu lửa quá lớn làm cháo cháy đáy: luôn giữ lửa nhỏ và khuấy đều khi đã cho yến mạch vào.','Cho chuối vào nấu lâu khiến chuối nhũn và có vị chát: chỉ trộn sau khi tắt bếp.'],
 '[{"ingredient":"Sữa chua","alternatives":["Sữa chua hạt không đường","Đậu hũ non xay mịn"],"note":"Dành cho người dị ứng sữa."},{"ingredient":"Chuối","alternatives":["Táo bào mỏng","Đu đủ chín"],"note":"Giữ độ ngọt tự nhiên cho bát cháo."}]',
 'Nên ăn ngay. Nếu thừa, để nguội, đậy kín và bảo quản tủ lạnh tối đa 24 giờ; hâm lại với 1–2 muỗng canh nước.',
 'Dùng kèm một ly nước ấm hoặc trà không đường.',
 'Yến mạch có thể chứa gluten do nhiễm chéo; món có sữa. Người tiểu đường nên chú ý lượng đường từ chuối (xem bảng dinh dưỡng).',
 '{soft,whole_grain}', null);

insert into recipe_ingredients(recipe_id,ingredient_id,group_name,amount_g,display_amount,display_unit,prep_note,note,optional,scale_mode,sort_order)
select r.id,i.id,v.grp,v.g,v.da::numeric,v.du::text,v.prep::text,v.note::text,v.opt::boolean,v.sm,v.so
from recipes r join (values
 ('yen-mach','Cháo yến mạch',40,4,'muỗng canh',null,'Yến mạch cán dẹt, không dùng loại ăn liền có đường',false,'linear',1),
 ('nuoc-loc','Cháo yến mạch',200,200,'ml',null,'Tỉ lệ khoảng 1 yến mạch : 5 nước cho cháo loãng vừa',false,'linear',2),
 ('muoi','Cháo yến mạch',0.3,1,'nhúm nhỏ',null,'Giúp nổi vị ngọt của chuối',false,'sublinear',3),
 ('chuoi','Topping',100,1,'quả nhỏ','Bóc vỏ; một nửa dằm, một nửa cắt lát tròn dày 5 mm',null,false,'linear',4),
 ('sua-chua-khong-duong','Topping',60,4,'muỗng canh',null,'Chọn loại không đường',false,'linear',5),
 ('hat-chia','Topping',5,1,'muỗng cà phê',null,null,false,'linear',6)
) v(ing,grp,g,da,du,prep,note,opt,sm,so) on true
join ingredients i on i.slug = v.ing where r.slug = 'chao-yen-mach-chuoi';

insert into recipe_steps(recipe_id,step_no,phase,title,instruction,timer_seconds,heat,tip)
select r.id,v.n,v.ph,v.t,v.ins,v.tm::int,v.h,v.tip::text
from recipes r join (values
 (1,'prep','Chuẩn bị nguyên liệu','Cân 40 g yến mạch (khoảng 4 muỗng canh) và đong 200 ml nước. Bóc vỏ chuối, cắt một nửa thành lát tròn dày khoảng 5 mm để trang trí, nửa còn lại dùng để dằm.',null,'none',null),
 (2,'prep','Dằm chuối','Cho nửa quả chuối còn lại vào bát nhỏ, dùng nĩa dằm cho nhuyễn nhưng vẫn còn vài vụn nhỏ để có độ ngọt tự nhiên và cảm giác ăn thú vị.',null,'none','Chuối chín vàng có đốm nâu nhẹ sẽ ngọt hơn, nhờ đó không cần thêm đường.'),
 (3,'cook','Đun sôi nước','Cho 200 ml nước và một nhúm muối nhỏ vào nồi, đun lửa vừa tới khi mặt nước sủi tăm nhỏ li ti (khoảng 2 phút).',120,'medium',null),
 (4,'cook','Nấu yến mạch','Cho yến mạch vào nồi, giảm lửa nhỏ và khuấy đều liên tục bằng muỗng gỗ trong 4–5 phút, tới khi cháo sánh như cháo loãng và hạt yến mạch nở mềm.',270,'low','Nếu cháo đặc quá, thêm 2–3 muỗng canh nước nóng. Khuấy sát đáy nồi để cháo không bị dính cháy.'),
 (5,'cook','Trộn chuối','Tắt bếp, cho chuối dằm vào khuấy đều khoảng 20 giây, đậy nắp để nghỉ 1 phút cho cháo nở thêm và quyện vị.',60,'none',null),
 (6,'finish','Trang trí và thưởng thức','Múc cháo ra bát, đặt sữa chua vào giữa, xếp lát chuối xung quanh và rắc hạt chia. Chờ 3–4 phút cho bớt nóng rồi ăn.',null,'none','Sữa chua lạnh sẽ làm dịu độ nóng của cháo; nếu thích ăn nóng hoàn toàn, đặt sữa chua ở bên cạnh thay vì trên cháo.')
) v(n,ph,t,ins,tm,h,tip) on true where r.slug = 'chao-yen-mach-chuoi';

-- ---------------------------------------------------------------------
-- R2. Cơm gạo lứt, ức gà áp chảo sốt chanh gừng & bông cải xanh
-- ---------------------------------------------------------------------
insert into recipes (slug,title,summary,intro,image_url,meal,cuisine,method,spice_level,texture,base_servings,
  prep_minutes,cook_minutes,difficulty,equipment,tips,common_mistakes,substitutions,storage_note,serving_suggestion,
  health_notes,tags)
values ('com-gao-lut-uc-ga-ap-chao','Cơm gạo lứt, ức gà áp chảo sốt chanh gừng & bông cải xanh',
 'Bữa chính giàu đạm, nhiều chất xơ; ức gà mềm ẩm nhờ kỹ thuật rạch dày đều và nghỉ thịt.',
 'Ức gà dễ bị khô nếu nấu sai cách. Công thức này hướng dẫn rạch mở thịt cho dày đều, áp chảo đúng lửa và để nghỉ trước khi cắt, kết hợp sốt chanh gừng thanh nhẹ ít muối và bông cải xanh hấp giòn.',
 'recipe-images/com-gao-lut-uc-ga-ap-chao.webp','{lunch,dinner}','asian','áp chảo',0,'{}',2,20,35,2,
 array['Nồi cơm điện hoặc nồi có nắp','Chảo chống dính','Nồi và xửng hấp','Dao và thớt','Bát nhỏ để pha sốt','Cân bếp'],
 array['Rạch mở thịt cho dày đều giúp gà chín cùng lúc, không bị khô phần mỏng.','Áp chảo ở lửa vừa; lửa quá lớn làm ngoài cháy trong sống.','Pha sốt sẵn trước khi nấu để thao tác nhanh khi gà vừa chín.'],
 array['Cho thịt vào chảo chưa nóng: thịt dính chảo và không vàng.','Đảo thịt liên tục: mất lớp vàng và thịt ra nước. Chỉ lật một lần.','Nấu gà quá lâu làm thịt khô dai: chín tới là chuyển ra nghỉ ngay.'],
 '[{"ingredient":"Ức gà","alternatives":["Cá diêu hồng phi lê","Đậu hũ cứng áp chảo"],"note":"Cá và đậu hũ chỉ cần áp chảo 2–3 phút mỗi mặt."},{"ingredient":"Gạo lứt","alternatives":["Gạo thường","Khoai lang hấp"],"note":"Gạo thường chín nhanh hơn và không cần ngâm."},{"ingredient":"Nước mắm","alternatives":["Nước tương giảm muối"],"note":"Dùng ít hơn nếu cần ăn nhạt."}]',
 'Bảo quản cơm và thịt riêng trong hộp kín, tủ lạnh tối đa 2 ngày. Hâm lại bằng lò vi sóng, đậy kín và thêm 1 muỗng nước để thịt không khô. Chỉ hâm một lần.',
 'Ăn kèm dưa leo hoặc cà chua thái lát.',
 'Giàu đạm và chất xơ. Natri chủ yếu đến từ nước mắm; có thể giảm còn 1 muỗng cà phê nếu cần ăn nhạt.',
 '{lean_protein,whole_grain}');

insert into recipe_ingredients(recipe_id,ingredient_id,group_name,amount_g,display_amount,display_unit,prep_note,note,optional,scale_mode,sort_order)
select r.id,i.id,v.grp,v.g,v.da::numeric,v.du::text,v.prep::text,v.note::text,v.opt::boolean,v.sm,v.so
from recipes r join (values
 ('gao-lut','Cơm gạo lứt',120,120,'g',null,'Khoảng 2/3 chén',false,'linear',1),
 ('nuoc-loc','Cơm gạo lứt',260,260,'ml',null,'Tỉ lệ khoảng 1 gạo : 2,2 nước',false,'linear',2),
 ('uc-ga','Ức gà áp chảo',300,2,'miếng (~150 g)','Lau thật khô; rạch ngang giữa miếng thịt (không cắt đứt) rồi mở ra như quyển sách',null,false,'linear',3),
 ('toi','Ức gà áp chảo',8,2,'tép','Băm nhuyễn',null,false,'linear',4),
 ('tieu-den','Ức gà áp chảo',0.5,0.25,'muỗng cà phê',null,null,false,'sublinear',5),
 ('dau-oliu','Ức gà áp chảo',10,2,'muỗng cà phê',null,'Chia 1 muỗng để ướp, 1 muỗng để áp chảo',false,'sublinear',6),
 ('bong-cai-xanh','Bông cải hấp',250,250,'g','Tách thành cụm nhỏ 3–4 cm, rửa sạch, để ráo',null,false,'linear',7),
 ('chanh','Sốt chanh gừng',30,0.5,'quả','Vắt lấy nước, bỏ hạt',null,false,'linear',8),
 ('gung','Sốt chanh gừng',8,8,'g','Băm nhuyễn',null,false,'linear',9),
 ('nuoc-mam','Sốt chanh gừng',8,1.5,'muỗng cà phê',null,'Có thể giảm còn 1 muỗng cà phê nếu cần ăn nhạt',false,'sublinear',10),
 ('nuoc-loc','Sốt chanh gừng',30,2,'muỗng canh',null,null,false,'linear',11),
 ('dau-oliu','Sốt chanh gừng',5,1,'muỗng cà phê',null,null,false,'sublinear',12)
) v(ing,grp,g,da,du,prep,note,opt,sm,so) on true
join ingredients i on i.slug = v.ing where r.slug = 'com-gao-lut-uc-ga-ap-chao';

insert into recipe_steps(recipe_id,step_no,phase,title,instruction,timer_seconds,heat,tip)
select r.id,v.n,v.ph,v.t,v.ins,v.tm::int,v.h,v.tip::text
from recipes r join (values
 (1,'prep','Ngâm gạo lứt','Vo gạo lứt 2–3 lần cho sạch, sau đó ngâm với nước ấm khoảng 40°C trong 30–60 phút. Ngâm giúp hạt mềm, chín đều và rút ngắn thời gian nấu.',1800,'none','Có thể ngâm từ tối hôm trước trong tủ lạnh; đổ bỏ nước ngâm và vo lại một lần trước khi nấu.'),
 (2,'cook','Nấu cơm gạo lứt','Cho gạo đã ngâm cùng 260 ml nước vào nồi cơm điện và chọn chế độ gạo lứt (hoặc nấu thường rồi ủ thêm 10 phút). Nếu nấu bằng nồi thường: đun sôi, hạ lửa nhỏ nhất, đậy kín nắp 35–40 phút.',2400,'low','Không mở nắp khi đang nấu. Chín xong để ủ 10 phút rồi xới tơi cho cơm không bị nát.'),
 (3,'prep','Sơ chế và ướp ức gà','Rửa ức gà, lau thật khô bằng khăn giấy. Đặt bàn tay phẳng lên miếng thịt, dùng dao sắc rạch ngang ở giữa (không cắt đứt) rồi mở ra như quyển sách để thịt dày đều khoảng 1,5 cm. Ướp với tỏi băm, tiêu và 1 muỗng cà phê dầu ô liu trong 15 phút.',900,'none','Bề mặt thịt khô thì mới vàng đẹp; thịt còn ướt sẽ bị luộc thay vì áp chảo.'),
 (4,'prep','Sơ chế bông cải và pha sốt','Tách bông cải thành cụm nhỏ, rửa sạch, để ráo. Pha sốt: trộn nước vắt nửa quả chanh, gừng băm nhuyễn, nước mắm, 2 muỗng canh nước và 1 muỗng cà phê dầu ô liu. Nếm thử: vị chua, mặn nhẹ và thơm gừng.',null,'none','Nếu sốt quá chua, thêm 1 muỗng canh nước; không cần thêm đường.'),
 (5,'cook','Áp chảo ức gà','Làm nóng chảo chống dính lửa vừa khoảng 1 phút, cho 1 muỗng cà phê dầu ô liu. Đặt thịt vào chảo và KHÔNG đảo; áp chảo 4–5 phút tới khi mặt dưới vàng nâu, lật lại và áp tiếp 4–5 phút.',540,'medium','Gà chín khi chọc đũa thấy nước thịt trong, không còn hồng; nếu có nhiệt kế, nhiệt độ ở tâm thịt đạt 74°C.'),
 (6,'cook','Hấp bông cải xanh','Đun sôi khoảng 200 ml nước trong nồi, đặt xửng hấp, cho bông cải vào và đậy nắp hấp 3–4 phút tới khi xanh đậm và vẫn còn giòn nhẹ.',210,'high','Không hấp quá 5 phút để giữ màu và độ giòn; có thể ngâm nhanh vào nước đá 10 giây để giữ màu xanh tươi.'),
 (7,'cook','Để nghỉ thịt','Chuyển ức gà ra thớt, đậy lỏng bằng giấy bạc và để nghỉ 5 phút để nước thịt phân bố đều, không chảy ra khi cắt.',300,'none',null),
 (8,'finish','Cắt và bày đĩa','Cắt ức gà thành lát dày khoảng 1 cm theo chiều ngang thớ thịt. Xới cơm ra đĩa, xếp gà và bông cải, rưới sốt chanh gừng lên thịt. Dùng nóng.',null,'none',null)
) v(n,ph,t,ins,tm,h,tip) on true where r.slug = 'com-gao-lut-uc-ga-ap-chao';

-- ---------------------------------------------------------------------
-- R3. Cá hồi áp chảo sốt chanh với bông cải & cà rốt
-- ---------------------------------------------------------------------
insert into recipes (slug,title,summary,intro,image_url,meal,cuisine,method,spice_level,texture,base_servings,
  prep_minutes,cook_minutes,difficulty,equipment,tips,common_mistakes,substitutions,storage_note,serving_suggestion,
  health_notes,tags)
values ('ca-hoi-ap-chao-sot-chanh','Cá hồi áp chảo sốt chanh với bông cải & cà rốt',
 'Cá hồi da giòn, thịt mọng, ăn cùng rau hấp và sốt chanh tỏi thanh nhẹ.',
 'Cá hồi giàu chất béo tốt (omega-3). Bí quyết là lau khô da cá, dùng chảo thật nóng và chỉ lật một lần để có lớp da giòn mà thịt bên trong vẫn mềm.',
 'recipe-images/ca-hoi-ap-chao-sot-chanh.webp','{lunch,dinner}','western','áp chảo',0,'{}',2,15,15,2,
 array['Chảo chống dính hoặc chảo gang','Nồi và xửng hấp','Xẻng lật cá','Nhíp nhổ xương','Dao và thớt'],
 array['Để cá ở nhiệt độ phòng 15 phút trước khi nấu để chín đều.','Ép nhẹ cá bằng xẻng 10 giây đầu để da phẳng, tiếp xúc đều với chảo.','Rưới sốt chanh sau khi tắt bếp để giữ vị chua tươi.'],
 array['Da cá còn ướt: da dai, không giòn. Luôn thấm khô kỹ.','Lật cá quá sớm: da dính chảo và rách. Chờ đến khi da tự bong.','Nấu quá lâu: cá khô bở. Cá chín khi thịt dễ tách thớ nhưng vẫn ẩm.'],
 '[{"ingredient":"Cá hồi","alternatives":["Cá diêu hồng phi lê","Cá basa phi lê"],"note":"Cá nạc hơn nên áp chảo ngắn hơn khoảng 1 phút mỗi mặt."},{"ingredient":"Bông cải xanh","alternatives":["Đậu cove","Măng tây"],"note":"Hấp 3–4 phút."}]',
 'Cá ngon nhất khi ăn ngay. Bảo quản thừa tủ lạnh tối đa 1 ngày, hâm nhẹ trong chảo hoặc lò nướng 150°C 5 phút; không nên hâm lại nhiều lần.',
 'Ăn kèm cơm gạo lứt hoặc khoai lang hấp.',
 'Phụ nữ mang thai, trẻ nhỏ và người cao tuổi nên nấu cá chín kỹ. Món có cá (dị ứng cá cần tránh).',
 '{omega3}');

insert into recipe_ingredients(recipe_id,ingredient_id,group_name,amount_g,display_amount,display_unit,prep_note,note,optional,scale_mode,sort_order)
select r.id,i.id,v.grp,v.g,v.da::numeric,v.du::text,v.prep::text,v.note::text,v.opt::boolean,v.sm,v.so
from recipes r join (values
 ('ca-hoi','Cá hồi',300,2,'miếng (~150 g)','Để ở nhiệt độ phòng 15 phút, lau khô, giữ nguyên da','Chọn miếng phi lê dày đều',false,'linear',1),
 ('muoi','Cá hồi',0.8,1,'nhúm lớn',null,null,false,'sublinear',2),
 ('tieu-den','Cá hồi',0.5,0.25,'muỗng cà phê',null,null,false,'sublinear',3),
 ('dau-oliu','Cá hồi',10,2,'muỗng cà phê',null,'1 muỗng để ướp, 1 muỗng để áp chảo',false,'sublinear',4),
 ('toi','Cá hồi',8,2,'tép','Băm nhuyễn',null,false,'linear',5),
 ('bong-cai-xanh','Rau hấp',200,200,'g','Tách cụm nhỏ 3–4 cm',null,false,'linear',6),
 ('ca-rot','Rau hấp',100,1,'củ nhỏ','Gọt vỏ, thái que dài 5 cm, dày 0,5 cm',null,false,'linear',7),
 ('dau-oliu','Rau hấp',5,1,'muỗng cà phê',null,'Trộn với rau sau khi hấp',false,'sublinear',8),
 ('chanh','Sốt chanh',30,0.5,'quả','Vắt lấy nước',null,false,'linear',9),
 ('nuoc-loc','Sốt chanh',20,4,'muỗng cà phê',null,null,false,'linear',10),
 ('rau-mui','Sốt chanh',5,1,'nhánh nhỏ','Ngắt lá, thái nhỏ','Dùng để trang trí',false,'fixed',11)
) v(ing,grp,g,da,du,prep,note,opt,sm,so) on true
join ingredients i on i.slug = v.ing where r.slug = 'ca-hoi-ap-chao-sot-chanh';

insert into recipe_steps(recipe_id,step_no,phase,title,instruction,timer_seconds,heat,tip)
select r.id,v.n,v.ph,v.t,v.ins,v.tm::int,v.h,v.tip::text
from recipes r join (values
 (1,'prep','Làm ấm và lau khô cá','Lấy cá ra khỏi tủ lạnh trước 15 phút. Dùng khăn giấy thấm khô cả hai mặt, đặc biệt là phần da. Kiểm tra và nhổ xương nhỏ còn sót bằng nhíp.',900,'none','Da khô là điều kiện bắt buộc để có lớp da giòn.'),
 (2,'prep','Ướp cá','Rắc muối và tiêu lên hai mặt, thoa mỏng 1 muỗng cà phê dầu ô liu. Để yên 10 phút. Không ướp muối lâu hơn vì cá sẽ ra nước.',600,'none',null),
 (3,'prep','Sơ chế rau củ và pha sốt','Tách bông cải thành cụm nhỏ, gọt cà rốt và thái que. Tỏi bóc vỏ băm nhuyễn. Vắt chanh vào bát, thêm 20 ml nước và rau mùi thái nhỏ để làm sốt.',null,'none',null),
 (4,'cook','Hấp rau củ','Cho cà rốt vào xửng hấp trước, 1 phút sau cho bông cải; hấp tổng cộng 4–5 phút tới khi mềm vừa mà vẫn giòn. Chuyển ra đĩa, trộn với 1 muỗng cà phê dầu ô liu.',300,'high',null),
 (5,'cook','Áp chảo phía da','Làm nóng chảo lửa vừa-lớn 1–2 phút, thêm 1 muỗng cà phê dầu. Đặt cá úp mặt da xuống, ấn nhẹ bằng xẻng 10 giây. Áp chảo khoảng 4 phút tới khi da vàng giòn và thịt cá chín dần lên khoảng 2/3 độ dày.',240,'high','Đừng lật sớm: da sẽ tự bong khỏi chảo khi đã đủ vàng.'),
 (6,'cook','Lật cá và phi tỏi','Lật cá, giảm lửa vừa, áp thêm 2–3 phút. Cho tỏi băm vào góc chảo, đảo khoảng 20 giây cho thơm (không để cháy tỏi).',180,'medium','Cá chín khi thịt chuyển từ đỏ cam sang hồng nhạt và dễ tách thớ. Phụ nữ mang thai, trẻ nhỏ và người cao tuổi nên nấu cá chín kỹ.'),
 (7,'finish','Rưới sốt chanh','Tắt bếp, rưới sốt chanh vào chảo, lắc nhẹ khoảng 30 giây cho sốt quyện với tỏi và dầu cá.',null,'none',null),
 (8,'finish','Bày đĩa','Xếp rau củ ra đĩa, đặt cá lên trên với da hướng lên, rưới phần sốt còn trong chảo và rắc rau mùi. Ăn ngay để da còn giòn.',null,'none',null)
) v(n,ph,t,ins,tm,h,tip) on true where r.slug = 'ca-hoi-ap-chao-sot-chanh';

-- ---------------------------------------------------------------------
-- R4. Canh bí đỏ nấu tôm
-- ---------------------------------------------------------------------
insert into recipes (slug,title,summary,intro,image_url,meal,cuisine,method,spice_level,texture,base_servings,
  prep_minutes,cook_minutes,difficulty,equipment,tips,common_mistakes,substitutions,storage_note,serving_suggestion,
  health_notes,tags)
values ('canh-bi-do-tom','Canh bí đỏ nấu tôm',
 'Canh ngọt thanh, mềm, dễ nấu; hợp bữa cơm gia đình và người ăn nhạt.',
 'Bí đỏ nấu mềm tạo vị ngọt tự nhiên, tôm xào sơ giữ độ giòn ngọt. Món cần rất ít gia vị, phù hợp khi muốn giảm muối.',
 'recipe-images/canh-bi-do-tom.webp','{lunch,dinner}','viet','canh',0,'{soft,liquid}',2,15,15,1,
 array['Nồi canh','Dao và thớt','Muôi','Tăm hoặc dao nhỏ để rút chỉ tôm'],
 array['Thái bí đều cỡ 2 cm để chín cùng lúc.','Dằm 1–2 miếng bí vào nước để canh sánh nhẹ và ngọt hơn.','Nêm nhạt rồi mới nêm thêm; tôm và bí đã có vị ngọt.'],
 array['Nấu tôm quá lâu làm tôm dai: xào sơ rồi cho lại vào cuối.','Cho bí vào khi nước chưa sôi: bí dễ nát và đục nước.'],
 '[{"ingredient":"Tôm","alternatives":["Đậu hũ non","Ức gà thái mỏng"],"note":"Người bị gout hoặc dị ứng hải sản nên dùng đậu hũ non, cho vào cuối và nấu 2 phút."}]',
 'Nên dùng trong ngày. Có thể bảo quản tủ lạnh tối đa 1 ngày và đun sôi lại kỹ trước khi ăn.',
 'Ăn với cơm trắng hoặc cơm gạo lứt và một món rau luộc.',
 'Món có tôm (dị ứng giáp xác cần tránh); tôm có hàm lượng purine ở mức cao, người bị gout nên thay bằng đậu hũ.',
 '{soft,gentle}');

insert into recipe_ingredients(recipe_id,ingredient_id,group_name,amount_g,display_amount,display_unit,prep_note,note,optional,scale_mode,sort_order)
select r.id,i.id,v.grp,v.g,v.da::numeric,v.du::text,v.prep::text,v.note::text,v.opt::boolean,v.sm,v.so
from recipes r join (values
 ('tom','Tôm',200,200,'g','Bóc vỏ, rút chỉ lưng, rửa nhanh với nước muối loãng, để ráo',null,false,'linear',1),
 ('toi','Tôm',8,2,'tép','Băm nhuyễn',null,false,'linear',2),
 ('tieu-den','Tôm',0.3,0.25,'muỗng cà phê',null,null,false,'sublinear',3),
 ('nuoc-mam','Tôm',6,1,'muỗng cà phê',null,'Dùng để ướp tôm',false,'sublinear',4),
 ('bi-do','Nấu canh',400,400,'g','Gọt vỏ, bỏ hạt, thái miếng vuông 2 cm',null,false,'linear',5),
 ('nuoc-loc','Nấu canh',600,600,'ml',null,null,false,'linear',6),
 ('dau-oliu','Nấu canh',5,1,'muỗng cà phê',null,'Dùng để phi hành',false,'sublinear',7),
 ('hanh-la','Nấu canh',15,3,'nhánh','Cắt khúc 2 cm, tách phần trắng và phần xanh',null,false,'sublinear',8)
) v(ing,grp,g,da,du,prep,note,opt,sm,so) on true
join ingredients i on i.slug = v.ing where r.slug = 'canh-bi-do-tom';

insert into recipe_steps(recipe_id,step_no,phase,title,instruction,timer_seconds,heat,tip)
select r.id,v.n,v.ph,v.t,v.ins,v.tm::int,v.h,v.tip::text
from recipes r join (values
 (1,'prep','Sơ chế và ướp tôm','Bóc vỏ tôm, dùng tăm hoặc dao nhỏ rút chỉ đen ở lưng. Rửa nhanh với nước muối loãng, để ráo. Ướp tôm với tỏi băm, tiêu và 1 muỗng cà phê nước mắm trong 10 phút.',600,'none','Tôm tươi có thịt chắc, màu trong; tôm có mùi lạ hoặc nhớt thì không nên dùng.'),
 (2,'prep','Sơ chế bí đỏ và hành','Gọt vỏ bí đỏ, bỏ ruột và hạt, thái miếng vuông khoảng 2 cm cho đều. Hành lá cắt khúc 2 cm, tách phần trắng và phần xanh.',null,'none',null),
 (3,'cook','Phi hành và xào tôm','Đun nóng dầu ô liu trong nồi lửa vừa, phi thơm phần trắng hành lá khoảng 20 giây. Cho tôm vào xào 1–2 phút tới khi chuyển màu hồng cam thì múc ra bát riêng.',120,'medium','Chỉ xào sơ để tôm không bị dai khi nấu lại.'),
 (4,'cook','Nấu bí đỏ','Đổ 600 ml nước vào nồi, đun sôi rồi cho bí đỏ vào. Hạ lửa vừa và nấu 8–10 phút tới khi bí mềm (đũa xuyên qua dễ dàng).',540,'medium','Dùng muôi dằm 1–2 miếng bí vào nước để canh sánh nhẹ và ngọt tự nhiên.'),
 (5,'cook','Cho tôm vào và nêm','Cho tôm trở lại nồi, nấu thêm 2 phút ở lửa nhỏ. Nêm nhẹ bằng chút tiêu; chỉ thêm vài giọt nước mắm nếu thấy nhạt.',120,'low','Ưu tiên nêm nhạt vì tôm và bí đã có vị ngọt.'),
 (6,'finish','Tắt bếp và dọn ăn','Tắt bếp, rắc phần xanh hành lá, đậy nắp 1 phút cho thơm. Múc ra tô và dùng nóng.',60,'none',null)
) v(n,ph,t,ins,tm,h,tip) on true where r.slug = 'canh-bi-do-tom';

-- ---------------------------------------------------------------------
-- R5. Đậu hũ sốt cà chua (chay)
-- ---------------------------------------------------------------------
insert into recipes (slug,title,summary,intro,image_url,meal,cuisine,method,spice_level,texture,base_servings,
  prep_minutes,cook_minutes,difficulty,equipment,tips,common_mistakes,substitutions,storage_note,serving_suggestion,
  health_notes,tags)
values ('dau-hu-sot-ca-chua','Đậu hũ sốt cà chua (món chay)',
 'Đậu hũ vàng nhẹ, sốt cà chua chua ngọt tự nhiên, món chay đơn giản cho bữa cơm.',
 'Món chay quen thuộc, ít gia vị, nhiều đạm thực vật. Cà chua được lột vỏ và xào chín mềm để sốt sánh mịn mà không cần thêm nhiều đường hay muối.',
 'recipe-images/dau-hu-sot-ca-chua.webp','{lunch,dinner}','viet','sốt',0,'{soft}',2,10,15,1,
 array['Chảo chống dính','Dao và thớt','Muỗng gỗ hoặc xẻng silicone','Nồi nhỏ để chần cà chua'],
 array['Thấm khô đậu hũ để áp chảo không bị dính và vỡ.','Chọn cà chua chín đỏ để sốt ngọt tự nhiên, không cần đường.','Lật đậu hũ bằng xẻng, tránh khuấy mạnh.'],
 array['Cho đậu hũ vào sốt rồi khuấy mạnh: đậu bị nát. Chỉ xoay chảo hoặc lật nhẹ.','Thêm quá nhiều nước tương: món mặn và át vị cà chua.'],
 '[{"ingredient":"Đậu hũ","alternatives":["Nấm đùi gà","Trứng luộc"],"note":"Nấm đùi gà cắt khoanh, áp chảo cho xém cạnh."},{"ingredient":"Nước tương","alternatives":["Nước tương giảm muối"],"note":"Cho người cần giảm natri."}]',
 'Bảo quản trong hộp kín ngăn mát tối đa 2 ngày; hâm lại ở lửa nhỏ, thêm chút nước nếu sốt đặc.',
 'Ăn với cơm trắng hoặc cơm gạo lứt và rau luộc.',
 'Món có đậu nành (dị ứng đậu nành cần tránh). Nước tương có thể chứa gluten.',
 '{plant_based,soft}');

insert into recipe_ingredients(recipe_id,ingredient_id,group_name,amount_g,display_amount,display_unit,prep_note,note,optional,scale_mode,sort_order)
select r.id,i.id,v.grp,v.g,v.da::numeric,v.du::text,v.prep::text,v.note::text,v.opt::boolean,v.sm,v.so
from recipes r join (values
 ('dau-hu','Đậu hũ',400,4,'miếng','Cắt miếng 3×3×1,5 cm, thấm khô bằng khăn giấy',null,false,'linear',1),
 ('dau-oliu','Đậu hũ',10,2,'muỗng cà phê',null,'Dùng để áp chảo',false,'sublinear',2),
 ('ca-chua','Sốt cà chua',400,4,'quả vừa','Khía chữ thập ở đáy, chần nước sôi 30 giây, lột vỏ, cắt hạt lựu',null,false,'linear',3),
 ('hanh-tay','Sốt cà chua',80,0.5,'củ','Thái hạt lựu nhỏ',null,false,'linear',4),
 ('toi','Sốt cà chua',8,2,'tép','Băm nhuyễn',null,false,'linear',5),
 ('nuoc-tuong','Sốt cà chua',10,2,'muỗng cà phê',null,'Có thể dùng loại giảm muối',false,'sublinear',6),
 ('tieu-den','Sốt cà chua',0.5,0.25,'muỗng cà phê',null,null,false,'sublinear',7),
 ('nuoc-loc','Sốt cà chua',100,100,'ml',null,null,false,'linear',8),
 ('duong','Sốt cà chua',3,1,'muỗng cà phê',null,'Chỉ thêm khi cà chua còn chua',true,'sublinear',9),
 ('hanh-la','Hoàn thiện',15,3,'nhánh','Cắt nhỏ',null,false,'sublinear',10),
 ('ot','Hoàn thiện',5,1,'quả','Thái lát mỏng','Thêm nếu thích ăn cay',true,'sublinear',11)
) v(ing,grp,g,da,du,prep,note,opt,sm,so) on true
join ingredients i on i.slug = v.ing where r.slug = 'dau-hu-sot-ca-chua';

insert into recipe_steps(recipe_id,step_no,phase,title,instruction,timer_seconds,heat,tip)
select r.id,v.n,v.ph,v.t,v.ins,v.tm::int,v.h,v.tip::text
from recipes r join (values
 (1,'prep','Cắt và thấm khô đậu hũ','Cắt đậu hũ thành miếng 3×3×1,5 cm. Đặt lên khăn giấy, thấm thật khô cả hai mặt trong 5 phút để áp chảo không bị bắn dầu và dính chảo.',300,'none',null),
 (2,'prep','Chần và lột vỏ cà chua','Khía chữ thập ở đáy mỗi quả cà chua, thả vào nước sôi 30 giây rồi vớt ra ngâm nước lạnh. Lột vỏ, bỏ cuống và cắt hạt lựu.',30,'high','Vỏ cà chua bong ra dễ dàng khi vừa nứt; cà chua chín đỏ cho sốt ngọt và đậm màu.'),
 (3,'prep','Sơ chế hành tỏi','Hành tây thái hạt lựu nhỏ, tỏi băm nhuyễn, hành lá cắt nhỏ. Để riêng phần hành lá để rắc cuối.',null,'none',null),
 (4,'cook','Áp chảo đậu hũ','Làm nóng chảo chống dính lửa vừa, cho 2 muỗng cà phê dầu ô liu. Xếp đậu hũ vào chảo, áp chảo 2–3 phút mỗi mặt tới khi vàng nhẹ. Gắp ra đĩa.',300,'medium','Chảo nóng và đậu hũ khô là hai điều kiện để đậu không dính, không vỡ.'),
 (5,'cook','Xào hành tỏi và cà chua','Trong cùng chảo, phi tỏi và hành tây 1 phút cho thơm. Cho cà chua vào, đảo 3–4 phút tới khi cà chua ra nước và mềm nhũn.',240,'medium',null),
 (6,'cook','Nêm và nấu sốt','Thêm 100 ml nước, nước tương và tiêu. Đun lửa nhỏ 5 phút cho sốt hơi sánh. Nếm thử: chỉ thêm 1 muỗng cà phê đường nếu cà chua còn chua.',300,'low','Cà chua chín đỏ thường đủ ngọt, nhờ đó món không cần đường.'),
 (7,'cook','Cho đậu hũ vào sốt','Cho đậu hũ vào chảo, đun lửa nhỏ 3 phút, xoay chảo hoặc lật nhẹ bằng xẻng để đậu thấm sốt mà không nát.',180,'low',null),
 (8,'finish','Rắc hành và dùng nóng','Tắt bếp, rắc hành lá (và ớt nếu thích ăn cay) lên trên. Dùng nóng với cơm.',null,'none',null)
) v(n,ph,t,ins,tm,h,tip) on true where r.slug = 'dau-hu-sot-ca-chua';

-- ---------------------------------------------------------------------
-- R6. Cá diêu hồng hấp gừng hành
-- ---------------------------------------------------------------------
insert into recipes (slug,title,summary,intro,image_url,meal,cuisine,method,spice_level,texture,base_servings,
  prep_minutes,cook_minutes,difficulty,equipment,tips,common_mistakes,substitutions,storage_note,serving_suggestion,
  health_notes,tags)
values ('ca-dieu-hong-hap-gung-hanh','Cá diêu hồng hấp gừng hành',
 'Cá hấp nguyên con, thịt ngọt mềm, thơm gừng hành, ít dầu mỡ.',
 'Hấp là cách nấu giữ trọn vị ngọt của cá và ít chất béo. Gừng giúp khử mùi tanh, nước tương pha nhẹ và một chút dầu nóng rưới lên hành tạo mùi thơm đặc trưng.',
 'recipe-images/ca-dieu-hong-hap-gung-hanh.webp','{lunch,dinner}','viet','hấp',0,'{soft}',2,15,15,2,
 array['Nồi hấp hoặc nồi có xửng','Đĩa sâu lòng chịu nhiệt','Dao và thớt','Chảo nhỏ để đun dầu'],
 array['Lót lát gừng dưới đáy đĩa để cá không dính và thơm hơn.','Đổ bỏ nước tiết ra trong đĩa trước khi rưới sốt để bớt tanh.','Cho cá vào khi nước đã sôi hẳn để cá chín nhanh, thịt không bở.'],
 array['Hấp quá lâu: thịt cá khô và bở. Kiểm tra bằng đũa ở chỗ dày nhất từ phút thứ 10.','Rưới quá nhiều nước tương: cá mặn và át vị ngọt tự nhiên.'],
 '[{"ingredient":"Cá diêu hồng","alternatives":["Cá lóc","Cá chép","Cá basa phi lê"],"note":"Phi lê chỉ cần hấp 6–8 phút."}]',
 'Nên ăn nóng ngay. Thừa có thể bảo quản tủ lạnh tối đa 1 ngày và hâm hấp lại 3–4 phút.',
 'Ăn với cơm trắng và canh rau.',
 'Món có cá và nước tương (dị ứng cá, đậu nành, gluten cần tránh). Cá hấp mềm, phù hợp người cao tuổi; nhớ gỡ kỹ xương khi dọn cho trẻ nhỏ và người lớn tuổi.',
 '{soft,gentle,lean_protein}');

insert into recipe_ingredients(recipe_id,ingredient_id,group_name,amount_g,display_amount,display_unit,prep_note,note,optional,scale_mode,sort_order)
select r.id,i.id,v.grp,v.g,v.da::numeric,v.du::text,v.prep::text,v.note::text,v.opt::boolean,v.sm,v.so
from recipes r join (values
 ('ca-dieu-hong','Cá',450,1,'con nhỏ','Cạo sạch vảy, bỏ ruột và mang; rạch 2–3 đường sâu 5 mm mỗi bên thân','Khối lượng đã làm sạch',false,'linear',1),
 ('tieu-den','Cá',0.3,0.25,'muỗng cà phê',null,null,false,'sublinear',2),
 ('gung','Hấp',10,3,'lát','Thái lát mỏng để lót đáy đĩa',null,false,'linear',3),
 ('gung','Hấp',15,15,'g','Thái sợi nhỏ để phủ lên cá',null,false,'linear',4),
 ('hanh-la','Hấp',25,5,'nhánh','Cắt khúc 5 cm, chẻ đôi theo chiều dọc',null,false,'sublinear',5),
 ('nuoc-tuong','Nước sốt',10,2,'muỗng cà phê',null,'Có thể dùng loại giảm muối',false,'sublinear',6),
 ('nuoc-loc','Nước sốt',20,4,'muỗng cà phê',null,'Pha loãng nước tương',false,'sublinear',7),
 ('dau-oliu','Nước sốt',10,2,'muỗng cà phê',null,'Đun nóng để rưới',false,'sublinear',8),
 ('rau-mui','Trang trí',10,2,'nhánh','Ngắt lá',null,false,'fixed',9),
 ('ot','Trang trí',5,1,'quả','Thái lát mỏng','Thêm nếu thích ăn cay',true,'sublinear',10)
) v(ing,grp,g,da,du,prep,note,opt,sm,so) on true
join ingredients i on i.slug = v.ing where r.slug = 'ca-dieu-hong-hap-gung-hanh';

insert into recipe_steps(recipe_id,step_no,phase,title,instruction,timer_seconds,heat,tip)
select r.id,v.n,v.ph,v.t,v.ins,v.tm::int,v.h,v.tip::text
from recipes r join (values
 (1,'prep','Làm sạch cá','Cạo sạch vảy, bỏ ruột và mang, rửa kỹ cả trong bụng dưới vòi nước lạnh. Dùng muối hạt chà nhẹ lên thân rồi rửa lại để bớt nhớt.',null,'none','Nhờ cửa hàng làm sạch cá sẽ nhanh hơn, nhưng vẫn nên rửa lại ở nhà.'),
 (2,'prep','Rạch thân và khử tanh','Lau khô cá. Rạch 2–3 đường sâu khoảng 5 mm mỗi bên thân để cá chín đều và thấm vị. Xoa đều 1–2 lát gừng và chút tiêu lên cá, để 5 phút.',300,'none',null),
 (3,'prep','Sơ chế gừng và hành','Thái 3 lát gừng mỏng để lót đáy đĩa, thái sợi 15 g gừng để phủ lên cá. Hành lá cắt khúc 5 cm rồi chẻ đôi theo chiều dọc.',null,'none',null),
 (4,'prep','Pha nước sốt','Trộn nước tương với 4 muỗng cà phê nước lọc trong chén nhỏ. Nếm thử: chỉ mặn nhẹ vì còn rưới lên cá.',null,'none','Pha loãng giúp phân bố đều và giảm lượng muối cho mỗi miếng cá.'),
 (5,'cook','Chuẩn bị nồi hấp','Đổ nước vào nồi sao cho cách xửng khoảng 3 cm, đun lửa lớn tới khi nước sôi mạnh và có hơi nước bốc đều.',300,'high',null),
 (6,'cook','Hấp cá','Xếp gừng lát lót đáy đĩa, đặt cá lên, phủ gừng sợi. Cho đĩa vào xửng, đậy nắp và hấp lửa lớn 10–12 phút. Cá chín khi dùng đũa chọc ở chỗ dày nhất sau gáy thấy thịt trắng đục và tách thớ dễ dàng.',660,'high','Nếu cá lớn hơn 600 g, kéo dài thêm 2–3 phút. Tránh mở nắp nhiều lần trong khi hấp.'),
 (7,'finish','Rưới sốt và dầu nóng','Lấy đĩa ra, đổ bỏ nước tiết ra trong đĩa (nước này có mùi tanh). Rải hành lá lên cá, rưới nước tương pha. Đun nóng 2 muỗng cà phê dầu ô liu trong chảo nhỏ khoảng 1 phút rồi rưới lên hành lá cho dậy mùi thơm.',60,'medium','Rưới dầu cẩn thận, tránh bắn dầu vào tay. Dầu chỉ cần nóng vừa, bốc khói nhẹ là được.'),
 (8,'finish','Trang trí và dọn ăn','Rắc rau mùi (và ớt nếu thích ăn cay) lên cá. Ăn nóng ngay với cơm, gỡ xương cẩn thận khi cho trẻ nhỏ hoặc người cao tuổi ăn.',null,'none',null)
) v(n,ph,t,ins,tm,h,tip) on true where r.slug = 'ca-dieu-hong-hap-gung-hanh';

-- ---------- 6. XUẤT BẢN (kích hoạt trigger kiểm tra đủ chi tiết) ----------
update recipes set status = 'published' where status = 'draft';

-- ---------- 7. KIỂM TRA NHANH (chạy tay) ----------
-- select slug, kcal, protein_g, sodium_mg, auto_tags, diet_tags, allergen_ids from recipes order by slug;
-- Gán admin:  update profiles set role = 'admin' where id = '<uuid người dùng>';

-- =====================================================================
-- 8. CỬA HÀNG (DỮ LIỆU MẪU — giá & quy cách mang tính minh họa, cần thay bằng dữ liệu thật)
-- =====================================================================
insert into product_categories(name, slug) values
 ('Rau củ quả','rau-cu-qua'),('Thịt - cá - hải sản','thit-ca-hai-san'),('Ngũ cốc - đậu - hạt','ngu-coc-dau-hat'),
 ('Gia vị - dầu ăn','gia-vi-dau-an'),('Sữa & chế phẩm','sua-che-pham')
on conflict (slug) do nothing;

insert into products (sku, name, slug, category_id, ingredient_id, kind, unit, pack_size_g, price_vnd, stock)
select 'IN-' || upper(v.ing), v.nm, 'sp-' || v.ing, c.id, i.id, 'ingredient', v.unit, v.pack, v.price, 100
from (values
 ('gao-lut','Gạo lứt','túi 1 kg',1000,45000),
 ('yen-mach','Yến mạch cán','túi 500 g',500,60000),
 ('chuoi','Chuối','kg',1000,30000),
 ('sua-chua-khong-duong','Sữa chua không đường','hộp 100 g',100,8000),
 ('hat-chia','Hạt chia','gói 200 g',200,95000),
 ('uc-ga','Ức gà phi lê','khay 500 g',500,55000),
 ('ca-hoi','Cá hồi phi lê','khay 300 g',300,150000),
 ('ca-dieu-hong','Cá diêu hồng làm sạch','con ~500 g',500,60000),
 ('tom','Tôm tươi','khay 250 g',250,80000),
 ('dau-hu','Đậu hũ','hộp 300 g',300,10000),
 ('bi-do','Bí đỏ','kg',1000,25000),
 ('ca-chua','Cà chua','khay 500 g',500,20000),
 ('ca-rot','Cà rốt','khay 500 g',500,15000),
 ('bong-cai-xanh','Bông cải xanh','bông ~300 g',300,25000),
 ('hanh-tay','Hành tây','túi 500 g',500,18000),
 ('hanh-la','Hành lá','bó 100 g',100,8000),
 ('rau-mui','Rau mùi','bó 50 g',50,6000),
 ('toi','Tỏi','túi 100 g',100,12000),
 ('gung','Gừng','túi 100 g',100,8000),
 ('chanh','Chanh','túi 4 quả ~200 g',200,12000),
 ('ot','Ớt','túi 100 g',100,8000),
 ('dau-oliu','Dầu ô liu','chai 250 ml',230,120000),
 ('nuoc-mam','Nước mắm','chai 500 ml',600,35000),
 ('nuoc-tuong','Nước tương','chai 500 ml',550,30000),
 ('muoi','Muối','gói 500 g',500,8000),
 ('tieu-den','Tiêu đen','hũ 50 g',50,30000),
 ('duong','Đường','túi 1 kg',1000,25000)
) v(ing, nm, unit, pack, price)
join ingredients i on i.slug = v.ing
join product_categories c on c.slug = case i.category
   when 'rau_cu' then 'rau-cu-qua' when 'trai_cay' then 'rau-cu-qua'
   when 'thit' then 'thit-ca-hai-san' when 'ca' then 'thit-ca-hai-san' when 'hai_san' then 'thit-ca-hai-san'
   when 'ngu_coc' then 'ngu-coc-dau-hat' when 'dau' then 'ngu-coc-dau-hat' when 'hat' then 'ngu-coc-dau-hat'
   when 'sua' then 'sua-che-pham' else 'gia-vi-dau-an' end
on conflict (sku) do nothing;

insert into shipping_rules(province, fee_vnd, free_from_vnd) values
 ('*', 30000, 300000), ('Hồ Chí Minh', 20000, 250000), ('Hà Nội', 20000, 250000);

insert into coupons(code, discount_pct, max_discount_vnd, min_order_vnd, max_uses, ends_at)
values ('WELCOME10', 10, 50000, 100000, 1000, now() + interval '90 days')
on conflict (code) do nothing;

