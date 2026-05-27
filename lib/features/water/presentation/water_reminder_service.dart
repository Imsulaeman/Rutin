import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';

import '../data/water_model.dart';
import '../water_reminder_callback.dart';

class WaterReminderService {
  static Future<void> schedule(WaterGoal goal) async {
    final effectiveInterval = kDebugMode ? 1 : goal.reminderIntervalMinutes;
    await AndroidAlarmManager.oneShot(
      Duration(minutes: effectiveInterval),
      waterAlarmId,
      waterAlarmCallback,
      exact: true,
      wakeup: true,
    );
  }

  static Future<void> cancel() async {
    await AndroidAlarmManager.cancel(waterAlarmId);
  }
}
