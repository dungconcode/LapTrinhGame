#!/usr/bin/env python
"""
make_ui_svg.py — Vẽ icon + khung UI của Underlab bằng SVG, rồi render ra PNG bằng Chrome headless.

  python Tools/ui_svg/make_ui_svg.py            # vẽ + render tất cả
  python Tools/ui_svg/make_ui_svg.py icon_blast # chỉ 1 vài id
  python Tools/ui_svg/make_ui_svg.py --sheet    # thêm ảnh tổng hợp Tools/ui_svg/contact_sheet.png để xem nhanh

- SVG gốc lưu ở Tools/ui_svg/src/<id>.svg (nhóm art có thể mở bằng Inkscape/Figma để sửa).
- PNG ghi đè vào Assets/_Game/Art/<ui|icon>/<id>.png đúng kích thước spec trong manifest.
- Màu lấy theo bảng màu chung (PAL). Đổi màu toàn bộ UI = sửa PAL rồi chạy lại.
"""
import csv
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
SRC = os.path.join(HERE, "src")
MANIFEST = os.path.join(ROOT, "Assets", "_Game", "Art", "asset_manifest.csv")
CHROME = [r"C:\Program Files\Google\Chrome\Application\chrome.exe",
          r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"]

PAL = dict(
    ink="#16132B",      # viền tối
    navy="#1E1B3A",     # nền panel
    navy2="#2C2758",    # nền sáng hơn
    teal="#3FE0D0",
    teal_d="#1F8F86",
    rust="#E07A3F",
    rust_d="#A9502A",
    gold="#F2D35B",
    gold_l="#FFF1A8",
    red="#FF5A4A",
    white="#F4F1FF",
    grey="#8C8AA8",
    green="#6BE04F",
    ice="#9BE7FF",
)
OUT = 6  # độ dày viền icon


def svg(w, h, body, defs=""):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'
            f'<defs>{defs}</defs>{body}</svg>')


def grad(gid, c1, c2, vertical=True):
    x2, y2 = ("0", "1") if vertical else ("1", "0")
    return (f'<linearGradient id="{gid}" x1="0" y1="0" x2="{x2}" y2="{y2}">'
            f'<stop offset="0" stop-color="{c1}"/><stop offset="1" stop-color="{c2}"/></linearGradient>')


def chamfer(x, y, w, h, c):
    """Hình chữ nhật vát 4 góc (kiểu sci-fi)."""
    return (f"M{x+c},{y} L{x+w-c},{y} L{x+w},{y+c} L{x+w},{y+h-c} L{x+w-c},{y+h} "
            f"L{x+c},{y+h} L{x},{y+h-c} L{x},{y+c} Z")


def S(**kw):
    """stroke chuẩn cho icon"""
    st = dict(stroke=PAL["ink"], stroke_width=OUT, stroke_linejoin="round", stroke_linecap="round")
    st.update(kw)
    return " ".join(f'{k.replace("_", "-")}="{v}"' for k, v in st.items())


def up_badge():
    """Mũi tên nâng cấp vàng ở góc phải dưới (dùng chung cho icon_up_*)."""
    return (f'<circle cx="100" cy="100" r="22" fill="{PAL["gold"]}" {S()}/>'
            f'<path d="M100 86 L112 101 L104 101 L104 113 L96 113 L96 101 L88 101 Z" fill="{PAL["ink"]}"/>')


# ----------------------------------------------------------------------------- UI

def ui_panel(w, h):
    d = grad("g", PAL["navy2"], PAL["navy"])
    body = (f'<path d="{chamfer(6, 6, w-12, h-12, 26)}" fill="url(#g)" fill-opacity="0.94" '
            f'stroke="{PAL["teal_d"]}" stroke-width="4"/>'
            f'<path d="{chamfer(16, 16, w-32, h-32, 18)}" fill="none" stroke="{PAL["teal"]}" stroke-opacity="0.35" stroke-width="2"/>')
    # góc nhấn
    for (x, y, sx, sy) in [(6, 6, 1, 1), (w-6, 6, -1, 1), (6, h-6, 1, -1), (w-6, h-6, -1, -1)]:
        body += (f'<path d="M{x} {y+sy*40} L{x} {y+sy*26} L{x+sx*26} {y} L{x+sx*40} {y}" fill="none" '
                 f'stroke="{PAL["teal"]}" stroke-width="6" stroke-linecap="round"/>')
    return svg(w, h, body, d)


