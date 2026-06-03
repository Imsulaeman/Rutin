# Agent Context

Read this first before touching any code. This file keeps all AI agents (Claude, Codex, etc.) aligned.

## What This Project Is

A Flutter Android app for daily health habits and reminders. Built by Ilham Maulana Sulaeman, a university student in Bandung, Indonesia who has TB and needed a reliable medicine reminder that actually works — free, no paywalls, local-first.

**Not** a generic habit tracker. A personal health infrastructure tool with a real mission: Indonesia is #2 in TB cases worldwide. Poor medication adherence causes drug-resistant TB. This app solves that.

## Owner

- **Name:** Ilham Maulana Sulaeman
- **Device:** Realme GT 2 Pro (RMX3301), Android 14 + Huawei Watch (watch receives notifications passively, no special code needed)
- **Goal:** Daily use + Apple Developer Academy portfolio

## How Ilham Works (important)

- Direct and fast — no filler, no over-explaining
- Simple over clever — if there's a 10-line solution and you wrote 50, rewrite it
- Ask before any visual/design decision — never guess on UI
- Treat localization as a product requirement, not polish - no mixed-language UI, no hardcoded visible strings on user-facing screens, and no manual Indonesian-only date/day/month labels when locale-aware formatting exists
- No Inter/Roboto fonts
- Glassmorphism and gradients are allowed if used with intention and taste — not as defaults

## Current Status

See `TODO.md` for full task list with statuses.

**Phase:** Medicine ✅ Water ✅ Habits ✅ Home today view ✅ Firebase Analytics ✅ Sleep Mode ✅ Morning Gate ✅
**App name:** Rutin — Package: `com.rutin.app`

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3.44 (Dart) |
| State | flutter_riverpod |
| Storage | hive + hive_flutter |
| Notifications | flutter_local_notifications |
| Alarms | Native AlarmManager (water/habit) + NativeReminderScheduler (medicine) |
| Navigation | go_router |
| PDF | pdf + printing |
| Localization | flutter_localizations + intl |
| Sleep mode | AccessibilityService (native Android) + SleepModeService foreground service |

Full details: `docs/ARCHITECTURE.md`

## Key Decisions Already Made

- **Bahasa Indonesia default**, English secondary
- **Localization must stay complete in both supported languages** - every new visible string, dialog, snackbar, helper text, empty state, mascot nudge, and date/day/month label must respect the selected locale
- **Offline-first** — no account, no internet required, ever
- **Free forever** — no paywalls, no premium tier
- **Medicine reminder is alarm-grade** — re-notifies every 1 min until taken
- **Sleep mode** uses `ACTION_USER_PRESENT` (not screen state) to avoid false triggers
- **Accessibility Service** used for home button intercept during morning gate/game
- **No build_runner** — Hive `.g.dart` adapters are edited by hand when model changes
- **Riverpod** over Bloc; **Hive** over SQLite
- **HapticsService** (native `VibrationEffect.createOneShot`, 255 amplitude) — not Flutter's `HapticFeedback.*` which is too weak on Android

## Sleep Mode Architecture (built)

```
SleepScheduleReceiver (silent AlarmManager bedtime alarm)
  → starts SleepModeService only during the configured nightly window
  → foreground notification appears only while nightly detection is running

SleepModeService polls every 5 min → 3-case sleep detection
  → sets sleep_active=true in SharedPrefs

ACTION_USER_PRESENT → WakeUpTriggerReceiver
  → checks sleep_active + wake window (or test_trigger to bypass)
  → starts MainActivity with route="/morning-gate"

MainActivity.onNewIntent → MethodChannel("rutin/sleep").invokeMethod("launchGame")
  → _LaunchGameListener in app.dart pushes /morning-gate

/morning-gate: compact header + medicine/habits dashboard + slide-to-unlock
  → slide 85% → pushes /wakeup-game (daily seed: Sequence or Piano Tiles)
  → game complete → both screens pop

RutinAccessibilityService: if game_active && user leaves app → bring the existing MainActivity task forward
PopScope(canPop: false) blocks Flutter back during gate
```

**Test path:** Profile → Mode Tidur → Test Sleep Gate → gate appears immediately (bypasses window check via test_trigger flag)

## Data Models

All defined in `docs/ARCHITECTURE.md`. Hive typeIds:
- 0: Medicine (`scheduleTimes: List<int>`, `mealTimingKey: String`)
- 1: MedicineLog
- 2: WaterGoal (`reminderActive`, `reminderIntervalMinutes`, `startTimeMinutes`, `endTimeMinutes`, `glassSizeMl`, `dailyTargetMl`)
- 3: WaterLog (`mlLogged` @HiveField(2) — hand-edited adapter, glassesLogged kept but unused)
- 4: Habit (`reminderMinutes: int?` @HiveField(4) — single reminder, see pending task for multi)
- 5: HabitLog
- 6: Routine
- 7: RoutineLog
- 8: TBTreatmentProfile
- 9: SleepSettings
- 10: Medal
- 11: HabitGroup
- 12: UserProfile
- `morning_streaks`: `Box<int>` keyed by `"yyyy-MM-dd"` → 1 when game completed that day

## Docs Reference

| File | Contents |
|---|---|
| `TODO.md` | Full task list with statuses |
| `docs/ARCHITECTURE.md` | Folder structure, data models, notification + sleep mode logic |
| `MANUAL_TEST_CHECKLIST.md` | Active manual QA checklist |

## Log

Recent significant decisions and completions. Oldest entries pruned — see git log for full history.

---

**2026-06-03 - Codex**
- **P4 compliance + test batch shipped**:
  - Added focused repository tests for `HabitRepository.getStreak()` and `MedicineRepository.isTaken()`.
  - Removed medicine and habit names from Firebase Analytics event params so no medication names or other user-entered labels are sent.
  - Added `android:description` to `RutinAccessibilityService` with a narrow Morning Gate use case for Play Store review.
  - Kept `medals` lazy-open deferred for now because Profile and Habits still read that box directly on normal app startup; forcing it now would risk a regression.
- **Sleep settings status refresh softened**: returning from Android settings now re-checks sleep permission statuses immediately and once more after a short delay to reduce cases where the UI only updates after a restart.
- **Verified:** `flutter test test/habit_repository_test.dart test/medicine_repository_test.dart`, focused `dart analyze`, and `gradlew app:compileDebugKotlin --no-daemon` passed.

---

**2026-06-02 - Claude**
- **Play Store prep in progress — paused at account verification**:
  - Studio name: **Benih Studio** (chosen over personal name)
  - Play Console account registered, awaiting Google verification before publishing
  - Release APK built: `build/app/outputs/flutter-apk/app-release.apk` (78MB, signed)
  - Keystore: `android/rutin-release.jks` — alias `rutin`, password stored in `android/key.properties` (gitignored). **Back up the .jks to Google Drive.**
  - Store listing copy: `store_listing.md` — ID + EN short desc, full desc, category, keywords
  - Privacy policy live: `https://imsulaeman.me/rutin-privacy/`
  - Gradle JVM kept at 2GB heap / 512m metaspace / 128m code cache after review (4GB was too aggressive on the 5GB machine)
  - Pending after verification: upload APK, fill store listing, screenshots, feature graphic, content rating, Settings About section → update to Benih Studio

---

**2026-06-02 - Claude**
- **Coach marks tutorial fixed (3 bugs from source read):**
  1. `enableOverlayTab` defaults to `false` in the library — every `TargetFocus` was missing `enableOverlayTab: true`, so tapping the dark overlay did nothing. Fixed on all targets.
  2. Wrong overlay level — was using `Navigator.of(context, rootNavigator: true).context` which resolves incorrectly. Correct API is `show(context: context, rootOverlay: true)`, which calls `Overlay.of(context, rootOverlay: true)` and also makes `getTargetCurrent` use root overlay coordinates. Fixed.
  3. Animation guard `_isAnimating` blocks taps for the full default 900ms focus animation. Added `focusAnimationDuration: 300ms` / `unFocusAnimationDuration: 200ms` per target.
- **Known bug — first-launch tutorial timing**: `onboarding_screen.dart._requestAndFinish()` calls `TutorialTrigger.fire()` before `context.go('/')`. On cold start, HomeScreen hasn't registered its `TutorialTrigger` listener yet, so the first-launch auto-fire is silently dropped. The Settings → Tutorial path works fine (HomeScreen already alive). Fix: delay fire until after navigation, or check listener count. Not blocking — Settings Tutorial path is functional.

---

**2026-06-02 - Claude**
- **Coach marks tutorial shipped**: 5-step `tutorial_coach_mark` overlay on HomeScreen — header (welcome), FAB (+), medicine tab, water tab, habits tab. GlobalKeys on `_Header`, `ShellScaffold.fabKey/medicineTabKey/waterTabKey/habitsTabKey`. Triggered via `TutorialTrigger.fire()` — auto-fires after first-launch onboarding finish; Settings → Tutorial → `fire()` + `go('/')`. All copy localized ID+EN.

---

**2026-06-02 - Claude**
- **Onboarding flow shipped**: 3-screen PageView (`/onboarding`) — Problem (`med_pill_mascot`), Solution (`star_mascot`), Permissions (`flame_mascot`). Shown only on first launch via `go_router` redirect on `/` when `app_settings['onboarding_done'] != 'true'`. Screen 3 CTA requests notification + exact alarm permissions then sets the flag and routes to `/`. Skip sets the flag immediately; existing `_maybeShowPermissionWizard` in home stays as fallback. Dot indicator expands active dot to 24px pill. All strings localized ID + EN.

---

**2026-06-02 - Claude**
- **Data backup shipped**: `BackupService.exportJson()` serializes all Hive boxes (medicines, logs, habits, groups, water, treatment profiles, medals, user profile) to a dated JSON file and shares it via the Android share sheet. Added `share_plus` + `path_provider` deps. Settings → DATA → Ekspor backup triggers it with a loading spinner.

---

**2026-06-02 - Claude**
- **Home header regression fixed**: `_Header.build()` column was missing `mainAxisSize: MainAxisSize.min`. `Column` defaulted to `MainAxisSize.max`, expanding the `DecoratedBox(color: _bgTop)` to full screen height and painting a solid overlay over the entire dashboard. Fixed by adding `mainAxisSize: MainAxisSize.min` to the Column.
- **Status bar transparent gap fixed**: removed `SafeArea` from the `_Header` overlay, passed `topInset` into `_Header` and folded it into the top padding so the solid `_bgTop` background extends from y=0 through the status bar area.
- **Stack streak shipped**: `🔥 N` now appears on `HabitGroup` headers in both the Habits screen (`_EditGroupBlock`) and the Home dashboard stacked-habit rows. Streak = minimum across all habits in the stack (weakest link). Hidden when 0.

---

**2026-06-02 - Codex**
- **Habit reminders hardened to survive reboot like Water**: native habit alarms now persist their scheduled entries and `BootReceiver` re-arms them on boot, matching the existing Water reminder resilience pattern instead of dropping all Habit reminders after the phone has been powered off.
- **Sound settings shipped in categorized form**: Settings now exposes separate reminder sound choices for notification-style reminders (Water + Habits) and medicine alarm/ringtone behavior, each with `Rutin app sound` or `phone default` options. True custom file upload/import remains deferred.
- **Routine stack streak shipped (owner re-requested)**: `🔥 N` on `HabitGroup` headers in `_EditGroupBlock` (Habits screen) and stacked-habit rows on Home dashboard. Streak = min across all habits in the stack. Hidden when 0. Overrides the earlier "not accepted" note — it is now live.
- **Verified:** `gradlew app:compileDebugKotlin --no-daemon` passed, and focused `dart analyze` on the touched Home/Habits/Settings files returned info-level notices only.

---

**2026-06-02 - Codex**
- **Habit surfaces and home header fully synced**: the habit monthly calendar now uses full-cell status coloring, habit cards are in the compact merged-streak layout, and the Home top header now has the intended solid background instead of floating transparently over the hero.
- **Docs synced again**: `TODO.md` now marks Habit calendar visual, Compact habit cards, and Navbar solid background as shipped.
- **Verified:** `dart analyze` passed for `home_screen.dart`, `habit_card.dart`, and `habit_history_screen.dart`.

---

**2026-06-02 - Codex**
- **History screen corrected to the approved pattern**: the combined History page now defaults to the current day, uses a medicine-style month calendar instead of the old recent-day strip/date-picker-only experiment, and shows a read-only newest-first combined feed for the selected day across medicine, habits, and water.
- **Docs synced to current state**: `TODO.md` now marks the shipped History and Treatment Program surfaces as complete instead of leaving them as in-progress.
- **Verified:** `dart analyze lib/features/history/presentation/history_screen.dart` passed after the final History rewrite.

---

**2026-06-02 - Codex**
- **Profile identity shipped**: local `UserProfile` persistence is now wired through Hive (typeId 12 + `user_profile` box), and Profile now supports editable name, age, and avatar selection from the 10 dropped character assets.
- **Profile header upgraded**: the top section now shows avatar, identity, and stat chips for best streak, medals earned, and total habit completions without changing the existing History / Sleep Mode / Treatment / Settings menu order.
- **EN sweep finished for deep secondary surfaces**: remaining low-frequency wake-up game copy (`Connect the Colors`, rhythm judgments, completion text) and treatment-program date presentation were aligned with the selected locale.
- **Verified:** `dart analyze` passed for `main.dart`, `profile_screen.dart`, `user_profile_model.dart`, `treatment_onboarding_screen.dart`, `treatment_detail_screen.dart`, and `wakeup_game_screen.dart`.

---

