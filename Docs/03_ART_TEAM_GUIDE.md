# Hướng dẫn cho nhóm Art — UNDERLAB

Gửi file này cho nhóm art. Không cần biết Unity hay git.

## 1. Cách làm việc chung

- Dev đang dùng **ảnh AI tạm** để code. Nhóm art vẽ bản **final** để thay dần.
- Danh sách asset + trạng thái: file `asset_manifest.csv` (dev sẽ share dạng Google Sheet).
  - `status = ai-approved` → bản AI đã đủ đẹp, **không cần vẽ** (trừ khi có thời gian dư).
  - Làm theo thứ tự **P0 → P1 → P2**.
  - Bắt đầu vẽ 1 asset → báo trong Discord / sửa status thành `art-wip` để không trùng.
- Muốn nhanh: **vẽ đè lên ảnh AI** trong `04_AI_Candidates/<id>/` (giữ dáng/bố cục, vẽ lại nét + màu theo style). Được khuyến khích.
- Họp duyệt art: **Thứ 4 + Chủ nhật** (ART-SYNC).
- **Art freeze: Thứ 4 9/12.** Bản nào gửi sau ngày này có thể không kịp vào game.

## 2. Thư mục Google Drive

```
Underlab_Art/
├─ 00_StyleGuide/        style_key.png, palette.png, ví dụ đúng/sai
├─ 01_WIP/<id>/          bản đang vẽ (tuỳ ý)
├─ 02_Final/<category>/  ★ BẢN GIAO: <id>.png đúng chuẩn mục 4
├─ 03_Source/<id>.psd    file gốc nhiều layer (giữ lại để sửa)
└─ 04_AI_Candidates/<id>/ ảnh AI dev gen ra để tham khảo / vẽ đè
```

Dev chỉ lấy file trong **02_Final**. Gửi xong nhắn 1 dòng: `xong enemy_melee_walk`.

## 3. Thông số chung

| Mục | Quy định |
|---|---|
| Style | Vẽ tay 2D, nét viền tối, tô cel-shading mềm, theo `style_key.png` |
| Đơn vị | **1 ô đất = 128×128 px** |
| Định dạng | **PNG nền trong suốt**, RGBA |
| Tên file | **đúng y `id`** trong bảng, chữ thường, vd `enemy_melee_walk.png` |
| Hướng | Nhân vật, đạn, nòng pháo nhìn **PHẢI** · Quái, boss nhìn **TRÁI** |
| Ánh sáng | Từ trên-trái |
| Bóng đổ | Không vẽ bóng xuống đất |
| Vẽ to hơn? | Được vẽ gấp 2 rồi export đúng `spec_px` (hoặc giữ gấp 2, miễn đúng tỉ lệ) |

## 4. Animation — QUAN TRỌNG

- Xuất thành **1 dải ngang**, các frame **bằng nhau**, sát nhau, không khoảng cách:
  `[frame0][frame1][frame2][frame3]` → file 4 frame × 256px = **1024×256**.
- Số frame **đúng như cột `frames`**. Muốn đổi số frame → báo dev sửa bảng.
- Nhân vật **đứng cùng 1 vị trí trong mọi frame**: chân chạm cùng 1 đường đáy (pivot `bc`), không trôi ngang.
- Nhân vật cao khoảng 75–85% chiều cao frame, chừa lề.

## 5. Bảng kích thước nhanh

| Loại | Kích thước 1 frame | Pivot | Ghi chú |
|---|---|---|---|
| Nhân vật `char_*` | 256×256 | chân giữa | cao ~0.85 ô — **phải chui lọt đường hầm 1 ô**; vẽ người chiếm ~70% chiều cao frame |
| Quái `enemy_*` | 256×256 | chân giữa (quái bay: tâm) | |
| Boss `boss_*` | 768×768 | chân giữa | |
| Tile `tile_*` | 128×128 | tâm | **seamless 4 phía**, phủ kín ô |
| Quặng rơi `item_*` | 64×64 | tâm | |
| Base `bld_base_*` | 512×512 | chân giữa | chừa chỗ gắn pháo trên đỉnh |
| Nòng pháo `bld_turret_barrel` | 256×128 | đuôi nòng (15% từ trái) | nằm ngang chĩa phải |
| Đạn `proj_*` | 64×64 | tâm | bay sang phải |
| Hiệu ứng `fx_*` | xem bảng | tâm | có thể để dev làm bằng particle |
| Background `bg_*` | 1920×1080 | — | lớp xa/giữa tách riêng; lòng đất lặp **dọc**, mặt đất lặp **ngang** |
| UI `ui_*` | xem bảng | — | panel/nút để vẽ kiểu **9-slice** (4 góc trang trí, cạnh giữa kéo giãn được) |
| Icon `icon_*` | 128×128 | — | rõ ở kích thước nhỏ, silhouette đậm |

## 6. Lịch art đề xuất (thay timeline cũ 12/10–20/11)

| Đợt | Hạn | Nội dung (ưu tiên những gì chưa `ai-approved`) |
|---|---|---|
| 1 | 18/11 | Style key + palette (cùng dev chốt) |
| 2 | 24/11 | Nhân vật P0, tile + quặng, base + pháo |
| 3 | 1/12 | 3 loại quái (walk/attack), đạn, icon quặng/đạn |
| 4 | 6/12 | Boss, UI HUD + menu, background |
| 5 | 9/12 | **Art freeze**: hurt/death, fx, màn thắng/thua, sửa theo playtest |

## 7. Checklist trước khi gửi
- [ ] Tên file đúng id · PNG trong suốt
- [ ] Đúng số frame, dải ngang, frame bằng nhau
- [ ] Đúng hướng nhìn · chân chạm đáy cố định
- [ ] Tile ghép thử 3×3 không thấy đường nối
- [ ] Giữ PSD trong `03_Source`
