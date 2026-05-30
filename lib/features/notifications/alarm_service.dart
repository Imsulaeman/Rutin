import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';

class AlarmService {
  static const MethodChannel _channel =
      MethodChannel('habit_app/native_reminder');

  static int medicineRootAlarmId(String medicineId, int scheduledMinutes) =>
      '$medicineId|$scheduledMinutes'.hashCode & 0x7fffffff;

  static int medicineLoopAlarmId(int rootAlarmId) => rootAlarmId + 1000000;

  static Future<void> init() async {
    if (Platform.isAndroid) await AndroidAlarmManager.initialize();
  }

  static int renotifyAlarmId(int alarmId) => alarmId + 1000000;

  static Future<void> scheduleMedicineAlarm({
    required int alarmId,
    required DateTime scheduledTime,
    required int scheduledMinutes,
    required String medicineName,
    String? dosage,
    int? renotifyMinutes,
  }) async {
    await _scheduleNative(
      rootAlarmId: alarmId,
      triggerAt: scheduledTime,
      scheduledMinutes: scheduledMinutes,
      medicineName: medicineName,
      dosage: dosage,
      renotifyMinutes: renotifyMinutes ?? AppConstants.renotifyIntervalMinutes,
      isLoop: false,
    );
  }

  static Future<void> scheduleRenotify({
    required int alarmId,
    required Duration delay,
    required int scheduledMinutes,
    required String medicineName,
    String? dosage,
    int? renotifyMinutes,
  }) async {
    await _scheduleNative(
      rootAlarmId: alarmId,
      triggerAt: DateTime.now().add(delay),
      scheduledMinutes: scheduledMinutes,
      medicineName: medicineName,
      dosage: dosage,
      renotifyMinutes: renotifyMinutes ?? AppConstants.renotifyIntervalMinutes,
      isLoop: true,
    );
  }

  static Future<void> startRenotifyLoop({
    required int alarmId,
    required int repeatMinutes,
    required DateTime startAt,
    required int scheduledMinutes,
    required String medicineName,
    String? dosage,
  }) async {
    await _scheduleNative(
      rootAlarmId: alarmId,
      triggerAt: startAt,
      scheduledMinutes: scheduledMinutes,
      medicineName: medicineName,
      dosage: dosage,
      renotifyMinutes: repeatMinutes,
      isLoop: true,
    );
  }

  static Future<void> cancel(int alarmId) async {
    await cancelAllForAlarm(alarmId);
  }

  static Future<void> cancelCurrentDoseLoop(int alarmId) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('cancelDoseLoop', {
      'alarmId': alarmId,
    });
  }

  /// Drains "taken" events queued by the native reminder screen. Each entry is
  /// `"$alarmId|$scheduledMinutes|$firedAtMillis"`. Native clears the queue once read.
  static Future<List<String>> getPendingTaken() async {
    if (!Platform.isAndroid) return const [];
    final raw = await _channel.invokeMethod<List<dynamic>>('getPendingTaken');
    return raw?.cast<String>() ?? const [];
  }

  static Future<void> cancelAllForAlarm(int alarmId) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('cancelReminder', {
      'alarmId': alarmId,
    });
  }

  static Future<Map<String, int>> getReminderDebug(int alarmId) async {
    if (!Platform.isAndroid) return const {};
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'getReminderDebug',
      {'alarmId': alarmId},
    );
    if (raw == null) return const {};
    return raw.map(
      (key, value) => MapEntry(
        key.toString(),
        (value as num).toInt(),
      ),
    );
  }

  static Future<void> _scheduleNative({
    required int rootAlarmId,
    required DateTime triggerAt,
    required int scheduledMinutes,
    required String medicineName,
    String? dosage,
    required int renotifyMinutes,
    required bool isLoop,
  }) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('scheduleReminder', {
      'alarmId': rootAlarmId,
      'triggerAtMillis': triggerAt.millisecondsSinceEpoch,
      'scheduledMinutes': scheduledMinutes,
      'medicineName': medicineName,
      'dosage': dosage,
      'renotifyMinutes': renotifyMinutes,
      'isLoop': isLoop,
    });
  }
}
