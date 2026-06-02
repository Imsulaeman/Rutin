# Rutin — ADA Pitch Deck

> **Format:** 7-slide story deck. Each slide = one headline + one visual + 2–3 supporting points.
> Use dark navy `#0B0E1A` background, gold `#F4A92B` accents, white body text throughout.

---

## Slide 1 — Hook / Title

**Headline:** "Every missed pill is a step toward drug resistance."

**Visual:** Full-bleed hero — the Rutin home screen on a phone mockup, night-hill art with the sun peeking over the hills. Sun mascot icon in the top-left corner.

**Supporting:**
- App name: **Rutin** — daily health, free forever
- Built by Ilham Maulana Sulaeman, Bina Nusantara University
- Made in Bandung, Indonesia

---

## Slide 2 — The Problem

**Headline:** "Indonesia has the second-highest TB burden in the world."

**Visual:** Simple world map with Indonesia highlighted, stat callouts in gold.

**Supporting:**
- 969,000 new TB cases in Indonesia every year (WHO 2023)
- Treatment requires taking medicine **every single day for 6 months**
- Inconsistent adherence → drug-resistant TB (MDR-TB), which is nearly incurable
- Most reminder solutions are either too complex, paywalled, or offline-incapable

---

## Slide 3 — The Solution

**Headline:** "Rutin: a free, offline-first health companion that actually keeps you on track."

**Visual:** 3-up screenshot: Home dashboard → Medicine alarm screen → Morning Gate game.

**Supporting:**
- **Medicine reminders** — alarm-grade, fires every minute until taken
- **Water & habit tracking** — streaks, medals, progress rings
- **Sleep mode** — forced wake-up game before your phone unlocks
- No account. No internet. No paywall. Works on any Android.

---

## Slide 4 — How It Works (Technical)

**Headline:** "Alarm-grade reliability — not just push notifications."

**Visual:** Simple architecture diagram: Flutter UI → Hive (offline) → Native AlarmManager → Full-screen intent.

**Supporting:**
- Native Android `AlarmManager` (exact alarms) — survives battery optimization, Doze mode
- `AccessibilityService` for morning gate home-button intercept
- Hive local storage — zero-dependency, works without internet permanently
- Flutter 3.44 / Kotlin — full Android 14 support

---

## Slide 5 — Features

**Headline:** "One app for the whole health routine."

**Visual:** Icon grid of 6 features — sun mascot as the central anchor character.

| Feature | What it does |
|---|---|
| 💊 Medicine | Multi-dose reminders, food timing, streak tracking, adherence calendar |
| 💧 Water | Daily ml goal, interval reminders, progress ring |
| ⭐ Habits | Habit stacking, multi-completion, streak + medals |
| 🌙 Sleep Mode | Bedtime schedule, morning gate, rotating wake-up mini-games |
| 🏥 Treatment | Generic condition tracker (TB, Tifus, Malaria, ARV) + PDF adherence report |
| 📊 History | Combined activity feed, 28-day calendar strip |

---

## Slide 6 — Impact + Vision

**Headline:** "Built for real people managing real health conditions."

**Visual:** Quote card — a hypothetical user story (TB patient, Bandung). Sun mascot in the corner, warm glow.

**Supporting:**
- Designed around the **actual TB treatment journey** (6–9 month regimen)
- Generalised to any chronic condition — Diabetes, ARV, Hipertensi
- Open-source, Saweria donation model — sustainable without monetising patients
- **Next:** home screen widget, caregiver view, WhatsApp adherence share, cloud backup

---

## Slide 7 — About the Builder

**Headline:** "I built the app I wished existed."

**Visual:** Avatar / photo of Ilham + GitHub contribution graph or app store screenshots.

**Supporting:**
- Ilham Maulana Sulaeman — Computer Science, Bina Nusantara University
- Manages his own health routine with Rutin daily
- Goal: bring this to Apple Developer Academy to build the iOS version
- GitHub: `imsulaeman` — full source available

---

## Appendix — Key Numbers (for the leave-behind)

| Stat | Value |
|---|---|
| Screens | 12 unique screens |
| Games | 4 wake-up mini-games (Sequence, Rhythm, Flow Free, Piano Tiles) |
| Languages | Bahasa Indonesia + English |
| Storage | Offline-first, 0 KB cloud dependency |
| Target device | Android 8+ (API 26) |
| Package | `com.rutin.app` |

---

## Logo / Brand Character

**Icon concept:** Single sun mascot character — cheerful, energetic, arms-up pose, navy background. One character, the whole brand.

The sun represents morning, daily routine, and waking up — the core of what Rutin is. It's already alive in the app's home screen art (`home_sun.webp`). The logo makes it the face of the brand.

See `LOGO_PROMPT.md` for full image-generation prompts.
