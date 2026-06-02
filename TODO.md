# TODO

Status: `[ ]` todo | `[x]` done | `[-]` in progress | `[~]` blocked

---

## Handoff -> Codex

### Bugs (fix first)
- [x] Home dashboard appears gone after solid header/navbar edit in `home_screen.dart` — likely overlay/header sizing regression
- [x] Splash red screen — remove `_SplashPage` and `_AppRoot` from `main.dart`, go straight to `HabitApp()` (spec in AGENTS.md)
- [x] Remove medicine archive flow; use delete-only behavior instead
- [x] Medicine alarm behavior accepted for now — full takeover works in-app; outside apps it falls back to notification + alarm sound
- [x] Obat red screen after archive removal — fix `Dismissible` assertion and empty-dose card crash
- [x] Missed log entry finalization policy at end of day

### Kebiasaan (Habits)
- [x] Restore clear stack creation from `Semua`
- [x] Drag habit onto another habit to create a new stack
- [x] Move habit reminder time to the right side, Obat-style placement
- [x] Keep habit reminder pill aligned with Habits theme instead of copying Obat pink literally
- [x] Rewrite Connect the Dots → Flow Free style (grid, colored pairs, fill all cells) — spec in AGENTS.md
- [x] Habit calendar visual — full cell background colors instead of tiny dots
- [x] Compact habit cards (reduce padding, merge streak into name row)
- [x] History screen (month calendar + selected-day combined activity feed from Profile menu)

### Obat (Medicine)
- [x] Daily medicine schedule re-arms for the next day
- [x] Swipe-to-delete on medicine items
- [x] Persistent medicine reminder repeats every 1 minute until taken
- [x] Today-first Obat workflow with sections: `Perlu diminum sekarang`, `Berikutnya`, `Sudah diminum`, `Terlewat`
- [x] Food timing on medicine: `Bebas`, `Sebelum makan`, `Sesudah makan`, `Saat makan`
- [x] Separate Riwayat calendar page for medicine adherence
- [x] RECEIVE_BOOT_COMPLETED reschedule after reboot (medicine and water user-tested)
- [x] Streak counter per medicine
- [x] Remove archive bug surface by deleting archive flow
- [x] Medicine alarm behavior accepted for now — `ReminderActivity` reliably works in-app; outside apps still behave as heads-up + sound on target device
- [x] Obat screen stable after archive removal
- [x] Missed log entry finalization policy at end of day

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
- [x] RECEIVE_BOOT_COMPLETED reschedule
- [x] Medicine streaks

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
- [x] Multiple daily reminder times per habit
- [x] Per-reminder completion count + partial streak semantics
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
- [x] Habit history / calendar view
- [x] Routine streak

## Feature: Home / Today View
- [x] Combine routines + standalone habits + water progress
- [x] At-a-glance done / pending / missed
- [x] Treatment program countdown
- [x] Navbar solid background (non-transparent)

## Feature: Treatment Program (generic — TB, Tifus, Malaria, ARV, etc.)
- [x] TBTreatmentProfile data model
- [x] Add conditionName field to model
- [x] Onboarding screen (condition, start date, duration, link medicine)
- [x] Treatment detail screen (progress, adherence, PDF export)
- [x] Home countdown card
- [x] Profile menu entry point
- [x] PDF adherence report + share sheet

## Feature: Sleep Mode + Wake-up Game Gate
- [x] SleepSettings data model
- [x] **Session A** — Sleep settings screen (Flutter): toggle, sleep time, wake window, accessibility guidance, battery optimization prompt
- [x] **Session B** — Wake-up game screen (Flutter): daily-rotating games, emergency skip after 15s, morning streak, completion celebration + sound
  - [x] Game 0: Sequence Memory (3 rounds, colored tiles)
  - [x] Game 2: Tap Rhythm (10 falling circles, hit 7/10)
  - [x] Game 5: Connect the Colors (Flow Free-style 6×6 puzzle, 4 colored pairs)
- [x] **Session C** — Native sleep detection service (Kotlin): foreground service, 3-case logic, ACTION_USER_PRESENT receiver, MethodChannel bridge, launches game screen
- [x] **Session D** — AccessibilityService (Kotlin): home button intercept during game, touch tracking for sleep detection, XML config

- [x] **Morning Gate** - read-only morning dashboard + slide-to-unlock before `/wakeup-game`
- [x] Replace incorrect sleep foreground `health` service type with `specialUse`
- [x] Refresh Accessibility status after returning from Android settings
- [x] Retest Infinix X6873: enabling Mode Tidur no longer force-closes after Android 13+ receiver registration fix
- [x] Retest Infinix X6873: Home or window switching during Morning Gate reuses one existing gate
- [x] Schedule SleepModeService silently at bedtime instead of showing an all-day foreground notification
- [ ] Retest nightly transition: `Mode tidur aktif` notification appears at bedtime and disappears after the wake window or gate dismissal

## Feature: Localization
- [x] `flutter_localizations` + `intl`
- [x] Bahasa Indonesia strings
- [x] English strings
- [x] Runtime language switch with phone-locale default
- [x] Native Android reminder localization mirror
- [x] Finish EN sweep for deep secondary dialogs and low-frequency game copy

