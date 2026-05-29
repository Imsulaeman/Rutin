"""Strip the baked transparency-checkerboard from a mascot PNG via border
flood-fill (no saturation key, so white/neutral interior parts like the pill's
belly survive). Floods from all four corners, crops to the figure, exports WebP."""
import sys
from PIL import Image, ImageDraw

SRC = sys.argv[1] if len(sys.argv) > 1 else "assets/Pink-pill.png"
OUT = sys.argv[2] if len(sys.argv) > 2 else "assets/med_pill_mascot.webp"
NAVY = (11, 14, 26)
PREVIEW = "preview/_mascot_on_navy.png"
THRESH = 70  # bridges both checker greys, well below the saturated mascot

img = Image.open(SRC).convert("RGBA")
w, h = img.size
# Flood transparent from each corner; checker is one connected border region.
for xy in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]:
    ImageDraw.floodfill(img, xy, (0, 0, 0, 0), thresh=THRESH)

# Crop to the visible figure (+ small margin).
bbox = img.getbbox()
if bbox:
    pad = 12
    bbox = (max(0, bbox[0] - pad), max(0, bbox[1] - pad),
            min(w, bbox[2] + pad), min(h, bbox[3] + pad))
    img = img.crop(bbox)

# Downscale longest side to 560 for a tidy asset.
scale = 560 / max(img.size)
img = img.resize((round(img.size[0] * scale), round(img.size[1] * scale)), Image.LANCZOS)
img.save(OUT, "WEBP", lossless=True, quality=100)
print(f"wrote {OUT}  size={img.size}")

bg = Image.new("RGB", img.size, NAVY)
bg.paste(img, (0, 0), img)
bg.save(PREVIEW)
print("wrote", PREVIEW)
