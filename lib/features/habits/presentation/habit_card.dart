import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/habit_model.dart';

// Star count milestones: 3/7/14/30/60 days
int _starsForStreak(int streak) {
  if (streak >= 60) return 5;
  if (streak >= 30) return 4;
  if (streak >= 14) return 3;
  if (streak >= 7)  return 2;
  if (streak >= 3)  return 1;
  return 0;
}

class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.isDone,
    required this.streak,
    required this.onTap,
    this.onLongPress,
  });

  final Habit habit;
  final bool isDone;
  final int streak;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: isDone ? AppTheme.habitsColor.withOpacity(0.12) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDone
              ? AppTheme.habitsColor.withOpacity(0.3)
              : AppTheme.border,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppTheme.habitsColor.withOpacity(0.2)
                      : AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    habit.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    _StarRow(streak: streak),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                size: 28,
                color: isDone ? AppTheme.habitsColor : cs.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    final filled = _starsForStreak(streak);
    return Row(
      children: List.generate(5, (i) {
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(
            i < filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 14,
            color: i < filled
                ? AppTheme.streakColor
                : AppTheme.muted.withOpacity(0.4),
          ),
        );
      }),
    );
  }
}
