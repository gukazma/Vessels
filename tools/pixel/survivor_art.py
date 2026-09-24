"""Draw the survivor's original 4-direction, 4-frame pixel animation.

The sprite contract is 32 x 40 pixels per frame, with feet at y=35.
Rows are down, left, right, up; column zero is the resting pose.
Run this file directly or import ``survivor`` from the world art builder.
"""

from pathlib import Path

from PIL import Image, ImageDraw


OUTPUT = Path(__file__).resolve().parents[2] / "assets" / "pixel" / "survivor.png"
AIMING_OUTPUT = OUTPUT.with_name("survivor_aiming.png")
INK = "#293a49"
DEEP = "#365c70"
COAT = "#438f99"
LIGHT = "#80c3bd"
RIM = "#e4e8bf"
SKIN = "#e8ba8e"
SKIN_SHADOW = "#bd8069"
HAIR = "#594641"
HAIR_LIGHT = "#957657"
OCHRE = "#e3aa58"
GOLD_LIGHT = "#ffe0a0"
GOLD_DARK = "#ad7b4a"
PANTS = "#506e87"
PANTS_LIGHT = "#89a2af"
LEATHER = "#916549"


def _front_legs(draw, frame, back=False):
    """Alternate boot height and trouser folds without changing the origin."""
    left_lift, right_lift = ((0, 0), (2, 0), (0, 0), (0, 2))[frame]
    for x, lift in ((10, left_lift), (18, right_lift)):
        draw.polygon([(x, 25), (x + 5, 25), (x + 5, 31 - lift),
                      (x + 6, 34 - lift), (x + 6, 35 - lift),
                      (x, 35 - lift), (x - 1, 33 - lift)], fill=INK)
        draw.rectangle((x + 1, 26, x + 4, 31 - lift), fill=PANTS)
        draw.line((x + 1, 26, x + 1, 29 - lift), fill=PANTS_LIGHT)
        draw.line((x + 2, 31 - lift, x + 4, 31 - lift), fill=DEEP)
        draw.rectangle((x, 33 - lift, x + 4, 34 - lift), fill=LEATHER)
        draw.point((x, 33 - lift), fill="#a08b75")
        if not back:
            draw.line((x + 1, 34 - lift, x + 4, 34 - lift), fill="#ab9f84")


