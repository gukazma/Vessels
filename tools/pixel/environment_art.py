"""Sunlit town art: warm masonry, grouped foliage and readable handmade surfaces.

All shapes use native integer pixels. Alpha is reserved for contact shadows.
"""
import random
from PIL import Image, ImageDraw, ImageFilter
from pixel_common import ASSETS, canvas, save, text

INK = "#384d50"
CREAM = "#fff1c9"


def flower(d, x, y, color):
    d.line((x, y, x, y + 4), fill="#527d57")
    d.rectangle((x - 2, y - 1, x + 2, y + 1), fill=color)
    d.rectangle((x - 1, y - 2, x + 1, y + 2), fill=color)
    d.point((x, y), fill="#f8d477")


def terrain():
    rng = random.Random(472)
    image = Image.new("RGB", (960, 640), "#8db875")
    d = ImageDraw.Draw(image)
    # Broad, quiet grass clusters keep the ground from becoming pixel noise.
    for _ in range(1800):
        x, y = rng.randrange(960), rng.randrange(640)
        w, h = rng.randrange(5, 19), rng.randrange(2, 6)
        d.polygon([(x, y), (x + w - 3, y), (x + w, y + 2), (x + w - 3, y + h),
                   (x + 2, y + h)], fill=rng.choice(["#91bc78", "#86b271", "#97bf7a", "#83ae70"]))
    # Paved pedestrian areas and inset curbs; individually shaded sandstone slabs.
    for rect in [(390, 0, 569, 640), (0, 343, 960, 486)]:
        d.rectangle(rect, fill="#a69d81", outline="#728777", width=2)
    for y in range(0, 640, 16):
        for x in range(0, 960, 16):
            if 390 <= x < 569 or 343 <= y < 486:
                color = rng.choice(["#d4c5a0", "#cebe9b", "#dccaac", "#d1c2a2"])
                d.rectangle((x + 1, y + 1, x + 14, y + 14), fill=color)
                d.line((x + 2, y + 2, x + 13, y + 2), fill="#e6d6b2")
                d.point((x + 3, y + 10), fill="#c3b994")
    road_mask = Image.new("1", image.size)
    md = ImageDraw.Draw(road_mask)
    md.rectangle((417, 0, 543, 640), fill=1)
    md.rectangle((0, 369, 960, 462), fill=1)
    road = Image.new("RGB", image.size, "#748f96")
    rd = ImageDraw.Draw(road)
    for _ in range(9500):
        x, y = rng.randrange(960), rng.randrange(640)
        rd.line((x, y, x + rng.randrange(1, 4), y),
                fill=rng.choice(["#7d999e", "#718c92", "#6e898f", "#809ba0"]))
    image.paste(road, mask=road_mask)
    d = ImageDraw.Draw(image)
    for x in (417, 543):
        d.line((x, 0, x, 368), fill="#efe4c7", width=2)
        d.line((x, 464, x, 640), fill="#efe4c7", width=2)
    for y in (369, 463):
        d.line((0, y, 415, y), fill="#eee3c5", width=2)
        d.line((545, y, 960, y), fill="#eee3c5", width=2)
    for y in range(13, 640, 43):
        if not 339 < y < 476:
            for x in (478, 482):
                d.rectangle((x, y, x + 1, y + 21), fill="#e6cf91")
    for x in range(13, 960, 43):
        if not 388 < x < 562:
            d.rectangle((x, 415, x + 21, 417), fill="#e6cf91")
    for x in range(429, 538, 14):
        d.rectangle((x, 348, x + 7, 364), fill="#f7efce")
        d.line((x, 364, x + 7, 364), fill="#c2c4ad")
        d.point((x + 3, 351), fill="#c1c7b3")
    for y in range(383, 455, 13):
        d.rectangle((553, y, 569, y + 6), fill="#f7efce")
    # Restrained wear gives the quarantine setting history without dirtying the palette.
    for x, y in [(523, 435), (358, 396), (710, 428), (443, 268), (486, 490)]:
        points = [(x, y), (x + 2, y + 5), (x - 2, y + 9), (x + 3, y + 14), (x + 1, y + 19)]
        d.line(points, fill="#68868a")
        d.line((x - 1, y + 9, x - 7, y + 10), fill="#68868a")
    for x, y in [(421, 325), (535, 505), (590, 451), (295, 374)]:
        d.rectangle((x - 4, y - 8, x + 3, y + 7), fill="#526d74", outline="#b8c3ab")
        for yy in range(y - 5, y + 6, 3):
            d.line((x - 2, yy, x + 1, yy), fill="#92aaa5")
    d.ellipse((467, 432, 485, 444), fill="#6b8789", outline="#c1c9ac")
    d.arc((470, 434, 482, 442), 190, 350, fill="#8fa7a0")
    d.line((471, 436, 480, 440), fill="#abc0af")
    text(d, (449, 299), "SLOW", "#e8dcae", 2)
    # Small sky reflections sit at the curb rather than making the entire street shiny.
    for x, y, width in [(410, 430, 24), (536, 339, 20), (377, 465, 37), (620, 378, 33)]:
        d.polygon([(x, y), (x + width - 4, y - 2), (x + width, y + 2),
                   (x + width - 7, y + 6), (x + 4, y + 7)], fill="#6f9b9f")
        d.line((x + 4, y, x + width - 6, y), fill="#c7dfd3")
        d.line((x + 8, y + 4, x + width - 12, y + 4), fill="#a2c9c6")
    # Soft directional tree shade: offset from the contact shadow in the prop sprite.
    shade = Image.new("RGBA", image.size)
    sd = ImageDraw.Draw(shade)
    for x, y in [(190, 330), (782, 349), (199, 520), (376, 570), (778, 532),
                 (237, 195), (752, 197), (150, 244), (808, 252), (306, 594), (691, 625)]:
        sd.polygon([(x - 15, y - 9), (x + 10, y - 8), (x + 50, y + 15),
                    (x + 55, y + 27), (x + 30, y + 30), (x + 11, y + 13)], fill=(53, 88, 83, 48))
    image = Image.alpha_composite(image.convert("RGBA"), shade)
    d = ImageDraw.Draw(image)
    for _ in range(500):
        x, y = rng.randrange(960), rng.randrange(640)
        if not (385 < x < 576 or 338 < y < 492):
            d.line((x, y, x - 2, y - 3), fill="#659955")
            d.line((x + 1, y, x + 3, y - 4), fill="#c1d987")
    for cx, cy in [(346, 506), (596, 321), (720, 541), (262, 332), (775, 378), (391, 586), (164, 394)]:
        for _ in range(10):
            x, y = cx + rng.randrange(-16, 17), cy + rng.randrange(-8, 9)
            flower(d, x, y, rng.choice(["#f8f0c4", "#e89a87", "#e9d06f"]))
    # Fallen paper, a few leaves, and expansion seams are intentional, not visual noise.
    for x, y in [(441, 338), (351, 442), (570, 464), (697, 363)]:
        d.rectangle((x, y, x + 4, y + 3), fill="#f2e9c9")
        d.line((x + 1, y + 1, x + 3, y + 1), fill="#9ba18a")
    save(image.convert("RGB"), "street_ground")


