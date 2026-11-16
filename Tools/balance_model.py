#!/usr/bin/env python
"""
balance_model.py — Mô hình ước lượng cân bằng Underlab (KHÔNG thay được playtest, chỉ để chọn số hợp lý).

  python Tools/balance_model.py            # in bảng: số hiện tại vs số đề xuất
  python Tools/balance_model.py --apply    # ghi số ĐỀ XUẤT vào các asset trong Assets/_Game/Data

Mô hình:
  * Mật độ quặng: chạy lại thuật toán PlaceOres của TerrainGenerator (nhiều seed) => % ô là sắt/S/Mg/KCl theo độ sâu.
  * Thu nhập 1 pha đào: số chuyến = thời gian đào / thời gian 1 chuyến;
      1 chuyến = xuống (rơi) + khoan tìm đủ 1 túi + bay về (jetpack, chậm khi nặng) + đi tới base.
      Người chơi mua nâng cấp RẺ NHẤT trước bằng sắt dư (ưu tiên đào trước, rồi phòng thủ).
  * Phòng thủ: tổng máu quái mỗi wave / DPS pháo (có tính % trúng) => số giây cần bắn,
      so với thời gian quái đi tới base => quái đánh base bao lâu => base mất bao nhiêu máu.
"""
import os
import random
import re
import struct
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
DATA = os.path.join(ROOT, "Assets", "_Game", "Data")

# ----------------------------------------------------------------------------- số liệu cố định (đọc từ code/asset)
DRILL_DPS = 4.0                 # DrillConfig.damagePerSecond
LAYER_HP = [(1, 30, 2), (30, 70, 5), (70, 999, 10)]  # (từ, tới, HP ô)
FALL_SPEED = 10.0               # rơi tự do ~ maxFallSpeed thực tế
RISE_SPEED = 5.0                # PlayerConfig.maxRiseSpeed
WALK = 5.0
BASE_WALK_SECONDS = 2.0         # từ miệng hố tới base
LIFT_RISE = 6.0                 # cartSpeed
UP_MOVE = [1, 1.15, 1.3, 1.45, 1.6]
UP_DRILL = [1, 1.5, 2.2, 3, 4]
UP_CARRY = [0, 4, 8, 13, 20]
UP_JET = [1, 1.2, 1.4, 1.6, 1.8]
CARRY_BASE = 10
TURRET_DMG, TURRET_FIRE = 20.0, 0.3
TURRET_DMG_UP = 0.25
HIT_RATE = 0.6                  # % đạn trúng khi người chơi tự ngắm
ENEMY = {  # máu, tốc độ, tầm, giây/đòn, sát thương  (DefenseConfig.enemies)
    "melee": (40, 1.0, 2, 1.5, 8), "flying": (25, 2.0, 2, 1.5, 8),
    "ranged": (35, 1.0, 8, 1.5, 8), "boss": (1600, 0.6, 4, 1.5, 25),
}
SPAWN_DIST = 16.0
BASE_HP, BASE_HP_UP = 500, 100

ORES = [  # (tên, minDepth, maxDepth, veinChance, size min, size max) — TerrainConfig
    ("Fe", 2, 999, 0.03, 2, 5), ("S", 10, 80, 0.015, 2, 4),
    ("Mg", 30, 999, 0.012, 2, 4), ("KCl", 50, 999, 0.01, 2, 3),
]

# ----------------------------------------------------------------------------- 2 bộ số

CURRENT = dict(
    mining=[90] * 10,
    waves=[(5, 0, 0, 0, 1.0, 1.0, 1.5)] * 10,   # melee, flying, ranged, boss, hpScale, speedScale, spawnDelay
    costs=dict(drill=[5, 10, 20, 35], move=[5, 10, 20, 35], carry=[5, 10, 20, 35], jetpack=[5, 10, 20, 35],
               lift=[20], turret_damage=[5, 10, 20, 35, 50], turret_rotate=[5, 10, 20, 35, 50],
               base_hp=[5, 10, 20, 35, 50]),
)

PROPOSED = dict(
    # Run ~18 phút: pha đào ngắn lúc đầu (ít thứ để mua), dài dần khi phải đào sâu
    mining=[60, 65, 70, 70, 75, 75, 80, 80, 85, 90],
    waves=[
        (4, 0, 0, 0, 1.00, 1.00, 2.0),
        (6, 0, 0, 0, 1.10, 1.00, 1.8),
        (6, 2, 0, 0, 1.20, 1.05, 1.6),
        (7, 3, 1, 0, 1.35, 1.05, 1.5),
        (8, 3, 2, 0, 1.50, 1.10, 1.4),
        (9, 4, 3, 0, 1.70, 1.10, 1.3),
        (10, 5, 3, 0, 1.90, 1.15, 1.2),
        (12, 6, 4, 0, 2.10, 1.15, 1.1),
        (14, 7, 5, 0, 2.40, 1.20, 1.0),
        (6, 4, 3, 1, 1.70, 1.20, 1.4),   # wave 10: BOSS + ít quái phụ (boss tự gọi thêm)
    ],
    costs=dict(drill=[8, 16, 30, 50], move=[6, 12, 22, 36], carry=[8, 16, 30, 50], jetpack=[6, 12, 22, 36],
               lift=[30], turret_damage=[8, 16, 28, 45, 65], turret_rotate=[6, 12, 22, 35, 50],
               base_hp=[10, 20, 35, 55, 80]),
)


