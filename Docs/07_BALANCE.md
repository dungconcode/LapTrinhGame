# Cân bằng game (R03)

> Số liệu hiện tại được chọn bằng **mô hình** `Tools/balance_model.py`, chưa phải playtest.
> Playtest xong → sửa số trong `PROPOSED` của script → `python Tools/balance_model.py --apply` (hoặc sửa thẳng asset trong Unity).

## Vấn đề của số cũ
- Cả **10 wave giống hệt nhau** (5 quái cận chiến), **không có boss**, không khó dần.
- Mỗi wave tổng máu quái 200 ⇒ bắn ~3 giây là xong, base không mất máu.
- Sắt dư: đến wave 5 đã mua gần hết nâng cấp, cuối game dư ~190 sắt ⇒ không phải lựa chọn gì.

## Mục tiêu
| Tiêu chí | Mục tiêu |
|---|---|
| Thời gian 1 run | 15–20 phút |
| Độ khó | Wave 1–5 an toàn để học; từ wave 6 base bắt đầu mất máu; wave 9 mất ~⅓; **boss wave khó nhưng thắng được** |
| Kinh tế | Không mua hết được ⇒ phải chọn (đào nhanh hơn hay pháo mạnh hơn) |
| Quặng hiếm | S từ độ sâu 10, Mg từ 30, KCl từ 50 ⇒ đạn đặc biệt là phần thưởng cho việc đào sâu |

## Số mới

**Thời gian đào mỗi wave (giây):** 60 · 65 · 70 · 70 · 75 · 75 · 80 · 80 · 85 · 90

**Wave** (cận chiến / bay / bắn xa / boss · hệ số máu · hệ số tốc độ · giây giữa 2 con):

| Wave | Quái | Máu × | Tốc độ × | Spawn (s) |
|---|---|---|---|---|
| 1 | 4 / 0 / 0 | 1.00 | 1.00 | 2.0 |
| 2 | 6 / 0 / 0 | 1.10 | 1.00 | 1.8 |
| 3 | 6 / 2 / 0 | 1.20 | 1.05 | 1.6 |
| 4 | 7 / 3 / 1 | 1.35 | 1.05 | 1.5 |
| 5 | 8 / 3 / 2 | 1.50 | 1.10 | 1.4 |
| 6 | 9 / 4 / 3 | 1.70 | 1.10 | 1.3 |
| 7 | 10 / 5 / 3 | 1.90 | 1.15 | 1.2 |
| 8 | 12 / 6 / 4 | 2.10 | 1.15 | 1.1 |
| 9 | 14 / 7 / 5 | 2.40 | 1.20 | 1.0 |
| 10 | 6 / 4 / 3 + **BOSS** | 1.70 | 1.20 | 1.4 |

**Giá nâng cấp (sắt):**

| Nâng cấp | Cũ | Mới |
|---|---|---|
| Khoan | 5·10·20·35 | **8·16·30·50** |
| Tốc độ | 5·10·20·35 | **6·12·22·36** |
| Sức mang | 5·10·20·35 | **8·16·30·50** |
| Jetpack | 5·10·20·35 | **6·12·22·36** |
| Thang máy | 20 | **30** |
| Sát thương pháo | 5·10·20·35·50 | **8·16·28·45·65** |
| Xoay pháo | 5·10·20·35·50 | **6·12·22·35·50** |
| Máu base | 5·10·20·35·50 | **10·20·35·55·80** |
| Bom (mỗi quả) | 5 | **6** |
| Sửa base (+100) | 5 | **8** |

## Kết quả mô hình

| | Số cũ | Số mới |
|---|---|---|
| Thời gian run | ~17.5 phút | ~16.7 phút |
| Base mất máu wave 6 / 9 / 10 | 0 / 0 / 0 | ~18 / ~280 / **~585 trên 800** |
| Sắt dư cuối game | ~190 | ~12 |
| Mua hết nâng cấp vào | wave 5 | không bao giờ (phải chọn) |

Mô hình **chưa tính** đạn đặc biệt (axit/lửa/băng), sửa base, và boss gọi thêm quái ⇒ thực tế boss wave có thể dễ hoặc khó hơn chút.

## Cần kiểm chứng khi playtest
1. Wave 1–3 có quá nhàm không? (nếu nhàm: rút đào wave 1–2 xuống 45–50s)
2. Sắt có đủ để thấy tiến bộ mỗi wave không? (nếu thiếu: tăng `veinChance` của Fe trong `TerrainConfig` 0.03 → 0.035)
3. Boss: thắng được khi đã nâng sát thương pháo ≥ cấp 3 + có đạn lửa? Nếu thua quá dễ: giảm `healthScale` wave 10 xuống 1.5
4. Pha đào cuối (85–90s) có đủ để xuống tầng KCl (≥ 50) và về không?
