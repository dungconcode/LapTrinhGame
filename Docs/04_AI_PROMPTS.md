# Gen asset bằng AI — ChatGPT · Gemini · Claude

Mục tiêu: có asset **dùng được trong ngày**, cùng 1 style, để code + (nếu đẹp) dùng luôn làm final.

## 0. Chia việc giữa các tool

| Tool | Giỏi | Dùng cho | Ai |
|---|---|---|---|
| **ChatGPT** (tạo ảnh, Plus) | Giữ nhân vật nhất quán qua nhiều lần chỉnh, sửa ảnh theo lời, nền trong suốt | Nhân vật, quái, boss, base, pháo, logo | Dev B |
| **Gemini** (tạo/sửa ảnh) | Gen nhanh nhiều biến thể, sửa ảnh có sẵn ("làm bản bị hư hại") | Tile, quặng, background, item, fx | Dev A |
| **Claude** | **Không xuất ảnh raster**, nhưng viết **SVG** (vector) rất sạch + viết/sửa prompt + code | Khung UI, nút, thanh máu, icon phẳng, logo chữ; viết Particle System / shader cho fx | Dev A |

Quy trình chung cho mỗi asset:
1. Mở bảng `asset_manifest.csv` → lấy id, `spec_px`, `frames`, hướng nhìn trong notes.
2. Ghép **STYLE BLOCK** (§1) + prompt riêng (§3). **Đính kèm `style_key.png`** làm ảnh tham chiếu.
3. Gen 2–4 phương án → lưu tất cả vào Drive `04_AI_Candidates/<id>/`.
4. Chọn 1 → `python Tools/ai_sheet.py <ảnh> --id <id> [--grid CxR]` → chép vào Unity.
5. CSV: `status = ai`. Đến ART-SYNC cả nhóm quyết `ai-approved` hay giao nhóm art vẽ.

---

## 1. STYLE BLOCK (dán vào đầu MỌI prompt ảnh)

Viết tiếng Anh vì model ảnh hiểu tốt hơn.

```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game set on an alien planet.
Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette.
Palette: deep indigo and violet shadows, teal/cyan tech glow, warm rust-orange metal, muted earthy soil.
Lighting from top-left. Orthographic side view (2D platformer camera). No perspective tilt.
No text, no watermark, no ground shadow, no frame or border.
Background: flat solid pure magenta #FF00FF (or transparent).
```

> Sau khi chốt `style_key.png` (task C05), thêm dòng: `Match the exact art style, line weight and palette of the attached reference image.`

### Prompt tạo style key (task C05 — chạy ngày 1)
```
[STYLE BLOCK]
Create a style key sheet for the game "Underlab": in one image show
(1) a small chubby engineer-miner character in a sci-fi suit holding a big drill, side view facing right,
(2) a compact armored sci-fi bunker base with a rotating cannon on top,
(3) a 3x3 patch of underground soil tiles with an orange-red iron ore vein and a yellow sulfur crystal,
(4) one alien bug monster facing left.
Consistent style across all four. Wide 16:9 image.
```
Gen 4–6 bản ở cả ChatGPT và Gemini → nhóm chọn 1.

---

## 2. Mẹo để ra asset dùng được

- **1 asset / 1 lần gen.** Không xin "cả bộ quái" trong 1 ảnh (trừ style key).
- **Nhân vật nhất quán:** gen bản tĩnh `idle` thật ưng trước → các anim sau **đính kèm ảnh đó** + "same character, same proportions, same colors".
- **Animation:** AI vẽ sprite sheet hay lệch frame. Thứ tự ưu tiên:
  1. Xin **grid** (vd 3×2 cho 6 frame) rồi dùng `ai_sheet.py --grid 3x2` (tool tự căn chân, scale đều).
  2. Lệch quá → gen từng pose riêng (mỗi pose 1 ảnh, đính kèm idle) → `ai_sheet.py f1.png f2.png ...`.
  3. Vẫn xấu → dùng **1 frame tĩnh** + code làm chuyển động (nhún, nghiêng, squash) — đủ cho bài nộp. Đổi `frames` trong CSV về 1.
