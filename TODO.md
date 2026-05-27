# TODO

Status: `[ ]` todo · `[x]` done · `[-]` in progress · `[~]` blocked

---

## Environment Setup
- [x] Install Flutter SDK 3.44.0
- [x] Install Android Studio
- [x] Install VS Code Flutter + Dart extensions
- [x] Run `flutter doctor` - fix all issues
- [x] Connect physical Android device (enable USB debugging)
- [x] Run first `flutter create` and confirm app boots on device

## Project Scaffold
- [x] `flutter create` with package name `com.ilham.habit_app` (name TBD)
- [x] Set up folder structure per ARCHITECTURE.md
- [x] Add all packages to `pubspec.yaml`
- [x] Configure Hive - register all adapters
- [x] Set up Riverpod providers
- [x] Set up go_router navigation
- [x] Set up localization (Bahasa Indonesia default, English secondary)
- [x] Set up base theme (no Inter/Roboto)

## Feature: Medicine Reminder (Priority 1)
- [x] Medicine data model + Hive adapter
- [x] MedicineLog data model + Hive adapter
- [x] MedicineRepository (CRUD)
- [x] Notification service - full-screen intent
- [x] Alarm service - re-notification every 10 min until "Taken"
- [x] "Taken" action dismisses all pending re-notifications
- [x] "Snooze 1 min" action
- [ ] RECEIVE_BOOT_COMPLETED - reschedule alarms after reboot
- [x] Add Medicine screen (name, dosage, times)
- [x] Medicine list screen
- [x] Forced full-screen re-open on every repeat (all devices)
- [ ] Streak counter per medicine
- [ ] Missed log entry if not taken by end of day

## Feature: Water Reminder
- [x] WaterGoal + WaterLog data models
- [x] WaterRepository
- [x] Interval reminder (every X hours, within active window)
- [x] Quick log - tap to add / remove a glass
- [x] Daily progress indicator
- [x] Water screen UI
- [x] Science-backed target: daily L goal + glass size (ml) → auto-calculated interval
- [x] Reminder toggle on/off with native AlarmManager
- [x] "Sudah minum" action button — no app launch, native BroadcastReceiver
- [x] Settings sheet: target slider, glass size, start/end hours, WHO note

## Feature: General Habits
- [x] Habit + HabitLog data models
- [x] HabitRepository
- [ ] Create habit (name, emoji, schedule, optional reminder)
- [ ] Check off for today
- [ ] Streak counter
- [ ] Skip day without breaking streak
- [ ] Archive habit (pause without deleting)
- [x] Habits list screen

## Feature: Routine Stacking
- [x] Routine + RoutineLog data models
- [ ] RoutineRepository
- [ ] Create routine (name, anchor type, habit sequence)
- [ ] Sequential flow UI - one habit at a time
- [ ] Auto-prompt next habit on completion
- [ ] Routine streak separate from habit streak
- [ ] Routine progress (e.g. "2 of 4 done")

## Feature: Home / Today View
- [ ] Combine routines + standalone habits + water progress
- [ ] At-a-glance status: done / pending / missed
- [ ] TB treatment countdown ("142 days to go")

## Feature: TB Treatment Mode
- [x] TBTreatmentProfile data model
- [ ] Onboarding: "Are you in TB treatment?" -> pre-configure
- [ ] Treatment countdown on home screen
- [ ] Adherence score (% of days taken)
- [ ] Adherence report - generate PDF
- [ ] PDF share via Android share sheet

## Feature: Sleep Mode + Wake-up Routine Lock
- [x] SleepSettings data model
- [ ] Foreground service - sleep mode monitor
- [ ] ACTION_USER_PRESENT broadcast receiver
- [ ] AccessibilityService - home button intercept + interaction tracking
- [ ] Audio detection - AudioManager.isMusicActive()
- [ ] Sleep mode logic (all 4 cases per ARCHITECTURE.md)
- [ ] Manual override - "I'm still awake" on notification
- [ ] Wake-up window (5 AM - 10 AM default)
- [ ] Full-screen routine lock screen (above lockscreen)
- [ ] Graceful degradation if Accessibility Service denied
- [ ] RECEIVE_BOOT_COMPLETED - restart service after reboot

## Feature: Localization
- [x] Set up flutter_localizations + intl
- [x] Bahasa Indonesia strings
- [x] English strings
- [ ] Language toggle in settings

## Settings Screen
- [ ] Sleep mode on/off + schedule
- [ ] Wake-up window time range
- [ ] Language (ID / EN)
- [ ] Battery optimization guidance
- [ ] Accessibility Service status + grant button
- [ ] About / app version

## Phase 2 (Later)
- [ ] Weekly stats per habit
- [ ] Caregiver view (read-only share)
- [ ] Huawei Health Kit integration
- [ ] WhatsApp status share of adherence
- [ ] Notes on medicine completion
- [ ] Second Brain / Obsidian integration
- [ ] Home screen widget

## Polish / ADA Ready
- [ ] Onboarding flow
- [x] App name: Rutin
- [ ] App icon
- [ ] Splash screen
- [ ] Empty states for all screens
- [ ] Data backup / export JSON
- [ ] Play Store listing
