import 'package:firebase_core/firebase_core.dart';
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
import 'features/settings/data/language_service.dart';
import 'features/sleep/data/sleep_model.dart';
import 'features/tb/data/tb_model.dart';
import 'features/water/data/water_model.dart';
import 'features/water/presentation/water_reminder_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await Hive.initFlutter();
  _registerHiveAdapters();
  await _openHiveBoxes();
  await LanguageService.initialize();
  await AlarmService.init();
  await _syncMedicineSchedules();
  await _syncWaterSchedule();
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
    Hive.openBox<int>('morning_streaks'),
    Hive.openBox<String>('app_settings'),
  ]);
}

Future<void> _syncMedicineSchedules() async {
  final medicines = Hive.box<Medicine>(
    'medicines',
  ).values.where((medicine) => medicine.isActive);
  for (final medicine in medicines) {
    await AlarmService.cancelAllForAlarm(medicine.id.hashCode & 0x7fffffff);
    for (final minutes in medicine.scheduleTimes) {
      await AlarmService.scheduleMedicineAlarm(
        alarmId: AlarmService.medicineRootAlarmId(medicine.id, minutes),
        scheduledTime: _nextMedicineTime(minutes),
        scheduledMinutes: minutes,
        medicineName: medicine.name,
        dosage: medicine.dosage,
      );
    }
  }
}

// Re-arm the water reminder from the authoritative Hive goal on every cold
// start, mirroring medicine. Without this the native `interval_ms` pref only
// gets written when the settings sheet saves, so after a reboot the alarm can
// run off a stale/default value. Re-applying the goal here keeps Hive as the
// source of truth and writes the correct computed interval back to native.
Future<void> _syncWaterSchedule() async {
  final box = Hive.box<WaterGoal>('water_goals');
  if (box.isEmpty) return;
  final goal = box.values.first;
  if (goal.reminderActive) {
    await WaterReminderService.schedule(goal);
  }
}

DateTime _nextMedicineTime(int minutes) {
  final now = DateTime.now();
  var next = DateTime(
    now.year,
    now.month,
    now.day,
    minutes ~/ 60,
    minutes % 60,
  );
  if (!next.isAfter(now)) {
    next = next.add(const Duration(days: 1));
  }
  return next;
}

Future<void> _initNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: NotificationHandler.handle,
    onDidReceiveBackgroundNotificationResponse: onBackgroundNotification,
  );

  final androidImplementation = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await androidImplementation?.requestNotificationsPermission();
  try {
    await (androidImplementation as dynamic)?.requestExactAlarmsPermission();
  } catch (_) {
    // Older plugin versions may not expose exact-alarm permission request.
  }
}
