import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'features/habits/data/habit_model.dart';
import 'features/habits/data/medal_model.dart';
import 'features/medicine/data/medicine_model.dart';
import 'features/notifications/alarm_service.dart';
import 'features/notifications/notification_handler.dart'
    show NotificationHandler, onBackgroundNotification;
import 'features/routines/data/routine_model.dart';
import 'features/sleep/data/sleep_model.dart';
import 'features/tb/data/tb_model.dart';
import 'features/water/data/water_model.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  _registerHiveAdapters();
  await _openHiveBoxes();
  await AlarmService.init();
  await _initNotifications();

  runApp(const ProviderScope(child: HabitApp()));
}

void _registerHiveAdapters() {
  Hive
    ..registerAdapter(MedicineAdapter())
    ..registerAdapter(MedicineLogAdapter())
    ..registerAdapter(WaterGoalAdapter())
    ..registerAdapter(WaterLogAdapter())
    ..registerAdapter(HabitAdapter())
    ..registerAdapter(HabitLogAdapter())
    ..registerAdapter(HabitGroupAdapter())
    ..registerAdapter(MedalAdapter())
    ..registerAdapter(RoutineAdapter())
    ..registerAdapter(RoutineLogAdapter())
    ..registerAdapter(TBTreatmentProfileAdapter())
    ..registerAdapter(SleepSettingsAdapter());
}

Future<void> _openHiveBoxes() async {
  await Future.wait([
    Hive.openBox<Medicine>('medicines'),
    Hive.openBox<MedicineLog>('medicine_logs'),
    Hive.openBox<WaterGoal>('water_goals'),
    Hive.openBox<WaterLog>('water_logs'),
    Hive.openBox<Habit>('habits'),
    Hive.openBox<HabitLog>('habit_logs'),
    Hive.openBox<HabitGroup>('habit_groups'),
    Hive.openBox<Medal>('medals'),
    Hive.openBox<Routine>('routines'),
    Hive.openBox<RoutineLog>('routine_logs'),
    Hive.openBox<TBTreatmentProfile>('tb_profiles'),
    Hive.openBox<SleepSettings>('sleep_settings'),
  ]);
}

Future<void> _initNotifications() async {
  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: NotificationHandler.handle,
    onDidReceiveBackgroundNotificationResponse: onBackgroundNotification,
  );

  final androidImplementation = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidImplementation?.requestNotificationsPermission();
  try {
    await (androidImplementation as dynamic?)?.requestExactAlarmsPermission();
  } catch (_) {
    // Older plugin versions may not expose exact-alarm permission request.
  }
}
