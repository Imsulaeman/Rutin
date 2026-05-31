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
<!-- Add new log entries above this line, newest first -->

---

## Pending Task — Home Dashboard Card Improvements

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

## Pending Task — Water Tab: Next Reminder Time

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

## Pending Task — Habit Multiple Reminder Times

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