def ui_button(w, h, pressed=False):
    top, bot = (PAL["navy"], "#15122B") if pressed else ("#3A3478", PAL["navy2"])
    edge = PAL["gold"] if pressed else PAL["teal"]
    d = grad("g", top, bot)
    off = 3 if pressed else 0
    body = (f'<path d="{chamfer(4, 4+off, w-8, h-10, 16)}" fill="#0C0A1A" fill-opacity="0.6"/>'
            f'<path d="{chamfer(4, 2+off, w-8, h-10, 16)}" fill="url(#g)" stroke="{edge}" stroke-width="4"/>')
    if not pressed:
        body += f'<path d="M24 {12} L{w-24} 12" stroke="#FFFFFF" stroke-opacity="0.25" stroke-width="4" stroke-linecap="round"/>'
    return svg(w, h, body, d)


def ui_bar_frame(w, h):
    body = (f'<path d="{chamfer(3, 3, w-6, h-6, 14)}" fill="#0C0A1A" fill-opacity="0.85" '
            f'stroke="{PAL["teal_d"]}" stroke-width="4"/>'
            f'<path d="{chamfer(3, 3, w-6, h-6, 14)}" fill="none" stroke="{PAL["teal"]}" stroke-width="2" stroke-opacity="0.6"/>')
    for x in (w * 0.25, w * 0.5, w * 0.75):
        body += f'<path d="M{x} 6 L{x} 14 M{x} {h-14} L{x} {h-6}" stroke="{PAL["teal"]}" stroke-opacity="0.5" stroke-width="3"/>'
    return svg(w, h, body)


def ui_bar_fill(w, h):
    # TRẮNG để code tô màu; dải sáng phía trên cho có khối
    d = grad("g", "#FFFFFF", "#CFCFE0")
    body = (f'<rect x="0" y="0" width="{w}" height="{h}" rx="{h*0.3}" fill="url(#g)"/>'
            f'<rect x="{h*0.3}" y="{h*0.14}" width="{w-h*0.6}" height="{h*0.18}" rx="{h*0.09}" fill="#FFFFFF" fill-opacity="0.7"/>')
    return svg(w, h, body, d)


def ui_wave_timer(w, h):
    c = w / 2
    body = (f'<circle cx="{c}" cy="{c}" r="{c-8}" fill="{PAL["navy"]}" fill-opacity="0.92" stroke="{PAL["teal_d"]}" stroke-width="6"/>'
            f'<circle cx="{c}" cy="{c}" r="{c-44}" fill="none" stroke="{PAL["ink"]}" stroke-width="4"/>')
    import math
    for i in range(12):
        a = i * math.pi / 6
        r1, r2 = c - 18, c - (30 if i % 3 == 0 else 24)
        body += (f'<line x1="{c+r1*math.sin(a):.1f}" y1="{c-r1*math.cos(a):.1f}" x2="{c+r2*math.sin(a):.1f}" '
                 f'y2="{c-r2*math.cos(a):.1f}" stroke="{PAL["teal"]}" stroke-width="{5 if i % 3 == 0 else 3}" stroke-linecap="round"/>')
    return svg(w, h, body)


def ui_wave_timer_fill(w, h):
    c = w / 2
    # vòng trắng đặt đúng giữa các vạch của ui_wave_timer
    return svg(w, h, f'<circle cx="{c}" cy="{c}" r="{c-30}" fill="none" stroke="#FFFFFF" stroke-width="30"/>')