def roof(d, clinic):
    rng = random.Random(37 if clinic else 57)
    colors = ["#c87755", "#ce805b", "#d58a5e", "#be6c50"] if clinic else ["#628e8b", "#6d9b90", "#57827f", "#719d91"]
    dark = "#955b49" if clinic else "#426c70"
    light = "#efb279" if clinic else "#a6c2a4"
    d.polygon([(2, 60), (19, 12), (139, 12), (158, 60), (153, 68), (7, 68)], fill=INK)
    d.polygon([(5, 59), (21, 14), (137, 14), (154, 59)], fill=dark)
    for row, yy in enumerate(range(17, 59, 8)):
        left = int(20 - (yy - 14) * 0.30)
        right = 139 + int((yy - 14) * 0.30)
        for xx in range(left - 8 + (row % 2) * 7, right, 14):
            x0, x1 = max(left, xx), min(right, xx + 12)
            if x1 <= x0:
                continue
            d.rectangle((x0, yy, x1, yy + 5), fill=rng.choice(colors))
            d.line((x0 + 1, yy, x1, yy), fill=light)
            d.line((x0 + 2, yy + 6, x1 - 1, yy + 6), fill=dark)
    d.rectangle((5, 60, 153, 65), fill="#7a7053" if clinic else "#506d65")
    d.line((6, 60, 152, 60), fill="#f4c88a" if clinic else "#d3d9ae")
    d.line((10, 66, 149, 66), fill="#a39269")
    # A ceramic ridge and chimney cast short shadows into the roof plane.
    d.rectangle((19, 10, 139, 14), fill=dark)
    d.line((22, 10, 136, 10), fill=light)
    d.polygon([(116, 17), (127, 18), (138, 33), (123, 33)], fill=dark)
    d.rectangle((114, 7, 124, 23), fill="#ad9a7c")
    d.rectangle((112, 5, 126, 10), fill="#eed7ac", outline="#786f5f")
    d.line((116, 12, 123, 12), fill="#e8cba0")
    d.line((115, 17, 123, 17), fill="#827868")
    d.rectangle((115, 6, 123, 7), fill="#686e64")


