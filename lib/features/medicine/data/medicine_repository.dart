import 'package:hive_flutter/hive_flutter.dart';
import 'medicine_model.dart';

class MedicineRepository {
  Box<Medicine> get _medicines => Hive.box<Medicine>('medicines');
  Box<MedicineLog> get _logs => Hive.box<MedicineLog>('medicine_logs');

  List<Medicine> getAll() =>
      _medicines.values.where((m) => m.isActive).toList();

  Medicine? getById(String id) => _medicines.get(id);

  Future<void> save(Medicine medicine) =>
      _medicines.put(medicine.id, medicine);

  Future<void> delete(String id) => _medicines.delete(id);

  List<MedicineLog> getLogsForDate(String date) => _logs.values
      .where((l) =>
          l.scheduledTime.toIso8601String().startsWith(date))
      .toList();

  Future<void> saveLog(MedicineLog log) =>
      _logs.add(log);
}