def ui_wave_warning(w, h):
    d = grad("g", "#D23A2E", "#8E1F1A")
    pat = (f'<pattern id="hz" width="28" height="28" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">'
           f'<rect width="14" height="28" fill="{PAL["gold"]}"/><rect x="14" width="14" height="28" fill="{PAL["ink"]}"/></pattern>')
    body = (f'<path d="{chamfer(4, 8, w-8, h-16, 22)}" fill="url(#g)" stroke="{PAL["ink"]}" stroke-width="6"/>'
            f'<path d="{chamfer(10, 14, 52, h-28, 10)}" fill="url(#hz)"/>'
            f'<path d="{chamfer(w-62, 14, 52, h-28, 10)}" fill="url(#hz)"/>'
            f'<path d="M70 22 L{w-70} 22" stroke="#FFFFFF" stroke-opacity="0.25" stroke-width="5" stroke-linecap="round"/>')
    return svg(w, h, body, d + pat)


def ui_ammo_slot(w, h, selected=False):
    edge = PAL["gold"] if selected else PAL["teal_d"]
    body = ""
    if selected:
        body += f'<rect x="2" y="2" width="{w-4}" height="{h-4}" rx="22" fill="none" stroke="{PAL["gold"]}" stroke-opacity="0.35" stroke-width="4"/>'
    body += (f'<rect x="10" y="10" width="{w-20}" height="{h-20}" rx="18" fill="{PAL["navy"]}" fill-opacity="0.9" '
             f'stroke="{edge}" stroke-width="{7 if selected else 5}"/>'
             f'<rect x="20" y="20" width="{w-40}" height="{h-40}" rx="12" fill="none" stroke="#FFFFFF" stroke-opacity="0.08" stroke-width="3"/>')
    return svg(w, h, body)


def ui_depth_meter(w, h):
    d = grad("g", PAL["teal"], "#5B2A8C")
    body = (f'<rect x="{w/2-16}" y="10" width="32" height="{h-20}" rx="16" fill="url(#g)" fill-opacity="0.85" '
            f'stroke="{PAL["ink"]}" stroke-width="6"/>')
    n = 10
    for i in range(n + 1):
        y = 24 + (h - 48) * i / n
        L = 22 if i % 5 == 0 else 12
        body += f'<line x1="{w/2+18}" y1="{y:.1f}" x2="{w/2+18+L}" y2="{y:.1f}" stroke="{PAL["white"]}" stroke-width="{4 if i % 5 == 0 else 3}" stroke-linecap="round"/>'
    return svg(w, h, body, d)


def ui_crosshair(w, h):
    c = w / 2
    body = ""
    for col, sw in ((PAL["ink"], 12), (PAL["teal"], 5)):
        body += (f'<circle cx="{c}" cy="{c}" r="34" fill="none" stroke="{col}" stroke-width="{sw}"/>'
                 f'<path d="M{c} 8 L{c} 36 M{c} {w-8} L{c} {w-36} M8 {c} L36 {c} M{w-8} {c} L{w-36} {c}" '
                 f'stroke="{col}" stroke-width="{sw}" stroke-linecap="round"/>')
    body += f'<circle cx="{c}" cy="{c}" r="6" fill="{PAL["red"]}" stroke="{PAL["ink"]}" stroke-width="3"/>'
    return svg(w, h, body)


def hexagon(cx, cy, r):
    import math
    pts = " ".join(f"{cx + r*math.cos(math.pi/6 + i*math.pi/3):.1f},{cy + r*math.sin(math.pi/6 + i*math.pi/3):.1f}" for i in range(6))
    return pts


