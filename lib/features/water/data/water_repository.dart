import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/utils/date_utils.dart' show AppDateUtils;
import 'water_model.dart';

class WaterRepository {
  Box<WaterGoal> get _goals => Hive.box<WaterGoal>('water_goals');
  Box<WaterLog> get _logs => Hive.box<WaterLog>('water_logs');

  WaterGoal getGoal() {
    if (_goals.isEmpty) {
      final goal = WaterGoal()
        ..startTimeMinutes = 420
        ..endTimeMinutes = 1320
        ..dailyTargetMl = 2500
        ..glassSizeMl = 250;
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

  int getTodayMl() => getTodayLog()?.mlLogged ?? 0;

  Future<void> addMl(int amount) async {
    final log = getTodayLog();
    if (log != null) {
      log.mlLogged += amount;
      await log.save();
    } else {
      await _logs.add(WaterLog()
        ..date = AppDateUtils.todayString()
        ..mlLogged = amount);
    }
  }

  Future<void> removeMl(int amount) async {
    final log = getTodayLog();
    if (log != null && log.mlLogged > 0) {
      log.mlLogged = (log.mlLogged - amount).clamp(0, log.mlLogged);
      await log.save();
    }
  }
}
