import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/utils/date_utils.dart' show AppDateUtils;
import 'habit_model.dart';

class HabitRepository {
  Box<Habit> get _habits => Hive.box<Habit>('habits');
  Box<HabitLog> get _logs => Hive.box<HabitLog>('habit_logs');

  List<Habit> getAll() => _habits.values.toList();

  Future<void> save(Habit habit) => _habits.put(habit.id, habit);

  Future<void> delete(String id) => _habits.delete(id);

  bool isCompletedToday(String habitId) {
    final today = AppDateUtils.todayString();
    return _logs.values.any((l) => l.habitId == habitId && l.date == today);
  }

  Future<void> markDone(String habitId) async {
    if (!isCompletedToday(habitId)) {
      await _logs.add(HabitLog()
        ..habitId = habitId
        ..date = AppDateUtils.todayString());
    }
  }

  int getStreak(String habitId) {
    final logs = _logs.values
        .where((l) => l.habitId == habitId)
        .map((l) => l.date)
        .toSet();
    int streak = 0;
    var day = DateTime.now();
    while (logs.contains(AppDateUtils.toDateString(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