def ui_upgrade_node(w, h, locked=False):
    c = w / 2
    fill, edge = ("#2A2838", PAL["grey"]) if locked else (PAL["navy2"], PAL["teal"])
    body = (f'<polygon points="{hexagon(c, c, c-8)}" fill="{fill}" stroke="{PAL["ink"]}" stroke-width="10" stroke-linejoin="round"/>'
            f'<polygon points="{hexagon(c, c, c-10)}" fill="none" stroke="{edge}" stroke-width="5" stroke-linejoin="round"/>')
    if locked:
        body += (f'<path d="M{c-16} {c-4} L{c-16} {c-16} A16 16 0 0 1 {c+16} {c-16} L{c+16} {c-4}" fill="none" '
                 f'stroke="{PAL["grey"]}" stroke-width="8"/>'
                 f'<rect x="{c-24}" y="{c-6}" width="48" height="38" rx="6" fill="{PAL["grey"]}" stroke="{PAL["ink"]}" stroke-width="4"/>'
                 f'<circle cx="{c}" cy="{c+10}" r="5" fill="{PAL["ink"]}"/>')
    return svg(w, h, body)


# ----------------------------------------------------------------------------- ICON (128x128)

def icon(body, defs=""):
    return svg(128, 128, body, defs)


def icon_ore_iron():
    return icon(f'<path d="M22 78 L34 40 L64 26 L96 36 L108 70 L88 100 L44 104 Z" fill="{PAL["rust_d"]}" {S()}/>'
                f'<path d="M34 40 L64 26 L96 36 L74 56 Z" fill="{PAL["rust"]}"/>'
                f'<path d="M74 56 L96 36 L108 70 Z" fill="#C2603A"/>'
                f'<path d="M50 66 L60 60 M70 78 L82 74 M40 86 L48 82" stroke="#5A2416" stroke-width="5" stroke-linecap="round"/>'
                f'<path d="M22 78 L34 40 L64 26 L96 36 L108 70 L88 100 L44 104 Z" fill="none" {S()}/>')


def icon_ore_sulfur():
    b = ""
    for (x, y, w, hgt, col) in ((30, 52, 26, 52, "#E2BC2E"), (72, 46, 26, 58, "#E2BC2E"), (48, 28, 32, 76, PAL["gold"])):
        b += (f'<path d="M{x} {y+hgt} L{x} {y+12} L{x+w/2} {y} L{x+w} {y+12} L{x+w} {y+hgt} Z" fill="{col}" {S()}/>'
              f'<path d="M{x+w/2} {y+4} L{x+w/2} {y+hgt-6}" stroke="{PAL["gold_l"]}" stroke-width="5" stroke-linecap="round"/>')
    b += f'<ellipse cx="64" cy="106" rx="46" ry="8" fill="#8A6A1E" {S(stroke_width=4)}/>'
    return icon(b)


def icon_ore_mg():
    return icon(f'<path d="M24 82 L30 46 L58 28 L94 34 L106 66 L90 98 L48 102 Z" fill="#B9BCD3" {S()}/>'
                f'<path d="M30 46 L58 28 L94 34 L66 58 Z" fill="#E8EAF6"/>'
                f'<path d="M66 58 L94 34 L106 66 Z" fill="#D2D5EA"/>'
                f'<path d="M24 82 L30 46 L58 28 L94 34 L106 66 L90 98 L48 102 Z" fill="none" {S()}/>'
                f'<path d="M98 14 L102 26 L114 30 L102 34 L98 46 L94 34 L82 30 L94 26 Z" fill="#FFFFFF" {S(stroke_width=3)}/>')


def iso_cube(x, y, s):
    top = f"M{x} {y} L{x+s} {y-s*0.5} L{x+2*s} {y} L{x+s} {y+s*0.5} Z"
    left = f"M{x} {y} L{x+s} {y+s*0.5} L{x+s} {y+s*1.5} L{x} {y+s} Z"
    right = f"M{x+s} {y+s*0.5} L{x+2*s} {y} L{x+2*s} {y+s} L{x+s} {y+s*1.5} Z"
    return (f'<path d="{left}" fill="#E3A9C0" {S(stroke_width=4)}/><path d="{right}" fill="#F0C5D6" {S(stroke_width=4)}/>'
            f'<path d="{top}" fill="#FFFFFF" {S(stroke_width=4)}/>')


def icon_ore_kcl():
    return icon(iso_cube(18, 66, 24) + iso_cube(62, 70, 22) + iso_cube(38, 34, 26))


