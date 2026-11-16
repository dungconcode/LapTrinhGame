#!/usr/bin/env python
"""
ai_sheet.py - Biến ảnh AI (ChatGPT / Gemini) thành PNG đúng chuẩn Underlab để chép thẳng vào Unity.

Việc nó làm:
  1. Xoá nền màu đơn (magenta #FF00FF mặc định) -> trong suốt  (bỏ qua nếu ảnh đã trong suốt)
  2. Cắt ảnh grid (vd AI vẽ 6 frame trong lưới 3x2) thành từng frame
     hoặc nhận nhiều file, mỗi file = 1 frame
  3. Trim khoảng trống, scale ĐỀU mọi frame, căn theo pivot (bc = chân chạm đáy, c = giữa)
  4. Ghép thành DẢI NGANG đúng kích thước frame trong asset_manifest.csv

Cài:   pip install pillow
Ví dụ:
  # 1 ảnh tĩnh nền magenta -> sprite 512x512 chân chạm đáy
  python Tools/ai_sheet.py base.png -o bld_base_normal.png --frame 512x512 --pivot bc

  # ảnh AI vẽ 6 frame lưới 3 cột x 2 hàng -> dải 6 frame 256x256
  python Tools/ai_sheet.py walk_grid.png --grid 3x2 --frames 6 --frame 256x256 -o enemy_melee_walk.png

  # 4 file rời là 4 frame
  python Tools/ai_sheet.py f1.png f2.png f3.png f4.png --frame 256x256 -o char_player_idle.png

  # tile: không xoá nền, cắt vuông giữa ảnh, phủ kín 128x128
  python Tools/ai_sheet.py dirt.png --mode tile --frame 128x128 -o tile_dirt_1.png

  # Dùng spec trong manifest luôn (frame size, frames, pivot) theo id:
  python Tools/ai_sheet.py walk_grid.png --grid 3x2 --id enemy_melee_walk
"""
import argparse
import csv
import os
import sys

try:
    from PIL import Image
except ImportError:
    sys.exit("Thiếu Pillow: pip install pillow")

HERE = os.path.dirname(os.path.abspath(__file__))
MANIFEST = os.path.join(HERE, "..", "Assets", "_Game", "Art", "asset_manifest.csv")
PIVOTS = {"bc": (0.5, 0.0), "c": (0.5, 0.5), "tc": (0.5, 1.0), "lc": (0.0, 0.5), "rc": (1.0, 0.5), "bl": (0.0, 0.0)}


def parse_wh(s):
    w, h = s.lower().split("x")
    return int(w), int(h)


def parse_pivot(s):
    if s in PIVOTS:
        return PIVOTS[s]
    x, y = s.split(";")
    return float(x), float(y)


def load_manifest_entry(art_id):
    with open(MANIFEST, encoding="utf-8") as f:
        for row in csv.DictReader(f):
            if row["id"].strip() == art_id:
                return row
    sys.exit(f"Không thấy id '{art_id}' trong {MANIFEST}")


def has_transparency(img):
    return img.mode == "RGBA" and img.getextrema()[3][0] < 250


def key_out(img, key_rgb, tol):
    """Xoá nền màu key; viền mềm trong khoảng tol..tol*1.6, và khử viền màu key (despill)."""
    img = img.convert("RGBA")
    px = img.load()
    kr, kg, kb = key_rgb
    soft = tol * 1.6
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            d = ((r - kr) ** 2 + (g - kg) ** 2 + (b - kb) ** 2) ** 0.5
            if d < tol:
                px[x, y] = (0, 0, 0, 0)
            elif d < soft:
                k = (d - tol) / (soft - tol)
                # despill: kéo màu ra xa màu key
                r2 = int(min(255, max(0, (r - kr * (1 - k)) / max(k, 0.01))))
                g2 = int(min(255, max(0, (g - kg * (1 - k)) / max(k, 0.01))))
                b2 = int(min(255, max(0, (b - kb * (1 - k)) / max(k, 0.01))))
                px[x, y] = (r2, g2, b2, int(a * k))
    return img


def split_grid(img, cols, rows, count):
    cw, ch = img.width // cols, img.height // rows
    cells = []
    for r in range(rows):
        for c in range(cols):
            cells.append(img.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch)))
    return cells[:count] if count else cells


def trim(img):
    bbox = img.getchannel("A").point(lambda a: 255 if a > 10 else 0).getbbox()
    return img.crop(bbox) if bbox else img


