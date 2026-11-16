# Danh sách asset cần gen bằng ChatGPT

> Dành cho người gen asset. **Không cần Unity, không cần git.**
> Icon và khung UI (`icon_*`, `ui_*` trừ logo/màn hình) Claude làm bằng SVG — không có trong danh sách này.
> File được sinh tự động từ `Assets/_Game/Art/asset_manifest.csv`.

## Cách làm (đọc 1 lần)

1. **Đính kèm `style_key.png`** (Drive `00_StyleGuide/`) vào MỌI lần gen. Chưa có thì gen ảnh style key trước (Docs/04_AI_PROMPTS.md §1), cả nhóm chọn 1.
2. Làm theo thứ tự **P0 → P1 → P2**. Mỗi asset: copy nguyên khối prompt → gen 2–3 lần → chọn cái đẹp nhất.
3. **Animation**: gen bản `idle` (hoặc frame đầu) thật ưng trước. Các anim sau **đính kèm thêm ảnh đó** để giữ đúng nhân vật.
   Nếu ChatGPT vẽ lệch grid/sai số ô: bảo *"redo, exactly N cells in a CxR grid, equal size, character same size in every cell"*.
   Vẫn không được → gen **từng frame riêng** (mỗi ảnh 1 pose), đặt tên `f1.png`, `f2.png`…
4. **Biến thể** (base hư hại, nòng giật…): đính kèm ảnh gốc đã chọn, prompt đã ghi "the SAME … as the attached image".
5. **Nộp**: tải PNG về (bản gốc, không cần cắt/resize) → bỏ vào Drive
   `04_AI_Candidates/<id>/` (vd `04_AI_Candidates/enemy_melee_walk/`). Có nhiều bản thì để hết, đánh dấu bản chọn bằng tên `chon.png`.
6. Tick `[x]` vào bảng dưới (hoặc nhắn "xong <id>").

Hướng nhìn quy ước: **nhân vật, đạn, nòng pháo → PHẢI**; **quái, boss → TRÁI**.

## Tiến độ

| Ưu tiên | Số lượng | Cần xong |
|---|---|---|
| P0 | 28 | **20/11** |
| P1 | 38 | 27/11 |
| P2 | 10 | 4/12 (có thì tốt) |

## Bảng tổng

