# Kế hoạch A/B Testing: Rewarded Ads tại level khó

Trạng thái: Đề xuất thử nghiệm, chưa triển khai thực tế.

## 1. Cơ sở đề xuất

Trong dataset công khai, level 27 và 29 có tỷ lệ hoàn thành quan sát lần lượt là 36,39% và 46,35%, đồng thời ghi nhận nhiều sự kiện thất bại và thử lại.

Đây là cơ sở để đặt giả thuyết, chưa chứng minh độ khó hoặc quảng cáo là nguyên nhân khiến người chơi rời game.

## 2. Giả thuyết

Cung cấp lựa chọn xem quảng cáo thưởng để nhận thêm bước sau thất bại tại level 27 hoặc 29 có thể tăng doanh thu quảng cáo mà không làm giảm đáng kể tỷ lệ hoàn thành và khả năng quay lại chơi.

## 3. Đối tượng và phân nhóm

- Người dùng gặp thất bại tại level 27 hoặc 29, đủ điều kiện nhận quảng cáo theo cấu hình sản phẩm.
- Phân nhóm ngẫu nhiên 50/50 tại lần đầu đủ điều kiện.
- Mỗi người giữ nguyên nhóm trong suốt thử nghiệm.
- Loại tài khoản nội bộ và thiết bị kiểm thử theo quy tắc xác định trước khi chạy.

Nhóm A — Đối chứng:
- Giữ nguyên trải nghiệm hiện tại.

Nhóm B — Thử nghiệm:
- Thêm lựa chọn tự nguyện xem Rewarded Ad sau thất bại tại level 27 hoặc 29 để nhận 2 bước và tiếp tục lượt chơi.
- Tối đa một lần nhận ưu đãi trong mỗi lượt chơi đủ điều kiện.
- Không thay đổi tần suất Interstitial, độ khó hoặc ưu đãi khác.
- Không có quảng cáo khả dụng thì giữ luồng thất bại bình thường.

Trước triển khai phải xác minh trải nghiệm và vị trí quảng cáo hiện tại, tránh thêm trùng ưu đãi đã tồn tại.

## 4. Chỉ số đánh giá

Chỉ số chính:
- Ad ARPDAU trong D0–D7 sau phân nhóm:tổng doanh thu quảng cáo / tổng ngày-người dùng hoạt động.
- Định nghĩa hoạt động và cách ghi nhận doanh thu phải thống nhất giữa hai nhóm.

Chỉ số bảo vệ trải nghiệm:
- D1 và D7 quay lại chơi, tính từ ngày phân nhóm.
- Tỷ lệ hoàn thành lượt chơi đủ điều kiện: lượt hoàn thành / lượt bắt đầu đủ điều kiện.

Chỉ số chẩn đoán:
- Rewarded Ad opt-in rate: số lần chọn xem / số lần hiển thị đề nghị.
- Lượt hiển thị quảng cáo trên người dùng hoạt động.
- Tỷ lệ lỗi quảng cáo.
- Tổng doanh thu quảng cáo D0–D7 trên mỗi người được phân nhóm.

Phân tích theo nhóm được phân ban đầu, không chỉ so sánh người đã xem quảng cáo với người không xem.

## 5. Dữ liệu cần ghi nhận

- Mã người dùng, nhóm thử nghiệm và thời điểm phân nhóm.
- Level, mã lượt chơi và kết quả hoàn thành/thất bại.
- Lần hiển thị đề nghị, chọn xem, quảng cáo hiển thị, nhận thưởng và lỗi quảng cáo.
- Doanh thu quảng cáo, đơn vị tiền tệ và định dạng quảng cáo.

Dataset công khai hiện tại chưa đủ để thực hiện phép thử này.

## 6. Cỡ mẫu và thời gian

- Dùng dữ liệu vận hành trước thử nghiệm để ước lượng mức nền và biến động của chỉ số chính.
- Xác định mức cải thiện tối thiểu cần phát hiện (MDE), mức ý nghĩa 5% và power 80% trước khi tính cỡ mẫu.
- Tính thêm nhu cầu mẫu cho các chỉ số bảo vệ trải nghiệm.
- Phân tích thống kê phải xử lý các quan sát lặp theo người dùng.

Kế hoạch lịch ban đầu:
- Tuyển mẫu tối thiểu 14 ngày để bao phủ hai chu kỳ tuần.
- Theo dõi đủ D0–D7 cho người cuối cùng được phân nhóm.
- Nếu chưa đủ cỡ mẫu, thời gian cần dài hơn theo kế hoạch xác định trước; không kết luận chỉ vì đã đủ 14 ngày.
- Không dừng sớm chỉ vì một lần xem kết quả có ý nghĩa thống kê.

## 7. Tiêu chí kết luận

Trước khi chạy, thống nhất:
- Mức tăng ARPDAU tối thiểu có ý nghĩa kinh doanh.
- Biên giảm tối đa chấp nhận được của retention và tỷ lệ hoàn thành.

Đề xuất mở rộng thử nghiệm khi:
- ARPDAU tăng với bằng chứng thống kê và mức cải thiện đáp ứng tiêu chí kinh doanh.
- Khoảng tin cậy của các chỉ số bảo vệ loại trừ mức giảm vượt quá biên chấp nhận.
- Không có lỗi tracking hoặc mất cân bằng phân nhóm nghiêm trọng.

Nếu chưa đủ bằng chứng, kết luận chưa xác định. Không coi việc “không có khác biệt có ý nghĩa thống kê” là bằng chứng trải nghiệm không bị ảnh hưởng.