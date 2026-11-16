# Hệ thống Asset "3 tầng" — code trước, art thay sau

## Ý tưởng trong 1 câu
Mỗi asset có **1 ID cố định** (vd `enemy_melee_walk`). Code chỉ biết ID. File PNG mang tên ID có thể được **chép đè** bao nhiêu lần tuỳ thích: placeholder → bản AI → bản vẽ tay final. Game tự nhận, không phải sửa prefab hay code.

```
  Tầng 0: PLACEHOLDER  ──►  Tầng 1: AI  ──►  Tầng 2: FINAL (nhóm art)
  (tool tự sinh,           (ChatGPT/Gemini/      (vẽ tay, ưu tiên các
   khối màu đúng size)      Claude, dev tự gen)   asset chưa ai-approved)
                                │
                                └── đẹp sẵn? → đánh "ai-approved" = coi như FINAL,
                                    nhóm art KHÔNG cần vẽ lại
```

## Các file

| File | Vai trò |
|---|---|
| `Assets/_Game/Art/asset_manifest.csv` | **Nguồn sự thật**: danh sách ~110 asset, kích thước, số frame, pivot, độ ưu tiên, trạng thái |
| `Assets/_Game/Art/<category>/<id>.png` | File art thật đang dùng (tên file = id) |
| `Assets/_Game/Resources/ArtDatabase.asset` | Tự sinh: id → các frame sprite. **Không sửa tay** |
| `Assets/_Game/Art/_GeneratedTiles/<id>.asset` | Tự sinh: Tile để vẽ Tilemap (cho `type = tile`) |
| `Assets/_Game/Scripts/Art/ArtSprite.cs` | Component hiển thị/animate theo id |
| `Assets/_Game/Editor/ArtTools/*` | Tool: tự import, tự cắt frame, build database, sinh placeholder |
| `Tools/ai_sheet.py` | Biến ảnh AI thành PNG đúng chuẩn (xoá nền, cắt grid, căn pivot) |

## Cột trong manifest

| Cột | Ý nghĩa |
|---|---|
| `id` | Tên duy nhất = tên file PNG. Đặt xong **không đổi** |
| `category` | Thư mục: char, tile, item, bld, proj, enemy, boss, fx, bg, ui, icon |
| `type` | `sprite` (tĩnh), `anim` (nhiều frame), `tile` (tạo Tile asset), `ui` (dùng cho UI Image) |
| `frames` | Số frame. Ảnh phải là **dải ngang** N frame bằng nhau |
| `fps` | Tốc độ anim (0 = code tự chọn frame, vd `tile_crack`) |
| `world_w` | Độ rộng 1 frame **trong game** tính bằng ô (1 ô = 1 unit). Tool tự tính PPU = px / world_w ⇒ **ảnh to hay nhỏ đều hiện đúng kích thước** |
| `pivot` | `bc` chân giữa · `c` tâm · `tc` · `lc` · `rc` · `bl` · hoặc `x;y` (vd `0.15;0.5` = điểm xoay nòng pháo) |
| `spec_px` | Kích thước 1 frame **khuyến nghị** khi vẽ/gen (chuẩn 128 px = 1 ô) |
| `priority` | P0 cần cho M1–M2 · P1 cho M3 · P2 có thì tốt |
| `status` | `placeholder` → `ai` → `ai-approved` / `art-wip` → `final` |
| `ai_tool` | Gợi ý tool: GPT (ChatGPT) · GEM (Gemini) · CLA (Claude SVG) |
| `notes` | Mô tả ngắn (không dùng dấu phẩy, ghi không dấu để Excel/Sheets khỏi lỗi font) |
| `border` | (tuỳ chọn) viền 9-slice theo px của spec: `trái;dưới;phải;trên`, vd `48;48;48;48`. Dùng cho panel/nút/thanh co giãn |

> Sửa `frames / world_w / pivot / type` trong CSV → tool tự reimport đúng các PNG đó. Thêm asset mới = thêm 1 dòng + chạy *Generate Missing Placeholders*.

