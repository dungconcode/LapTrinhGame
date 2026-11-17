#!/usr/bin/env python
"""
import_ai_batch.py — Đưa ảnh AI (bàn giao dạng 04_AI_Candidates/<id>/chon.png) vào game hàng loạt.

  # xem trước (không đụng Unity): xuất ra thư mục preview + ảnh kiểm tra
  python Tools/import_ai_batch.py <thư_mục_04_AI_Candidates> --priority P0 --preview <thư_mục_preview>

  # import thật: ghi Assets/_Game/Art/<category>/<id>.png + status=ai trong manifest
  python Tools/import_ai_batch.py <thư_mục_04_AI_Candidates> --priority P0
  python Tools/import_ai_batch.py <thư_mục> --ids char_player_walk enemy_melee_walk

Thông số từng nhóm ở OVERRIDES (fill, pivot khi xử lý, ...). Ảnh nguồn không bị sửa.
"""
import argparse
import csv
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, ".."))
sys.path.insert(0, HERE)
import ai_sheet  # noqa: E402

MANIFEST = os.path.join(ROOT, "Assets", "_Game", "Art", "asset_manifest.csv")

# Thông số mặc định theo category, sau đó ghi đè theo id
BY_CATEGORY = {
    # nhân vật/quái/boss: chuẩn hoá theo chiều cao thân => mọi animation cùng cỡ
    "char": dict(fill=0.72, fit="height"),   # phải chui lọt hầm 1 ô => chừa lề rộng
    "enemy": dict(fill=0.62, fit="height"),
    "boss": dict(fill=0.7, fit="height"),
    "item": dict(fill=0.85),
    "proj": dict(fill=0.9),
    "fx": dict(fill=0.95, auto=False, use_grid=True),   # hạt rời rạc (tia lửa, mảnh băng) => cắt theo lưới
    "bld": dict(fill=0.92),
}
OVERRIDES = {
    "bld_turret_barrel": dict(pivot="lc"),   # khớp xoay ở mép trái ảnh => đặt sát trái (manifest giữ 0.15;0.5)
    "bld_turret_fire": dict(pivot="lc"),
    "tile_crack": dict(fill=1.0),
    "enemy_ranged_attack": dict(auto=False, grid="3x2"),  # cục axit nối 2 frame => cắt theo lưới
    "char_player_carry": dict(cut=110, auto=False, use_grid=True),  # quầng trắng nối các frame => cắt lưới
    "boss_death": dict(auto=False, use_grid=True),  # mảnh vỡ nối các frame => cắt lưới
    "proj_enemy": dict(flip=True),               # vẽ chĩa trái; code xoay đạn theo hướng bay => phải chĩa PHẢI
    "bg_surface_far": dict(crop_bottom=0.74),    # bỏ lát cắt hang ngầm dưới đường chân trời
    "bg_surface_mid": dict(crop_bottom=0.68),
    "enemy_ranged_": dict(fill=0.8),   # key kết thúc bằng "_" = áp cho mọi id bắt đầu như vậy (dáng cao gầy)
    "fx_status_poison": dict(fill=0.8),
    "fx_status_burn": dict(fill=0.8),
    "fx_status_frozen": dict(fill=0.8),
}


def manifest_rows():
    with open(MANIFEST, encoding="utf-8") as f:
        return list(csv.DictReader(f))


def set_status(ids, status="ai"):
    with open(MANIFEST, encoding="utf-8") as f:
        lines = f.read().splitlines()
    out = []
    for i, line in enumerate(lines):
        c = line.split(",")
        if i > 0 and c and c[0] in ids:
            c[9] = status
        out.append(",".join(c))
    with open(MANIFEST, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out) + "\n")


def settings_for(row):
    s = dict(auto=True, cut=40, fill=0.9, pivot=None, grid=None, fit="box", use_grid=False,
             flip=False, crop_bottom=None)
    s.update(BY_CATEGORY.get(row["category"], {}))
    for key, val in OVERRIDES.items():          # theo tiền tố trước, id cụ thể sau
        if key.endswith("_") and row["id"].startswith(key):
            s.update(val)
    s.update(OVERRIDES.get(row["id"], {}))
    return s


