"""Re-key home_sun.png: force the saturated disc fully opaque, keep a soft
saturation-based alpha only for the outer glow. Fixes the navy 'stain' that
appeared because dark face lines / pale highlights were low-saturation and got
punched semi-transparent by the old chroma key."""
import numpy as np
from PIL import Image

SRC = "preview/home_sun.png"
OUT = "assets/home_sun.webp"
NAVY = (11, 14, 26)  # #0B0E1A, the home background
PREVIEW = "preview/_sun_on_navy.png"

img = Image.open(SRC).convert("RGB")
a = np.asarray(img).astype(np.float32)
h, w = a.shape[:2]
R, G, B = a[..., 0], a[..., 1], a[..., 2]
mx = a.max(axis=2)
mn = a.min(axis=2)
sat = mx - mn  # chroma (0..255)

# Soft alpha for the glow halo from chroma.
alpha = np.clip(sat * 3.0, 0, 255)

# Detect the disc: strongly coloured pixels (yellow body + pink cheeks).
mask = sat > 70
ys, xs = np.where(mask)
x0, x1 = np.percentile(xs, 1), np.percentile(xs, 99)
y0, y1 = np.percentile(ys, 1), np.percentile(ys, 99)
cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
rad = max(x1 - x0, y1 - y0) / 2 * 1.02
print(f"disc center=({cx:.0f},{cy:.0f}) radius={rad:.0f}  image={w}x{h}")

# Force everything inside the disc fully opaque.
Y, X = np.ogrid[:h, :w]
dist = np.sqrt((X - cx) ** 2 + (Y - cy) ** 2)
inside = dist <= rad
alpha[inside] = 255
# Feather a 12px ring just outside the disc so the edge blends with the glow.
ring = (dist > rad) & (dist <= rad + 12)
alpha[ring] = np.maximum(alpha[ring], 255 * (1 - (dist[ring] - rad) / 12))

rgba = np.dstack([a, alpha]).astype(np.uint8)
out = Image.fromarray(rgba, "RGBA").resize((640, 640), Image.LANCZOS)
out.save(OUT, "WEBP", lossless=True, quality=100)
print("wrote", OUT)

# Composite over navy for a visual check.
bg = Image.new("RGB", out.size, NAVY)
bg.paste(out, (0, 0), out)
bg.save(PREVIEW)
print("wrote", PREVIEW)
