import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
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

class _HabitsScreenState extends State<HabitsScreen>
    with SingleTickerProviderStateMixin {
  final _repo = HabitRepository();
  final _medals = MedalRepository();
  List<Habit> _habits = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _load() => setState(() => _habits = _repo.getAll());

  List<Habit> get _filtered {
    if (_tabController.index == 0) {
      // Pagi: no reminder or reminder before noon (720 min)
      return _habits.where((h) =>
          h.reminderMinutes == null || h.reminderMinutes! < 720).toList();
    } else {
      // Sore: reminder from noon onward
      return _habits.where((h) =>
          h.reminderMinutes != null && h.reminderMinutes! >= 720).toList();
    }
  }

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
    final cs = Theme.of(context).colorScheme;
    final visible = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kebiasaan'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pagi'),
            Tab(text: 'Sore'),
          ],
          indicatorColor: AppTheme.habitsColor,
          labelColor: AppTheme.habitsColor,
          unselectedLabelColor: AppTheme.muted,
          dividerColor: AppTheme.border,
        ),
      ),
      body: visible.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 56,
                      color: cs.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _habits.isEmpty
                          ? 'Belum ada kebiasaan'
                          : 'Tidak ada kebiasaan di sesi ini',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _habits.isEmpty
                          ? 'Tambah kebiasaan pertamamu\ndengan tombol + di bawah.'
                          : 'Coba tab yang lain atau tambah kebiasaan baru.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: visible.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final h = visible[i];
                return Dismissible(
                  key: ValueKey(h.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: cs.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: cs.onError,
                    ),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Hapus kebiasaan?'),
                        content: Text(
                          '${h.name} akan dihapus permanen tanpa dijadikan medali.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Batal'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: cs.error,
                            ),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) async {
                    await HabitReminderService.cancel(h.id);
                    await _repo.delete(h.id);
                    _load();
                  },
                  child: HabitCard(
                    habit: h,
                    isDone: _repo.isCompletedToday(h.id),
                    streak: _repo.getStreak(h.id),
                    onTap: () => _markDone(h),
                    onLongPress: () => _retireAsModal(h),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/habits/add');
          _load();
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ─── Retire sheet ─────────────────────────────────────────────────────────────

class _RetireSheet extends StatelessWidget {
  const _RetireSheet({required this.habit, required this.streak});
  final Habit habit;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(habit.emoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 10),
          Text(habit.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            streak > 0 ? '$streak hari berturut-turut' : 'Belum ada streak',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: streak > 0 ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: streak > 0 ? FontWeight.w600 : FontWeight.w400,
                ),
          ),
          const SizedBox(height: 20),
          Text(
            'Kebiasaan ini akan dihapus dari daftar aktif dan disimpan sebagai medali pencapaian.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('🏅  Jadikan Medali'),
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
