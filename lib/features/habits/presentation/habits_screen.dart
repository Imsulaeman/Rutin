import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/habit_model.dart';
import '../data/habit_repository.dart';
import 'habit_card.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final _repo = HabitRepository();
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
    setState(() {});
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
