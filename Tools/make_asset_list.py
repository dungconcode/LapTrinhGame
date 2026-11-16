"""Sinh Docs/06_ASSET_LIST_CHATGPT.md từ asset_manifest.csv + mô tả tiếng Anh cho từng id."""
import csv
import sys

import os
ROOT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
rows = list(csv.DictReader(open(f"{ROOT}/Assets/_Game/Art/asset_manifest.csv", encoding="utf-8")))

STYLE = ("STYLE: 2D hand-painted game asset for a sci-fi mining & tower-defense game on an alien planet. "
         "Clean bold dark outlines, soft cel shading, painterly texture, readable silhouette. "
         "Palette: deep indigo/violet shadows, teal-cyan tech glow, warm rust-orange metal, muted earthy soil. "
         "Lighting from top-left. Orthographic side view (2D platformer camera), no perspective. "
         "No text, no watermark, no ground shadow, no border. "
         "Match the art style of the attached style_key.png.")

CHAR = "a small chubby engineer-miner in a bulky sci-fi suit with a round glowing teal visor, a backpack ore container and a heavy drill"
MELEE = "a four-legged armored alien beetle with big mandibles, low and wide, purple carapace with red accents"
FLY = "an alien flying insect/bat hybrid with translucent wings and a glowing stinger, purple and magenta"
RANGED = "a tall thin alien creature with a bulbous glowing green acid sac on its back that it spits from"
BOSS = "a huge armored alien queen beetle with violet crystal plates on its back, glowing eyes, massive claws"

