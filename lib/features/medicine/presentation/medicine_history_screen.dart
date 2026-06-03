import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../shared/providers/providers.dart';
import '../../../l10n/l10n.dart';
import '../data/medicine_model.dart';
import '../data/medicine_repository.dart';

const _navy = Color(0xFF0B0E1A);
const _surface = Color(0xFF161D2E);
const _surfaceLine = Color(0xFF222C42);
const _grey = Color(0xFF9AA3B2);
const _green = Color(0xFF4CC56A);
const _amber = Color(0xFFF4A92B);
const _red = Color(0xFFF36B5B);

class MedicineHistoryScreen extends ConsumerStatefulWidget {
  const MedicineHistoryScreen({super.key});

  @override
  ConsumerState<MedicineHistoryScreen> createState() =>
      _MedicineHistoryScreenState();
}

class _MedicineHistoryScreenState extends ConsumerState<MedicineHistoryScreen> {
  late DateTime _month;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(medicineRepositoryProvider).finalizeMissedDoses().then((added) {
        if (added > 0 && mounted) setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(medicineRepositoryProvider);
    final medicines = repo.getAllIncludingInactive();
    final days = _daysForMonth(_month);
    final selectedDoses = _dosesForDay(medicines, _selectedDay);

    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: Text(context.l10n.medicineHistory),
      ),
      body: ValueListenableBuilder<Box<MedicineLog>>(
        valueListenable: Hive.box<MedicineLog>('medicine_logs').listenable(),
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
              _Legend(),
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
                              style: TextStyle(
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
                        final state = _dayState(repo, medicines, day);
                        final selected = _sameDay(day, _selectedDay);
                        return GestureDetector(
                          onTap: () => setState(() => _selectedDay = day),
                          child: Container(
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : const Color(0xFF0F1524),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected ? Colors.white54 : _surfaceLine,
                              ),
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
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SelectedDayCard(
                day: _selectedDay,
                doses: selectedDoses,
                repo: repo,
              ),
            ],
          );
        },
      ),
    );
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
            _monthLabel(context, month),
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
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _LegendItem(label: context.l10n.allTaken, color: _green),
        _LegendItem(label: context.l10n.partial, color: _amber),
        _LegendItem(label: context.l10n.missed, color: _red),
        _LegendItem(label: context.l10n.noSchedule, color: _grey),
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

class _SelectedDayCard extends StatelessWidget {
  const _SelectedDayCard({
    required this.day,
    required this.doses,
    required this.repo,
  });

  final DateTime day;
  final List<_HistoryDose> doses;
  final MedicineRepository repo;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            _dayLabel(context, day),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.reviewDoses,
            style: TextStyle(color: _grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (doses.isEmpty)
            Text(
              context.l10n.noMedicineForDay,
              style: TextStyle(color: _grey),
            )
          else
            for (int i = 0; i < doses.length; i++) ...[
              _HistoryDoseTile(
                dose: doses[i],
                status: _historyStatus(repo, doses[i]),
              ),
              if (i != doses.length - 1) const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _HistoryDose {
  const _HistoryDose(this.medicine, this.scheduled);

  final Medicine medicine;
  final DateTime scheduled;
}

class _HistoryDoseTile extends StatelessWidget {
  const _HistoryDoseTile({required this.dose, required this.status});

  final _HistoryDose dose;
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'taken' => _green,
      'upcoming' => _amber,
      'missed' => _red,
      _ => _grey,
    };
    final label = switch (status) {
      'taken' => context.l10n.taken,
      'upcoming' => context.l10n.notDueYet,
      'missed' => context.l10n.missed,
      _ => context.l10n.noLogYet,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1524),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _surfaceLine),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dose.medicine.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ((dose.medicine.dosage ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    dose.medicine.dosage!,
                    style: const TextStyle(color: _grey, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  medicineMealTimingLabel(context, dose.medicine.mealTimingKey),
                  style: const TextStyle(color: _grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmtClock(dose.scheduled),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
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

List<DateTime?> _daysForMonth(DateTime month) {
  final firstDay = DateTime(month.year, month.month, 1);
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  final leading = firstDay.weekday % 7;
  return [
    for (int i = 0; i < leading; i++) null,
    for (int day = 1; day <= daysInMonth; day++)
      DateTime(month.year, month.month, day),
  ];
}

List<_HistoryDose> _dosesForDay(List<Medicine> medicines, DateTime day) {
  final doses = <_HistoryDose>[];
  for (final medicine in medicines) {
    for (final minute in medicine.scheduleTimes) {
      doses.add(
        _HistoryDose(
          medicine,
          DateTime(day.year, day.month, day.day, minute ~/ 60, minute % 60),
        ),
      );
    }
  }
  doses.sort((a, b) => a.scheduled.compareTo(b.scheduled));
  return doses;
}

String _dayState(
  MedicineRepository repo,
  List<Medicine> medicines,
  DateTime day,
) {
  final doses = _dosesForDay(medicines, day);
  if (doses.isEmpty) return 'empty';

  var taken = 0;
  var missed = 0;
  for (final dose in doses) {
    final status = _historyStatus(repo, dose);
    if (status == 'taken') taken++;
    if (status == 'missed') missed++;
  }
  if (taken == doses.length) return 'taken';
  if (taken > 0) return 'partial';
  if (missed > 0) return 'missed';
  return 'empty';
}

String _historyStatus(MedicineRepository repo, _HistoryDose dose) {
  if (repo.isTaken(dose.medicine.id, dose.scheduled)) return 'taken';
  if (repo.isMissed(dose.medicine.id, dose.scheduled)) return 'missed';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final doseDay = DateTime(
    dose.scheduled.year,
    dose.scheduled.month,
    dose.scheduled.day,
  );
  if (doseDay.isBefore(today)) return 'upcoming';
  if (dose.scheduled.isAfter(now)) return 'upcoming';
  return 'missed';
}

Color _stateColor(String state) {
  switch (state) {
    case 'taken':
      return _green;
    case 'partial':
      return _amber;
    case 'missed':
      return _red;
    default:
      return _grey;
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _fmtClock(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _monthLabel(BuildContext context, DateTime month) =>
    formatMonthYear(context, month);

String _dayLabel(BuildContext context, DateTime day) =>
    formatLongDate(context, day);