def icon_ammo_normal():
    d = grad("g", PAL["white"], PAL["teal"], vertical=False)
    return icon(f'<path d="M14 64 L40 50 L96 50 Q116 64 96 78 L40 78 Z" fill="url(#g)" {S()}/>'
                f'<path d="M44 58 L92 58" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round"/>'
                f'<path d="M8 50 L26 56 M6 64 L22 64 M8 78 L26 72" stroke="{PAL["teal"]}" stroke-width="5" stroke-linecap="round"/>', d)


def icon_ammo_acid():
    return icon(f'<path d="M64 14 C64 14 28 58 28 80 A36 36 0 0 0 100 80 C100 58 64 14 64 14 Z" fill="{PAL["green"]}" {S()}/>'
                f'<circle cx="52" cy="78" r="10" fill="#B8F59F"/><circle cx="76" cy="92" r="6" fill="#B8F59F"/>'
                f'<circle cx="74" cy="68" r="4" fill="#B8F59F"/>'
                f'<circle cx="100" cy="30" r="8" fill="{PAL["green"]}" {S(stroke_width=4)}/>')


def icon_ammo_fire():
    return icon(f'<path d="M64 12 C80 36 104 48 98 82 C94 104 78 116 64 116 C46 116 30 104 28 84 C26 64 40 54 44 38 '
                f'C52 50 54 58 58 62 C60 44 56 30 64 12 Z" fill="{PAL["rust"]}" {S()}/>'
                f'<path d="M64 56 C74 70 82 78 78 94 C76 104 70 108 64 108 C56 108 48 102 48 92 C48 80 58 74 64 56 Z" fill="{PAL["gold"]}"/>')


def icon_ammo_ice():
    import math
    b = ""
    for i in range(6):
        a = i * math.pi / 3
        x, y = 64 + 48 * math.sin(a), 64 - 48 * math.cos(a)
        b += f'<line x1="64" y1="64" x2="{x:.1f}" y2="{y:.1f}" stroke="{PAL["ink"]}" stroke-width="16" stroke-linecap="round"/>'
    for i in range(6):
        a = i * math.pi / 3
        x, y = 64 + 48 * math.sin(a), 64 - 48 * math.cos(a)
        mx, my = 64 + 30 * math.sin(a), 64 - 30 * math.cos(a)
        b += f'<line x1="64" y1="64" x2="{x:.1f}" y2="{y:.1f}" stroke="{PAL["ice"]}" stroke-width="8" stroke-linecap="round"/>'
        for s in (-1, 1):
            bx, by = mx + 14 * math.sin(a + s * 0.9), my - 14 * math.cos(a + s * 0.9)
            b += f'<line x1="{mx:.1f}" y1="{my:.1f}" x2="{bx:.1f}" y2="{by:.1f}" stroke="{PAL["ice"]}" stroke-width="6" stroke-linecap="round"/>'
    b += f'<circle cx="64" cy="64" r="10" fill="#FFFFFF" {S(stroke_width=4)}/>'
    return icon(b)


def icon_up_drill():
    return icon(f'<path d="M20 30 L62 30 L104 52 L62 74 L20 74 Z" fill="#B9BCD3" {S()}/>'
                f'<path d="M36 30 L50 74 M52 32 L66 72 M70 40 L80 66" stroke="{PAL["ink"]}" stroke-width="4"/>'
                f'<rect x="8" y="34" width="16" height="36" rx="4" fill="{PAL["rust"]}" {S()}/>' + up_badge())


def icon_up_move():
    return icon(f'<path d="M34 24 L60 24 L62 62 L92 70 Q104 74 104 86 L104 94 L30 94 Z" fill="{PAL["rust"]}" {S()}/>'
                f'<path d="M30 94 L104 94 L104 104 L30 104 Z" fill="{PAL["ink"]}"/>'
                f'<path d="M8 44 L24 44 M4 60 L22 60 M8 76 L24 76" stroke="{PAL["teal"]}" stroke-width="6" stroke-linecap="round"/>'
                + up_badge())


