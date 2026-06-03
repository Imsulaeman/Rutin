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

  static int _nextTriggerMs(int minutes, List<int> scheduleDays) {
    final now = DateTime.now();
    for (var offset = 0; offset < 8; offset++) {
      final day = now.add(Duration(days: offset));
      if (scheduleDays.isNotEmpty && !scheduleDays.contains(day.weekday)) {
        continue;
      }
      final scheduled = DateTime(
        day.year,
        day.month,
        day.day,
        minutes ~/ 60,
        minutes % 60,
      );
      if (scheduled.isAfter(now)) {
        return scheduled.millisecondsSinceEpoch;
      }
    }
    final fallback = now.add(const Duration(days: 1));
    return DateTime(
      fallback.year,
      fallback.month,
      fallback.day,
      minutes ~/ 60,
      minutes % 60,
    ).millisecondsSinceEpoch;
  }

  static Future<void> scheduleAll(Habit habit) async {
    for (final minutes in _times(habit)) {
      await _channel.invokeMethod('scheduleHabitAlarm', {
        'notifId': _alarmId(habit.id, minutes),
        'triggerMs': _nextTriggerMs(minutes, habit.scheduleDays),
        'title': '${habit.emoji} ${habit.name}',
        'scheduleDays': habit.scheduleDays,
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