| ✔ | Ưu tiên | id | Số frame | Ghi chú |
|---|---|---|---|---|
| [ ] | P0 | `char_player_idle` | 4 | Nhân vật |
| [ ] | P0 | `char_player_walk` | 6 | Nhân vật |
| [ ] | P0 | `char_player_drill` | 4 | Nhân vật |
| [ ] | P1 | `char_player_carry` | 6 | Nhân vật |
| [ ] | P1 | `char_player_hurt` | 2 | Nhân vật |
| [ ] | P2 | `char_player_death` | 6 | Nhân vật |
| [ ] | P0 | `enemy_melee_walk` | 6 | Quái |
| [ ] | P0 | `enemy_melee_attack` | 4 | Quái |
| [ ] | P0 | `enemy_flying_fly` | 6 | Quái |
| [ ] | P0 | `enemy_ranged_walk` | 6 | Quái |
| [ ] | P0 | `enemy_ranged_attack` | 5 | Quái |
| [ ] | P1 | `enemy_melee_hurt` | 2 | Quái |
| [ ] | P1 | `enemy_melee_death` | 5 | Quái |
| [ ] | P1 | `enemy_flying_attack` | 4 | Quái |
| [ ] | P1 | `enemy_flying_hurt` | 2 | Quái |
| [ ] | P1 | `enemy_flying_death` | 5 | Quái |
| [ ] | P1 | `enemy_ranged_hurt` | 2 | Quái |
| [ ] | P1 | `enemy_ranged_death` | 5 | Quái |
| [ ] | P1 | `boss_idle` | 4 | Boss |
| [ ] | P1 | `boss_move` | 6 | Boss |
| [ ] | P1 | `boss_skill` | 8 | Boss |
| [ ] | P1 | `boss_projectile` | tĩnh | Boss |
| [ ] | P2 | `boss_death` | 8 | Boss |
| [ ] | P0 | `bld_base_normal` | tĩnh | Base, pháo, thang máy |
| [ ] | P0 | `bld_turret_body` | tĩnh | Base, pháo, thang máy |
| [ ] | P0 | `bld_turret_barrel` | tĩnh | Base, pháo, thang máy |
| [ ] | P1 | `bld_base_damaged` | tĩnh | Base, pháo, thang máy |
| [ ] | P1 | `bld_turret_fire` | 3 | Base, pháo, thang máy |
| [ ] | P1 | `bld_lift` | tĩnh | Base, pháo, thang máy |
| [ ] | P1 | `bld_lift_cart` | tĩnh | Base, pháo, thang máy |
| [ ] | P2 | `bld_base_destroyed` | tĩnh | Base, pháo, thang máy |
| [ ] | P2 | `bld_base_upgraded` | tĩnh | Base, pháo, thang máy |
| [ ] | P2 | `bld_teleporter` | 6 | Base, pháo, thang máy |
| [ ] | P0 | `tile_surface` | tĩnh | Ô đất & quặng |
| [ ] | P0 | `tile_dirt_1` | tĩnh | Ô đất & quặng |
| [ ] | P0 | `tile_dirt_2` | tĩnh | Ô đất & quặng |
| [ ] | P0 | `tile_dirt_3` | tĩnh | Ô đất & quặng |
| [ ] | P0 | `tile_ore_iron` | tĩnh | Ô đất & quặng |
| [ ] | P0 | `tile_ore_sulfur` | tĩnh | Ô đất & quặng |
| [ ] | P0 | `tile_ore_mg` | tĩnh | Ô đất & quặng |
| [ ] | P0 | `tile_ore_kcl` | tĩnh | Ô đất & quặng |
| [ ] | P0 | `tile_crack` | 4 | Ô đất & quặng |
| [ ] | P1 | `tile_bedrock` | tĩnh | Ô đất & quặng |
| [ ] | P0 | `item_ore_iron` | tĩnh | Quặng rơi & item |
| [ ] | P0 | `item_ore_sulfur` | tĩnh | Quặng rơi & item |
| [ ] | P0 | `item_ore_mg` | tĩnh | Quặng rơi & item |
| [ ] | P0 | `item_ore_kcl` | tĩnh | Quặng rơi & item |
| [ ] | P1 | `item_blast_charge` | tĩnh | Quặng rơi & item |
| [ ] | P0 | `proj_normal` | tĩnh | Đạn |
| [ ] | P1 | `proj_acid` | tĩnh | Đạn |
| [ ] | P1 | `proj_fire` | tĩnh | Đạn |
| [ ] | P1 | `proj_ice` | tĩnh | Đạn |
| [ ] | P1 | `proj_enemy` | tĩnh | Đạn |
| [ ] | P0 | `bg_surface_sky` | tĩnh | Nền |
| [ ] | P0 | `bg_underground_far` | tĩnh | Nền |
| [ ] | P1 | `bg_surface_far` | tĩnh | Nền |
| [ ] | P1 | `bg_surface_mid` | tĩnh | Nền |
| [ ] | P1 | `bg_underground_mid` | tĩnh | Nền |
| [ ] | P1 | `ui_logo` | tĩnh | Logo & màn hình |
| [ ] | P1 | `ui_bg_mainmenu` | tĩnh | Logo & màn hình |
| [ ] | P2 | `ui_screen_victory` | tĩnh | Logo & màn hình |
| [ ] | P2 | `ui_screen_gameover` | tĩnh | Logo & màn hình |
| [ ] | P0 | `fx_block_break` | 6 | Hiệu ứng (ưu tiên thấp — có thể làm bằng code) |
| [ ] | P1 | `fx_drill_spark` | 4 | Hiệu ứng (ưu tiên thấp — có thể làm bằng code) |
| [ ] | P1 | `fx_muzzle_flash` | 3 | Hiệu ứng (ưu tiên thấp — có thể làm bằng code) |
| [ ] | P1 | `fx_explosion` | 8 | Hiệu ứng (ưu tiên thấp — có thể làm bằng code) |
| [ ] | P1 | `fx_hit_normal` | 4 | Hiệu ứng (ưu tiên thấp — có thể làm bằng code) |
| [ ] | P1 | `fx_hit_acid` | 6 | Hiệu ứng (ưu tiên thấp — có thể làm bằng code) |
| [ ] | P1 | `fx_hit_fire` | 6 | Hiệu ứng (ưu tiên thấp — có thể làm bằng code) |
| [ ] | P1 | `fx_hit_ice` | 6 | Hiệu ứng (ưu tiên thấp — có thể làm bằng code) |
| [ ] | P1 | `fx_status_poison` | 4 | Hiệu ứng (ưu tiên thấp — có thể làm bằng code) |
| [ ] | P1 | `fx_status_burn` | 4 | Hiệu ứng (ưu tiên thấp — có thể làm bằng code) |
| [ ] | P1 | `fx_status_frozen` | tĩnh | Hiệu ứng (ưu tiên thấp — có thể làm bằng code) |
| [ ] | P2 | `fx_blast` | 8 | Hiệu ứng (ưu tiên thấp — có thể làm bằng code) |
| [ ] | P2 | `fx_teleport` | 6 | Hiệu ứng (ưu tiên thấp — có thể làm bằng code) |
| [ ] | P2 | `fx_deposit` | 6 | Hiệu ứng (ưu tiên thấp — có thể làm bằng code) |

