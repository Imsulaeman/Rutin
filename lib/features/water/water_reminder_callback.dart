import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'data/water_model.dart';
import 'data/water_repository.dart';

const int waterAlarmId = 800000;

@pragma('vm:entry-point')
Future<void> waterAlarmCallback() async {
  debugPrint('[WAC] waterAlarmCallback fired');
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(WaterGoalAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(WaterLogAdapter());
  if (!Hive.isBoxOpen('water_goals')) await Hive.openBox<WaterGoal>('water_goals');
  if (!Hive.isBoxOpen('water_logs')) await Hive.openBox<WaterLog>('water_logs');
  if (!Hive.isBoxOpen('app_settings')) await Hive.openBox<String>('app_settings');

  final repo = WaterRepository();
  final goal = repo.getGoal();
  if (!goal.reminderActive) return;

  final now = DateTime.now();
  final nowMin = now.hour * 60 + now.minute;

  if (nowMin >= goal.startTimeMinutes && nowMin <= goal.endTimeMinutes) {
    await _showWaterNotification();
  }

  // Reschedule next tick if still within window
  if (kDebugMode) {
    await AndroidAlarmManager.oneShot(
      const Duration(seconds: 15),
      waterAlarmId,
      waterAlarmCallback,
      exact: true,
      wakeup: true,
    );
  } else {
    final intervalMin = goal.reminderIntervalMinutes;
    if (nowMin + intervalMin <= goal.endTimeMinutes) {
      await AndroidAlarmManager.oneShot(
        Duration(minutes: intervalMin),
        waterAlarmId,
        waterAlarmCallback,
        exact: true,
        wakeup: true,
      );
    }
  }
}

Future<void> _showWaterNotification() async {
  final plugin = FlutterLocalNotificationsPlugin();
  final isId = Hive.box<String>('app_settings').get('language') == 'id';

  await plugin.show(
    waterAlarmId,
    isId ? 'Waktunya minum air' : 'Time to drink water',
    isId ? 'Sudah minum segelas belum?' : 'Have you had a glass of water?',
    NotificationDetails(
      android: AndroidNotificationDetails(
        'water_reminder_v2',
        isId ? 'Pengingat Air' : 'Water Reminder',
        importance: Importance.high,
        priority: Priority.high,
        autoCancel: true,
        actions: [
          AndroidNotificationAction(
            'water_taken',
            isId ? 'Sudah minum' : 'Drank water',
            cancelNotification: true,
            showsUserInterface: true,
          ),
        ],
      ),
    ),
    payload: 'water',
  );
}
