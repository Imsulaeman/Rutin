import 'package:flutter/services.dart';

class HapticsService {
  static const MethodChannel _channel = MethodChannel(
    'habit_app/native_reminder',
  );

  static Future<void> tap() async {
    try {
      await _channel.invokeMethod('vibrateImpact', {
        'durationMs': 55,
        'amplitude': 255,
      });
    } catch (_) {}
  }

  static Future<void> softTap() async {
    try {
      await _channel.invokeMethod('vibrateImpact', {
        'durationMs': 35,
        'amplitude': 180,
      });
    } catch (_) {}
  }

  static Future<void> success() async {
    try {
      await _channel.invokeMethod('vibratePattern', {
        'timings': [0, 28, 34, 54],
        'amplitudes': [0, 200, 0, 255],
      });
    } catch (_) {}
  }

  static Future<void> fun() async {
    try {
      await _channel.invokeMethod('vibratePattern', {
        'timings': [0, 24, 34, 52, 28, 76],
        'amplitudes': [0, 170, 0, 255, 0, 200],
      });
    } catch (_) {}
  }
}
