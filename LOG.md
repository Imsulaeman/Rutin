# Log

---

## 2026-06-15

### Sleep timer notification wake fix
- Notifications waking the phone screen (e.g. incoming messages) were resetting the 10-minute sleep timer, preventing `sleep_active` from ever being set.
- Fix: `onScreenOn()` now checks `KeyguardManager.isKeyguardLocked()` — if the keyguard is still showing, the screen woke due to a notification (not user), so the timer is left running.

### Tutorial fix
- Tutorial never appeared after onboarding because `TutorialTrigger.fire()` was called before `context.go('/')`, so no listener was attached yet when the event fired.
- Fix: check `TutorialTrigger.notifier.value > 0` right after adding the listener in home screen `initState` — fires tutorial immediately if it was already triggered.

### Morning gate reliability + duplicate fix
- **Root cause (duplicates):** accessibility service + full-screen intent notification + `_checkPendingGate()` on resume all fired `appRouter.push('/morning-gate')` independently for the same sleep event → 2–3 stacked gates.
- **Root cause (unreliable):** accessibility service checked `sleep_active`, but `onUserPresent()` clears it before the service sees any window events → fallback was a no-op.
- **Fix:** replaced `sleep_active` gate-trigger check with a new `gate_pending` one-shot flag in SharedPrefs.  
  - Set at all 3 trigger sites (`handleSleepTrigger`, `handleAudioCheck` max-wait, `simulateSleepTrigger`).  
  - Cleared in `onNewIntent` (first trigger wins), `checkPendingGate`, and `setGameDismissedNormally`.  
  - Accessibility service now reads `gate_pending` (persists even if service was killed).  
  - Dart-side `_gateShowing` bool added as load-bearing dedup: `_pushGate()` is a no-op if gate already on screen, auto-resets when gate is popped.

Dropped Play Store distribution — too hard to recruit 12 testers. App is now **self-use only** (sideloaded APK). No more Closed Testing track, no production submission goal.

---

## 2026-06-06 (current status)

### App status
- Version: `1.0.1+2` (bumped from `1.0.0+1` this session)
- Play Store track: **Internal Testing** (active, `1.0.0+1` uploaded under Benih Studio account)
- Next step: build & upload `1.0.1+2` AAB to Internal Testing, then create **Closed Testing** release to start the 12-tester / 14-day clock

### What was done this session
- Removed Pill mascot from onboarding page 1 (transparency issue)
- Fixed habit notifications: changed channel audio from `USAGE_NOTIFICATION` → `USAGE_ALARM`, added `setBypassDnd(true)`, `VISIBILITY_PUBLIC`, `CATEGORY_REMINDER` — root cause was DND and OEM battery savers silently suppressing habit reminders while medicine (which uses `USAGE_ALARM`) worked fine
- Bumped version to `1.0.1+2`

### Tester recruitment plan
- Need 12 Gmail addresses for Closed Testing
- Fastest sources: r/betatesting, Threads (@ulanghidup), Binus classmates group chat
- Collect emails via DM or Google Form → paste into Play Console Closed Testing email list → share opt-in link → testers open link on Android phone → install from Play Store

---

## 2026-06-06 (Play Store track requirements reference)

### Track summary
| Track | Purpose | Requirement |
|---|---|---|
| Internal Testing | Quick builds to trusted testers, identify early issues | None |
| Closed Testing | Wider controlled group, fix issues before launch | Must finish app setup |
| Open Testing | Public beta on Play Store, anyone can join | Must have production access first |
| Production | Live to everyone | Closed test with 12 opted-in testers for 14 consecutive days → apply from Dashboard |

### Flow
Internal Testing (done) → Closed Testing (12 testers, 14 days) → Apply for Production (Dashboard) → Google review ~7 days → Live

### Key rule
The 14-day clock only starts when testers **opt in**. Testers who opt out and re-opt in — the days do NOT accumulate; must be 14 consecutive days.

---

## 2026-06-06 (habit notification hardening + onboarding pill mascot removed)

