# Analysis Decision Log
### Đã hoàn thành
- Tạo Google Cloud Project: flood-it-analysis.
- Thêm firebase-public-project vào danh sách yêu thích.
- Truy cập dataset: analytics_153293282.
- Chạy thành công truy vấn kiểm tra và nhận được 10 dòng dữ liệu.
- Tạo thư mục dự án và lưu truy vấn vào sql/01_explore.sql.

### Quan sát ban đầu
- Kết quả truy vấn có sự kiện first_open.
- Có các trường event_date, event_name và user_pseudo_id.

### Quyết định
- Chạy SQL trên BigQuery.
- Lưu code SQL và ghi chú trong VS Code.
- Phân biệt dữ liệu hành vi thực tế với doanh thu quảng cáo mô phỏng.

### Câu hỏi cần khám phá
- Dữ liệu bao gồm khoảng thời gian nào?
- Có bao nhiêu người chơi và sự kiện?
- Có những loại sự kiện nào?
- Có sự kiện quảng cáo và thông tin level không?

## Khám phá dữ liệu – Quy mô tháng 9/2018
- Phạm vi: 01/09/2018–30/09/2018.
- Tổng số sự kiện: 1.500.000.
- Số user_pseudo_id khác nhau: 6.065.
- Số ngày có dữ liệu: 30.
- Các kết quả chỉ mô tả bộ dữ liệu công khai trong phạm vi đã chọn.

## Khám phá danh sách sự kiện – Tháng 9/2018
- Có các sự kiện gameplay mang hậu tố _quickplay và không có hậu tố.
- Cần kiểm tra tham số trước khi xác định cấu trúc level và funnel.
- ad_reward: 391 sự kiện từ 102 mã người dùng.
- in_app_purchase: 10 sự kiện từ 10 mã người dùng.
- Chưa xác định được dữ liệu doanh thu quảng cáo thực tế.
- first_open: 1.351 sự kiện từ 1.349 mã người dùng.

## Kiểm tra giá trị và kiểu dữ liệu tham số
- level_start lưu level ở cả int_value và double_value.
- Khi phân tích cần chuẩn hóa hai kiểu về số nguyên.
- Các giá trị level quan sát trong truy vấn nằm trong khoảng 1–30.
- Quickplay có ba mã board: S, M, L.
- ad_reward có type chủ yếu là Steps; value gồm 1, 2, 5.
- Không sử dụng ad_reward.value làm doanh thu quảng cáo.
- Chưa kết luận tỷ lệ bỏ game từ số sự kiện bắt đầu và hoàn thành.

## Phạm vi bảng dữ liệu
- Bảng đầu tiên: events_20180612.
- Bảng cuối cùng: events_20181003.
- Có 114 bảng ngày, không thiếu ngày trong khoảng này.
- Đang kiểm tra phạm vi ngày có sự kiện và quy mô toàn bộ dữ liệu.

## Quy mô toàn bộ dữ liệu
- Thời gian: 12/06/2018–03/10/2018.
- Có sự kiện trong đủ 114 ngày.
- Tổng số sự kiện: 5.700.000.
- Số user_pseudo_id khác nhau: 15.175.
- Các kết quả khám phá sự kiện và tham số trước đó mới xét tháng 9/2018.

## Kiểm tra dữ liệu theo ngày
- Cả 114 ngày đều có chính xác 50.000 sự kiện/ngày.
- Số mã người dùng khác nhau theo từng ngày.
- Có dấu hiệu dữ liệu đã được lấy mẫu hoặc giới hạn số dòng,
  nhưng chưa xác minh được cơ chế.
- DAU và retention sẽ được diễn giải trong phạm vi dataset.
- Không dùng số sự kiện cố định mỗi ngày để kết luận mức độ hoạt động thực tế của game ổn định.

## Phân bố số sự kiện theo người dùng
- Phạm vi: 12/06/2018–03/10/2018.
- Số mã người dùng: 15.175.
- Số sự kiện trung bình: 375,62.
- Trung vị ước lượng: 52.
- Số sự kiện lớn nhất: 102.503.
- Trung bình cao hơn trung vị khoảng 7,2 lần.
- Cần kiểm tra nhóm có nhiều sự kiện trước khi diễn giải mức độ gắn bó hoặc xác định bất thường.

## Kiểm tra hành trình một người dùng
- Xem 100 sự kiện đầu tiên của mã:
  959635567E419A061EECCCA478EDC718.
- Gameplay trong đoạn quan sát thuộc Quickplay, board S.
- Có cả sự kiện thất bại và hoàn thành.
- Thứ tự start, end, fail không tạo thành chuỗi cố định.
- Chưa ghép sự kiện thành từng lượt chơi khi chưa có quy tắc kiểm chứng.
- post_score có level = 0; cần lọc theo loại sự kiện khi phân tích level.
- event_date có thể khác ngày UTC của event_timestamp.
- Dùng nhất quán event_date khi tính chỉ số theo ngày.

## DAU và người dùng mới
- DAU được tính bằng số user_pseudo_id khác nhau theo event_date.
- new_users được tính bằng số mã có first_open trong ngày.
- Một số ngày DAU cao có rất ít hoặc không có first_open.
- Chưa xác định nguyên nhân; cần kiểm tra cơ cấu sự kiện.
- Không mặc định người không có first_open là người dùng quay lại.

