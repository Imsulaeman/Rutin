import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LanguageService {
  static const _channel = MethodChannel('habit_app/native_reminder');
  static const _boxName = 'app_settings';
  static const _key = 'language';

  static Box<String> get box => Hive.box<String>(_boxName);

  static String get current => box.get(_key) ?? 'en';

  static Future<void> initialize() async {
    if (!box.containsKey(_key)) {
      await box.put(_key, current);
    }
    await _mirrorToNative(current);
  }

  static Future<void> setLanguage(String language) async {
    final normalized = _normalize(language);
    await box.put(_key, normalized);
    await _mirrorToNative(normalized);
  }

  static Future<void> _mirrorToNative(String language) async {
    try {
      await _channel.invokeMethod('setAppLanguage', {'language': language});
    } on MissingPluginException {
      // Android owns native alarm copy. Other platforms only need Hive.
    }
  }

  static String _normalize(String language) => language == 'id' ? 'id' : 'en';
}
