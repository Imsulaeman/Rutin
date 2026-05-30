import 'package:hive_flutter/hive_flutter.dart';

part 'medicine_model.g.dart';

class MedicineMealTiming {
  static const bebas = 'bebas';
  static const sebelumMakan = 'sebelum_makan';
  static const sesudahMakan = 'sesudah_makan';
  static const saatMakan = 'saat_makan';

  static const values = [
    bebas,
    sebelumMakan,
    sesudahMakan,
    saatMakan,
  ];

  static String label(String value) {
    switch (value) {
      case sebelumMakan:
        return 'Sebelum makan';
      case sesudahMakan:
        return 'Sesudah makan';
      case saatMakan:
        return 'Saat makan';
      case bebas:
      default:
        return 'Bebas';
    }
  }
}

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

  @HiveField(6)
  late String mealTimingKey;
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
