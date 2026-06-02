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

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _selected = DateTime.now();
  final _medicineRepo = MedicineRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final added = await _medicineRepo.finalizeMissedDoses();
      if (added > 0 && mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: ValueListenableBuilder<Box<MedicineLog>>(
        valueListenable: Hive.box<MedicineLog>('medicine_logs').listenable(),
        builder: (context, _, _) => ValueListenableBuilder<Box<HabitLog>>(
          valueListenable: Hive.box<HabitLog>('habit_logs').listenable(),
          builder: (context, _, _) => ValueListenableBuilder<Box<WaterLog>>(
            valueListenable: Hive.box<WaterLog>('water_logs').listenable(),
            builder: (context, _, _) {
              final items = _itemsFor(_selected);
              final summary = _summaryFor(items);
              return Scaffold(
                backgroundColor: _navy,
                appBar: AppBar(
                  title: Text(localized(context, id: 'Riwayat', en: 'History')),
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.today_rounded),
                      onPressed: () =>
                          setState(() => _selected = DateTime.now()),
                    ),
                  ],
                ),
                body: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: [
                    _HistoryHero(day: _selected, summary: summary),
                    const SizedBox(height: 16),
                    _RecentDaysPicker(
                      selected: _selected,
                      onSelected: (day) => setState(() => _selected = day),
                    ),
                    const SizedBox(height: 16),
                    if (items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161D2E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(
                          localized(
                            context,
                            id: 'Tidak ada aktivitas pada hari ini.',
                            en: 'Nothing logged on this day.',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.muted),
                        ),
                      )
                    else ...[
                      Text(
                        localized(context, id: 'Aktivitas', en: 'Activity'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _FeedTile(item: item),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
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
    final water = Hive.box<WaterLog>(
      'water_logs',
    ).values.where((log) => log.date == date);
    for (final log in water) {
      if (log.mlLogged <= 0) continue;
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

  _HistorySummary _summaryFor(List<_FeedItem> items) {
    var medicineCount = 0;
    var habitCount = 0;
    var waterCount = 0;
    for (final item in items) {
      if (item.color == AppTheme.medicineColor) {
        medicineCount++;
      } else if (item.color == AppTheme.habitsColor) {
        habitCount++;
      } else if (item.color == AppTheme.waterColor) {
        waterCount++;
      }
    }
    return _HistorySummary(
      medicineCount: medicineCount,
      habitCount: habitCount,
      waterCount: waterCount,
    );
  }
}

class _HistoryHero extends StatelessWidget {
  const _HistoryHero({required this.day, required this.summary});

  final DateTime day;
  final _HistorySummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161D2E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatLongDate(context, day),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            localized(
              context,
              id: 'Ringkasan dari semua fitur',
              en: 'A summary across all features',
            ),
            style: const TextStyle(color: AppTheme.muted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryChip(
                  color: AppTheme.medicineColor,
                  label: localized(context, id: 'Obat', en: 'Medicine'),
                  value: summary.medicineCount,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryChip(
                  color: AppTheme.habitsColor,
                  label: localized(context, id: 'Kebiasaan', en: 'Habits'),
                  value: summary.habitCount,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryChip(
                  color: AppTheme.waterColor,
                  label: localized(context, id: 'Air', en: 'Water'),
                  value: summary.waterCount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentDaysPicker extends StatelessWidget {
  const _RecentDaysPicker({required this.selected, required this.onSelected});

  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(14, (index) {
      return DateTime(today.year, today.month, today.day - (13 - index));
    });
    final weekdayLabels = localizedWeekdayShortLabels(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161D2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final day in days)
            _DayChip(
              label: weekdayLabels[day.weekday - 1],
              dayNumber: day.day,
              selected: _sameDay(day, selected),
              onTap: () => onSelected(day),
              activity: _activityFor(day),
            ),
        ],
      ),
    );
  }
}

List<Color> _activityFor(DateTime day) {
  final date = AppDateUtils.toDateString(day);
  final colors = <Color>[];
  if (Hive.box<HabitLog>('habit_logs').values.any((log) => log.date == date)) {
    colors.add(AppTheme.habitsColor);
  }
  if (Hive.box<MedicineLog>('medicine_logs').values.any(
    (log) =>
        log.status == 'taken' &&
        log.takenAt != null &&
        _sameDay(log.takenAt!, day),
  )) {
    colors.add(AppTheme.medicineColor);
  }
  if (Hive.box<WaterLog>(
    'water_logs',
  ).values.any((log) => log.date == date && log.mlLogged > 0)) {
    colors.add(AppTheme.waterColor);
  }
  return colors;
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.dayNumber,
    required this.selected,
    required this.onTap,
    required this.activity,
  });

  final String label;
  final int dayNumber;
  final bool selected;
  final VoidCallback onTap;
  final List<Color> activity;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFF0F1524),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.white70 : const Color(0xFF222C42),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? _navy : AppTheme.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$dayNumber',
              style: TextStyle(
                color: selected ? _navy : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < activity.length; i++) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: activity[i],
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (i != activity.length - 1) const SizedBox(width: 3),
                ],
                if (activity.isEmpty)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1524),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222C42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 10),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppTheme.muted, fontSize: 12),
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
      color: const Color(0xFF161D2E),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.border),
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
          style: const TextStyle(color: AppTheme.muted, fontSize: 12),
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

class _HistorySummary {
  const _HistorySummary({
    required this.medicineCount,
    required this.habitCount,
    required this.waterCount,
  });

  final int medicineCount;
  final int habitCount;
  final int waterCount;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
String _clock(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
