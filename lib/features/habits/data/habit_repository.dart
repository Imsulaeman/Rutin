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

  Future<void> deleteGroup(String id) async {
    for (final h in _habits.values.where((h) => h.groupId == id).toList()) {
      h.groupId = null;
      await _habits.put(h.id, h);
    }
    await _groups.delete(id);
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
    for (final h in habitsInGroup(null)) items.add((h.sortIndex, h));
    for (final g in getGroups()) items.add((g.sortIndex, g));
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

  bool isCompletedToday(String habitId) {
    final today = AppDateUtils.todayString();
    return _logs.values.any((l) => l.habitId == habitId && l.date == today);
  }

  Future<void> markDone(String habitId) async {
    if (!isCompletedToday(habitId)) {
      await _logs.add(HabitLog()
        ..habitId = habitId
        ..date = AppDateUtils.todayString());
    }
  }

  int getStreak(String habitId) {
    final logs = _logs.values
        .where((l) => l.habitId == habitId)
        .map((l) => l.date)
        .toSet();
    int streak = 0;
    var day = DateTime.now();
    while (logs.contains(AppDateUtils.toDateString(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
