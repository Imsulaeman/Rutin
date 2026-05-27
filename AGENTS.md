# Agent Context

Read this first before touching any code. This file keeps all AI agents (Claude, Codex, etc.) aligned.

## What This Project Is

A Flutter Android app for daily health habits and reminders. Built by Ilham Maulana Sulaeman, a university student in Bandung, Indonesia who has TB and needed a reliable medicine reminder that actually works - free, no paywalls, local-first.

**Not** a generic habit tracker. A personal health infrastructure tool, with a real mission: Indonesia is #2 in TB cases worldwide. Poor medication adherence causes drug-resistant TB. This app solves that.

## Owner

- **Name:** Ilham Maulana Sulaeman
- **Device:** Realme GT 2 Pro (RMX3301), Android 14 + Huawei Watch (watch receives notifications passively, no special code needed)
- **Goal:** Daily use + Apple Developer Academy portfolio

## How Ilham Works (important)

- Direct and fast - no filler, no over-explaining
- Simple over clever - if there's a 10-line solution and you wrote 50, rewrite it
- Ask before any visual/design decision - never guess on UI
- No Inter/Roboto fonts
- Glassmorphism and gradients are allowed if used with intention and taste - not as defaults
- GPU-safe animations only: `transform` + `opacity`, never `width`/`height`/`top`/`left`
- Only modify what the task requires - don't "improve" adjacent code

## Current Status

See `TODO.md` for full task list with statuses.

**Phase:** Medicine alarm ✅ complete. Water reminder ✅ complete. Habits MVP ✅ complete. Next: Habit skip day / archive, or Routine stacking.  
**App name:** Rutin

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3.44 (Dart) |
| State | flutter_riverpod |
| Storage | hive + hive_flutter |
| Notifications | flutter_local_notifications |
| Alarms | Native AlarmManager (water) + android_alarm_manager_plus (legacy, unused) |
| Navigation | go_router |
| PDF | pdf + printing |
| Localization | flutter_localizations + intl |
| Sleep mode | AccessibilityService (native Android) |

Full details: `docs/ARCHITECTURE.md`

## Key Decisions Already Made

- **Bahasa Indonesia default**, English secondary - target market is Indonesian TB patients
- **Offline-first** - no account, no internet required, ever
- **Free forever** - no paywalls, no premium tier
- **Medicine reminder is alarm-grade** - re-notifies until taken
- **Sleep mode** uses `ACTION_USER_PRESENT` (not screen state) to avoid false triggers from notifications
- **Accessibility Service** used for wake-up routine lock (home button intercept)
- **Riverpod** over Bloc - simpler for a first Flutter project
- **Hive** over SQLite - no SQL knowledge required

## Feature Priority Order

1. Medicine reminder (most critical - TB medication)
2. Water reminder
3. General habits
4. Routine stacking
5. Today / home view
6. TB Treatment Mode
7. Sleep mode + wake-up routine lock
8. Localization
9. Settings

## Data Models

All defined in `docs/ARCHITECTURE.md`. Hive typeIds:
- 0: Medicine
- 1: MedicineLog
- 2: WaterGoal
- 3: WaterLog
- 4: Habit
- 5: HabitLog
- 6: Routine
- 7: RoutineLog
- 8: TBTreatmentProfile
- 9: SleepSettings

## Docs Reference

| File | Contents |
|---|---|
| `TODO.md` | Full task list with statuses |
| `docs/ROADMAP.md` | Phase breakdown, feature specs |
| `docs/ARCHITECTURE.md` | Folder structure, data models, notification + sleep mode logic |
| `docs/WORKFLOW.md` | Dev loop, branch strategy, Flutter commands |
| `MANUAL_TEST_CHECKLIST.md` | Active manual QA checklist |

## Log

Use this section to record significant decisions, blockers, or completions so other agents stay in sync.

---

