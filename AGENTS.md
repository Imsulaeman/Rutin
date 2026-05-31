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
- No Inter/Roboto fonts
- Glassmorphism and gradients are allowed if used with intention and taste — not as defaults

## Current Status

See `TODO.md` for full task list with statuses.

**Phase:** Medicine ✅ Water ✅ Habits ✅ Home today view ✅ Firebase Analytics ✅ Archive ✅ Sleep Mode ✅ Morning Gate ✅
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

**2026-05-31 - Codex**
- **Four pending product specs shipped**: Connect the Dots wake-up game, medicine streak badges, habit history calendar, and the Profile-accessible Settings screen.
- **Connect the Dots** joins the daily wake-up rotation with seeded 1→8 drag progression, haptics, persistent connected lines, and no fail state.
- **Computed adherence surfaces**: medicine cards now show consecutive fully-taken day streaks, while habit cards expose a read-only monthly calendar with full, partial, and missed states from existing logs.
- **Settings screen**: Mode Tidur link, live accessibility status, persisted language preference, and About/version details. Locale wiring remains intentionally deferred.
- **Verified:** targeted and full `dart analyze` report no errors; only existing info-level notices remain.

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

## Pending Task — Flow Free Connect the Dots (rewrite Game 5)

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
Scaffold → CustomScrollView
  SliverAppBar(pinned, title: 'History')
  SliverToBoxAdapter → _CalendarStrip (horizontal 4-week scroll, today highlighted)
  SliverList → activity feed items (newest first, filtered to selected day)
```

### `_CalendarStrip`

Horizontal `ListView` of the past 28 days + today. Each day = 48×56 column:
- Day letter (M T W T F S S) — 11pt _grey
- Day number — 15pt bold white
- Activity dot (8px circle) below: habitsColor if any habit done, medicineColor if any medicine taken, waterColor if any water logged, transparent if nothing
- Selected day: white background, dark text

Tapping a day filters the feed below to that day. Default = today.

### Feed items

For the selected day, collect:

**Medicine:** for each `MedicineLog` where `takenAt` is on that day and `status == 'taken'`:
```
Row: pink dot | "Took [medicine name]" | time (HH:mm)
```

**Habits:** for each `HabitLog` where `date == dateStr`:
```
Row: purple dot | "[emoji] [habit name]" | "completed"
```

**Water:** for each `WaterLog` where date matches:
```
Row: blue dot | "Drank [Xml] of water" | time (if available) or just "logged"
```

Sort all feed items by time (descending). If nothing: empty state "Nothing logged on this day."

### Settings entry

In `settings_screen.dart`, add a card at the top (above Sleep Mode):

```dart
Card(
  child: ListTile(
    leading: Icon(Icons.history_rounded, color: AppTheme.habitsColor),
    title: Text('History'),
    subtitle: Text('Activity log across all features'),
    trailing: Icon(Icons.chevron_right_rounded),
    onTap: () => context.push('/history'),
  ),
)
```

### What NOT to do
- No new Hive boxes — read directly from existing `medicine_logs`, `habit_logs`, `water_logs` boxes
- Do not modify existing data models
- Keep it read-only — no actions in the feed

---

## Pending Task — English as default language

**File:** `lib/features/settings/data/language_service.dart` only.

Change the fallback so the app defaults to English on first launch instead of mirroring the device locale.

```dart
// before
static String get current =>
    box.get(_key) ?? _normalize(PlatformDispatcher.instance.locale.languageCode);

// after
static String get current => box.get(_key) ?? 'en';
```

Remove the unused `PlatformDispatcher` import from `dart:ui` if `_normalize` no longer references it (check — `_normalize` is still used by `setLanguage`, so keep the import only if needed elsewhere; otherwise remove).

That's the only change. `initialize()` will then persist 'en' on first launch. Users can switch to Indonesian in Settings → Language.

### What NOT to do
- Do not touch `app.dart`, `app_en.arb`, `app_id.arb`, or any other file
- Do not change the `_normalize` function — it's still used by `setLanguage`

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
