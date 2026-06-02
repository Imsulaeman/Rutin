import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/services/haptics_service.dart';
import '../../../l10n/l10n.dart';
import '../../habits/data/habit_model.dart';
import '../../medicine/data/medicine_model.dart';

const _gateBg = Color(0xFF0B0E1A);
const _surfaceDark = Color(0xFF131C2B);
const _surfaceHigh = Color(0xFF1A2438);
const _pink = Color(0xFFE91E63);
const _purple = Color(0xFF7C3AED);
const _green = Color(0xFF4CC56A);
const _orange = Color(0xFFF4A92B);
const _red = Color(0xFFF36B5B);

class MorningGateScreen extends StatefulWidget {
  const MorningGateScreen({super.key});

  @override
  State<MorningGateScreen> createState() => _MorningGateScreenState();
}

class _MorningGateScreenState extends State<MorningGateScreen>
    with SingleTickerProviderStateMixin {
  static const _ch = MethodChannel('rutin/sleep');

  late final AnimationController _slideCtrl;
  Timer? _clockTimer;

  DateTime _now = DateTime.now();
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(_refresh);
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
    _ch.invokeMethod('setGameActive', true);
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _slideCtrl
      ..removeListener(_refresh)
      ..dispose();
    _ch.invokeMethod('setGameActive', false);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int _calcStreak() {
    if (!Hive.isBoxOpen('morning_streaks')) return 0;
    final box = Hive.box<int>('morning_streaks');
    final today = DateTime.now();
    int streak = 0;
    for (int i = 1; i <= 365; i++) {
      if (box.get(_dateKey(today.subtract(Duration(days: i)))) == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  DateTime _todayAt(int minutes) =>
      DateTime(_now.year, _now.month, _now.day, minutes ~/ 60, minutes % 60);

  bool _isSameScheduledMinute(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute;

  List<_MedicineDoseRowData> _medicineRows() {
    final medicineBox = Hive.box<Medicine>('medicines');
    final logBox = Hive.box<MedicineLog>('medicine_logs');
    final medicines =
        medicineBox.values.where((medicine) => medicine.isActive).toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    final logs = logBox.values.toList();
    final rows = <_MedicineDoseRowData>[];

    for (final medicine in medicines) {
      final times = [...medicine.scheduleTimes]..sort();
      for (final minute in times) {
        final scheduled = _todayAt(minute);
        final log = logs.cast<MedicineLog?>().firstWhere(
          (entry) =>
              entry != null &&
              entry.medicineId == medicine.id &&
              _isSameScheduledMinute(entry.scheduledTime, scheduled),
          orElse: () => null,
        );

        final status = switch (log?.status) {
          'taken' => _DoseStatus.taken,
          'missed' => _DoseStatus.missed,
          _ =>
            scheduled.isBefore(_now) ? _DoseStatus.missed : _DoseStatus.pending,
        };

        rows.add(
          _MedicineDoseRowData(
            name: medicine.name,
            dosage: medicine.dosage?.trim().isNotEmpty == true
                ? medicine.dosage!.trim()
                : '',
            timeText: _clock(scheduled),
            status: status,
          ),
        );
      }
    }

    rows.sort((a, b) => a.timeText.compareTo(b.timeText));
    return rows;
  }

  List<_HabitRowData> _habitRows() {
    final habitBox = Hive.box<Habit>('habits');
    final logBox = Hive.box<HabitLog>('habit_logs');
    final weekday = _now.weekday;
    final todayKey = _dateKey(_now);
    final logs = logBox.values.toList();
    final habits =
        habitBox.values
            .where(
              (habit) =>
                  habit.scheduleDays.isEmpty ||
                  habit.scheduleDays.contains(weekday),
            )
            .toList()
          ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    return habits.map((habit) {
      final target = habit.reminderTimes.isNotEmpty
          ? habit.reminderTimes.length
          : 1;
      final completions = logs
          .where((log) => log.habitId == habit.id && log.date == todayKey)
          .length;
      return _HabitRowData(
        emoji: habit.emoji,
        name: habit.name,
        target: target,
        completions: completions.clamp(0, target),
        done: completions >= target,
      );
    }).toList();
  }

  Future<void> _onUnlocked() async {
    if (_unlocked) return;
    _unlocked = true;
    final router = GoRouter.of(context);
    await HapticsService.success();
    await router.push('/wakeup-game');
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _onEmergencyExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          localized(context, id: 'Lewati gerbang?', en: 'Skip the gate?'),
        ),
        content: Text(
          localized(
            context,
            id: 'Game pagi ini akan dilewati. Streak kamu tetap aman.',
            en: 'This morning game will be skipped. Your streak stays safe.',
          ),
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              localized(context, id: 'Lewati', en: 'Skip'),
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _ch.invokeMethod('setGameDismissedNormally', true);
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _onDragUpdate(double deltaDx, double trackWidth) {
    if (_unlocked) return;
    final travel = math.max(trackWidth - 52, 1);
    final next = (_slideCtrl.value + (deltaDx / travel)).clamp(0.0, 1.0);
    _slideCtrl.value = next;
    if (next >= 0.85) {
      _slideCtrl.value = 1;
      _onUnlocked();
    }
  }

  void _onDragEnd() {
    if (_unlocked || _slideCtrl.value >= 0.85) return;
    _slideCtrl.animateBack(0, curve: Curves.elasticOut);
  }

  @override
  Widget build(BuildContext context) {
    final medicineRows = _medicineRows();
    final habitRows = _habitRows();
    final medicineDone = medicineRows
        .where((row) => row.status == _DoseStatus.taken)
        .length;
    final habitDone = habitRows.where((row) => row.done).length;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _gateBg,
        body: SafeArea(
          child: Column(
            children: [
              _CompactHeader(
                timeText: _clock(_now),
                dateText: formatShortDate(context, _now),
                streak: _calcStreak(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _MedicineCard(
                        rows: medicineRows,
                        doneCount: medicineDone,
                        totalCount: medicineRows.length,
                      ),
                      const SizedBox(height: 12),
                      _HabitsCard(
                        rows: habitRows,
                        doneCount: habitDone,
                        totalCount: habitRows.length,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _SlideToUnlock(
                      fraction: _slideCtrl.value,
                      onDragUpdate: _onDragUpdate,
                      onDragEnd: _onDragEnd,
                    ),
                    const SizedBox(height: 8),
                    Center(child: _EmergencyExit(onPressed: _onEmergencyExit)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({
    required this.timeText,
    required this.dateText,
    required this.streak,
  });

  final String timeText;
  final String dateText;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeText,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateText,
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
          const Spacer(),
          _StreakPill(streak: streak),
        ],
      ),
    );
  }
}

String _clock(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6D00).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF6D00).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 5),
          Text(
            streak == 0
                ? localized(context, id: 'Hari pertama!', en: 'First day!')
                : localized(context, id: 'Hari ke-$streak', en: 'Day $streak'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF6D00),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({
    required this.rows,
    required this.doneCount,
    required this.totalCount,
  });

  final List<_MedicineDoseRowData> rows;
  final int doneCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return _HeroCard(
      accent: _pink,
      title: context.l10n.medicineToday,
      icon: Icons.medication_rounded,
      doneCount: doneCount,
      totalCount: totalCount,
      child: rows.isEmpty
          ? _EmptyCardText(
              text: localized(
                context,
                id: 'Tidak ada obat hari ini',
                en: 'No medicine today',
              ),
            )
          : Column(
              children: [
                for (int i = 0; i < rows.length; i++) ...[
                  _MedicineDoseRow(row: rows[i]),
                  if (i != rows.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: Color(0x1FFFFFFF)),
                    ),
                ],
              ],
            ),
    );
  }
}

class _HabitsCard extends StatelessWidget {
  const _HabitsCard({
    required this.rows,
    required this.doneCount,
    required this.totalCount,
  });

  final List<_HabitRowData> rows;
  final int doneCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return _HeroCard(
      accent: _purple,
      title: context.l10n.habitsToday,
      icon: Icons.auto_awesome_rounded,
      doneCount: doneCount,
      totalCount: totalCount,
      child: rows.isEmpty
          ? _EmptyCardText(
              text: localized(
                context,
                id: 'Tidak ada kebiasaan hari ini',
                en: 'No habits today',
              ),
            )
          : Column(
              children: [
                for (int i = 0; i < rows.length; i++) ...[
                  _HabitRow(row: rows[i]),
                  if (i != rows.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: Color(0x1FFFFFFF)),
                    ),
                ],
              ],
            ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.accent,
    required this.title,
    required this.icon,
    required this.doneCount,
    required this.totalCount,
    required this.child,
  });

  final Color accent;
  final String title;
  final IconData icon;
  final int doneCount;
  final int totalCount;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceDark,
        borderRadius: BorderRadius.circular(22),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: accent, size: 18),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                _CountChip(
                  doneCount: doneCount,
                  totalCount: totalCount,
                  accent: accent,
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.doneCount,
    required this.totalCount,
    required this.accent,
  });

  final int doneCount;
  final int totalCount;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$doneCount/$totalCount',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
  }
}

class _MedicineDoseRow extends StatelessWidget {
  const _MedicineDoseRow({required this.row});

  final _MedicineDoseRowData row;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _StatusDot(color: row.status.color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            row.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          row.timeText,
          style: const TextStyle(fontSize: 13, color: Colors.white54),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 68,
          child: Text(
            row.dosage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, color: Colors.white38),
          ),
        ),
      ],
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({required this.row});

  final _HabitRowData row;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(row.emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            row.name,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ),
        if (row.target > 1)
          _GateCompletionDots(target: row.target, completions: row.completions)
        else
          Icon(
            row.done
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: row.done ? _green : Colors.white24,
            size: 18,
          ),
      ],
    );
  }
}

