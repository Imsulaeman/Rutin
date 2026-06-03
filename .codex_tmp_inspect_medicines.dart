import 'dart:io';
import 'package:hive/hive.dart';
import 'lib/features/medicine/data/medicine_model.dart';

Future<void> main() async {
  final src = File(r'C:\Users\Ilham4\AppData\Local\Temp\rutin_medicines.hive');
  final dir = Directory.systemTemp.createTempSync('rutin_hive_inspect_');
  final dst = File('${dir.path}\\medicines.hive');
  await src.copy(dst.path);
  Hive.init(dir.path);
  Hive.registerAdapter(MedicineAdapter());
  final box = await Hive.openBox<Medicine>('medicines');
  for (final key in box.keys) {
    final m = box.get(key)!;
    print('key=$key id=${m.id} name=${m.name} isActive=${m.isActive} times=${m.scheduleTimes}');
  }
  await box.close();
}
