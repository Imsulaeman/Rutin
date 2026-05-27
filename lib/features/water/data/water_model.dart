import 'package:hive_flutter/hive_flutter.dart';

part 'water_model.g.dart';

@HiveType(typeId: 2)
class WaterGoal extends HiveObject {
  @HiveField(0)
  late int dailyGoalGlasses; // default: 8

  @HiveField(1)
  late int reminderIntervalMinutes; // default: 120

  @HiveField(2)
  late int startTimeMinutes; // default: 420 (7 AM)

  @HiveField(3)
  late int endTimeMinutes; // default: 1320 (10 PM)

  @HiveField(4)
  bool reminderActive = false;
}

@HiveType(typeId: 3)
class WaterLog extends HiveObject {
  @HiveField(0)
  late String date; // "2026-05-25"

  @HiveField(1)
  late int glassesLogged;
}
