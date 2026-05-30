import 'package:hive_flutter/hive_flutter.dart';

part 'habit_model.g.dart';

@HiveType(typeId: 4)
class Habit extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String emoji;

  @HiveField(3)
  late List<int> scheduleDays; // 1–7, Monday=1. Empty = daily

  @HiveField(4)
  int? reminderMinutes;

  @HiveField(5)
  int colorValue = 0;

  @HiveField(6)
  String? groupId;

  @HiveField(7)
  int sortIndex = 0;
}

@HiveType(typeId: 5)
class HabitLog extends HiveObject {
  @HiveField(0)
  late String habitId;

  @HiveField(1)
  late String date; // "2026-05-25"
}

@HiveType(typeId: 11)
class HabitGroup extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  String emoji = '📋';

  @HiveField(3)
  int sortIndex = 0;
}