---

## Prompt từng asset (copy nguyên khối)

### Nhân vật

**`char_player_drill`** — P0 · 4 frame · đính kèm ảnh **char_player_idle** đã chọn
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: the SAME creature as the attached image (a small chubby engineer-miner in a bulky sci-fi suit with a round glowing teal visor, a backpack ore container and a heavy drill). 4-frame drilling forward, drill pointing right with sparks animation arranged in a 2x2 grid of equal square cells, each frame centered in its cell. Same size, proportions and colors in every cell. Feet on the same baseline in every cell. Facing RIGHT. No overlap, no grid lines, no numbers. Transparent background.
```

**`char_player_idle`** — P0 · 4 frame
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: a small chubby engineer-miner in a bulky sci-fi suit with a round glowing teal visor, a backpack ore container and a heavy drill. 4-frame idle breathing animation arranged in a 2x2 grid of equal square cells, each frame centered in its cell. Same size, proportions and colors in every cell. Feet on the same baseline in every cell. Facing RIGHT. No overlap, no grid lines, no numbers. Transparent background.
```

**`char_player_walk`** — P0 · 6 frame · đính kèm ảnh **char_player_idle** đã chọn
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: the SAME creature as the attached image (a small chubby engineer-miner in a bulky sci-fi suit with a round glowing teal visor, a backpack ore container and a heavy drill). 6-frame walk cycle animation arranged in a 3x2 grid of equal square cells, each frame centered in its cell. Same size, proportions and colors in every cell. Feet on the same baseline in every cell. Facing RIGHT. No overlap, no grid lines, no numbers. Transparent background.
```

**`char_player_carry`** — P1 · 6 frame · đính kèm ảnh **char_player_idle** đã chọn
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: the SAME creature as the attached image (a small chubby engineer-miner in a bulky sci-fi suit with a round glowing teal visor, a backpack ore container and a heavy drill). 6-frame slow heavy walk, hunched over, dragging a heavy load of ore animation arranged in a 3x2 grid of equal square cells, each frame centered in its cell. Same size, proportions and colors in every cell. Feet on the same baseline in every cell. Facing RIGHT. No overlap, no grid lines, no numbers. Transparent background.
```

**`char_player_hurt`** — P1 · 2 frame · đính kèm ảnh **char_player_idle** đã chọn
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: the SAME creature as the attached image (a small chubby engineer-miner in a bulky sci-fi suit with a round glowing teal visor, a backpack ore container and a heavy drill). 2-frame hit reaction, recoiling backwards animation arranged in a 2x1 grid of equal square cells, each frame centered in its cell. Same size, proportions and colors in every cell. Feet on the same baseline in every cell. Facing RIGHT. No overlap, no grid lines, no numbers. Transparent background.
```

**`char_player_death`** — P2 · 6 frame · đính kèm ảnh **char_player_idle** đã chọn
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: the SAME creature as the attached image (a small chubby engineer-miner in a bulky sci-fi suit with a round glowing teal visor, a backpack ore container and a heavy drill). 6-frame collapsing to the ground, visor flickering off animation arranged in a 3x2 grid of equal square cells, each frame centered in its cell. Same size, proportions and colors in every cell. Feet on the same baseline in every cell. Facing RIGHT. No overlap, no grid lines, no numbers. Transparent background.
```