D = {
    "char_player_idle": (CHAR, "idle breathing"),
    "char_player_walk": (CHAR, "walk cycle"),
    "char_player_drill": (CHAR, "drilling forward, drill pointing right with sparks"),
    "char_player_carry": (CHAR, "slow heavy walk, hunched over, dragging a heavy load of ore"),
    "char_player_hurt": (CHAR, "hit reaction, recoiling backwards"),
    "char_player_death": (CHAR, "collapsing to the ground, visor flickering off"),
    "enemy_melee_walk": (MELEE, "walk cycle"),
    "enemy_melee_attack": (MELEE, "lunging bite attack with mandibles"),
    "enemy_melee_hurt": (MELEE, "hit flinch"),
    "enemy_melee_death": (MELEE, "dying, bursting into goo"),
    "enemy_flying_fly": (FLY, "flying, wings flapping"),
    "enemy_flying_attack": (FLY, "diving down to sting"),
    "enemy_flying_hurt": (FLY, "hit flinch in the air"),
    "enemy_flying_death": (FLY, "falling and bursting"),
    "enemy_ranged_walk": (RANGED, "walk cycle"),
    "enemy_ranged_attack": (RANGED, "rearing back and spitting an acid glob"),
    "enemy_ranged_hurt": (RANGED, "hit flinch"),
    "enemy_ranged_death": (RANGED, "acid sac bursting, collapsing"),
    "boss_idle": (BOSS, "idle, breathing menacingly"),
    "boss_move": (BOSS, "heavy walk cycle"),
    "boss_skill": (BOSS, "rearing up and firing a beam of crystal shards from its back"),
    "boss_death": (BOSS, "collapsing, crystal plates shattering"),
    "boss_projectile": ("a glowing violet crystal shard projectile flying LEFT with a short trail", None),
    "tile_surface": ("alien topsoil: brown-violet soil with a strip of teal alien moss along the TOP edge", None),
    "tile_dirt_1": ("soft brownish alien soil with small pebbles", None),
    "tile_dirt_2": ("harder dark grey-brown rock with cracks", None),
    "tile_dirt_3": ("very hard dark violet stone with tiny faint glowing crystals", None),
    "tile_bedrock": ("unbreakable near-black basalt with heavy hexagonal cracks, clearly darker than all other tiles", None),
    "tile_ore_iron": ("the soft brown soil tile with rust-red iron ore veins in the center", None),
    "tile_ore_sulfur": ("the brown soil tile with bright yellow sulfur crystals in the center", None),
    "tile_ore_mg": ("the grey rock tile with silvery-white shiny magnesium chunks in the center", None),
    "tile_ore_kcl": ("the dark violet stone tile with pale pink-white cubic KCl salt crystals in the center", None),
    "tile_crack": ("transparent overlay showing ONLY dark cracks (no soil), stage {i} of 4 from hairline cracks to almost shattered", None),
    "item_ore_iron": ("a single chunk of rust-red iron ore", None),
    "item_ore_sulfur": ("a single bright yellow sulfur crystal cluster", None),
    "item_ore_mg": ("a single silvery-white shiny magnesium chunk", None),
    "item_ore_kcl": ("a single pale pink-white cubic salt (KCl) crystal", None),
    "item_blast_charge": ("a sci-fi mining explosive charge with a blinking red light", None),
    "bld_base_normal": ("a compact armored sci-fi bunker base: half-dome metal shell with rust-orange plates and teal lights, a door at ground level, an EMPTY circular turret mount on top, flat bottom", None),
    "bld_base_damaged": ("the SAME bunker base as the attached image, now cracked and dented with small fires and smoke; keep exact shape and camera", None),
    "bld_base_destroyed": ("the SAME bunker base as the attached image, collapsed and burning ruins", None),
    "bld_base_upgraded": ("the SAME bunker base as the attached image with extra armor plates and brighter teal lights", None),
    "bld_turret_body": ("a turret rotating head/housing only, round armored, seen from the side, NO barrel", None),
    "bld_turret_barrel": ("a turret cannon BARREL only, horizontal, pointing RIGHT, thick sci-fi barrel with teal energy coils, round pivot joint at the LEFT end, nothing else", None),
    "bld_turret_fire": ("the SAME turret barrel as the attached image, recoil animation: barrel pushed back then returning", "recoil"),
    "bld_lift": ("a vertical mining-lift shaft frame segment (metal rails and cables), seamless top-to-bottom so it can repeat vertically", None),
    "bld_lift_cart": ("a small sci-fi ore cart/cage that rides the lift, filled with glowing ore", None),
    "bld_teleporter": ("a sci-fi teleporter pad with a rotating ring of teal energy", "energy ring spinning"),
    "proj_normal": ("a glowing white-cyan energy bolt flying RIGHT with a short trail", None),
    "proj_acid": ("a bubbling green acid glob flying RIGHT", None),
    "proj_fire": ("a blazing orange fire shell flying RIGHT with a flame trail", None),
    "proj_ice": ("an icy blue crystal shard flying RIGHT", None),
    "proj_enemy": ("a purple alien spit glob flying LEFT", None),
    "fx_block_break": ("small dirt and rock debris burst, growing then fading", "burst"),
    "fx_drill_spark": ("bright orange-yellow sparks spraying", "sparks"),
    "fx_muzzle_flash": ("cannon muzzle flash pointing RIGHT, teal-white", "flash"),
    "fx_explosion": ("cartoon explosion with fire and smoke, growing then fading", "explosion"),
    "fx_hit_normal": ("small white-cyan impact flash", "impact"),
    "fx_hit_acid": ("green acid splash", "splash"),
    "fx_hit_fire": ("orange fire burst", "burst"),
    "fx_hit_ice": ("ice shards shattering, light blue", "shatter"),
    "fx_status_poison": ("small floating green poison bubbles icon", "bubbling"),
    "fx_status_burn": ("small flickering flame icon", "flickering"),
    "fx_status_frozen": ("small snowflake icon, light blue", None),
    "fx_blast": ("big rock-blasting explosion with flying rocks", "explosion"),
    "fx_teleport": ("teal energy teleport swirl", "swirl"),
    "fx_deposit": ("ore chunks and sparkles being sucked into a point", "suck-in"),
    "bg_surface_sky": ("alien sky at dusk with two moons and violet clouds; fills the whole image", None),
    "bg_surface_far": ("distant alien rock spires silhouette along the bottom third; EVERYTHING above the silhouette fully transparent; tiles horizontally", None),
    "bg_surface_mid": ("mid-ground alien hills with strange plants along the bottom third; EVERYTHING above fully transparent; tiles horizontally", None),
    "bg_underground_far": ("dark underground cave wall, very low contrast, roots and faint crystals; seamless top-to-bottom", None),
    "bg_underground_mid": ("mid-depth cave layer with stalactites and glowing fungus, low contrast; seamless top-to-bottom", None),
    "ui_logo": ("game logo text 'UNDERLAB' in chunky sci-fi letters, a drill bit forming the letter U, teal and rust-orange", None),
    "ui_bg_mainmenu": ("main menu illustration: the miner standing next to the bunker base on an alien planet surface at dusk, cave tunnels visible below in a cross-section", None),
    "ui_screen_victory": ("victory screen illustration: the bunker base intact at sunrise, defeated alien queen in the distance", None),
    "ui_screen_gameover": ("game over illustration: the bunker base destroyed and smoking at night, alien beetles swarming", None),
}