**2026-06-02 - Codex**
- **Medicine flow simplified after repeated archive failures**: the Archive feature was removed from the live Obat flow. The archive header entry, archive route, and archive screen were deleted, and medicine cards now support delete-only swipe from right to left.
- **Splash red-screen fix shipped**: `main.dart` now launches `HabitApp()` directly and no longer renders the deleted Flutter splash widget layer.
- **Obat red-screen after archive removal fixed**: medicine cards now tolerate medicines whose `scheduleTimes` are empty instead of assuming `doses.first` always exists.
- **Missed-dose finalization policy shipped**: any past-day medicine dose with no existing log is now backfilled into `medicine_logs` as `missed` when the app starts and when medicine/history screens open. Today remains live: overdue untaken doses can still appear missed in UI immediately, but only completed past days are finalized into stored logs.
- **Full-screen medicine alarm status accepted for now**: on the target phone, `ReminderActivity` takes over reliably when Rutin is already foregrounded. When another app is foregrounded, the phone still falls back to notification + alarm sound. The owner is satisfied with this current behavior, so it is no longer treated as an active blocker.
- **Verified:** focused `dart analyze` passed for `main.dart`, `app.dart`, `medicine_list_screen.dart`, `medicine_repository.dart`, and `settings_screen.dart`; native Kotlin compile passed for the reminder/settings channel changes.

---

**2026-05-31 - Codex**
- **History navigation and UX corrected**: the overall History feed now lives in the hamburger/Profile menu rather than Settings, and the old sideways reversed day strip was removed.
- **Habits history corrected to helicopter view**: per-habit calendar entry points were removed from habit cards. Habits now exposes one top-bar calendar action, matching Medicine, and `HabitHistoryScreen` was repurposed into an overall habits monthly overview with selected-day breakdown.
- **Verified:** focused `dart analyze` on `app.dart`, habits history/card/screen, and `history_screen.dart` passed with info-level lints only.

---

**2026-05-31 - Codex**
- **Wake-up Game 5 rewritten to Flow Free-style**: the old numbered-dot activity is now a 6×6 `Connect the Colors` puzzle with four seeded color pairs, orthogonal drag paths, path overwrite on crossing, and a win only when all pairs connect and the full board is filled.
- **Verified:** `dart analyze lib/features/sleep/presentation/wakeup_game_screen.dart` passed after the rewrite. Device/manual puzzle playthrough is now tracked in `MANUAL_TEST_CHECKLIST.md`.

---

**2026-05-31 - Codex**
- **Four pending product specs shipped**: Connect the Dots wake-up game, medicine streak badges, habit history calendar, and the Profile-accessible Settings screen.
- **Connect the Dots** joins the daily wake-up rotation with seeded 1→8 drag progression, haptics, persistent connected lines, and no fail state.
- **Computed adherence surfaces**: medicine cards now show consecutive fully-taken day streaks, while habit cards expose a read-only monthly calendar with full, partial, and missed states from existing logs.
- **Settings screen**: Mode Tidur link, live accessibility status, persisted language preference, and About/version details. Locale wiring remains intentionally deferred.
- **Verified:** targeted and full `dart analyze` report no errors; only existing info-level notices remain.

---

**2026-06-02 - Claude**
- **Three bug-fix specs written** (see Bug Fix sections at bottom of file): splash red-screen (remove `_SplashPage` from `main.dart`), medicine archive not persisting (explicit `put` + move write into `confirmDismiss`), medicine alarm not forced when phone in use (`singleTask` → `singleTop` + `onNewIntent` + legacy window flags).

---

**2026-06-02 - Claude**
- **Connect the Dots: procedural generation** — replaced 5 hardcoded puzzles with Warnsdorff's Hamiltonian path algorithm. Finds a path covering all 36 cells, splits at 3 random cut points into 4 segments, each segment's endpoints become a color pair. Seed is still date-based (same puzzle per day, different every day, no cycle). Fallback to boustrophedon snake if Warnsdorff fails (rare on 6×6).
- **Connect the Dots: touch offset bug fixed** — `GestureDetector` was wrapping the full `LayoutBuilder` area, but the board `SizedBox` was `Center`-ed inside it. `localPosition` was measured from the outer container, not the board, causing touch to be offset by `(maxHeight − boardSize) / 2`. Fixed by moving `GestureDetector` inside `Center`.

---

**2026-06-02 - Claude**
- **Sleep mode cold-start gate drop fixed**: `WakeUpTriggerReceiver` launches `MainActivity` with `route="/morning-gate"` extra. On cold start (app process dead), Android calls `onCreate`/`configureFlutterEngine` — not `onNewIntent` — so the route extra was silently dropped and the gate never appeared. Fix: Dart's `_LaunchGameListenerState.initState` now calls `checkPendingGate` on the native channel immediately after registering the `launchGame` handler; native reads `intent.getStringExtra("route")` (always available on the Activity) and returns true if the gate is pending, then clears the extra.
- **`KEY_SLEEP_ACTIVE` no longer cleared on service destroy**: `SleepModeService.onDestroy` was setting `KEY_SLEEP_ACTIVE = false`, which meant if Android killed the service overnight (battery optimization), the gate would silently fail even if sleep had been detected. The flag now persists until properly cleared by `WakeUpTriggerReceiver` (on gate fire) or `SleepScheduleReceiver.finishNight` (end of window).
- **Root cause confirmed by**: test button (warm-start path) worked → overnight trigger (cold-start path) didn't.

---

**2026-05-31 - Codex**
- **Sleep notification lifecycle corrected**: enabling Mode Tidur outside the nightly window now arms a silent native `SleepScheduleReceiver` bedtime alarm instead of running `SleepModeService` all day.
- **Night-only foreground service**: at bedtime, AlarmManager starts `SleepModeService`; only then does Android show the required `Mode tidur aktif` notification and `Saya masih terjaga` action. After the wake window or normal gate dismissal, the service stops and tomorrow's bedtime alarm is scheduled.
- **Reboot and update migration covered**: `BootReceiver` re-arms the bedtime alarm, and MainActivity reconciles existing enabled settings on the next app launch.
- **Verified on Infinix X6873 at 16:32**: Mode Tidur remains enabled, `SleepModeService` is absent, and a silent `SleepScheduleReceiver` alarm is scheduled for `21:00`. Kotlin compilation, APK assembly, and data-preserving install passed. The actual 21:00 transition still needs manual confirmation.

---

**2026-05-31 - Codex**
- **Infinix X6873 sleep-mode retest passed on device**: enabling Mode Tidur no longer force-closes Rutin, no body-sensor prompt appears, and pressing Home or switching windows during Morning Gate returns to one existing gate.
- **Water reboot cadence also confirmed**: reminder timing continues from the persisted timestamp after restart.

---

**2026-05-31 - Codex**
- **Water reboot cadence verified on device**: after restart, native `water_settings.interval_ms` remains `5400000` and the next `WaterAlarmReceiver` alarm continues from the persisted timestamp instead of resetting.
- **Infinix sleep-mode startup fix implemented**: `SleepModeService` now registers dynamic receivers with `Context.RECEIVER_NOT_EXPORTED` on Android 13+, preventing the newer-Android receiver registration crash when Mode Tidur starts.
- **Duplicate Morning Gate fix implemented**: `RutinAccessibilityService` now brings the existing MainActivity task forward without sending another `/morning-gate` route extra, so Flutter does not blindly push duplicate gate screens.
- **Verified:** Kotlin compilation and debug APK assembly passed; patched APK installed successfully on Infinix X6873 with data preserved.

---

**2026-05-31 - Codex**
- **Sleep-mode cross-device blockers recorded; stop iterating for now.**
- **Infinix X6873 crash:** enabling `Mode Tidur` force-closes Rutin with a stopped-working prompt. The `specialUse` manifest correction is implemented but has not resolved the on-device startup path yet.
- **Duplicate gate windows:** while Morning Gate is active, pressing Home or switching windows can spawn multiple gate instances instead of bringing one existing gate to the front.
- **Next debugging session:** capture `adb logcat` during the Mode Tidur toggle crash, then inspect MainActivity route delivery and accessibility re-launch deduplication before changing behavior.

---

**2026-05-31 - Codex**
- **Water reboot repair audited**: `main.dart` now re-arms an active Hive water goal on every cold start, which writes the computed interval back into native `water_settings` before future boot restores. Native `BootReceiver` already reads that stored `interval_ms`. Physical reboot verification is still required.
- **Cross-device sleep-mode fix shipped**: `SleepModeService` was incorrectly declared as foreground type `health`, causing Android health/body-sensor prerequisites on the Infinix X6873. It now uses `specialUse` with an explicit morning-gate subtype; no body sensor access is used or needed.
- **Sleep settings hardened**: accessibility status refreshes after returning from Android settings, and service startup failures now reset the toggle with visible feedback instead of failing silently.
- **Verified:** Infinix X6873 inspection confirmed the installed old build still declares `FOREGROUND_SERVICE_HEALTH`; source now declares `FOREGROUND_SERVICE_SPECIAL_USE`. `gradlew app:compileDebugKotlin --no-daemon` and focused Dart analysis passed.

---

**2026-05-31 - Codex**
- **Habit multi-completion shipped**: daily completion is now target-aware, where target = reminder count with a minimum of one.
- **Per-reminder dots added**: Kebiasaan cards and Home rows show tappable rating-style dots for multi-target habits; the Morning Gate shows the same dots read-only.
- **Undo and streak rules implemented**: tapping the top filled dot removes one completion; partial past days preserve streak without increasing it; fully complete days increase streak; zero-completion past days break it.
- **Summary behavior preserved**: Home and Kebiasaan completion summaries count only fully complete habits through the unchanged `isCompletedToday()` signature.
- **Verified:** focused four-file analysis passed with no issues; full `dart analyze` reports only existing info lints in `app.dart` and the existing `onReorder` deprecation in `habits_screen.dart`.

---

**2026-05-31 - Claude + Codex**
- **Sleep gate full flow shipped**: SleepModeService, WakeUpTriggerReceiver, MorningGateScreen, WakeupGameScreen (Sequence + Piano Tiles), RutinAccessibilityService. Test via Profile → Mode Tidur.
- **Morning gate**: dashboard-as-hero layout, compact header, medicine card (pink left border), habits card (purple left border), CountChip, slide-to-unlock (85% threshold, spring-back), emergency Lewati dialog.
- **Home button intercept fixed**: RutinAccessibilityService re-launches MainActivity with route="/morning-gate" instead of broken `GLOBAL_ACTION_BACK`.
- **Piano Tiles game**: 4 colorful lanes (pink/blue/purple/orange), ticker-driven physics, ringtone.ogg as looped bg music, judgment text (Perfect/Good/Miss), tile pop animation, native haptics via HapticsService.
- **Custom notification sounds**: notif_chime.ogg for water/habit, ringtone.ogg for medicine. Channel IDs bumped to _v2.
- **Boot restore verified**: medicine alarms survive reboot on Realme GT 2 Pro / Android 14. Water reboot restore still unverified on device.
- **Sleep gate on-device**: FBE limitation confirmed — BOOT_COMPLETED fires after first unlock on Android 14, so post-reboot mornings miss the first gate trigger.

---
**2026-05-31 - Codex**
- **Home dashboard cards improved** in `lib/features/home/presentation/home_screen.dart` only.
- **Habit rows** now show emoji, optional reminder time, and streak (`🔥 N`) alongside the completion circle.
- **Medicine section** now uses compact single-line rows with a status dot, next-dose label, dosage under the medicine name when available, and a quick check button for due-now doses instead of tall chip cards.
- **Verified:** `dart analyze lib/features/home/presentation/home_screen.dart` -> no issues.

---
**2026-05-31 - Codex**
- **Water next-reminder label shipped** in `lib/features/water/presentation/water_screen.dart` only.
- **Water ring** now shows the next reminder timing below the percentage while reminders are active and refreshes the label every minute.
- **Docs synced:** Home dashboard and Water next-reminder sections are marked completed; Habit Multiple Reminder Times remains pending.
- **Verified:** `dart analyze lib/features/water/presentation/water_screen.dart` -> no issues.

---
**2026-05-31 - Codex**
- **Habit multiple reminder times shipped**: habits now persist `reminderTimes`, while `reminderMinutes` remains as the legacy-compatible first reminder.
- **Add/edit flow upgraded**: the original `Aktifkan pengingat` switch remains the entry point. Turning it on reveals an initial `08:00` row plus the existing Add Medicine-style multi-time card with purple Habits styling; turning it off clears the reminder schedule. Reminder times are deduplicated and sorted on save.
- **Routine creation shortcut added**: `Tambah Kebiasaan` now has a compact `+ Tambah` action beside `RUTINITAS`; creating a routine stack from the form saves it and selects it immediately.
- **Routine dialog back/cancel crash fixed**: the dialog-owned text controller is disposed after its closing animation instead of immediately after `Navigator.pop`, avoiding a disposed-controller red screen.
- **Alarm lifecycle hardened**: each habit reminder time gets a deterministic alarm ID; edit, delete, medal-retire, and delete-routine-with-habits paths cancel all current alarms plus the legacy single alarm.
- **Implementation note:** alarm IDs use 11 low bits for minute-of-day (`0..1439`), not the draft's 9 bits (`0..511`), to avoid collisions between valid reminder times.
- **Verified:** analyzer completed with only the pre-existing `onReorder` deprecation info in `habits_screen.dart`.

**2026-05-31 - Claude**
- Specs written for 4 pending tasks: Connect the Dots game, Medicine Streak, Habit History calendar, Settings Screen. See sections below.
- TB Treatment Mode redesigned as generic "Treatment Program" — condition name field added to model; onboarding, countdown, adherence score, and PDF report specced below.

**2026-05-31 - Codex**
- **Runtime language switching shipped**: Settings now uses compact `🇮🇩 ID` / `🇬🇧 EN` choices, first launch follows the phone locale (`id`, otherwise English), and the app reacts immediately without restart. Normal-use screens are localized; a final EN sweep remains for deep secondary dialogs and low-frequency game copy.
- **Native reminder localization shipped**: selected language mirrors into Android preferences for medicine, water, habit, and sleep-mode notifications, including the native full-screen medicine activity and active sleep notification refresh.
- **Wake-up game test coverage improved**: Mode Tidur now exposes direct test buttons for Sequence, Rhythm, and Connect the Dots.
- **Verified:** `flutter gen-l10n`, full `dart analyze` with existing info lints only, `gradlew app:compileDebugKotlin --no-daemon`, and `flutter build apk --debug` passed. APK installed and launched on the connected device without startup crash markers; native prefs contain `language=en`. Physical notification-content verification remains in `MANUAL_TEST_CHECKLIST.md`.

