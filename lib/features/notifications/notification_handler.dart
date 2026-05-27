import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../app.dart';
import '../../core/constants/app_constants.dart';
import 'alarm_service.dart';
import 'notification_service.dart';

// Handles "Sudah diminum" and "Tunda 15 menit" action taps
// Called from main.dart via onDidReceiveNotificationResponse
class NotificationHandler {
  static Future<void> handle(NotificationResponse response) async {
    final action = response.actionId;
    final notificationId = response.id;
    if (notificationId == null) return;
    final payload = _parsePayload(response.payload);
    final rootAlarmId = payload.$1;

    switch (action) {
      case 'taken':
        await handleTaken(rootAlarmId);
        return;
      case 'snooze':
        await handleSnooze(
          rootAlarmId,
          medicineName: payload.$2,
          dosage: payload.$3,
        );
        return;
      default:
        if (response.notificationResponseType ==
            NotificationResponseType.selectedNotification) {
          openReminderScreen(
            alarmId: rootAlarmId,
            medicineName: payload.$2,
            dosage: payload.$3,
          );
        }
        return;
    }
  }

  static Future<void> handleTaken(int notificationId) async {
    await AlarmService.cancelAllForAlarm(notificationId);
    await NotificationService.cancelAll();
  }

  static Future<void> handleSnooze(
    int notificationId, {
    required String medicineName,
    String? dosage,
  }) async {
    await AlarmService.cancelAllForAlarm(notificationId);
    await NotificationService.cancelAll();

    await AlarmService.scheduleRenotify(
      alarmId: notificationId,
      delay: const Duration(minutes: AppConstants.snoozeMinutes),
      medicineName: medicineName,
      dosage: dosage,
      renotifyMinutes: AppConstants.renotifyIntervalMinutes,
    );
  }

  static (int, String, String?) _parsePayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return (0, 'Obat', null);
    }
    final split = payload.split('||');
    if (split.length < 2) {
      return (0, payload, null);
    }
    final alarmId = int.tryParse(split[0]) ?? 0;
    final medicineName = split[1];
    final dosage = split.length >= 3 && split[2].isNotEmpty ? split[2] : null;
    return (alarmId, medicineName, dosage);
  }
}
