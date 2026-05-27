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
                    if (streak > 0) ...[
                      const SizedBox(height: 3),
                      Text(
                        '🔥 $streak hari berturut-turut',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.streakColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
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
