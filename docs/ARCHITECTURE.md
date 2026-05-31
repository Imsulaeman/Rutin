# Architecture

## Tech Stack

| Layer | Package | Why |
|---|---|---|
| Framework | Flutter 3.44 | Cross-platform, great UI, strong Android support |
| State | flutter_riverpod | Simple, beginner-friendly, no boilerplate |
| Storage | hive + hive_flutter | Fast local DB, works fully offline, no SQL needed |
| Notifications | flutter_local_notifications | Rich Android notifications, full-screen intent |
| Alarms | android_alarm_manager_plus | Reliable background alarms (survives app close) |
| Navigation | go_router | Simple, declarative routing |
| Wake-up lock | AccessibilityService (native Android) | Detect home button press, return to routine screen |
| PDF reports | pdf + printing | Generate medicine adherence report for doctor |
| Localization | flutter_localizations + intl | Bahasa Indonesia default, English secondary |

## Folder Structure

```
lib/
├── main.dart                   # Entry point, Hive init, notification setup
├── app.dart                    # App widget, router, theme
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart  # Snooze duration, water goal defaults, etc.
│   ├── theme/
│   │   └── app_theme.dart      # Colors, typography, spacing
│   └── utils/
│       └── date_utils.dart     # Helper functions for date/time
│
├── features/
│   ├── medicine/
│   │   ├── data/
│   │   │   ├── medicine_model.dart
│   │   │   └── medicine_repository.dart
│   │   └── presentation/
│   │       ├── medicine_list_screen.dart
│   │       ├── add_medicine_screen.dart
│   │       └── medicine_card.dart
│   │
│   ├── water/
│   │   ├── data/
│   │   │   ├── water_model.dart
│   │   │   └── water_repository.dart
│   │   └── presentation/
│   │       ├── water_screen.dart
│   │       └── water_progress_widget.dart
│   │
│   ├── habits/
│   │   ├── data/
│   │   │   ├── habit_model.dart
│   │   │   └── habit_repository.dart
│   │   └── presentation/
│   │       ├── habits_screen.dart
│   │       └── habit_card.dart
│   │
│   ├── notifications/
│   │   ├── notification_service.dart   # Core notification logic
│   │   ├── alarm_service.dart          # Persistent re-notification engine
│   │   └── notification_handler.dart   # Handle "Taken" / "Snooze" actions
│   │
│   └── home/
│       └── presentation/
│           └── home_screen.dart        # Today view — all items combined
│
└── shared/
    ├── widgets/
    │   ├── streak_badge.dart
    │   └── section_header.dart
    └── providers/
        └── providers.dart              # All Riverpod providers
```

## Data Models

### Medicine
```dart
@HiveType(typeId: 0)
class Medicine {
  String id;
  String name;
  String? dosage;         // "500mg", "1 tablet", etc.
  List<int> scheduleTimes; // minutes since midnight, e.g. [360] = 6:00 AM
  bool isActive;
  int colorValue;
}
```

### MedicineLog
```dart
@HiveType(typeId: 1)
class MedicineLog {
  String medicineId;
  DateTime scheduledTime;
  DateTime? takenAt;
  String status; // 'taken' | 'missed' | 'snoozed' | 'pending'
}
```

### WaterGoal
```dart
@HiveType(typeId: 2)
class WaterGoal {
  int dailyGoalGlasses;        // default: 8
  int reminderIntervalMinutes; // default: 120 (every 2 hours)
  int startTimeMinutes;        // default: 420 (7:00 AM)
  int endTimeMinutes;          // default: 1320 (10:00 PM)
}
```

### WaterLog
```dart
@HiveType(typeId: 3)
class WaterLog {
  String date;          // "2026-05-25"
  int glassesLogged;
}
```

### Habit
```dart
@HiveType(typeId: 4)
class Habit {
  String id;
  String name;
  String emoji;
  List<int> scheduleDays; // 1-7, Monday=1. Empty = daily
  int? reminderMinutes;   // null = no reminder
  int colorValue;
}
```

### HabitLog
```dart
@HiveType(typeId: 5)
class HabitLog {
  String habitId;
  String date; // "2026-05-25"
}
```

### Routine
```dart
@HiveType(typeId: 6)
class Routine {
  String id;
  String name;              // "Morning Routine"
  String anchorType;        // 'after_wake' | 'fixed_time'
  int? fixedTimeMinutes;    // only if anchorType = 'fixed_time'
  List<String> habitIds;    // ordered list — sequence matters
  bool isActive;
}
```

### RoutineLog
```dart
@HiveType(typeId: 7)
class RoutineLog {
  String routineId;
  String date;              // "2026-05-25"
  bool completed;           // all items done
  int completedCount;       // partial progress
}
```

### TBTreatmentProfile
```dart
@HiveType(typeId: 8)
class TBTreatmentProfile {
  DateTime startDate;
  int durationDays;         // 180 = standard 6 months, custom for MDR-TB
  String medicineId;        // links to Medicine model
  bool isActive;
}
```

### SleepSettings
```dart
@HiveType(typeId: 9)
class SleepSettings {
  int sleepModeStartMinutes;   // default: 1260 (9 PM)
  int wakeWindowStartMinutes;  // default: 300 (5 AM)
  int wakeWindowEndMinutes;    // default: 600 (10 AM)
  bool sleepModeEnabled;
  bool accessibilityGranted;
}
```

## Notification Architecture

### Language Preference

`app_settings.language` is the Flutter source of truth. First launch resolves the
phone language (`id` stays Indonesian; unsupported locales use English). Every
change is mirrored through `habit_app/native_reminder` into
`app_settings_native.language`, so native medicine, water, habit, and sleep-mode
notifications use the selected language even while Flutter is not running.