---

<!-- Add new log entries above this line, newest first -->

Home dashboard note: this task is already shipped. The delivered state includes emoji + reminder time + streak on habit rows, compact medicine rows, and dosage shown under the medicine name when available.

---

## Completed Task — Home Dashboard Card Improvements

**File:** `lib/features/home/presentation/home_screen.dart` only. No other files.

---

### Change 1 — `_TodayHabitRow`: add emoji, reminder time, and streak

**Current:** check circle + name only. No emoji, no reminder time, no streak. Feels generic.

**New row layout (~52px tall):**
```
GestureDetector(onTap)
  Container(padding: h12/v10, bg: 0xAA0D1423, radius 16, border: _panelLine)
    Row
      Container(32×32, radius 10, color: _habitColor.withValues(0.12))
        Center: Text(habit.emoji, fontSize 17)
      SizedBox(10)
      Expanded
        Column(mainAxisSize.min, crossAxis.start)
          Text(habit.name, 14pt bold white, lineThrough if done)
          if habit.reminderMinutes != null:
            SizedBox(2)
            Row([Icon(Icons.alarm_rounded, 11px, _muted), SizedBox(3), Text(_fmtMinute(habit.reminderMinutes!), 11pt _muted)])
      if streak > 0:
        SizedBox(6)
        Text('🔥 $streak', 11pt bold, color _habitColor)
      SizedBox(10)
      [existing AnimatedContainer check circle — unchanged]
```

`streak` — compute via `_habitRepo.getStreak(habit.id)`. Method already exists on HabitRepository.

---

### Change 2 — `_HomeMedicineCard`: collapse to single compact row

**Current:** full card per medicine (name + Wrap of dose chips + meal timing) = 80–100px per medicine, too tall.

**New:** replace `_HomeMedicineCard` with `_HomeMedicineRow` — one slim ~44px row per medicine:

```
Container(padding: h14/v10, bg 0xAA0D1423, radius 14, border _panelLine)
  Row
    Container(10×10 circle, color: _dotColor(doses, bucketFor))
    SizedBox(10)
    Expanded: Text(medicine.name, 14pt w600 white)
    Text(_nextDoseLabel(doses, bucketFor), 12pt _muted)
    if _hasNowDose(doses, bucketFor):
      SizedBox(8)
      GestureDetector(onTap: onTapDose(_nowDose))
        Container(28×28, radius 8, color _medGradient[0].withValues(0.2))
          Icon(Icons.check_rounded, 16px, _medGradient[0])
```

```dart
Color _dotColor(doses, bucketFor) {
  if (doses.any((d) => bucketFor(d) == _HomeDoseBucket.now)) return _medGradient[0];
  if (doses.any((d) => bucketFor(d) == _HomeDoseBucket.missed)) return _missed;
  if (doses.every((d) => bucketFor(d) == _HomeDoseBucket.taken)) return _success;
  return _muted;
}

String _nextDoseLabel(doses, bucketFor) {
  final now = doses.where((d) => bucketFor(d) == _HomeDoseBucket.now);
  if (now.isNotEmpty) return _fmtMinute(now.first.minute);
  final upcoming = doses.where((d) => bucketFor(d) == _HomeDoseBucket.upcoming);
  if (upcoming.isNotEmpty) return _fmtMinute(upcoming.first.minute);
  if (doses.every((d) => bucketFor(d) == _HomeDoseBucket.taken)) return '✓ Selesai';
  return 'Terlewat';
}
```

Remove `_HomeDoseChip` if no longer used.

**What NOT to do:** do not touch any file outside `home_screen.dart`, do not change data loading logic or `_HomeDoseBucket`.

---

## Completed Task — Water Tab: Next Reminder Time

**File:** `lib/features/water/presentation/water_screen.dart` only.

Add a small label inside the hero ring showing when the next water reminder fires. Updates every minute. Only visible when reminder is active.

---

### Computation (pure Dart, no native call)

Add `Timer? _clockTimer` to state. In `initState`: `_clockTimer = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}))`. Cancel in `dispose`.

```dart
String? _nextReminderLabel() {
  if (!_goal.reminderActive) return null;
  final now = DateTime.now();
  final nowMin = now.hour * 60 + now.minute;

  if (nowMin < _goal.startTimeMinutes) {
    return 'Pengingat mulai ${_pad(_goal.startTimeMinutes ~/ 60)}:${_pad(_goal.startTimeMinutes % 60)}';
  }
  if (nowMin >= _goal.endTimeMinutes) return 'Pengingat selesai hari ini';

  final elapsed = nowMin - _goal.startTimeMinutes;
  final interval = _goal.reminderIntervalMinutes;
  final nextMin = _goal.startTimeMinutes + ((elapsed / interval).ceil() * interval).toInt();

  if (nextMin >= _goal.endTimeMinutes) return 'Pengingat selesai hari ini';

  final diff = nextMin - nowMin;
  if (diff <= 0) return 'Sebentar lagi...';
  if (diff < 60) return 'Pengingat dalam $diff menit';
  final h = diff ~/ 60; final m = diff % 60;
  return m == 0 ? 'Pengingat dalam ${h}j' : 'Pengingat dalam ${h}j ${m}m';
}

String _pad(int n) => n.toString().padLeft(2, '0');
```

### Where to render

Inside the ring's `center:` Column, below the `'$pctInt%'` Text:

```dart
if (_nextReminderLabel() != null) ...[
  const SizedBox(height: 6),
  Text(
    _nextReminderLabel()!,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: 11,
      color: AppTheme.waterColor.withValues(alpha: 0.7),
      fontWeight: FontWeight.w600,
    ),
  ),
],
```

**What NOT to do:** no Kotlin changes, no model changes, no new widgets.

---

## Completed Task — Habit Multiple Reminder Times

**Goal:** habits support multiple daily reminders like medicine does.
**Scope:** 4 files — model, hand-edited adapter, add screen, reminder service.

---

### Step 1 — `lib/features/habits/data/habit_model.dart`

Add new field. Keep `reminderMinutes` — do NOT remove it (backward compat).

```dart
@HiveField(8)
List<int> reminderTimes = []; // minutes since midnight, empty = no reminder
```

---

### Step 2 — `lib/features/habits/data/habit_model.g.dart` (hand-edit)

In `HabitAdapter.read()`:
- Add before returning: `final reminderTimes = (fields[8] as List?)?.cast<int>() ?? <int>[];`
- Set on object: `..reminderTimes = reminderTimes`
- Guard with: `if (numOfFields > 8)` before reading field 8

In `HabitAdapter.write()`:
- Change `writer.writeLength(8)` → `writer.writeLength(9)`
- Add at end: `writer.write(obj.reminderTimes);`

---

### Step 3 — `lib/features/habits/presentation/add_habit_screen.dart`

Replace single reminder toggle + time picker with multi-time list (same pattern as AddMedicineScreen).

**State:**
```dart
List<int> _reminderTimes = [];
```

On load (editing existing habit):
```dart
_reminderTimes = habit.reminderTimes.isNotEmpty
    ? List.of(habit.reminderTimes)
    : (habit.reminderMinutes != null ? [habit.reminderMinutes!] : []);
```

**UI (replace existing PENGINGAT section):**
```
Row
  Text('PENGINGAT', section label)
  Spacer
  if _reminderTimes.isNotEmpty: TextButton('+ Tambah waktu', _addTime)

for each time in _reminderTimes:
  _TimePickerRow(time, onTap: () => _pickTime(i), onRemove: () => _reminderTimes.removeAt(i))

if _reminderTimes.isEmpty:
  OutlinedButton.icon(Icons.alarm_add_rounded, 'Tambah waktu pengingat', _addTime)
```

`_addTime()`: show time picker → add to list → dedup → sort.

On save:
```dart
habit.reminderTimes = _reminderTimes;
habit.reminderMinutes = _reminderTimes.firstOrNull; // legacy compat
```

---

### Step 4 — `lib/features/habits/presentation/habit_reminder_service.dart`

```dart
// Alarm ID: upper 23 bits = habit hash, lower 9 bits = time minutes
static int _alarmId(String habitId, int minutes) =>
    (habitId.hashCode & 0x7FFFFE00) | (minutes & 0x1FF);

static Future<void> scheduleAll(Habit habit) async {
  final times = habit.reminderTimes.isNotEmpty
      ? habit.reminderTimes
      : (habit.reminderMinutes != null ? [habit.reminderMinutes!] : <int>[]);
  for (final m in times) {
    await _channel.invokeMethod('scheduleHabitAlarm', {
      'notifId': _alarmId(habit.id, m),
      'triggerMs': _nextTriggerMs(m),
      'title': '${habit.emoji} ${habit.name}',
    });
  }
}

static Future<void> cancelAll(Habit habit) async {
  final times = habit.reminderTimes.isNotEmpty
      ? habit.reminderTimes
      : (habit.reminderMinutes != null ? [habit.reminderMinutes!] : <int>[]);
  for (final m in times) {
    await _channel.invokeMethod('cancelHabitAlarm', {'notifId': _alarmId(habit.id, m)});
  }
  // Cancel legacy single-alarm ID too
  await _channel.invokeMethod('cancelHabitAlarm',
      {'notifId': habit.id.hashCode & 0x7fffffff});
}
```

Update all callers of old `scheduleReminder`/`cancelReminder` to use `scheduleAll`/`cancelAll`.

**What NOT to do:** do not modify `HabitAlarmReceiver.kt`, do not run build_runner, do not remove `reminderMinutes`.

---

## Completed Task — Habit Multi-Completion (per-reminder check-off)

**Problem:** A habit with multiple reminder times (e.g. workout morning + evening) only needs ONE check to show as fully done all day — the remaining slots get ignored. Completion should be a count, not a binary.

**Decision (locked with owner):**
- A habit's daily **target** = number of reminder times (min 1).
- Each completion is one tap; you can tap to add and tap to undo.
- Reminders keep firing for all slots regardless of completion (no suppression).
- **Streak rule:** day with **0%** done → streak breaks. Day with **>0% but <100%** → streak **survives but does not increase**. Day with **100%** → streak **increases**.
- Home "X / Y selesai" summary counts **only fully-complete habits** (a 1/2 habit is NOT counted).

**No Hive model change needed** — `HabitLog` already uses `_logs.add()` (auto-key), so multiple rows per day are allowed. Completion count = number of HabitLog rows for (habitId, today).

---

### Step 1 — `habit_repository.dart`

Add target-aware completion logic. Replace the binary `isCompletedToday` and `markDone`.

```dart
/// Daily target = number of reminder times (min 1).
int dailyTarget(Habit habit) {
  final times = habit.reminderTimes.isNotEmpty
      ? habit.reminderTimes
      : (habit.reminderMinutes != null ? [habit.reminderMinutes!] : const <int>[]);
  return times.isEmpty ? 1 : times.length;
}

int completionsToday(String habitId) {
  final today = AppDateUtils.todayString();
  return _logs.values.where((l) => l.habitId == habitId && l.date == today).length;
}

/// Fully done = completions >= target. (Signature unchanged — callers unaffected.)
bool isCompletedToday(String habitId) {
  final habit = _habits.get(habitId);
  if (habit == null) return false;
  return completionsToday(habitId) >= dailyTarget(habit);
}

Future<void> addCompletion(String habitId) async {
  await _logs.add(HabitLog()
    ..habitId = habitId
    ..date = AppDateUtils.todayString());
}

Future<void> removeCompletion(String habitId) async {
  final today = AppDateUtils.todayString();
  final entry = _logs.toMap().entries
      .where((e) => e.value.habitId == habitId && e.value.date == today)
      .lastOrNull;
  if (entry != null) await _logs.delete(entry.key);
}

/// Rating-style set: add/remove rows until count == n (clamped 0..target).
Future<void> setCompletionsToday(Habit habit, int n) async {
  final target = dailyTarget(habit);
  n = n.clamp(0, target);
  var current = completionsToday(habit.id);
  while (current < n) { await addCompletion(habit.id); current++; }
  while (current > n) { await removeCompletion(habit.id); current--; }
}
```

Keep `markDone(habitId)` working (some callers use it) — redefine as "add one, capped at target":
```dart
Future<void> markDone(String habitId) async {
  final habit = _habits.get(habitId);
  if (habit == null) return;
  if (completionsToday(habitId) < dailyTarget(habit)) {
    await addCompletion(habitId);
  }
}
```

**Streak rewrite:**
```dart
int getStreak(String habitId) {
  final habit = _habits.get(habitId);
  if (habit == null) return 0;
  final target = dailyTarget(habit);

  final byDate = <String, int>{};
  for (final l in _logs.values.where((l) => l.habitId == habitId)) {
    byDate[l.date] = (byDate[l.date] ?? 0) + 1;
  }

  int streak = 0;
  var day = DateTime.now();

  // Today: full → counts; partial or zero → does NOT break (day in progress).
  final todayCount = byDate[AppDateUtils.toDateString(day)] ?? 0;
  if (todayCount >= target) streak++;
  day = day.subtract(const Duration(days: 1));

  // Past days: full → +1; partial → survive (skip); zero → break.
  var guard = 0;
  while (guard++ < 3660) {
    final count = byDate[AppDateUtils.toDateString(day)] ?? 0;
    if (count >= target) {
      streak++;
    } else if (count > 0) {
      // partial — streak survives, no increment
    } else {
      break; // missed a full past day
    }
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}
```

**Caveat (acceptable for v1):** past days are compared to the *current* target. If the user later changes reminder count, historical fractions shift. Fine for now.

---

### Step 2 — `habit_card.dart` (Kebiasaan list)

