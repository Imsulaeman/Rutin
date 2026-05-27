import 'package:hive_flutter/hive_flutter.dart';
import 'medal_model.dart';

class MedalRepository {
  Box<Medal> get _box => Hive.box<Medal>('medals');

  List<Medal> getAll() => _box.values.toList();

  Future<void> save(Medal medal) => _box.put(medal.id, medal);

  Future<void> delete(String id) => _box.delete(id);

  Medal? findByHabit(String name, String emoji) {
    try {
      return _box.values.firstWhere(
        (m) => m.name == name && m.emoji == emoji && m.type == 'habit',
      );
    } catch (_) {
      return null;
    }
  }
}