### Why two packages?
- `flutter_local_notifications` handles the UI (what you see)
- `android_alarm_manager_plus` handles the scheduling (fires even when app is closed)

### Medicine Re-notification Flow
```
6:00 AM → Alarm fires → Show full-screen notification
  ↓ (user doesn't tap "Taken")
6:10 AM → Re-notification check → Still pending? → Re-notify
  ↓ (user doesn't tap "Taken")
6:20 AM → Re-notification check → Still pending? → Re-notify
  ↓ (user taps "Taken")
→ Mark log as taken → Cancel all pending re-notifications → Done
```

### Android Permissions Required
```xml
<!-- AndroidManifest.xml -->
USE_EXACT_ALARM
SCHEDULE_EXACT_ALARM
RECEIVE_BOOT_COMPLETED    <!-- reschedule after phone restart -->
VIBRATE
USE_FULL_SCREEN_INTENT    <!-- alarm-style notifications -->
POST_NOTIFICATIONS        <!-- Android 13+ -->
```

## Sleep Mode & Wake-up Routine Architecture

### Sleep Mode Detection

Tracks **user presence + audio state**, not screen state — notifications waking the screen don't reset the timer.

```
Mode Tidur enabled outside nightly window
  → SleepScheduleReceiver silently schedules AlarmManager for bedtime
  → no foreground service and no notification during the day

Bedtime alarm fires
  → SleepModeService starts as foreground service
  → "Mode tidur aktif" notification appears

Signals monitored:
  ACTION_USER_PRESENT        → user unlocked phone → reset last_interaction
  AccessibilityEvent (touch) → any tap/scroll → reset last_interaction
  AudioManager.isMusicActive → audio playback state (polled every 5 min)

Full sleep mode logic (after 9 PM):

Case 1 — Idle, no audio
  last_interaction > 60 min ago
  AND audio = false
  → sleep mode ON

Case 2 — Music timer ended (primary use case)
  audio was playing → audio stopped
  AND last_interaction > 15 min ago
  → sleep mode ON (shorter timer — already in bed)

Case 3 — Fell asleep with audio/video still playing
  audio = true
  AND last_interaction > 2h ago
  → sleep mode ON (no taps for 2h = clearly asleep)

Case 4 — Intentionally using phone late (NOT sleep)
  audio = true AND interactions happening
  → timer keeps resetting, sleep mode stays OFF
```

Why not screen state: notifications (WhatsApp, etc.) wake the screen briefly but `ACTION_USER_PRESENT` only fires on actual unlock — clean signal with no false resets.

### Manual Override

Nightly foreground notification ("Sleep mode active") includes an **"I'm still awake"** action button.
- Tapping it pauses sleep mode for 30 min
- After 30 min, detection resumes from scratch
- Prevents mis-triggers without requiring app to be opened

### Wake-up Window

Routine only fires during configurable window (default **5 AM – 10 AM**).
- Unlocking at 3 AM for bathroom → no routine trigger
- Unlocking at 6 AM → routine fires
- Window is user-adjustable in settings

### Wake-up Routine Lock Flow

```
Sleep mode active (e.g. 11 PM)
  ↓
6:15 AM — user unlocks phone within wake-up window
  ↓
User unlocks PIN → app launches Morning Gate
  ↓
Back button → disabled
Home button → AccessibilityService detects → returns to routine immediately
Recent apps → AccessibilityService detects → returns to routine immediately
  ↓
User completes all routine items (medicine ✓, water ✓, etc.)
  ↓
Routine dismissed → normal phone use resumes
```

### Graceful Degradation (Accessibility Service Denied)

If user denies Accessibility Service permission:
- Full-screen routine still launches above lockscreen ✓
- Back button still disabled ✓
- Home / recent apps → user can escape (no intercept)
- App shows one-time warning: "Grant accessibility for full lock"
- Routine still functions, just slightly less persistent

### AccessibilityService Role

Granted once during onboarding. Three jobs:
1. Intercept home/recent apps during wake-up routine → return to foreground
2. Track touch interactions for sleep mode accuracy
3. Detect app navigation during routine → pull back

### Android Background Service Survival

Required:
- `SleepScheduleReceiver` silently schedules the configured bedtime with native `AlarmManager`
- Sleep mode monitor runs as **foreground service only during the nightly window** (persistent notification: "Sleep mode active")
- `RECEIVE_BOOT_COMPLETED` → re-arm the bedtime alarm after phone reboot
- On-screen guidance during onboarding: disable battery optimization for this app

The Huawei Watch receives notifications passively from the Android phone — no special handling needed.

### Additional Permissions Required
```xml
BIND_ACCESSIBILITY_SERVICE     <!-- wake-up lock, home button intercept -->
FOREGROUND_SERVICE             <!-- sleep mode monitor survives in background -->
RECEIVE_BOOT_COMPLETED         <!-- restart after reboot -->
```

---

## Key Decisions

**Riverpod over Bloc** — Bloc is powerful but verbose. Riverpod is simpler for someone learning Flutter. Can migrate later if needed.

**Hive over SQLite** — No SQL knowledge required, pure Dart objects, fast reads. Sufficient for this app's data volume.

**android_alarm_manager_plus for medicine** — `flutter_local_notifications` alone can be killed by Android battery optimization. `android_alarm_manager_plus` registers with Android's AlarmManager directly, survives battery optimization.

**No cloud sync in Phase 1** — Adds complexity (auth, conflict resolution) for no immediate benefit. Local-first ships faster and is more reliable.