class _GateCompletionDots extends StatelessWidget {
  const _GateCompletionDots({required this.target, required this.completions});

  final int target;
  final int completions;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < target; i++) ...[
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < completions ? _purple : Colors.transparent,
              border: Border.all(
                color: i < completions ? _purple : Colors.white24,
              ),
            ),
            child: i < completions
                ? const Icon(Icons.check_rounded, size: 11, color: Colors.white)
                : null,
          ),
          if (i != target - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SlideToUnlock extends StatelessWidget {
  const _SlideToUnlock({
    required this.fraction,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final double fraction;
  final void Function(double deltaDx, double trackWidth) onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final thumbOffset = fraction * math.max(trackWidth - 52, 0);
        return Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: _surfaceHigh,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white12),
          ),
          child: Stack(
            children: [
              Center(
                child: Opacity(
                  opacity: (1 - fraction).clamp(0.0, 1.0),
                  child: const Text(
                    'Geser untuk mulai  →→',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ),
              ),
              Positioned(
                left: thumbOffset,
                top: 4,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) =>
                      onDragUpdate(details.delta.dx, trackWidth),
                  onHorizontalDragEnd: (_) => onDragEnd(),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [_purple, Color(0xFF9A67FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _purple.withValues(alpha: 0.45),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmergencyExit extends StatelessWidget {
  const _EmergencyExit({required this.onPressed});

  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        localized(context, id: 'Lewati', en: 'Skip'),
        style: TextStyle(color: Colors.white24, fontSize: 12),
      ),
    );
  }
}

class _EmptyCardText extends StatelessWidget {
  const _EmptyCardText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white38, fontSize: 13),
        ),
      ),
    );
  }
}

class _MedicineDoseRowData {
  const _MedicineDoseRowData({
    required this.name,
    required this.dosage,
    required this.timeText,
    required this.status,
  });

  final String name;
  final String dosage;
  final String timeText;
  final _DoseStatus status;
}

class _HabitRowData {
  const _HabitRowData({
    required this.emoji,
    required this.name,
    required this.target,
    required this.completions,
    required this.done,
  });

  final String emoji;
  final String name;
  final int target;
  final int completions;
  final bool done;
}

enum _DoseStatus {
  taken(_green),
  pending(_orange),
  missed(_red);

  const _DoseStatus(this.color);

  final Color color;
}
