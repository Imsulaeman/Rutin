import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../l10n/l10n.dart';
import '../../habits/data/habit_model.dart';
import '../../medicine/data/medicine_model.dart';
import '../../medicine/data/medicine_repository.dart';
import '../../water/data/water_model.dart';

const _navy = Color(0xFF0B0E1A);
const _surface = Color(0xFF161D2E);
const _surfaceLine = Color(0xFF222C42);
const _grey = Color(0xFF9AA3B2);

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late DateTime _month;
  late DateTime _selectedDay;
  final _medicineRepo = MedicineRepository();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final added = await _medicineRepo.finalizeMissedDoses();
      if (added > 0 && mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: Text(localized(context, id: 'Riwayat', en: 'History')),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded),
            onPressed: _jumpToToday,
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<MedicineLog>>(
        valueListenable: Hive.box<MedicineLog>('medicine_logs').listenable(),
        builder: (context, _, _) => ValueListenableBuilder<Box<HabitLog>>(
          valueListenable: Hive.box<HabitLog>('habit_logs').listenable(),
          builder: (context, _, _) => ValueListenableBuilder<Box<WaterLog>>(
            valueListenable: Hive.box<WaterLog>('water_logs').listenable(),
            builder: (context, _, _) {
              final days = _daysForMonth(_month);
              final items = _itemsFor(_selectedDay);
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  _MonthHeader(
                    month: _month,
                    onPrev: () => _shiftMonth(-1),
                    onNext: () => _shiftMonth(1),
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
                            final selected = _sameDay(day, _selectedDay);
                            final isToday = _sameDay(day, DateTime.now());
                            final markers = _markersFor(day);
                            return GestureDetector(
                              onTap: () => setState(() => _selectedDay = day),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : const Color(0xFF0F1524),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: selected
                                        ? Colors.white70
                                        : isToday
                                        ? Colors.white24
                                        : _surfaceLine,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${day.day}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        for (var i = 0;
                                            i < markers.length && i < 3;
                                            i++) ...[
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: markers[i],
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          if (i != markers.length - 1 &&
                                              i < 2)
                                            const SizedBox(width: 4),
                                        ],
                                        if (markers.isEmpty)
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.12,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
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
                  _SelectedDayCard(day: _selectedDay, items: items),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _month = DateTime(now.year, now.month);
      _selectedDay = DateTime(now.year, now.month, now.day);
    });
  }

  void _shiftMonth(int offset) {
    final nextMonth = DateTime(_month.year, _month.month + offset);
    final maxDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    final nextDay = _selectedDay.day.clamp(1, maxDay);
    setState(() {
      _month = DateTime(nextMonth.year, nextMonth.month);
      _selectedDay = DateTime(nextMonth.year, nextMonth.month, nextDay);
    });
  }

  List<Color> _markersFor(DateTime day) {
    final date = AppDateUtils.toDateString(day);
    final markers = <Color>[];
    if (Hive.box<MedicineLog>('medicine_logs').values.any(
      (log) =>
          log.status == 'taken' &&
          log.takenAt != null &&
          _sameDay(log.takenAt!, day),
    )) {
      markers.add(AppTheme.medicineColor);
    }
    if (Hive.box<HabitLog>('habit_logs').values.any((log) => log.date == date)) {
      markers.add(AppTheme.habitsColor);
    }
    if (Hive.box<WaterLog>(
      'water_logs',
    ).values.any((log) => log.date == date && log.mlLogged > 0)) {
      markers.add(AppTheme.waterColor);
    }
    return markers;
  }

  List<_FeedItem> _itemsFor(DateTime day) {
    final date = AppDateUtils.toDateString(day);
    final medicines = Hive.box<Medicine>('medicines');
    final habits = Hive.box<Habit>('habits');
    final items = <_FeedItem>[];

    for (final log in Hive.box<MedicineLog>('medicine_logs').values) {
      if (log.status != 'taken' ||
          log.takenAt == null ||
          !_sameDay(log.takenAt!, day)) {
        continue;
      }
      final name =
          medicines.get(log.medicineId)?.name ??
          localized(context, id: 'Obat', en: 'Medicine');
      items.add(
        _FeedItem(
          color: AppTheme.medicineColor,
          title: localized(context, id: 'Minum $name', en: 'Took $name'),
          trailing: _clock(log.takenAt!),
          sortTime: log.takenAt!,
        ),
      );
    }

    for (final log in Hive.box<HabitLog>('habit_logs').values) {
      if (log.date != date) continue;
      final habit = habits.get(log.habitId);
      items.add(
        _FeedItem(
          color: AppTheme.habitsColor,
          title: habit == null
              ? localized(
                  context,
                  id: 'Kebiasaan selesai',
                  en: 'Habit completed',
                )
              : '${habit.emoji} ${habit.name}',
          trailing: localized(context, id: 'Selesai', en: 'Completed'),
        ),
      );
    }

    for (final log in Hive.box<WaterLog>('water_logs').values) {
      if (log.date != date || log.mlLogged <= 0) continue;
      items.add(
        _FeedItem(
          color: AppTheme.waterColor,
          title: localized(
            context,
            id: 'Minum ${log.mlLogged} ml air',
            en: 'Drank ${log.mlLogged} ml of water',
          ),
          trailing: localized(context, id: 'dicatat', en: 'logged'),
        ),
      );
    }

    items.sort((a, b) => b.sortTime.compareTo(a.sortTime));
    return items;
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
        _LegendItem(
          label: localized(context, id: 'Obat', en: 'Medicine'),
          color: AppTheme.medicineColor,
        ),
        _LegendItem(
          label: localized(context, id: 'Kebiasaan', en: 'Habits'),
          color: AppTheme.habitsColor,
        ),
        _LegendItem(
          label: localized(context, id: 'Air', en: 'Water'),
          color: AppTheme.waterColor,
        ),
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
  const _SelectedDayCard({required this.day, required this.items});

  final DateTime day;
  final List<_FeedItem> items;

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
            formatLongDate(context, day),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            localized(
              context,
              id: 'Aktivitas terbaru untuk tanggal ini.',
              en: 'Recent activity for this day.',
            ),
            style: const TextStyle(color: _grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Text(
              localized(
                context,
                id: 'Tidak ada aktivitas pada hari ini.',
                en: 'Nothing logged on this day.',
              ),
              style: const TextStyle(color: _grey),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FeedTile(item: item),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeedTile extends StatelessWidget {
  const _FeedTile({required this.item});

  final _FeedItem item;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    decoration: BoxDecoration(
      color: const Color(0xFF0F1524),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _surfaceLine),
    ),
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          item.trailing,
          style: const TextStyle(color: _grey, fontSize: 12),
        ),
      ],
    ),
  );
}

class _FeedItem {
  _FeedItem({
    required this.color,
    required this.title,
    required this.trailing,
    DateTime? sortTime,
  }) : sortTime = sortTime ?? DateTime(1970);

  final Color color;
  final String title;
  final String trailing;
  final DateTime sortTime;
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

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _clock(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
