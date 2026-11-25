"""Generate aligned pixel-art dome layers. No source/reference PNG is modified."""
from pathlib import Path
from PIL import Image, ImageDraw
import math

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'Assets/_Game/Art/bld'
SCALE = 4
INK = '#17142b'
DEEP = '#25203e'
VIOLET = '#574171'
LILAC = '#ba86d6'
GOLD = '#f6b960'
LIGHT = '#ffe8a2'
CYAN = '#8be0ed'


def canvas(size=(128, 80)):
    im = Image.new('RGBA', size)
    return im, ImageDraw.Draw(im)


def save(im, name):
    OUT.mkdir(parents=True, exist_ok=True)
    im.resize((im.width*SCALE, im.height*SCALE), Image.Resampling.NEAREST).save(OUT / (name+'.png'))


def dome_arc(d, fill, width=1, inset=0):
    pts = [(round(64 + (60-inset)*math.cos(t*math.pi/96)),
            round(70 - (60-inset)*math.sin(t*math.pi/96))) for t in range(97)]
    d.line(pts, fill=fill, width=width)


def hatch(d, box, rim=GOLD, hot=LIGHT):
    x0, y0, x1, y1 = box
    d.ellipse((x0-2, y0-1, x1+2, y1+2), fill=INK)
    d.ellipse(box, fill=rim)
    d.ellipse((x0+3, y0+2, x1-3, y1-2), fill='#100e21')
    d.line((x0+5, y0+1, x1-5, y0+1), fill=hot)
    d.line((x0+6, y1, x1-6, y1), fill=hot)


def generate_cracks():
    strip, _ = canvas((128 * 3, 80))
    groups = (
        (
            [(13, 46), (17, 48), (16, 54), (23, 58), (21, 65)],
            [(17, 48), (23, 45), (29, 47)],
        ),
        (
            [(32, 23), (35, 30), (29, 36), (34, 42), (31, 50)],
            [(35, 30), (45, 32), (48, 39), (55, 43)],
            [(69, 13), (65, 23), (71, 29), (68, 36), (76, 43)],
            [(65, 23), (55, 25), (49, 20)],
            [(104, 30), (98, 36), (102, 45), (94, 49), (97, 60)],
            [(98, 36), (89, 38), (86, 46)],
        ),
        (
            [(23, 58), (30, 57), (36, 63), (42, 61), (46, 68)],
            [(31, 50), (39, 54), (48, 51), (55, 43), (61, 48), (68, 46), (76, 43)],
            [(61, 48), (58, 56), (64, 61), (60, 69)],
            [(48, 39), (54, 33), (60, 35), (68, 36)],
            [(71, 29), (79, 24), (84, 26), (89, 21)],
            [(76, 43), (83, 42), (86, 46), (82, 54), (88, 60), (85, 69)],
            [(97, 60), (106, 56), (113, 60), (118, 55)],
            [(102, 45), (109, 43), (111, 47), (117, 46)],
        ),
    )
    for stage in range(3):
        cracks, d = canvas()
        paths = [points for group in groups[:stage + 1] for points in group]
        if stage == 2:
            for points in paths:
                d.line(points, fill=(233, 77, 118, 110), width=3)
        for points in paths:
            d.line(points, fill=(255, 231, 199, 235 if stage else 170))
        for y in range(cracks.height):
            for x in range(cracks.width):
                if y > 70 or (x - 64) ** 2 + (y - 70) ** 2 > 58 ** 2:
                    cracks.putpixel((x, y), (0, 0, 0, 0))
        strip.paste(cracks, (128 * stage, 0))
    save(strip, 'bld_dome_cracks')


