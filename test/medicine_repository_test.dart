import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:habit_app/features/medicine/data/medicine_model.dart';
import 'package:habit_app/features/medicine/data/medicine_repository.dart';

void main() {
  late Directory tempDir;
  late MedicineRepository repo;

  setUpAll(() {
    Hive
      ..registerAdapter(MedicineAdapter())
      ..registerAdapter(MedicineLogAdapter());
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('medicine_repo_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<Medicine>('medicines');
    await Hive.openBox<MedicineLog>('medicine_logs');
    repo = MedicineRepository();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('isTaken is true only for exact matching taken log', () async {
    final medicine = Medicine()
      ..id = 'med-1'
      ..name = 'Rifampicin'
      ..scheduleTimes = [480]
      ..isActive = true
      ..colorValue = 0
      ..mealTimingKey = MedicineMealTiming.bebas;
    await Hive.box<Medicine>('medicines').put(medicine.id, medicine);

    final scheduled = DateTime(2026, 6, 3, 8, 0);
    await Hive.box<MedicineLog>('medicine_logs').add(
      MedicineLog()
        ..medicineId = medicine.id
        ..scheduledTime = scheduled
        ..takenAt = DateTime(2026, 6, 3, 8, 2)
        ..status = 'taken',
    );

    expect(repo.isTaken(medicine.id, scheduled), isTrue);
    expect(repo.isTaken(medicine.id, scheduled.add(const Duration(minutes: 1))), isFalse);
  });

  test('isTaken is false for missed status and missing log', () async {
    final medicine = Medicine()
      ..id = 'med-2'
      ..name = 'Isoniazid'
      ..scheduleTimes = [1260]
      ..isActive = true
      ..colorValue = 0
      ..mealTimingKey = MedicineMealTiming.bebas;
    await Hive.box<Medicine>('medicines').put(medicine.id, medicine);

    final scheduled = DateTime(2026, 6, 3, 21, 0);
    await Hive.box<MedicineLog>('medicine_logs').add(
      MedicineLog()
        ..medicineId = medicine.id
        ..scheduledTime = scheduled
        ..status = 'missed',
    );

    expect(repo.isTaken(medicine.id, scheduled), isFalse);
    expect(repo.isTaken(medicine.id, scheduled.add(const Duration(days: 1))), isFalse);
  });

  test('finalizeMissedDoses backfills only past missing doses and skips duplicates', () async {
    final createdAt = DateTime(2026, 6, 1, 9, 0);
    final medicine = Medicine()
      ..id = createdAt.millisecondsSinceEpoch.toString()
      ..name = 'Ethambutol'
      ..scheduleTimes = [480, 1260]
      ..isActive = true
      ..colorValue = 0
      ..mealTimingKey = MedicineMealTiming.bebas;
    await Hive.box<Medicine>('medicines').put(medicine.id, medicine);

    await Hive.box<MedicineLog>('medicine_logs').add(
      MedicineLog()
        ..medicineId = medicine.id
        ..scheduledTime = DateTime(2026, 6, 1, 21, 0)
        ..status = 'taken'
        ..takenAt = DateTime(2026, 6, 1, 21, 5),
    );

    final added = await repo.finalizeMissedDoses(
      now: DateTime(2026, 6, 3, 12, 0),
    );

    expect(added, 2);

    final logs = Hive.box<MedicineLog>('medicine_logs').values.toList();
    expect(
      logs.where((log) => log.status == 'missed').map((log) => log.scheduledTime),
      containsAll(<DateTime>[
        DateTime(2026, 6, 2, 8, 0),
        DateTime(2026, 6, 2, 21, 0),
      ]),
    );
    expect(
      logs.any((log) => log.scheduledTime == DateTime(2026, 6, 1, 8, 0)),
      isFalse,
    );
    expect(
      logs.where((log) => log.scheduledTime == DateTime(2026, 6, 1, 21, 0)).length,
      1,
    );
    expect(
      logs.any((log) => log.scheduledTime == DateTime(2026, 6, 3, 8, 0)),
      isFalse,
    );
  });

  test('getMedicineStreak counts only due doses for today', () async {
    final medicine = Medicine()
      ..id = 'med-3'
      ..name = 'Pyrazinamide'
      ..scheduleTimes = [480, 1320]
      ..isActive = true
      ..colorValue = 0
      ..mealTimingKey = MedicineMealTiming.bebas;
    await Hive.box<Medicine>('medicines').put(medicine.id, medicine);

    final now = DateTime.now();
    final todayMorning = DateTime(now.year, now.month, now.day, 8, 0);
    final yesterdayMorning = todayMorning.subtract(const Duration(days: 1));
    final yesterdayNight = DateTime(now.year, now.month, now.day - 1, 22, 0);

    await Hive.box<MedicineLog>('medicine_logs').addAll([
      MedicineLog()
        ..medicineId = medicine.id
        ..scheduledTime = todayMorning
        ..status = 'taken'
        ..takenAt = todayMorning.add(const Duration(minutes: 3)),
      MedicineLog()
        ..medicineId = medicine.id
        ..scheduledTime = yesterdayMorning
        ..status = 'taken'
        ..takenAt = yesterdayMorning.add(const Duration(minutes: 2)),
      MedicineLog()
        ..medicineId = medicine.id
        ..scheduledTime = yesterdayNight
        ..status = 'taken'
        ..takenAt = yesterdayNight.add(const Duration(minutes: 4)),
    ]);

    final streak = repo.getMedicineStreak(medicine.id);
    final nowMin = now.hour * 60 + now.minute;

    if (nowMin < 480) {
      expect(streak, 1);
    } else if (nowMin < 1320) {
      expect(streak, 2);
    } else {
      expect(streak, 0);
    }
  });
}
