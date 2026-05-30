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
    medicine.isActive = false;
    await medicine.save();
  }

  Future<void> unarchive(String id) async {
    final medicine = _medicines.get(id);
    if (medicine == null) return;
    medicine.isActive = true;
    await medicine.save();
  }

  Medicine? getById(String id) => _medicines.get(id);

  Future<void> save(Medicine medicine) =>
      _medicines.put(medicine.id, medicine);

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

  Future<void> saveLog(MedicineLog log) =>
      _logs.add(log);

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

  Future<void> setTaken(
      String medicineId, DateTime scheduled, bool taken) async {
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
}
