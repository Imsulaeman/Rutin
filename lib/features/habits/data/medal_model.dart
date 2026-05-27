import 'package:hive_flutter/hive_flutter.dart';

part 'medal_model.g.dart';

@HiveType(typeId: 10)
class Medal extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String emoji;

  @HiveField(3)
  late int peakStreak;

  @HiveField(4)
  late DateTime awardedAt;

  @HiveField(5)
  late String type; // 'habit' | 'routine'
}