### Quái

**`enemy_flying_fly`** — P0 · 6 frame
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: an alien flying insect/bat hybrid with translucent wings and a glowing stinger, purple and magenta. 6-frame flying, wings flapping animation arranged in a 3x2 grid of equal square cells, each frame centered in its cell. Same size, proportions and colors in every cell. Facing LEFT. No overlap, no grid lines, no numbers. Transparent background.
```

**`enemy_melee_attack`** — P0 · 4 frame · đính kèm ảnh walk/idle đã chọn
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: the SAME creature as the attached image (a four-legged armored alien beetle with big mandibles, low and wide, purple carapace with red accents). 4-frame lunging bite attack with mandibles animation arranged in a 2x2 grid of equal square cells, each frame centered in its cell. Same size, proportions and colors in every cell. Feet on the same baseline in every cell. Facing LEFT. No overlap, no grid lines, no numbers. Transparent background.
```

**`enemy_melee_walk`** — P0 · 6 frame
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: a four-legged armored alien beetle with big mandibles, low and wide, purple carapace with red accents. 6-frame walk cycle animation arranged in a 3x2 grid of equal square cells, each frame centered in its cell. Same size, proportions and colors in every cell. Feet on the same baseline in every cell. Facing LEFT. No overlap, no grid lines, no numbers. Transparent background.
```

**`enemy_ranged_attack`** — P0 · 5 frame · đính kèm ảnh walk/idle đã chọn
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: the SAME creature as the attached image (a tall thin alien creature with a bulbous glowing green acid sac on its back that it spits from). 5-frame rearing back and spitting an acid glob animation arranged in a 3x2 grid of equal square cells, each frame centered in its cell. Same size, proportions and colors in every cell. Feet on the same baseline in every cell. Facing LEFT. No overlap, no grid lines, no numbers. Leave the last 1 cell(s) empty. Transparent background.
```

**`enemy_ranged_walk`** — P0 · 6 frame
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: a tall thin alien creature with a bulbous glowing green acid sac on its back that it spits from. 6-frame walk cycle animation arranged in a 3x2 grid of equal square cells, each frame centered in its cell. Same size, proportions and colors in every cell. Feet on the same baseline in every cell. Facing LEFT. No overlap, no grid lines, no numbers. Transparent background.
```

**`enemy_flying_attack`** — P1 · 4 frame · đính kèm ảnh walk/idle đã chọn
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: the SAME creature as the attached image (an alien flying insect/bat hybrid with translucent wings and a glowing stinger, purple and magenta). 4-frame diving down to sting animation arranged in a 2x2 grid of equal square cells, each frame centered in its cell. Same size, proportions and colors in every cell. Facing LEFT. No overlap, no grid lines, no numbers. Transparent background.
```

**`enemy_flying_death`** — P1 · 5 frame · đính kèm ảnh walk/idle đã chọn
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: the SAME creature as the attached image (an alien flying insect/bat hybrid with translucent wings and a glowing stinger, purple and magenta). 5-frame falling and bursting animation arranged in a 3x2 grid of equal square cells, each frame centered in its cell. Same size, proportions and colors in every cell. Facing LEFT. No overlap, no grid lines, no numbers. Leave the last 1 cell(s) empty. Transparent background.
```

**`enemy_flying_hurt`** — P1 · 2 frame · đính kèm ảnh walk/idle đã chọn
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: the SAME creature as the attached image (an alien flying insect/bat hybrid with translucent wings and a glowing stinger, purple and magenta). 2-frame hit flinch in the air animation arranged in a 2x1 grid of equal square cells, each frame centered in its cell. Same size, proportions and colors in every cell. Facing LEFT. No overlap, no grid lines, no numbers. Transparent background.
```

