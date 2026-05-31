import 'package:flutter/services.dart';

import '../data/habit_model.dart';

class HabitReminderService {
  static const _channel = MethodChannel('habit_app/native_reminder');

  // Eleven low bits are needed to represent every minute in a 24-hour day.
  static int _alarmId(String habitId, int minutes) =>
      (_stableHash(habitId) & 0x7FFFF800) | (minutes & 0x7FF);

  static int _stableHash(String habitId) {
    var hash = 0;
    for (final c in habitId.codeUnits) {
      hash = (hash * 31 + c) & 0x7FFFFFFF;
    }
    return hash;
  }

  static int _legacyAlarmId(String habitId) =>
      _stableHash(habitId) % 500000 + 200000;

  static List<int> _times(Habit habit) => habit.reminderTimes.isNotEmpty
      ? habit.reminderTimes
      : (habit.reminderMinutes != null ? [habit.reminderMinutes!] : <int>[]);

  static int _nextTriggerMs(int minutes) {
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      minutes ~/ 60,
      minutes % 60,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled.millisecondsSinceEpoch;
  }

  static Future<void> scheduleAll(Habit habit) async {
    for (final minutes in _times(habit)) {
      await _channel.invokeMethod('scheduleHabitAlarm', {
        'notifId': _alarmId(habit.id, minutes),
        'triggerMs': _nextTriggerMs(minutes),
        'title': '${habit.emoji} ${habit.name}',
      });
    }
  }

  static Future<void> cancelAll(Habit habit) async {
    for (final minutes in _times(habit)) {
      await _channel.invokeMethod('cancelHabitAlarm', {
        'notifId': _alarmId(habit.id, minutes),
      });
    }
    await _channel.invokeMethod('cancelHabitAlarm', {
      'notifId': _legacyAlarmId(habit.id),
    });
  }
}
