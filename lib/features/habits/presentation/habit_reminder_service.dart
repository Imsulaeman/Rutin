import 'package:flutter/services.dart';

import '../data/habit_model.dart';

class HabitReminderService {
  static const _channel = MethodChannel('habit_app/native_reminder');

  static int _notifId(String habitId) {
    var hash = 0;
    for (final c in habitId.codeUnits) {
      hash = (hash * 31 + c) & 0x7FFFFFFF;
    }
    return hash % 500000 + 200000;
  }

  static Future<void> schedule(Habit habit) async {
    final minutes = habit.reminderMinutes;
    if (minutes == null) return;
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, h, m);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _channel.invokeMethod('scheduleHabitAlarm', {
      'notifId': _notifId(habit.id),
      'triggerMs': scheduled.millisecondsSinceEpoch,
      'title': '${habit.emoji} ${habit.name}',
    });
  }

  static Future<void> cancel(String habitId) async {
    await _channel.invokeMethod('cancelHabitAlarm', {
      'notifId': _notifId(habitId),
    });
  }
}