def icon_up_jetpack():
    return icon(f'<rect x="30" y="18" width="26" height="58" rx="10" fill="#B9BCD3" {S()}/>'
                f'<rect x="60" y="18" width="26" height="58" rx="10" fill="#B9BCD3" {S()}/>'
                f'<rect x="38" y="30" width="40" height="14" rx="4" fill="{PAL["teal_d"]}" {S(stroke_width=4)}/>'
                f'<path d="M34 78 Q43 112 52 78 Z" fill="{PAL["rust"]}" {S(stroke_width=4)}/>'
                f'<path d="M64 78 Q73 112 82 78 Z" fill="{PAL["rust"]}" {S(stroke_width=4)}/>'
                f'<path d="M39 80 Q43 96 47 80 Z M69 80 Q73 96 77 80 Z" fill="{PAL["gold"]}"/>'
                + up_badge())


def icon_up_carry():
    return icon(f'<rect x="22" y="34" width="70" height="66" rx="12" fill="{PAL["teal_d"]}" {S()}/>'
                f'<path d="M40 34 L40 24 Q40 14 50 14 L64 14 Q74 14 74 24 L74 34" fill="none" {S()}/>'
                f'<rect x="34" y="52" width="46" height="22" rx="5" fill="{PAL["teal"]}" {S(stroke_width=4)}/>'
                f'<circle cx="46" cy="88" r="7" fill="{PAL["rust"]}"/><circle cx="66" cy="88" r="7" fill="{PAL["gold"]}"/>'
                + up_badge())


def icon_up_turret_dmg():
    return icon(f'<path d="M64 14 L72 36 L94 30 L84 50 L104 60 L82 66 L88 88 L68 76 L60 98 L54 76 L32 84 L42 64 L20 54 L42 48 L36 26 L56 36 Z" '
                f'fill="{PAL["gold"]}" {S()}/>'
                f'<path d="M64 40 L70 54 L84 56 L72 64 L74 78 L64 70 L54 78 L56 64 L44 56 L58 54 Z" fill="{PAL["rust"]}"/>'
                + up_badge())


def icon_up_turret_rot():
    return icon(f'<circle cx="60" cy="60" r="18" fill="none" stroke="{PAL["ink"]}" stroke-width="12"/>'
                f'<circle cx="60" cy="60" r="18" fill="none" stroke="{PAL["teal"]}" stroke-width="5"/>'
                f'<path d="M60 16 A44 44 0 0 1 102 52" fill="none" stroke="{PAL["ink"]}" stroke-width="14" stroke-linecap="round"/>'
                f'<path d="M60 16 A44 44 0 0 1 102 52" fill="none" stroke="{PAL["white"]}" stroke-width="7" stroke-linecap="round"/>'
                f'<path d="M94 40 L106 56 L112 38 Z" fill="{PAL["white"]}" {S(stroke_width=4)}/>'
                f'<path d="M60 104 A44 44 0 0 1 18 68" fill="none" stroke="{PAL["ink"]}" stroke-width="14" stroke-linecap="round"/>'
                f'<path d="M60 104 A44 44 0 0 1 18 68" fill="none" stroke="{PAL["white"]}" stroke-width="7" stroke-linecap="round"/>'
                f'<path d="M26 80 L14 64 L8 82 Z" fill="{PAL["white"]}" {S(stroke_width=4)}/>'
                + up_badge())


def icon_up_base_hp():
    return icon(f'<path d="M64 12 L104 26 L104 60 C104 86 86 104 64 116 C42 104 24 86 24 60 L24 26 Z" fill="{PAL["teal_d"]}" {S()}/>'
                f'<path d="M64 24 L94 34 L94 60 C94 80 80 94 64 104 Z" fill="{PAL["teal"]}" fill-opacity="0.6"/>'
                f'<path d="M64 46 L64 82 M46 64 L82 64" stroke="{PAL["white"]}" stroke-width="12" stroke-linecap="round"/>'
                + up_badge())


