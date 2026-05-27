# Alarm System: Technical Report

Generated: 2026-05-27  
Project: habit_app — Flutter Android medicine reminder  
Scope: Full alarm/notification pipeline analysis

---

## 1. Full System Architecture (Current)

```
Flutter (Dart)
  AlarmService.scheduleMedicineAlarm()
      │ MethodChannel "habit_app/native_reminder"
      ▼
  MainActivity.configureFlutterEngine()
      ▼
  NativeReminderScheduler.schedule()
      ▼
  AlarmManager.setExactAndAllowWhileIdle()

─── alarm fires ───────────────────────────────────

  ReminderAlarmReceiver.onReceive()
      ├─ context.startActivity(ReminderActivity) ← ❌ BLOCKED Android 10+
      └─ NativeReminderScheduler.schedule(+renotifyMinutes) ← repeats

  ReminderActivity
      ├─ "Sudah diminum" → NativeReminderScheduler.cancel()
      └─ "Tunda 1 menit" → NativeReminderScheduler.schedule(+1min)
```

---

## 2. Bug Inventory

### CRITICAL

| # | Bug | File | Line | Impact |
|---|-----|------|------|--------|
| C1 | `context.startActivity()` from BroadcastReceiver blocked on Android 10+ (API 29+). Silent failure — no crash, alarm just doesn't show. | `ReminderAlarmReceiver.kt` | 14 | App unusable on all modern devices |
| C2 | No notification ever posted. Zero fallback when device is in active use. | `ReminderAlarmReceiver.kt` | all | Reminder invisible if phone is unlocked |

### HIGH

| # | Bug | File | Line | Impact |
|---|-----|------|------|--------|
| H1 | `ReminderActivity` cancels alarm on dismiss but never cancels any notification (none exist yet, but will after C1/C2 fix). | `ReminderActivity.kt` | 52–68 | Stale notification after user interaction |
| H2 | Double scheduling in snooze: `scheduleRenotify()` AND `startRenotifyLoop()` both called. Alarm at +1 min AND another loop starting at +11 min. | `notification_handler.dart` | 55–72 | Duplicate alarms, confusing behavior |
| H3 | Non-deterministic notification ID: `DateTime.now().millisecondsSinceEpoch & 0x7fffffff`. New ID on every call means old notifications can't be cancelled by ID. | `notification_service.dart` | 43 | Notifications pile up, cancel doesn't clear them |

### MEDIUM

| # | Bug | File | Impact |
|---|-----|------|--------|
| M1 | `||` delimiter in payload not escaped. Medicine name containing `||` breaks `_parsePayload()`. | `notification_handler.dart` | Corrupt payload silently defaults to alarmId=0 |
| M2 | `onBackPressed()` deprecated API 33+. | `ReminderActivity.kt` | Works now, will break on future Android |
| M3 | `FLAG_ALLOW_LOCK_WHILE_SCREEN_ON` contradicts `FLAG_KEEP_SCREEN_ON`. | `ReminderActivity.kt` | Unpredictable screen behavior |
| M4 | Debug lock-icon button (alarmId 777002) visible in production UI. | `medicine_list_screen.dart` | Confusing to users |
| M5 | Add medicine doesn't auto-return to list; requires manual back+forward. | `medicine_list_screen.dart` | UX friction (known, from test checklist) |

### LOW

| # | Bug | File | Impact |
|---|-----|------|--------|
| L1 | `AlarmService.init()` is a no-op. Misleading. | `alarm_service.dart` | Dead code |
| L2 | No try-catch on MethodChannel calls. Silent failure if native crashes. | `alarm_service.dart` | Hard to debug |
| L3 | Unused permissions: FOREGROUND_SERVICE_HEALTH, WAKE_LOCK, REQUEST_IGNORE_BATTERY_OPTIMIZATIONS declared but nothing uses them. | `AndroidManifest.xml` | Security surface, minor |

---

## 3. Root Cause: Why the Alarm Doesn't Show