## Kiểm tra mức tăng người dùng ngày 18/06
- Ngày 17/06: 443 mã có sự kiện, 2 mã chỉ có screen_view, 394 mã có sự kiện bắt đầu chơi.
- Ngày 18/06: 1.283 mã có sự kiện, 537 mã chỉ có screen_view, 495 mã có sự kiện bắt đầu chơi.
- Chưa xác định nguyên nhân khác biệt.
- Tách chỉ số người dùng có bất kỳ sự kiện nào và người dùng có sự kiện bắt đầu chơi.
- Các chỉ số chỉ phản ánh dữ liệu quan sát trong dataset.

## Retention quay lại chơi D1/D7
- Cohort: ngày first_open đầu tiên quan sát được của mỗi mã.
- Quay lại chơi: có level_start hoặc level_start_quickplay.
- D1: 743 / 4.251 = 17,48%.
- D7: 191 / 3.998 = 4,78%.
- Chỉ tính cohort đủ thời gian theo dõi.
- Tỷ lệ tổng hợp = tổng người quay lại / tổng người đủ điều kiện.
- Kết quả chịu giới hạn về độ đầy đủ của dataset công khai.

## Hoàn thành theo level
- Tính theo người dùng, không phải theo lượt chơi.
- Level 27 có tỷ lệ hoàn thành quan sát thấp nhất: 36,39%.
- Level 29 có tỷ lệ 46,35%; level 1 có tỷ lệ 51,70%.
- Cần kiểm tra thêm sự kiện thất bại và chơi lại tại các level này.
- Chưa kết luận độ khó là nguyên nhân hoặc người chưa hoàn thành đã bỏ game.
- Bảng theo level không phải funnel tuần tự của cùng một cohort.

## Kiểm tra sâu level 27 và 29
- Level 27: tỷ lệ hoàn thành quan sát 36,39%; 3.795 sự kiện thất bại, 3.966 sự kiện thử lại; trung bình 9,07 sự kiện bắt đầu/người bắt đầu.
- Level 29: tỷ lệ hoàn thành quan sát 46,35%; 1.759 sự kiện thất bại, 1.812 sự kiện thử lại; trung bình 7,32 sự kiện bắt đầu/người bắt đầu.
- Giả thuyết: hai level này có thể gây khó khăn cho người chơi.
- Chưa xác định quan hệ nhân quả với việc rời game.
- Ý tưởng thử nghiệm: hỗ trợ thêm bước bằng quảng cáo thưởng tại điểm thất bại; cần kiểm tra vị trí quảng cáo hiện tại.
- Theo dõi khi thử nghiệm: tỷ lệ hoàn thành, quay lại chơi, mức sử dụng quảng cáo thưởng và doanh thu.

## Phiên chơi ước lượng
- Phạm vi: 12/06/2018–03/10/2018.
- Tạo phiên mới khi hai timestamp liên tiếp cách nhau hơn 30 phút.
- Loại app_remove, app_update, os_update và timestamp NULL.
- Tổng phiên: 88.495; số mã người dùng: 14.525.
- Trung bình 6,09 phiên/người trong toàn bộ khoảng quan sát.
- Độ dài phiên trung bình: 10,59 phút; trung vị: 4,24 phút.
- Có 6.306 phiên dài 0 phút, tương đương khoảng 7,13%.
- Độ dài phiên không đồng nghĩa thời gian tương tác liên tục.
- Các phiên được ước lượng từ sự kiện, không yêu cầu có gameplay.

## Phân nhóm theo số ngày chơi trong D0–D6
- Đối tượng: 4.024 mã có first_open đầu tiên quan sát được không muộn hơn 27/09/2018.
- 0 ngày chơi: 452 mã, chiếm 11,23%.
- 1 ngày chơi: 2.430 mã, chiếm 60,39%.
- 2–3 ngày chơi: 858 mã, chiếm 21,32%.
- 4–7 ngày chơi: 284 mã, chiếm 7,06%.
- Ngày chơi yêu cầu có level_start hoặc level_start_quickplay.
- Không gọi nhóm 0–1 ngày là đã bỏ game.

## Quảng cáo thưởng theo nhóm ngày chơi
- Phạm vi: D0–D6 của 4.024 mã thuộc cohort đủ điều kiện.
- Có 112 mã ghi nhận ad_reward, chiếm 2,78%.
- Tổng số sự kiện ad_reward: 378.
- Tỷ lệ mã có ad_reward:
  + Nhóm 1 ngày: 1,36%.
  + Nhóm 2–3 ngày: 6,06%.
  + Nhóm 4–7 ngày: 9,51%.
- Đây là mối liên hệ, chưa chứng minh quan hệ nhân quả.
- Không diễn giải tỷ lệ này thành tỷ lệ đồng ý xem quảng cáo.
- Không dùng số sự kiện thưởng thay cho lượt hiển thị.

## Đầu vào hoạt động cho mô hình quảng cáo
- Phạm vi: 114 ngày, từ 12/06/2018 đến 03/10/2018.
- Tổng phiên ước lượng: 88.495.
- Tổng người dùng hoạt động cộng theo ngày: 57.609.
- Người dùng hoạt động trung bình/ngày: 505,3421053.
- Phiên trung bình/ngày: 776,2719298.
- Phiên/người dùng hoạt động/ngày: 1,536131507.
- Dùng cùng bộ lọc sự kiện cho người dùng hoạt động và phiên.
- Đây là đầu vào từ dataset, không phải quy mô thực tế toàn game.