def window(d, x, y, w=24, h=26, awning=False):
    d.rectangle((x - 2, y - 2, x + w + 1, y + h + 2), fill="#a48d6c")
    d.rectangle((x - 1, y - 1, x + w, y + h), fill="#f9e7be")
    d.rectangle((x + 1, y + 1, x + w - 2, y + h - 2), fill="#52878b")
    d.polygon([(x + 2, y + 2), (x + w - 3, y + 2), (x + 2, y + h - 5)], fill="#94bfb5")
    d.line((x + 3, y + 3, x + w - 5, y + 3), fill="#d8e8cf")
    d.line((x + w // 2, y + 1, x + w // 2, y + h - 1), fill="#eee1b3", width=2)
    d.line((x + 1, y + h // 2, x + w - 1, y + h // 2), fill="#eee1b3")
    d.rectangle((x - 3, y + h, x + w + 3, y + h + 2), fill="#f6e0b3")
    d.line((x - 1, y + h + 3, x + w + 2, y + h + 3), fill="#ae9d77")
    if awning:
        for xx in range(x - 5, x + w + 4, 7):
            color = "#cf8170" if ((xx - x + 5) // 7) % 2 == 0 else "#faf0c6"
            d.rectangle((xx, y - 8, xx + 6, y - 3), fill=color)
            d.rectangle((xx + 1, y - 2, xx + 5, y), fill=color)


def flower_box(d, x, y, width):
    d.rectangle((x - 1, y, x + width, y + 7), fill="#977250")
    d.rectangle((x, y + 1, x + width - 1, y + 5), fill="#ca9a64")
    d.line((x, y + 1, x + width - 1, y + 1), fill="#efc688")
    for xx in range(x + 1, x + width - 1, 4):
        d.rectangle((xx, y - 4, xx + 3, y), fill="#618d53")
        d.point((xx, y - 4), fill="#a1c572")
    for xx in range(x + 4, x + width - 2, 8):
        flower(d, xx, y - 4, "#f4c5a0" if xx % 3 else "#e88979")


def building(name, clinic):
    image, d = canvas((160, 132))
    d.polygon([(7, 116), (146, 116), (160, 128), (153, 131), (20, 131), (3, 121)], fill=(62, 85, 78, 70))
    d.rectangle((7, 52, 151, 122), fill="#8b9178")
    d.rectangle((10, 55, 147, 119), fill="#eed8ad" if clinic else "#e5c597")
    d.rectangle((11, 59, 144, 70), fill="#d5b891" if clinic else "#caaa84")
    d.line((10, 71, 10, 117), fill="#fff0c6", width=2)
    d.rectangle((143, 68, 147, 118), fill="#c4a882")
    d.rectangle((9, 115, 148, 120), fill="#b2a286")
    for yy in (113, 118):
        d.line((11, yy, 144, yy), fill="#d6c39e")
        for xx in range(14 + (yy % 2) * 5, 145, 16):
            d.line((xx, yy - 3, xx, yy), fill="#9d947c")
    for x, y in [(11, 80), (143, 86), (12, 107), (139, 105)]:
        d.rectangle((x, y, x + 4, y + 2), fill="#d2b68c")
        d.line((x, y, x + 4, y), fill="#f6e2b4")
    roof(d, clinic)
    window(d, 20, 80, 24, 26, not clinic)
    window(d, 113, 80, 22, 26, not clinic)
    for x in (15, 45) if clinic else ():
        d.rectangle((x, 80, x + 3, 107), fill="#799877")
        for y in range(83, 107, 4):
            d.line((x, y, x + 2, y), fill="#aac197")
    flower_box(d, 19, 108, 27)
    flower_box(d, 111, 108, 27)
    # Recessed entrance with lintel, sunlit doorstep and small brass handle.
    d.rectangle((61, 75, 97, 121), fill="#a99273")
    d.rectangle((64, 77, 93, 119), fill="#4f786d" if clinic else "#996e50")
    d.line((65, 78, 92, 78), fill="#bed0a9" if clinic else "#e0b887")
    d.rectangle((68, 81, 89, 102), fill="#426c70")
    d.polygon([(69, 82), (87, 82), (69, 96)], fill="#8bb5aa")
    d.line((70, 84, 85, 84), fill="#d3dec0")
    d.rectangle((70, 107, 87, 115), outline="#8baa86" if clinic else "#b88d61")
    d.rectangle((87, 105, 89, 107), fill="#f0cc7c")
    d.rectangle((58, 120, 99, 123), fill="#e6d7af")
    d.line((59, 120, 98, 120), fill="#fff1cf")
    # Shop sign is a material object, with a framed face and tiny hanging brackets.
    d.rectangle((43, 66, 114, 78), fill="#887a61")
    d.rectangle((44, 66, 113, 76), fill="#faf0ca")
    d.line((45, 67, 112, 67), fill="#fff9df")
    if clinic:
        text(d, (63, 69), "CLINIC", "#4a776a")
        d.rectangle((49, 68, 57, 74), fill="#d97d68")
        d.line((53, 69, 53, 73), fill="#fff4d2")
        d.line((51, 71, 55, 71), fill="#fff4d2")
    else:
        text(d, (49, 69), "GENERAL STORE", "#866342")
    # A small weathered notice keeps the setting grounded in the outbreak fiction.
    d.rectangle((99, 91, 107, 103), fill="#f5e7ba", outline="#b59d76")
    d.rectangle((100, 92, 106, 94), fill="#c18367")
    d.line((101, 97, 105, 97), fill="#a09a7a")
    d.line((101, 100, 104, 100), fill="#a09a7a")
    save(image, name)


def tree(name, seed):
    rng = random.Random(seed)
    image, d = canvas((68, 92))
    d.ellipse((8, 72, 65, 89), fill=(57, 88, 72, 55))
    d.polygon([(26, 82), (30, 66), (27, 44), (38, 42), (37, 69), (42, 83), (37, 85)], fill="#647458")
    d.polygon([(28, 81), (32, 65), (30, 45), (35, 44), (35, 71), (38, 83)], fill="#b29461")
    d.line((31, 58, 32, 78), fill="#d9b47c", width=2)
    d.line((36, 59, 35, 77), fill="#897a54")
    # The outline belongs to the whole canopy, not to every leaf cluster.
    clusters = [(20, 52, 16), (45, 51, 16), (15, 35, 13), (52, 34, 13),
                (24, 29, 18), (43, 25, 16), (32, 17, 14), (33, 43, 19)]
    mask = Image.new("L", image.size)
    md = ImageDraw.Draw(mask)
    for cx, cy, r in clusters:
        md.ellipse((cx - r, cy - r + 3, cx + r, cy + r - 2), fill=255)
    image.paste("#437b58", mask=mask.filter(ImageFilter.MaxFilter(3)))
    foliage = Image.new("RGBA", image.size, "#558959")
    fd = ImageDraw.Draw(foliage)
    for cx, cy, r in clusters:
        fd.ellipse((cx - r, cy - r, cx + r - 2, cy + r - 5), fill="#75aa60")
        fd.ellipse((cx - r + 1, cy - r, cx + r - 6, cy + r - 10),
                   fill=rng.choice(["#93bf6c", "#9dc873", "#a4cc73"]))
        for _ in range(18):
            xx, yy = cx + rng.randrange(-r + 3, r - 2), cy + rng.randrange(-r + 3, r - 2)
            fd.rectangle((xx, yy, xx + 3, yy + 1), fill=rng.choice(["#badb87", "#8dbd68", "#6fa561"]))
            if yy < cy:
                fd.point((xx + 1, yy - 1), fill="#c8e08c")
    image.paste(foliage, mask=mask)
    d = ImageDraw.Draw(image)
    # A few berries / seed pods distinguish the two canopy variants.
    if seed % 2:
        for x, y in [(15, 43), (29, 31), (48, 42)]:
            d.rectangle((x, y, x + 2, y + 2), fill="#d79768")
            d.point((x, y), fill="#efbf76")
    save(image, name)


def car():
    image, d = canvas((74, 40))
    d.ellipse((4, 24, 73, 39), fill=(58, 84, 81, 60))
    for x in (14, 52):
        d.rectangle((x, 6, x + 9, 13), fill="#4e5d5c")
        d.rectangle((x, 28, x + 9, 35), fill="#4e5d5c")
        d.line((x + 2, 32, x + 7, 32), fill="#a5b6a8")
    d.polygon([(6, 12), (13, 8), (59, 8), (69, 15), (69, 27), (62, 32), (10, 31), (4, 25)], fill="#726e60")
    d.polygon([(8, 13), (15, 10), (58, 10), (67, 16), (66, 26), (60, 29), (10, 28), (7, 24)], fill="#c77867")
    d.line((14, 11, 56, 11), fill="#f5c197", width=2)
    d.line((10, 27, 61, 27), fill="#ab685b")
    d.rectangle((26, 12, 48, 27), fill="#4f777c")
    d.rectangle((29, 12, 44, 25), fill="#e0a086")
    d.line((31, 13, 41, 13), fill="#ffe2b3", width=2)
    d.polygon([(22, 13), (26, 13), (26, 25), (20, 24)], fill="#8bb5b1")
    d.line((23, 14, 23, 19), fill="#dbebce")
    d.polygon([(48, 13), (52, 14), (56, 24), (49, 25)], fill="#8fbeb7")
    d.line((50, 14, 54, 22), fill="#dbe5c9")
    d.line((52, 19, 55, 22), fill="#658c8f")
    d.rectangle((63, 14, 66, 17), fill="#ffeac1")
    d.rectangle((63, 25, 66, 27), fill="#ecd1a0")
    d.line((68, 17, 68, 24), fill="#d7d8ba", width=2)
    d.line((6, 16, 6, 23), fill="#b8c5b3")
    d.rectangle((8, 14, 10, 16), fill="#b05f56")
    d.line((58, 13, 62, 16), fill="#e1a07d")
    d.rectangle((17, 23, 20, 24), fill="#dbac7b")
    save(image, "wrecked_car")


def props():
    image, d = canvas((28, 32))
    d.ellipse((3, 24, 27, 31), fill=(60, 85, 78, 65))
    d.rectangle((4, 8, 23, 26), fill="#588b80")
    d.rectangle((6, 9, 21, 26), fill="#79aaa0")
    d.rectangle((7, 10, 10, 24), fill="#b0c9ad")
    d.rectangle((19, 11, 21, 25), fill="#5a8f88")
    d.ellipse((4, 3, 23, 12), fill="#719b8d", outline="#4e796f")
    d.arc((5, 3, 22, 11), 185, 350, fill="#d5dcbc")
    d.ellipse((8, 5, 20, 9), fill="#9ebcad", outline="#568175")
    d.rectangle((17, 6, 18, 7), fill="#d0d6b3")
    for y in (14, 23):
        d.line((5, y, 22, y), fill="#5c8277", width=2)
        d.line((6, y, 20, y), fill="#c2c9a8")
    d.rectangle((13, 17, 17, 20), fill="#f0d390")
    save(image, "barrel")
    image, d = canvas((32, 34))
    d.polygon([(3, 27), (28, 24), (31, 30), (7, 33)], fill=(61, 84, 74, 60))
    d.rectangle((3, 8, 28, 29), fill="#987c58")
    d.rectangle((5, 11, 26, 27), fill="#c29b68")
    d.polygon([(3, 8), (10, 2), (30, 2), (28, 9)], fill="#e2be83", outline="#9a805b")
    d.line((6, 8, 28, 8), fill="#ffe0a4")
    d.line((11, 3, 28, 3), fill="#f3d79b")
    d.polygon([(28, 9), (30, 3), (30, 23), (28, 29)], fill="#ac8b5d")
    for y in (14, 19, 24):
        d.line((5, y, 26, y), fill="#a88458")
        d.line((5, y + 1, 26, y + 1), fill="#d6b17a")
    d.line((7, 12, 23, 26), fill="#e8c68b", width=3)
    d.line((23, 12, 7, 26), fill="#d5b079", width=2)
    for x in (6, 25):
        for y in (11, 26):
            d.point((x, y), fill="#727766")
    save(image, "crate")
    image, d = canvas((72, 34))
    d.rectangle((4, 27, 15, 32), fill="#65786e")
    d.rectangle((57, 27, 68, 32), fill="#65786e")
    d.polygon([(4, 27), (9, 9), (63, 9), (68, 27)], fill="#c0b994", outline="#8f987f")
    d.rectangle((10, 10, 62, 21), fill="#efd097")
    for x in range(3, 61, 14):
        d.polygon([(x + 7, 10), (x + 14, 10), (x + 6, 21), (x, 21)], fill="#74877a")
    d.line((10, 9, 62, 9), fill="#fff0c5")
    d.rectangle((12, 25, 60, 27), fill="#e1d7ae")
    d.line((10, 23, 61, 23), fill="#a4a78d")
    save(image, "barricade")
    image, d = canvas((104, 53))
    for x in range(6, 101, 8):
        d.line((x, 13, min(x + 23, 100), 42), fill="#b4c7ad")
        d.line((x, 42, min(x + 23, 100), 13), fill="#8caa95")
    for x in (3, 99):
        d.rectangle((x, 6, x + 3, 50), fill="#718e7d")
        d.line((x + 1, 7, x + 1, 49), fill="#dce2be")
        d.rectangle((x - 1, 48, x + 5, 51), fill="#a5b599")
    d.line((5, 12, 101, 12), fill="#c7d5b4", width=2)
    d.line((5, 43, 101, 43), fill="#afc4a7")
    # Old warning tape is a small warm accent against the green mesh.
    d.polygon([(13, 20), (51, 27), (51, 30), (13, 23)], fill="#e5c68a")
    for x in range(16, 50, 7):
        d.point((x, 23 + (x - 16) // 7), fill="#ad9c70")
    save(image, "fence")
    image, d = canvas((42, 100))
    d.ellipse((19, 91, 40, 99), fill=(54, 80, 78, 60))
    d.rectangle((25, 19, 29, 94), fill="#657d74")
    d.line((26, 22, 26, 93), fill="#b8c4a4")
    d.rectangle((23, 90, 32, 96), fill="#819783")
    d.line((24, 90, 31, 90), fill="#d5d9b7")
    d.line((26, 21, 14, 11), fill="#718c7e", width=3)
    d.line((25, 20, 14, 10), fill="#c2ceae")
    d.rectangle((4, 11, 21, 15), fill="#7b927d")
    d.rectangle((6, 15, 19, 18), fill="#f5dfad")
    d.line((7, 15, 18, 15), fill="#fff4d8")
    save(image, "streetlamp")


def garden_props():
    image, d = canvas((58, 36))
    d.polygon([(5, 29), (51, 29), (57, 35), (12, 35)], fill=(59, 83, 71, 55))
    for x in (9, 45):
        d.line((x, 20, x - 2, 31), fill="#6d887a", width=3)
        d.line((x + 3, 20, x + 5, 31), fill="#6d887a", width=3)
        d.line((x, 10, x, 25), fill="#a5b299", width=2)
    for y in (5, 10, 15):
        d.rectangle((5, y, 52, y + 3), fill="#bb915f")
        d.line((6, y, 51, y), fill="#efc68b")
        d.line((6, y + 3, 51, y + 3), fill="#9c7d57")
    for y in (22, 25):
        d.rectangle((3, y, 54, y + 2), fill="#d1a76e")
        d.line((4, y, 53, y), fill="#f0cf91")
    d.line((4, 18, 4, 24), fill="#91a28b", width=2)
    d.line((54, 18, 54, 24), fill="#91a28b", width=2)
    save(image, "garden_bench")
    image, d = canvas((58, 32))
    d.ellipse((4, 21, 57, 31), fill=(58, 89, 71, 50))
    d.rectangle((3, 15, 53, 28), fill="#b49c78")
    d.rectangle((5, 17, 51, 27), fill="#d2b78a")
    d.line((3, 15, 53, 15), fill="#f4dcad", width=2)
    for x in range(9, 52, 11):
        d.line((x, 18, x, 26), fill="#b69f78")
    for x, y in [(10, 14), (21, 10), (34, 12), (46, 12)]:
        d.ellipse((x - 7, y - 7, x + 6, y + 7), fill="#619356")
        d.ellipse((x - 6, y - 7, x + 3, y + 1), fill="#9bc56c")
        flower(d, x, y - 4, "#f6e3bc" if x % 2 else "#e79980")
    save(image, "flower_planter")
    image, d = canvas((26, 43))
    d.ellipse((7, 34, 25, 42), fill=(56, 87, 80, 50))
    d.rectangle((11, 16, 15, 39), fill="#647f72")
    d.line((12, 20, 12, 37), fill="#b7bda0")
    d.rectangle((4, 7, 23, 21), fill="#557f8a")
    d.pieslice((3, 2, 24, 17), 180, 360, fill="#75a9ac")
    d.rectangle((6, 7, 21, 19), fill="#6e9ca2")
    d.line((7, 8, 21, 8), fill="#bed6c2")
    d.rectangle((8, 11, 20, 13), fill="#456874")
    d.rectangle((9, 16, 18, 18), fill="#f1dbac")
    d.line((5, 21, 22, 21), fill="#abc7b2")
    save(image, "mailbox")


def build_environment():
    ASSETS.mkdir(parents=True, exist_ok=True)
    terrain()
    building("clinic", True)
    building("ranger", False)
    tree("tree_a", 31)
    tree("tree_b", 74)
    car()
    props()
    garden_props()


if __name__ == "__main__":
    build_environment()
