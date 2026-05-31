# Rutin — Daily Health Habits

> Built for myself. Useful for everyone.

A free, offline-first Android app for medicine reminders, hydration tracking, daily habits, and a morning wake-up routine. No account. No paywall. No internet required.

---

## Why It Exists

I built Rutin while managing my own TB treatment. Taking medicine at exact times, every day, for 6+ months — a missed dose isn't just a bad habit, it can cause drug resistance. Every existing app I tried was either too generic, paywalled, or unreliable when it mattered most.

So I built the one I needed. Then I kept going, because the same problem applies to anyone trying to build consistent health habits.

---

## Features

### Medicine Reminders
Alarm-grade. Re-notifies every minute until confirmed taken. Full-screen takeover, persistent even if you dismiss the notification. Supports multiple daily doses, food timing (before/after/with meals), snooze, and a history calendar with adherence tracking. Alarms survive reboots.

### Water Tracking
Interval-based reminders within a configurable active window. Quick add/remove glass, WHO-based daily target, inline undo, and a "next reminder" countdown on the main screen.

### Habits
Multiple daily reminder times per habit. Per-reminder completion dots (tap to check off, tap again to undo). Streak tracking with partial-day survival — missing one reminder doesn't break a streak, missing the whole day does. Habit stacking (chain habits into routines). Calendar history per habit.

### Sleep Mode + Morning Gate
Native Android foreground service detects sleep passively. On unlock, a morning dashboard appears before you can use your phone — shows today's medicine and habits, then a wake-up game (Sequence Memory, Piano Tiles, or Connect the Dots). Backed by an AccessibilityService that prevents skipping the gate via the home button.

### TB Treatment Mode
Treatment-profile groundwork is in place. Countdown, adherence score, and PDF export are planned next.

---

## Technical Highlights

**Alarm-grade notifications** — medicines use a custom `NativeReminderScheduler` (Kotlin) on top of `AlarmManager` with `setExactAndAllowWhileIdle`. Reminders re-arm automatically for the next day after each dose is taken.

**Sleep detection without sensors** — `SleepModeService` polls user-presence timing + audio state every 5 minutes using a 3-case heuristic. No health permissions, no body sensors. Works on Android 13+.

**Home button intercept** — `RutinAccessibilityService` keeps the morning gate on screen even if the user presses Home or switches apps, without blocking emergency calls.

**No build_runner** — Hive adapters are hand-edited. Keeps the build fast and removes a fragile codegen step.

**Offline-first, always** — all data lives in Hive on-device. No Firebase Auth, no sync, no account. Firebase Analytics is the only network call.

---

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3.44 (Dart) |
| State | flutter_riverpod |
| Storage | Hive |
| Alarms | AlarmManager via MethodChannel (Kotlin) |
| Notifications | flutter_local_notifications |
| Navigation | go_router |
| Analytics | Firebase Analytics |
| Sleep mode | AccessibilityService + foreground service (Kotlin) |

---

## Project Structure

```
lib/
  features/
    medicine/     # reminders, logs, history, archive
    water/        # hydration goals, interval reminders
    habits/       # habit model, stacking, streaks, history
    home/         # today view combining all features
    sleep/        # sleep settings, morning gate, wake-up games
    settings/     # language, accessibility, about
    tb/           # TB treatment profile and adherence
  core/           # theme, services, utilities
  shared/         # providers, shared widgets

android/
  app/src/main/kotlin/com/rutin/app/
    NativeReminderScheduler.kt   # medicine alarm engine
    SleepModeService.kt          # sleep detection
    RutinAccessibilityService.kt # home button intercept
    BootReceiver.kt              # alarm restore after reboot
```

---

## Status

Core features shipped: medicine, water, habits, sleep mode, morning gate, TB profile groundwork, Firebase Analytics.

In progress: app icon, splash screen, onboarding flow, Play Store listing.

**Package:** `com.rutin.app` — Android only.

---

*Built by [Ilham Maulana Sulaeman](https://github.com/imsulaeman) — Bandung, Indonesia.*