**`enemy_melee_death`** — P1 · 5 frame · đính kèm ảnh walk/idle đã chọn
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: the SAME creature as the attached image (a four-legged armored alien beetle with big mandibles, low and wide, purple carapace with red accents). 5-frame dying, bursting into goo animation arranged in a 3x2 grid of equal square cells, each frame centered in its cell. Same size, proportions and colors in every cell. Feet on the same baseline in every cell. Facing LEFT. No overlap, no grid lines, no numbers. Leave the last 1 cell(s) empty. Transparent background.
```

**`enemy_melee_hurt`** — P1 · 2 frame · đính kèm ảnh walk/idle đã chọn
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: the SAME creature as the attached image (a four-legged armored alien beetle with big mandibles, low and wide, purple carapace with red accents). 2-frame hit flinch animation arranged in a 2x1 grid of equal square cells, each frame centered in its cell. Same size, proportions and colors in every cell. Feet on the same baseline in every cell. Facing LEFT. No overlap, no grid lines, no numbers. Transparent background.
```

**`enemy_ranged_death`** — P1 · 5 frame · đính kèm ảnh walk/idle đã chọn
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: the SAME creature as the attached image (a tall thin alien creature with a bulbous glowing green acid sac on its back that it spits from). 5-frame acid sac bursting, collapsing animation arranged in a 3x2 grid of equal square cells, each frame centered in its cell. Same size, proportions and colors in every cell. Feet on the same baseline in every cell. Facing LEFT. No overlap, no grid lines, no numbers. Leave the last 1 cell(s) empty. Transparent background.
```

**`enemy_ranged_hurt`** — P1 · 2 frame · đính kèm ảnh walk/idle đã chọn
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: the SAME creature as the attached image (a tall thin alien creature with a bulbous glowing green acid sac on its back that it spits from). 2-frame hit flinch animation arranged in a 2x1 grid of equal square cells, each frame centered in its cell. Same size, proportions and colors in every cell. Feet on the same baseline in every cell. Facing LEFT. No overlap, no grid lines, no numbers. Transparent background.
```

### Boss

**`boss_idle`** — P1 · 4 frame
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: a huge armored alien queen beetle with violet crystal plates on its back, glowing eyes, massive claws. 4-frame idle, breathing menacingly animation arranged in a 2x2 grid of equal square cells, each frame centered in its cell. Same size, proportions and colors in every cell. Feet on the same baseline in every cell. Facing LEFT. No overlap, no grid lines, no numbers. Transparent background.
```

**`boss_move`** — P1 · 6 frame · đính kèm ảnh walk/idle đã chọn
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: the SAME creature as the attached image (a huge armored alien queen beetle with violet crystal plates on its back, glowing eyes, massive claws). 6-frame heavy walk cycle animation arranged in a 3x2 grid of equal square cells, each frame centered in its cell. Same size, proportions and colors in every cell. Feet on the same baseline in every cell. Facing LEFT. No overlap, no grid lines, no numbers. Transparent background.
```

**`boss_projectile`** — P1 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Game sprite: a glowing violet crystal shard projectile flying LEFT with a short trail. Facing LEFT. Full view, centered, nothing else in the image. Transparent background.
```

**`boss_skill`** — P1 · 8 frame · đính kèm ảnh walk/idle đã chọn
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: the SAME creature as the attached image (a huge armored alien queen beetle with violet crystal plates on its back, glowing eyes, massive claws). 8-frame rearing up and firing a beam of crystal shards from its back animation arranged in a 4x2 grid of equal square cells, each frame centered in its cell. Same size, proportions and colors in every cell. Feet on the same baseline in every cell. Facing LEFT. No overlap, no grid lines, no numbers. Transparent background.
```

**`boss_death`** — P2 · 8 frame · đính kèm ảnh walk/idle đã chọn
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: the SAME creature as the attached image (a huge armored alien queen beetle with violet crystal plates on its back, glowing eyes, massive claws). 8-frame collapsing, crystal plates shattering animation arranged in a 4x2 grid of equal square cells, each frame centered in its cell. Same size, proportions and colors in every cell. Feet on the same baseline in every cell. Facing LEFT. No overlap, no grid lines, no numbers. Transparent background.
```

### Base, pháo, thang máy

**`bld_base_normal`** — P0 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Game sprite: a compact armored sci-fi bunker base: half-dome metal shell with rust-orange plates and teal lights, a door at ground level, an EMPTY circular turret mount on top, flat bottom. Full view, centered, nothing else in the image. Transparent background.
```