# ----------------------------------------------------------------------------- mật độ quặng

def ore_density(width=40, depth=120, seeds=40):
    """% ô là từng loại quặng theo hàng độ sâu (trung bình nhiều seed) — port của PlaceOres."""
    acc = {o[0]: [0.0] * (depth + 1) for o in ORES}
    for seed in range(seeds):
        rng = random.Random(seed)
        grid = {}
        for name, mn, mx, chance, smin, smax in ORES:
            for iy in range(max(1, mn), min(depth - 1, mx) + 1):
                for ix in range(1, width + 1):
                    if rng.random() >= chance:
                        continue
                    x, y = ix, iy
                    for _ in range(rng.randint(smin, smax)):
                        if 1 <= x <= width and 1 <= y < depth:
                            grid[(x, y)] = name
                        d = rng.randrange(4)
                        x += (d == 0) - (d == 1)
                        y += (d == 2) - (d == 3)
        for (x, y), name in grid.items():
            acc[name][y] += 1
    return {k: [c / (seeds * width) for c in v] for k, v in acc.items()}


def band(dens, a, b):
    return sum(dens[a:b]) / max(1, b - a)


def tile_hp(d):
    for a, b, hp in LAYER_HP:
        if a <= d < b:
            return hp
    return 10


# ----------------------------------------------------------------------------- kinh tế

def income_one_phase(seconds, lv, dens_fe, lift):
    """Sắt kiếm được trong 1 pha đào (người chơi tập trung sắt ở tầng 2..25)."""
    cap = CARRY_BASE + UP_CARRY[lv["carry"]]
    depth = 8 + 2 * lv["drill"]                         # nâng khoan => dám xuống sâu hơn chút
    p = band(dens_fe, 2, depth + 6)
    tiles_per_ore = 0.5 / max(p, 1e-3) + 1             # mạch quặng gom cụm => ~1/2 số ô phải phá
    t_tile = tile_hp(depth) / (DRILL_DPS * UP_DRILL[lv["drill"]]) + 0.25 / UP_MOVE[lv["move"]]
    dig = cap * tiles_per_ore * t_tile * 0.35            # đã khoan sẵn hầm từ chuyến trước => ~35%
    down = depth / FALL_SPEED
    up = depth / LIFT_RISE if lift else depth / (RISE_SPEED * UP_JET[lv["jetpack"]] * 0.8)
    trip = down + dig + up + BASE_WALK_SECONDS / UP_MOVE[lv["move"]]
    trips = seconds / trip
    return trips * cap, trip


def simulate(cfg, dens):
    lv = dict(drill=0, move=0, carry=0, jetpack=0, turret_damage=0, turret_rotate=0, base_hp=0)
    lift = False
    bank = 0
    rows = []
    spent_total = 0
    order_mining = ["drill", "carry", "move", "jetpack"]
    order_def = ["turret_damage", "base_hp", "turret_rotate"]
    for w in range(10):
        inc, trip = income_one_phase(cfg["mining"][w], lv, dens["Fe"], lift)
        bank += inc
        bought = []
        # mua: rẻ nhất trước, xen kẽ đào/phòng thủ; lift khi đủ tiền từ wave 3
        while True:
            options = []
            for k in order_mining + order_def:
                costs = cfg["costs"][k]
                if lv[k] < len(costs) and (k not in order_mining or lv[k] < 4):
                    options.append((costs[lv[k]], k))
            if not lift and w >= 2:
                options.append((cfg["costs"]["lift"][0], "lift"))
            if not options:
                break
            price, k = min(options)
            if price > bank:
                break
            bank -= price
            spent_total += price
            if k == "lift":
                lift = True
            else:
                lv[k] += 1
            bought.append(k)
        rows.append(dict(w=w + 1, mine=cfg["mining"][w], trip=trip, inc=inc, bank=bank,
                         lv=dict(lv), lift=lift, bought=bought))
    return rows


# ----------------------------------------------------------------------------- phòng thủ

