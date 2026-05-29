import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';

class AlarmService {
  static const MethodChannel _channel =
      MethodChannel('habit_app/native_reminder');

  static Future<void> init() async {
    if (Platform.isAndroid) await AndroidAlarmManager.initialize();
  }

  static int renotifyAlarmId(int alarmId) => alarmId + 1000000;

  static Future<void> scheduleMedicineAlarm({
    required int alarmId,
    required DateTime scheduledTime,
    required String medicineName,
    String? dosage,
    int? renotifyMinutes,
  }) async {
    await _scheduleNative(
      alarmId: alarmId,
      triggerAt: scheduledTime,
      medicineName: medicineName,
      dosage: dosage,
      renotifyMinutes: renotifyMinutes ?? AppConstants.renotifyIntervalMinutes,
    );
  }

  static Future<void> scheduleRenotify({
    required int alarmId,
    required Duration delay,
    required String medicineName,
    String? dosage,
    int? renotifyMinutes,
  }) async {
    await _scheduleNative(
      alarmId: alarmId,
      triggerAt: DateTime.now().add(delay),
      medicineName: medicineName,
      dosage: dosage,
      renotifyMinutes: renotifyMinutes ?? AppConstants.renotifyIntervalMinutes,
    );
  }

  static Future<void> startRenotifyLoop({
    required int alarmId,
    required int repeatMinutes,
    required DateTime startAt,
    required String medicineName,
    String? dosage,
  }) async {
    await _scheduleNative(
      alarmId: alarmId,
      triggerAt: startAt,
      medicineName: medicineName,
      dosage: dosage,
      renotifyMinutes: repeatMinutes,
    );
  }

  static Future<void> cancel(int alarmId) async {
    await cancelAllForAlarm(alarmId);
  }

  /// Drains "taken" events queued by the native reminder screen. Each entry is
  /// `"$alarmId|$firedAtMillis"`. Native clears the queue once read.
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

  static Future<void> _scheduleNative({
    required int alarmId,
    required DateTime triggerAt,
    required String medicineName,
    String? dosage,
    required int renotifyMinutes,
  }) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('scheduleReminder', {
      'alarmId': alarmId,
      'triggerAtMillis': triggerAt.millisecondsSinceEpoch,
      'medicineName': medicineName,
      'dosage': dosage,
      'renotifyMinutes': renotifyMinutes,
    });
  }
}