## Settings Screen
- [x] Sleep mode link + accessibility status
- [x] Full-screen medicine alarm permission status + settings shortcut
- [x] Language selector (`🇮🇩 ID` / `🇬🇧 EN`) with immediate runtime switch
- [x] Reminder sound categories (`app` vs `phone default`) for notification and alarm sounds
- [x] About / version
- [x] Battery optimization guidance
- [x] Wake-up window range (in /sleep-settings)
- [x] Tutorial button (Settings → LAINNYA → replays coach marks overlay)
- [x] Data backup / JSON export (Settings → DATA → share sheet)

## Feature: Analytics + Infrastructure
- [x] Firebase Analytics setup (`com.rutin.app`)
- [x] Key events: medicine_taken, medicine_added, medicine_archived, medicine_deleted, habit_completed, habit_added, water_added
- [x] Medicine list uses delete-only flow; archive removed
- [x] Multi-dose support (unlimited times per medicine in add flow)
- [x] RECEIVE_BOOT_COMPLETED reschedule (medicine and water confirmed after reboot)
- [ ] Accounts / cloud backup (Phase 2 — Supabase, Google/Apple/email auth)

## Polish / ADA Ready
- [x] Onboarding flow
- [x] App name: Rutin
- [x] Package name: `com.rutin.app`
- [x] App icon
- [x] Splash screen
- [x] Empty states
- [x] UI redesign pass
- [ ] Dedicated medal/profile collection screen polish
- [x] Profile: user name + age + avatar picker (10 diverse characters) + stat chips

## ADA Portfolio Prep
- [x] App icon (final, production-ready) — prompts in `LOGO_PROMPT.md`
- [x] Splash screen
- [x] Onboarding flow (3–5 screens: problem, solution, permissions ask)
- [x] Coach marks tutorial (5-step overlay: header, FAB, medicine tab, water tab, habits tab)
- [x] Privacy policy page (hosted URL required — Firebase Analytics makes this a hard Play Store blocker)
- [x] Play Store listing copy (ID + EN): short description, full description, feature graphic — see store_listing.md
- [ ] Play Store screenshots (6 screens: Home, Medicine, Water, Habits, Sleep Gate, Game)
- [ ] Feature graphic (1024×500px banner)
- [ ] Update Settings About + privacy policy contact → Benih Studio
- [ ] Upload signed APK to Play Console (awaiting account verification)
- [ ] Fill store listing in Play Console (copy ready in store_listing.md)
- [ ] Complete content rating questionnaire in Play Console
- [-] App pitch deck / one-pager — structure in `deck.md`
- [ ] Demo video / screen recording (30–60s walkthrough)
- [ ] README polish (GitHub repo, for ADA reviewers who look at code)
- [~] Internal beta on Play Store — not required for ADA; skip for now
- [ ] Crash-free rate check (Firebase Crashlytics or at minimum no known crashes)
- [x] **Post-MVP design polish pass** (only once MVP is done + launch-ready): run `/emil-design-eng`, `/impeccable`, `/gpt-taste` across all screens for final visual refinement — full report in `report.md`
- [ ] Play Store listing

## From Review Report (report.md) — 2026-06-02

### P1 — Immediate
- [x] **Custom font**: add Bricolage Grotesque (display) + DM Sans (body) via `google_fonts`; apply in `AppTheme`
- [x] **Permission dialog rewrite**: replace single `AlertDialog` with step-by-step bottom sheet (one permission per step, stays open)
- [x] **Hive encryption**: encrypt `medicines`, `medicine_logs`, `tb_profiles` with `HiveAesCipher` + `flutter_secure_storage`

### P2 — Before Play Store
- [ ] **Checkbox AnimatedContainer curve**: add `curve: Curves.easeOut` to the habit checkbox container in `home_screen.dart:1344`
- [ ] **FAB press feedback**: wrap FAB `GestureDetector` in `_Pressable` in `app.dart`
- [ ] **Dependency injection**: move `WaterRepository()` and `HabitRepository()` in `HomeScreen` to Riverpod providers
- [x] **Permission flag persistence**: save `_permissionDialogShown` to Hive `app_settings` instead of static bool
- [ ] **Battery optimization rationale**: show explanation dialog before calling `requestIgnoreBatteryOptimizations`

### P3 — Polish
- [ ] **GoRouter page transitions**: add `CustomTransitionPage` with fade (280ms easeOut) for shell routes
- [ ] **Calendar icon in home header**: wire to `/history` or remove
- [ ] **Migrate `localized()` calls to ARB**: move all inline `localized(context, id:..., en:...)` strings to `app_en.arb` and `app_id.arb`
- [ ] **Ambient sun easing**: apply `CurvedAnimation(curve: Curves.easeInOut)` to `_ambient` controller to smooth sine reversal

### P4 — Backlog
- [ ] **Unit tests**: add tests for `HabitRepository.getStreak()` and `MedicineRepository.isTaken()`
- [ ] **Play Store**: add Accessibility Service `android:description` in manifest narrowing use case
- [ ] **Play Store**: audit Firebase Analytics event params — confirm no PII or medication names sent
- [ ] **Lazy Hive box opening**: open non-critical boxes (`medals`, `morning_streaks`) after first frame via `addPostFrameCallback`

## Phase 2
- [ ] Custom sound import/upload for reminders
- [ ] Optional additional wake-up games: Word Unscramble, Tile Puzzle, Daily Quiz
- [ ] Weekly stats per habit
- [ ] Caregiver view
- [ ] Huawei Health Kit integration
- [ ] WhatsApp adherence share
- [ ] Notes on medicine completion
- [ ] Obsidian / Second Brain integration
- [ ] Home screen widget
