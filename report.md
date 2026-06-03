# Rutin App — Full Review Report

**Date:** 2026-06-02
**App:** Rutin — Health Habit Tracker (com.rutin.app)
**Review scope:** UI/UX design, animation quality, security, code quality
**Reviewer lenses:** Impeccable (UI/UX heuristics), gpt-taste (design craft), Emil Kowalski (animation + interaction), Senior Android/Flutter Developer (security + architecture)

---

## Status Update — 2026-06-03

This review was originally written before the P1-P4 implementation batch. The biggest findings from this report are now already shipped:

- Custom fonts are live: `Bricolage Grotesque` for display and `DM Sans` for UI/body.
- The permission flow was rewritten into a step-by-step bottom sheet.
- Sensitive Hive boxes `medicines`, `medicine_logs`, and `tb_profiles` now use encryption.
- Home now uses Riverpod providers for `WaterRepository` and `HabitRepository`.
- Shell routes use fade transitions, the Home calendar icon goes to `History`, and many inline `localized()` strings were moved into ARB files.
- Firebase Analytics no longer sends medicine names or habit names.
- Accessibility Service now has a narrow manifest description for Play Store review.
- Repository tests were added for `HabitRepository.getStreak()` and `MedicineRepository.isTaken()`.

Remaining relevant gaps from this report are the items still open in `TODO.md`, especially:

- lazy-opening non-critical Hive boxes if startup time becomes a real issue
- polishing medal/profile collection surfaces
- richer empty states / CTA treatment if we want a more portfolio-styled first-run experience
- final device/manual verification for the nightly sleep-mode transition

---

## Executive Summary

Rutin is a solidly built, offline-first Flutter health app with a strong design foundation: intentional dark palette, consistent feature color coding, custom typography, and a distinctive bottom nav. The animation layer shows real craft — particularly `_Pressable`, staggered entrance, and the ambient bobbing sun. After the P1-P4 follow-up batch, the biggest review blockers are no longer typography, permission UX, or analytics privacy. The remaining work is mostly polish, startup-performance tradeoffs, and final manual verification rather than foundational product risk.

---

## 1. Design & UI Review (Impeccable + gpt-taste)

### Strengths

| What | Where | Why it works |
|---|---|---|
| GitHub-dark palette | `app_theme.dart` | `#0D1117 / #161B22 / #30363D` is instantly readable at night. Good ambient light reasoning. |
| Feature color identity | `app_theme.dart` | Pink=medicine, blue=water, amber=habits — consistent across every screen and home cards |
| Raised center FAB with green glow | `app.dart:_BottomNav` | Distinctive navigation shape, avoids the boring 5-icon flat nav |
| `_SectionCard` with border + shadow | `home_screen.dart:1041` | Clean glass-panel look without actual glassmorphism cliché |
| Home hero with layered WebP assets | `home_screen.dart:876` | Background + foreground + sun layers create depth. Gradient fade to content is well-tuned (stops at 0.36/0.78/1.0) |
| Empty states | `home_screen.dart:_EmptyHint` | Present on every section. No broken layouts when no data. |
| Tutorial coach marks | `home_screen.dart:_startTutorial` | Contextual, targets real UI elements, properly filtered to keys in-tree |

### Issues

**[DONE] Custom display font was previously missing.**
This was a real issue in the original review, but it has now been fixed. The app now uses `Bricolage Grotesque` for display/headline text and `DM Sans` for UI/body text.

**[MEDIUM] Section headers use `.toUpperCase()` in code.**
`context.l10n.medicine.toUpperCase()` (home_screen.dart:402) is not safe for all locales — Turkish `I` capitalisation is a known Flutter gotcha, and Indonesian has no uppercase issue but the call is still fragile. Use `ARB` strings that are already in the correct display form, or apply `TextStyle(letterSpacing: 0.8)` without `.toUpperCase()`.

**[DONE] Permission dialog UX was confusing.**
This was fixed after the review. The app now uses a guided step-by-step bottom sheet instead of a one-shot `AlertDialog`.

**[DONE] `_Header` calendar button was a no-op.**
This has already been wired to `History`.

**[LOW] `_EmptyHint` is text-only.**
Empty states for Medicine, Water, and Habits are plain muted text. For a health app, a small illustration or icon + a call-to-action button ("Add your first medicine") would both delight first-time users and improve activation. Given the scattered-idea goal of ADA portfolio, this is worth investing in.

**[LOW] Action label uses raw `→` arrow character.**
`'→ $actionLabel'` (home_screen.dart:1089) works but the `→` character renders differently across fonts. Use `Icons.arrow_forward_rounded` at 14px or a standard `»` to be safe.