**`bld_turret_barrel`** — P0 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Game sprite: a turret cannon BARREL only, horizontal, pointing RIGHT, thick sci-fi barrel with teal energy coils, round pivot joint at the LEFT end, nothing else. Full view, centered, nothing else in the image. Transparent background.
```

**`bld_turret_body`** — P0 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Game sprite: a turret rotating head/housing only, round armored, seen from the side, NO barrel. Full view, centered, nothing else in the image. Transparent background.
```

**`bld_base_damaged`** — P1 · tĩnh · đính kèm ảnh gốc đã chọn (bld_base_normal)
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Game sprite: the SAME bunker base as the attached image, now cracked and dented with small fires and smoke; keep exact shape and camera. Full view, centered, nothing else in the image. Transparent background.
```

**`bld_lift`** — P1 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Game sprite: a vertical mining-lift shaft frame segment (metal rails and cables), seamless top-to-bottom so it can repeat vertically. Full view, centered, nothing else in the image. Transparent background.
```

**`bld_lift_cart`** — P1 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Game sprite: a small sci-fi ore cart/cage that rides the lift, filled with glowing ore. Full view, centered, nothing else in the image. Transparent background.
```

**`bld_turret_fire`** — P1 · 3 frame · đính kèm ảnh gốc đã chọn (bld_turret_barrel)
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: the SAME turret barrel as the attached image, recoil animation: barrel pushed back then returning. 3-frame recoil animation arranged in a 3x1 grid of equal 2:1 wide cells, each frame centered in its cell. Same size, proportions and colors in every cell. No overlap, no grid lines, no numbers. Transparent background.
```

**`bld_base_destroyed`** — P2 · tĩnh · đính kèm ảnh gốc đã chọn (bld_base_normal)
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Game sprite: the SAME bunker base as the attached image, collapsed and burning ruins. Full view, centered, nothing else in the image. Transparent background.
```

**`bld_base_upgraded`** — P2 · tĩnh · đính kèm ảnh gốc đã chọn (bld_base_normal)
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Game sprite: the SAME bunker base as the attached image with extra armor plates and brighter teal lights. Full view, centered, nothing else in the image. Transparent background.
```

**`bld_teleporter`** — P2 · 6 frame
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: a sci-fi teleporter pad with a rotating ring of teal energy. 6-frame energy ring spinning animation arranged in a 3x2 grid of equal square cells, each frame centered in its cell. Same size, proportions and colors in every cell. No overlap, no grid lines, no numbers. Transparent background.
```

### Ô đất & quặng

**`tile_crack`** — P0 · 4 frame
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
4-frame sprite sheet in a 2x2 grid of equal square cells: transparent overlay showing ONLY dark cracks (no soil), each cell more cracked than the previous (hairline -> almost shattered). Transparent background, no grid lines.
```

**`tile_dirt_1`** — P0 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Seamless tileable SQUARE texture for a 2D side-view underground block: soft brownish alien soil with small pebbles. Fills the whole square edge to edge, no border, no outline, uniform lighting, 1:1.
```

**`tile_dirt_2`** — P0 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Seamless tileable SQUARE texture for a 2D side-view underground block: harder dark grey-brown rock with cracks. Fills the whole square edge to edge, no border, no outline, uniform lighting, 1:1.
```

**`tile_dirt_3`** — P0 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Seamless tileable SQUARE texture for a 2D side-view underground block: very hard dark violet stone with tiny faint glowing crystals. Fills the whole square edge to edge, no border, no outline, uniform lighting, 1:1.
```

**`tile_ore_iron`** — P0 · tĩnh · đính kèm ảnh **tile_dirt_1** đã chọn
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Use the attached plain soil tile as the base: the soft brown soil tile with rust-red iron ore veins in the center. Keep the four edges identical to the attached tile so it tiles seamlessly next to it. Fills the whole square edge to edge, no border, no outline, 1:1.
```

**`tile_ore_kcl`** — P0 · tĩnh · đính kèm ảnh **tile_dirt_3** đã chọn
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Use the attached plain soil tile as the base: the dark violet stone tile with pale pink-white cubic KCl salt crystals in the center. Keep the four edges identical to the attached tile so it tiles seamlessly next to it. Fills the whole square edge to edge, no border, no outline, 1:1.
```

**`tile_ore_mg`** — P0 · tĩnh · đính kèm ảnh **tile_dirt_2** đã chọn
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Use the attached plain soil tile as the base: the grey rock tile with silvery-white shiny magnesium chunks in the center. Keep the four edges identical to the attached tile so it tiles seamlessly next to it. Fills the whole square edge to edge, no border, no outline, 1:1.
```