def generate():
    frame, d = canvas()
    # Deck rim and open hatch; glass and all machines are separate files.
    d.ellipse((3, 67, 125, 79), fill=INK)
    d.ellipse((5, 67, 123, 77), fill='#594065')
    d.ellipse((7, 68, 121, 74), fill='#3d2c50')
    d.arc((5, 67, 123, 77), 0, 180, fill=GOLD, width=2)
    d.line((13, 77, 115, 77), fill='#b97968', width=2)
    # Transparent opening in the deck, rather than a painted patch of soil.
    d.ellipse((42, 69, 86, 77), fill=(0, 0, 0, 0))
    dome_arc(d, INK, 7)
    dome_arc(d, '#9c658a', 5)
    dome_arc(d, GOLD, 3)
    dome_arc(d, LIGHT, 1, 1)
    for a in (0.2, 0.55, 1.05, 1.55, 2.05, 2.6, 2.95):
        x, y = round(64+60*math.cos(a)), round(70-60*math.sin(a))
        d.rectangle((x-2, y-1, x+2, y+1), fill='#b77b98')
        d.point((x, y-1), fill=LIGHT)
    save(frame, 'bld_dome_frame')

    interior, d = canvas()
    # Twin energy cores, fins, luminous windows and shared plinth.
    d.rectangle((50, 63, 79, 67), fill=INK)
    d.line((52, 64, 77, 64), fill=LILAC)
    for x in (54, 69):
        d.rectangle((x-2, 36, x+7, 63), fill=INK)
        d.rectangle((x-1, 38, x+6, 61), fill='#64426f')
        d.rectangle((x+1, 39, x+4, 60), fill='#35283f')
        d.line((x-1, 38, x+5, 38), fill=GOLD)
        for y in (42, 48, 54, 60):
            d.rectangle((x-3, y, x+8, y+1), fill='#9d628f')
            d.rectangle((x+1, y, x+4, y+1), fill='#f1b4df')
            d.point((x+2, y), fill=LIGHT)
        d.line((x-1, 39, x-1, 60), fill='#cd8db0')
        d.rectangle((x-2, 62, x+7, 64), fill='#3a2b4f')
    # Left compact battery/canister, deliberately shorter than the cores.
    d.rectangle((16, 54, 29, 67), fill=INK)
    d.rectangle((18, 54, 27, 65), fill='#5a3e69')
    d.ellipse((18, 52, 27, 56), fill=GOLD)
    d.ellipse((20, 53, 25, 55), fill='#a15f83')
    for y in (58, 62):
        d.rectangle((17, y, 28, y+1), fill='#d4979c')
    d.rectangle((19, 57, 20, 63), fill=CYAN)
    d.line((14, 59, 12, 59, 12, 65, 16, 65), fill=VIOLET, width=2)
    # Right monitor, keyboard desk, separate luminous computer tower.
    d.rectangle((96, 43, 114, 56), fill=INK)
    d.rectangle((97, 43, 113, 54), fill='#9c738f')
    d.rectangle((99, 45, 111, 52), fill='#254e70')
    d.line((100, 46, 108, 46), fill=CYAN)
    d.line((101, 48, 105, 48), fill='#bdc0ef')
    d.rectangle((104, 55, 106, 59), fill='#8e668c')
    d.polygon([(94, 58), (112, 58), (116, 63), (92, 63)], fill='#835674')
    d.line((96, 59, 109, 59), fill=GOLD)
    for x in range(96, 111, 3):
        d.point((x, 61), fill=LIGHT)
    d.rectangle((94, 64, 97, 68), fill=INK)
    d.rectangle((110, 64, 113, 68), fill=INK)
    d.rectangle((84, 54, 92, 68), fill=INK)
    d.rectangle((85, 55, 91, 67), fill='#52395d')
    d.line((86, 57, 90, 57), fill=LILAC)
    d.rectangle((86, 60, 87, 63), fill=CYAN)
    d.point((90, 65), fill=GOLD)
    hatch(d, (42, 69, 86, 77))
    save(interior, 'bld_dome_interior')

    glass, d = canvas()
    # Low alpha everywhere except small stepped reflections. No frame/interior baked in.
    for y in range(10, 71):
        for x in range(5, 124):
            if ((x-64)/58)**2 + ((y-70)/58)**2 <= 1:
                d.point((x, y), fill=(74, 60, 116, 24 + (70-y)//5))
    d.line((20, 48, 23, 40, 29, 32, 37, 25), fill=(211, 214, 244, 90), width=2)
    d.line((28, 39, 31, 35, 35, 31), fill=(255, 232, 191, 125), width=2)
    d.line((87, 26, 94, 31, 100, 38), fill=(196, 195, 236, 65), width=2)
    save(glass, 'bld_dome_glass')

    generate_cracks()

    chamber, d = canvas((128, 64))
    d.rectangle((9, 0, 119, 48), fill=(23, 20, 43, 205))
    d.ellipse((9, 35, 119, 63), fill=(32, 25, 54, 230))
    d.line((9, 0, 9, 47, 15, 55, 29, 60, 99, 60, 113, 55, 119, 47, 119, 0), fill='#7c558d', width=2)
    d.line((12, 2, 12, 46), fill='#392c52')
    d.line((116, 2, 116, 46), fill='#392c52')
    # Deliberately thin, subdued circuitry behind the player.
    for points in (
        [(17, 10), (28, 10), (28, 18), (39, 18), (39, 9), (49, 9)],
        [(18, 33), (26, 33), (26, 25), (42, 25), (42, 35), (51, 35)],
        [(77, 10), (88, 10), (88, 20), (105, 20), (105, 13), (112, 13)],
        [(77, 33), (92, 33), (92, 40), (107, 40), (107, 30), (113, 30)],
        [(33, 41), (33, 34), (47, 34), (47, 29)],
    ):
        d.line(points, fill=(130, 87, 165, 145))
        x, y = points[-1]
        d.rectangle((x-1, y-1, x+1, y+1), outline=(146, 130, 195, 175))
    d.ellipse((54, 17, 73, 36), outline='#60487b', width=2)
    d.ellipse((58, 21, 69, 32), outline='#9271b0')
    d.rectangle((61, 25, 66, 28), fill=(119, 183, 210, 110))
    d.arc((12, 37, 116, 60), 0, 180, fill='#ae77c4')
    hatch(d, (41, 49, 87, 59), '#a65bd3', '#d29aeb')
    save(chamber, 'bld_dome_underground')

    shaft, d = canvas((64, 96))
    d.rectangle((4, 0, 59, 95), fill=(31, 27, 57, 125))
    d.rectangle((1, 0, 5, 95), fill='#403456')
    d.rectangle((58, 0, 62, 95), fill='#403456')
    d.line((6, 0, 6, 95), fill='#a479b5')
    d.line((57, 0, 57, 95), fill='#a479b5')
    d.line((8, 0, 8, 95), fill='#e4a565')
    d.line((55, 0, 55, 95), fill='#e4a565')
    for y in range(10, 96, 19):
        d.rectangle((2, y, 4, y+3), fill=CYAN)
        d.rectangle((59, y, 61, y+3), fill=CYAN)
    save(shaft, 'bld_dome_shaft')

    # Authored-layer preview, same registration and offsets as the renderer.
    preview = Image.new('RGBA', (256, 256), '#29223e')
    for im in (shaft, chamber, frame, interior, glass):
        pos = (96, 144) if im is shaft else (64, 80) if im is chamber else (64, 0)
        preview.alpha_composite(im, pos)
    target = ROOT / '.utmp/dome-layers-preview.png'
    target.parent.mkdir(exist_ok=True)
    preview.resize((768, 768), Image.Resampling.NEAREST).save(target)


if __name__ == '__main__':
    generate()
    print('Generated six registered dome layers and .utmp/dome-layers-preview.png')