def build_strip(frames, fw, fh, pivot, fill):
    frames = [trim(f) for f in frames]
    max_w = max(f.width for f in frames)
    max_h = max(f.height for f in frames)
    scale = min(fw * fill / max_w, fh * fill / max_h)  # scale chung => frame không bị to nhỏ lệch nhau
    strip = Image.new("RGBA", (fw * len(frames), fh), (0, 0, 0, 0))
    px, py = pivot
    margin_x = int(fw * (1 - fill) / 2)
    margin_y = int(fh * (1 - fill) / 2)
    for i, f in enumerate(frames):
        f = f.resize((max(1, round(f.width * scale)), max(1, round(f.height * scale))), Image.LANCZOS)
        # x: đặt tâm sprite tại pivot.x (kẹp trong lề)
        x = int(px * fw - f.width / 2) if 0 < px < 1 else (margin_x if px == 0 else fw - margin_x - f.width)
        x = max(0, min(fw - f.width, x))
        # y (PIL tính từ trên xuống): pivot.y = 0 -> chân chạm đáy frame
        if py <= 0.01:
            y = fh - f.height - max(1, fh // 64)
        elif py >= 0.99:
            y = margin_y
        else:
            y = int((1 - py) * fh - f.height / 2)
        y = max(0, min(fh - f.height, y))
        strip.alpha_composite(f, (i * fw + x, y))
    return strip


def make_tile(img, fw, fh):
    img = img.convert("RGBA")
    side = min(img.width, img.height)
    left, top = (img.width - side) // 2, (img.height - side) // 2
    return img.crop((left, top, left + side, top + side)).resize((fw, fh), Image.LANCZOS)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("inputs", nargs="+", help="1 ảnh (grid hoặc tĩnh) hoặc nhiều ảnh = nhiều frame")
    ap.add_argument("-o", "--out", help="file output (mặc định <id>.png)")
    ap.add_argument("--id", help="lấy frame size / frames / pivot / mode từ asset_manifest.csv")
    ap.add_argument("--grid", help="CxR, vd 3x2")
    ap.add_argument("--frames", type=int, help="số frame lấy từ grid (mặc định = C*R)")
    ap.add_argument("--frame", help="kích thước 1 frame WxH, vd 256x256")
    ap.add_argument("--pivot", default=None, help="bc | c | tc | lc | rc | bl | x;y")
    ap.add_argument("--mode", choices=["sprite", "tile"], default=None)
    ap.add_argument("--key", default="ff00ff", help="màu nền cần xoá (hex), 'none' để bỏ qua")
    ap.add_argument("--tol", type=float, default=90, help="độ lệch màu nền chấp nhận")
    ap.add_argument("--fill", type=float, default=0.9, help="sprite chiếm bao nhiêu % frame (0.9 = chừa 5%% mỗi bên)")
    a = ap.parse_args()

    frame, pivot, mode, frames = a.frame, a.pivot, a.mode, a.frames
    if a.id:
        row = load_manifest_entry(a.id)
        frame = frame or row["spec_px"]
        pivot = pivot or row["pivot"]
        frames = frames or int(row["frames"])
        mode = mode or ("tile" if row["type"] == "tile" else "sprite")
    if not frame:
        sys.exit("Cần --frame WxH hoặc --id")
    fw, fh = parse_wh(frame)
    mode = mode or "sprite"
    out = a.out or (a.id + ".png" if a.id else "out.png")

    imgs = [Image.open(p) for p in a.inputs]

    if mode == "tile":
        strip = make_tile(imgs[0], fw, fh)
    else:
        key = None if a.key.lower() == "none" else tuple(int(a.key[i:i + 2], 16) for i in (0, 2, 4))
        prepared = []
        for im in imgs:
            im = im.convert("RGBA")
            if key and not has_transparency(im):
                im = key_out(im, key, a.tol)
            prepared.append(im)
        if a.grid:
            cols, rows = parse_wh(a.grid)
            cells = split_grid(prepared[0], cols, rows, frames)
        else:
            cells = prepared
        if frames and len(cells) != frames:
            print(f"[!] Có {len(cells)} frame nhưng manifest/--frames = {frames}", file=sys.stderr)
        strip = build_strip(cells, fw, fh, parse_pivot(pivot or "c"), a.fill)

    strip.save(out)
    print(f"OK -> {out}  ({strip.width}x{strip.height}, {strip.width // fw} frame {fw}x{fh})")


if __name__ == "__main__":
    main()
