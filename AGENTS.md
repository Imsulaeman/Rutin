# Agent Context

Read this first before touching any code. This file keeps all AI agents (Claude, Codex, etc.) aligned.

## What This Project Is

A Flutter Android app for daily health habits and reminders. Built by Ilham Maulana Sulaeman, a university student in Bandung, Indonesia who has TB and needed a reliable medicine reminder that actually works - free, no paywalls, local-first.

**Not** a generic habit tracker. A personal health infrastructure tool, with a real mission: Indonesia is #2 in TB cases worldwide. Poor medication adherence causes drug-resistant TB. This app solves that.

## Owner

- **Name:** Ilham Maulana Sulaeman
- **Device:** Android phone + Huawei Watch (watch receives notifications passively, no special code needed)
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

**Phase:** Medicine reminder reliability + forced full-screen behavior testing  
**Next:** Stabilize forced full-screen re-open on every repeat on target device behavior, then continue priority feature buildout

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3.44 (Dart) |
| State | flutter_riverpod |
| Storage | hive + hive_flutter |
| Notifications | flutter_local_notifications |
| Alarms | android_alarm_manager_plus (plus native fallback experiments) |
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
