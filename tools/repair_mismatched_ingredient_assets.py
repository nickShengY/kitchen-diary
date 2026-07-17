from __future__ import annotations

from pathlib import Path
from random import Random
from typing import Iterable

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
MODULAR_DIR = ROOT / "generated" / "kitchen_asset_pack_v1" / "png" / "modular" / "ingredients"
STATE_DIR = ROOT / "generated" / "kitchen_asset_pack_v1" / "png" / "ingredient_states"

SIZE = 512
SCALE = 3
CANVAS = SIZE * SCALE


def sc(value: float) -> int:
    return int(round(value * SCALE))


def new_canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGBA", (CANVAS, CANVAS), (255, 255, 255, 0))
    return image, ImageDraw.Draw(image)


def finalize(image: Image.Image) -> Image.Image:
    image = image.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if not bbox:
        return image

    cropped = image.crop(bbox)
    scale = min(430 / cropped.width, 430 / cropped.height)
    cropped = cropped.resize(
        (max(1, int(cropped.width * scale)), max(1, int(cropped.height * scale))),
        Image.Resampling.LANCZOS,
    )
    fitted = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 0))
    fitted.alpha_composite(cropped, ((SIZE - cropped.width) // 2, (SIZE - cropped.height) // 2))
    return fitted


def ellipse(draw: ImageDraw.ImageDraw, box, fill, outline=(118, 86, 61, 255), width=5):
    draw.ellipse(tuple(sc(v) for v in box), fill=fill, outline=outline, width=sc(width))


def rounded(draw: ImageDraw.ImageDraw, box, radius, fill, outline=(118, 86, 61, 255), width=5):
    draw.rounded_rectangle(tuple(sc(v) for v in box), radius=sc(radius), fill=fill, outline=outline, width=sc(width))


def polygon(draw: ImageDraw.ImageDraw, points, fill, outline=(118, 86, 61, 255), width=5):
    draw.polygon([(sc(x), sc(y)) for x, y in points], fill=fill)
    draw.line([(sc(x), sc(y)) for x, y in points + [points[0]]], fill=outline, width=sc(width), joint="curve")


def line(draw: ImageDraw.ImageDraw, points, fill, width=6):
    draw.line([(sc(x), sc(y)) for x, y in points], fill=fill, width=sc(width), joint="curve")


def shadow(draw: ImageDraw.ImageDraw, box, alpha=45):
    draw.ellipse(tuple(sc(v) for v in box), fill=(68, 52, 41, alpha))


def save_asset(asset_id: str, image: Image.Image) -> None:
    for directory in (MODULAR_DIR, STATE_DIR):
        directory.mkdir(parents=True, exist_ok=True)
        image.save(directory / f"{asset_id}.png")


def draw_powder(color, accent, seed=1) -> Image.Image:
    rng = Random(seed)
    img, d = new_canvas()
    shadow(d, (155, 376, 360, 430), 42)
    polygon(d, [(142, 374), (252, 168), (370, 374)], color, outline=(119, 82, 45, 255), width=5)
    for _ in range(42):
        x = rng.randint(138, 374)
        y = rng.randint(318, 402)
        r = rng.randint(2, 5)
        ellipse(d, (x - r, y - r, x + r, y + r), accent, outline=accent, width=1)
    return finalize(img)


def draw_seed_pile(base, accent, seed=2) -> Image.Image:
    rng = Random(seed)
    img, d = new_canvas()
    shadow(d, (128, 378, 386, 430), 34)
    for _ in range(54):
        x = rng.randint(148, 360)
        y = rng.randint(210, 386)
        r = rng.randint(13, 19)
        ellipse(d, (x - r, y - r * 0.72, x + r, y + r * 0.72), base, outline=(110, 73, 43, 255), width=3)
        line(d, [(x - r * 0.45, y), (x + r * 0.45, y)], accent, width=2)
    return finalize(img)


def draw_leaf(points, fill, vein=(80, 126, 52, 255), outline=(73, 112, 50, 255)) -> Image.Image:
    img, d = new_canvas()
    polygon(d, points, fill, outline=outline, width=5)
    cx = sum(p[0] for p in points) / len(points)
    cy = sum(p[1] for p in points) / len(points)
    line(d, [(cx - 70, cy + 75), (cx + 78, cy - 82)], vein, width=4)
    return finalize(img)


def draw_ginger() -> Image.Image:
    img, d = new_canvas()
    shadow(d, (112, 360, 398, 424), 38)
    blobs = [
        (126, 238, 274, 362),
        (218, 200, 384, 330),
        (174, 148, 304, 252),
        (284, 250, 416, 360),
    ]
    for box in blobs:
        rounded(d, box, 48, (222, 178, 118, 255), outline=(137, 93, 55, 255), width=6)
    for x, y in [(175, 280), (252, 224), (314, 288), (228, 330)]:
        line(d, [(x - 24, y), (x + 18, y - 10)], (165, 116, 70, 155), width=4)
    return finalize(img)


def draw_chili_pepper() -> Image.Image:
    img, d = new_canvas()
    shadow(d, (132, 376, 378, 430), 36)
    polygon(d, [(168, 308), (210, 182), (323, 142), (386, 194), (338, 328), (236, 386)], (212, 42, 37, 255), outline=(130, 44, 34, 255), width=6)
    line(d, [(222, 190), (290, 158), (362, 194)], (244, 102, 86, 160), width=9)
    line(d, [(322, 146), (362, 98), (394, 126)], (74, 126, 45, 255), width=12)
    return finalize(img)


def draw_eggplant() -> Image.Image:
    img, d = new_canvas()
    shadow(d, (128, 374, 386, 430), 40)
    rounded(d, (154, 142, 372, 386), 108, (105, 57, 154, 255), outline=(68, 46, 105, 255), width=7)
    line(d, [(196, 166), (166, 252), (182, 340)], (158, 100, 199, 150), width=10)
    polygon(d, [(232, 128), (274, 82), (314, 128), (294, 166), (248, 166)], (84, 140, 55, 255), outline=(54, 102, 41, 255), width=5)
    line(d, [(274, 88), (288, 54)], (91, 83, 45, 255), width=9)
    return finalize(img)


def draw_bok_choy() -> Image.Image:
    img, d = new_canvas()
    shadow(d, (146, 382, 366, 430), 34)
    for x, h, c in [(186, 172, (86, 157, 72, 255)), (248, 132, (97, 174, 82, 255)), (314, 176, (73, 143, 68, 255))]:
        rounded(d, (x - 30, 210, x + 42, 390), 34, (237, 245, 206, 255), outline=(115, 139, 78, 255), width=4)
        ellipse(d, (x - 74, h, x + 70, h + 132), c, outline=(53, 113, 57, 255), width=5)
        line(d, [(x - 12, h + 120), (x + 8, h + 24)], (201, 231, 176, 150), width=4)
    return finalize(img)


def draw_herb(asset_id: str) -> Image.Image:
    rng = Random(asset_id)
    img, d = new_canvas()
    shadow(d, (152, 382, 360, 428), 30)
    stems = {
        "rosemary": [(176, 360), (256, 168), (338, 356)],
        "dill": [(178, 368), (240, 156), (326, 370)],
        "thyme": [(178, 356), (248, 188), (330, 350)],
    }.get(asset_id, [(174, 358), (252, 168), (338, 354)])
    for start, mid, end in [(stems[0], stems[1], stems[2]), ((214, 378), (270, 220), (372, 306))]:
        line(d, [start, mid, end], (66, 123, 54, 255), width=6)
    if asset_id in {"rosemary", "dill", "thyme"}:
        for i in range(28):
            x = 190 + i * 5 + rng.randint(-7, 7)
            y = 330 - i * 6 + rng.randint(-8, 8)
            line(d, [(x, y), (x + rng.choice([-34, 34]), y - rng.randint(8, 20))], (64, 139, 73, 255), width=4 if asset_id != "dill" else 3)
    else:
        palette = {
            "basil": (74, 157, 74, 255),
            "parsley": (60, 145, 62, 255),
            "cilantro": (69, 152, 82, 255),
            "mint": (78, 172, 111, 255),
            "oregano": (88, 142, 76, 255),
        }
        fill = palette.get(asset_id, (73, 153, 78, 255))
        for _ in range(14):
            x = rng.randint(150, 352)
            y = rng.randint(150, 330)
            w = rng.randint(38, 58)
            h = rng.randint(24, 42)
            ellipse(d, (x - w, y - h, x + w, y + h), fill, outline=(44, 110, 50, 255), width=4)
            line(d, [(x - w * 0.55, y), (x + w * 0.55, y)], (162, 218, 142, 110), width=3)
    return finalize(img)


def draw_bay_leaf() -> Image.Image:
    img, d = new_canvas()
    shadow(d, (146, 382, 370, 424), 28)
    polygon(d, [(170, 340), (220, 160), (322, 114), (378, 220), (320, 360)], (103, 136, 68, 255), outline=(75, 96, 52, 255), width=6)
    line(d, [(186, 328), (334, 144)], (187, 177, 103, 160), width=5)
    return finalize(img)


def draw_pepper() -> Image.Image:
    rng = Random(7)
    img, d = new_canvas()
    shadow(d, (126, 378, 384, 430), 40)
    for _ in range(28):
        x = rng.randint(150, 354)
        y = rng.randint(190, 376)
        r = rng.randint(18, 28)
        ellipse(d, (x - r, y - r, x + r, y + r), (39, 34, 35, 255), outline=(17, 16, 17, 255), width=4)
        ellipse(d, (x - r * 0.25, y - r * 0.35, x + r * 0.08, y - r * 0.12), (102, 96, 92, 150), outline=(102, 96, 92, 150), width=1)
    return finalize(img)


def draw_oil() -> Image.Image:
    img, d = new_canvas()
    shadow(d, (170, 384, 338, 430), 34)
    rounded(d, (204, 126, 312, 382), 42, (236, 208, 68, 255), outline=(95, 91, 47, 255), width=6)
    rounded(d, (226, 74, 290, 140), 18, (70, 83, 62, 255), outline=(45, 56, 45, 255), width=5)
    rounded(d, (216, 126, 300, 176), 22, (246, 233, 120, 255), outline=(95, 91, 47, 255), width=4)
    line(d, [(232, 178), (220, 330)], (255, 248, 160, 100), width=10)
    return finalize(img)


def draw_broth() -> Image.Image:
    img, d = new_canvas()
    shadow(d, (126, 382, 386, 430), 36)
    rounded(d, (124, 204, 388, 378), 58, (83, 68, 56, 255), outline=(78, 54, 45, 255), width=7)
    ellipse(d, (142, 174, 370, 284), (220, 151, 69, 255), outline=(78, 54, 45, 255), width=6)
    ellipse(d, (166, 198, 346, 260), (236, 174, 91, 255), outline=(236, 174, 91, 255), width=1)
    for x, y, color in [(206, 224, (91, 172, 85, 255)), (258, 238, (238, 210, 91, 255)), (304, 220, (220, 91, 73, 255)), (238, 210, (247, 238, 165, 255))]:
        ellipse(d, (x - 12, y - 8, x + 12, y + 8), color, outline=(112, 84, 51, 100), width=2)
    rounded(d, (374, 234, 436, 278), 20, (83, 68, 56, 255), outline=(78, 54, 45, 255), width=6)
    return finalize(img)


GENERATORS = {
    "ginger": draw_ginger,
    "chili_pepper": draw_chili_pepper,
    "eggplant": draw_eggplant,
    "bok_choy": draw_bok_choy,
    "basil": lambda: draw_herb("basil"),
    "parsley": lambda: draw_herb("parsley"),
    "cilantro": lambda: draw_herb("cilantro"),
    "mint": lambda: draw_herb("mint"),
    "thyme": lambda: draw_herb("thyme"),
    "oregano": lambda: draw_herb("oregano"),
    "rosemary": lambda: draw_herb("rosemary"),
    "dill": lambda: draw_herb("dill"),
    "pepper": draw_pepper,
    "paprika": lambda: draw_powder((202, 54, 38, 255), (238, 111, 72, 255), 11),
    "cumin": lambda: draw_seed_pile((160, 111, 55, 255), (104, 72, 39, 180), 12),
    "turmeric": lambda: draw_powder((226, 155, 39, 255), (247, 196, 66, 255), 13),
    "curry_powder": lambda: draw_powder((216, 143, 45, 255), (239, 191, 78, 255), 14),
    "chili_flakes": lambda: draw_seed_pile((191, 50, 42, 255), (241, 116, 73, 210), 15),
    "bay_leaf": draw_bay_leaf,
    "oil": draw_oil,
    "broth": draw_broth,
}


def main(ids: Iterable[str] = GENERATORS.keys()) -> None:
    for asset_id in ids:
        save_asset(asset_id, GENERATORS[asset_id]())
    print(f"repaired {len(list(ids))} ingredient assets")


if __name__ == "__main__":
    main()
