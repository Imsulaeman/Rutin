import 'dart:io';

import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';

class AlarmService {
  static const MethodChannel _channel =
      MethodChannel('habit_app/native_reminder');

  static Future<void> init() async {}

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

  static const int waterAlarmId = 800000;

  static Future<void> scheduleWater({
    required int intervalMinutes,
    required int startTimeMinutes,
    required int endTimeMinutes,
  }) async {
    if (!Platform.isAndroid) return;
    final triggerAt = DateTime.now().add(Duration(minutes: intervalMinutes));
    await _channel.invokeMethod('scheduleWaterReminder', {
      'alarmId': waterAlarmId,
      'triggerAtMillis': triggerAt.millisecondsSinceEpoch,
      'intervalMinutes': intervalMinutes,
      'startTimeMinutes': startTimeMinutes,
      'endTimeMinutes': endTimeMinutes,
    });
  }

  static Future<void> cancelWater() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('cancelWaterReminder', {
      'alarmId': waterAlarmId,
    });
  }

  static Future<void> cancel(int alarmId) async {
    await cancelAllForAlarm(alarmId);
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
