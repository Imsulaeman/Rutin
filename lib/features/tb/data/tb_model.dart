import 'package:hive_flutter/hive_flutter.dart';

part 'tb_model.g.dart';

@HiveType(typeId: 8)
class TBTreatmentProfile extends HiveObject {
  @HiveField(0)
  late DateTime startDate;

  @HiveField(1)
  late int durationDays; // 180 = standard 6 months

  @HiveField(2)
  late String medicineId;

  @HiveField(3)
  late bool isActive;

  @HiveField(4)
  String conditionName = 'TB';
}
