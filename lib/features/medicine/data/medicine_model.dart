import 'package:hive_flutter/hive_flutter.dart';

part 'medicine_model.g.dart';

@HiveType(typeId: 0)
class Medicine extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  String? dosage;

  @HiveField(3)
  late List<int> scheduleTimes; // minutes since midnight

  @HiveField(4)
  late bool isActive;

  @HiveField(5)
  late int colorValue;
}

@HiveType(typeId: 1)
class MedicineLog extends HiveObject {
  @HiveField(0)
  late String medicineId;

  @HiveField(1)
  late DateTime scheduledTime;

  @HiveField(2)
  DateTime? takenAt;

  // 'taken' | 'missed' | 'snoozed' | 'pending'
  @HiveField(3)
  late String status;
}
