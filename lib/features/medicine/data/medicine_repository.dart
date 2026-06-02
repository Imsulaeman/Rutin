import 'dart:developer' as developer;

import 'package:hive_flutter/hive_flutter.dart';
import 'medicine_model.dart';

class MedicineRepository {
  Box<Medicine> get _medicines => Hive.box<Medicine>('medicines');
  Box<MedicineLog> get _logs => Hive.box<MedicineLog>('medicine_logs');

  List<Medicine> getAll() =>
      _medicines.values.where((m) => m.isActive).toList();

  List<Medicine> getAllIncludingInactive() => _medicines.values.toList();

  Future<void> archive(String id) async {
    final medicine = _medicines.get(id);
    if (medicine == null) return;
    final archived = _copyMedicine(medicine)..isActive = false;
    await _medicines.put(id, archived);
    _debugLogState('archive($id)');
  }

  Future<void> unarchive(String id) async {
    final medicine = _medicines.get(id);
    if (medicine == null) return;
    final restored = _copyMedicine(medicine)..isActive = true;
    await _medicines.put(id, restored);
    _debugLogState('unarchive($id)');
  }

  Medicine? getById(String id) => _medicines.get(id);

  Future<void> save(Medicine medicine) => _medicines.put(medicine.id, medicine);

  Future<void> delete(String id) => _medicines.delete(id);

  List<MedicineLog> getLogsForDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return _logs.values.where((l) {
      final scheduled = l.scheduledTime;
      return scheduled.year == day.year &&
          scheduled.month == day.month &&
          scheduled.day == day.day;
    }).toList();
  }

  Future<void> saveLog(MedicineLog log) => _logs.add(log);

  Future<int> finalizeMissedDoses({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final existing = <String>{
      for (final log in _logs.values) _doseKey(log.medicineId, log.scheduledTime),
    };
    final pending = <MedicineLog>[];

    for (final medicine in _medicines.values) {
      if (medicine.scheduleTimes.isEmpty) continue;
      final createdAt = _createdAtFor(medicine);
      if (createdAt == null) continue;

      var day = DateTime(createdAt.year, createdAt.month, createdAt.day);
      while (day.isBefore(today)) {
        for (final minute in medicine.scheduleTimes) {
          final scheduled = DateTime(
            day.year,
            day.month,
            day.day,
            minute ~/ 60,
            minute % 60,
          );
          if (scheduled.isBefore(createdAt)) continue;
          final key = _doseKey(medicine.id, scheduled);
          if (existing.contains(key)) continue;
          pending.add(
            MedicineLog()
              ..medicineId = medicine.id
              ..scheduledTime = scheduled
              ..takenAt = null
              ..status = 'missed',
          );
          existing.add(key);
        }
        day = day.add(const Duration(days: 1));
      }
    }

    if (pending.isEmpty) return 0;
    await _logs.addAll(pending);
    return pending.length;
  }

  // ── Per-dose taken state ──────────────────────────────────────────────────
  // A dose is keyed by (medicineId, minute-truncated local scheduledTime).
  // The medicine list is the only writer, so this key is the single source.

  MedicineLog? findLog(String medicineId, DateTime scheduled) {
    for (final l in _logs.values) {
      if (l.medicineId == medicineId &&
          l.scheduledTime.isAtSameMomentAs(scheduled)) {
        return l;
      }
    }
    return null;
  }

  bool isTaken(String medicineId, DateTime scheduled) =>
      findLog(medicineId, scheduled)?.status == 'taken';

  bool isMissed(String medicineId, DateTime scheduled) =>
      findLog(medicineId, scheduled)?.status == 'missed';

  int getMedicineStreak(String medicineId) {
    final medicine = _medicines.get(medicineId);
    if (medicine == null || medicine.scheduleTimes.isEmpty) return 0;

    int streak = 0;
    final today = DateTime.now();
    final nowMin = today.hour * 60 + today.minute;

    for (var guard = 0; guard < 3660; guard++) {
      final day = today.subtract(Duration(days: guard));
      final isToday = guard == 0;
      bool allTaken = true;
      bool anyDue = false;

      for (final minute in medicine.scheduleTimes) {
        if (isToday && minute > nowMin) continue;
        anyDue = true;
        final scheduled = DateTime(
          day.year,
          day.month,
          day.day,
          minute ~/ 60,
          minute % 60,
        );
        if (!isTaken(medicineId, scheduled)) {
          allTaken = false;
          break;
        }
      }

      if (!anyDue) continue;
      if (!allTaken) break;
      streak++;
    }
    return streak;
  }

  Future<void> setTaken(
    String medicineId,
    DateTime scheduled,
    bool taken,
  ) async {
    final existing = findLog(medicineId, scheduled);
    if (taken) {
      if (existing != null) {
        existing
          ..status = 'taken'
          ..takenAt = DateTime.now();
        await existing.save();
      } else {
        final log = MedicineLog()
          ..medicineId = medicineId
          ..scheduledTime = scheduled
          ..takenAt = DateTime.now()
          ..status = 'taken';
        await _logs.add(log);
      }
    } else if (existing != null) {
      await existing.delete();
    }
  }

  Medicine _copyMedicine(Medicine source) {
    return Medicine()
      ..id = source.id
      ..name = source.name
      ..dosage = source.dosage
      ..scheduleTimes = List<int>.from(source.scheduleTimes)
      ..isActive = source.isActive
      ..colorValue = source.colorValue
      ..mealTimingKey = source.mealTimingKey;
  }

  DateTime? _createdAtFor(Medicine medicine) {
    final createdMs = int.tryParse(medicine.id);
    if (createdMs == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(createdMs);
  }

  String _doseKey(String medicineId, DateTime scheduled) =>
      '$medicineId|${scheduled.millisecondsSinceEpoch}';

  void _debugLogState(String reason) {
    final snapshot = _medicines.values
        .map((m) => '${m.name}:${m.id}:${m.isActive ? 'active' : 'archived'}')
        .join(' | ');
    // Temporary device-side archive diagnostics.
    developer.log(
      'MedicineRepository $reason -> $snapshot',
      name: 'archive-debug',
    );
  }
}
