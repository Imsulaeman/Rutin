import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/services/haptics_service.dart';
import '../../habits/data/habit_model.dart';
import '../../medicine/data/medicine_model.dart';

const _gateBg = Color(0xFF0B0E1A);
const _gatePanel = Color(0xFF131C2B);
const _gatePanelSoft = Color(0xFF172235);
const _gateLine = Color(0x1FFFFFFF);
const _gateMuted = Color(0xFF9AA3B2);
const _gateSuccess = Color(0xFF4CC56A);
const _gatePending = Color(0xFFF4A92B);
const _gateMissed = Color(0xFFF36B5B);
const _gateAccentA = Color(0xFF5FD97E);
const _gateAccentB = Color(0xFF2FAF63);

class MorningGateScreen extends StatefulWidget {
  const MorningGateScreen({super.key});

  @override
  State<MorningGateScreen> createState() => _MorningGateScreenState();
}

class _MorningGateScreenState extends State<MorningGateScreen>
    with SingleTickerProviderStateMixin {
  static const _ch = MethodChannel('rutin/sleep');

  late final Box<Medicine> _medicineBox;
  late final Box<MedicineLog> _medicineLogBox;
  late final Box<Habit> _habitBox;
  late final Box<HabitLog> _habitLogBox;
  late final ValueListenable<Box<Medicine>> _medicineListenable;
  late final ValueListenable<Box<MedicineLog>> _medicineLogListenable;
  late final ValueListenable<Box<Habit>> _habitListenable;
  late final ValueListenable<Box<HabitLog>> _habitLogListenable;
  late final AnimationController _slideCtrl;

  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    _medicineBox = Hive.box<Medicine>('medicines');
    _medicineLogBox = Hive.box<MedicineLog>('medicine_logs');
    _habitBox = Hive.box<Habit>('habits');
    _habitLogBox = Hive.box<HabitLog>('habit_logs');
    _medicineListenable = _medicineBox.listenable();
    _medicineLogListenable = _medicineLogBox.listenable();
    _habitListenable = _habitBox.listenable();
    _habitLogListenable = _habitLogBox.listenable();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(_refresh);

    _medicineListenable.addListener(_refresh);
    _medicineLogListenable.addListener(_refresh);
    _habitListenable.addListener(_refresh);
    _habitLogListenable.addListener(_refresh);
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
    _ch.invokeMethod('setGameActive', true);
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _medicineListenable.removeListener(_refresh);
    _medicineLogListenable.removeListener(_refresh);
    _habitListenable.removeListener(_refresh);
    _habitLogListenable.removeListener(_refresh);
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

  String _greeting() {
    final hour = _now.hour;
    if (hour < 11) return 'Selamat pagi!';
    if (hour < 15) return 'Selamat siang!';
    if (hour < 19) return 'Selamat sore!';
    return 'Selamat malam!';
  }

  DateTime _todayAt(int minutes) =>
      DateTime(_now.year, _now.month, _now.day, minutes ~/ 60, minutes % 60);

  bool _isSameScheduledMinute(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute;

  List<_GateMedicineCardData> _medicineCards() {
    final medicines =
        _medicineBox.values.where((medicine) => medicine.isActive).toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    final logs = _medicineLogBox.values.toList();

    return medicines
        .map((medicine) {
          final rows = medicine.scheduleTimes.map((minute) {
            final scheduled = _todayAt(minute);
            final log = logs.cast<MedicineLog?>().firstWhere(
              (entry) =>
                  entry != null &&
                  entry.medicineId == medicine.id &&
                  _isSameScheduledMinute(entry.scheduledTime, scheduled),
              orElse: () => null,
            );
            final state = switch (log?.status) {
              'taken' => _GateDoseState.taken,
              'missed' => _GateDoseState.missed,
              _ =>
                scheduled.isBefore(_now)
                    ? _GateDoseState.missed
                    : _GateDoseState.pending,
            };
            return _GateDoseRowData(
              timeLabel: DateFormat('HH:mm').format(scheduled),
              name: medicine.name,
              dosage: medicine.dosage?.trim().isNotEmpty == true
                  ? medicine.dosage!.trim()
                  : null,
              state: state,
            );
          }).toList()..sort((a, b) => a.timeLabel.compareTo(b.timeLabel));
          return _GateMedicineCardData(rows: rows);
        })
        .where((card) => card.rows.isNotEmpty)
        .toList();
  }

  List<_GateHabitRowData> _habitRows() {
    final todayKey = _dateKey(_now);
    final weekday = _now.weekday;
    final logs = _habitLogBox.values.toList();
    final habits = _habitBox.values.where((habit) {
      return habit.scheduleDays.isEmpty || habit.scheduleDays.contains(weekday);
    }).toList()..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    return habits.map((habit) {
      final done = logs.any(
        (log) => log.habitId == habit.id && log.date == todayKey,
      );
      return _GateHabitRowData(
        emoji: habit.emoji,
        name: habit.name,
        done: done,
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

  void _onDragUpdate(double deltaDx, double trackWidth) {
    if (_unlocked) return;
    final travel = math.max(trackWidth - 56, 1);
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
    final medicines = _medicineCards();
    final habits = _habitRows();
    final streak = _calcStreak();

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _gateBg,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF12192B), _gateBg],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _GateHeader(
                  timeText: DateFormat('HH:mm').format(_now),
                  dateText: DateFormat('EEEE, d MMMM y', 'id').format(_now),
                  greeting: _greeting(),
                  streak: streak,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      children: [
                        if (medicines.isNotEmpty)
                          _MedicineSection(cards: medicines),
                        if (medicines.isNotEmpty && habits.isNotEmpty)
                          const SizedBox(height: 14),
                        if (habits.isNotEmpty) _HabitsSection(rows: habits),
                        if (medicines.isEmpty && habits.isEmpty)
                          const _EmptyTodayState(),
                      ],
                    ),
                  ),
                ),
                _SlideToUnlock(
                  fraction: _slideCtrl.value,
                  onDragUpdate: _onDragUpdate,
                  onDragEnd: _onDragEnd,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GateHeader extends StatelessWidget {
  const _GateHeader({
    required this.timeText,
    required this.dateText,
    required this.greeting,
    required this.streak,
  });

  final String timeText;
  final String dateText;
  final String greeting;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timeText,
            style: const TextStyle(
              fontSize: 64,
              height: 0.95,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dateText,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  greeting,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6D00).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFFFF6D00).withValues(alpha: 0.28),
                  ),
                ),
                child: Text(
                  streak == 0 ? 'Hari pertama!' : 'Hari ke-$streak',
                  style: const TextStyle(
                    color: Color(0xFFFF6D00),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MedicineSection extends StatelessWidget {
  const _MedicineSection({required this.cards});

  final List<_GateMedicineCardData> cards;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SectionLabel(text: '💊 OBAT HARI INI'),
        const SizedBox(height: 10),
        for (int i = 0; i < cards.length; i++) ...[
          _GlassCard(
            child: Column(
              children: [
                for (
                  int rowIndex = 0;
                  rowIndex < cards[i].rows.length;
                  rowIndex++
                ) ...[
                  _MedicineRow(row: cards[i].rows[rowIndex]),
                  if (rowIndex != cards[i].rows.length - 1)
                    const Divider(height: 1, color: _gateLine),
                ],
              ],
            ),
          ),
          if (i != cards.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _HabitsSection extends StatelessWidget {
  const _HabitsSection({required this.rows});

  final List<_GateHabitRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SectionLabel(text: '✦ KEBIASAAN HARI INI'),
        const SizedBox(height: 10),
        _GlassCard(
          child: Column(
            children: [
              for (int i = 0; i < rows.length; i++) ...[
                _HabitRow(row: rows[i]),
                if (i != rows.length - 1)
                  const Divider(height: 1, color: _gateLine),
              ],
            ],
          ),
        ),
      ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth;
          final thumbOffset = fraction * math.max(trackWidth - 56, 0);
          return Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              color: _gatePanel,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white12),
            ),
            child: Stack(
              children: [
                Center(
                  child: Opacity(
                    opacity: (1 - fraction).clamp(0.0, 1.0),
                    child: const Text(
                      'Geser untuk mulai  →→',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
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
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [_gateAccentA, _gateAccentB],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _gateAccentA.withValues(alpha: 0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _gatePanelSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _gateLine),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: child,
      ),
    );
  }
}

class _MedicineRow extends StatelessWidget {
  const _MedicineRow({required this.row});

  final _GateDoseRowData row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              row.timeLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (row.dosage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      row.dosage!,
                      style: const TextStyle(color: _gateMuted, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          Icon(row.state.icon, color: row.state.color, size: 24),
        ],
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({required this.row});

  final _GateHabitRowData row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(row.emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              row.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            row.done
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            color: row.done ? _gateSuccess : Colors.white24,
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _EmptyTodayState extends StatelessWidget {
  const _EmptyTodayState();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: const [
            Icon(Icons.wb_sunny_outlined, color: Colors.white38, size: 32),
            SizedBox(height: 10),
            Text(
              'Belum ada jadwal pagi ini.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Geser untuk lanjut ke game bangun pagi.',
              style: TextStyle(color: _gateMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _GateMedicineCardData {
  const _GateMedicineCardData({required this.rows});

  final List<_GateDoseRowData> rows;
}

class _GateDoseRowData {
  const _GateDoseRowData({
    required this.timeLabel,
    required this.name,
    required this.dosage,
    required this.state,
  });

  final String timeLabel;
  final String name;
  final String? dosage;
  final _GateDoseState state;
}

class _GateHabitRowData {
  const _GateHabitRowData({
    required this.emoji,
    required this.name,
    required this.done,
  });

  final String emoji;
  final String name;
  final bool done;
}

enum _GateDoseState {
  taken(_gateSuccess, Icons.check_circle_rounded),
  pending(_gatePending, Icons.radio_button_unchecked),
  missed(_gateMissed, Icons.cancel_rounded);

  const _GateDoseState(this.color, this.icon);

  final Color color;
  final IconData icon;
}
