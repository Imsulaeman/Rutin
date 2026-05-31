import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/utils/date_utils.dart' show AppDateUtils;
import '../../../l10n/l10n.dart';
import '../data/habit_model.dart';

const _navy = Color(0xFF0B0E1A);
const _surface = Color(0xFF161D2E);
const _surfaceLine = Color(0xFF222C42);
const _grey = Color(0xFF9AA3B2);
const _full = Color(0xFF7C3AED);
const _partial = Color(0xFFF4A92B);

class HabitHistoryScreen extends StatefulWidget {
  const HabitHistoryScreen({super.key, required this.habitId});

  final String habitId;

  @override
  State<HabitHistoryScreen> createState() => _HabitHistoryScreenState();
}

class _HabitHistoryScreenState extends State<HabitHistoryScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final habit = Hive.box<Habit>('habits').get(widget.habitId);
    if (habit == null) {
      return Scaffold(
        backgroundColor: _navy,
        body: Center(
          child: Text(
            localized(context, id: 'Kebiasaan tidak ditemukan', en: 'Habit not found'),
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    final days = _daysForMonth(_month);

    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: Text('${habit.emoji} ${habit.name}'),
      ),
      body: ValueListenableBuilder<Box<HabitLog>>(
        valueListenable: Hive.box<HabitLog>('habit_logs').listenable(),
        builder: (context, _, _) => ListView(
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
                      for (final label in ['M', 'S', 'S', 'R', 'K', 'J', 'S'])
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
                      final state = _dayState(habit, day);
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1524),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _surfaceLine),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Positioned(
                              bottom: 6,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _stateColor(state),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _completionsForDay(String habitId, String dateStr) =>
      Hive.box<HabitLog>('habit_logs').values.where((log) {
        return log.habitId == habitId && log.date == dateStr;
      }).length;

  int _targetForHabit(Habit habit) =>
      habit.reminderTimes.isNotEmpty ? habit.reminderTimes.length : 1;

  bool _isScheduledDay(Habit habit, DateTime day) {
    if (habit.scheduleDays.isEmpty) return true;
    return habit.scheduleDays.contains(day.weekday);
  }

  String _dayState(Habit habit, DateTime day) {
    final today = DateTime.now();
    if (day.isAfter(DateTime(today.year, today.month, today.day))) {
      return 'future';
    }
    if (!_isScheduledDay(habit, day)) return 'off';
    final completions = _completionsForDay(
      habit.id,
      AppDateUtils.toDateString(day),
    );
    final target = _targetForHabit(habit);
    if (completions >= target) return 'full';
    if (completions > 0) return 'partial';
    return 'missed';
  }

  Color _stateColor(String state) => switch (state) {
    'full' => _full,
    'partial' => _partial,
    'missed' => Colors.white.withValues(alpha: 0.15),
    _ => Colors.transparent,
  };
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
            _monthLabel(month),
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
        _LegendItem(label: localized(context, id: 'Sebagian', en: 'Partial'), color: _partial),
        _LegendItem(label: context.l10n.missed, color: Color(0x26FFFFFF)),
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

List<DateTime?> _daysForMonth(DateTime month) {
  final first = DateTime(month.year, month.month);
  final count = DateTime(month.year, month.month + 1, 0).day;
  return [
    for (var i = 1; i < first.weekday; i++) null,
    for (var day = 1; day <= count; day++)
      DateTime(month.year, month.month, day),
  ];
}

String _monthLabel(DateTime month) {
  const names = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return '${names[month.month - 1]} ${month.year}';
}