- **Habit notification fix**: Changed habit notification channel from `USAGE_NOTIFICATION` → `USAGE_ALARM` audio attributes. Added `setBypassDnd(true)` and `lockscreenVisibility = VISIBILITY_PUBLIC` to channel. Added `CATEGORY_REMINDER` and `VISIBILITY_PUBLIC` to notification builder. Changed channel base ID from `"habit_reminder_*"` → `"habit_alarm_*"` so old channels get deleted and recreated with the new audio attributes on next trigger.
- **Root cause**: `USAGE_NOTIFICATION` is suppressible by DND and OEM battery savers; medicine (which works) used `USAGE_ALARM`. Habit now uses the same audio lane.
- **Removed Pill mascot from onboarding page 1**: `asset` param made optional in `_OnboardingPage`; pill mascot image removed. Star and flame mascots (pages 2–3) unchanged.
- Bumped version `1.0.0+1` → `1.0.1+2`.

---

## 2026-06-04 (repo cleanup + README screenshots)

- Added screenshots and banner to README (`preview/banner-preview/`).
- Removed irrelevant files from repo: `.codex_tmp_inspect_medicines.dart`, `flutter_01.png`, `scattered-idea.md`, `report.md`, `deck.md`, `AGENTS.md`, `LOGO_PROMPT.md`, `docs/plan/plan.md`, `web/`, `rutin-privacy/` submodule reference.

---

## 2026-06-04 (Play Store setup + package rename)

- Renamed package from `com.rutin.app` → `com.benihstudio.rutin` (original was already taken on Play Store).
- Updated `namespace` and `applicationId` in `android/app/build.gradle.kts`.
- Moved Kotlin source files from `com/rutin/app/` to `com/benihstudio/rutin/`; updated `package` declaration in all 15 Kotlin files.
- Removed old `com/rutin/` directory.
- Updated `android/app/google-services.json` with new Firebase app entry (`mobilesdk_app_id: 1:465017525957:android:d4eb9a26ecc2e2298f02ac`) for `com.benihstudio.rutin`; old `com.rutin.app` entry retained in file.
- Fixed `gradle.properties` JVM crash: added `-XX:+UseSerialGC` and set `org.gradle.daemon=false`; root cause was CompressedOops blocking native heap growth on low-RAM machine.
- Updated Settings About section: `builtBy` → "Benih Studio" (was "Ilham Maulana Sulaeman").
- Built release AAB (`flutter build appbundle --release`) and uploaded to Play Console internal testing track under Benih Studio developer account.
- Internal testing live: release name `1.0.0 (1)`, EN release notes.
- Play Store path: internal testing → closed testing (12 testers, 14 days) → production. Closed testing required before production access.

---

## 2026-06-04 (morning game always Connect the Dots fix)

- Fixed morning gate game always showing Connect the Dots for multiple consecutive days.
- Root cause: seed formula `year*10000 + month*100 + day` produces consecutive integers (20260602, 20260603, 20260604...). Dart's `Random` with consecutive integer seeds produces correlated `nextInt(3)` output — e.g. June 2–4 all mapped to index 5 (Connect the Dots).
- Fix: apply a bit-mixing hash to the raw date integer before passing to `Random`, breaking the correlation between adjacent dates.

---

## 2026-06-04 (notification reliability + separate sound settings)

- **Habit alarm reliability**: wrapped `showNotification()` and `schedule()` calls in `HabitAlarmReceiver.onReceive()` with `runCatching`. Each step now runs independently — a notification failure no longer kills the reschedule chain permanently.
- **Sound setting not applying**: notification channels are immutable after first creation. Fixed by switching to **sound-keyed channel IDs** (`habit_reminder_chime`, `habit_reminder_system`, etc.) in both `HabitAlarmReceiver` and `WaterAlarmReceiver`. On sound change, the old channel is deleted and a fresh one with the correct sound is created automatically.
- **Separate habit / water sound settings**: added `KEY_HABIT` / `habitSound` / `saveHabitSound` / `habitUri` to `ReminderSoundPrefs`. `HabitAlarmReceiver` now reads `habitUri()` instead of `notificationUri()`. Settings screen has a separate "Habit sound" row (seeded from the existing water sound for existing users).
- Renamed "Notification sound" row → "Water sound" (EN: "Water sound", ID: "Suara air") to match the new separation.
- Note: intermittent habit alarm misses on OEM devices (Xiaomi/Samsung) are likely OEM power management — ensure battery optimization is disabled in Settings → Battery.

---

