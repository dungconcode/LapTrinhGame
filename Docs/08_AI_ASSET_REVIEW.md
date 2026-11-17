# Duyệt ảnh AI — đợt 1 (18/11)

Nguồn: `04_AI_Candidates` (76 ID, bản `chon.png`). Đã xử lý bằng `Tools/import_ai_batch.py` và đưa vào game.

## Kết quả

| | Số lượng |
|---|---|
| Đã vào game (status `ai`) | **75 / 76** |
| Dùng tạm hình khác | 1 (`char_player_carry` → tạm dùng `char_player_walk`) |
| Cần gen lại | **6** (bảng dưới) — trong lúc chờ, 5 cái đã được sửa tạm để dùng được |

Nhận xét chung: style rất đồng bộ; nhân vật/quái giữ đúng thiết kế giữa các animation; hướng nhìn đúng; nền trong suốt sạch ở hầu hết ảnh. Tile ghép 3×3 không lộ đường nối rõ.

## Cần gen lại (cho người gen ảnh)

| ID | Lỗi | Yêu cầu khi gen lại | Đang dùng tạm |
|---|---|---|---|
| `char_player_carry` | Quầng **trắng gần như đặc** bao quanh nhân vật ở cả 6 frame — không xoá được mà không hỏng hình | Nền **trong suốt hoàn toàn**, không glow/aura. Đính kèm `char_player_walk/chon.png`. Dáng khom lưng, đi chậm, có bao/khối quặng nặng | Animation đi bộ |
| `tile_ore_mg` | Vẽ trên nền **đất nâu tầng 1**; Mg nằm ở tầng 2 (đá xám tím) ⇒ lạc màu | Đính kèm **`tile_dirt_2/chon.png`** làm nền, giữ nguyên 4 cạnh | Bản hiện tại |
| `tile_ore_kcl` | Vẽ trên nền đất nâu; KCl nằm ở tầng 3 (đá tím đậm) | Đính kèm **`tile_dirt_3/chon.png`** làm nền | Bản hiện tại |
| `bg_surface_far` | Có **lát cắt hang ngầm** dưới đường chân trời ⇒ hiện lơ lửng trên trời | Chỉ dãy núi/vách đá, **mép dưới ảnh = mặt đất**, phía trên trong suốt, lặp ngang được | Đã cắt bỏ phần dưới 74% |
| `bg_surface_mid` | Như trên | Đồi + cây ngoài hành tinh, mép dưới = mặt đất, trên trong suốt | Đã cắt bỏ phần dưới 68% |
| `bg_underground_mid` | **Kín 100%** ⇒ che mất lớp `bg_underground_far` phía sau, mất parallax | Chỉ vẽ **lớp gần** (thạch nhũ, nấm phát sáng, rễ) với **khoảng trống trong suốt** giữa chúng; lặp dọc | Giảm độ đậm còn 55% |

## Ghi chú khác (không cần gen lại)

- `proj_enemy` vẽ **chĩa trái** — code xoay đạn theo hướng bay nên mọi viên đạn phải chĩa **phải**. Đã lật ngang khi xử lý. Lần sau gen đạn: luôn chĩa phải.
- `enemy_ranged_attack`, `boss_death`, `char_player_carry`, nhóm `fx_*`: tách frame theo lưới (hạt rời/cục axit nối các ô) — đã xử lý được, không cần sửa.
- Các animation **bị thương / chết / hiệu ứng trúng đạn / tia lửa khoan / teleport** đã có hình nhưng **code chưa gọi tới** (quái chết đang hiện vụ nổ chung). Việc nối vào gameplay là phần code.

## Cách nộp bản gen lại
Bỏ vào đúng thư mục `04_AI_Candidates/<id>/`, đặt tên **`chon.png`** (giữ bản cũ thành `candidate_old.png`). Sau đó chạy:

```bash
python Tools/import_ai_batch.py <đường_dẫn>/04_AI_Candidates --ids <id1> <id2>
```

Với `bg_surface_far/mid` bản mới thì xoá dòng `crop_bottom` tương ứng trong `OVERRIDES` của `Tools/import_ai_batch.py`.
