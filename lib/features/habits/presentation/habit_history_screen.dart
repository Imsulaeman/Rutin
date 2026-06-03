import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/utils/date_utils.dart' show AppDateUtils;
import '../../../l10n/l10n.dart';
import '../data/habit_model.dart';
import '../data/habit_repository.dart';

const _navy = Color(0xFF0B0E1A);
const _surface = Color(0xFF161D2E);
const _surfaceLine = Color(0xFF222C42);
const _grey = Color(0xFF9AA3B2);
const _full = Color(0xFF7C3AED);
const _partial = Color(0xFFF4A92B);

class HabitHistoryScreen extends StatefulWidget {
  const HabitHistoryScreen({super.key});

  @override
  State<HabitHistoryScreen> createState() => _HabitHistoryScreenState();
}

class _HabitHistoryScreenState extends State<HabitHistoryScreen> {
  late DateTime _month;
  late DateTime _selectedDay;
  final _repo = HabitRepository();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final habits = Hive.box<Habit>('habits').values.toList()
      ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    final days = _daysForMonth(_month);
    final selectedRows = _rowsForDay(habits, _selectedDay);
    final completedCount = selectedRows.where((row) => row.isFull).length;
    final activeCount = selectedRows.where((row) => !row.isOffDay).length;

    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: Text(context.l10n.habitHistory),
      ),
      body: ValueListenableBuilder<Box<HabitLog>>(
        valueListenable: Hive.box<HabitLog>('habit_logs').listenable(),
        builder: (context, _, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              _MonthHeader(
                month: _month,
                onPrev: () => setState(() {
                  _month = DateTime(_month.year, _month.month - 1);
                }),
                onNext: () => setState(() {
                  _month = DateTime(_month.year, _month.month + 1);
                }),
              ),
              const SizedBox(height: 14),
              const _Legend(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _surfaceLine),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (final label in localizedWeekdayShortLabels(
                          context,
                        ))
                          Expanded(
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      itemCount: days.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemBuilder: (context, index) {
                        final day = days[index];
                        if (day == null) return const SizedBox.shrink();
                        final state = _dayState(habits, day);
                        final isSelected = _sameDay(day, _selectedDay);
                        final isToday = _sameDay(day, DateTime.now());
                        return GestureDetector(
                          onTap: () => setState(() => _selectedDay = day),
                          child: Container(
                            decoration: BoxDecoration(
                              color: switch (state) {
                                'full' => _full.withValues(
                                  alpha: isSelected ? 0.95 : 0.82,
                                ),
                                'partial' => _partial.withValues(
                                  alpha: isSelected ? 0.92 : 0.72,
                                ),
                                'missed' => Colors.white.withValues(
                                  alpha: isSelected ? 0.12 : 0.06,
                                ),
                                'off' => Colors.transparent,
                                _ => Colors.transparent,
                              },
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white70
                                    : isToday
                                    ? Colors.white24
                                    : state == 'off'
                                    ? _surfaceLine
                                    : Colors.transparent,
                                width: isSelected ? 1.4 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: state == 'off'
                                      ? Colors.white24
                                      : Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _surfaceLine),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatLongDate(context, _selectedDay),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      activeCount == 0
                          ? context.l10n.noHabitsScheduled
                          : context.l10n.habitsCompletedCount(completedCount, activeCount),
                      style: const TextStyle(color: _grey),
                    ),
                    const SizedBox(height: 16),
                    if (selectedRows.isEmpty)
                      Text(
                        context.l10n.noHabitsYetShort,
                        style: const TextStyle(color: _grey),
                      )
                    else
                      ...selectedRows.map(
                        (row) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _HabitDayTile(row: row),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<_HabitDayRow> _rowsForDay(List<Habit> habits, DateTime day) {
    return habits.map((habit) {
      final target = _repo.dailyTarget(habit);
      final completions = _completionsForDay(habit.id, day).clamp(0, target);
      final isOffDay = !_isScheduledDay(habit, day);
      return _HabitDayRow(
        habit: habit,
        target: target,
        completions: completions,
        isOffDay: isOffDay,
      );
    }).toList();
  }

  int _completionsForDay(String habitId, DateTime day) {
    final date = AppDateUtils.toDateString(day);
    return Hive.box<HabitLog>('habit_logs').values.where((log) {
      return log.habitId == habitId && log.date == date;
    }).length;
  }

  bool _isScheduledDay(Habit habit, DateTime day) {
    if (habit.scheduleDays.isEmpty) return true;
    return habit.scheduleDays.contains(day.weekday);
  }

  String _dayState(List<Habit> habits, DateTime day) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    if (day.isAfter(startOfToday)) return 'future';

    var scheduledCount = 0;
    var fullCount = 0;
    var partialCount = 0;

    for (final habit in habits) {
      if (!_isScheduledDay(habit, day)) continue;
      scheduledCount++;
      final target = _repo.dailyTarget(habit);
      final completions = _completionsForDay(habit.id, day);
      if (completions >= target) {
        fullCount++;
      } else if (completions > 0) {
        partialCount++;
      }
    }

    if (scheduledCount == 0) return 'off';
    if (fullCount == scheduledCount) return 'full';
    if (fullCount > 0 || partialCount > 0) return 'partial';
    return 'missed';
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _NavCircle(icon: Icons.chevron_left_rounded, onTap: onPrev),
        Expanded(
          child: Text(
            formatMonthYear(context, month),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _NavCircle(icon: Icons.chevron_right_rounded, onTap: onNext),
      ],
    );
  }
}

class _NavCircle extends StatelessWidget {
  const _NavCircle({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _LegendItem(label: context.l10n.done, color: _full),
        _LegendItem(label: context.l10n.partial, color: _partial),
        _LegendItem(label: context.l10n.missed, color: const Color(0x26FFFFFF)),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: _grey, fontSize: 12)),
      ],
    );
  }
}

class _HabitDayTile extends StatelessWidget {
  const _HabitDayTile({required this.row});

  final _HabitDayRow row;

  @override
  Widget build(BuildContext context) {
    final stateColor = row.isOffDay
        ? Colors.white24
        : row.isFull
        ? _full
        : row.completions > 0
        ? _partial
        : const Color(0x33FFFFFF);
    final statusText = row.isOffDay
        ? context.l10n.offDay
        : '${row.completions}/${row.target}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1524),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _surfaceLine),
      ),
      child: Row(
        children: [
          Text(row.habit.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              row.habit.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            statusText,
            style: const TextStyle(color: _grey, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 10),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: stateColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitDayRow {
  const _HabitDayRow({
    required this.habit,
    required this.target,
    required this.completions,
    required this.isOffDay,
  });

  final Habit habit;
  final int target;
  final int completions;
  final bool isOffDay;

  bool get isFull => !isOffDay && completions >= target;
}

List<DateTime?> _daysForMonth(DateTime month) {
  final first = DateTime(month.year, month.month);
  final count = DateTime(month.year, month.month + 1, 0).day;
  return [
    for (var i = 1; i < first.weekday; i++) null,
    for (var day = 1; day <= count; day++)
      DateTime(month.year, month.month, day),
  ];
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
