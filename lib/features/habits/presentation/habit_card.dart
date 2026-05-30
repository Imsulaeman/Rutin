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
    this.onMoreTap,
  });

  final Habit habit;
  final bool isDone;
  final int streak;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap; // ··· context menu

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                  child: Text(habit.emoji,
                      style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      streak > 0
                          ? '$streak hari beruntun 🔥'
                          : 'Mulai hari ini',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: streak > 0
                                ? AppTheme.streakColor
                                : cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              // ··· menu button — absorbs tap so it doesn't trigger card onTap
              if (onMoreTap != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onMoreTap,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Icon(Icons.more_vert_rounded,
                        size: 18, color: AppTheme.muted),
                  ),
                ),
              const SizedBox(width: 4),
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
