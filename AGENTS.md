# Agent Context

Read this first before touching any code. This file keeps all AI agents (Claude, Codex, etc.) aligned.

## What This Project Is

A Flutter Android app for daily health habits and reminders. Built by Ilham Maulana Sulaeman, a university student in Bandung, Indonesia who has TB and needed a reliable medicine reminder that actually works - free, no paywalls, local-first.

**Not** a generic habit tracker. A personal health infrastructure tool, with a real mission: Indonesia is #2 in TB cases worldwide. Poor medication adherence causes drug-resistant TB. This app solves that.

## Owner

- **Name:** Ilham Maulana Sulaeman
- **Device:** Realme GT 2 Pro (RMX3301), Android 14 + Huawei Watch (watch receives notifications passively, no special code needed)
- **Goal:** Daily use + Apple Developer Academy portfolio

## How Ilham Works (important)

- Direct and fast - no filler, no over-explaining
- Simple over clever - if there's a 10-line solution and you wrote 50, rewrite it
- Ask before any visual/design decision - never guess on UI
- No Inter/Roboto fonts
- Glassmorphism and gradients are allowed if used with intention and taste - not as defaults


## Current Status

See `TODO.md` for full task list with statuses.

**Phase:** Medicine ✅ Water ✅ Habits ✅ Home today view ✅ (hero + scrollable sections). Firebase Analytics ✅. Archive screen ✅. Package: `com.rutin.app`.
**App name:** Rutin

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3.44 (Dart) |
| State | flutter_riverpod |
| Storage | hive + hive_flutter |
| Notifications | flutter_local_notifications |
| Alarms | Native AlarmManager (water) + android_alarm_manager_plus (legacy, unused) |
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

## Pending Task — RECEIVE_BOOT_COMPLETED Reschedule

**Why:** Android cancels all AlarmManager alarms on device reboot. Medicine and water reminders go silent after a restart with no error. For TB patients missing a dose is dangerous — this must be fixed.

**The permission `RECEIVE_BOOT_COMPLETED` is already declared in `AndroidManifest.xml`. Do not add it again.**

---

### Step 1 — Medicine alarm registry in `NativeReminderScheduler.kt`

Add a persistent registry of active base alarms to SharedPreferences so `BootReceiver` can reschedule without Flutter running.

**New prefs file:** `"medicine_alarm_registry"` (separate from the existing `"medicine_alarm_debug"` prefs).

Add these methods to the `NativeReminderScheduler` companion object:

```
persistAlarm(context, rootAlarmId, scheduledMinutes, medicineName, dosage, renotifyMinutes)
  → writes/updates one entry in the registry JSON array

removeAlarm(context, rootAlarmId)
  → removes the entry with matching rootAlarmId from the registry

rescheduleAll(context)
  → reads the registry, for each entry calls schedule() with:
      triggerAtMillis = nextOccurrenceMillis(scheduledMinutes)
      isLoop = false
```

`nextOccurrenceMillis(scheduledMinutes: Int): Long` — same logic as `_nextMedicineTime` in `main.dart`:
set today's date at HH:MM, if that time has already passed bump to tomorrow.

Registry JSON format (use `org.json.JSONArray` — built into Android, no extra dependency):
```json
[
  { "rootAlarmId": 12345, "scheduledMinutes": 480, "medicineName": "Amoxicillin", "dosage": "1 tablet", "renotifyMinutes": 1 },
  ...
]
```

**Wire up in existing methods:**
- In `schedule()`: call `persistAlarm()` only when `isLoop == false` (base alarms only, not the re-notify loop)
- In `cancel()`: call `removeAlarm()`

---

### Step 2 — New file `BootReceiver.kt`

```kotlin
package com.rutin.app

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != "android.intent.action.QUICKBOOT_POWERON") return

        // Reschedule all medicine alarms
        NativeReminderScheduler.rescheduleAll(context)

        // Reschedule water reminder if it was active
        val waterPrefs = context.getSharedPreferences("water_settings", Context.MODE_PRIVATE)
        if (waterPrefs.getBoolean("reminder_active", false)) {
            val intervalMs = waterPrefs.getLong("interval_ms", 120 * 60_000L)
            WaterAlarmReceiver.schedule(context, intervalMs)
        }
    }
}
```

