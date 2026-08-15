#!/usr/bin/env python3
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "Assets"
ICONSET = ASSETS / "AppIcon.iconset"
MASTER = ASSETS / "AppIcon-1024.png"

SIZES = {
    "icon_16x16.png": 16,
    "icon_16x16@2x.png": 32,
    "icon_32x32.png": 32,
    "icon_32x32@2x.png": 64,
    "icon_128x128.png": 128,
    "icon_128x128@2x.png": 256,
    "icon_256x256.png": 256,
    "icon_256x256@2x.png": 512,
    "icon_512x512.png": 512,
    "icon_512x512@2x.png": 1024,
}


def lerp(a, b, t):
    return int(a + (b - a) * t)


def draw_master(size=1024):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = img.load()
    for y in range(size):
        t = y / (size - 1)
        r = lerp(18, 28, t)
        g = lerp(18, 30, t)
        b = lerp(20, 32, t)
        for x in range(size):
            px[x, y] = (r, g, b, 255)

    overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    margin = int(size * 0.16)
    folder = [
        (margin, int(size * 0.30)),
        (margin, int(size * 0.82)),
        (size - margin, int(size * 0.82)),
        (size - margin, int(size * 0.36)),
        (int(size * 0.58), int(size * 0.36)),
        (int(size * 0.50), int(size * 0.26)),
        (margin, int(size * 0.26)),
    ]
    draw.polygon(folder, fill=(199, 214, 189, 235))

    inset = int(size * 0.055)
    draw.rounded_rectangle(
        [margin + inset, int(size * 0.41), size - margin - inset, int(size * 0.76)],
        radius=max(size // 28, 4),
        fill=(16, 16, 18, 255),
    )

    bars = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bar_draw = ImageDraw.Draw(bars)
    heights = [0.22, 0.48, 0.35, 0.78, 0.56, 0.92, 0.64, 0.40, 0.70, 0.30, 0.52]
    left = int(size * 0.27)
    right = int(size * 0.73)
    baseline = int(size * 0.72)
    max_h = int(size * 0.26)
    gap = (right - left) / len(heights)
    width = max(int(gap * 0.58), 2)
    for index, height in enumerate(heights):
        x0 = int(left + index * gap + (gap - width) / 2)
        y0 = int(baseline - max_h * height)
        x1 = x0 + width
        y1 = baseline
        bar_draw.rounded_rectangle(
            [x0, y0, x1, y1],
            radius=max(width // 2, 1),
            fill=(199, 214, 189, 255),
        )
    overlay = Image.alpha_composite(overlay, bars)

    highlight = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    hi = ImageDraw.Draw(highlight)
    hi.arc(
        [int(size * 0.08), int(size * 0.04), int(size * 0.92), int(size * 0.55)],
        start=200,
        end=340,
        fill=(255, 255, 255, 28),
        width=max(size // 80, 2),
    )
    highlight = highlight.filter(ImageFilter.GaussianBlur(radius=size * 0.01))
    return Image.alpha_composite(Image.alpha_composite(img, overlay), highlight)


def main():
    ASSETS.mkdir(parents=True, exist_ok=True)
    ICONSET.mkdir(parents=True, exist_ok=True)
    master = draw_master()
    master.save(MASTER)
    for name, edge in SIZES.items():
        resized = master.resize((edge, edge), Image.Resampling.LANCZOS)
        resized.save(ICONSET / name)
    print(f"Wrote {MASTER}")
    print(f"Wrote {ICONSET}")


if __name__ == "__main__":
    main()