- **Tile seamless:** xin "seamless tileable texture"; kiểm tra bằng cách ghép 3×3 (Photopea: Filter ▸ Other ▸ Offset 50%). Gemini sửa đường nối khá tốt: "make the edges seamless".
- **Biến thể từ ảnh có sẵn** (Gemini/ChatGPT edit): `bld_base_damaged` = đưa ảnh `bld_base_normal` + "same building, now cracked, dented, small fires and smoke, keep exact shape and camera".
- **Nền:** ChatGPT có thể xin nền trong suốt trực tiếp. Gemini → nền magenta, tool sẽ xoá.
- **Kích thước:** AI ra ảnh 1024+ px — không sao, tool + Unity tự scale.

---

## 3. Prompt theo nhóm asset

> Luôn dán STYLE BLOCK trước. `{...}` = thay theo asset.

### 3.1 Nhân vật (ChatGPT) — `char_player_*`
```
[STYLE BLOCK]
Game sprite: a small chubby engineer-miner in a bulky sci-fi suit with a round glowing visor and
a backpack ore container, holding a heavy drill. Full body, side view, FACING RIGHT, centered.
Pose: {idle breathing | mid-stride walking | drilling forward with sparks | hunched over dragging heavy ore | recoiling hurt}.
```
Anim (đính kèm idle đã chọn):
```
[STYLE BLOCK]
Sprite sheet of the SAME character from the attached image (same proportions, colors, suit details).
{6}-frame {walk cycle} animation arranged in a {3x2} grid, equal cells, character centered in each cell,
feet on the same baseline in every cell, facing right. No overlap between cells.
```

### 3.2 Quái (ChatGPT) — `enemy_*`
| id gốc | Mô tả |
|---|---|
| `enemy_melee` | four-legged armored alien beetle with big mandibles, low and wide, FACING LEFT |
| `enemy_flying` | alien flying insect/bat hybrid with translucent wings and a glowing stinger, FACING LEFT |
| `enemy_ranged` | tall thin alien creature with a bulbous glowing acid sac on its back that it spits from, FACING LEFT |
```
[STYLE BLOCK]
Game enemy sprite: {mô tả}. Full body, side view, centered. Pose: {walking | attacking | hit flinch | dying, collapsing}.
Hostile but readable colors (purple/red accents) so it stands out from the brown soil and teal base.
```
Boss: thêm `huge`, `armored crystal plates`, và frame 768.

### 3.3 Base & pháo (ChatGPT)
```
[STYLE BLOCK]
Game building sprite: compact armored sci-fi bunker base sitting on the ground, half-dome metal shell
with rust-orange plates and teal lights, a circular mount on top for a turret (leave the mount EMPTY),
a door at ground level. Side view, centered, flat bottom.
```
```
[STYLE BLOCK]
Game sprite: turret cannon BARREL only, horizontal, pointing RIGHT, thick sci-fi barrel with teal energy
coils, the back end is a round pivot joint at the left. Nothing else, no base.
```
```
[STYLE BLOCK]
Game sprite: turret rotating BASE/HEAD only, round armored housing seen from the side, no barrel.
```

### 3.4 Tile & quặng (Gemini) — `tile_*`
```
[STYLE BLOCK]
Seamless tileable square texture for a 2D side-view underground soil block. {soft brownish alien soil with small pebbles |
harder dark grey-brown rock with cracks | very hard dark violet stone with tiny glowing crystals}.
Fills the whole square edge to edge, no border, no outline around the tile, uniform lighting. 1:1.
```
Quặng (đính kèm tile nền tương ứng):
```
[STYLE BLOCK]
Same soil tile as the attached image, now with an embedded ore deposit in the center:
{rust-red iron ore veins | bright yellow sulfur crystals | silvery-white shiny magnesium chunks | pale pink-white cubic KCl salt crystals}.
Keep the edges identical so it still tiles seamlessly with the plain tile. 1:1.
```
`tile_crack`: "transparent overlay of dark cracks only, no soil, 4 stages from hairline to shattered, 4x1 grid".