---

### Step 3 — Register `BootReceiver` in `AndroidManifest.xml`

Add inside `<application>`, alongside the other receivers:

```xml
<receiver
    android:name=".BootReceiver"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

`QUICKBOOT_POWERON` covers Huawei/MIUI/OnePlus fast-boot which does not fire `BOOT_COMPLETED`.

---

### What NOT to do
- Do not start a Flutter engine or launch the app at boot — registry must be native-only
- Do not reschedule loop alarms (`isLoop=true`) at boot — only base alarms fire at the scheduled time; the loop is started by `ReminderAlarmReceiver` when the base alarm fires
- Do not modify the Dart/Flutter side — all changes are Kotlin only

---

## Sleep Mode — Full Feature Plan (4 Codex Sessions)

**What this is:** A wake-up gate. When the phone is unlocked during the morning window (5–10AM) after sleep mode was active, a mini-game launches full-screen. The user must play (or wait 15s for emergency skip) before the phone is usable. The game rotates daily. This is the app's MOAT.

**Data model:** `SleepSettings` (typeId: 9) already exists in Hive. Fields: `sleepModeEnabled`, `sleepModeStartMinutes`, `wakeWindowStartMinutes`, `wakeWindowEndMinutes`, `accessibilityGranted`.

**Morning streak:** Add a new Hive box `"morning_streaks"` using a simple `Box<int>` keyed by date string `"yyyy-MM-dd"` storing value `1` when game completed that day. Streak = consecutive days with value `1`.

---

### Session A — Sleep Settings Screen (Flutter only)

**File to create:** `lib/features/sleep/presentation/sleep_settings_screen.dart`
**Route:** `/sleep-settings` — add to `app.dart` as full-screen route above shell

**UI sections:**
1. **Toggle** — "Mode Tidur" on/off switch. When turned on, check if `AccessibilityService` is granted:
   - If not granted → show inline banner: "Untuk pengalaman terbaik, aktifkan Accessibility Service." with button "Aktifkan" → opens `Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)` via `url_launcher` or a MethodChannel
   - If granted → just enable
2. **Jam tidur** — time picker for `sleepModeStartMinutes` (default 21:00)
3. **Jendela bangun** — two time pickers: start (default 05:00) and end (default 10:00)
4. **Accessibility status row** — shows "Diizinkan ✓" or "Belum diizinkan" with a grant button
5. **Battery optimization row** — button that opens battery optimization settings for the app (`ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`)

Save all changes to Hive `SleepSettings` on every picker change (no save button needed).

**Access from:** Settings sheet or home screen header menu (wherever the gear/menu is).

---

### Session B — Wake-up Game Screen (Flutter only)

**File to create:** `lib/features/sleep/presentation/wakeup_game_screen.dart`

**Entry point:** This screen is launched by the native `WakeUpTriggerReceiver` (built in Session C). For now, also add a **"Test Game"** button on the sleep settings screen so it can be tested without the native service.

**Daily game selection:**
```dart
int _todayGameIndex() {
  final now = DateTime.now();
  final seed = now.year * 10000 + now.month * 100 + now.day;
  return Random(seed).nextInt(6); // 0–5
}
```
Same game all day. Different every day.

**Emergency skip:** After 15 seconds, a small `TextButton("Lewati →")` fades in at bottom-right. Tapping it logs the skip and dismisses.

**On game completion:**
- Play `notif_chime.ogg` via `AudioPlayer` or `SystemSound`
- Show a 2-second celebration overlay (confetti or pulsing circle)
- Increment morning streak in Hive
- Log `game_completed` event to Firebase Analytics
- Dismiss screen → phone unlocks

**Morning streak display:** Show "Hari ke-N 🔥" at the top of the game screen.

---

#### The 6 Games (all in same file as private widgets)

**Game 0 — Sequence Memory**
- 4 colored squares (pink, blue, green, amber — match app palette)
- Computer lights them up in sequence (1 per second)
- User taps same sequence
- 3 rounds: sequence length 3, 4, 5
- Wrong tap → gentle shake + restart round (infinite tries, no fail state)
- All 3 rounds correct → complete

**Game 1 — Word Unscramble**
- Pick word from daily seed: `['RUTIN','SEHAT','OBAT','PAGI','TIDUR','DISIPLIN','SEMANGAT','KONSISTEN','KEBIASAAN','TUBUH']`
- Show scrambled letters as tappable chips in a row
- Tap chip → moves to answer row in order
- Tap placed chip → returns to pool
- When answer matches → complete
- Show word meaning below on completion

**Game 2 — Tap Rhythm**
- 10 circles fall from top, one at a time, ~1.5 seconds each
- A green "tap zone" bar at the bottom (20% height)
- Tap anywhere when circle is in zone → hit (green flash)
- Miss (circle leaves zone untapped) → miss counter
- Get 7/10 hits → complete
- Use `AnimationController` per circle, sequential

**Game 3 — Tile Puzzle (8-puzzle)**
- 3×3 grid, tiles 1–8 + one empty space
- Tap tile adjacent to empty space → slides
- Solved when tiles 1–8 in order left-to-right, top-to-bottom
- Generate a random but **solvable** shuffle (check parity — an 8-puzzle is solvable if number of inversions + row of blank from bottom is even)
- Seed shuffle with today's date for daily consistency

**Game 4 — Daily Quiz**
- 3 questions from a hardcoded bank of 20 health/motivation questions (Indonesian)
- Select 3 using daily seed
- 4 options each, one correct
- Get 2/3 correct → complete (fail = restart from Q1, infinite tries)
- Sample questions:
  - "Berapa liter air yang direkomendasikan per hari?" → 2 liter ✓
  - "Apa kepanjangan dari OAT?" → Obat Anti Tuberkulosis ✓
  - "Vitamin apa yang diproduksi tubuh dari sinar matahari?" → Vitamin D ✓
  - (fill remaining 17 with general wellness/health questions)

**Game 5 — Connect the Dots**
- 8 numbered dots placed pseudo-randomly on screen (seeded by date)
- User draws a path connecting 1→2→3→...→8 by dragging
- Use `CustomPainter` + `GestureDetector` onPanUpdate
- Dot "snaps" highlighted when finger is within 30px
- Line drawn behind finger
- All 8 connected in order → complete
- Dots positioned so lines don't cross too awkwardly (pre-generate good layouts, pick by seed)

---

### Session C — Native Sleep Detection Service (Kotlin only)

**Files to create:**
- `android/.../SleepModeService.kt` — foreground service
- `android/.../WakeUpTriggerReceiver.kt` — listens for `ACTION_USER_PRESENT`
- `android/.../SleepModeChannel.kt` — MethodChannel bridge

**SleepModeService:**
- Runs as foreground service with persistent notification "Mode tidur aktif" + action "Saya masih terjaga" (pauses detection 30 min)
- Tracks `lastInteractionMs` (updated by `ACTION_USER_PRESENT` + Accessibility events)
- Polls every 5 min: check 3-case sleep logic from `docs/ARCHITECTURE.md`
- When sleep mode triggers → writes `"sleep_active": true` to SharedPreferences
- When `ACTION_USER_PRESENT` fires during wake window + sleep was active → launches `WakeUpGameScreen` via Flutter intent
- MethodChannel `"rutin/sleep"` methods: `startService`, `stopService`, `isRunning`

**WakeUpTriggerReceiver:**
- Registered dynamically by `SleepModeService` (not in manifest — avoids always-on)
- On `ACTION_USER_PRESENT`:
  - Read `SleepSettings` from Hive via shared prefs mirror OR just check SharedPreferences `"sleep_active"` flag
  - Check current time is within wake window
  - If both true → launch `WakeUpGameScreen`

**AndroidManifest additions:**
- `<service android:name=".SleepModeService" android:foregroundServiceType="health" android:exported="false" />`

**Wire up from Flutter:**
In `sleep_settings_screen.dart`, when toggle turned on → `MethodChannel("rutin/sleep").invokeMethod("startService")`. When turned off → `stopService`.

---

### Session D — AccessibilityService (Kotlin only)

**Files to create:**
- `android/.../RutinAccessibilityService.kt`
- `android/app/src/main/res/xml/accessibility_service_config.xml`

**Config XML:**
```xml
<accessibility-service
    android:accessibilityEventTypes="typeWindowStateChanged|typeViewClicked"
    android:accessibilityFeedbackType="feedbackGeneric"
    android:accessibilityFlags="flagReportViewIds"
    android:canRetrieveWindowContent="false"
    android:notificationTimeout="100" />