def _front(frame, back=False, armed=False):
    image = Image.new("RGBA", (32, 40))
    d = ImageDraw.Draw(image)
    d.ellipse((7, 33, 26, 37), fill=(8, 16, 28, 105))
    _front_legs(d, frame, back)
    bob = int(frame in (1, 3))
    # The torso is drawn separately so walk bobbing does not move planted feet.
    body = Image.new("RGBA", (32, 34))
    p = ImageDraw.Draw(body)
    swing = (0, 1, 0, -1)[frame]
    # Pack straps and shoulders break up the outline before the coat.
    p.polygon([(9, 15), (13, 13), (21, 13), (24, 16), (24, 25),
               (20, 28), (10, 27), (8, 22)], fill=INK)
    p.rectangle((10, 16, 12, 24), fill=GOLD_DARK)
    if armed:
        # Raised elbows silhouette the aiming pose. In the rear view the
        # forearms reach away from the camera, behind the head and rucksack.
        p.polygon([(9, 16), (12, 16), (14, 14), (17, 13), (20, 14),
                   (23, 16), (25, 17), (27, 20), (25, 22), (22, 21),
                   (19, 18), (14, 18), (11, 21), (8, 22), (6, 20),
                   (7, 17)], fill=INK)
        p.polygon([(8, 17), (11, 17), (12, 19), (9, 21), (7, 20)], fill=COAT)
        p.polygon([(23, 17), (25, 18), (26, 20), (24, 21), (22, 19)], fill=COAT)
        p.line((8, 17, 10, 17), fill=RIM)
        p.line((7, 19, 9, 20), fill=LIGHT)
        p.line((24, 18, 25, 20), fill=LIGHT)
        p.line((7, 20, 9, 21), fill=OCHRE)
    else:
        for x, dy in ((7, swing), (23, -swing)):
            p.polygon([(x + 1, 16 + dy), (x + 3, 16 + dy),
                       (x + 4, 20 + dy), (x + 3, 25 + dy),
                       (x, 25 + dy), (x - 1, 21 + dy)], fill=INK)
            p.line((x + 1, 17 + dy, x + 1, 21 + dy), fill=LIGHT, width=2)
            p.point((x, 18 + dy), fill=RIM)
            p.rectangle((x, 22 + dy, x + 2, 23 + dy), fill=COAT)
            p.rectangle((x, 24 + dy, x + 2, 25 + dy), fill=LEATHER)
            p.point((x, 24 + dy), fill=SKIN)
    p.polygon([(12, 15), (21, 15), (23, 18), (22, 24),
               (23, 27), (18, 28), (16, 26), (14, 28), (9, 27),
               (10, 22), (10, 17)], fill=INK)
    p.polygon([(12, 16), (21, 16), (21, 24), (22, 26),
               (18, 26), (16, 25), (13, 26), (10, 26), (11, 18)], fill=COAT)
    p.line((12, 17, 12, 22), fill=LIGHT)
    p.line((11, 17, 14, 16), fill=RIM)
    p.rectangle((20, 18, 21, 24), fill=DEEP)
    p.line((11, 25, 14, 25), fill=LIGHT)
    # Ochre identification band and a belt pouch remain visible in every row.
    if not armed:
        p.rectangle((7, 20 + swing, 9, 21 + swing), fill=OCHRE)
        p.point((7, 20 + swing), fill=GOLD_LIGHT)
    if back:
        p.polygon([(12, 15), (20, 15), (23, 18), (23, 25),
                   (20, 28), (12, 27), (10, 24), (10, 18)], fill=INK)
        p.rectangle((12, 17, 21, 25), fill=GOLD_DARK)
        p.polygon([(12, 17), (20, 17), (21, 19), (20, 21),
                   (12, 21), (11, 19)], fill=OCHRE)
        p.line((13, 17, 19, 17), fill=GOLD_LIGHT)
        p.rectangle((13, 22, 19, 26), fill="#a27c4f")
        p.line((13, 22, 19, 22), fill=OCHRE)
        p.rectangle((15, 20, 17, 23), fill=INK)
        p.point((16, 21), fill=RIM)
        p.rectangle((10, 21, 11, 25), fill=LEATHER)
        p.line((20, 23, 20, 25), fill=GOLD_LIGHT)
        p.rectangle((21, 16, 23, 19), fill=DEEP)
        p.point((22, 16), fill=RIM)
    else:
        p.line((16, 18, 16, 25), fill=DEEP)
        p.line((17, 19, 17, 24), fill=LIGHT)
        p.rectangle((18, 20, 20, 22), fill=DEEP)
        p.line((18, 20, 20, 20), fill=RIM)
        p.line((12, 16, 19, 24), fill=INK, width=2)
        p.line((12, 16, 19, 23), fill=LEATHER)
        p.rectangle((18, 24, 22, 26), fill=INK)
        p.rectangle((19, 24, 21, 25), fill=GOLD_DARK)
        p.point((20, 24), fill=GOLD_LIGHT)
        if armed:
            # Both sleeves fold inward to the grip at (17, 22). The hands
            # stay raised through all four strides; only the torso bobs.
            p.polygon([(8, 18), (11, 18), (12, 21), (16, 21), (18, 20),
                       (21, 21), (23, 18), (25, 19), (24, 23),
                       (20, 24), (17, 23), (13, 24), (9, 22)], fill=INK)
            p.polygon([(9, 19), (11, 20), (12, 22), (15, 22),
                       (14, 23), (10, 21)], fill=LIGHT)
            p.polygon([(24, 19), (23, 22), (20, 23), (19, 21),
                       (21, 22), (23, 19)], fill=COAT)
            p.line((9, 20, 11, 22), fill=OCHRE)
            p.line((21, 22, 23, 21), fill=LIGHT)
            p.rectangle((15, 21, 18, 23), fill=LEATHER)
            p.line((16, 21, 18, 21), fill=SKIN)
            p.point((18, 22), fill=SKIN_SHADOW)
    # Rounded head with uneven hair and small ears rather than a square mask.
    p.polygon([(12, 5), (19, 4), (23, 7), (23, 12), (21, 15),
               (19, 17), (13, 16), (10, 12), (10, 8)], fill=INK)
    p.polygon([(12, 8), (21, 8), (21, 13), (19, 15),
               (14, 15), (12, 13)], fill=SKIN)
    p.rectangle((11, 10, 12, 12), fill=SKIN_SHADOW)
    p.line((20, 11, 20, 14), fill=SKIN_SHADOW)
    p.point((21, 11), fill=SKIN)
    p.polygon([(12, 5), (19, 5), (22, 7), (22, 10), (20, 9),
               (18, 8), (17, 10), (15, 8), (12, 10), (11, 9), (11, 7)], fill=HAIR)
    p.line((12, 6, 17, 5), fill=HAIR_LIGHT)
    p.line((12, 7, 14, 7), fill="#998168")
    if back:
        p.polygon([(11, 9), (22, 8), (22, 12), (20, 15),
                   (13, 15), (11, 12)], fill=HAIR)
        p.line((12, 10, 12, 12), fill=HAIR_LIGHT)
        p.line((14, 14, 18, 14), fill=INK)
        p.line((12, 15, 21, 15), fill=GOLD_DARK)
    else:
        p.point((14, 11), fill=INK)
        p.point((19, 11), fill=INK)
        p.point((16, 13), fill="#efd0a3")
        p.line((13, 15, 20, 15), fill=GOLD_DARK, width=2)
        p.line((13, 15, 19, 15), fill=OCHRE)
        p.line((13, 16, 17, 16), fill=GOLD_LIGHT)
        p.polygon([(18, 16), (21, 16), (20, 20), (18, 19)], fill=OCHRE)
        p.point((19, 17), fill=GOLD_LIGHT)
    image.alpha_composite(body, (0, bob))
    return image


