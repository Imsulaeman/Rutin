import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../main.dart';
import '../settings/data/language_service.dart';

class NotificationService {
  static const String _channelId = 'medicine_reminder';
  static bool _initialized = false;

  static Future<void> showMedicineReminder({
    required int alarmId,
    required String medicineName,
    String? dosage,
  }) async {
    await _ensureInitialized();
    final isId = LanguageService.current == 'id';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        isId ? 'Pengingat Obat' : 'Medicine Reminder',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        ongoing: true,
        autoCancel: false,
        actions: [
          AndroidNotificationAction(
            'taken',
            isId ? 'Sudah diminum' : 'Taken',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'snooze',
            isId ? 'Tunda 1 menit' : 'Snooze 1 min',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      alarmId,
      isId ? 'Waktunya minum obat' : 'Time to take medicine',
      dosage != null ? '$medicineName - $dosage' : medicineName,
      details,
      payload: _buildPayload(
        alarmId: alarmId,
        medicineName: medicineName,
        dosage: dosage,
      ),
    );
  }

  static Future<void> cancel(int id) =>
      flutterLocalNotificationsPlugin.cancel(id);

  static Future<void> cancelAll() =>
      flutterLocalNotificationsPlugin.cancelAll();

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
    _initialized = true;
  }

  static String _buildPayload({
    required int alarmId,
    required String medicineName,
    String? dosage,
  }) {
    return dosage == null
        ? '$alarmId||$medicineName'
        : '$alarmId||$medicineName||$dosage';
  }
}