```

**RutinAccessibilityService:**
- On `TYPE_WINDOW_STATE_CHANGED`: if `WakeUpGameScreen` is active and user navigated away → `performGlobalAction(GLOBAL_ACTION_BACK)` to return
- On any `AccessibilityEvent` during sleep hours → update `lastInteractionMs` in SharedPreferences (used by `SleepModeService` detection)
- When `WakeUpGameScreen` is dismissed normally (game complete or skip) → set a flag `"game_dismissed_normally": true` so the service doesn't force-return

**AndroidManifest:**
```xml
<service
    android:name=".RutinAccessibilityService"
    android:exported="true"
    android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE">
    <intent-filter>
        <action android:name="android.accessibilityservice.AccessibilityService"/>
    </intent-filter>
    <meta-data
        android:name="android.accessibilityservice"
        android:resource="@xml/accessibility_service_config"/>
</service>
```

---

### Build order
Session A → B → C → D. Each session is independently testable.
Session B has a "Test Game" button so games work before native service exists.
Session C wires the native trigger to Session B's screen.
Session D adds the home-button intercept on top of Session C.

---

## Pending Task — Custom Notification Sounds + Vibration

**Sound files are already placed at:**
- `android/app/src/main/res/raw/notif_chime.ogg` → use for water + habit notifications
- `android/app/src/main/res/raw/ringtone.ogg` → use for medicine alarm

**Do not touch Flutter/Dart files. All changes are Kotlin only.**

---

### Critical Android constraint
`NotificationChannel` sound can only be set when the channel is **first created**. If the channel already exists on the device, `setSound()` is ignored. To force the new sound, each channel ID must change. Use `_v2` suffix:
- `water_reminder_native` → `water_reminder_v2`
- `habit_reminder` → `habit_reminder_v2`
- `medicine_alarm` → `medicine_alarm_v2`

Also delete the old channels to clean up orphans:
```kotlin
nm.deleteNotificationChannel("water_reminder_native")  // in WaterAlarmReceiver
nm.deleteNotificationChannel("habit_reminder")          // in HabitAlarmReceiver
nm.deleteNotificationChannel("medicine_alarm")          // in ReminderAlarmReceiver
```

---

### How to set custom sound on a NotificationChannel (API 26+)

Required imports: `android.content.ContentResolver`, `android.media.AudioAttributes`, `android.net.Uri`

**For water + habit notifications** (notif_chime.ogg, USAGE_NOTIFICATION):
```kotlin
val soundUri = Uri.parse(
    "${ContentResolver.SCHEME_ANDROID_RESOURCE}://${context.packageName}/${R.raw.notif_chime}"
)
val audioAttrs = AudioAttributes.Builder()
    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
    .build()