## Menu trong Unity

- **Underlab ▸ Art ▸ Generate Missing Placeholders** — tạo PNG khối màu cho mọi id chưa có file (không ghi đè). Khối có: màu theo loại, vạch số frame, chấm hồng = pivot, tam giác = hướng nhìn.
- **Underlab ▸ Art ▸ Rebuild Art Database + Report** — build lại + in báo cáo: bao nhiêu asset ở trạng thái nào, P0 đã chốt bao nhiêu, id nào thiếu file.

(Database cũng tự build mỗi khi có PNG trong `Assets/_Game/Art` thay đổi.)

## Code dùng thế nào

```csharp
using Underlab.Art;

// Trên prefab: SpriteRenderer (hoặc UI Image) + ArtSprite, gõ Art Id trong Inspector.
[SerializeField] ArtSprite art;

art.Play("enemy_melee_walk");                    // loop
art.Play("enemy_melee_death", loop: false);      // 1 lần
art.OnFinished += id => { if (id == "enemy_melee_death") Despawn(); };
art.SetFrame(crackLevel);                        // chọn frame tay (tile_crack)
art.SetFlipX(dir < 0);

Sprite icon = ArtDatabase.GetSprite("icon_ore_iron"); // lấy sprite lẻ (UI động)
```

Tilemap: kéo Tile trong `Assets/_Game/Art/_GeneratedTiles/` vào Tile Palette, hoặc load bằng code từ đó. Tile tự cập nhật khi PNG đổi.

**Cấm**: kéo PNG trực tiếp vào SpriteRenderer/Animator cho asset có trong manifest; tạo Animator Controller chỉ để đổi frame. (Animator vẫn dùng được cho logic state, nhưng frame lấy qua `ArtSprite.Play`.)

## Quy trình thay 1 asset (dev làm, ~1 phút)

1. Có file mới (AI hoặc nhóm art gửi qua Drive).
2. Nếu là ảnh AI thô: `python Tools/ai_sheet.py anh.png --id <id> [--grid 3x2]` → ra `<id>.png` chuẩn.
3. Chép đè vào `Assets/_Game/Art/<category>/<id>.png`.
4. Mở Unity, nhìn thử trong scene. Sửa cột `status` trong CSV (`ai`, `ai-approved`, `final`).
5. Commit: `art(<id>): ai v1` hoặc `art(<id>): final`.

Lưu **mọi bản thô / các phương án** trên Drive (`04_AI_Candidates/<id>/`), **repo chỉ giữ bản đang dùng**.

## Quy tắc chất lượng (để AI và tay trông cùng 1 game)

- Tất cả theo `00_StyleGuide/style_key.png` + bảng màu (chốt ở task C05).
- Hướng mặc định: nhân vật / đạn / nòng pháo nhìn **PHẢI**; quái & boss nhìn **TRÁI** (đi về base). Code tự lật.
- Ánh sáng từ **trên-trái**. Viền nét tối đậm. Không đổ bóng xuống đất (game tự thêm).
- Nền **trong suốt** (hoặc magenta #FF00FF để tool xoá).
- Tile: **seamless** (ghép liền 4 phía), không viền.
- Animation: ít frame (4–6) vẽ tay là đủ; độ "mượt" bù bằng code (squash/stretch, nhún, rung, particle).

## Asset Dome Keeper có sẵn trong repo (`Assets/Art/content`)
Dùng được làm **placeholder xịn hơn khối màu** cho bài tập trên lớp: chọn PNG cần → cắt thành dải ngang (Photopea hoặc `ai_sheet.py`) → lưu thành `<id>.png` trong `Assets/_Game/Art/...` → status ghi `placeholder`. Lưu ý đây là pixel art, khác style vẽ tay — chỉ để chạy tạm, đến art freeze nên thay hết. Không sửa/di chuyển gì trong `Assets/Art/content` (nó không thuộc pipeline).
