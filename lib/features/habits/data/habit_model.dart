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
  int? reminderMinutes; // null = no reminder

  @HiveField(5)
  late int colorValue;
}

@HiveType(typeId: 5)
class HabitLog extends HiveObject {
  @HiveField(0)
  late String habitId;

  @HiveField(1)
  late String date; // "2026-05-25"
}
