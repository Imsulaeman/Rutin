import 'package:hive_flutter/hive_flutter.dart';

part 'water_model.g.dart';

@HiveType(typeId: 2)
class WaterGoal extends HiveObject {
  @HiveField(2)
  late int startTimeMinutes; // default: 420 (7 AM)

  @HiveField(3)
  late int endTimeMinutes; // default: 1320 (10 PM)

  @HiveField(4)
  bool reminderActive = false;

  @HiveField(5)
  int dailyTargetMl = 2500; // WHO midpoint for adults in hot climate

  @HiveField(6)
  int glassSizeMl = 250; // standard glass

  // Computed — not stored
  int get goalGlasses => (dailyTargetMl / glassSizeMl).ceil();

  // Spread reminders evenly across active window; clamp 15–240 min
  int get reminderIntervalMinutes {
    final windowMinutes = endTimeMinutes - startTimeMinutes;
    final glasses = goalGlasses;
    if (glasses <= 0 || windowMinutes <= 0) return 120;
    return (windowMinutes / glasses).floor().clamp(15, 240);
  }
}

@HiveType(typeId: 3)
class WaterLog extends HiveObject {
  @HiveField(0)
  late String date; // "2026-05-25"

  @HiveField(1)
  late int glassesLogged;
}