GRID = {2: (2, 1), 3: (3, 1), 4: (2, 2), 5: (3, 2), 6: (3, 2), 8: (4, 2)}
ORDER = [("char", "Nhân vật"), ("enemy", "Quái"), ("boss", "Boss"), ("bld", "Base, pháo, thang máy"),
         ("tile", "Ô đất & quặng"), ("item", "Quặng rơi & item"), ("proj", "Đạn"), ("bg", "Nền"),
         ("ui", "Logo & màn hình"), ("fx", "Hiệu ứng (ưu tiên thấp — có thể làm bằng code)")]


def facing(r):
    if r["category"] in ("enemy", "boss"):
        return " Facing LEFT."
    if r["category"] in ("char",):
        return " Facing RIGHT."
    return ""


CREATURE = ("char", "enemy", "boss")


def is_first_anim(rid):
    return rid.endswith("_idle") or rid in ("enemy_melee_walk", "enemy_flying_fly", "enemy_ranged_walk")


ORE_BASE = {"tile_ore_iron": "tile_dirt_1", "tile_ore_sulfur": "tile_dirt_1",
            "tile_ore_mg": "tile_dirt_2", "tile_ore_kcl": "tile_dirt_3"}


def prompt(r):
    rid, cat, frames = r["id"], r["category"], int(r["frames"])
    desc, anim = D[rid]
    w, h = r["spec_px"].split("x")
    if rid in ORE_BASE:
        return (f"{STYLE}\nUse the attached plain soil tile as the base: {desc}. "
                "Keep the four edges identical to the attached tile so it tiles seamlessly next to it. "
                "Fills the whole square edge to edge, no border, no outline, 1:1.")
    if cat == "tile" and rid != "tile_crack":
        return (f"{STYLE}\nSeamless tileable SQUARE texture for a 2D side-view underground block: {desc}. "
                "Fills the whole square edge to edge, no border, no outline, uniform lighting, 1:1.")
    if rid == "tile_crack":
        return (f"{STYLE}\n4-frame sprite sheet in a 2x2 grid of equal square cells: transparent overlay showing ONLY "
                "dark cracks (no soil), each cell more cracked than the previous (hairline -> almost shattered). "
                "Transparent background, no grid lines.")
    if cat == "bg":
        bg = "" if rid == "bg_surface_sky" or rid.startswith("bg_underground") else ""
        return (f"{STYLE}\n2D parallax game background layer, 16:9: {desc}. "
                "Low detail and low contrast so gameplay sprites stay readable.")
    if cat == "ui":
        ratio = "2:1" if rid == "ui_logo" else "16:9"
        tr = " Transparent background." if rid == "ui_logo" else ""
        return f"{STYLE}\n{desc}. {ratio}.{tr}"
    f = facing(r)
    if frames == 1:
        kind = "Game sprite" if cat not in ("fx",) else "Game VFX sprite"
        return f"{STYLE}\n{kind}: {desc}.{f} Full view, centered, nothing else in the image. Transparent background."
    c, rr = GRID.get(frames, (frames, 1))
    feet = " Feet on the same baseline in every cell." if r["pivot"] == "bc" and cat in CREATURE else ""
    if cat in CREATURE and not is_first_anim(rid):
        subject = f"the SAME creature as the attached image ({desc})"
    else:
        subject = desc
    same = " Same size, proportions and colors in every cell." if cat != "fx" else ""
    cell = "square" if w == h else f"{int(w) // int(h)}:1 wide"
    unused = f" Leave the last {c * rr - frames} cell(s) empty." if c * rr > frames else ""
    return (f"{STYLE}\nSprite sheet: {subject}. {frames}-frame {anim} animation arranged in a {c}x{rr} grid "
            f"of equal {cell} cells, each frame centered in its cell.{same}{feet}{f} "
            f"No overlap, no grid lines, no numbers.{unused} Transparent background.")


