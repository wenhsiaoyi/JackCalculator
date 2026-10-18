"""從 docs/icons/Logo2.jpg 產生四平台圖示（Android legacy／自適應、iOS appiconset、Windows .ico）。

用法：python tool/generate_icons.py
"""

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "icons" / "Logo2.jpg"
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"
IOS_SET = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
WINDOWS_ICO = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"

MIPMAP_DENSITIES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
ADAPTIVE_DP = 108
# 自適應圖示安全區是直徑 66dp 的圓（半径 33dp）；取 31 留一點邊距
SAFE_RADIUS_RATIO = 31 / 108
ICO_SIZES = (16, 24, 32, 48, 64, 128, 256)


def load_source():
    return np.asarray(Image.open(SOURCE).convert("RGB")).astype(np.int16)


def square_bbox(rgb):
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    mask = (r > 120) & (r > b + 40) & (g > 40)
    ys, xs = np.where(mask)
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def face_color(rgb):
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    face = (r > 200) & ~((r > 200) & (g > 200) & (b > 200))
    return tuple(int(round(c)) for c in rgb[face].mean(axis=0))


def glyph_alpha(rgb):
    lo, hi = 150.0, 215.0
    soft = np.clip((rgb.min(axis=2) - lo) / (hi - lo), 0, 1)
    solid = (rgb[..., 0] > 200) & (rgb[..., 1] > 200) & (rgb[..., 2] > 200)
    alpha = np.where(solid, 1.0, soft)
    ys, xs = np.where(alpha > 0.5)
    box = (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)
    cx, cy = (box[0] + box[2] - 1) / 2, (box[1] + box[3] - 1) / 2
    radius = float(np.hypot(xs - cx, ys - cy).max())
    return alpha, box, radius


def rounded_square(size, radius_ratio):
    yy, xx = np.mgrid[0:size, 0:size]
    r = radius_ratio * size
    c = np.stack([np.minimum(xx, size - 1 - xx), np.minimum(yy, size - 1 - yy)], axis=-1)
    inside = np.where(
        c.min(axis=-1) >= r,
        True,
        (np.maximum(r - c[..., 0], 0) ** 2 + np.maximum(r - c[..., 1], 0) ** 2) <= r * r,
    )
    a = (inside * 255).astype(np.uint8)
    return Image.fromarray(a, "L").filter(ImageFilter.GaussianBlur(max(0.6, size / 300)))


def circle_mask(size):
    yy, xx = np.mgrid[0:size, 0:size]
    d = np.hypot(xx - (size - 1) / 2, yy - (size - 1) / 2)
    a = np.clip((size / 2 - d) * 2, 0, 1)
    return Image.fromarray((a * 255).astype(np.uint8), "L")


def to_rgba(base, mask, size):
    img = base.convert("RGB").resize((size, size), Image.LANCZOS)
    img.putalpha(mask.resize((size, size), Image.LANCZOS))
    return img


def main():
    rgb = load_source()
    x0, y0, x1, y1 = square_bbox(rgb)
    side = min(x1 - x0, y1 - y0)
    square = Image.fromarray(rgb[y0:y1, x0:x1].astype(np.uint8))
    orange = face_color(rgb)
    alpha, (gx0, gy0, gx1, gy1), glyph_radius = glyph_alpha(rgb)

    hi_res = 512
    sq_mask = rounded_square(hi_res, 0.2214)
    legacy_hi = to_rgba(square, sq_mask, hi_res)
    round_hi = to_rgba(square, circle_mask(hi_res), hi_res)

    glyph = Image.fromarray(
        np.dstack([np.full(rgb.shape[:2], 255, np.uint8)] * 3 + [(alpha * 255).astype(np.uint8)]),
        "RGBA",
    ).crop((gx0, gy0, gx1, gy1))

    for dens, px in MIPMAP_DENSITIES.items():
        out = ANDROID_RES / f"mipmap-{dens}"
        out.mkdir(parents=True, exist_ok=True)
        legacy_hi.resize((px, px), Image.LANCZOS).save(out / "ic_launcher.png")
        round_hi.resize((px, px), Image.LANCZOS).save(out / "ic_launcher_round.png")

        canvas = round(px * ADAPTIVE_DP / MIPMAP_DENSITIES["mdpi"])
        bg = Image.new("RGB", (canvas, canvas), orange)
        bg.save(out / "ic_launcher_background.png")

        scale = canvas * SAFE_RADIUS_RATIO / glyph_radius
        gw = round(glyph.width * scale)
        gh = round(glyph.height * scale)
        fg = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
        scaled = glyph.resize((gw, gh), Image.LANCZOS)
        fg.paste(scaled, ((canvas - gw) // 2, (canvas - gh) // 2), scaled)
        fg.save(out / "ic_launcher_foreground.png")

    anydpi = ANDROID_RES / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    adaptive_xml = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@mipmap/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        "</adaptive-icon>\n"
    )
    for name in ("ic_launcher.xml", "ic_launcher_round.xml"):
        (anydpi / name).write_text(adaptive_xml, encoding="utf-8")

    face_crop_side = round(side * 0.73)
    face = square.crop(
        (
            square.width // 2 - face_crop_side // 2,
            square.height // 2 - face_crop_side // 2,
            square.width // 2 + face_crop_side // 2,
            square.height // 2 + face_crop_side // 2,
        )
    )
    contents = json.loads((IOS_SET / "Contents.json").read_text(encoding="utf-8"))
    for entry in contents["images"]:
        pt = float(entry["size"].split("x")[0])
        px = round(pt * int(entry["scale"].rstrip("x")))
        face.resize((px, px), Image.LANCZOS).convert("RGB").save(IOS_SET / entry["filename"])

    legacy_hi.resize((256, 256), Image.LANCZOS).save(
        WINDOWS_ICO, format="ICO", sizes=[(s, s) for s in ICO_SIZES]
    )

    print(f"square bbox {(x0, y0, x1, y1)} face color {orange} glyph box {(gx0, gy0, gx1, gy1)}")
    print("icons generated")


if __name__ == "__main__":
    main()
