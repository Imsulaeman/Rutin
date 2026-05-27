import 'package:hive_flutter/hive_flutter.dart';

part 'routine_model.g.dart';

@HiveType(typeId: 6)
class Routine extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  // 'after_wake' | 'fixed_time'
  @HiveField(2)
  late String anchorType;

  @HiveField(3)
  int? fixedTimeMinutes;

  @HiveField(4)
  late List<String> habitIds; // ordered sequence

  @HiveField(5)
  late bool isActive;
}

@HiveType(typeId: 7)
class RoutineLog extends HiveObject {
  @HiveField(0)
  late String routineId;

  @HiveField(1)
  late String date; // "2026-05-25"

  @HiveField(2)
  late bool completed;

  @HiveField(3)
  late int completedCount;
}