channel.setSound(soundUri, audioAttrs)
channel.enableVibration(true)
channel.vibrationPattern = longArrayOf(0, 250)
```

**For medicine alarm** (ringtone.ogg, USAGE_ALARM — plays through silent mode):
```kotlin
val soundUri = Uri.parse(
    "${ContentResolver.SCHEME_ANDROID_RESOURCE}://${context.packageName}/${R.raw.ringtone}"
)
val audioAttrs = AudioAttributes.Builder()
    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
    .setUsage(AudioAttributes.USAGE_ALARM)
    .build()
channel.setSound(soundUri, audioAttrs)
channel.enableVibration(true)
channel.vibrationPattern = longArrayOf(0, 400, 200, 400, 200, 400)
```

---

### Files to modify

**`WaterAlarmReceiver.kt`**
- Change `CHANNEL_ID = "water_reminder_native"` → `"water_reminder_v2"`
- In `showNotification()`, before `nm.createNotificationChannel(channel)`:
  - Delete old channel: `nm.deleteNotificationChannel("water_reminder_native")`
  - Apply sound + vibration from snippet above (notif_chime, USAGE_NOTIFICATION)

**`HabitAlarmReceiver.kt`**
- Change `CHANNEL_ID = "habit_reminder"` → `"habit_reminder_v2"`
- In the channel creation block:
  - Delete old channel: `nm.deleteNotificationChannel("habit_reminder")`
  - Apply sound + vibration (notif_chime, USAGE_NOTIFICATION)

**`ReminderAlarmReceiver.kt`**
- Change `channelId = "medicine_alarm"` → `"medicine_alarm_v2"`
- In the channel creation block:
  - Delete old channel: `nm.deleteNotificationChannel("medicine_alarm")`
  - Apply sound + vibration (ringtone, USAGE_ALARM)
  - Keep existing `setBypassDnd(true)` and `lockscreenVisibility` — do not remove

---

### What NOT to do
- Do not change notification text, priorities, or full-screen intent logic
- Do not touch `NotificationCompat.Builder` calls — only the `NotificationChannel` setup changes
- Do not add sound to `NotificationCompat.Builder` directly — channel-level sound is sufficient on API 26+
- For API < 26, `NotificationCompat.Builder.setSound()` would be needed, but minSdk covers this — skip it

---

**2026-05-30 (session 14) - Claude (claude-sonnet-4-6)**
- **Sleep Mode — all 4 sessions shipped:**
- **Session A** — `lib/features/sleep/presentation/sleep_settings_screen.dart`: toggle (start/stop SleepModeService via rutin/sleep channel), sleep time picker (sleepModeStartMinutes), wake window pickers (start/end), accessibility status row (isAccessibilityGranted → opens ACTION_ACCESSIBILITY_SETTINGS), battery optimization row (opens ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS). Settings mirrored to native SharedPrefs via `saveSleepSettings`. Route: `/sleep-settings`. Test Game button → `/wakeup-game`.
- **Session B** — `lib/features/sleep/presentation/wakeup_game_screen.dart`: daily game picker selects from `[0, 2]` only (seed = year*10000+month*100+day). Morning streak from `morning_streaks` Hive box (Box<int>). 15s emergency skip (`Lewati →` TextButton). Game 0 = Sequence Memory (3 rounds len 3/4/5, shake on wrong, all correct → complete). Game 2 = Tap Rhythm (10 circles, zone at bottom ~22% height, 7/10 hits → complete). On complete: native chime via `playChime` MethodChannel, 2s celebration overlay (animated scale + check icon), increment streak, Firebase `game_completed`, pop. `_LaunchGameListener` in `app.dart` listens for native→Flutter `launchGame` MethodChannel call to push `/wakeup-game` from any state. `morning_streaks` box opened in `main.dart`.
- **Session C** — `SleepModeService.kt`: foreground service (`health` type), sticky, polls every 5 min for 3-case sleep logic (idle>60min, audio-stopped>15min, audio-on>2h). Sets `sleep_active` flag. "Saya masih terjaga" notification action pauses 30 min. Registers `WakeUpTriggerReceiver` dynamically for ACTION_USER_PRESENT. `WakeUpTriggerReceiver.kt`: checks sleep_active + wake window (from `sleep_settings_native` SharedPrefs) → clears flag, sets `launch_game_at`, starts MainActivity with route extra. MainActivity.onNewIntent routes Flutter to `/wakeup-game` via MethodChannel call `launchGame`. `setupSleepChannel` added to MainActivity for all rutin/sleep methods: startService, stopService, isRunning, isAccessibilityGranted, openAccessibilitySettings, openBatteryOptimization, saveSleepSettings, setGameActive, setGameDismissedNormally. `playChime` added to `habit_app/native_reminder` channel (MediaPlayer.create → R.raw.notif_chime).
- **Session D** — `RutinAccessibilityService.kt`: updates `last_interaction_ms` on every event. On TYPE_WINDOW_STATE_CHANGED: if `game_active` && !`game_dismissed_normally` && package ≠ com.rutin.app → performGlobalAction(GLOBAL_ACTION_BACK). `accessibility_service_config.xml` created. Both services registered in AndroidManifest.
- **Verified:** `dart analyze` — only pre-existing info lints. `gradlew app:compileDebugKotlin --no-daemon` → BUILD SUCCESSFUL.
- **End-to-end test** (sleep detect → USER_PRESENT → game launch) requires physical device — cannot be verified here.

**2026-05-30 (session 13) - Codex (gpt-5)**
- **Home today view** — replaced 3-card feature launcher with scrollable today dashboard. Background image is now a fixed hero at top; Obat / Air / Kebiasaan sections scroll below it. Each section has a label + "→ Semua" link. Obat shows per-medicine dose chips (inline tap to mark taken). Air shows compact WaterProgressWidget. Kebiasaan shows today's habits (capped at 5 + overflow link).
- **Background fix** — initial implementation blocked the sun/atmosphere background; fixed by making the background a full-height hero sliver and pushing content sections below the fold.

**2026-05-30 (session 12) - Claude (claude-sonnet-4-6)**
- **Multi-dose medicine workflow redesign** — replaced the 4-section bucket layout (Perlu diminum sekarang / Berikutnya / Sudah diminum / Terlewat) with per-medicine cards. Each card shows medicine name, meal timing, dosage, then a row of tappable dose chips: pink gradient = active now, green = taken, orange-red = missed, grey = upcoming. Tap a chip to toggle taken.
- **Slim day banner** — replaced the `_HeroSummary` 4-stat grid with a single-line banner showing the most relevant status (N perlu diminum / N terlewat / Semua sudah diminum / N/M selesai).
- **Multi-time add flow** — `AddMedicineScreen` now supports unlimited dose times per medicine. Default is 1 time; `+ Tambah waktu` adds another row; each row has an × to remove; times are de-duped and sorted on save. No model change needed — `scheduleTimes` was already `List<int>`.
- **Swipe-to-delete** now at the medicine card level (one swipe deletes the whole medicine + all its alarms), not per individual dose.
- Verification: `dart analyze` on both files — no issues. Device-level verification still needed (Windows Dart worker issue may block build on first attempt).

**2026-05-30 (session 11) - Codex (gpt-5)**
- **Obat workflow redesign** — the Obat tab is now a true `Hari ini` dashboard grouped into `Perlu diminum sekarang`, `Berikutnya`, `Sudah diminum`, and `Terlewat` instead of a flat medicine list.
- **Food timing** — medicines now store and display `Bebas`, `Sebelum makan`, `Sesudah makan`, or `Saat makan` as a first-class property on both add-flow and dose cards.
- **Riwayat calendar** — added a separate medicine history page with monthly calendar dots and per-day dose inspection so taken vs missed is visible by date.
- **Reminder interval correction** — persistent medicine re-notify now matches product intent at 1 minute, not 10 minutes.
- Verification: analyzer hit only existing info-level lints. A full Flutter debug build was blocked once by a local Dart worker thread startup failure on Windows after code edits, so device-level verification of the new Obat UI still needs a fresh run.

**2026-05-30 (session 10) - Codex (gpt-5)**
- **Medicine daily schedule fix** — reworked the native reminder architecture so each medicine time has a daily base alarm plus a separate active-dose re-notify loop. When a dose fires, tomorrow's fixed-time reminder is scheduled immediately; tapping `Sudah diminum` now cancels only today's loop, not the future daily schedule. Root alarm ids are now per `(medicineId, scheduledMinute)` rather than one id per medicine.
- **Water undo UX** — removed the add-water snackbar and replaced it with a persistent inline Undo bar directly under the main add button on the Air screen.
- **Habits follow-up correction** — restored `Semua` as the always-visible stack workspace (tab bar always shown, no extra inline "buat rutinitas baru" row) and changed the reminder time pill to a Habits-themed purple pill instead of reusing Obat's pink medicine styling literally.
- Verification: `dart analyze` on changed Dart files passed with info-level existing lints only. Android Kotlin compile passed with `.\gradlew.bat app:compileDebugKotlin --no-daemon` after a daemon crash on the first attempt.

**2026-05-30 (session 9) - Claude (claude-opus-4-8 / claude-sonnet-4-6)**
Refinement pass across Home, Water, Obat, Kebiasaan:
- **Time chip on habit card** — when a habit has a reminder, the card shows a small clock + `HH:MM` in habits-purple (mirrors Obat). Feeds the existing auto-sort-by-time.
- **Back navigation consistency** — Water back arrow now `context.go('/')` (was a no-op `maybePop` in the shell). Added a back arrow to the Obat header → Home. Added a back arrow + `centerTitle` to the Kebiasaan AppBar → Home.
- **Live updates** — Home and Habits screens now listen to their Hive boxes (`water_logs`/`habits`/`habit_logs` on Home; `habits`/`habit_groups`/`habit_logs` on Habits) via stored `ValueListenable`s added/removed symmetrically. Adding water/a habit reflects instantly without a manual refresh. `_load()` guarded with `mounted`.
- **Group delete from tab** — long-press a group tab pill → actions sheet (rename / Hapus rutinitas).
- **Two-option stack delete** — `_deleteGroup` now asks: "Hapus rutinitas saja" (habits → ungrouped) vs "Hapus beserta kebiasaannya" (habits deleted too, reminders cancelled). Empty groups skip straight to a simple confirm. New repo method `deleteGroupWithHabits` returns deleted ids for reminder cancellation.
- **Swipe-to-delete restored** — re-wrapped habit cards in `_SwipeToDelete` inside the drag view (both flat + inside stacks); the wrapper had been dropped during the drag rewrite. Whole stacks are now swipe-to-delete too (Dismissible → two-option dialog, `confirmDismiss` returns false since we delete + reload ourselves).
- **Unfold-after-move** — dropping a stack (or a habit into a stack) calls `onEnsureExpanded` so the moved stack expands, making the whole-stack move obvious.
- **Dead code removed** — `_FlatView`, `_GroupBlock`, `_NewGroupButton`, `_onFlatReorder` (all orphaned when the flat view became the always-on `_EditModeView`). Restored `_GroupView` + `_TodayHeader` which an over-broad delete had caught; `_TodayHeader` is now rendered at the top of `_EditModeView`.

**2026-05-27 (session 6) - Claude (claude-sonnet-4-6)**
- Full UI/UX redesign across all 9 files (Impeccable pass). No logic changes — visual layer only.
- `AppTheme`: warm `surfaceContainerLow` scaffold bg, `CardThemeData` 0-elevation with 1px `outlineVariant` border, tight letter-spacing text hierarchy, 52px `FilledButton`, floating SnackBar with 12px radius.
- `HomeScreen`: removed AppBar, greeting header with time-of-day salutation ("Selamat pagi/siang/malam"), `FeatureCards` with colored 52×52 icon containers (green/blue/brown), permission wizard logic preserved.
- `WaterProgressWidget`: `TweenAnimationBuilder<double>` → `CustomPainter` 270° arc (GPU-safe), 180×180, `StrokeCap.round`, center stack shows count + label.
- `WaterScreen`: arc centered, `_GlassButton` (68×68 `Material` + `InkWell`) replacing bare `IconButton`, `SingleChildScrollView`.
- `HabitCard`: emoji in 48×48 rounded container, `primaryContainer` tint on done card, streak in `cs.primary` bold.
- `HabitsScreen` + retire sheet: better empty state, improved retire sheet layout.
- `AddHabitScreen`: "JADWAL" section label, "PENGINGAT" bordered container with `InkWell` time row.
- `MedicineListScreen`: time badge with `primaryContainer` bg, improved empty state, `cs.error` Dismissible bg.
- `AddMedicineScreen`: "WAKTU MINUM" section label, `InkWell` time picker row replacing bare `ListTile`.
- Fixed `CardTheme` → `CardThemeData` (API change in newer Flutter SDK).

**2026-05-27 (session 5) - Claude (claude-sonnet-4-6)**
- Added delete (swipe left) for Medicine and Habits. Medicine delete cancels all AlarmManager alarms for that medicine before removing from Hive. Habit delete cancels native HabitAlarmReceiver alarm before removing. Both confirm via AlertDialog before dismissing.
- Medal system: long-press habit card → "Jadikan Medali" bottom sheet → habit removed, medal stored with peak streak. Auto-update: after each markDone, if new streak > existing medal peak, medal silently updates. Medal Hive model (typeId 10) + MedalRepository. Medals UI (profile/trophy tab) deferred.

**2026-05-27 (session 4) - Claude (claude-sonnet-4-6)**
- Completed habits MVP: create habit, check off today, streak counter, optional daily reminder.
- `AddHabitScreen`: name, emoji (text field), 7-day schedule chips (all selected by default), optional reminder toggle + time picker.
- `HabitsScreen`: real Hive-backed list, tap to mark done (guarded against double-log), streak shown on card, empty state, FAB → push /habits/add then `_load()` on pop.
- Navigation fix: `AddHabitScreen` uses `context.pop()` (not `context.go('/habits')`) so the awaited push in HabitsScreen FAB resolves and the list refreshes immediately.
- **Native habit reminder architecture**: `HabitAlarmReceiver.kt` — BroadcastReceiver shows notification (emoji + name, "Waktunya melakukan kebiasaanmu!"), reschedules itself +24h. `HabitReminderService.dart` computes next trigger with `DateTime.now()` (no timezone package needed), passes `triggerMs` via MethodChannel `scheduleHabitAlarm` / `cancelHabitAlarm`.
- Avoided `timezone` + `flutter_timezone` packages — flutter_timezone 1.0.8 had JVM 1.8 target incompatible with project's Java/Kotlin 17; native AlarmManager approach sidesteps this entirely and stays consistent with water alarm architecture.
- Notification tap (`payload == 'habit'`) routes to `/habits` via `appRouter.go()`.

**2026-05-27 (session 3) - Claude (claude-sonnet-4-6)**
- Completed water reminder feature end-to-end.
- **Native water alarm architecture**: replaced android_alarm_manager_plus + flutter_local_notifications action callbacks with two native Kotlin BroadcastReceivers: `WaterAlarmReceiver` (shows notification, reschedules via AlarmManager) and `WaterActionReceiver` (handles "Sudah minum" tap — cancels notification, writes pending count to SharedPreferences). No app launch on action tap.
- Root cause of broken action callback: flutter_local_notifications background isolate `initialize()` was overwriting the registered Flutter engine on the native side, so action broadcasts were delivered to a dead isolate.
- Fixed Kotlin `Long`/`Integer` type mismatch in MethodChannel (`call.argument<Any>(...) as? Number`)?.toLong()`) — without this, `intervalMs` defaulted to 2 hours instead of 15 seconds.
- Fixed race condition: `_load()` (sync) and `_checkPendingLogs()` (async) are now separate — previously a single async `_load()` could reassign `_goal` mid-flight and reset the reminder toggle.
- Pending water logs are synced to Hive when the Water screen is opened or app resumes.
- Debug mode: alarm fires every 15 seconds (native), notifications appear as banner on all phone states.
- Water settings (start/end/interval) are saved to native SharedPreferences so `WaterAlarmReceiver` can check the time window without a Flutter engine.