**2026-05-27 (session 6) - Claude (claude-sonnet-4-6)**
- Full UI/UX redesign across all 9 files (Impeccable pass). No logic changes — visual layer only.
- `AppTheme`: warm `surfaceContainerLow` scaffold bg, `CardThemeData` 0-elevation with 1px `outlineVariant` border, tight letter-spacing text hierarchy, 52px `FilledButton`, floating SnackBar with 12px radius.
- `HomeScreen`: removed AppBar, greeting header with time-of-day salutation ("Selamat pagi/siang/malam"), `FeatureCards` with colored 52×52 icon containers (green/blue/brown), permission wizard logic preserved.
- `WaterProgressWidget`: `TweenAnimationBuilder<double>` → `CustomPainter` 270° arc (GPU-safe), 180×180, `StrokeCap.round`, center stack shows count + label.
- `WaterScreen`: arc centered, `_GlassButton` (68×68 `Material` + `InkWell`) replacing bare `IconButton`, `SingleChildScrollView`.
- `HabitCard`: emoji in 48×48 rounded container, `primaryContainer` tint on done card, streak in `cs.primary` bold.
- `HabitsScreen` + retire sheet: better empty state, improved retire sheet layout.
- `AddHabitScreen`: "JADWAL" section label, "PENGINGAT" bordered container with `InkWell` time row.
- `MedicineListScreen`: time badge with `primaryContainer` bg, improved empty state, `cs.error` Dismissible bg.
- `AddMedicineScreen`: "WAKTU MINUM" section label, `InkWell` time picker row replacing bare `ListTile`.
- Fixed `CardTheme` → `CardThemeData` (API change in newer Flutter SDK).

**2026-05-27 (session 5) - Claude (claude-sonnet-4-6)**
- Added delete (swipe left) for Medicine and Habits. Medicine delete cancels all AlarmManager alarms for that medicine before removing from Hive. Habit delete cancels native HabitAlarmReceiver alarm before removing. Both confirm via AlertDialog before dismissing.
- Medal system: long-press habit card → "Jadikan Medali" bottom sheet → habit removed, medal stored with peak streak. Auto-update: after each markDone, if new streak > existing medal peak, medal silently updates. Medal Hive model (typeId 10) + MedalRepository. Medals UI (profile/trophy tab) deferred.

**2026-05-27 (session 4) - Claude (claude-sonnet-4-6)**
- Completed habits MVP: create habit, check off today, streak counter, optional daily reminder.
- `AddHabitScreen`: name, emoji (text field), 7-day schedule chips (all selected by default), optional reminder toggle + time picker.
- `HabitsScreen`: real Hive-backed list, tap to mark done (guarded against double-log), streak shown on card, empty state, FAB → push /habits/add then `_load()` on pop.
- Navigation fix: `AddHabitScreen` uses `context.pop()` (not `context.go('/habits')`) so the awaited push in HabitsScreen FAB resolves and the list refreshes immediately.
- **Native habit reminder architecture**: `HabitAlarmReceiver.kt` — BroadcastReceiver shows notification (emoji + name, "Waktunya melakukan kebiasaanmu!"), reschedules itself +24h. `HabitReminderService.dart` computes next trigger with `DateTime.now()` (no timezone package needed), passes `triggerMs` via MethodChannel `scheduleHabitAlarm` / `cancelHabitAlarm`.
- Avoided `timezone` + `flutter_timezone` packages — flutter_timezone 1.0.8 had JVM 1.8 target incompatible with project's Java/Kotlin 17; native AlarmManager approach sidesteps this entirely and stays consistent with water alarm architecture.
- Notification tap (`payload == 'habit'`) routes to `/habits` via `appRouter.go()`.

