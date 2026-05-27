import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/utils/date_utils.dart' show AppDateUtils;
import 'water_model.dart';

class WaterRepository {
  Box<WaterGoal> get _goals => Hive.box<WaterGoal>('water_goals');
  Box<WaterLog> get _logs => Hive.box<WaterLog>('water_logs');

  WaterGoal getGoal() {
    if (_goals.isEmpty) {
      final goal = WaterGoal()
        ..dailyGoalGlasses = 8
        ..reminderIntervalMinutes = 120
        ..startTimeMinutes = 420
        ..endTimeMinutes = 1320;
      _goals.add(goal);
      return goal;
    }
    return _goals.values.first;
  }

  Future<void> saveGoal(WaterGoal goal) => _goals.put(0, goal);

  WaterLog? getTodayLog() {
    final today = AppDateUtils.todayString();
    return _logs.values.cast<WaterLog?>().firstWhere(
      (l) => l?.date == today,
      orElse: () => null,
    );
  }

  Future<void> logGlass() async {
    final today = AppDateUtils.todayString();
    final existing = _logs.values
        .toList()
        .asMap()
        .entries
        .cast<MapEntry<int, WaterLog>?>()
        .firstWhere(
          (e) => e?.value.date == today,
          orElse: () => null,
        );
    if (existing != null) {
      existing.value.glassesLogged++;
      await existing.value.save();
    } else {
      await _logs.add(WaterLog()
        ..date = today
        ..glassesLogged = 1);
    }
  }
}