out = []
out.append("""# Danh sách asset cần gen bằng ChatGPT

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

""")

total = {"P0": 0, "P1": 0, "P2": 0}
items = [r for r in rows if r["id"] in D]
missing = [r["id"] for r in rows if r["category"] not in ("icon",) and not (r["category"] == "ui" and r["id"] not in D) and r["id"] not in D]
assert not missing, missing
for r in items:
    total[r["priority"]] += 1
out.append(f"| Ưu tiên | Số lượng | Cần xong |\n|---|---|---|\n| P0 | {total['P0']} | **20/11** |\n| P1 | {total['P1']} | 27/11 |\n| P2 | {total['P2']} | 4/12 (có thì tốt) |\n\n")

out.append("## Bảng tổng\n\n| ✔ | Ưu tiên | id | Số frame | Ghi chú |\n|---|---|---|---|---|\n")
for cat, title in ORDER:
    for r in sorted([x for x in items if x["category"] == cat], key=lambda x: x["priority"]):
        fr = r["frames"] if int(r["frames"]) > 1 else "tĩnh"
        out.append(f"| [ ] | {r['priority']} | `{r['id']}` | {fr} | {title} |\n")

out.append("\n---\n\n## Prompt từng asset (copy nguyên khối)\n")
for cat, title in ORDER:
    group = sorted([x for x in items if x["category"] == cat], key=lambda x: (x["priority"], x["id"]))
    if not group:
        continue
    out.append(f"\n### {title}\n")
    for r in group:
        fr = int(r["frames"])
        meta = f"{r['priority']} · {'tĩnh' if fr == 1 else f'{fr} frame'}"
        att = ""
        if fr > 1 and cat in CREATURE and not is_first_anim(r["id"]):
            att = " · đính kèm ảnh walk/idle đã chọn"
        if r["id"].startswith("char_player") and r["id"] != "char_player_idle":
            att = " · đính kèm ảnh **char_player_idle** đã chọn"
        if "attached image" in D[r["id"]][0]:
            att = " · đính kèm ảnh gốc đã chọn (" + ("bld_base_normal" if "base" in r["id"] else "bld_turret_barrel") + ")"
        if r["id"] in ORE_BASE:
            att = f" · đính kèm ảnh **{ORE_BASE[r['id']]}** đã chọn"
        out.append(f"\n**`{r['id']}`** — {meta}{att}\n```\n{prompt(r)}\n```\n")

open(f"{ROOT}/Docs/06_ASSET_LIST_CHATGPT.md", "w", encoding="utf-8").write("".join(out))
print("ok", len(items), total)
