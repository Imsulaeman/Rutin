import 'dart:convert';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../habits/data/habit_model.dart';
import '../../habits/data/medal_model.dart';
import '../../medicine/data/medicine_model.dart';
import '../../profile/data/user_profile_model.dart';
import '../../tb/data/tb_model.dart';
import '../../water/data/water_model.dart';

class BackupService {
  static Future<void> exportJson() async {
    final now = DateTime.now();

    final waterGoalBox = Hive.box<WaterGoal>('water_goals');
    final wg = waterGoalBox.isEmpty ? null : waterGoalBox.getAt(0);
    final profileBox = Hive.box<UserProfile>('user_profile');
    final profile = profileBox.isEmpty ? null : profileBox.getAt(0);

    final data = <String, dynamic>{
      'version': 1,
      'exportedAt': now.toIso8601String(),
      'medicines': Hive.box<Medicine>('medicines').values.map((m) => {
        'id': m.id,
        'name': m.name,
        'dosage': m.dosage,
        'scheduleTimes': m.scheduleTimes,
        'isActive': m.isActive,
        'colorValue': m.colorValue,
        'mealTimingKey': m.mealTimingKey,
      }).toList(),
      'medicine_logs': Hive.box<MedicineLog>('medicine_logs').values.map((l) => {
        'medicineId': l.medicineId,
        'scheduledTime': l.scheduledTime.toIso8601String(),
        'takenAt': l.takenAt?.toIso8601String(),
        'status': l.status,
      }).toList(),
      'habits': Hive.box<Habit>('habits').values.map((h) => {
        'id': h.id,
        'name': h.name,
        'emoji': h.emoji,
        'scheduleDays': h.scheduleDays,
        'reminderMinutes': h.reminderMinutes,
        'colorValue': h.colorValue,
        'groupId': h.groupId,
        'sortIndex': h.sortIndex,
        'reminderTimes': h.reminderTimes,
      }).toList(),
      'habit_logs': Hive.box<HabitLog>('habit_logs').values.map((l) => {
        'habitId': l.habitId,
        'date': l.date,
      }).toList(),
      'habit_groups': Hive.box<HabitGroup>('habit_groups').values.map((g) => {
        'id': g.id,
        'name': g.name,
        'emoji': g.emoji,
        'sortIndex': g.sortIndex,
      }).toList(),
      'water_goal': wg == null ? null : {
        'startTimeMinutes': wg.startTimeMinutes,
        'endTimeMinutes': wg.endTimeMinutes,
        'reminderActive': wg.reminderActive,
        'dailyTargetMl': wg.dailyTargetMl,
        'glassSizeMl': wg.glassSizeMl,
      },
      'water_logs': Hive.box<WaterLog>('water_logs').values.map((l) => {
        'date': l.date,
        'mlLogged': l.mlLogged,
      }).toList(),
      'treatment_profiles': Hive.box<TBTreatmentProfile>('tb_profiles').values.map((p) => {
        'startDate': p.startDate.toIso8601String(),
        'durationDays': p.durationDays,
        'medicineId': p.medicineId,
        'isActive': p.isActive,
        'conditionName': p.conditionName,
      }).toList(),
      'medals': Hive.box<Medal>('medals').values.map((m) => {
        'id': m.id,
        'name': m.name,
        'emoji': m.emoji,
        'peakStreak': m.peakStreak,
        'awardedAt': m.awardedAt.toIso8601String(),
        'type': m.type,
      }).toList(),
      'user_profile': profile == null ? null : {
        'name': profile.name,
        'age': profile.age,
        'avatarId': profile.avatarId,
      },
    };

    final json = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final file = File('${dir.path}/rutin_backup_$dateStr.json');
    await file.writeAsString(json);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Rutin Backup $dateStr',
    );
  }
}
