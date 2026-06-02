# Rutin — Logo Prompts

**Core concept:** The Sun. One character, the whole brand. A single chibi sun mascot, front and center — the face of Rutin. Morning. Routine. Every day. Like Finch's bird: you meet this character and you know the app.

Style reference: match the existing mascot family (`home_sun.webp`, `star_mascot.webp`, `flame_mascot.webp`) — soft 3D claymorphic, kawaii face, smooth shading, gentle rim lighting.

Brand colors: navy `#0B0E1A`, white `#FFFFFF`, sun gold `#FDD25B`, warm amber `#F4A92B`

---

## Shared style block (prepend to every prompt)

> A cute, friendly 3D-rendered mascot character, soft rounded glossy claymorphic form, smooth surface with gentle soft studio lighting from the top-left and one soft specular highlight, subtle soft ambient occlusion, kawaii face with two large glossy black eyes (white specular dot in each) and a warm wide open smile, rosy circular cheeks, playful but premium, mobile-app mascot style, centered with generous empty margin, no text, no ground shadow, no extra props.

---

## App Icon

512×512px PNG, navy background. No text. No border.

```
A 3D cartoon chibi app icon. 512×512px, deep navy (#0B0E1A) square background.

The subject: a single sun mascot character. A round golden disc — warm yellow 
(#FDD25B) with a soft amber gradient toward the edges — with short, chunky, 
rounded rays radiating outward, two of which are angled forward like raised arms.

Face: two large glossy black eyes (white specular highlight dot in each), 
rosy circular cheeks (soft pink blush), a wide open cheerful smile. 
The expression is energetic and warm — "good morning, let's go."

Pose: slight tilt (~8°), both arm-rays raised and spread wide — open, 
inviting, full of energy. Not calm — bright and ready.

The character fills ~75% of the frame. Centered, sitting slightly low so 
the face occupies the upper-center of the icon — the face is what you see 
first at small sizes.

A soft warm golden radial glow behind the character (low opacity, wide spread) — 
separates the character from the navy background without competing with it.

Style: high-quality 3D render. Soft subsurface scattering on the golden disc. 
Specular highlights on the glossy dome. Pixar / claymorphic quality — round, 
smooth, full of life. Consistent with the mascot family style. The character 
must read clearly at 48×48px: face visible, pose readable, silhouette clean.

No background scene. No other characters. No text. Just the sun.
```

---

## Wordmark

For splash screen, pitch deck, README. Navy background.

```
The word "Rutin" in a rounded, friendly sans-serif (similar to Nunito ExtraBold 
or Poppins Black). Mixed case — capital R, lowercase the rest.
Color: white on navy background.

The dot above the letter "i" is replaced by a tiny sun mascot face — just 
the golden disc with the kawaii face (two dot eyes, small open smile, rosy 
cheeks), no rays. It sits exactly where the i-dot belongs. The brand character, 
even in the wordmark.

Kerning: slightly tight. The whole word feels compact and confident.
No underlines, no taglines, no drop shadows on the text itself.
```

---

## Icon + Wordmark Lockup

For pitch deck and README header.

```
Horizontal lockup, navy (#0B0E1A) background.

Left: the sun icon at 72×72px, corner radius matching Play Store spec.

Right side, vertically centered:
  Line 1 — "Rutin" wordmark as described above, white, ~32pt
  Line 2 — "kesehatan harian, gratis selamanya" in muted grey (#9AA3B2), 
            ~13pt, same font at regular weight

12px gap between icon and text block.
```

---

## Technical notes

- Generate on **navy background** — the mark is designed for dark
- Play Store icon: exactly **512×512px PNG** (Play Store does not accept WebP)
- After cleanup: `python preview/clean_mascot.py SRC OUT` → crop → `ffmpeg -i rutin_icon.png -c:v libwebp -lossless 1 assets/app_icon.webp` for in-app use
- Style consistency check: place generated icon next to `home_sun.webp`, `star_mascot.webp`, `flame_mascot.webp` — they should feel like one family
- The sun icon should also work as a single-color silhouette (all gold, no gradient) for monochrome contexts
