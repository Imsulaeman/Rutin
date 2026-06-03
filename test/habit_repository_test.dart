import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:habit_app/core/utils/date_utils.dart';
import 'package:habit_app/features/habits/data/habit_model.dart';
import 'package:habit_app/features/habits/data/habit_repository.dart';

void main() {
  late Directory tempDir;
  late HabitRepository repo;

  setUpAll(() {
    Hive
      ..registerAdapter(HabitAdapter())
      ..registerAdapter(HabitLogAdapter())
      ..registerAdapter(HabitGroupAdapter());
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('habit_repo_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<Habit>('habits');
    await Hive.openBox<HabitLog>('habit_logs');
    await Hive.openBox<HabitGroup>('habit_groups');
    repo = HabitRepository();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('getStreak counts today plus consecutive previous full days', () async {
    final habit = Habit()
      ..id = 'habit-1'
      ..name = 'Medicine walk'
      ..emoji = 'A'
      ..scheduleDays = []
      ..reminderTimes = [480, 1200];
    await Hive.box<Habit>('habits').put(habit.id, habit);

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));
    final threeDaysAgo = today.subtract(const Duration(days: 3));

    Future<void> addLog(DateTime day) async {
      await Hive.box<HabitLog>('habit_logs').add(
        HabitLog()
          ..habitId = habit.id
          ..date = AppDateUtils.toDateString(day),
      );
    }

    await addLog(today);
    await addLog(today);
    await addLog(yesterday);
    await addLog(yesterday);
    await addLog(twoDaysAgo);
    await addLog(twoDaysAgo);
    await addLog(threeDaysAgo);
    await addLog(threeDaysAgo);

    expect(repo.getStreak(habit.id), 4);
  });

  test('getStreak keeps partial past day but does not add to streak', () async {
    final habit = Habit()
      ..id = 'habit-2'
      ..name = 'Stretch'
      ..emoji = 'B'
      ..scheduleDays = []
      ..reminderTimes = [480, 1200];
    await Hive.box<Habit>('habits').put(habit.id, habit);

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));
    final threeDaysAgo = today.subtract(const Duration(days: 3));

    Future<void> addLog(DateTime day) async {
      await Hive.box<HabitLog>('habit_logs').add(
        HabitLog()
          ..habitId = habit.id
          ..date = AppDateUtils.toDateString(day),
      );
    }

    await addLog(today);
    await addLog(today);
    await addLog(yesterday);
    await addLog(twoDaysAgo);
    await addLog(twoDaysAgo);
    await addLog(threeDaysAgo);
    await addLog(threeDaysAgo);

    expect(repo.getStreak(habit.id), 3);
  });

  test('getStreak breaks on a zero-completion day', () async {
    final habit = Habit()
      ..id = 'habit-3'
      ..name = 'Hydrate'
      ..emoji = 'C'
      ..scheduleDays = []
      ..reminderTimes = [600];
    await Hive.box<Habit>('habits').put(habit.id, habit);

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final threeDaysAgo = today.subtract(const Duration(days: 3));

    await Hive.box<HabitLog>('habit_logs').add(
      HabitLog()
        ..habitId = habit.id
        ..date = AppDateUtils.toDateString(today),
    );
    await Hive.box<HabitLog>('habit_logs').add(
      HabitLog()
        ..habitId = habit.id
        ..date = AppDateUtils.toDateString(yesterday),
    );
    await Hive.box<HabitLog>('habit_logs').add(
      HabitLog()
        ..habitId = habit.id
        ..date = AppDateUtils.toDateString(threeDaysAgo),
    );

    expect(repo.getStreak(habit.id), 2);
  });
}
