import 'package:hive_flutter/hive_flutter.dart';

part 'user_profile_model.g.dart';

@HiveType(typeId: 12)
class UserProfile extends HiveObject {
  @HiveField(0)
  String name = '';

  @HiveField(1)
  int age = 0;

  @HiveField(2)
  int avatarId = 0;
}