- If `dailyTarget(habit) == 1` → keep the existing single check-circle UI and tap behavior unchanged.
- If `dailyTarget(habit) > 1` → render a **row of small dots** (one per target) below the title.
  - Dot ~16px. Filled (index < completionsToday) = habit color + small check icon. Empty = outline `AppTheme.muted`.
  - **Rating-style tap** on dot index `i`:
    - if `i + 1 == completionsToday` → `setCompletionsToday(habit, i)` (tapping the topmost filled dot clears one — undo)
    - else → `setCompletionsToday(habit, i + 1)`
  - Haptics: increasing → `HapticsService.tap()`; reaching full → `HapticsService.success()`; decreasing → `HapticsService.softTap()`.
  - The card's done-styling (tinted bg) applies only when fully complete (`isCompletedToday`).

---

### Step 3 — `home_screen.dart` (`_TodayHabitRow`)

Mirror the same dot row when `target > 1` (tappable, same rating logic). Single-target habits keep the existing check circle. The "X / Y selesai" summary already works unchanged — `isCompletedToday` is now target-aware so only fully-done habits count.

---

### Step 4 — `morning_gate_screen.dart`

In the habits card, show the dots **read-only** (filled/empty per `completionsToday` vs target) — the gate is a read-only dashboard, not tappable.

---

### Verify
- `dart analyze` on all four files — no errors
- Manual: habit with 2 reminders → tap 1 dot → shows 1/2, card not marked fully done, streak survives but doesn't grow. Tap 2nd → full, streak grows next day. Tap a filled dot → undoes.

### What NOT to do
- No Hive model/adapter change (multiple HabitLog rows already work)
- No notification suppression — all reminders keep firing
- Do not change `markDone` callers' signatures; keep single-target UX identical

---

## Completed Task — Connect the Dots (Wake-up Game 5)

**File:** `lib/features/sleep/presentation/wakeup_game_screen.dart` only.

**What it does:** 8 numbered dots on screen. User draws a path connecting them in order (1→2→...→8). All 8 connected = win. No timer. No fail state — user can lift finger and try again from where they left off.

---

### Step 1 — Update game rotation

Change `_todayGameIndex()`:
```dart
// before
return const [0, 2][Random(seed).nextInt(2)];
// after
return const [0, 2, 5][Random(seed).nextInt(3)];
```

Change the game builder in `_WakeupGameScreenState.build()`:
```dart
// before
_gameIndex == 0
    ? _SequenceGame(onComplete: _onGameComplete)
    : _PianoTilesGame(onComplete: _onGameComplete),
// after
switch (_gameIndex) {
  case 0 => _SequenceGame(onComplete: _onGameComplete),
  case 2 => _PianoTilesGame(onComplete: _onGameComplete),
  _ => _ConnectDotsGame(onComplete: _onGameComplete),
},
```

---

### Step 2 — `_ConnectDotsGame` widget

```dart
class _ConnectDotsGame extends StatefulWidget {
  const _ConnectDotsGame({required this.onComplete});
  final VoidCallback onComplete;
  @override
  State<_ConnectDotsGame> createState() => _ConnectDotsGameState();
}
```

**State:**
```dart
List<Offset>? _dots;      // normalized 0..1, computed once on first layout
final List<Offset> _path = []; // current finger trace, cleared on panEnd
int _nextDot = 0;          // count of dots connected so far (never reset)
bool _done = false;
Size _gameSize = Size.zero;
```

**Dot positions (computed from daily seed, normalized 0..1):**
```dart
static List<Offset> _computeDots() {
  final now = DateTime.now();
  final seed = now.year * 10000 + now.month * 100 + now.day;
  final rng = Random(seed);
  // 4-col × 2-row grid with random jitter per cell
  const pX = 0.12, pY = 0.12;
  const cols = 4, rows = 2;
  const cW = (1.0 - 2 * pX) / cols;
  const cH = (1.0 - 2 * pY) / rows;
  final pts = <Offset>[];
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      pts.add(Offset(
        pX + c * cW + cW / 2 + (rng.nextDouble() - 0.5) * cW * 0.55,
        pY + r * cH + cH / 2 + (rng.nextDouble() - 0.5) * cH * 0.5,
      ));
    }
  }
  pts.shuffle(rng);
  return pts;
}
```

**Gesture handlers:**
```dart
void _onPanUpdate(Offset local) {
  if (_done) return;
  setState(() => _path.add(local));
  final dot = _dots![_nextDot];
  final dotPx = Offset(dot.dx * _gameSize.width, dot.dy * _gameSize.height);
  if ((local - dotPx).distance < 30) {
    HapticsService.tap();
    setState(() => _nextDot++);
    if (_nextDot == 8) {
      setState(() => _done = true);
      HapticsService.success();
      Future.delayed(const Duration(milliseconds: 300), widget.onComplete);
    }
  }
}

void _onPanEnd() {
  if (!_done) setState(() => _path.clear()); // clear trace; keep _nextDot
}
```

**`build`:**
```dart
Column(children: [
  Padding(...) // title + progress ("N/8 titik")
  Expanded(
    child: LayoutBuilder(builder: (ctx, constraints) {
      _gameSize = Size(constraints.maxWidth, constraints.maxHeight);
      _dots ??= _computeDots();
      return GestureDetector(
        onPanUpdate: (d) => _onPanUpdate(d.localPosition),
        onPanEnd: (_) => _onPanEnd(),
        child: CustomPaint(
          painter: _DotsPainter(
            dots: _dots!,
            path: List.unmodifiable(_path),
            nextDot: _nextDot,
          ),
          child: const SizedBox.expand(),
        ),
      );
    }),
  ),
])
```

---

### Step 3 — `_DotsPainter`

```dart
class _DotsPainter extends CustomPainter {
  _DotsPainter({required this.dots, required this.path, required this.nextDot});
  final List<Offset> dots;
  final List<Offset> path;
  final int nextDot;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Permanent connected line between dots 0..nextDot-1
    if (nextDot > 1) {
      final p = Paint()
        ..color = const Color(0xFF7C3AED)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final pa = Path()..moveTo(dots[0].dx * size.width, dots[0].dy * size.height);
      for (int i = 1; i < nextDot; i++) {
        pa.lineTo(dots[i].dx * size.width, dots[i].dy * size.height);
      }
      canvas.drawPath(pa, p);
    }

    // 2. In-progress finger trace
    if (path.length >= 2) {
      final p = Paint()
        ..color = const Color(0xFF7C3AED).withValues(alpha: 0.45)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final pa = Path()..moveTo(path.first.dx, path.first.dy);
      for (final pt in path.skip(1)) pa.lineTo(pt.dx, pt.dy);
      canvas.drawPath(pa, p);
    }

    // 3. Dots (connected = filled purple; next = semi-filled; rest = outline)
    for (int i = 0; i < dots.length; i++) {
      final px = dots[i].dx * size.width;
      final py = dots[i].dy * size.height;
      final connected = i < nextDot;
      final isNext = i == nextDot;
      final radius = connected ? 20.0 : isNext ? 18.0 : 16.0;

      canvas.drawCircle(Offset(px, py), radius, Paint()
        ..color = connected
            ? const Color(0xFF7C3AED)
            : isNext
                ? const Color(0xFF7C3AED).withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1));
      canvas.drawCircle(Offset(px, py), radius, Paint()
        ..color = connected
            ? const Color(0xFF7C3AED)
            : isNext
                ? const Color(0xFF7C3AED).withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.3)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke);

      // Number label
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color: connected || isNext ? Colors.white : Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(px - tp.width / 2, py - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) =>
      old.path != path || old.nextDot != nextDot;
}
```

---

### Verify
- `dart analyze lib/features/sleep/presentation/wakeup_game_screen.dart` — no errors
- Profile → Mode Tidur → Test Game → force `forceGameIndex: 5` → dots appear, drawing connects them in order, all 8 → celebration fires
- Daily rotation: index 5 appears ~1/3 of days

### What NOT to do
- No Kotlin changes, no model changes
- Do not add a fail state or timer
- Do not touch existing game classes (`_SequenceGame`, `_PianoTilesGame`)

---

## Completed Task — Medicine Streak Counter

**Files:** `lib/features/medicine/data/medicine_repository.dart`, `lib/features/medicine/presentation/medicine_list_screen.dart`

---

### Step 1 — `medicine_repository.dart`

Add `getMedicineStreak(String medicineId)`. Reuses the existing `isTaken()` method — no new log scanning logic.

```dart
int getMedicineStreak(String medicineId) {
  final medicine = _medicines.get(medicineId);
  if (medicine == null || medicine.scheduleTimes.isEmpty) return 0;

  int streak = 0;
  final today = DateTime.now();
  final nowMin = today.hour * 60 + today.minute;

  for (var guard = 0; guard < 3660; guard++) {
    final day = today.subtract(Duration(days: guard));
    final isToday = guard == 0;
    bool allTaken = true;
    bool anyDue = false;

    for (final minute in medicine.scheduleTimes) {
      if (isToday && minute > nowMin) continue; // future dose
      anyDue = true;
      final scheduled = DateTime(
          day.year, day.month, day.day, minute ~/ 60, minute % 60);
      if (!isTaken(medicineId, scheduled)) {
        allTaken = false;
        break;
      }
    }

    if (!anyDue) continue; // today before any dose — skip, don't break
    if (!allTaken) break;
    streak++;
  }
  return streak;
}
```

---

### Step 2 — `medicine_list_screen.dart`

**Add `streak` parameter to `_MedicineCard`:**
```dart
class _MedicineCard extends StatelessWidget {
  const _MedicineCard({
    required this.medicine,
    required this.doses,
    required this.bucketFor,
    required this.onToggle,
    required this.debugTextFor,
    required this.streak,   // ← add
  });
  // ...
  final int streak;
```

**In `_MedicineCard.build()`, add streak badge after the meal timing badge:**
```dart
Row(
  children: [
    Expanded(child: Text(medicine.name, ...)),
    if (streak > 0)
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text(
          '🔥 $streak',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFF6D00), // AppTheme.streakColor
          ),
        ),
      ),
    _Badge(icon: Icons.restaurant_rounded, label: MedicineMealTiming.label(medicine.mealTimingKey)),
  ],
),
```

**Pass it at the call site in `_MedicineListScreenState.build()`:**
```dart
_MedicineCard(
  medicine: medicine,
  doses: dosesByMedicine[medicine.id] ?? [],
  bucketFor: (d) => _bucketFor(repo, d),
  onToggle: (dose, taken) => _toggle(repo, dose, taken),
  debugTextFor: _debugTextFor,
  streak: repo.getMedicineStreak(medicine.id),  // ← add
),
```

---

### Verify
- `dart analyze` on both files — no errors
- Add a medicine, mark doses as taken for 2+ consecutive days → streak shows `🔥 2`
- Miss a day → streak resets to 0 or shows correct value

### What NOT to do
- No Hive model change — computed from existing logs
- Do not call this from an async context; it's sync (Hive boxes are open)

---

## Completed Task — Habit History Calendar

**New file:** `lib/features/habits/presentation/habit_history_screen.dart`
**Modified:** `lib/features/habits/presentation/habit_card.dart`, `lib/app.dart`

Pattern: adapt `medicine_history_screen.dart` — same calendar grid, no "selected day detail" card.

---

### Step 1 — `habit_history_screen.dart` (new file)

Same structure as `MedicineHistoryScreen` but simpler (no detail card, no dose breakdown).

**Colors:**
```dart
const _navy = Color(0xFF0B0E1A);
const _surface = Color(0xFF161D2E);
const _surfaceLine = Color(0xFF222C42);
const _grey = Color(0xFF9AA3B2);
const _full = Color(0xFF7C3AED);   // habitsColor
const _partial = Color(0xFFF4A92B); // amber
const _muted = Color(0xFF9AA3B2);
```

**State:** `DateTime _month` (current displayed month), initialized to `DateTime(now.year, now.month)`.

**Data source:** `ValueListenableBuilder<Box<HabitLog>>` on `'habit_logs'` box.

**Helper functions:**
```dart
int _completionsForDay(String habitId, String dateStr) =>
    Hive.box<HabitLog>('habit_logs')
        .values
        .where((l) => l.habitId == habitId && l.date == dateStr)
        .length;

int _targetForHabit(Habit habit) =>
    habit.reminderTimes.isNotEmpty ? habit.reminderTimes.length : 1;

bool _isScheduledDay(Habit habit, DateTime day) {
  if (habit.scheduleDays.isEmpty) return true; // daily
  return habit.scheduleDays.contains(day.weekday); // 1=Mon..7=Sun
}

String _dayState(Habit habit, DateTime day) {
  if (day.isAfter(DateTime.now())) return 'future';
  if (!_isScheduledDay(habit, day)) return 'off';
  final dateStr = AppDateUtils.toDateString(day);
  final completions = _completionsForDay(habit.id, dateStr);
  final target = _targetForHabit(habit);
  if (completions >= target) return 'full';
  if (completions > 0) return 'partial';
  return 'missed';
}

Color _stateColor(String state) => switch (state) {
  'full' => _full,
  'partial' => _partial,
  'missed' => Colors.white.withValues(alpha: 0.15),
  _ => Colors.transparent,
};
```

**Layout:** `Scaffold` → `AppBar(title: Text('${habit.emoji} ${habit.name}'))` → `ListView`:
- `_MonthHeader` (reuse same widget pattern: `<` month `>`)
- Legend row: `● Selesai`, `● Sebagian`, `● Terlewat`
- Calendar container (same `GridView.builder(crossAxisCount: 7)` as medicine history)
  - Day cell: day number centered, colored dot at bottom (8×8, circle)
  - No tap handler needed (read-only)

Reuse `_daysForMonth()` and `_monthLabel()` helper functions (copy from medicine_history_screen — they're top-level functions so they can't be imported directly).

**Constructor:**
```dart
class HabitHistoryScreen extends StatefulWidget {
  const HabitHistoryScreen({super.key, required this.habitId});
  final String habitId;
```

Load habit from `HabitRepository().getById(habitId)` — sync.

---

### Step 2 — `habit_card.dart`

Add a calendar icon button in the trailing area, before the time pill and more-vert button. Import `go_router` for `context.push`.

