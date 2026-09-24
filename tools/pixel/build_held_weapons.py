"""Draw dedicated, original weapon sprites for the survivor's hand rig.

Run ``python tools/pixel/build_held_weapons.py`` from the project root.
Each transparent RGBA sprite is 24 x 16 pixels and points along +X.
The hand socket is pixel (6, 9), independent of the inventory icon.
Firearm barrels lie on y=6: pistol muzzle (20, 6), shotgun (23, 6).
The ``*_axial`` sprites show the narrow top of each firearm for forward/back
aiming, with no side-view trigger or hanging grip. Their hand socket stays
(6, 9); barrel center is y=9, pistol tip (18, 9), shotgun tip (22, 9).
Use nearest filtering and anchor at the hand socket before rotating.
"""

from pathlib import Path

from PIL import Image, ImageDraw

from build_items import GOLD, INK, METAL, RIM, STEEL, WOOD, WOOD_SHADE


OUTPUT = Path(__file__).resolve().parents[2] / "assets" / "pixel" / "weapons"
SIZE = (24, 16)


def _crowbar(draw):
    # A narrow steel shaft with a bent claw and wrapped hand grip.
    draw.line([(2, 9), (19, 9), (22, 7), (22, 4), (20, 3),
               (18, 4), (18, 6)], fill=INK, width=3)
    draw.line([(3, 9), (19, 9), (21, 7), (21, 4), (19, 4),
               (19, 5)], fill=METAL)
    draw.line((10, 8, 19, 8), fill=STEEL)
    draw.line((21, 4, 21, 6), fill=STEEL)
    draw.point((20, 4), fill=RIM)
    draw.rectangle((4, 8, 9, 10), fill="#bf6d59")
    draw.line((4, 8, 9, 8), fill="#e89b77")
    for x in (5, 7, 9):
        draw.point((x, 10), fill=WOOD_SHADE)
    draw.point((2, 9), fill=STEEL)


def _pistol(draw):
    # Compact slide above the socket; the trigger guard is a real cutout.
    draw.polygon([(3, 4), (19, 4), (20, 5), (20, 7), (13, 7),
                  (12, 11), (9, 11), (8, 13), (3, 13),
                  (5, 8), (3, 8)], fill=INK)
    draw.rectangle((4, 5, 19, 6), fill=METAL)
    draw.line((5, 4, 18, 4), fill=RIM)
    draw.line((9, 7, 17, 7), fill="#4c6e7f")
    draw.point((19, 5), fill=STEEL)
    draw.point((20, 6), fill=INK)
    draw.point((17, 3), fill=GOLD)
    for x in (5, 7):
        draw.point((x, 5), fill=INK)
    draw.polygon([(6, 8), (9, 8), (7, 12), (4, 12)], fill=WOOD)
    draw.line((6, 8, 5, 11), fill=GOLD)
    draw.point((7, 10), fill=WOOD_SHADE)
    draw.rectangle((10, 8, 11, 9), fill=(0, 0, 0, 0))
    draw.point((10, 8), fill=METAL)
    draw.point((9, 7), fill=STEEL)


def _shotgun(draw):
    # Wooden stock meets the socket; the long barrel stays slim and readable.
    draw.polygon([(1, 8), (6, 7), (9, 5), (23, 5), (23, 7),
                  (20, 8), (19, 10), (12, 10), (10, 9),
                  (8, 11), (4, 13), (1, 13)], fill=INK)
    draw.line((10, 5, 22, 5), fill=RIM)
    draw.line((10, 6, 22, 6), fill=METAL)
    draw.line((11, 7, 21, 7), fill=STEEL)
    draw.point((23, 6), fill=INK)
    draw.point((21, 4), fill=GOLD)
    draw.polygon([(2, 9), (7, 8), (9, 8), (7, 10),
                  (4, 12), (2, 12)], fill=WOOD)
    draw.line((2, 9, 6, 8), fill=GOLD)
    draw.line((3, 12, 6, 10), fill=WOOD_SHADE)
    draw.point((8, 7), fill=STEEL)
    draw.rectangle((13, 8, 18, 9), fill=WOOD)
    draw.line((13, 8, 18, 8), fill=GOLD)
    for x in (14, 16, 18):
        draw.point((x, 9), fill=WOOD_SHADE)
    draw.line((1, 10, 1, 12), fill=METAL)


def _pistol_axial(draw):
    """Foreshortened top of the slide, socket (6, 9), muzzle tip (18, 9)."""
    # The grip is underneath the slide in this view and must not protrude.
    draw.polygon([(4, 8), (5, 7), (16, 7), (18, 8),
                  (18, 10), (5, 10), (4, 9)], fill=INK)
    draw.line((6, 8, 16, 8), fill=RIM)
    draw.line((5, 9, 17, 9), fill=METAL)
    draw.line((9, 8, 13, 8), fill=STEEL)
    draw.point((7, 8), fill=INK)
    draw.point((16, 8), fill=GOLD)
    draw.point((18, 9), fill=INK)


def _shotgun_axial(draw):
    """Top of stock, receiver and barrel, socket (6, 9), tip (22, 9)."""
    # All parts share one axis; the stock and pump widen by only one pixel.
    draw.polygon([(1, 8), (4, 7), (11, 7), (12, 8), (22, 8),
                  (22, 10), (2, 10), (1, 9)], fill=INK)
    draw.line((2, 9, 5, 9), fill=WOOD)
    draw.line((3, 8, 5, 8), fill=GOLD)
    draw.line((6, 8, 11, 8), fill=RIM)
    draw.line((6, 9, 11, 9), fill=METAL)
    draw.rectangle((12, 8, 16, 9), fill=WOOD)
    draw.line((12, 8, 16, 8), fill=GOLD)
    for x in (13, 15):
        draw.point((x, 9), fill=WOOD_SHADE)
    draw.line((17, 9, 21, 9), fill=STEEL)
    draw.point((21, 8), fill=GOLD)
    draw.point((22, 9), fill=INK)


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, painter in (("crowbar", _crowbar), ("pistol", _pistol),
                          ("shotgun", _shotgun),
                          ("pistol_axial", _pistol_axial),
                          ("shotgun_axial", _shotgun_axial)):
        sprite = Image.new("RGBA", SIZE)
        painter(ImageDraw.Draw(sprite))
        sprite.save(OUTPUT / f"{name}.png")
    print("Built five dedicated held-weapon sprites (24 x 16).")


if __name__ == "__main__":
    main()