def icon_repair():
    return icon(f'<g transform="rotate(-45 64 64)">'
                f'<rect x="56" y="40" width="16" height="74" rx="8" fill="#B9BCD3" {S()}/>'
                f'<path d="M40 22 A28 28 0 1 0 88 22 L80 22 L80 40 L48 40 L48 22 Z" fill="#B9BCD3" {S()}/>'
                f'</g>'
                f'<path d="M92 92 L112 92 M102 82 L102 102" stroke="{PAL["green"]}" stroke-width="10" stroke-linecap="round"/>')


def icon_lift():
    return icon(f'<rect x="26" y="10" width="76" height="108" rx="8" fill="{PAL["navy2"]}" {S()}/>'
                f'<path d="M40 10 L40 118 M88 10 L88 118" stroke="{PAL["teal_d"]}" stroke-width="5"/>'
                f'<rect x="36" y="46" width="56" height="40" rx="6" fill="{PAL["rust"]}" {S()}/>'
                f'<path d="M64 14 L64 46" stroke="{PAL["ink"]}" stroke-width="4"/>'
                f'<path d="M64 52 L74 64 L54 64 Z" fill="{PAL["gold"]}" {S(stroke_width=3)}/>'
                f'<path d="M64 80 L74 68 L54 68 Z" fill="{PAL["gold"]}" {S(stroke_width=3)}/>')


def icon_teleporter():
    return icon(f'<ellipse cx="64" cy="98" rx="46" ry="14" fill="{PAL["navy2"]}" {S()}/>'
                f'<ellipse cx="64" cy="56" rx="30" ry="40" fill="none" stroke="{PAL["ink"]}" stroke-width="16"/>'
                f'<ellipse cx="64" cy="56" rx="30" ry="40" fill="none" stroke="{PAL["teal"]}" stroke-width="8"/>'
                f'<ellipse cx="64" cy="56" rx="16" ry="24" fill="{PAL["teal"]}" fill-opacity="0.35"/>'
                f'<path d="M104 18 L107 27 L116 30 L107 33 L104 42 L101 33 L92 30 L101 27 Z" fill="#FFFFFF" {S(stroke_width=3)}/>')


def icon_blast():
    return icon(f'<circle cx="56" cy="74" r="36" fill="{PAL["ink"]}"/>'
                f'<circle cx="56" cy="74" r="32" fill="#3B3A55"/>'
                f'<circle cx="44" cy="62" r="10" fill="#FFFFFF" fill-opacity="0.25"/>'
                f'<rect x="64" y="30" width="20" height="16" rx="3" transform="rotate(35 74 38)" fill="{PAL["grey"]}" {S(stroke_width=4)}/>'
                f'<path d="M80 30 Q92 14 104 18" fill="none" stroke="{PAL["ink"]}" stroke-width="6" stroke-linecap="round"/>'
                f'<path d="M106 6 L109 15 L118 16 L111 22 L114 31 L106 26 L98 31 L101 22 L94 16 L103 15 Z" fill="{PAL["gold"]}" {S(stroke_width=3)}/>'
                f'<circle cx="106" cy="18" r="4" fill="{PAL["red"]}"/>')