## 2026-06-03 (sleep gate fix 2)

- Fixed morning gate requiring app to be open first.
- Root cause: `ACTION_USER_PRESENT` is caught by SleepModeService's dynamic receiver — if the service died before the user woke up, the unlock was never caught.
- Fix: `SleepTriggerReceiver.handleSleepTrigger()` now calls `SleepModeService.start()` after setting `sleep_active = true`. The alarm receiver is manifest-registered (survives service death), so it reliably restarts the service the moment sleep activates. Service is then alive and catches USER_PRESENT on unlock → gate fires without opening the app.
- The app-resume fallback (lifecycle fix) remains as a secondary backstop.

---

## 2026-06-03 (sleep gate fix)

- Fixed morning gate never appearing when app was already running in background overnight.
- Root cause: `_checkPendingGate()` only ran once in `initState`. If the wake-end alarm stopped the service (or OEM killed it) before the user woke up, `ACTION_USER_PRESENT` was never caught and the gate was silently dropped.
- Fix: added `WidgetsBindingObserver` to `_LaunchGameListenerState` in `app.dart`. Now calls `_checkPendingGate()` on every `AppLifecycleState.resumed` — covers both the service-killed path and the wake-end-stopped-service path.

---

## 2026-06-03 (medal redesign)

- Replaced retire-habit medal system with 3 fixed auto-calculated medals: Water Intake, Medicine Streak, Habit Streak.
- Created `MedalService` — stores PR + best date in `app_settings` Hive box, never resets on streak break, only updates when new streak exceeds stored PR.
- Profile screen redesigned: 3 medal cards with colored left borders, PR + current streak display, tappable for detail bottom sheet. Medals section appears above navigation tiles.
- Removed `_RetireSheet`, `_retireAsModal`, `_updateMedal`, `MedalRepository` import from habits screen. "Turn into medal" option removed from habit actions menu.
- Wired `MedalService.checkHabit()` on mark-done, `checkMedicine()` on dose taken, `checkWater()` on ml added.
- 11 new ARB keys added. `flutter analyze` clean.

---

## 2026-06-03 (continued)

- Completed ARB migration: all 225 `localized()` calls across 19 files replaced with `context.l10n.keyName`. Added 100+ new keys to both `app_en.arb` and `app_id.arb` (simple keys, parameterized keys with typed int placeholders, multi-placeholder keys). Deleted `localized()` helper from `l10n.dart`. Ran `flutter gen-l10n` and `flutter analyze` — zero errors, zero remaining `localized()` calls.
- Hardcoded strings intentionally left as-is (not in `localized()`): `habits_screen.dart` drag hint, streak label row; `add_medicine_screen.dart` dose schedule row. These are in scope for a future pass.

---

## 2026-06-03

- Verified P1–P4 implementation status against actual code.
- Confirmed done: custom fonts, permission wizard, Hive encryption, checkbox curve, FAB pressable, Riverpod DI, permission flag persistence, GoRouter fade transitions, calendar icon → /history, ambient sun easing, unit tests, Firebase Analytics audit (no PII), accessibility service description.
- Battery rationale: confirmed implemented via changed flow — pre-dialog in sleep_settings_screen.dart, opens app settings via native channel, no longer uses `requestIgnoreBatteryOptimizations` directly. TODO note updated.
- Lazy Hive: genuinely pending — `medals` and `morning_streaks` still open eagerly in `_openHiveBoxes()`.
- ARB migration: marked [x] in TODO but `localized()` helper still has 226 calls across 20 files — migration not complete.

---

## 2026-06-02

- Fixed Gradle daemon OOM crash: reduced JVM heap from `-Xmx4g` to `-Xmx2g`, trimmed Metaspace to 512m and CodeCache to 128m in `android/gradle.properties`. Machine has 5GB RAM; 4GB JVM left no headroom.
- Ran full app review pass: `/impeccable`, `/gpt-taste`, `/emil-design-eng` + Senior Developer security + code audit. Output: `report.md`.
- Added P1–P4 action items to `TODO.md` (From Review Report section).
- Added 3 AGENTS.md specs for P1 tasks: custom fonts (Bricolage Grotesque + DM Sans), permission dialog rewrite (step-by-step bottom sheet), Hive encryption (medicines + medicine_logs + tb_profiles).
