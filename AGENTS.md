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
SleepModeService (foreground) polls every 5 min → 3-case sleep detection
  → sets sleep_active=true in SharedPrefs

ACTION_USER_PRESENT → WakeUpTriggerReceiver
  → checks sleep_active + wake window (or test_trigger to bypass)
  → starts MainActivity with route="/morning-gate"

MainActivity.onNewIntent → MethodChannel("rutin/sleep").invokeMethod("launchGame")
  → _LaunchGameListener in app.dart pushes /morning-gate

/morning-gate: compact header + medicine/habits dashboard + slide-to-unlock
  → slide 85% → pushes /wakeup-game (daily seed: Sequence or Piano Tiles)
  → game complete → both screens pop

RutinAccessibilityService: if game_active && user leaves app → re-launch MainActivity with route="/morning-gate"
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

## Pending Task — Habit Multi-Completion (per-reminder check-off)

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
