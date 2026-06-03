# Log

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
