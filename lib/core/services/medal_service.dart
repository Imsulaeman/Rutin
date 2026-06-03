import 'dart:math' as math;

import 'package:hive_flutter/hive_flutter.dart';

import '../../features/habits/data/habit_repository.dart';
import '../../features/medicine/data/medicine_repository.dart';
import '../../features/water/data/water_model.dart';
import '../utils/date_utils.dart';

class MedalService {
  static Box<String> get _box => Hive.box<String>('app_settings');

  // ─── Public read ──────────────────────────────────────────────────────────

  static int getPr(String key) =>
      int.tryParse(_box.get('medal_${key}_pr') ?? '0') ?? 0;

  static String? getBestDate(String key) => _box.get('medal_${key}_best_date');

  // ─── Live current streak (for display) ───────────────────────────────────

  static int waterStreak() {
    final logs = Hive.box<WaterLog>('water_logs');
    final goalBox = Hive.box<WaterGoal>('water_goals');
    if (goalBox.isEmpty) return 0;
    final target = goalBox.values.first.dailyTargetMl;
    int streak = 0;
    for (var i = 0; i <= 365; i++) {
      final day = DateTime.now().subtract(Duration(days: i));
      final dateKey = AppDateUtils.toDateString(day);
      final total = logs.values
          .where((l) => l.date == dateKey)
          .fold(0, (sum, l) => sum + l.mlLogged);
      if (total >= target) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  static int medicineStreak() {
    final repo = MedicineRepository();
    final medicines = repo.getAll();
    if (medicines.isEmpty) return 0;
    return medicines
        .map((m) => repo.getMedicineStreak(m.id))
        .fold(0, math.max);
  }

  static int habitStreak() {
    final repo = HabitRepository();
    final habits = repo.getAll();
    if (habits.isEmpty) return 0;
    return habits.map((h) => repo.getStreak(h.id)).fold(0, math.max);
  }

  // ─── Check and update PR ──────────────────────────────────────────────────

  static void checkWater(int currentMl, int goalMl) {
    if (currentMl < goalMl) return;
    _updatePr('water', waterStreak());
  }

  static void checkMedicine() => _updatePr('medicine', medicineStreak());

  static void checkHabit() => _updatePr('habit', habitStreak());

  // ─── Private ──────────────────────────────────────────────────────────────

  static void _updatePr(String key, int streak) {
    if (streak <= getPr(key)) return;
    _box.put('medal_${key}_pr', '$streak');
    _box.put(
      'medal_${key}_best_date',
      DateTime.now().toIso8601String().substring(0, 10),
    );
  }
}
