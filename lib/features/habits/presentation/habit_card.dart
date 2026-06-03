import 'package:flutter/material.dart';

import '../../../core/services/haptics_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../data/habit_model.dart';
import '../data/habit_repository.dart';

/// Returns the nearest upcoming reminder time for [habit] today.
/// Falls back to the smallest time (tomorrow's first reminder) if all passed.
int? nearestReminderMinutes(Habit habit) {
  final times = habit.reminderTimes.isNotEmpty
      ? List<int>.from(habit.reminderTimes)
      : (habit.reminderMinutes != null ? [habit.reminderMinutes!] : <int>[]);
  if (times.isEmpty) return null;
  times.sort();
  final nowMin = DateTime.now().hour * 60 + DateTime.now().minute;
  final upcoming = times.where((t) => t > nowMin).toList();
  return upcoming.isNotEmpty ? upcoming.first : times.first;
}

class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.isDone,
    required this.isScheduledToday,
    required this.streak,
    required this.onTap,
    this.onMoreTap,
  });

  final Habit habit;
  final bool isDone;
  final bool isScheduledToday;
  final int streak;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final repo = HabitRepository();
    final target = repo.dailyTarget(habit);
    final completions = repo.completionsToday(habit.id).clamp(0, target);
    final scheduleLabel = _scheduleLabel(context);
    return Card(
      color: isDone
          ? AppTheme.habitsColor.withValues(alpha: 0.12)
          : AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDone
              ? AppTheme.habitsColor.withValues(alpha: 0.35)
              : AppTheme.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppTheme.habitsColor.withValues(alpha: 0.2)
                      : AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    habit.emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            habit.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (streak > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '🔥 $streak',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.streakColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scheduleLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (nearestReminderMinutes(habit) != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.alarm_rounded,
                            size: 11,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _fmtTime(nearestReminderMinutes(habit)!),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                    if (target > 0) ...[
                      const SizedBox(height: 6),
                      _CompletionDots(
                        target: target,
                        completions: completions,
                        enabled: isScheduledToday,
                        onTap: (index) async {
                          if (!isScheduledToday) {
                            onTap();
                            return;
                          }
                          final next = index + 1 == completions
                              ? index
                              : index + 1;
                          if (next < completions) {
                            HapticsService.softTap();
                          } else if (next == target) {
                            HapticsService.success();
                          } else {
                            HapticsService.tap();
                          }
                          await repo.setCompletionsToday(habit, next);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              if (onMoreTap != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onMoreTap,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Icon(
                      Icons.more_vert_rounded,
                      size: 18,
                      color: AppTheme.muted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _scheduleLabel(BuildContext context) {
    if (habit.scheduleDays.isEmpty) {
      return context.l10n.everyDay;
    }
    final labels = localizedWeekdayShortLabels(context);
    final sortedDays = [...habit.scheduleDays]..sort();
    return sortedDays
        .where((day) => day >= 1 && day <= 7)
        .map((day) => labels[day - 1])
        .join(', ');
  }

  static String _fmtTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

class _CompletionDots extends StatelessWidget {
  const _CompletionDots({
    required this.target,
    required this.completions,
    required this.enabled,
    required this.onTap,
  });

  final int target;
  final int completions;
  final bool enabled;
  final Future<void> Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < target; i++) ...[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(i),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < completions
                      ? AppTheme.habitsColor
                      : Colors.transparent,
                  border: Border.all(
                    color: i < completions
                        ? AppTheme.habitsColor
                        : enabled
                        ? AppTheme.muted
                        : AppTheme.border,
                  ),
                ),
                child: i < completions
                    ? const Icon(
                        Icons.check_rounded,
                        size: 11,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          ),
          if (i != target - 1) const SizedBox(width: 2),
        ],
      ],
    );
  }
}
