import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:habit_app/core/utils/date_utils.dart';
import 'package:habit_app/features/water/data/water_model.dart';
import 'package:habit_app/features/water/data/water_repository.dart';

void main() {
  late Directory tempDir;
  late WaterRepository repo;

  setUpAll(() {
    Hive
      ..registerAdapter(WaterGoalAdapter())
      ..registerAdapter(WaterLogAdapter());
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('water_repo_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<WaterGoal>('water_goals');
    await Hive.openBox<WaterLog>('water_logs');
    repo = WaterRepository();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('getGoal creates a default goal once', () {
    final goal = repo.getGoal();

    expect(goal.startTimeMinutes, 420);
    expect(goal.endTimeMinutes, 1320);
    expect(goal.dailyTargetMl, 2500);
    expect(goal.glassSizeMl, 250);
    expect(Hive.box<WaterGoal>('water_goals').length, 1);
  });

  test('addMl accumulates into the same day log', () async {
    await repo.addMl(250);
    await repo.addMl(500);

    expect(repo.getTodayMl(), 750);
    expect(Hive.box<WaterLog>('water_logs').length, 1);
  });

  test('removeMl clamps at zero and never goes negative', () async {
    await repo.addMl(300);
    await repo.removeMl(200);
    expect(repo.getTodayMl(), 100);

    await repo.removeMl(500);
    expect(repo.getTodayMl(), 0);
  });

  test('getTodayLog ignores previous-day logs', () async {
    await Hive.box<WaterLog>('water_logs').add(
      WaterLog()
        ..date = AppDateUtils.toDateString(
          DateTime.now().subtract(const Duration(days: 1)),
        )
        ..mlLogged = 900,
    );

    expect(repo.getTodayLog(), isNull);
    expect(repo.getTodayMl(), 0);
  });
}
