import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../main.dart';

class NotificationService {
  static const String _channelId = 'medicine_reminder';
  static const String _channelName = 'Pengingat Obat';
  static bool _initialized = false;

  static Future<void> showMedicineReminder({
    required int alarmId,
    required String medicineName,
    String? dosage,
  }) async {
    await _ensureInitialized();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        ongoing: true,
        autoCancel: false,
        actions: const [
          AndroidNotificationAction(
            'taken',
            'Sudah diminum',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'snooze',
            'Tunda 1 menit',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      alarmId,
      'Waktunya minum obat',
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