BUILDERS = {
    "ui_panel": ui_panel,
    "ui_button": ui_button,
    "ui_button_pressed": lambda w, h: ui_button(w, h, pressed=True),
    "ui_bar_frame": ui_bar_frame,
    "ui_bar_fill": ui_bar_fill,
    "ui_wave_timer": ui_wave_timer,
    "ui_wave_timer_fill": ui_wave_timer_fill,
    "ui_wave_warning": ui_wave_warning,
    "ui_ammo_slot": ui_ammo_slot,
    "ui_ammo_slot_selected": lambda w, h: ui_ammo_slot(w, h, selected=True),
    "ui_depth_meter": ui_depth_meter,
    "ui_crosshair": ui_crosshair,
    "ui_upgrade_node": ui_upgrade_node,
    "ui_upgrade_node_locked": lambda w, h: ui_upgrade_node(w, h, locked=True),
    "icon_ore_iron": icon_ore_iron, "icon_ore_sulfur": icon_ore_sulfur,
    "icon_ore_mg": icon_ore_mg, "icon_ore_kcl": icon_ore_kcl,
    "icon_ammo_normal": icon_ammo_normal, "icon_ammo_acid": icon_ammo_acid,
    "icon_ammo_fire": icon_ammo_fire, "icon_ammo_ice": icon_ammo_ice,
    "icon_up_drill": icon_up_drill, "icon_up_move": icon_up_move, "icon_up_carry": icon_up_carry,
    "icon_up_jetpack": icon_up_jetpack,
    "icon_up_turret_dmg": icon_up_turret_dmg, "icon_up_turret_rot": icon_up_turret_rot,
    "icon_up_base_hp": icon_up_base_hp, "icon_repair": icon_repair,
    "icon_lift": icon_lift, "icon_teleporter": icon_teleporter, "icon_blast": icon_blast,
}


def find_chrome():
    for p in CHROME:
        if os.path.exists(p):
            return p
    sys.exit("Không tìm thấy Chrome/Edge để render SVG.")


def render(chrome, svg_path, png_path, w, h):
    tmp = tempfile.mkdtemp()
    html = os.path.join(tmp, "r.html")
    with open(html, "w", encoding="utf-8") as f:
        f.write(f'<html><body style="margin:0;background:transparent">'
                f'<img src="file:///{svg_path.replace(os.sep, "/")}" width="{w}" height="{h}" style="display:block"></body></html>')
    subprocess.run([chrome, "--headless", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                    "--default-background-color=00000000", "--allow-file-access-from-files",
                    f"--window-size={w},{h}", f"--screenshot={png_path}", "file:///" + html.replace(os.sep, "/")],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=60, check=False)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    sheet = "--sheet" in sys.argv
    rows = {r["id"]: r for r in csv.DictReader(open(MANIFEST, encoding="utf-8"))}
    os.makedirs(SRC, exist_ok=True)
    chrome = find_chrome()
    ids = args or list(BUILDERS)
    done = []
    for rid in ids:
        if rid not in BUILDERS or rid not in rows:
            print(f"[bỏ qua] {rid}")
            continue
        w, h = (int(x) for x in rows[rid]["spec_px"].split("x"))
        content = BUILDERS[rid](w, h) if rid.startswith("ui_") else BUILDERS[rid]()
        svg_path = os.path.join(SRC, rid + ".svg")
        with open(svg_path, "w", encoding="utf-8") as f:
            f.write(content)
        out_dir = os.path.join(ROOT, "Assets", "_Game", "Art", rows[rid]["category"])
        os.makedirs(out_dir, exist_ok=True)
        png = os.path.join(out_dir, rid + ".png")
        render(chrome, svg_path, png, w, h)
        print(f"OK {rid} ({w}x{h})")
        done.append((rid, png))

    if sheet and done:
        from PIL import Image, ImageDraw
        cell = 180
        cols = 8
        rowsn = (len(done) + cols - 1) // cols
        im = Image.new("RGBA", (cols * cell, rowsn * cell), (40, 44, 60, 255))
        dr = ImageDraw.Draw(im)
        for i, (rid, png) in enumerate(done):
            t = Image.open(png).convert("RGBA")
            t.thumbnail((cell - 30, cell - 40))
            x, y = (i % cols) * cell, (i // cols) * cell
            im.alpha_composite(t, (x + (cell - t.width) // 2, y + 6 + (cell - 40 - t.height) // 2))
            dr.text((x + 6, y + cell - 22), rid.replace("icon_", "").replace("ui_", "ui:"), fill=(230, 230, 240, 255))
        out = os.path.join(HERE, "contact_sheet.png")
        im.save(out)
        print("Sheet:", out)


if __name__ == "__main__":
    main()
