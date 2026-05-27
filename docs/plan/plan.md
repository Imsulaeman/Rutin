# Implementation Plan: Fix Alarm System

Generated: 2026-05-27  
For: Codex or next implementation agent  
Read `report.md` first for full context.

---

## Goal

Make the medicine alarm reliably:
1. Fire at the scheduled time
2. Show the full-screen `ReminderActivity` on ALL Android versions (10+)
3. Fall back to a notification banner if device is in active use
4. Cancel correctly when user taps "Sudah diminum" or "Tunda"
5. Repeat every configured interval until dismissed

---

## Files to Modify

| File | Change Summary |
|---|---|
| `android/app/src/main/kotlin/com/ilham/habit_app/ReminderAlarmReceiver.kt` | Replace `startActivity()` with notification + fullScreenIntent |
| `android/app/src/main/kotlin/com/ilham/habit_app/ReminderActivity.kt` | Add notification cancel on button press; fix window flags |
| `lib/features/notifications/notification_service.dart` | Fix notification ID (use alarmId, not timestamp) |
| `lib/features/notifications/notification_handler.dart` | Fix double scheduling in snooze |
| `lib/features/medicine/presentation/add_medicine_screen.dart` | Fix post-save navigation |

---

## Fix 1 — ReminderAlarmReceiver.kt (CRITICAL)

**Replace the entire `onReceive()` body.**

Remove:
```kotlin
val activityIntent = Intent(context, ReminderActivity::class.java).apply {
    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
    putExtra("alarm_id", alarmId)
    putExtra("medicine_name", medicineName)
    putExtra("dosage", dosage)
    putExtra("renotify_minutes", renotifyMinutes)
}
context.startActivity(activityIntent)
```

Replace with:
```kotlin
showFullScreenNotification(context, alarmId, medicineName, dosage, renotifyMinutes)
```

Add new private method `showFullScreenNotification()`:

```kotlin
private fun showFullScreenNotification(
    context: Context,
    alarmId: Int,
    medicineName: String,
    dosage: String?,
    renotifyMinutes: Int
) {
    val channelId = "medicine_alarm"
    val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    // Create channel (idempotent, safe to call every time)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        val channel = NotificationChannel(
            channelId,
            "Pengingat Obat",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Alarm minum obat"
            setBypassDnd(true)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        nm.createNotificationChannel(channel)
    }

    // PendingIntent → ReminderActivity
    val activityIntent = Intent(context, ReminderActivity::class.java).apply {
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        putExtra("alarm_id", alarmId)
        putExtra("medicine_name", medicineName)
        putExtra("dosage", dosage)
        putExtra("renotify_minutes", renotifyMinutes)
    }
    val fullScreenPi = PendingIntent.getActivity(
        context,
        alarmId,
        activityIntent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )

    val body = if (!dosage.isNullOrEmpty()) "$medicineName – $dosage" else medicineName

    val notification = NotificationCompat.Builder(context, channelId)
        .setSmallIcon(R.mipmap.ic_launcher)
        .setContentTitle("Waktunya minum obat")
        .setContentText(body)
        .setPriority(NotificationCompat.PRIORITY_MAX)
        .setCategory(NotificationCompat.CATEGORY_ALARM)
        .setFullScreenIntent(fullScreenPi, true)
        .setOngoing(true)
        .setAutoCancel(false)
        .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
        .build()

    nm.notify(alarmId, notification)
}
```

**Required imports for ReminderAlarmReceiver.kt:**
```kotlin
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.ilham.habit_app.R
```

**Keep the renotify reschedule at the bottom of onReceive() — that logic is correct.**

---

## Fix 2 — ReminderActivity.kt (HIGH)

**Add notification cancellation to both button handlers.**

In `takenButton.setOnClickListener`:
```kotlin
setOnClickListener {
    val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    nm.cancel(alarmId)                           // ← ADD THIS
    NativeReminderScheduler.cancel(this@ReminderActivity, alarmId)
    finish()
}
```

In `snoozeButton.setOnClickListener`:
```kotlin
setOnClickListener {
    val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    nm.cancel(alarmId)                           // ← ADD THIS
    val trigger = System.currentTimeMillis() + 60_000L
    NativeReminderScheduler.schedule(
        context = this@ReminderActivity,
        alarmId = alarmId,
        triggerAtMillis = trigger,
        medicineName = medicineName,
        dosage = if (dosage.isEmpty()) null else dosage,
        renotifyMinutes = renotifyMinutes
    )
    finish()
}
```

**Fix window flags** — remove the contradictory flag:
```kotlin
// REMOVE this line:
android.view.WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON
// KEEP:
android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
```

**Required import:**
```kotlin
import android.app.NotificationManager
```

---

## Fix 3 — notification_service.dart (HIGH)

**Use `alarmId` as the notification ID instead of a timestamp.**

Current:
```dart
final notificationId = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
await flutterLocalNotificationsPlugin.show(
  notificationId,
  ...
);
```

Replace with:
```dart
await flutterLocalNotificationsPlugin.show(
  alarmId,   // use alarmId directly as notification ID
  ...
);
```

---

## Fix 4 — notification_handler.dart (HIGH)

**Fix double scheduling in snooze.** Remove `startRenotifyLoop()` call — the native receiver already reschedules automatically.

Replace `handleSnooze()` with:

```dart
static Future<void> handleSnooze(
  int notificationId, {
  required String medicineName,
  String? dosage,
}) async {
  await AlarmService.cancelAllForAlarm(notificationId);
  await NotificationService.cancelAll();

  await AlarmService.scheduleRenotify(
    alarmId: notificationId,
    delay: const Duration(minutes: AppConstants.snoozeMinutes),
    medicineName: medicineName,
    dosage: dosage,
    renotifyMinutes: AppConstants.renotifyIntervalMinutes,
  );
}
```

---

## Fix 5 — add_medicine_screen.dart (MEDIUM)

After saving, replace:
```dart
context.pop()
```
with:
```dart
context.go('/medicine')
```

---

## AndroidManifest.xml — No Changes Needed

`USE_FULL_SCREEN_INTENT`, `ReminderActivity` with `showWhenLocked`/`turnScreenOn`, and `ReminderAlarmReceiver` are all already declared correctly.

---

## build.gradle.kts — No Changes Needed

`NotificationCompat` comes from `androidx.core` which is a transitive Flutter dependency. No explicit `implementation` line needed.

---

## Verification Steps

Test on physical device after implementing:

### Test A — Screen OFF
1. Add medicine with time = now + 30 seconds
2. Lock screen, wait
3. Expected: `ReminderActivity` opens above lock screen
4. Tap "Sudah diminum" → closes, no notification remains, no repeat

### Test B — Screen ON / app in background
1. Add medicine with time = now + 30 seconds
2. Go to home screen, wait
3. Expected: notification banner appears
4. Tap banner → `ReminderActivity` opens
5. Tap "Tunda 1 menit" → closes, notification gone, reappears in ~1 min

### Test C — Loop stops on "Sudah diminum"
1. Trigger alarm, tap "Sudah diminum"
2. Wait 15+ minutes
3. Expected: no further notifications

### Test D — Loop repeats when ignored
1. Trigger alarm, ignore it
2. Wait renotifyIntervalMinutes (10 min prod / 1 min debug)
3. Expected: notification reappears

---

## Out of Scope (Do Not Touch)

- RECEIVE_BOOT_COMPLETED — separate task
- Flutter notification action buttons — orphaned from alarm flow, leave as-is
- Sleep mode / Accessibility Service — Phase 2+
- Water / habits features — Phase 2+