**2026-05-27 - Claude (claude-sonnet-4-6)**
- Full alarm system diagnosis: root cause was `context.startActivity()` blocked on Android 10+ (API 29+).
- Fixed `ReminderAlarmReceiver.kt`: replaced `startActivity()` with `showFullScreenNotification()` — posts notification with `setFullScreenIntent()`. Android now handles: screen off → full-screen ReminderActivity; screen on → notification banner.
- Fixed `ReminderActivity.kt`: both buttons now call `nm.cancel(alarmId)` before finish(); removed contradictory `FLAG_ALLOW_LOCK_WHILE_SCREEN_ON`.
- Fixed `notification_service.dart`: notification ID is now `alarmId` directly (was random timestamp — couldn't cancel by ID).
- Fixed `notification_handler.dart`: removed double scheduling in snooze (`startRenotifyLoop()` removed — native receiver already reschedules).
- Fixed `add_medicine_screen.dart`: `context.pop()` → `context.go('/medicine')` so user lands on updated list after saving.
- Created `docs/plan/report.md` + `docs/plan/plan.md` for full technical record.
- Created `docs/DECK.md` — app pitch for Apple Developer Academy + personal portfolio.
- App named **Rutin**. Git repo initialized, first commit `2e6ce21`.
- Verified on Realme GT 2 Pro / Android 14: screen-off full-screen ✅, screen-on banner ✅, snooze ✅.
- Gradle OOM fixed: daemon disabled, heap reduced to 512m in `android/gradle.properties`.

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