**2026-05-27 (session 3) - Claude (claude-sonnet-4-6)**
- Completed water reminder feature end-to-end.
- **Native water alarm architecture**: replaced android_alarm_manager_plus + flutter_local_notifications action callbacks with two native Kotlin BroadcastReceivers: `WaterAlarmReceiver` (shows notification, reschedules via AlarmManager) and `WaterActionReceiver` (handles "Sudah minum" tap — cancels notification, writes pending count to SharedPreferences). No app launch on action tap.
- Root cause of broken action callback: flutter_local_notifications background isolate `initialize()` was overwriting the registered Flutter engine on the native side, so action broadcasts were delivered to a dead isolate.
- Fixed Kotlin `Long`/`Integer` type mismatch in MethodChannel (`call.argument<Any>(...) as? Number`)?.toLong()`) — without this, `intervalMs` defaulted to 2 hours instead of 15 seconds.
- Fixed race condition: `_load()` (sync) and `_checkPendingLogs()` (async) are now separate — previously a single async `_load()` could reassign `_goal` mid-flight and reset the reminder toggle.
- Pending water logs are synced to Hive when the Water screen is opened or app resumes.
- Debug mode: alarm fires every 15 seconds (native), notifications appear as banner on all phone states.
- Water settings (start/end/interval) are saved to native SharedPreferences so `WaterAlarmReceiver` can check the time window without a Flutter engine.

**2026-05-27 - Claude (claude-sonnet-4-6)**
- Full alarm system diagnosis: root cause was `context.startActivity()` blocked on Android 10+ (API 29+).
- Fixed `ReminderAlarmReceiver.kt`: replaced `startActivity()` with `showFullScreenNotification()` — posts notification with `setFullScreenIntent()`. Android now handles: screen off → full-screen ReminderActivity; screen on → notification banner.
- Fixed `ReminderActivity.kt`: both buttons now call `nm.cancel(alarmId)` before finish(); removed contradictory `FLAG_ALLOW_LOCK_WHILE_SCREEN_ON`.
- Fixed `notification_service.dart`: notification ID is now `alarmId` directly (was random timestamp — couldn't cancel by ID).
- Fixed `notification_handler.dart`: removed double scheduling in snooze (`startRenotifyLoop()` removed — native receiver already reschedules).
- Fixed `add_medicine_screen.dart`: `context.pop()` → `context.go('/medicine')` so user lands on updated list after saving.
- Created `docs/plan/report.md` + `docs/plan/plan.md` for full technical record.
- Created `docs/DECK.md` — app pitch for Apple Developer Academy + personal portfolio.
- App named **Rutin**. Git repo initialized, first commit `2e6ce21`.
- Verified on Realme GT 2 Pro / Android 14: screen-off full-screen ✅, screen-on banner ✅, snooze ✅.
- Gradle OOM fixed: daemon disabled, heap reduced to 512m in `android/gradle.properties`.

**2026-05-25 - Codex (gpt-5)**
- Environment setup completed and scaffold confirmed working on physical device.
- Project scaffold wiring completed: dependencies, Hive adapter registration, Riverpod providers, go_router, localization delegates, base theme.
- Implemented medicine add flow and fixed back navigation behavior from Home.
- Implemented reminder action flow and changed snooze to **1 minute**.
- Added and iterated `MANUAL_TEST_CHECKLIST.md` as active QA source.
- User-verified: full-screen block can open, `Tunda 1 menit` can re-trigger, and `Sudah diminum` can stop.
- Active blocker: forced full-screen re-open on every repeat is still inconsistent on target device behavior path; native forced-path work is in progress and not finalized.

**2026-05-25 - Claude (claude-sonnet-4-6)**
- Project scoped and documented from scratch
- Created: README.md, TODO.md, AGENTS.md, docs/ROADMAP.md, docs/ARCHITECTURE.md, docs/WORKFLOW.md
- Flutter SDK 3.44.0 downloaded and setup initiated
- Key features decided: medicine reminder, water, habits, routine stacking, TB treatment mode, sleep mode with Accessibility Service, Bahasa Indonesia default
- Sleep mode logic specified (including audio timer edge case)

---
<!-- Add new log entries above this line, newest first -->
