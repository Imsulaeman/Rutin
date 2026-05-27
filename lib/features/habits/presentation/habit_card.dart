import 'package:flutter/material.dart';
import '../data/habit_model.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.isDone,
    required this.streak,
    required this.onTap,
  });

  final Habit habit;
  final bool isDone;
  final int streak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Text(habit.emoji, style: const TextStyle(fontSize: 28)),
        title: Text(habit.name),
        subtitle: streak > 0 ? Text('$streak hari berturut-turut') : null,
        trailing: Icon(
          isDone ? Icons.check_circle : Icons.circle_outlined,
          color: isDone
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}
