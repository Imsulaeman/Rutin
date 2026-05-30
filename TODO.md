# TODO

Status: `[ ]` todo | `[x]` done | `[-]` in progress | `[~]` blocked

---

## Handoff -> Codex

### Kebiasaan (Habits)
- [x] Restore clear stack creation from `Semua`
- [x] Drag habit onto another habit to create a new stack
- [x] Move habit reminder time to the right side, Obat-style placement
- [x] Keep habit reminder pill aligned with Habits theme instead of copying Obat pink literally

### Obat (Medicine)
- [x] Daily medicine schedule re-arms for the next day
- [x] Swipe-to-delete on medicine items
- [x] Persistent medicine reminder repeats every 1 minute until taken
- [x] Today-first Obat workflow with sections: `Perlu diminum sekarang`, `Berikutnya`, `Sudah diminum`, `Terlewat`
- [x] Food timing on medicine: `Bebas`, `Sebelum makan`, `Sesudah makan`, `Saat makan`
- [x] Separate Riwayat calendar page for medicine adherence
- [ ] RECEIVE_BOOT_COMPLETED reschedule after reboot
- [ ] Streak counter per medicine
- [ ] Missed log entry finalization policy at end of day

### Air (Water)
- [x] Replace add-water snackbar with persistent inline undo

---

## Environment Setup
- [x] Install Flutter SDK 3.44.0
- [x] Install Android Studio
- [x] Install VS Code Flutter + Dart extensions
- [x] Run `flutter doctor`
- [x] Connect physical Android device
- [x] Confirm first app boot on device

## Project Scaffold
- [x] `flutter create` with package name `com.rutin.app` (renamed from `com.ilham.habit_app`)
- [x] Set up folder structure per `docs/ARCHITECTURE.md`
- [x] Add packages to `pubspec.yaml`
- [x] Configure Hive adapters
- [x] Set up Riverpod providers
- [x] Set up `go_router`
- [x] Set up localization
- [x] Set up base theme

## Feature: Medicine Reminder
- [x] Medicine data model + Hive adapter
- [x] MedicineLog data model + Hive adapter
- [x] MedicineRepository
- [x] Native notification + alarm flow
- [x] Re-notification every 1 minute until `Sudah diminum`
- [x] `Sudah diminum` stops the active dose loop
- [x] `Tunda 1 menit`
- [x] Daily medicine alarms continue across days after the current dose is taken
- [x] Add Medicine screen
- [x] Medicine Today screen
- [x] Medicine history / calendar page
- [x] Swipe delete with alarm cancellation
- [x] Forced full-screen re-open on repeat path
- [ ] RECEIVE_BOOT_COMPLETED reschedule
- [ ] Medicine streaks

## Feature: Water Reminder
- [x] WaterGoal + WaterLog data models
- [x] WaterRepository
- [x] Interval reminder within active window
- [x] Quick add / remove glass
- [x] Daily progress indicator
- [x] Water screen UI
- [x] WHO-based target / interval logic
- [x] Native reminder toggle on/off
- [x] Native `Sudah minum` action
- [x] Settings sheet
- [x] Inline undo bar

## Feature: General Habits
- [x] Habit + HabitLog data models
- [x] HabitRepository
- [x] Create habit with optional reminder
- [x] Check off for today
- [x] Streak counter
- [x] Skip non-scheduled days without breaking streak
- [x] Medal flow
- [x] Habits list screen
- [x] Live updates

## Feature: Habit Groups
- [x] HabitGroup model
- [x] Group repository operations
- [x] Scrollable tab bar with `Semua`
- [x] Drag reorder in groups
- [x] Create / rename / delete groups
- [x] Drag routines into stacks
- [x] Swipe-to-delete on habits and stacks
- [x] Stack unfolds after move
- [ ] Habit history / calendar view
- [ ] Routine streak

## Feature: Home / Today View
- [x] Combine routines + standalone habits + water progress
- [x] At-a-glance done / pending / missed
- [ ] TB treatment countdown

## Feature: TB Treatment Mode
- [x] TBTreatmentProfile data model
- [ ] TB onboarding
- [ ] Treatment countdown on home
- [ ] Adherence score
- [ ] PDF adherence report
- [ ] Share via Android share sheet

## Feature: Sleep Mode + Wake-up Routine Lock
- [x] SleepSettings data model
- [ ] Foreground service monitor
- [ ] `ACTION_USER_PRESENT` receiver
- [ ] AccessibilityService intercept flow
- [ ] Audio detection
- [ ] Sleep mode logic per architecture doc
- [ ] Manual override
- [ ] Wake-up window
- [ ] Full-screen routine lock screen
- [ ] Graceful degradation if accessibility denied
- [ ] Restart after reboot

## Feature: Localization
- [x] `flutter_localizations` + `intl`
- [x] Bahasa Indonesia strings
- [x] English strings
- [ ] Language toggle in settings

## Settings Screen
- [ ] Sleep mode on/off + schedule
- [ ] Wake-up window range
- [ ] Language toggle
- [ ] Battery optimization guidance
- [ ] Accessibility status + grant button
- [ ] About / version

## Phase 2
- [ ] Weekly stats per habit
- [ ] Caregiver view
- [ ] Huawei Health Kit integration
- [ ] WhatsApp adherence share
- [ ] Notes on medicine completion
- [ ] Obsidian / Second Brain integration
- [ ] Home screen widget

## Feature: Analytics + Infrastructure
- [x] Firebase Analytics setup (`com.rutin.app`)
- [x] Key events: medicine_taken, medicine_added, medicine_archived, medicine_deleted, habit_completed, habit_added, water_added
- [x] Medicine archive / unarchive flow (swipe right = arsipkan, history preserved)
- [x] Multi-dose support (unlimited times per medicine in add flow)
- [ ] RECEIVE_BOOT_COMPLETED reschedule (medicine + water alarms after reboot)
- [ ] Accounts / cloud backup (Phase 2 — Supabase, Google/Apple/email auth)

## Polish / ADA Ready
- [ ] Onboarding flow
- [x] App name: Rutin
- [x] Package name: `com.rutin.app`
- [ ] App icon
- [ ] Splash screen
- [x] Empty states
- [x] UI redesign pass
- [ ] Medal/profile collection screen
- [ ] Data backup / JSON export
- [ ] Play Store listing