```dart
// after the existing SizedBox(width: 12) before the trailing row:
IconButton(
  icon: const Icon(Icons.calendar_month_rounded, size: 18),
  color: AppTheme.muted,
  padding: EdgeInsets.zero,
  constraints: const BoxConstraints(),
  onPressed: () => context.push('/habits/history/${habit.id}'),
),
const SizedBox(width: 4),
```

Place it just before the `_TimePill` block.

---

### Step 3 — `app.dart`

Add route alongside `/habits/add`:
```dart
GoRoute(
  path: '/habits/history/:id',
  parentNavigatorKey: _rootNavigatorKey,
  builder: (_, state) =>
      HabitHistoryScreen(habitId: state.pathParameters['id']!),
),
```

Add import: `import 'features/habits/presentation/habit_history_screen.dart';`

---

### Verify
- `dart analyze` on all three files — no errors
- Tap calendar icon on any habit → history screen opens with correct name/emoji in AppBar
- Past days show correct color: full (purple), partial (amber), missed (dim white), future (nothing)
- Month navigation works

### What NOT to do
- No new Hive models or adapters
- Do not copy the "selected day detail" card from medicine history — not needed
- Do not touch `habit_repository.dart`

---

## Completed Task — Settings Screen

**New file:** `lib/features/settings/presentation/settings_screen.dart`
**Modified:** `lib/app.dart`, `lib/features/profile/presentation/profile_screen.dart`, `lib/main.dart`

---

### Step 1 — `settings_screen.dart` (new file)

```dart
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
```

**State:** `SleepSettings? _sleep`, `bool _accessibilityGranted`, `String _lang` ('id' or 'en')

Load `_sleep` from `Hive.box<SleepSettings>('sleep_settings').getAt(0)`.
Load `_lang` from `Hive.box<String>('app_settings').get('language', defaultValue: 'id')!`.
Check accessibility via `MethodChannel('rutin/sleep').invokeMethod<bool>('isAccessibilityGranted')` in `initState` — same as `SleepSettingsScreen`.
Add `WidgetsBindingObserver` to refresh accessibility on `didChangeAppLifecycleState(resumed)`.

**Screen layout:** `Scaffold` → `CustomScrollView`:
- `SliverAppBar(pinned: true, title: Text('Pengaturan'), backgroundColor: _navy)`
- `SliverList` with sections:

**Section 1 — Mode Tidur:**
```
Card
  ListTile
    leading: Icon(Icons.bedtime_rounded, color: habitsColor)
    title: Text('Mode Tidur')
    subtitle: Text(_sleep?.sleepModeEnabled == true ? 'Aktif' : 'Nonaktif')
    trailing: Icon(Icons.chevron_right_rounded)
    onTap: () => context.push('/sleep-settings')
  Divider (height:1)
  ListTile
    leading: Icon(
      _accessibilityGranted ? Icons.accessibility_new_rounded : Icons.warning_amber_rounded,
      color: _accessibilityGranted ? Color(0xFF4CC56A) : Color(0xFFF4A92B),
    )
    title: Text('Aksesibilitas')
    subtitle: Text(_accessibilityGranted ? 'Diizinkan' : 'Belum diizinkan — diperlukan untuk Mode Tidur')
    trailing: _accessibilityGranted
        ? null
        : TextButton(onPressed: _openAccessibilitySettings, child: Text('Izinkan'))
```

**Section 2 — Bahasa:**
```
Card
  Padding(16)
    Text('Bahasa', section label style)
    SizedBox(height: 12)
    SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'id', label: Text('Indonesia')),
        ButtonSegment(value: 'en', label: Text('English')),
      ],
      selected: {_lang},
      onSelectionChanged: (s) => _setLanguage(s.first),
    )
```

`_setLanguage(String lang)`:
```dart
await Hive.box<String>('app_settings').put('language', lang);
setState(() => _lang = lang);
```
No locale wiring needed for now — just persist the preference. Language toggle UI is done; actual locale switching is Phase 2 since it requires deeper MaterialApp wiring.

**Section 3 — Tentang:**
```
Card
  ListTile(leading: Icon(Icons.info_outline_rounded), title: Text('Versi'), trailing: Text('1.0.0 (build 1)'))
  Divider
  ListTile(leading: Icon(Icons.person_outline_rounded), title: Text('Dibuat oleh'), trailing: Text('Ilham Maulana Sulaeman'))
  Divider
  ListTile(leading: Icon(Icons.favorite_outline_rounded), title: Text('Rutin'), subtitle: Text('Kesehatan harian, gratis selamanya.'))
```

**`_openAccessibilitySettings()`:**
```dart
await MethodChannel('rutin/sleep').invokeMethod('openAccessibilitySettings');
```
(same channel call already used in `SleepSettingsScreen`)

---

### Step 2 — `main.dart`

In `_openHiveBoxes()`, add:
```dart
Hive.openBox<String>('app_settings'),
```

---

### Step 3 — `app.dart`

Add full-screen route:
```dart
GoRoute(
  path: '/settings',
  parentNavigatorKey: _rootNavigatorKey,
  builder: (_, __) => const SettingsScreen(),
),
```

Add import: `import 'features/settings/presentation/settings_screen.dart';`

---

### Step 4 — `profile_screen.dart`

Add a Settings card below the existing Mode Tidur card:
```dart
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
    child: Card(
      child: ListTile(
        leading: const Icon(Icons.settings_rounded, color: Color(0xFF9AA3B2)),
        title: const Text('Pengaturan',
            style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Bahasa, aksesibilitas, tentang'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push('/settings'),
      ),
    ),
  ),
),
```

---

### Verify
- `dart analyze` on all four files — no errors
- Profile → Pengaturan → Settings screen opens
- Mode Tidur tile navigates to existing `/sleep-settings`
- Accessibility status matches actual grant state
- Language toggle persists across app restarts (check Hive box)
- Tentang section shows correct version

### What NOT to do
- Do not wire `SegmentedButton` to `MaterialApp.locale` — just persist the value, actual locale switching is Phase 2
- Do not duplicate sleep enable/disable toggle — just link to `/sleep-settings`
- No new Hive adapter needed — `Box<String>` needs no adapter registration

---

## Pending Task — Treatment Program (generic TB mode)

**Goal:** Replace the TB-specific treatment feature with a generic "Program Pengobatan" that works for any condition with a start date, duration, and linked medicine — TB, Tifus, Malaria, ARV, Diabetes, etc.

**Files touched:**
- `lib/features/tb/data/tb_model.dart` — add `conditionName` field
- `lib/features/tb/data/tb_model.g.dart` — hand-edit adapter (add field 4)
- New: `lib/features/tb/presentation/treatment_onboarding_screen.dart`
- New: `lib/features/tb/presentation/treatment_detail_screen.dart`
- `lib/features/home/presentation/home_screen.dart` — add countdown card
- `lib/features/settings/presentation/settings_screen.dart` — add entry point
- `lib/app.dart` — add routes

---

### Step 1 — Model update (`tb_model.dart` + `tb_model.g.dart`)

Add one field to `TBTreatmentProfile`. Keep class name unchanged (Hive typeId 8 must not change).

```dart
@HiveField(4)
String conditionName = 'TB'; // backward compat — existing profiles read as 'TB'
```

**Hand-edit adapter (`tb_model.g.dart`):**
- In `read()`: add `final conditionName = (fields[4] as String?) ?? 'TB';` and `..conditionName = conditionName` — guard with `if (numOfFields > 4)`
- In `write()`: change `writeByte(4)` → `writeByte(5)`, add `..writeByte(4)..write(obj.conditionName)`

---

### Step 2 — Onboarding (`treatment_onboarding_screen.dart`)

Single-page scrollable form (no multi-step wizard — keeps it simple).

**Fields:**
1. **Nama kondisi** — `TextField` with suggestions shown as chips below: `TB`, `Tifus`, `Malaria`, `ARV`, `Diabetes`, `Hipertensi`. Tapping a chip fills the field. Default empty.
2. **Tanggal mulai** — date picker tile (same pattern as sleep settings `_TimeTile`). Defaults to today.
3. **Durasi pengobatan** — preset buttons: `1 bulan`, `3 bulan`, `6 bulan`, `9 bulan`, `12 bulan`, `Lainnya`. Tapping "Lainnya" shows a number input (days). Presets map: 30, 90, 180, 270, 365 days.
4. **Obat yang digunakan** — dropdown from `MedicineRepository.getAll()`. Optional — can be skipped (sets `medicineId = ''`).

**Save button:** validates conditionName not empty and durationDays > 0. Creates `TBTreatmentProfile` and saves to `'tb_profiles'` box. Navigates back.

**Route:** `/treatment/onboarding` — full-screen, `parentNavigatorKey: _rootNavigatorKey`.

---

### Step 3 — Detail screen (`treatment_detail_screen.dart`)

Shown when a profile already exists. Reached from Settings.

**Layout:**
```
AppBar: conditionName
Body:
  - Progress card:
      "Hari ke-X" (days since startDate, capped at durationDays)
      Linear progress bar (completedDays / durationDays)
      "X hari tersisa" or "Program selesai 🎉" if past end date
  - Adherence card (if medicineId is set):
      "Kepatuhan: X%" — doses taken / doses scheduled since startDate
      "7 hari terakhir: X/Y dosis"
  - Actions:
      OutlinedButton "Ekspor PDF" → generates and shares PDF
      TextButton "Akhiri program" → sets isActive = false, confirms first
```

**Route:** `/treatment/detail` — full-screen.

---

### Step 4 — Settings entry point (`settings_screen.dart`)

Add a **"Program Pengobatan"** section card above the Tentang section:

```dart
// Load profile
final profile = Hive.box<TBTreatmentProfile>('tb_profiles').values
    .where((p) => p.isActive).firstOrNull;

Card(
  child: ListTile(
    leading: Icon(Icons.medical_information_rounded, color: Color(0xFFE91E63)),
    title: Text('Program Pengobatan'),
    subtitle: Text(profile != null
        ? '${profile.conditionName} · hari ke-${_daysSince(profile.startDate)}'
        : 'Belum ada program aktif'),
    trailing: Icon(Icons.chevron_right_rounded),
    onTap: () => context.push(
      profile != null ? '/treatment/detail' : '/treatment/onboarding',
    ),
  ),
)
```

---

### Step 5 — Home countdown card (`home_screen.dart`)

Add a compact card below the water card when an active profile exists. Only shown when `profile.isActive == true`.

```
Container(padding: h16/v12, bg: 0xAA0D1423, radius 16, border: _panelLine)
  Row
    Column(crossAxis.start)
      Text(profile.conditionName, 12pt _muted)
      Text('Hari ke-$days', 18pt bold white)
    Spacer
    Column(crossAxis.end)
      Text('$daysLeft hari lagi', 12pt _muted)
      SizedBox(height: 6)
      // thin progress bar, width ~80px
      ClipRRect(radius 4)
        LinearProgressIndicator(value: days/total, color: medicineColor)
```

`_daysSince(DateTime start)` → `DateTime.now().difference(start).inDays + 1`, capped at `durationDays`.

---

### Step 6 — PDF report

Generate inside `treatment_detail_screen.dart` using the `pdf` package (already in pubspec).

**Content:**
- Header: app name "Rutin", condition name, patient note "Laporan Kepatuhan Pengobatan"
- Info row: Tanggal Mulai, Durasi, Nama Obat
- Table: Date | Doses Scheduled | Doses Taken | Status (✓ / ✗)
  - One row per day from startDate to today
  - Status: Lengkap / Tidak lengkap / Belum diminum (future)
- Footer: "Diekspor dari Rutin — {date}"

Share via `printing` package's `Printing.sharePdf()` → Android share sheet.

---

### Adherence calculation

```dart
double adherenceScore(TBTreatmentProfile profile, MedicineRepository repo) {
  if (profile.medicineId.isEmpty) return 0;
  final medicine = repo.getById(profile.medicineId);
  if (medicine == null) return 0;

  final start = profile.startDate;
  final today = DateTime.now();
  int scheduled = 0, taken = 0;

  for (var d = start;
      d.isBefore(today) || _sameDay(d, today);
      d = d.add(const Duration(days: 1))) {
    for (final minute in medicine.scheduleTimes) {
      final nowMin = today.hour * 60 + today.minute;
      if (_sameDay(d, today) && minute > nowMin) continue; // future dose
      scheduled++;
      final dt = DateTime(d.year, d.month, d.day, minute ~/ 60, minute % 60);
      if (repo.isTaken(medicine.id, dt)) taken++;
    }
  }
  return scheduled == 0 ? 0 : taken / scheduled;
}
```

---

### Verify
- `dart analyze` on all touched files — no errors
- Settings → Program Pengobatan → onboarding fills in → profile saved → Settings shows "TB · hari ke-1"
- Home shows countdown card
- Ekspor PDF → share sheet opens with a readable PDF
- Akhiri program → card disappears from home

### What NOT to do
- Do not rename `TBTreatmentProfile` class — Hive typeId 8 is registered globally
- Do not add a second active profile — one at a time; onboarding replaces the existing one after confirmation
- Do not create a new Hive box — use existing `'tb_profiles'`

---

## Completed Task — Flow Free Connect the Dots (rewrite Game 5)

**File:** `lib/features/sleep/presentation/wakeup_game_screen.dart` only.

The current Game 5 is a "connect numbered dots in sequence" game. Replace it entirely with a **Flow Free-style puzzle**: a grid with colored dot pairs, user draws paths connecting matching colors, win when all pairs connected and all cells filled.

---