**`tile_ore_sulfur`** — P0 · tĩnh · đính kèm ảnh **tile_dirt_1** đã chọn
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Use the attached plain soil tile as the base: the brown soil tile with bright yellow sulfur crystals in the center. Keep the four edges identical to the attached tile so it tiles seamlessly next to it. Fills the whole square edge to edge, no border, no outline, 1:1.
```

**`tile_surface`** — P0 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Seamless tileable SQUARE texture for a 2D side-view underground block: alien topsoil: brown-violet soil with a strip of teal alien moss along the TOP edge. Fills the whole square edge to edge, no border, no outline, uniform lighting, 1:1.
```

**`tile_bedrock`** — P1 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Seamless tileable SQUARE texture for a 2D side-view underground block: unbreakable near-black basalt with heavy hexagonal cracks, clearly darker than all other tiles. Fills the whole square edge to edge, no border, no outline, uniform lighting, 1:1.
```

### Quặng rơi & item

**`item_ore_iron`** — P0 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Game sprite: a single chunk of rust-red iron ore. Full view, centered, nothing else in the image. Transparent background.
```

**`item_ore_kcl`** — P0 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Game sprite: a single pale pink-white cubic salt (KCl) crystal. Full view, centered, nothing else in the image. Transparent background.
```

**`item_ore_mg`** — P0 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Game sprite: a single silvery-white shiny magnesium chunk. Full view, centered, nothing else in the image. Transparent background.
```

**`item_ore_sulfur`** — P0 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Game sprite: a single bright yellow sulfur crystal cluster. Full view, centered, nothing else in the image. Transparent background.
```

**`item_blast_charge`** — P1 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Game sprite: a sci-fi mining explosive charge with a blinking red light. Full view, centered, nothing else in the image. Transparent background.
```

### Đạn

**`proj_normal`** — P0 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Game sprite: a glowing white-cyan energy bolt flying RIGHT with a short trail. Full view, centered, nothing else in the image. Transparent background.
```

**`proj_acid`** — P1 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Game sprite: a bubbling green acid glob flying RIGHT. Full view, centered, nothing else in the image. Transparent background.
```

**`proj_enemy`** — P1 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Game sprite: a purple alien spit glob flying LEFT. Full view, centered, nothing else in the image. Transparent background.
```

**`proj_fire`** — P1 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Game sprite: a blazing orange fire shell flying RIGHT with a flame trail. Full view, centered, nothing else in the image. Transparent background.
```

**`proj_ice`** — P1 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Game sprite: an icy blue crystal shard flying RIGHT. Full view, centered, nothing else in the image. Transparent background.
```

### Nền

**`bg_surface_sky`** — P0 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
2D parallax game background layer, 16:9: alien sky at dusk with two moons and violet clouds; fills the whole image. Low detail and low contrast so gameplay sprites stay readable.
```

**`bg_underground_far`** — P0 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
2D parallax game background layer, 16:9: dark underground cave wall, very low contrast, roots and faint crystals; seamless top-to-bottom. Low detail and low contrast so gameplay sprites stay readable.
```

**`bg_surface_far`** — P1 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
2D parallax game background layer, 16:9: distant alien rock spires silhouette along the bottom third; EVERYTHING above the silhouette fully transparent; tiles horizontally. Low detail and low contrast so gameplay sprites stay readable.
```

**`bg_surface_mid`** — P1 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
2D parallax game background layer, 16:9: mid-ground alien hills with strange plants along the bottom third; EVERYTHING above fully transparent; tiles horizontally. Low detail and low contrast so gameplay sprites stay readable.
```

**`bg_underground_mid`** — P1 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
2D parallax game background layer, 16:9: mid-depth cave layer with stalactites and glowing fungus, low contrast; seamless top-to-bottom. Low detail and low contrast so gameplay sprites stay readable.
```

### Logo & màn hình

