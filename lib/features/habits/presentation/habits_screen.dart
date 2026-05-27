import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/habit_model.dart';
import '../data/habit_repository.dart';
import '../data/medal_model.dart';
import '../data/medal_repository.dart';
import 'habit_card.dart';
import 'habit_reminder_service.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final _repo = HabitRepository();
  final _medals = MedalRepository();
  List<Habit> _habits = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _habits = _repo.getAll());

  Future<void> _markDone(Habit habit) async {
    if (_repo.isCompletedToday(habit.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sudah dilakukan hari ini'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    await _repo.markDone(habit.id);
    _autoUpdateMedal(habit);
    setState(() {});
  }

  void _autoUpdateMedal(Habit habit) {
    final streak = _repo.getStreak(habit.id);
    final medal = _medals.findByHabit(habit.name, habit.emoji);
    if (medal != null && streak > medal.peakStreak) {
      medal.peakStreak = streak;
      _medals.save(medal);
    }
  }

  Future<void> _retireAsModal(Habit habit) async {
    final streak = _repo.getStreak(habit.id);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (_) => _RetireSheet(habit: habit, streak: streak),
    );
    if (confirmed != true) return;

    // Create or update medal
    final existing = _medals.findByHabit(habit.name, habit.emoji);
    if (existing != null) {
      if (streak > existing.peakStreak) {
        existing.peakStreak = streak;
        await _medals.save(existing);
      }
    } else {
      final medal = Medal()
        ..id = DateTime.now().millisecondsSinceEpoch.toString()
        ..name = habit.name
        ..emoji = habit.emoji
        ..peakStreak = streak
        ..awardedAt = DateTime.now()
        ..type = 'habit';
      await _medals.save(medal);
    }

    await HabitReminderService.cancel(habit.id);
    await _repo.delete(habit.id);
    _load();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${habit.emoji} ${habit.name} dijadikan medali!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kebiasaan')),
      body: _habits.isEmpty
          ? const Center(
              child: Text(
                'Belum ada kebiasaan.\nTambah dengan tombol + di bawah.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _habits.length,
              itemBuilder: (context, i) {
                final h = _habits[i];
                return HabitCard(
                  habit: h,
                  isDone: _repo.isCompletedToday(h.id),
                  streak: _repo.getStreak(h.id),
                  onTap: () => _markDone(h),
                  onLongPress: () => _retireAsModal(h),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/habits/add');
          _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RetireSheet extends StatelessWidget {
  const _RetireSheet({required this.habit, required this.streak});
  final Habit habit;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(habit.emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(
            habit.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            streak > 0 ? '$streak hari berturut-turut' : 'Belum ada streak',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          Text(
            'Jadikan medali akan menghapus kebiasaan ini dari daftar aktif dan menyimpannya sebagai pencapaian.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Text('🏅'),
            label: const Text('Jadikan Medali'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }
}