def _side(frame, left=False, armed=False):
    image = Image.new("RGBA", (32, 40))
    d = ImageDraw.Draw(image)
    d.ellipse((7, 33, 26, 37), fill=(8, 16, 28, 105))
    # Side steps open the silhouette forward and backward, with planted heels.
    stride = (0, 3, 0, -3)[frame]
    for rear in (True, False):
        dx = -stride if rear else stride
        x = 13 if rear else 16
        lift = 1 if (stride > 0 and rear) or (stride < 0 and not rear) else 0
        d.polygon([(x, 25), (x + 4, 25), (x + dx + 4, 31 - lift),
                   (x + dx + 6, 33 - lift), (x + dx + 6, 35 - lift),
                   (x + dx, 35 - lift), (x + dx - 1, 32 - lift)], fill=INK)
        d.polygon([(x + 1, 26), (x + 3, 26), (x + dx + 3, 31 - lift),
                   (x + dx, 31 - lift)], fill=DEEP if rear else PANTS)
        if not rear:
            d.line((x + 1, 27, x + dx, 30 - lift), fill=PANTS_LIGHT)
        d.line((x + dx + 1, 33 - lift, x + dx + 4, 33 - lift), fill=LEATHER)
        d.line((x + dx + 1, 34 - lift, x + dx + 5, 34 - lift), fill="#9d9880")
    bob = int(frame in (1, 3))
    body = Image.new("RGBA", (32, 34))
    p = ImageDraw.Draw(body)
    p.polygon([(11, 14), (19, 14), (22, 18), (21, 23), (23, 27),
               (12, 28), (10, 23)], fill=INK)
    p.polygon([(13, 15), (19, 15), (20, 19), (20, 24),
               (21, 26), (12, 26), (12, 17)], fill=COAT)
    p.line((14, 16, 18, 16), fill=LIGHT)
    p.line((13, 25, 20, 25), fill=LIGHT)
    # Loaded rucksack on the far side of the survivor.
    p.polygon([(9, 15), (12, 15), (14, 18), (13, 26), (9, 27),
               (7, 25), (7, 18)], fill=INK)
    p.rectangle((8, 18, 11, 24), fill=GOLD_DARK)
    p.rectangle((8, 17, 11, 20), fill=OCHRE)
    p.line((9, 17, 11, 17), fill=GOLD_LIGHT)
    p.point((10, 22), fill=GOLD_LIGHT)
    p.line((12, 16, 15, 18), fill=LEATHER)
    if armed:
        # The support arm reaches the fore-end; the near elbow folds up to
        # the trigger hand at (25, 20). Mirroring gives the left-hand socket.
        p.polygon([(20, 16), (23, 16), (25, 17), (28, 17), (29, 19),
                   (27, 20), (23, 19), (20, 19)], fill=INK)
        p.line((21, 17, 25, 18), fill=DEEP, width=2)
        p.line((26, 18, 28, 18), fill=SKIN)
        p.polygon([(16, 17), (19, 17), (21, 20), (24, 19),
                   (26, 19), (27, 21), (23, 23), (19, 24),
                   (16, 22), (15, 19)], fill=INK)
        p.polygon([(17, 18), (19, 19), (20, 21), (22, 21),
                   (23, 22), (19, 23), (17, 21)], fill=COAT)
        p.line((17, 18, 17, 20), fill=LIGHT, width=2)
        p.point((17, 18), fill=RIM)
        p.line((17, 21, 19, 22), fill=OCHRE, width=2)
        p.line((21, 22, 23, 21), fill=LIGHT)
        p.rectangle((24, 19, 26, 21), fill=LEATHER)
        p.line((24, 19, 26, 19), fill=SKIN)
        p.point((26, 20), fill=SKIN_SHADOW)
    else:
        # The near sleeve and glove swing opposite the lead foot.
        swing = -stride // 2
        p.polygon([(16, 17), (19, 17), (20 + swing, 22),
                   (19 + swing, 26), (16 + swing, 26), (15 + swing, 22)], fill=INK)
        p.line((17, 18, 17 + swing, 21), fill=LIGHT, width=2)
        p.point((17, 18), fill=RIM)
        p.line((16 + swing, 21, 18 + swing, 21), fill=OCHRE, width=2)
        p.line((16 + swing, 23, 18 + swing, 23), fill=COAT, width=2)
        p.line((16 + swing, 25, 18 + swing, 25), fill=LEATHER)
        p.point((18 + swing, 25), fill=SKIN)
    # Profile: protruding nose, swept forelock, ear, short scarf at the nape.
    p.polygon([(13, 5), (20, 4), (23, 7), (23, 10), (25, 12),
               (24, 14), (22, 14), (21, 16), (15, 16), (12, 13), (11, 8)], fill=INK)
    p.polygon([(15, 8), (22, 8), (22, 11), (24, 12), (22, 13),
               (21, 15), (16, 15), (14, 12)], fill=SKIN)
    p.line((16, 13, 19, 14), fill=SKIN_SHADOW)
    p.polygon([(13, 6), (19, 5), (22, 6), (23, 8), (21, 9),
               (19, 8), (17, 10), (16, 12), (13, 12), (12, 9)], fill=HAIR)
    p.line((13, 7, 17, 6), fill=HAIR_LIGHT)
    p.point((14, 6), fill="#998168")
    p.point((17, 11), fill=SKIN_SHADOW)
    p.point((21, 10), fill=INK)
    p.point((23, 12), fill="#efd0a3")
    p.line((16, 15, 21, 15), fill=GOLD_DARK, width=2)
    p.line((16, 15, 20, 15), fill=GOLD_LIGHT)
    p.polygon([(14, 15), (16, 16), (14, 20), (12, 19)], fill=OCHRE)
    image.alpha_composite(body, (0, bob))
    return image.transpose(Image.Transpose.FLIP_LEFT_RIGHT) if left else image


def survivor():
    """Write walking and firearm poses with identical frame order and feet.

    Aiming hand sockets in frame zero: down (17, 22), left (6, 20),
    right (25, 20), up (17, 13). Odd columns add one pixel of torso bob.
    The rear socket is deliberately occluded by the head and backpack.
    """
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    for output, armed in ((OUTPUT, False), (AIMING_OUTPUT, True)):
        sheet = Image.new("RGBA", (128, 160))
        for frame in range(4):
            poses = (_front(frame, armed=armed),
                     _side(frame, left=True, armed=armed),
                     _side(frame, armed=armed),
                     _front(frame, back=True, armed=armed))
            for row, pose in enumerate(poses):
                sheet.alpha_composite(pose, (frame * 32, row * 40))
        sheet.save(output)


if __name__ == "__main__":
    survivor()
    print(f"Built survivor animations: {OUTPUT}, {AIMING_OUTPUT}")
