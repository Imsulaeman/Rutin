# Log

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
