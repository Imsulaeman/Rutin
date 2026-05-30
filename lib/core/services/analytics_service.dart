import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final _a = FirebaseAnalytics.instance;

  // Medicine
  static Future<void> medicineTaken(String name) =>
      _log('medicine_taken', {'medicine': name});

  static Future<void> medicineAdded() => _log('medicine_added');

  static Future<void> medicineArchived() => _log('medicine_archived');

  static Future<void> medicineDeleted() => _log('medicine_deleted');

  // Habits
  static Future<void> habitCompleted(String name) =>
      _log('habit_completed', {'habit': name});

  static Future<void> habitAdded() => _log('habit_added');

  // Water
  static Future<void> waterAdded(int ml) =>
      _log('water_added', {'ml': ml});

  static Future<void> _log(String name,
      [Map<String, Object>? parameters]) async {
    try {
      await _a.logEvent(name: name, parameters: parameters);
    } catch (_) {
      // Never crash the app over analytics
    }
  }
}
