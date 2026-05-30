import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _HabitsScreenState extends State<HabitsScreen> {
  final _repo = HabitRepository();
  final _medals = MedalRepository();
  List<HabitGroup> _groups = [];
  List<Habit> _allHabits = [];
  String? _selectedGroupId; // null = "Semua"

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _groups = _repo.getGroups();
      _allHabits = _repo.getAll();
    });
  }

  Future<void> _safeCancel(String id) async {
    try {
      await HabitReminderService.cancel(id);
    } catch (_) {}
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
    HapticFeedback.mediumImpact();
    _updateMedal(habit);
    setState(() {});
  }

  void _updateMedal(Habit habit) {
    final streak = _repo.getStreak(habit.id);
    final medal = _medals.findByHabit(habit.name, habit.emoji);
    if (medal != null && streak > medal.peakStreak) {
      medal.peakStreak = streak;
      _medals.save(medal);
    }
  }

  void _showActions(Habit habit) {
    showModalBottomSheet(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit'),
              onTap: () async {
                Navigator.pop(sheetCtx);
                await context.push('/habits/add', extra: habit);
                _load();
              },
            ),
            ListTile(
              leading: const Text('🏅', style: TextStyle(fontSize: 22)),
              title: const Text('Jadikan medali'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _retireAsModal(habit);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded,
                  color: Theme.of(context).colorScheme.error),
              title: const Text('Hapus'),
              onTap: () async {
                Navigator.pop(sheetCtx);
                await _confirmDelete(habit);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Habit habit) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus kebiasaan?'),
        content: Text('${habit.name} akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _safeCancel(habit.id);
      await _repo.delete(habit.id);
      _load();
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

    await _safeCancel(habit.id);
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

  Future<void> _createGroup() async {
    final nameCtrl = TextEditingController();
    String emoji = '📋';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Rutinitas baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final e = await _pickEmoji(ctx);
                      if (e != null) setD(() => emoji = e);
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(emoji,
                            style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration:
                          const InputDecoration(labelText: 'Nama rutinitas'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Buat'),
            ),
          ],
        ),
      ),
    );
    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      final group = HabitGroup()
        ..id = DateTime.now().millisecondsSinceEpoch.toString()
        ..name = nameCtrl.text.trim()
        ..emoji = emoji
        ..sortIndex = _groups.length;
      await _repo.saveGroup(group);
      _load();
    }
  }

  Future<void> _renameGroup(HabitGroup group) async {
    final nameCtrl = TextEditingController(text: group.name);
    String emoji = group.emoji;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Ubah rutinitas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final e = await _pickEmoji(ctx);
                      if (e != null) setD(() => emoji = e);
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(emoji,
                            style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration:
                          const InputDecoration(labelText: 'Nama rutinitas'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      group
        ..name = nameCtrl.text.trim()
        ..emoji = emoji;
      await _repo.saveGroup(group);
      _load();
    }
  }

  Future<void> _deleteGroup(HabitGroup group) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus "${group.name}"?'),
        content: const Text(
            'Kebiasaan di rutinitas ini akan dipindah ke "Tanpa rutinitas".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _repo.deleteGroup(group.id);
      if (_selectedGroupId == group.id) _selectedGroupId = null;
      _load();
    }
  }

  Future<String?> _pickEmoji(BuildContext ctx) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('Pilih emoji'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 4,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 32),
          decoration: const InputDecoration(hintText: '📋'),
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
              const SizedBox.shrink(),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(
                dCtx, ctrl.text.trim().isEmpty ? null : ctrl.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _onReorder(String groupId, int oldIndex, int newIndex) async {
    final habits = _repo.habitsInGroup(groupId);
    if (newIndex > oldIndex) newIndex--;
    final item = habits.removeAt(oldIndex);
    habits.insert(newIndex, item);
    await _repo.reorderHabitsInGroup(habits);
    setState(() => _allHabits = _repo.getAll());
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = _allHabits.where((h) => _repo.isCompletedToday(h.id)).length;
    final bestStreak = _allHabits.fold<int>(
        0, (b, h) => _repo.getStreak(h.id) > b ? _repo.getStreak(h.id) : b);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Kebiasaan'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              await context.push('/habits/add');
              _load();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          if (_groups.isNotEmpty)
            _TabBar(
              groups: _groups,
              selectedGroupId: _selectedGroupId,
              onSelect: (id) => setState(() => _selectedGroupId = id),
            ),
          // Content
          Expanded(
            child: _selectedGroupId == null
                ? _SemuaView(
                    groups: _groups,
                    allHabits: _allHabits,
                    repo: _repo,
                    doneCount: doneCount,
                    bestStreak: bestStreak,
                    onTap: _markDone,
                    onLongPress: _showActions,
                    onDelete: (h) async {
                      await _safeCancel(h.id);
                      await _repo.delete(h.id);
                      _load();
                    },
                    onRename: _renameGroup,
                    onDeleteGroup: _deleteGroup,
                    onCreateGroup: _createGroup,
                  )
                : _GroupView(
                    group: _groups.firstWhere((g) => g.id == _selectedGroupId),
                    habits: _repo.habitsInGroup(_selectedGroupId),
                    repo: _repo,
                    onTap: _markDone,
                    onLongPress: _showActions,
                    onReorder: (oldIdx, newIdx) =>
                        _onReorder(_selectedGroupId!, oldIdx, newIdx),
                    onRename: _renameGroup,
                    onDeleteGroup: _deleteGroup,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab bar ──────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.groups,
    required this.selectedGroupId,
    required this.onSelect,
  });

  final List<HabitGroup> groups;
  final String? selectedGroupId;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _Tab(
            label: 'Semua',
            selected: selectedGroupId == null,
            onTap: () => onSelect(null),
          ),
          for (final g in groups)
            _Tab(
              label: '${g.emoji}  ${g.name}',
              selected: selectedGroupId == g.id,
              onTap: () => onSelect(g.id),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.habitsColor.withValues(alpha: 0.2)
                : AppTheme.surfaceHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppTheme.habitsColor : AppTheme.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppTheme.habitsColor : AppTheme.muted,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Semua view ───────────────────────────────────────────────────────────────

class _SemuaView extends StatelessWidget {
  const _SemuaView({
    required this.groups,
    required this.allHabits,
    required this.repo,
    required this.doneCount,
    required this.bestStreak,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
    required this.onRename,
    required this.onDeleteGroup,
    required this.onCreateGroup,
  });

  final List<HabitGroup> groups;
  final List<Habit> allHabits;
  final HabitRepository repo;
  final int doneCount;
  final int bestStreak;
  final void Function(Habit) onTap;
  final void Function(Habit) onLongPress;
  final Future<void> Function(Habit) onDelete;
  final Future<void> Function(HabitGroup) onRename;
  final Future<void> Function(HabitGroup) onDeleteGroup;
  final VoidCallback onCreateGroup;

  @override
  Widget build(BuildContext context) {
    final ungrouped = allHabits.where((h) => h.groupId == null).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        if (allHabits.isNotEmpty)
          _TodayHeader(
            done: doneCount,
            total: allHabits.length,
            bestStreak: bestStreak,
          ),
        for (final group in groups) ...[
          const SizedBox(height: 20),
          _GroupHeader(
            group: group,
            onRename: () => onRename(group),
            onDelete: () => onDeleteGroup(group),
          ),
          const SizedBox(height: 8),
          for (final habit in repo.habitsInGroup(group.id))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SwipeToDelete(
                habit: habit,
                onDelete: () => onDelete(habit),
                child: HabitCard(
                  habit: habit,
                  isDone: repo.isCompletedToday(habit.id),
                  streak: repo.getStreak(habit.id),
                  onTap: () => onTap(habit),
                  onLongPress: () => onLongPress(habit),
                ),
              ),
            ),
        ],
        if (ungrouped.isNotEmpty) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              '📋  Tanpa rutinitas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          for (final habit in ungrouped)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SwipeToDelete(
                habit: habit,
                onDelete: () => onDelete(habit),
                child: HabitCard(
                  habit: habit,
                  isDone: repo.isCompletedToday(habit.id),
                  streak: repo.getStreak(habit.id),
                  onTap: () => onTap(habit),
                  onLongPress: () => onLongPress(habit),
                ),
              ),
            ),
        ],
        if (allHabits.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                Icon(Icons.auto_awesome_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.outlineVariant),
                const SizedBox(height: 12),
                Text('Belum ada kebiasaan',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Tap + untuk menambah kebiasaan pertamamu',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        _NewGroupButton(onTap: onCreateGroup),
        const SizedBox(height: 16),
        const _MascotBanner(),
      ],
    );
  }
}

