# Rutin — Asset Spec & Generation Prompts

Goal: make the app blend like the `preview/` mockups. The screen is two layers:

- **Functional UI** (cards, numbers, rings, nav) → built in code. Stays code (live data).
- **Art** (backgrounds, mascots) → shipped image assets, shown with `Image.asset`.

Blending comes from (1) a **full-screen background** so there's no empty gap, and
(2) **colored card glows** added in code. This doc covers the art you (re)generate.

---

## Style rules (keep the whole set consistent)

- Cute, friendly, **soft 3D / smooth-shaded** look (like the existing mascots). Rounded forms, gentle rim light, cozy.
- **Night palette:** deep navy sky `#0B0E1A`–`#11203A`, soft green hills `#1C4D34`–`#2E7D4F`, warm sun `#FFD24D`/glow `#FEDD5D`.
- **No text, no UI, no device frames, no watermark.** Just the illustration.
- Transparent background (PNG, alpha) for **mascots**. Opaque for **full-screen backgrounds**.
- Same art style/seed across all assets so they feel like one product.
- Deliver PNG at the sizes below — I convert to **WebP** (≈95% smaller, no quality loss).

Drop everything in `assets/` keeping the **exact filenames** below.

### ⚠️ Transparency gotcha (important)
Your AI tool bakes the **transparency checkerboard into the image as real pixels**
instead of true alpha (confirmed on `home_sun.png` and `Blue-water.png`). It looks
fine on a light/gray preview but shows an ugly pale **box** on the dark app background.
- I auto-fix this with a **chroma key** (`ffmpeg geq` alpha from color-saturation) —
  works because the mascots are saturated colors on a neutral checkerboard. So you can
  keep generating as-is; I'll clean each one.
- If you *can* export true PNG transparency (or on a solid flat **magenta**/green bg I
  key out), even better — cleaner edges. Either way, **check mascots on a dark bg**, not gray.

---

## PRIORITY — Home screen

### 1. `home_background.png`  ← the big fix
- **Portrait, 9:19.5 ratio, ≥ 1080×2340** (deliver 1290×2796 if you can).
- **Opaque** full-screen night scene.
- Content: deep navy **starry sky** filling the top, transitioning into soft rolling **green hills** across the bottom ~40%, with a cute **rising sun character** (small happy closed-eye smile, rosy cheeks, warm glow) peeking between the hills, plus a few trees, bushes, small white daisies and warm **fireflies** near the hills.
- **CRITICAL composition:** keep the **top ~45% calm and almost empty** — just dark sky + a few faint stars. No bright/important art up there, because the UI cards overlay that zone. All focal detail (sun, hills, plants) lives in the **bottom ~45%**. The very top edge should be near-solid deep navy for a clean status bar.

```
┌───────────────────┐  ← top: near-solid deep navy (status bar)
│   .  ·     ·    .  │  ← upper 45%: calm sky, sparse faint stars
│      ·   .        │     (UI CARDS OVERLAY HERE — keep it quiet)
│  ·          ·   . │
│ ───────────────── │
│   ✦   ☀️(face)  ✦  │  ← lower 45%: hills + rising sun + fireflies
│ ⌒⌒hills🌳🌼⌒⌒🌳⌒ │
└───────────────────┘
```

### 2. (Optional, recommended) split the sun so it can animate
If you want the sun to gently bob / the scene to have moving parts, deliver the
background **without the sun**, plus the sun as its own transparent layer:
- `home_sky.png` — same as #1 but **no sun** (sky + hills + plants + fireflies).
- `home_sun.png` — **square, transparent, ~800×800.** Just the sun character + its
  soft warm glow fading to transparent. Front view, centered.

I'll stack `home_sky` → `home_sun` (animated bob) and blend them. If you skip this,
the baked single `home_background.png` is fine — the sun just won't move.

---

## MEDICINE — list + alarm (current task)

The medicine **list** screen is all code (dark cards, pink time pills, check
circles, day-switcher) + the cleaned `Pink-pill` mascot on the "Almost there!"
card — **no new asset needed there, I handle it.**

The **alarm/reminder** screen (mockup `04_medicine_reminder`) needs **one** asset:

### `med_reminder_bg.png`  ← the only thing I need from you
- **Portrait, 9:19.5 ratio, ≥ 1080×2340** (deliver 1290×2796 if you can).
- **Opaque** full-screen scene. **NO text, NO buttons, NO pill icon, NO UI** — I
  draw the clock, the capsule badge and both buttons in code on top.