**[LOW] Hardcoded FAB colors duplicate theme green.**
`Color(0xFF5FD97E)` and `Color(0xFF4CC56A)` in `app.dart:_BottomNav` match `_success` but are not referenced from theme. If the accent color ever changes, the FAB won't follow.

---

## 2. Animation & Interaction Quality (Emil Kowalski)

### Strengths

| Pattern | Location | Assessment |
|---|---|---|
| `_Pressable` scale(0.97) on press | `home_screen.dart:1528` | Exactly right. 110ms `easeOut`. Matches Emil's button responsiveness rule. |
| Staggered `_FadeSlideIn` entrance | `home_screen.dart:398–541` | start/end intervals (0.10→0.60, 0.20→0.70, 0.30→0.80) create cascading feel without being slow |
| `_BobbingSun` ambient breathing | `home_screen.dart:1502` | Sine wave translate + scale. Purposeful, delightful, non-distracting. ±5px / ±2% scale is exactly the right magnitude |
| `easeOutCubic` on FadeSlideIn | `home_screen.dart:1585` | Correct easing direction for enter animations |
| `HapticsService` on all interactions | throughout | softTap, tap, success, fun — appropriate differentiation per action weight |

### Issues

| Before | After | Why |
|---|---|---|
| `AnimatedContainer` with no `curve` at `home_screen.dart:1344` | Add `curve: Curves.easeOut` | Defaults to `Curves.linear` — the checkbox fill/border state change will feel robotic |
| `AnimationController` entrance duration of 760ms (home_screen.dart:86) | Fine for first-load, but the last card animates at interval 0.80 × 760ms = 608ms | Consider 600ms total so last card finishes at ~480ms; 760 is slightly sluggish on slower devices |
| FAB `GestureDetector` with no press feedback (app.dart:317) | Wrap in `_Pressable` or add `ScaleTransition` | The FAB is the most-tapped element and currently has zero scale feedback on press |
| `AnimatedScale` on `_TodayHabitRow` checkbox: `duration: 180ms` | Already good, but the `border` color animates inside `AnimatedContainer` which triggers layout. Use `AnimatedDecoration` or separate `AnimatedOpacity` + `AnimatedScale` | `AnimatedContainer` border changes are not GPU-accelerated |
| No page transition defined in `GoRouter` | Add `CustomTransitionPage` with a fade or vertical slide at 280ms easeOut | Default `MaterialPage` transition is a full horizontal push — heavy for a bottom-nav app where tabs feel like peers, not pages |
| `_ambient` repeats reverse every 3200ms (home_screen.dart:91) | The `repeat(reverse: true)` creates a linear ramp between cycles at the reversal point. Use `Curves.easeInOut` via `CurvedAnimation` | Without easing the sun pauses artificially at the extremes |

---

## 3. Security Review

### GOOD — Sensitive files properly excluded

Both `android/key.properties` (keystore password: present) and `android/app/google-services.json` (Firebase API key: present) are in `.gitignore` **and confirmed not tracked by git.** This is correct. The passwords exist locally on disk but are never committed.

Action item: add a `pre-commit` hook or CI check to block accidental commits of these files if you ever push to a shared remote.

### Issues

**[DONE] Sensitive Hive data was previously unencrypted.**
This has now been addressed for the highest-risk boxes: `medicines`, `medicine_logs`, and `tb_profiles` use `HiveAesCipher` with a key stored through `flutter_secure_storage`.

```dart
// Minimum viable approach for sensitive boxes
final encryptionKey = await _secureStorage.read(key: 'hive_key')
    ?? base64.encode(Hive.generateSecureKey());
await _secureStorage.write(key: 'hive_key', value: encryptionKey);
final encryptedBox = await Hive.openBox<Medicine>(
  'medicines',
  encryptionCipher: HiveAesCipher(base64.decode(encryptionKey)),
);
```

**[DONE] Battery optimization rationale was previously missing.**
The app now shows an explanation dialog before opening the settings handoff.

**[LOW] Accessibility Service scope.**
The manifest description is now in place, which is good progress. The remaining part is making sure the Play Store listing wording stays equally narrow and consistent.

**[DONE] Firebase Analytics health-context audit.**
This issue has already been addressed. Medicine names and habit names are no longer sent in analytics event parameters.

**[INFO] No HTTPS endpoints (by design).**
The app is fully offline-first with no direct REST calls from Dart code. Firebase SDK handles its own transport. This is a strong security posture for this class of app.

---

## 4. Code Quality

### Issues