### 3.5 Quặng rơi & item (Gemini) — `item_*`
```
[STYLE BLOCK]
Small game pickup icon: a single chunk of {iron ore | sulfur crystal | magnesium | KCl salt crystal | sci-fi mining explosive charge}, chunky, readable at small size, centered.
```

### 3.6 Đạn (Gemini) — `proj_*`
```
[STYLE BLOCK]
Small game projectile sprite flying to the RIGHT: {glowing white-cyan energy bolt | bubbling green acid glob |
blazing orange fire shell with flame trail | icy blue crystal shard | purple alien spit glob}. Centered, short trail on the left.
```

### 3.7 Background (Gemini) — `bg_*`
```
[STYLE BLOCK — bỏ dòng magenta]
2D parallax game background layer, 16:9, {alien sky at dusk with two moons and violet clouds |
distant alien rock spires silhouette, transparent/empty sky area above |
mid-ground alien hills with strange plants, transparent above |
dark underground cave wall, very low contrast, roots and faint crystals, seamless vertically |
mid-depth cave layer with stalactites and glowing fungus, seamless vertically}.
Low detail and low contrast so gameplay sprites stay readable.
```

### 3.8 FX (Gemini, hoặc Particle System)
AI vẽ fx frame-by-frame thường kém. Ưu tiên **Particle System trong Unity** (nhờ Claude/Codex viết script). Nếu cần sprite:
```
[STYLE BLOCK]
{6}-frame VFX sprite sheet in a {3x2} grid: {small dirt and rock debris burst | green acid splash | fire burst |
ice shards shattering | cartoon explosion with smoke}. Each cell centered, effect grows then fades.
```

### 3.9 UI & icon (Claude → SVG)
Prompt cho Claude:
```
Viết file SVG {256x96} cho nút bấm game sci-fi: nền indigo đậm #1E1B3A, viền teal #3FE0D0 dày 4px,
góc vát chéo 12px, highlight mảnh phía trên, không chữ. Thiết kế để làm 9-slice: 4 góc trang trí
nằm trong 24px mép, phần giữa phẳng. Chỉ trả về code SVG.
```
Icon:
```
Viết SVG 128x128 icon game "{nâng cấp mũi khoan}": hình phẳng, viền tối 6px, 2–3 màu từ bảng
#1E1B3A #3FE0D0 #E07A3F #F2D35B, silhouette rõ khi thu nhỏ 32px, không chữ.
```
Đổi SVG → PNG: mở bằng **Inkscape** (Export PNG đúng kích thước) hoặc web svgtopng; hoặc:
```bash
python -c "import cairosvg; cairosvg.svg2png(url='icon.svg', write_to='icon_up_drill.png', output_width=128)"
```
(SVG gốc lưu Drive `03_Source/` để sửa màu sau.)

Logo chữ `ui_logo`: ChatGPT ghi chữ ổn — "game logo text 'UNDERLAB', chunky sci-fi letters, drill bit forming the letter U".

---

## 4. Prompt cho AI viết code (Codex / Claude) — dán kèm đầu mỗi yêu cầu

```
Dự án Unity 6 2D (URP), C#, namespace Underlab.*. Đọc AGENTS.md trước.
- Asset hình ảnh CHỈ dùng qua ArtSprite / ArtDatabase bằng art id trong Assets/_Game/Art/asset_manifest.csv.
- Giao tiếp giữa module qua Underlab.Core.GameEvents; số liệu trong ScriptableObject ở Assets/_Game/Data.
- Chỉ sửa file trong folder của tôi: {Scripts/Mining | Scripts/Defense ...}.
Nhiệm vụ: {task ID + mô tả từ 01_ROADMAP.md}.
```