**Android 10 (API 29) introduced hard background activity start restrictions.**  
Apps cannot start Activities from a `BroadcastReceiver` when the app is not in the foreground — unless they use one of the allowed exemptions:
- Full-screen notification intent (CORRECT pattern)
- Device/companion app (not us)
- Foreground service (overkill)

The current code uses none of these. `context.startActivity()` fires, Android blocks it silently, nothing appears.

**The correct Android pattern for alarm-style interruptions:**
```
BroadcastReceiver.onReceive()
  └─ NotificationManager.notify(notification with setFullScreenIntent(ReminderActivity))
      Android decides:
        ├─ Screen OFF / locked → launches ReminderActivity as full-screen overlay
        └─ Screen ON / user active → shows notification banner; user taps → opens ReminderActivity
```

This is exactly how Clock app alarms work on Android 10+.

---

## 4. Flutter Notification System vs Native System

Two separate systems exist in this codebase:

| | Flutter (flutter_local_notifications) | Native (Kotlin) |
|---|---|---|
| **Posts notification?** | Yes (NotificationService) | No (never called) |
| **Handles tap actions?** | Yes (NotificationHandler) | Yes (ReminderActivity buttons) |
| **Called when alarm fires?** | Never | Yes (ReminderAlarmReceiver) |
| **Works when app closed?** | Only if Flutter engine boots | Yes |

The Flutter notification service (`NotificationService.showMedicineReminder`) is **never called from the alarm receiver**. It exists but is orphaned from the alarm flow. The native receiver tries to show a full Activity directly, bypassing Flutter entirely — and that's what's broken.

**Conclusion:** Keep the native path, fix it properly. Flutter notification service can be used for foreground-only nudges (water reminders, etc.) later.

---

## 5. Permissions Status

| Permission | In Manifest | Used | Notes |
|---|---|---|---|
| USE_EXACT_ALARM | ✅ | ✅ | Required for setExactAndAllowWhileIdle |
| SCHEDULE_EXACT_ALARM | ✅ | ✅ | User-grantable fallback |
| USE_FULL_SCREEN_INTENT | ✅ | ❌ | Declared but never used — this is the permission for the fix |
| POST_NOTIFICATIONS | ✅ | ✅ (via Flutter) | Required Android 13+ |
| VIBRATE | ✅ | ❌ | Declared, not used |
| RECEIVE_BOOT_COMPLETED | ✅ | ❌ | For reboot reschedule — not implemented yet |
| FOREGROUND_SERVICE | ✅ | ❌ | Declared for future sleep mode |
| WAKE_LOCK | ✅ | ❌ | Declared, not used |

`USE_FULL_SCREEN_INTENT` is already declared — the fix just needs to actually use it.

---

## 6. Test Checklist Status (from MANUAL_TEST_CHECKLIST.md)

| Test | Status | Notes |
|---|---|---|
| 0) Pre-check / permissions | ❌ partial | Permission popup never appeared |
| 1) Navigation back behavior | ✅ | Works |
| 2) Add medicine flow | ⚠️ partial | Saves but requires manual nav to see result |
| 3) Alarm trigger | ✅ | Notification appears |
| 3A) Full-screen reminder flow | ❌ | Can't tap buttons ("Sudah diminum", "Tunda") |
| 4) Re-notify every 10 min | ❓ | Not tested |
| 4A) Fast persistent test (1min) | ✅ partial | Loop works but "Sudah diminum" didn't stop it |
| 5–8 | ❓ | Not tested |

**Critical note from checklist:** "Can't tap sudah diminum dan tunda 1 menit" — this is the notification action buttons (Flutter side), NOT the ReminderActivity buttons. The ReminderActivity never shows because of bug C1.

---

## 7. Priority Fix Order

1. **C1 + C2**: Fix `ReminderAlarmReceiver.kt` — post notification with `fullScreenIntent`
2. **H1**: Fix `ReminderActivity.kt` — cancel notification on button press
3. **H3**: Fix notification ID — use `alarmId` directly as notification ID
4. **M5**: Fix add medicine → auto-return to list
5. **H2**: Fix double scheduling in snooze (Flutter handler)
6. **RECEIVE_BOOT_COMPLETED**: Implement after above are stable