// ─── Group view (with drag reorder) ──────────────────────────────────────────

class _GroupView extends StatelessWidget {
  const _GroupView({
    required this.group,
    required this.habits,
    required this.repo,
    required this.onTap,
    required this.onLongPress,
    required this.onReorder,
    required this.onRename,
    required this.onDeleteGroup,
  });

  final HabitGroup group;
  final List<Habit> habits;
  final HabitRepository repo;
  final void Function(Habit) onTap;
  final void Function(Habit) onLongPress;
  final void Function(int oldIndex, int newIndex) onReorder;
  final Future<void> Function(HabitGroup) onRename;
  final Future<void> Function(HabitGroup) onDeleteGroup;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _GroupHeader(
            group: group,
            onRename: () => onRename(group),
            onDelete: () => onDeleteGroup(group),
          ),
        ),
        Expanded(
          child: habits.isEmpty
              ? Center(
                  child: Text(
                    'Belum ada kebiasaan di rutinitas ini.\nTap + untuk menambah.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  buildDefaultDragHandles: false,
                  itemCount: habits.length,
                  onReorder: onReorder,
                  itemBuilder: (context, i) {
                    final habit = habits[i];
                    return Padding(
                      key: ValueKey(habit.id),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          ReorderableDragStartListener(
                            index: i,
                            child: const Padding(
                              padding: EdgeInsets.fromLTRB(0, 0, 8, 0),
                              child: Icon(Icons.drag_handle_rounded,
                                  color: AppTheme.muted, size: 22),
                            ),
                          ),
                          Expanded(
                            child: HabitCard(
                              habit: habit,
                              isDone: repo.isCompletedToday(habit.id),
                              streak: repo.getStreak(habit.id),
                              onTap: () => onTap(habit),
                              onLongPress: () => onLongPress(habit),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _MascotBanner(),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({
    required this.done,
    required this.total,
    required this.bestStreak,
  });

  final int done;
  final int total;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = total > 0 ? done / total : 0.0;
    final allDone = total > 0 && done == total;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: pct),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(
                      value: v,
                      strokeWidth: 5,
                      backgroundColor: AppTheme.surfaceHigh,
                      valueColor: AlwaysStoppedAnimation(
                        allDone ? AppTheme.streakColor : AppTheme.habitsColor,
                      ),
                    ),
                  ),
                ),
                Text(
                  '$done/$total',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allDone ? 'Semua selesai! 🎉' : 'Selesai hari ini',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  bestStreak > 0
                      ? '🔥 Beruntun terbaik $bestStreak hari'
                      : 'Centang kebiasaan untuk mulai streak',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.group,
    required this.onRename,
    required this.onDelete,
  });

  final HabitGroup group;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(group.emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            group.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.more_horiz_rounded, size: 20),
          color: AppTheme.muted,
          visualDensity: VisualDensity.compact,
          onPressed: () => showModalBottomSheet(
            context: context,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.edit_rounded),
                    title: const Text('Ubah nama & emoji'),
                    onTap: () {
                      Navigator.pop(ctx);
                      onRename();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.delete_outline_rounded,
                        color: Theme.of(context).colorScheme.error),
                    title: const Text('Hapus rutinitas'),
                    onTap: () {
                      Navigator.pop(ctx);
                      onDelete();
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NewGroupButton extends StatelessWidget {
  const _NewGroupButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppTheme.border)),
        TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Buat rutinitas baru'),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.muted,
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        const Expanded(child: Divider(color: AppTheme.border)),
      ],
    );
  }
}

class _MascotBanner extends StatelessWidget {
  const _MascotBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.habitsColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.habitsColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Langkah kecil setiap hari\nmembawa perubahan besar ✨',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    height: 1.4,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Image.asset('assets/star_mascot.webp', height: 72),
        ],
      ),
    );
  }
}

class _SwipeToDelete extends StatelessWidget {
  const _SwipeToDelete({
    required this.habit,
    required this.onDelete,
    required this.child,
  });

  final Habit habit;
  final Future<void> Function() onDelete;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey('dismiss_${habit.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: cs.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline_rounded, color: cs.onError),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus kebiasaan?'),
            content: Text('${habit.name} akan dihapus permanen.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: cs.error),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: child,
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
                  fontWeight:
                      streak > 0 ? FontWeight.w600 : FontWeight.w400,
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