def preview_sheet(results, path):
    """Ảnh kiểm tra: mỗi asset 1 dòng, frame trên nền ca-rô; tile ghép 3x3 để soi đường nối."""
    from PIL import Image, ImageDraw
    rows_h, pad = 150, 8
    width = 1500
    sheet = Image.new("RGB", (width, rows_h * len(results) + pad), (28, 28, 38))
    d = ImageDraw.Draw(sheet)
    for i, (rid, img, n, kind) in enumerate(results):
        y = i * rows_h + pad
        d.text((8, y + 4), f"{rid}  ({n} frame)", fill=(255, 255, 120))
        if kind == "tile":
            tiled = Image.new("RGBA", (img.width * 3, img.height * 3))
            for tx in range(3):
                for ty in range(3):
                    tiled.paste(img, (tx * img.width, ty * img.height))
            show = tiled
        else:
            show = img
        show = show.copy()
        show.thumbnail((width - 20, rows_h - 30))
        bg = Image.new("RGBA", show.size)
        bd = ImageDraw.Draw(bg)
        for yy in range(0, show.height, 10):
            for xx in range(0, show.width, 10):
                bd.rectangle([xx, yy, xx + 9, yy + 9], fill=(190, 190, 190, 255) if (xx // 10 + yy // 10) % 2 else (140, 140, 140, 255))
        bg.alpha_composite(show)
        if n > 1:  # vạch phân frame
            fwp = show.width / n
            for k in range(1, n):
                bd2 = ImageDraw.Draw(bg)
                bd2.line([(k * fwp, 0), (k * fwp, show.height)], fill=(255, 0, 0, 255), width=1)
            # đường baseline (đáy frame - 1/64)
        sheet.paste(bg.convert("RGB"), (10, y + 22))
    sheet.save(path)
    return path


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("candidates", help="thư mục 04_AI_Candidates (chứa <id>/chon.png)")
    ap.add_argument("--priority", help="P0 | P1 | P2")
    ap.add_argument("--ids", nargs="*", help="danh sách id cụ thể")
    ap.add_argument("--preview", help="chỉ xuất xem trước vào thư mục này, không ghi vào Unity")
    ap.add_argument("--source", default="chon.png", help="tên file trong mỗi thư mục id")
    a = ap.parse_args()

    rows = {r["id"]: r for r in manifest_rows()}
    cand_grid = {}
    cand_manifest = os.path.join(a.candidates, "MANIFEST.csv")
    if os.path.exists(cand_manifest):
        with open(cand_manifest, encoding="utf-8-sig") as f:
            cand_grid = {r["Id"]: r.get("Grid", "") for r in csv.DictReader(f)}
    import tempfile
    from PIL import Image, ImageOps
    tmp_dir = tempfile.mkdtemp(prefix="underlab_ai_")
    # icon/khung UI vẽ bằng SVG (Tools/ui_svg) => không lấy từ ảnh AI
    ids = a.ids or [r for r in rows if (not a.priority or rows[r]["priority"] == a.priority)
                    and rows[r]["ai_tool"] != "CLA"]
    results, done, missing = [], [], []
    for rid in ids:
        src = os.path.join(a.candidates, rid, a.source)
        if rid not in rows or not os.path.exists(src):
            missing.append(rid)
            continue
        row = rows[rid]
        st = settings_for(row)
        if a.preview:
            os.makedirs(a.preview, exist_ok=True)
            out = os.path.join(a.preview, rid + ".png")
        else:
            out_dir = os.path.join(ROOT, "Assets", "_Game", "Art", row["category"])
            os.makedirs(out_dir, exist_ok=True)
            out = os.path.join(out_dir, rid + ".png")
        if st["use_grid"] and cand_grid.get(rid):
            st["grid"] = cand_grid[rid]
        if st["flip"] or st["crop_bottom"]:
            im = Image.open(src)
            if st["crop_bottom"]:
                im = im.crop((0, 0, im.width, int(im.height * st["crop_bottom"])))
            if st["flip"]:
                im = ImageOps.mirror(im)
            src = os.path.join(tmp_dir, rid + ".png")
            im.save(src)
        img, n = ai_sheet.process([src], out, art_id=rid, pivot=st["pivot"], fill=st["fill"], grid=st["grid"], fit=st["fit"],
                                  auto=st["auto"], cut=st["cut"])
        kind = "tile" if row["type"] == "tile" else "sprite"
        results.append((rid, img, n, kind))
        done.append(rid)
        flag = "" if n == int(row["frames"]) else f"  [!] cần {row['frames']} frame"
        print(f"OK {rid:24} {img.width}x{img.height} {n} frame{flag}")

    if a.preview and results:
        print("Xem trước:", preview_sheet(results, os.path.join(a.preview, "_check.png")))
    elif done:
        set_status(set(done), "ai")
        print(f"Đã ghi {len(done)} asset vào Assets/_Game/Art và đặt status=ai trong manifest.")
    if missing:
        print("Không có ảnh nguồn:", ", ".join(missing))


if __name__ == "__main__":
    main()
