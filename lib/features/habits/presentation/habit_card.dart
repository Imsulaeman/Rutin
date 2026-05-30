import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/habit_model.dart';

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
      color: isDone ? AppTheme.habitsColor.withValues(alpha: 0.12) : AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDone
              ? AppTheme.habitsColor.withValues(alpha: 0.35)
              : AppTheme.border,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppTheme.habitsColor.withValues(alpha: 0.2)
                      : AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(habit.emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      streak > 0 ? '$streak hari beruntun 🔥' : 'Mulai hari ini',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: streak > 0
                                ? AppTheme.streakColor
                                : cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isDone
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                size: 24,
                color: isDone ? AppTheme.habitsColor : cs.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