### Gameplay rules
- 6×6 grid
- 4 colored pairs placed at fixed positions (seeded by today's date, different puzzle each day)
- User starts a path by pressing on any unconnected dot, drags through adjacent cells (horizontal/vertical only — no diagonal), releases on its matching color dot
- Paths snap to grid cells — drawing fills cells one by one as finger passes through
- If a new path crosses an existing path, the crossed path is erased
- Win: all 4 pairs connected AND all 36 cells covered
- No timer, no fail — user can always erase and retry

### Colors (reuse existing `_laneColors`)
```dart
// pink, blue, purple, orange — already defined at top of file
const _flowColors = [
  Color(0xFFE91E63), // pink
  Color(0xFF2196F3), // blue
  Color(0xFF7C3AED), // purple
  Color(0xFFFF6D00), // orange
];
```

---

### Data structures

```dart
// Grid cell owner: -1 = empty, 0..3 = color index
typedef _Grid = List<List<int>>;

class _Pair {
  final int colorIdx;
  final (int, int) a; // (row, col)
  final (int, int) b;
  bool connected = false;
  List<(int, int)> path = []; // cells in this path including endpoints
}
```

**Puzzle generation (seeded):**
```dart
static List<_Pair> _generatePairs(int seed) {
  // 5 hand-authored puzzles, pick one by (seed % 5)
  // Each puzzle defines 4 pairs as (row, col) endpoints on a 6x6 grid
  const puzzles = [
    [ // puzzle 0
      (0, (0,0), (5,0)), // pink: top-left to bottom-left
      (1, (0,5), (5,5)), // blue: top-right to bottom-right
      (2, (0,2), (3,3)), // purple
      (3, (2,1), (4,4)), // orange
    ],
    [ // puzzle 1
      (0, (0,1), (4,3)),
      (1, (0,4), (5,2)),
      (2, (1,0), (3,5)),
      (3, (2,2), (5,4)),
    ],
    [ // puzzle 2
      (0, (0,0), (3,2)),
      (1, (0,5), (4,3)),
      (2, (2,1), (5,4)),
      (3, (1,3), (5,0)),
    ],
    [ // puzzle 3
      (0, (0,2), (5,1)),
      (1, (0,3), (5,4)),
      (2, (1,0), (4,5)),
      (3, (2,4), (4,1)),
    ],
    [ // puzzle 4
      (0, (0,0), (2,4)),
      (1, (0,5), (3,1)),
      (2, (3,5), (5,0)),
      (3, (1,2), (5,3)),
    ],
  ];
  // Build _Pair list from selected puzzle
}
```

> **Important:** These 5 puzzles must each be solvable with all 36 cells covered. Verify manually before shipping. Adjust endpoint positions if needed.

---

### State

```dart
class _ConnectDotsGameState extends State<_ConnectDotsGame> {
  late List<_Pair> _pairs;
  late _Grid _grid; // 6×6, -1=empty, 0..3=color
  int? _activePair;    // index of pair currently being drawn
  List<(int,int)> _activePath = []; // cells drawn so far this stroke
  bool _done = false;

  @override
  void initState() {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    _pairs = _generatePairs(seed);
    _grid = List.generate(6, (_) => List.filled(6, -1));
    // Mark endpoint cells
    for (final p in _pairs) {
      _grid[p.a.$1][p.a.$2] = p.colorIdx;
      _grid[p.b.$1][p.b.$2] = p.colorIdx;
    }
    super.initState();
  }
}
```

---

### Gesture handling

Use `LayoutBuilder` to get cell size: `cellSize = min(constraints.maxWidth, constraints.maxHeight) / 6`.

```dart
(int, int)? _cellAt(Offset local, double cellSize) {
  final col = (local.dx / cellSize).floor();
  final row = (local.dy / cellSize).floor();
  if (row < 0 || row >= 6 || col < 0 || col >= 6) return null;
  return (row, col);
}
```

**onPanStart:**
- Find cell at position
- If cell is an endpoint of a pair → start drawing that pair
  - Clear that pair's existing path from `_grid` first (erase old path)
  - Set `_activePair` = pair index, `_activePath` = [startCell]

**onPanUpdate:**
- Find cell at position
- If cell == last cell in `_activePath`: skip (same cell)
- If cell is adjacent (horizontal/vertical only) to last cell in `_activePath`:
  - If cell belongs to another pair's path: erase that other pair's path first
  - If cell is the matching endpoint of `_activePair`: complete the connection
    - Add to path, mark pair connected, set `_grid` cells, clear `_activePair`
    - Check win condition
  - Else: add to `_activePath`, update `_grid[row][col] = colorIdx`

**onPanEnd:**
- If `_activePair != null` and path not completed: keep partial path in grid (don't erase — user can continue later)
- Clear `_activePair` and `_activePath`

**Win check:** `_pairs.every((p) => p.connected) && _grid.every((row) => row.every((c) => c >= 0))`

---

### Rendering (`CustomPaint`)

```dart
class _FlowPainter extends CustomPainter {
  final List<_Pair> pairs;
  final _Grid grid;
  final List<(int,int)> activePath;
  final int? activePairIdx;
  final double cellSize;
  // ...
}
```

**Paint order:**
1. Grid lines — thin `Colors.white.withValues(alpha: 0.08)` lines between cells
2. Filled cells — for each cell with `grid[r][c] >= 0`, draw a rounded rectangle in `_flowColors[grid[r][c]].withValues(alpha: 0.35)`. Slightly inset (4px padding).
3. Paths — for each pair, draw thick rounded line through its `path` cells. `strokeWidth = cellSize * 0.45`, `strokeCap = StrokeCap.round`, `strokeJoin = StrokeJoin.round`. Full color opacity.
4. Active path — draw `activePath` same as above in the active pair's color.
5. Endpoints — draw filled circle (radius `cellSize * 0.38`) at each pair's `a` and `b`. White border 2px.

---

### Header

Replace current header with:
```
Row
  Text('Connect the Colors', 16pt bold white)
  Spacer
  Text('$connectedCount/4', 13pt white54)
```

---

### Verify
- `dart analyze lib/features/sleep/presentation/wakeup_game_screen.dart` — no errors
- Force game index 5 via Profile → Mode Tidur → Test Dots
- All 5 puzzles playable: dots appear, paths draw along grid, crossing erases old path, win triggers celebration

### What NOT to do
- Do not use `GestureDetector.onTap` — all interaction is pan-based
- Do not remove `_DotsPainter` class — just rename/replace in place
- Do not touch any other game class

---

## Pending Task — Habit Calendar: per-habit visual improvement

**File:** `lib/features/habits/presentation/habit_history_screen.dart` only.

The current calendar cells show a tiny 8px dot at the bottom. Replace with full-cell background coloring — much clearer at a glance.

### Changes to grid cell `itemBuilder`

Replace the current `Stack` with a simple colored `Container`:

```dart
itemBuilder: (context, index) {
  final day = days[index];
  if (day == null) return const SizedBox.shrink();
  final state = _dayState(habit, day);
  final isToday = _sameDay(day, DateTime.now());

  return Container(
    decoration: BoxDecoration(
      color: switch (state) {
        'full'    => _full.withValues(alpha: 0.85),
        'partial' => _partial.withValues(alpha: 0.75),
        'missed'  => Colors.white.withValues(alpha: 0.06),
        _         => Colors.transparent,
      },
      borderRadius: BorderRadius.circular(10),
      border: isToday
          ? Border.all(color: Colors.white54, width: 1.5)
          : state == 'full' || state == 'partial'
              ? null
              : Border.all(color: _surfaceLine, width: 0.5),
    ),
    child: Center(
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: state == 'full'
              ? Colors.white
              : state == 'partial'
                  ? Colors.white
                  : Colors.white38,
          fontSize: 13,
          fontWeight: state == 'full' || state == 'partial'
              ? FontWeight.w700
              : FontWeight.w400,
        ),
      ),
    ),
  );
},
```

Also add `_sameDay` helper at the bottom of the file:
```dart
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
```

Update legend to remove the dot widget and match new style — use small `Container(8×8, radius 4)` in the same colors.

### What NOT to do
- No structural changes — screen stays per-habit, same route, same data logic
- Do not touch `habit_card.dart` or `app.dart`

---

## Pending Task — History Screen (overall activity feed)

**New file:** `lib/features/history/presentation/history_screen.dart`
**Modified:** `lib/features/settings/presentation/settings_screen.dart`, `lib/app.dart`

A single screen showing combined chronological activity across all features: medicine taken, habits completed, water logged.

---

### Route
`/history` — full-screen, `parentNavigatorKey: _rootNavigatorKey`.

### Screen structure

```
Scaffold
  AppBar(title: 'Riwayat' / 'History', action: Today button)
  ListView
    Month header with prev/next arrows
    Legend (medicine / habits / water)
    Month calendar grid
    Selected-day activity card
```

Default selected day is today. Tapping a calendar cell changes the selected day and updates the read-only feed below. The top-right Today button jumps back to the current day and month.

---

### Calendar behavior

- Reuse the same month-grid interaction pattern as `MedicineHistoryScreen`
- Show weekday headers using `localizedWeekdayShortLabels(context)`
- Selected day gets a stronger border/highlight
- Today gets a subtle border highlight even when not selected
- Each day cell shows up to 3 small markers:
  - medicine pink if at least one taken `MedicineLog` exists that day
  - habits purple if at least one `HabitLog` exists that day
  - water blue if a positive `WaterLog` exists that day

---

### Feed items

For the selected day, collect all events across boxes. Sort by time descending. Render them inside the selected-day card below the calendar.

```
SelectedDayCard
  title: formatLongDate(context, selectedDay)
  subtitle: "Recent activity for this day."
  FeedTile rows newest first
```

**Medicine:** `MedicineLog` where `takenAt.date == selectedDay` and log is a taken entry.
- color: `medicineColor` (pink `#EE5A8C`)
- description: `localized('Minum $name', 'Took $name')`
- time: `DateFormat('HH:mm').format(log.takenAt)`

**Habits:** `HabitLog` where `date == dateStr`.
- color: `habitsColor` (purple `#7C3AED`)
- description: `"${habit.emoji} ${habit.name}"`
- time: `"Selesai" / "Completed"` (no real timestamp available)

**Water:** `WaterLog` where `date == dateStr`.
- color: `waterColor` (blue `#3E8BF0`)
- description: `localized(id: 'Minum ${log.mlLogged} ml air', en: 'Drank ${log.mlLogged} ml of water')`
- time: `"dicatat" / "logged"` (aggregate daily log; no real timestamp available)

**Empty state** (no items for selected day):
```dart
Text(
  localized(
    context,
    id: 'Tidak ada aktivitas pada hari ini.',
    en: 'Nothing logged on this day.',
  ),
)
```

---

### Lookup helpers

```dart
// Resolve habit name/emoji from habitId
Habit? _habitFor(String id) => Hive.box<Habit>('habits').get(id);

// Resolve medicine name from medicineId
Medicine? _medicineFor(String id) => Hive.box<Medicine>('medicines').get(id);

// Date equality helper
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
```

---

### Settings entry (profile_screen.dart — already has History card)

The History card is already in `profile_screen.dart` pointing to `/history`. No change needed there.
In `settings_screen.dart`, add the same card above Sleep Mode if not already present.

---

### What NOT to do
- No recent-day strip or sideways selector
- No new Hive boxes — read directly from existing `medicine_logs`, `habit_logs`, `water_logs`, `habits`, `medicines` boxes
- Do not modify existing data models
- Keep it read-only — no actions in the feed
- Do not invent real timestamps for habit/water logs — they don't store one

---


## Pending Task — Compact Habit Cards

**File:** `lib/features/habits/presentation/habit_card.dart` only.

Reduce card height from ~68px to ~48px. Changes are padding and size only — no logic changes.

### In `HabitCard.build()` → `Padding`:
```dart
// before
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
// after
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
```

### Emoji container:
```dart
// before
width: 44, height: 44, borderRadius: 12
// after
width: 36, height: 36, borderRadius: 10
```
Emoji `fontSize`: 22 → 18.

### Streak text: merge into one line with name instead of separate row
```dart
// Replace the Column with two Text children with:
Row(
  children: [
    Expanded(
      child: Text(habit.name, style: Theme.of(context).textTheme.titleMedium),
    ),
    if (streak > 0) ...[
      const SizedBox(width: 6),
      Text(
        '🔥 $streak',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.streakColor),
      ),
    ],
  ],
),
if (target > 1) ...[
  const SizedBox(height: 4),
  _CompletionDots(...),
],
```

Remove the `SizedBox(height: 2)` between name and streak text that existed in the old layout.

### `_TimePill` padding:
```dart
// before
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
// after
padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
```
Font size: 14 → 12.

### What NOT to do
- Do not change `_CompletionDots` logic or size
- Do not change `onTap`, `onMoreTap`, or any other behavior
- Do not touch `habits_screen.dart`

---

## Pending Task — Home Navbar: Solid Background

**File:** `lib/features/home/presentation/home_screen.dart` only.

The top navbar (`_Header`) currently floats transparently over the hero image — icons and text are readable but the bar has no background, making it feel like it blends into the sky. Fix: give the header a solid, non-transparent background surface.

---

### Change — `_Header.build()`

Wrap the existing `Padding` in a `DecoratedBox` with a solid `_bgTop` background:

```dart
@override
Widget build(BuildContext context) {
  return DecoratedBox(
    decoration: const BoxDecoration(color: _bgTop),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: Column(
        children: [
          Row(
            children: [
              _IconButton(icon: Icons.menu_rounded, onTap: onMenu),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              _IconButton(icon: Icons.calendar_today_rounded, onTap: onMenu),
            ],
          ),
          const SizedBox(height: 4),
          Text(date, style: const TextStyle(fontSize: 13, color: _muted)),
        ],
      ),
    ),
  );
}
```

The bottom padding increases from `0` to `10` so the date label doesn't sit flush against the hero image edge.

### What NOT to do
- Do not add a blur effect (`BackdropFilter`) — keep it simple and solid
- Do not change `_HomeHero`, the scroll physics, or layout of any other widget
- Do not touch anything outside `_Header`

---

## Pending Task — Profile Page: User Identity + Avatar

**Files:**
- New: `lib/features/profile/data/user_profile_model.dart` + `user_profile_model.g.dart` (hand-edit)
- Modified: `lib/features/profile/presentation/profile_screen.dart`
- Modified: `lib/main.dart` (open new box)

**Goal:** Let the user set their name, age, and pick an avatar character. Show the avatar + name prominently in the profile header alongside the existing streak and medals. All data is local (Hive).

---

### Step 1 — Data model (`user_profile_model.dart`)

```dart
import 'package:hive/hive.dart';

part 'user_profile_model.g.dart';

@HiveType(typeId: 12)
class UserProfile extends HiveObject {
  @HiveField(0)
  String name = '';

  @HiveField(1)
  int age = 0;       // 0 = not set

  @HiveField(2)
  int avatarId = 0;  // 0–9, maps to avatar asset filenames
}
```

**Hand-edit `user_profile_model.g.dart`** (standard Hive adapter boilerplate, typeId: 12, 3 fields).

**Register in `main.dart`:**
```dart
Hive.registerAdapter(UserProfileAdapter());
// in _openHiveBoxes():
Hive.openBox<UserProfile>('user_profile'),
```

---

### Step 2 — Avatar assets

10 diverse multicultural characters. User generates on **white background** (not checkerboard), cleans via `preview/clean_mascot.py`, converts to WebP at 82 quality.

Asset filenames: `assets/avatar/avatar_0.png` through `assets/avatar/avatar_9.png`.

**Character prompts** (3D chibi/cartoon style, consistent with the app's existing mascot art — rounded shapes, soft lighting, transparent bg on white, bust portrait 512×512):

```
Shared style block for all 10:
"3D cartoon chibi portrait, soft rounded shapes, pastel shading, subtle rim light, 
white background, bust shot centered, friendly expression, high detail, 
consistent style across all characters, no text"

0 — Ayu (Indonesian girl): warm brown skin, hijab in dusty peach, 
    soft dark eyes, gentle smile, simple modest top

1 — Kai (Japanese boy): light skin, neat short black hair with a slight 
    side part, athletic jacket in navy-white, sporty grin

2 — Priya (South Asian girl): medium-brown skin, long straight black 
    hair, small bindi, violet kurta top, warm expression

3 — Marcus (Black/African-American boy): deep brown skin, tight fade 
    haircut with a shape-up, grey hoodie, bright wide smile

4 — Yusuf (Middle Eastern young man): olive skin, short trimmed beard, 
    white thobe collar, calm thoughtful look

5 — Elena (Eastern European girl): pale skin, platinum blonde hair in 
    a loose braid, mint-green sweater, soft cheerful expression

6 — Diego (Latin/Hispanic boy): warm tan skin, messy wavy dark hair, 
    colorful patchwork jacket in orange and teal, energetic grin

7 — Amara (West African girl): deep brown skin, full natural afro, 
    golden hoop earrings, bright yellow ankara-print top

8 — Sora (Korean nonbinary): light skin, lavender-tipped black bob, 
    minimalist white jacket with a small pin badge, subtle smile

9 — Lani (Pacific Islander/Filipino girl): medium brown skin, long 
    wavy dark hair with a flower tucked in, tropical teal top
```

> Store prompts in `preview/AVATAR_PROMPTS.md`. Run `clean_mascot.py` on each generated PNG before shipping.

---

### Step 3 — `profile_screen.dart` changes

**State additions:**
```dart
late Box<UserProfile> _profileBox;
UserProfile? _profile;

// Controllers for the edit sheet
final _nameCtrl = TextEditingController();
final _ageCtrl = TextEditingController();
int _editAvatarId = 0;
```

In `initState`:
```dart
_profileBox = Hive.box<UserProfile>('user_profile');
_profile = _profileBox.getAt(0);
```

**Replace `_buildHeader`** with the new version below. Keep all existing content (streak, medals section) — only the top portion of the header changes.

#### New `_buildHeader` layout:

```
Container(gradient: navy top→bottom, padding: h24/top60/bottom32)
  Column
    // — Avatar row —
    Stack
      GestureDetector(onTap: _openEditSheet)
        Container(80×80, shape: circle,
          decoration: gradient ring (habitColor → medicineColor, width 3px))
          ClipOval
            _profile?.avatarId != null
              ? Image.asset('assets/avatar/avatar_${_profile!.avatarId}.png', fit: cover)
              : Icon(Icons.person_rounded, size: 40, color: white54)
      // Edit badge
      Positioned(bottom:0, right:0)
        Container(22×22, circle, bg: _bgTop, border: white10)
          Icon(Icons.edit_rounded, size: 12, color: white70)

    SizedBox(height: 12)

    // — Name / age —
    if (_profile?.name.isNotEmpty == true)
      Text(_profile!.name, 22pt bold white, letterSpacing: -0.5)
    else
      GestureDetector(onTap: _openEditSheet)
        Text('Tap to set your name', 15pt, white38)

    if (_profile?.age != null && _profile!.age > 0)
      Text('${_profile!.age} years old', 13pt white54)

    SizedBox(height: 24)

    // — Streak (existing, unchanged) —
    [animated flame + streak number + "best streak days" label]

    SizedBox(height: 16)

    // — Win streak chip row —
    _WinStreakRow(bestStreak: _bestActiveStreak)

    SizedBox(height: 24)

    // — Medals title (existing) —
    [medals label + subtitle]
```

#### `_WinStreakRow` widget:

A horizontal row of stat chips. Each chip: rounded container, icon + value + label.

```
Row(mainAxisAlignment: center)
  _StatChip(icon: '🔥', value: '$_bestActiveStreak', label: localized 'Best streak')
  SizedBox(16)
  _StatChip(icon: '🏅', value: '${_list.length}', label: localized 'Medals')
  SizedBox(16)
  _StatChip(icon: '📅', value: '$_habitsDoneTotal', label: localized 'Habits done')
```

`_habitsDoneTotal`: count of all `HabitLog` entries = `Hive.box<HabitLog>('habit_logs').length`.

```dart
class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.value, required this.label});
  final String icon, value, label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xCC111A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF26324A)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9AA3B2))),
        ],
      ),
    );
  }
}
```

---

### Step 4 — Edit bottom sheet (`_openEditSheet`)

```dart
void _openEditSheet() {
  final profile = _profile ?? UserProfile();
  _nameCtrl.text = profile.name;
  _ageCtrl.text = profile.age > 0 ? '${profile.age}' : '';
  setState(() => _editAvatarId = profile.avatarId);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF111A2A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24, right: 24, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar grid (2 rows × 5 cols)
            const Text('Choose your character',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, mainAxisSpacing: 8, crossAxisSpacing: 8,
              ),
              itemCount: 10,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => setSheet(() => _editAvatarId = i),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _editAvatarId == i
                          ? const Color(0xFFF4A92B)
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/avatar/avatar_$i.png', fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Name field
            TextField(
              controller: _nameCtrl,
              maxLength: 30,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: localized(context, id: 'Nama', en: 'Name'),
                labelStyle: const TextStyle(color: Color(0xFF9AA3B2)),
                counterStyle: const TextStyle(color: Color(0xFF9AA3B2)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF26324A)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFF4A92B)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Age field
            TextField(
              controller: _ageCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: localized(context, id: 'Usia', en: 'Age'),
                labelStyle: const TextStyle(color: Color(0xFF9AA3B2)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF26324A)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFF4A92B)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF4A92B),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final p = _profile ?? UserProfile();
                  p.name = _nameCtrl.text.trim();
                  p.age = int.tryParse(_ageCtrl.text) ?? 0;
                  p.avatarId = _editAvatarId;
                  if (_profile == null) {
                    _profileBox.add(p);
                  } else {
                    p.save();
                  }
                  setState(() => _profile = p);
                  Navigator.of(ctx).pop();
                },
                child: Text(localized(context, id: 'Simpan', en: 'Save')),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}
```

---

### Verify
- `dart analyze` on both files — no errors
- Profile header shows avatar circle, name, age, stat chips
- Tapping avatar / pencil badge opens the sheet
- Avatar grid shows all 10 characters; selected one has gold ring
- Save persists across app restarts (Hive box)
- Medals section and menu links (History, Sleep Mode, Treatment, Settings) are unchanged

### What NOT to do
- Do not add a separate "profile edit" screen — use the bottom sheet
- Do not remove or reorder existing menu links
- Do not change medal card logic
- Do not run build_runner — hand-edit the adapter

---

## Bug Fix — Splash Red Screen

**Status:** Done

### What's wrong
`lib/main.dart` has a Flutter-level `_SplashPage` widget that calls
`Image.asset('assets/splash-screen.png')`. That file was deleted and removed
from `pubspec.yaml`. Any Flutter error during init also surfaces as a red screen
through this widget. The widget is redundant: `flutter_native_splash` already
renders the native splash before Flutter paints a single frame — a Flutter-level
splash widget adds nothing except a 2-second delay and a crash vector.

### Fix
**File: `lib/main.dart`**

1. Delete the entire `_SplashPage` class and `_SplashPageState` class.
2. Delete the entire `_AppRoot` class and `_AppRootState` class.
3. Change the `runApp` call:

```dart
// before
runApp(const ProviderScope(child: _AppRoot()));

// after
runApp(const ProviderScope(child: HabitApp()));
```

No other changes. The 2-second delay disappears; the native splash handles the
visual gap. `HabitApp` is already defined in `lib/app.dart`.

### Verify
- `dart analyze lib/main.dart` — no errors
- App cold-starts directly to the home screen with no red screen

---

## Bug Fix — Medicine Archive Not Persisting

**Status:** Superseded

### Product decision
This spec is no longer the active direction. After repeated failed attempts and device retests, the archive flow was removed from the live medicine product. Obat now uses delete-only behavior instead of archive/unarchive.

### What's wrong

Two problems combine to cause this.

**Problem A — `HiveObject.save()` unreliable with string keys.**
`MedicineRepository.archive()` in
`lib/features/medicine/data/medicine_repository.dart` does:
```dart
medicine.isActive = false;
await medicine.save();
```
`HiveObject.save()` calls `box.put(hiveObject.key, this)`. With Hive 2.x using
custom String keys (as this project does), the internal `_key` tracking can
disagree with the actual box key, causing the write to silently no-op or write
to the wrong slot. The safe approach: bypass `HiveObject.save()` and call
`_medicines.put(id, medicine)` directly — this is always correct regardless of
how the internal key tracking behaves.

**Problem B — archive runs fire-and-forget after Dismissible already closes.**
`_SwipeMedicine.onDismissed` (in
`lib/features/medicine/presentation/medicine_list_screen.dart`) calls
`onArchive()` without `await`. The callback resolves to `_executeArchive`, an
async method. Dismissible finishes animating the card away before
`repo.archive()` has run. If the user navigates to the archive screen in that
window, the medicine is still `isActive == true` in Hive and does not appear.

The correct pattern: perform the archive/delete operation fully inside
`confirmDismiss` (awaited), so the card only animates away after the data write
completes. `onDismissed` then only handles UI refresh.

### Fix

**File: `lib/features/medicine/data/medicine_repository.dart`**

Replace `medicine.save()` with explicit `put` in both `archive` and `unarchive`:

```dart
Future<void> archive(String id) async {
  final medicine = _medicines.get(id);
  if (medicine == null) return;
  medicine.isActive = false;
  await _medicines.put(id, medicine);
}

Future<void> unarchive(String id) async {
  final medicine = _medicines.get(id);
  if (medicine == null) return;
  medicine.isActive = true;
  await _medicines.put(id, medicine);
}
```

**File: `lib/features/medicine/presentation/medicine_list_screen.dart`**

1. Add two new async callback fields to `_SwipeMedicine`:
   - `Future<void> Function() onArchiveConfirmed`
   - `Future<void> Function() onDeleteConfirmed`

   Remove the old `Future<void> Function() onArchive` and
   `Future<void> Function() onDelete` fields.

2. Rewrite `confirmDismiss` to do the work (dialog + actual operation) fully
   awaited before returning `true`:

```dart
confirmDismiss: (direction) async {
  if (direction == DismissDirection.startToEnd) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        // ... existing archive dialog unchanged ...
      ),
    ) ?? false;
    if (!confirmed) return false;
    await onArchiveConfirmed();
    return true;
  } else {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        // ... existing delete dialog unchanged ...
      ),
    ) ?? false;
    if (!confirmed) return false;
    await onDeleteConfirmed();
    return true;
  }
},
```

3. `onDismissed` becomes UI-only — no data operations:

```dart
onDismissed: (direction) {
  // data is already saved; just refresh UI
  _refreshReminderDebug(repo, force: true);
  if (mounted) setState(() {});
},
```

4. At the call site in `_MedicineListScreenState.build`, update the
   `_SwipeMedicine` instantiation:

```dart
_SwipeMedicine(
  key: ValueKey('med_${medicine.id}'),
  medicine: medicine,
  onArchiveConfirmed: () => _executeArchive(repo, medicine),
  onDeleteConfirmed: () => _executeDelete(repo, medicine),
  child: _MedicineCard(...),
)
```

5. Strip `setState(() {})` and `_refreshReminderDebug` calls from the END of
   `_executeArchive` and `_executeDelete` — those now live in `onDismissed`.
   Keep alarm cancellation and analytics inside `_executeArchive`/`_executeDelete`.

### Verify
- `dart analyze` on both files — no errors
- Swipe-archive a medicine → immediately open the archive tab → medicine is
  listed without waiting
- Restart app → medicine stays in archive, not in active list
- Swipe-delete a medicine → medicine is gone from both lists after restart

---

## Bug Fix — Medicine Alarm Not Forced When Phone Is In Use

**Status:** Accepted for now

### What's wrong
`ReminderActivity` is declared with `launchMode="singleTask"` in the manifest.
With `singleTask`, if `ReminderActivity` is anywhere in the back stack from a
prior alarm, a new `startActivity` call fires `onNewIntent` instead of
`onCreate`. Because `onNewIntent` is not overridden, the activity silently reuses
stale intent data and may not come to the foreground — on screen-on scenarios
this means the full-screen takeover is skipped and only a heads-up notification
shows.

`ReminderAlarmReceiver.kt` already calls `context.startActivity(launchIntent)`
which is the correct approach (a direct activity launch from an AlarmManager
exact-alarm receiver is always allowed). The problem is `singleTask` + missing
`onNewIntent`.

Additionally, `ReminderActivity` is missing legacy window flags for API < 27
(`FLAG_DISMISS_KEYGUARD`, `FLAG_SHOW_WHEN_LOCKED`, `FLAG_TURN_SCREEN_ON`). The
`setShowWhenLocked`/`setTurnScreenOn` API calls in `onCreate` only work on
API 27+; older devices silently ignore them without the deprecated window flags.

### Fix

**File: `android/app/src/main/AndroidManifest.xml`**

Change `ReminderActivity`'s `launchMode` from `singleTask` to `singleTop`:

```xml
<activity
    android:name=".ReminderActivity"
    android:exported="false"
    android:excludeFromRecents="true"
    android:launchMode="singleTop"
    android:showWhenLocked="true"
    android:turnScreenOn="true"
    android:theme="@style/LaunchTheme" />
```

`singleTop` still prevents double-stacking when the activity is already at the
top of the stack (calls `onNewIntent` only then), but creates a fresh instance
when it's in the background — which is what we want for alarm interruptions.

**File: `android/app/src/main/kotlin/com/rutin/app/ReminderActivity.kt`**

1. Add `onNewIntent` override immediately after `onCreate`:

```kotlin
override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    setIntent(intent)
    recreate()   // re-run onCreate with the fresh alarm intent
}
```

2. Add legacy window flags for API < 27, inside `onCreate` before `setContentView`,
   right after the existing `window.addFlags(FLAG_KEEP_SCREEN_ON)` line:

```kotlin
if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O_MR1) {
    @Suppress("DEPRECATION")
    window.addFlags(
        android.view.WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
        android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
        android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
    )
}
```

No other changes. `ReminderAlarmReceiver.kt` already calls `startActivity`
correctly; the fix is entirely in `ReminderActivity` and the manifest.

### Verify
- Current accepted device result on the owner's phone:
- If Rutin is already foregrounded, the full-screen reminder takeover works.
- If another app is foregrounded, the phone may fall back to a heads-up notification plus alarm sound.
- The owner has accepted this behavior for now, so further escalation is optional rather than required.

---

## Pending Task — Custom Fonts (Bricolage Grotesque + DM Sans)

**Goal:** Replace system default Roboto with Bricolage Grotesque (display headings) and DM Sans (body/UI). This is the single biggest design quality gap for ADA portfolio presentation.

**Files:** `pubspec.yaml`, `lib/core/theme/app_theme.dart`

---

### Step 1 — `pubspec.yaml`

Add `google_fonts` dependency:

```yaml
dependencies:
  google_fonts: ^6.2.1
```

---

### Step 2 — `lib/core/theme/app_theme.dart`

Import and apply fonts in both `light()` and `dark()` theme builders. The pattern: Bricolage Grotesque for display/headline styles (large, impactful text), DM Sans for title/body/label styles (UI chrome, cards, labels).

```dart
import 'package:google_fonts/google_fonts.dart';
```

Replace the static `_textTheme` constant with a function that builds the text theme with fonts applied:

```dart
static TextTheme _buildTextTheme() {
  const base = TextTheme(
    displayLarge:  TextStyle(fontSize: 56, fontWeight: FontWeight.w800, letterSpacing: -2.0),
    displayMedium: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -1.5),
    displaySmall:  TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.0),
    headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
    headlineMedium:TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3),
    titleLarge:    TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.2),
    titleMedium:   TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    bodyLarge:     TextStyle(fontSize: 16),
    bodyMedium:    TextStyle(fontSize: 14),
    bodySmall:     TextStyle(fontSize: 12),
    labelMedium:   TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1),
  );

  // Bricolage Grotesque for display + headline (large, expressive)
  final display = GoogleFonts.bricolageGrotesqueTextTheme(base);

  // DM Sans for title + body + label (UI chrome, readable at small sizes)
  return display.copyWith(
    titleLarge:   GoogleFonts.dmSans(textStyle: base.titleLarge),
    titleMedium:  GoogleFonts.dmSans(textStyle: base.titleMedium),
    bodyLarge:    GoogleFonts.dmSans(textStyle: base.bodyLarge),
    bodyMedium:   GoogleFonts.dmSans(textStyle: base.bodyMedium),
    bodySmall:    GoogleFonts.dmSans(textStyle: base.bodySmall),
    labelMedium:  GoogleFonts.dmSans(textStyle: base.labelMedium),
  );
}
```

In both `light()` and `dark()`, replace `textTheme: _textTheme` with `textTheme: _buildTextTheme()`.

Also apply DM Sans to `AppBarTheme.titleTextStyle` and `NavigationBarTheme.labelTextStyle`:

```dart
// In AppBarTheme:
titleTextStyle: GoogleFonts.dmSans(
  fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: cs.onSurface,
),

// In NavigationBarTheme.labelTextStyle:
labelTextStyle: WidgetStateProperty.resolveWith(
  (s) => GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
  ),
),
```

### Verify
- `flutter pub get` — no errors
- App runs; home screen hero title renders in Bricolage Grotesque, card body text in DM Sans
- `dart analyze lib/core/theme/app_theme.dart` — no errors

### What NOT to do
- Do not bundle font files manually — `google_fonts` fetches and caches at runtime
- Do not change any TextStyle `fontSize` or `fontWeight` values — only change the font family
- Do not touch any screen files — all font changes flow through `AppTheme`

---

## Pending Task — Permission Dialog Rewrite (Step-by-Step Bottom Sheet)

**Goal:** Replace the current `AlertDialog` with 3 disconnected buttons with a guided bottom sheet that walks through each permission one at a time.

**File:** `lib/features/home/presentation/home_screen.dart` only.

---

### Problem with current code (line 816–872)

`showDialog` presents one dialog with three `TextButton`s. Each button grants one permission and then calls `Navigator.pop()` — the dialog disappears after the first tap. The user never sees the remaining two permissions.

---

### New behavior

Show a `showModalBottomSheet` with 3 steps. Each step has:
- Icon + title + one-sentence explanation
- A primary `FilledButton` to grant that permission
- A secondary `TextButton('Lewati / Skip')` to skip to the next step
- Step indicator dots at the top

When all steps are done (granted or skipped), the sheet closes.

---

### Implementation

Replace `_maybeShowPermissionWizard` with:

```dart
Future<void> _maybeShowPermissionWizard(BuildContext context) async {
  if (_permissionDialogShown || !context.mounted) return;

  // Persist the flag so it doesn't repeat on every cold start
  await Hive.box<String>('app_settings').put('permission_wizard_shown', 'true');
  _permissionDialogShown = true;

  final android = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (android == null) return;

  final notifEnabled = await android.areNotificationsEnabled() ?? false;
  final exactEnabled = await android.canScheduleExactNotifications() ?? false;
  if (notifEnabled && exactEnabled) return;
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF131C2B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) => _PermissionWizard(android: android),
  );
}
```

New `_PermissionWizard` widget (private, same file):

```dart
class _PermissionWizard extends StatefulWidget {
  const _PermissionWizard({required this.android});
  final AndroidFlutterLocalNotificationsPlugin android;

  @override
  State<_PermissionWizard> createState() => _PermissionWizardState();
}

class _PermissionWizardState extends State<_PermissionWizard> {
  int _step = 0;

  static const _steps = [
    (
      icon: Icons.notifications_rounded,
      color: Color(0xFF4CC56A),
      titleId: 'Izinkan Notifikasi',
      titleEn: 'Allow Notifications',
      bodyId: 'Diperlukan agar pengingat obat dan air muncul di layar.',
      bodyEn: 'Required so medicine and water reminders appear on screen.',
    ),
    (
      icon: Icons.alarm_rounded,
      color: Color(0xFFF4A92B),
      titleId: 'Izinkan Exact Alarm',
      titleEn: 'Allow Exact Alarm',
      bodyId: 'Agar pengingat muncul tepat waktu — buka Alarm & Pengingat lalu aktifkan Rutin.',
      bodyEn: 'So reminders appear on time — open Alarms & Reminders and enable Rutin.',
    ),
    (
      icon: Icons.fullscreen_rounded,
      color: Color(0xFF3E8BF0),
      titleId: 'Izinkan Layar Penuh',
      titleEn: 'Allow Full Screen',
      bodyId: 'Pengingat obat muncul menyeluruh saat layar terkunci.',
      bodyEn: 'Medicine reminders appear full screen when the device is locked.',
    ),
  ];

  Future<void> _grant() async {
    switch (_step) {
      case 0: await widget.android.requestNotificationsPermission();
      case 1: await widget.android.requestExactAlarmsPermission();
      case 2: await widget.android.requestFullScreenIntentPermission();
    }
    _next();
  }

  void _next() {
    if (_step >= _steps.length - 1) {
      Navigator.pop(context);
    } else {
      setState(() => _step++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _steps[_step];
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Step dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_steps.length, (i) => Container(
              width: i == _step ? 20 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i == _step ? s.color : Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            )),
          ),
          const SizedBox(height: 28),
          Icon(s.icon, color: s.color, size: 48),
          const SizedBox(height: 16),
          Text(
            localized(context, id: s.titleId, en: s.titleEn),
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            localized(context, id: s.bodyId, en: s.bodyEn),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.45),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _grant,
            style: FilledButton.styleFrom(backgroundColor: s.color),
            child: Text(localized(context, id: 'Izinkan', en: 'Allow')),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _next,
            child: Text(
              localized(context, id: 'Lewati', en: 'Skip'),
              style: const TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}
```

Also update the `_permissionDialogShown` static bool to check Hive on init:

```dart
// In _HomeScreenState.initState(), replace the static bool check:
@override
void initState() {
  super.initState();
  // ... existing code ...
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final shown = Hive.box<String>('app_settings').get('permission_wizard_shown') == 'true';
    if (!shown) _maybeShowPermissionWizard(context);
  });
}
```

Remove `_permissionDialogShown` static bool entirely.

### Verify
- `dart analyze lib/features/home/presentation/home_screen.dart` — no errors
- First launch: bottom sheet appears with 3 steps, step indicator advances, sheet closes after step 3
- Second cold start: sheet does not appear (Hive flag persists)
- Granting on step 1 does not dismiss the sheet; continues to step 2

### What NOT to do
- Do not change any other screen files
- Do not remove `_maybeShowPermissionWizard` — just rewrite its body
- Do not import new packages — `showModalBottomSheet` is already used in `app.dart`

---

## Pending Task — Hive Encryption for Sensitive Health Data

**Goal:** Encrypt the three most sensitive Hive boxes (`medicines`, `medicine_logs`, `tb_profiles`) using `HiveAesCipher`. The key is stored in `flutter_secure_storage` (Android Keystore-backed). Other boxes remain unencrypted — no need to encrypt habits, water, streaks, settings.

**Files:** `pubspec.yaml`, `lib/main.dart`

---

### Step 1 — `pubspec.yaml`

```yaml
dependencies:
  flutter_secure_storage: ^9.2.2
```

---

### Step 2 — `lib/main.dart`

Add the key generation + box opening helper. Call it before `_openHiveBoxes`.

```dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<HiveAesCipher> _getOrCreateCipher() async {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  const keyName = 'rutin_hive_key';
  String? stored = await storage.read(key: keyName);
  if (stored == null) {
    final key = Hive.generateSecureKey();
    stored = base64.encode(key);
    await storage.write(key: keyName, value: stored);
  }
  return HiveAesCipher(base64.decode(stored));
}
```

In `_openHiveBoxes()` (or wherever Hive boxes are opened in `main.dart`), change the three sensitive boxes to use the cipher:

```dart
Future<void> _openHiveBoxes() async {
  final cipher = await _getOrCreateCipher();

  await Future.wait([
    // Sensitive boxes — encrypted
    Hive.openBox<Medicine>('medicines', encryptionCipher: cipher),
    Hive.openBox<MedicineLog>('medicine_logs', encryptionCipher: cipher),
    Hive.openBox<TBTreatmentProfile>('tb_profiles', encryptionCipher: cipher),

    // Non-sensitive boxes — unchanged
    Hive.openBox<WaterGoal>('water_goals'),
    Hive.openBox<WaterLog>('water_logs'),
    Hive.openBox<Habit>('habits'),
    Hive.openBox<HabitLog>('habit_logs'),
    Hive.openBox<HabitGroup>('habit_groups'),
    Hive.openBox<Routine>('routines'),
    Hive.openBox<RoutineLog>('routine_logs'),
    Hive.openBox<Medal>('medals'),
    Hive.openBox<UserProfile>('user_profile'),
    Hive.openBox<SleepSettings>('sleep_settings'),
    Hive.openBox<int>('morning_streaks'),
    Hive.openBox<String>('app_settings'),
  ]);
}
```

**Migration note:** Existing unencrypted boxes cannot be re-opened with a cipher. On first install after this change, existing users will get an error trying to open an already-created unencrypted box with a cipher. To handle gracefully, add a migration try/catch:

```dart
Future<Box<Medicine>> _openMedicinesBox(HiveAesCipher cipher) async {
  try {
    return await Hive.openBox<Medicine>('medicines', encryptionCipher: cipher);
  } catch (_) {
    // Existing unencrypted box — delete and re-open encrypted (data loss on migration)
    await Hive.deleteBoxFromDisk('medicines');
    return Hive.openBox<Medicine>('medicines', encryptionCipher: cipher);
  }
}
```

Apply same pattern for `medicine_logs` and `tb_profiles`. Users will lose existing data once on upgrade — acceptable for a first release with no prior published version.

### Verify
- `flutter pub get` — no errors
- App cold starts without errors
- Medicine added → app killed → reopened → medicine still present (cipher key persisted correctly)
- `dart analyze lib/main.dart` — no errors

### What NOT to do
- Do not encrypt `habits`, `water_goals`, `water_logs`, `app_settings` — unnecessary overhead
- Do not hardcode the cipher key — always read from secure storage
- Do not use `EncryptedSharedPreferences` directly — `flutter_secure_storage` wraps Android Keystore correctly