**`ui_bg_mainmenu`** — P1 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
main menu illustration: the miner standing next to the bunker base on an alien planet surface at dusk, cave tunnels visible below in a cross-section. 16:9.
```

**`ui_logo`** — P1 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
game logo text 'UNDERLAB' in chunky sci-fi letters, a drill bit forming the letter U, teal and rust-orange. 2:1. Transparent background.
```

**`ui_screen_gameover`** — P2 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
game over illustration: the bunker base destroyed and smoking at night, alien beetles swarming. 16:9.
```

**`ui_screen_victory`** — P2 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
victory screen illustration: the bunker base intact at sunrise, defeated alien queen in the distance. 16:9.
```

### Hiệu ứng (ưu tiên thấp — có thể làm bằng code)

**`fx_block_break`** — P0 · 6 frame
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: small dirt and rock debris burst, growing then fading. 6-frame burst animation arranged in a 3x2 grid of equal square cells, each frame centered in its cell. No overlap, no grid lines, no numbers. Transparent background.
```

**`fx_drill_spark`** — P1 · 4 frame
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: bright orange-yellow sparks spraying. 4-frame sparks animation arranged in a 2x2 grid of equal square cells, each frame centered in its cell. No overlap, no grid lines, no numbers. Transparent background.
```

**`fx_explosion`** — P1 · 8 frame
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: cartoon explosion with fire and smoke, growing then fading. 8-frame explosion animation arranged in a 4x2 grid of equal square cells, each frame centered in its cell. No overlap, no grid lines, no numbers. Transparent background.
```

**`fx_hit_acid`** — P1 · 6 frame
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: green acid splash. 6-frame splash animation arranged in a 3x2 grid of equal square cells, each frame centered in its cell. No overlap, no grid lines, no numbers. Transparent background.
```

**`fx_hit_fire`** — P1 · 6 frame
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: orange fire burst. 6-frame burst animation arranged in a 3x2 grid of equal square cells, each frame centered in its cell. No overlap, no grid lines, no numbers. Transparent background.
```

**`fx_hit_ice`** — P1 · 6 frame
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: ice shards shattering, light blue. 6-frame shatter animation arranged in a 3x2 grid of equal square cells, each frame centered in its cell. No overlap, no grid lines, no numbers. Transparent background.
```

**`fx_hit_normal`** — P1 · 4 frame
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: small white-cyan impact flash. 4-frame impact animation arranged in a 2x2 grid of equal square cells, each frame centered in its cell. No overlap, no grid lines, no numbers. Transparent background.
```

**`fx_muzzle_flash`** — P1 · 3 frame
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: cannon muzzle flash pointing RIGHT, teal-white. 3-frame flash animation arranged in a 3x1 grid of equal square cells, each frame centered in its cell. No overlap, no grid lines, no numbers. Transparent background.
```

**`fx_status_burn`** — P1 · 4 frame
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: small flickering flame icon. 4-frame flickering animation arranged in a 2x2 grid of equal square cells, each frame centered in its cell. No overlap, no grid lines, no numbers. Transparent background.
```

**`fx_status_frozen`** — P1 · tĩnh
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Game VFX sprite: small snowflake icon, light blue. Full view, centered, nothing else in the image. Transparent background.
```

**`fx_status_poison`** — P1 · 4 frame
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: small floating green poison bubbles icon. 4-frame bubbling animation arranged in a 2x2 grid of equal square cells, each frame centered in its cell. No overlap, no grid lines, no numbers. Transparent background.
```

**`fx_blast`** — P2 · 8 frame
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: big rock-blasting explosion with flying rocks. 8-frame explosion animation arranged in a 4x2 grid of equal square cells, each frame centered in its cell. No overlap, no grid lines, no numbers. Transparent background.
```

**`fx_deposit`** — P2 · 6 frame
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: ore chunks and sparkles being sucked into a point. 6-frame suck-in animation arranged in a 3x2 grid of equal square cells, each frame centered in its cell. No overlap, no grid lines, no numbers. Transparent background.
```

**`fx_teleport`** — P2 · 6 frame
```
STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. No text, no watermark, no ground shadow, no border. Match the art style of the attached style_key.png.
Sprite sheet: teal energy teleport swirl. 6-frame swirl animation arranged in a 3x2 grid of equal square cells, each frame centered in its cell. No overlap, no grid lines, no numbers. Transparent background.
```
