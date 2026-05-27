import 'package:hive_flutter/hive_flutter.dart';

part 'sleep_model.g.dart';

@HiveType(typeId: 9)
class SleepSettings extends HiveObject {
  @HiveField(0)
  late int sleepModeStartMinutes; // default: 1260 (9 PM)

  @HiveField(1)
  late int wakeWindowStartMinutes; // default: 300 (5 AM)

  @HiveField(2)
  late int wakeWindowEndMinutes; // default: 600 (10 AM)

  @HiveField(3)
  late bool sleepModeEnabled;

  @HiveField(4)
  late bool accessibilityGranted;
}
