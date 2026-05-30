# Rutin Mascot Prompts

Image-generation prompts for the app's mascot family. Render each as a **square ~1254×1254** image. They must read as **one family**: same straight-on camera with a very slight top-down tilt, same kawaii face (two small oval black eyes + a tiny rounded smile), same soft top-left studio light, same glossy finish.

**Pipeline note:** Generate on a **plain solid pure-white background, no ground shadow, no extra props, generous empty margin, single centered character.** White (not a gradient, not the checkerboard) makes the corner flood-fill in `clean_mascot.py` trivial. After export I run `python preview/clean_mascot.py SRC OUT` → crop → convert to WebP and wire into `pubspec.yaml`.

---

## Shared style block (prepend to every prompt)

> A cute, friendly 3D-rendered mascot character, soft rounded glossy form, smooth surface with gentle soft studio lighting from the top-left and one soft specular highlight, subtle soft ambient occlusion, simple kawaii face with two small oval black eyes and a tiny rounded smile, playful but premium, mobile-app mascot style, centered with generous empty margin, plain solid pure-white background, no text, no ground shadow, no extra props.

---

## 1. Water drop  (water screen — needed now)
> …a single teardrop-shaped water droplet, translucent glossy blue gradient from `#2196F3` down to a deeper `#1565C0`, dewy glassy surface with a bright soft highlight near the top-left, smooth and rounded.

→ save as `assets/water_drop_mascot.webp`

## 2. Star  (habits screen)
> …a plump rounded five-point star, soft puffy edges, warm golden-yellow gradient from `#FDD25B` to `#F5A623`, cheerful and bouncy.

→ save as `assets/star_mascot.webp`

## 3. Flame  (streaks screen)
> …a single rounded campfire flame with soft glowing edges, gradient from a warm `#FF8A00` core up to bright `#FFD54F` tips, friendly and slightly bouncy, a faint warm glow around it.

→ save as `assets/flame_mascot.webp`

---

## Spares / consistency refresh (optional — you already have working WebPs)

## 4. Pill  (medicine)
> …a rounded capsule pill, left half soft glossy pink `#E91E63`, right half clean white, smooth glossy surface.

→ already shipped as `assets/med_pill_mascot.webp` — only regenerate if you want it to match the family exactly.

## 5. Sun  (home / dashboard)
> …a round smiling sun, warm golden-yellow `#FDD25B`, soft rounded stubby rays, gentle warm glow.

→ already shipped as `assets/home_sun.webp`.

---

## 6. Moon  (sleep feature — for later, no mockup yet)
> …a soft crescent moon, pale lavender-blue `#A9B7FF`, calm sleepy half-closed eyes and a tiny peaceful smile, faint soft glow.

→ save as `assets/moon_mascot.webp`
