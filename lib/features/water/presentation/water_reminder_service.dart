import 'package:flutter/services.dart';

import '../data/water_model.dart';

class WaterReminderService {
  static const _channel = MethodChannel('habit_app/native_reminder');

  static Future<void> schedule(WaterGoal goal) async {
    final intervalMs = goal.reminderIntervalMinutes * 60000;
    await _channel.invokeMethod('saveWaterSettings', {
      'startMin': goal.startTimeMinutes,
      'endMin': goal.endTimeMinutes,
      'intervalMs': intervalMs,
      'reminderActive': true,
      'debug': false,
    });
    await _channel.invokeMethod('scheduleWaterAlarm', {'delayMs': intervalMs});
  }

  static Future<void> cancel() async {
    await _channel.invokeMethod('cancelWaterAlarm');
  }

  static Future<int> getPendingLogs() async {
    return await _channel.invokeMethod<int>('getPendingWaterLogs') ?? 0;
  }
}