def defense(cfg, rows):
    out = []
    for i, (m, f, r, b, hp_s, sp_s, delay) in enumerate(cfg["waves"]):
        lv = rows[i]["lv"]
        dps = TURRET_DMG * (1 + TURRET_DMG_UP * lv["turret_damage"]) / TURRET_FIRE * HIT_RATE
        counts = dict(melee=m, flying=f, ranged=r, boss=b)
        total_hp = sum(ENEMY[k][0] * n * hp_s for k, n in counts.items())
        n_total = m + f + r + b
        spawn_time = n_total * delay
        kill_time = total_hp / dps
        # quái tới base sau (khoảng cách - tầm)/tốc độ; ước lượng số quái "còn sống ở base" theo thời gian
        walk = min((SPAWN_DIST - ENEMY[k][2]) / (ENEMY[k][1] * sp_s) for k, n in counts.items() if n > 0)
        pressure = max(0.0, kill_time - walk - spawn_time * 0.3)   # giây có quái đứng đánh base
        avg_attack_dps = sum(ENEMY[k][4] / ENEMY[k][3] * n for k, n in counts.items()) / max(1, n_total) * min(n_total, 3)
        base_dmg = pressure * avg_attack_dps
        base_max = BASE_HP + BASE_HP_UP * lv["base_hp"]
        out.append(dict(w=i + 1, n=n_total, hp=total_hp, dps=dps, kill=kill_time, walk=walk,
                        dmg=base_dmg, base=base_max, boss=b))
    return out


def report(name, cfg, dens):
    rows = simulate(cfg, dens)
    dfs = defense(cfg, rows)
    print(f"\n==================== {name} ====================")
    print("wave | đào(s) | 1 chuyến(s) | sắt kiếm | dư | quái | tổng máu | DPS pháo | cần bắn(s) | base mất ~ / max | đã mua")
    total = 0
    for r, d in zip(rows, dfs):
        total += r["mine"] + max(15, d["kill"] + 8)
        print(f"{r['w']:>4} | {r['mine']:>6} | {r['trip']:>11.1f} | {r['inc']:>8.0f} | {r['bank']:>3.0f} | {d['n']:>4}{'+B' if d['boss'] else '  '}"
              f" | {d['hp']:>8.0f} | {d['dps']:>8.0f} | {d['kill']:>10.1f} | {d['dmg']:>6.0f} / {d['base']:<5} | {','.join(r['bought'])}")
    print(f"Thời gian 1 run ~ {total / 60:.1f} phút (đào + phòng thủ ước lượng)")
    return rows, dfs


# ----------------------------------------------------------------------------- ghi asset

def ints_hex(v):
    return struct.pack("<%di" % len(v), *v).hex()


def apply(cfg):
    # giá upgrade
    for k, costs in cfg["costs"].items():
        path = os.path.join(DATA, "Defense", f"{k}.asset")
        s = open(path, encoding="utf-8").read()
        s = re.sub(r"ironCosts: \w*", "ironCosts: " + ints_hex(costs), s)
        open(path, "w", encoding="utf-8", newline="\n").write(s)
    for k, price in (("blast", [6]), ("repair", [8])):
        path = os.path.join(DATA, "Defense", f"{k}.asset")
        s = open(path, encoding="utf-8").read()
        s = re.sub(r"ironCosts: \w*", "ironCosts: " + ints_hex(price), s)
        open(path, "w", encoding="utf-8", newline="\n").write(s)
    # wave
    path = os.path.join(DATA, "Defense", "WaveConfig.asset")
    s = open(path, encoding="utf-8").read()
    head = s[: s.index("  waves:")]
    body = "  waves:\n"
    for (m, f, r, b, hp, sp, dl), mine in zip(cfg["waves"], cfg["mining"]):
        body += (f"  - miningSeconds: {mine}\n    spawnDelay: {dl}\n    melee: {m}\n    flying: {f}\n"
                 f"    ranged: {r}\n    bosses: {b}\n    healthScale: {hp}\n    speedScale: {sp}\n")
    open(path, "w", encoding="utf-8", newline="\n").write(head + body)
    print("Đã ghi giá upgrade (+ blast 6, repair 8) và 10 wave vào Assets/_Game/Data/Defense/.")


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    dens = ore_density()
    print("Mật độ quặng (% ô) theo dải độ sâu:")
    for a, b in ((2, 10), (10, 30), (30, 50), (50, 80), (80, 120)):
        print(f"  {a:>3}-{b:<3}: " + "  ".join(f"{k} {band(v, a, b) * 100:4.1f}%" for k, v in dens.items()))
    report("HIỆN TẠI", CURRENT, dens)
    report("ĐỀ XUẤT", PROPOSED, dens)
    if "--apply" in sys.argv:
        apply(PROPOSED)


if __name__ == "__main__":
    main()