**[DONE] Inconsistent dependency injection in HomeScreen.**
This was fixed after the review. Home now reads `WaterRepository` and `HabitRepository` from providers instead of constructing them directly.

**[DONE] `_permissionDialogShown` static flag issue.**
This has already been fixed by persisting the permission-flow shown state in Hive `app_settings`.

**[MEDIUM] `localized()` parallel localization system.**
The codebase uses both `context.l10n.someKey` (ARB-based, type-safe) and `localized(context, id: '...', en: '...')` (inline bilingual string, home_screen.dart:158+). The `localized()` pattern bypasses ARB files entirely, meaning Indonesian strings for home screen are hardcoded in Dart rather than extracted to `app_id.arb`. This makes future translation work harder and creates a split source of truth. Migrate all `localized()` calls to ARB entries.

**[LOW] `_HomeScreen` header calendar button points to profile.**
`Icons.calendar_today_rounded` → `onMenu` (→ /profile) is misleading iconography. Remove the calendar icon or wire it to `/history`.

**[LOW] `_FadeSlideIn` uses `Transform.translate` which triggers compositing.**
`Transform.translate` with `Offset(0, 16 * ...)` during the entrance animation causes a repaint each frame. This is acceptable for an entrance animation that runs once, but should use `FractionalTranslation` instead of `Transform.translate` for the offset — it avoids a separate compositing layer.

**[PARTIAL] Test coverage is no longer zero.**
There are now focused repository tests for `HabitRepository.getStreak()` and `MedicineRepository.isTaken()`. Broader integration or widget testing is still not in place.

**[INFO] `main.dart` opens all Hive boxes sequentially at startup.**
13 Hive boxes are opened in sequence before `runApp`. On a slower device this can add 200–400ms to cold start. Consider lazy-opening non-critical boxes (medals, history) after the first frame using `addPostFrameCallback`.

---

## 5. Scattered Ideas Evaluation

From `scattered-idea.md`:

| Idea | Assessment |
|---|---|
| **100% free + open source** | Correct direction for ADA portfolio. Demonstrates ethical product thinking. |
| **Donation tiers via Saweria** | Good. Saweria is standard in Indonesian indie app ecosystem. No in-app billing means no Play Store revenue share or policy complexity. |
| **Wake-up puzzle (Simon Says etc.)** | The game system already exists (`wakeup_game_screen.dart`). Adding Simon Says is a focused, scoped feature. High delight factor for the ADA demo. |
| **App lock (donor-only)** | Correctly flagged as not doable without server. Removing this is the right call. |
| **Home screen widget** | High value for a habit app — users need to log water/habits without opening the app. Technically: Android AppWidget + `android_alarm_manager_plus` for live updates. Significant effort but strong Play Store store listing differentiator. |
| **Cross-device sync** | Not compatible with current offline-first / no-account architecture. Would require Firebase Firestore + Auth. Large scope — not worth attempting before ADA application. |
| **Medicine notes / log field** | Small, high-value addition. A `notes` field on `MedicineLog` for daily observations is 1–2 day feature. PDF export already exists so the notes would appear there naturally. |

---

## 6. Priority Action List

| Priority | Category | Item |
|---|---|---|
| Done | Security | Add `HiveAesCipher` for `medicines`, `medicine_logs`, `tb_profiles` boxes |
| Done | UX | Rewrite permission dialog as step-by-step bottom sheet |
| Done | Design | Add custom fonts via `google_fonts` |
| Done | Animation | Add `curve: Curves.easeOut` to the checkbox `AnimatedContainer` |
| Done | Animation | Wrap the FAB in `_Pressable` for press scale feedback |
| Done | Code | Move `WaterRepository` and `HabitRepository` in `HomeScreen` to Riverpod providers |
| Done | Code | Persist permission-flow shown state to Hive |
| Partial | Code | Migrate major `localized()` inline strings on Home to ARB files; app-wide migration is still not finished |
| Done | Animation | Define custom `GoRouter` page transitions (fade, 280ms easeOut) |
| Done | UX | Wire the calendar icon in the home header to `/history` |
| Open | Design | Improve empty states with a small icon + CTA button |
| Done | Code | Add unit tests for `HabitRepository.getStreak()` and `MedicineRepository.isTaken()` |
| Done | Play Store | Add battery optimization rationale dialog before opening settings |
| Done | Play Store | Narrow and document `RutinAccessibilityService` purpose in manifest description |
| Open | Performance | Lazy-open non-critical Hive boxes if startup cost becomes noticeable |
| Open | QA | Finish manual nightly sleep-mode transition verification |
