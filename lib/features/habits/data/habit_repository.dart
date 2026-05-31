import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/utils/date_utils.dart' show AppDateUtils;
import 'habit_model.dart';

class HabitRepository {
  Box<Habit> get _habits => Hive.box<Habit>('habits');
  Box<HabitLog> get _logs => Hive.box<HabitLog>('habit_logs');
  Box<HabitGroup> get _groups => Hive.box<HabitGroup>('habit_groups');

  // ─── Groups ───

  List<HabitGroup> getGroups() {
    final list = _groups.values.toList();
    list.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    return list;
  }

  Future<void> saveGroup(HabitGroup group) => _groups.put(group.id, group);

  /// Delete the group only; its habits become ungrouped (groupId = null).
  Future<void> deleteGroup(String id) async {
    for (final h in _habits.values.where((h) => h.groupId == id).toList()) {
      h.groupId = null;
      await _habits.put(h.id, h);
    }
    await _groups.delete(id);
  }

  /// Delete the group AND every habit inside it. Returns the deleted habit ids
  /// so callers can cancel their reminders.
  Future<List<String>> deleteGroupWithHabits(String id) async {
    final ids = <String>[];
    for (final h in _habits.values.where((h) => h.groupId == id).toList()) {
      ids.add(h.id);
      await _habits.delete(h.id);
    }
    await _groups.delete(id);
    return ids;
  }

  Future<void> reorderGroups(List<HabitGroup> ordered) async {
    for (var i = 0; i < ordered.length; i++) {
      ordered[i].sortIndex = i;
      await _groups.put(ordered[i].id, ordered[i]);
    }
  }

  // ─── Habits ───

  List<Habit> getAll() {
    final list = _habits.values.toList();
    list.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    return list;
  }

  List<Habit> habitsInGroup(String? groupId) {
    final list = _habits.values.where((h) => h.groupId == groupId).toList();
    list.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    return list;
  }

  Future<void> save(Habit habit) => _habits.put(habit.id, habit);

  Future<void> delete(String id) => _habits.delete(id);

  Future<void> reorderHabitsInGroup(List<Habit> ordered) async {
    for (var i = 0; i < ordered.length; i++) {
      ordered[i].sortIndex = i;
      await _habits.put(ordered[i].id, ordered[i]);
    }
  }

  /// Reorders the flat list of ungrouped habits + groups by updating their
  /// sortIndex values. [ordered] is a mixed list of Habit and HabitGroup.
  Future<void> reorderFlatList(List<dynamic> ordered) async {
    for (var i = 0; i < ordered.length; i++) {
      final item = ordered[i];
      if (item is Habit) {
        item.sortIndex = i;
        await _habits.put(item.id, item);
      } else if (item is HabitGroup) {
        item.sortIndex = i;
        await _groups.put(item.id, item);
      }
    }
  }

  /// Builds the flat list (ungrouped habits + groups) sorted by sortIndex.
  List<dynamic> getFlatList() {
    final items = <(int, dynamic)>[];
    for (final h in habitsInGroup(null)) {
      items.add((h.sortIndex, h));
    }
    for (final g in getGroups()) {
      items.add((g.sortIndex, g));
    }
    items.sort((a, b) => a.$1.compareTo(b.$1));
    return items.map((e) => e.$2).toList();
  }

  /// Auto-sorts a newly placed timed habit within its group (or flat list).
  /// Inserts it just before the first existing timed item whose time is later.
  /// Untimed items are never moved.
  Future<void> autoSortNewItem(String? groupId, String habitId) async {
    final habits = habitsInGroup(groupId);
    final idx = habits.indexWhere((h) => h.id == habitId);
    if (idx == -1) return;
    final newHabit = habits[idx];
    if (newHabit.reminderMinutes == null) return;

    habits.removeAt(idx);

    // Find first timed habit with a later time.
    int insertAt = habits.length;
    for (var i = 0; i < habits.length; i++) {
      final m = habits[i].reminderMinutes;
      if (m != null && m > newHabit.reminderMinutes!) {
        insertAt = i;
        break;
      }
    }

    habits.insert(insertAt, newHabit);
    await reorderHabitsInGroup(habits);
  }

  // ─── Logs ───

  /// Daily target = number of reminder times, with one completion minimum.
  int dailyTarget(Habit habit) {
    final times = habit.reminderTimes.isNotEmpty
        ? habit.reminderTimes
        : (habit.reminderMinutes != null
              ? [habit.reminderMinutes!]
              : const <int>[]);
    return times.isEmpty ? 1 : times.length;
  }

  int completionsToday(String habitId) {
    final today = AppDateUtils.todayString();
    return _logs.values
        .where((log) => log.habitId == habitId && log.date == today)
        .length;
  }

  bool isCompletedToday(String habitId) {
    final habit = _habits.get(habitId);
    if (habit == null) return false;
    return completionsToday(habitId) >= dailyTarget(habit);
  }

  Future<void> addCompletion(String habitId) async {
    await _logs.add(
      HabitLog()
        ..habitId = habitId
        ..date = AppDateUtils.todayString(),
    );
  }

  Future<void> removeCompletion(String habitId) async {
    final today = AppDateUtils.todayString();
    final entries = _logs
        .toMap()
        .entries
        .where(
          (entry) =>
              entry.value.habitId == habitId && entry.value.date == today,
        )
        .toList();
    if (entries.isNotEmpty) {
      await _logs.delete(entries.last.key);
    }
  }

  Future<void> setCompletionsToday(Habit habit, int count) async {
    final target = dailyTarget(habit);
    count = count.clamp(0, target);
    var current = completionsToday(habit.id);
    while (current < count) {
      await addCompletion(habit.id);
      current++;
    }
    while (current > count) {
      await removeCompletion(habit.id);
      current--;
    }
  }

  Future<void> markDone(String habitId) async {
    final habit = _habits.get(habitId);
    if (habit == null) return;
    if (completionsToday(habitId) < dailyTarget(habit)) {
      await addCompletion(habitId);
    }
  }

  int getStreak(String habitId) {
    final habit = _habits.get(habitId);
    if (habit == null) return 0;
    final target = dailyTarget(habit);
    final byDate = <String, int>{};
    for (final log in _logs.values.where((log) => log.habitId == habitId)) {
      byDate[log.date] = (byDate[log.date] ?? 0) + 1;
    }

    int streak = 0;
    var day = DateTime.now();
    final todayCount = byDate[AppDateUtils.toDateString(day)] ?? 0;
    if (todayCount >= target) streak++;
    day = day.subtract(const Duration(days: 1));

    var guard = 0;
    while (guard++ < 3660) {
      final count = byDate[AppDateUtils.toDateString(day)] ?? 0;
      if (count >= target) {
        streak++;
      } else if (count == 0) {
        break;
      }
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
