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
- [x] Delete medicine (swipe left → confirm dialog → cancels alarm + removes from Hive)
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
- [x] Create habit (name, emoji, schedule, optional reminder)
- [x] Check off for today
- [x] Streak counter
- [x] Skip day without breaking streak (handled by scheduleDays — only selected days count)
- [x] Archive habit → replaced with Medal system (long-press → "Jadikan Medali")
- [x] Habits list screen
- [x] Water tracker: ml-based (addMl/removeMl), undo snackbar, quick-add chips
- [x] Snackbar text color fixed (white on dark background)
- [x] colorValue LateInitializationError fix on new habit save

## Feature: Habit Groups (Routine Stacking)
- [x] HabitGroup model (typeId 11) — first-class named group with emoji + sortIndex
- [x] Habit.groupId + Habit.sortIndex replace linked-list stacking fields
- [x] HabitRepository: getGroups, habitsInGroup, reorderHabitsInGroup, deleteGroup
- [x] Habits screen: scrollable tab bar (Semua + one tab per group)
- [x] Drag-to-reorder within group tab (long-press drag handle)
- [x] Create group inline (──── + Buat rutinitas baru)
- [x] Rename / delete group via ··· menu on group header
- [x] Star mascot motivational banner at bottom of habits screen
- [x] Compact habit cards (44px icon, streak text, 12px padding)
- [x] Add habit screen: group picker chips replace old stacking UI
- [x] Drag routine directly INTO an expanded stack — edit mode (Atur/Selesai) with LongPressDraggable + DragTarget zones
- [ ] Habit history / calendar view
- [ ] Routine streak (group-level completion streak)

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
- [x] Empty states for all screens
- [x] UI/UX redesign — all screens (Impeccable pass, session 6)
- [ ] Medal/profile screen (view collected medals)
- [ ] Data backup / export JSON
- [ ] Play Store listing
