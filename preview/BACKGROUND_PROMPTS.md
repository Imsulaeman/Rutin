# Rutin Tab Background Prompts

Full-bleed backgrounds for the four flat tabs (Home already has `home_background.webp` + `home_foreground.webp`). Render each **portrait 1080×1920**.

**The golden rule:** content cards sit on top of these, so the **top ~65% must stay calm, dark and low-contrast** — all the visual interest lives in the **bottom third**, exactly like the Home scene (hills + rising sun at the bottom, empty night sky above). If the middle is busy, text becomes unreadable.

**Pipeline note:** unlike the mascots, these are **NOT** flood-filled. Generate full-bleed (no white margin, no character cutout). After export I just resize + convert to WebP and wire into `pubspec.yaml`. No `clean_mascot.py` step.

---

## Shared style block (prepend to every prompt)

> A premium mobile-app background illustration, portrait orientation, deep dark navy night palette anchored on `#0D1117` and `#0B0E1A`, cinematic and calm, soft volumetric glow, subtle film grain, smooth gradients, no text, no UI elements, no characters, no people. The TOP two-thirds is a near-empty dark sky with only faint atmosphere so foreground app cards stay readable; all detail sits along the BOTTOM third as a low silhouette.

---

## 1. Obat  (medicine tab — pink identity `#E91E63`)
> …a quiet night pharmacy-shelf horizon along the bottom: soft rounded silhouettes of bottles and a low counter rendered as dark navy shapes, lit by a gentle warm-pink `#E91E63` glow rising from below, a few soft floating bokeh dots of pink light in the lower air, fading to empty dark sky at the top.

→ save as `assets/medicine_background.webp`

## 2. Air  (water tab — blue identity `#2196F3`)
> …a calm moonlit sea horizon along the bottom: gentle dark navy waves with soft cyan-blue `#2196F3` reflections and a faint glow on the water, a few slow rising bubbles of soft blue light in the lower air, fading to empty dark sky at the top.

→ save as `assets/water_background.webp`

## 3. Kebiasaan  (habits tab — purple identity `#7C3AED`)
> …a low rolling hill horizon along the bottom (echoing the Home hills) in dark navy silhouette, lit by a soft violet-purple `#7C3AED` aurora glow rising from behind the hills, a scatter of faint star-points and a couple of soft purple light motes in the lower air, fading to empty dark sky at the top.

→ save as `assets/habits_background.webp`

## 4. Profil  (profile/settings tab — calm neutral)
> …a cozy night-house horizon along the bottom: a small dark navy house silhouette with two or three softly glowing warm-amber windows, set among low hills, a calm starry sky fading to empty dark at the top.

→ save as `assets/profile_background.webp`
(You already have `night-house-settings.png` — if you like it, I can process that instead; just say so.)

---

### Consistency checklist (all four)
- Same dark navy base (`#0D1117` / `#0B0E1A`) so they feel like one family with Home.
- Horizon/detail strictly in the **bottom third**; top is quiet sky.
- One feature-color glow per tab (pink / blue / purple / amber), kept soft — not neon.
- No characters, no text, no UI mockup elements.