- Content: warm **pink → magenta vertical gradient** sky (top `#F26D8B` →
  mid `#E0457A` → lower `#C23B73`), soft **out-of-focus capsules/pills** of
  varying sizes floating and scattered across the upper two-thirds (some sharp,
  some blurred, gentle depth), a low **mauve/purple rolling-hill silhouette**
  along the very bottom (`#7A3F73`→`#4A2A52`), a few faint sparkles and **one
  small flower** near the top-left. Dreamy, soft, premium.
- **CRITICAL composition:** keep the **vertical center band calm** — that's where
  the big "Medicine / 10:00 AM" text and the white buttons sit. Put the scattered
  pills toward the top third and the edges; keep the middle uncluttered. Top edge
  near-solid pink for a clean status bar.

```
┌───────────────────┐  ← top: pink, a flower + scattered pills
│  🌸   ◗ ◍   ◖  ✦  │
│      ◍      ◗      │  ← (code draws capsule badge here)
│   ·   (calm band)  │  ← BIG TEXT + BUTTONS overlay here — keep quiet
│        ◖     ◗     │
│ ⌒⌒⌒mauve hills⌒⌒⌒ │  ← lower: soft purple hill silhouette
└───────────────────┘
```

**Prompt (copy-paste):**
> A dreamy vertical phone background, portrait 9:19.5, warm pink to magenta
> gradient sky. Soft out-of-focus rounded medicine capsules and pills of various
> sizes floating and scattered across the upper area, some sharp and some blurred
> for depth. A low soft mauve-purple rolling-hill silhouette along the bottom
> edge. A few faint sparkles and one small simple flower near the top-left. Keep
> the vertical center calm and mostly empty for text. Soft, warm, dreamy,
> premium. [+ shared style suffix]

Drop it in `assets/med_reminder_bg.png`. I convert to WebP and overlay the UI.

---

## NEXT — Feature-screen mascots (reuse what you have, regenerate only if you want them cleaner)

You already have these as 1254×1254 transparent PNGs. Keep filenames or rename to match:

| Use on screen | Suggested file        | Have it? | Content                                   |
|---------------|-----------------------|----------|-------------------------------------------|
| Water         | `mascot_water.png`    | Blue-water.png | cute water-drop, happy face, bubbles |
| Medicine      | `mascot_pill.png`     | Pink-pill.png  | cute pill character, hearts/sparkles |
| Habits        | `mascot_star.png`     | Yellow-habit.png | cute star, arms up, sparkles       |
| Streak        | `mascot_flame.png`    | Red-streak.png | cute flame, energetic                 |
| Empty states  | `mascot_blob.png`     | Green-blob.png | friendly blob                         |

Spec if regenerating: **square, transparent PNG, ~800×800**, centered, front view,
consistent soft-3D style, glow/sparkles included in the alpha so they blend on dark.

---

## Generation prompts (copy-paste)

**Shared style suffix** (append to every prompt):
> soft 3D claymorphic style, smooth shading, rounded friendly forms, gentle rim
> lighting, cozy premium mobile-app illustration, cohesive palette, no text, no UI,
> no border, high detail, centered composition.

**`home_background.png`**
> A cozy nighttime rolling-hills landscape for a phone wallpaper, portrait
> orientation 9:19.5. Deep navy starry night sky filling the upper half, fading
> downward into soft rounded green hills. A cute rising sun character with a small
> happy face (closed smiling eyes, rosy cheeks) peeking up between two hills, soft
> warm yellow glow around it. A few small rounded trees, bushes, white daisies and
> tiny glowing fireflies near the hills. Keep the top half calm and mostly empty
> dark sky with only a few faint stars; put all the detail in the lower third. Dark,
> dreamy, peaceful. [+ shared style suffix]

**`home_sun.png`** (only if doing the split)
> A cute sun character with a small happy face — closed smiling eyes, rosy cheeks —
> glowing warm yellow, with a soft radial glow fading to transparent around it.
> Front view, centered, transparent background. [+ shared style suffix]

**`mascot_water.png`** (example; swap subject for the others)
> A cute single water droplet character with a happy face and tiny arms, glossy
> blue, a few small bubbles around it, transparent background. [+ shared style suffix]

---

## What I need from you (checklist)
- [ ] `home_background.png` (the priority — fixes the gap)
- [ ] *(optional)* `home_sky.png` + `home_sun.png` if you want the sun to animate
- [ ] confirm the 5 mascots are final, or regenerate any you want cleaner
- [ ] drop them in `assets/` with the filenames above

Then I will: convert all to WebP, wire them in, swap the home background, and add
the colored card glows + gloss so the cards fuse into the scene like the mockup.
