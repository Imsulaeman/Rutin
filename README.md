# [App Name TBD]

A personal Android habit and health reminder app. Built for daily-use — not a generic habit tracker, but a focused health tool.

## Why This Exists

Most habit apps are either too generic or locked behind paywalls. This one is built around a real need: reliably taking medicine, drinking enough water, and building small daily habits — all free, forever, local-first.

## Core Philosophy

- **Alarm-grade medicine reminders** — re-notifies every 10 min until confirmed taken
- **Local-first** — no account, no internet, data stays on your phone
- **Free, always** — no paywalls, no premium tiers
- **Huawei Watch ready** — notifications appear on watch automatically

## Features

### Phase 1 — MVP
- [ ] Medicine reminder (persistent, full-screen, re-notifies until "Taken")
- [ ] Water reminder (interval-based, log glasses)
- [ ] General habits (daily check-off, streak counter)
- [ ] Huawei Watch notification passthrough
- [ ] Local storage (offline, no account)

### Phase 2 — Polish
- [ ] Weekly stats and completion rate
- [ ] Habit categories
- [ ] Huawei Health Kit (steps/heart rate as nudge context)

### Phase 3 — ADA-ready
- [ ] Onboarding flow
- [ ] Data export/backup
- [ ] App icon and splash screen

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3.44 (Dart) |
| State management | Riverpod |
| Local storage | Hive |
| Notifications | flutter_local_notifications + android_alarm_manager_plus |
| Navigation | go_router |

## Getting Started

> Setup guide coming after Flutter environment is configured.

## Project Structure

```
lib/
  main.dart
  app.dart
  core/           # theme, constants, utilities
  features/
    medicine/     # persistent reminders
    water/        # hydration tracking
    habits/       # general habits
    notifications/# alarm scheduling engine
  shared/         # widgets, models
```
