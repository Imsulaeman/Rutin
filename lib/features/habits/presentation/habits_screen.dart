import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/services/analytics_service.dart';
import '../../../core/services/haptics_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../data/habit_model.dart';
import '../data/habit_repository.dart';
import '../data/medal_model.dart';
import '../data/medal_repository.dart';
import 'habit_card.dart';
import 'emoji_picker.dart';
import 'habit_reminder_service.dart';

const _groupTemplates = [
  ('☀️', 'Bangun Tidur'),
  ('🌙', 'Sebelum Tidur'),
  ('🍽️', 'Setelah Makan'),
  ('💪', 'Olahraga'),
  ('📚', 'Belajar'),
  ('🧘', 'Meditasi'),
];

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final _repo = HabitRepository();
  final _medals = MedalRepository();

  List<dynamic> _flatItems = []; // Habit (ungrouped) | HabitGroup
  Map<String, List<Habit>> _groupHabits = {};
  final Map<String, bool> _expanded = {};

  // null = flat/Semua view; non-null = group-specific tab
  String? _selectedGroupId;

  late final ValueListenable<Box<Habit>> _habitsL;
  late final ValueListenable<Box<HabitGroup>> _groupsL;
  late final ValueListenable<Box<HabitLog>> _logsL;

  @override
  void initState() {
    super.initState();
    _habitsL = Hive.box<Habit>('habits').listenable();
    _groupsL = Hive.box<HabitGroup>('habit_groups').listenable();
    _logsL = Hive.box<HabitLog>('habit_logs').listenable();
    _habitsL.addListener(_load);
    _groupsL.addListener(_load);
    _logsL.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _habitsL.removeListener(_load);
    _groupsL.removeListener(_load);
    _logsL.removeListener(_load);
    super.dispose();
  }

  void _load() {
    if (!mounted) return;
    setState(() {
      _flatItems = _repo.getFlatList();
      _groupHabits = {
        for (final g in _repo.getGroups()) g.id: _repo.habitsInGroup(g.id),
      };
      if (_selectedGroupId != null &&
          !_groupHabits.containsKey(_selectedGroupId)) {
        _selectedGroupId = null;
      }
    });
  }

  List<HabitGroup> get _groups => _flatItems.whereType<HabitGroup>().toList();

  List<Habit> get _allHabits => [
    ..._flatItems.whereType<Habit>(),
    for (final habits in _groupHabits.values) ...habits,
  ];

  // ─── Habit actions ────────────────────────────────────────────────────────

  Future<void> _safeCancel(Habit habit) async {
    try {
      await HabitReminderService.cancelAll(habit);
    } catch (_) {}
  }

  Future<void> _markDone(Habit habit) async {
    if (_repo.isCompletedToday(habit.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.habitAlreadyCompleted),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    await _repo.markDone(habit.id);
    AnalyticsService.habitCompleted();
    HapticsService.success();
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

  void _showHabitActions(Habit habit) {
    final groups = _groups;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: Text(context.l10n.edit),
              onTap: () async {
                Navigator.pop(ctx);
                await context.push('/habits/add', extra: habit);
                _load();
              },
            ),
            if (groups.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.drive_file_move_rounded),
                title: Text(context.l10n.habitMoveToRoutine),
                onTap: () {
                  Navigator.pop(ctx);
                  _showMoveToGroup(habit);
                },
              ),
            ListTile(
              leading: const Text('🏅', style: TextStyle(fontSize: 22)),
              title: Text(context.l10n.habitTurnIntoMedal),
              onTap: () {
                Navigator.pop(ctx);
                _retireAsModal(habit);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(context.l10n.delete),
              onTap: () async {
                Navigator.pop(ctx);
                await _confirmDeleteHabit(habit);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showMoveToGroup(Habit habit) async {
    final groups = _groups;
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                context.l10n.moveTo,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            if (habit.groupId != null)
              ListTile(
                leading: const Text('📋', style: TextStyle(fontSize: 20)),
                title: Text(context.l10n.noRoutine),
                onTap: () => Navigator.pop(ctx, ''),
              ),
            for (final g in groups)
              if (g.id != habit.groupId)
                ListTile(
                  leading: Text(g.emoji, style: const TextStyle(fontSize: 20)),
                  title: Text(g.name),
                  onTap: () => Navigator.pop(ctx, g.id),
                ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (result == null) return;
    final newGroupId = result.isEmpty ? null : result;
    final oldGroupId = habit.groupId;

    if (newGroupId == oldGroupId) return;

    habit.groupId = newGroupId;

    if (newGroupId != null) {
      habit.sortIndex = (_repo.habitsInGroup(newGroupId)).length;
      await _repo.save(habit);
      await _repo.autoSortNewItem(newGroupId, habit.id);
    } else {
      habit.sortIndex = _flatItems.length;
      await _repo.save(habit);
    }
    _load();
  }

  Future<void> _confirmDeleteHabit(Habit habit) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deleteHabitTitle),
        content: Text(context.l10n.deleteHabitBody(habit.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _safeCancel(habit);
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
      await _medals.save(
        Medal()
          ..id = DateTime.now().millisecondsSinceEpoch.toString()
          ..name = habit.name
          ..emoji = habit.emoji
          ..peakStreak = streak
          ..awardedAt = DateTime.now()
          ..type = 'habit',
      );
    }

    await _safeCancel(habit);
    await _repo.delete(habit.id);
    _load();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.habitTurnedIntoMedal(habit.emoji, habit.name)),
        ),
      );
    }
  }

  // ─── Group actions ────────────────────────────────────────────────────────

  Future<void> _createGroup() async {
    final nameCtrl = TextEditingController();
    String emoji = '📋';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(context.l10n.newRoutine),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Template',
                  style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in _groupTemplates)
                      GestureDetector(
                        onTap: () {
                          nameCtrl.text = t.$2;
                          setD(() => emoji = t.$1);
                        },
                        child: Chip(
                          label: Text('${t.$1} ${t.$2}'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picked = await showEmojiPicker(ctx);
                        if (picked != null) setD(() => emoji = picked);
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: nameCtrl,
                        autofocus: true,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: context.l10n.routineName,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.create),
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
        ..sortIndex = _flatItems.length;
      await _repo.saveGroup(group);
      _load();
    }
  }

  Future<void> _createGroupFromPair(Habit dragged, Habit target) async {
    final targetIndex = _flatItems.indexWhere(
      (item) => item is Habit && item.id == target.id,
    );
    if (targetIndex == -1) return;

    final nameCtrl = TextEditingController(text: context.l10n.newRoutine);
    String emoji = target.emoji;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(context.l10n.combineIntoRoutine),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Template',
                  style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in _groupTemplates)
                      GestureDetector(
                        onTap: () {
                          nameCtrl.text = t.$2;
                          setD(() => emoji = t.$1);
                        },
                        child: Chip(
                          label: Text('${t.$1} ${t.$2}'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picked = await showEmojiPicker(ctx);
                        if (picked != null) setD(() => emoji = picked);
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: nameCtrl,
                        autofocus: true,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: context.l10n.routineName,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.combine),
            ),
          ],
        ),
      ),
    );

    if (result != true || nameCtrl.text.trim().isEmpty) return;

    final group = HabitGroup()
      ..id = DateTime.now().millisecondsSinceEpoch.toString()
      ..name = nameCtrl.text.trim()
      ..emoji = emoji
      ..sortIndex = targetIndex;
    await _repo.saveGroup(group);

    target
      ..groupId = group.id
      ..sortIndex = 0;
    dragged
      ..groupId = group.id
      ..sortIndex = 1;
    await _repo.save(target);
    await _repo.save(dragged);

    final flat = _repo.getFlatList()
      ..removeWhere(
        (item) =>
            item is Habit && (item.id == target.id || item.id == dragged.id),
      );
    flat.insert(targetIndex.clamp(0, flat.length), group);
    await _repo.reorderFlatList(flat);
    await _repo.reorderHabitsInGroup([target, dragged]);
    _expanded[group.id] = true;
    _load();
  }

  Future<void> _renameGroup(HabitGroup group) async {
    final nameCtrl = TextEditingController(text: group.name);
    String emoji = group.emoji;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(context.l10n.editRoutine),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () async {
                  final picked = await showEmojiPicker(ctx);
                  if (picked != null) setD(() => emoji = picked);
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: context.l10n.routineName,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.save),
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

  Future<bool> _deleteGroup(HabitGroup group) async {
    final habitCount =
        _groupHabits[group.id]?.length ?? _repo.habitsInGroup(group.id).length;

    if (habitCount == 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.deleteRoutineTitle(group.name)),
          content: Text(context.l10n.deleteRoutineBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              child: Text(context.l10n.delete),
            ),
          ],
        ),
      );
      if (ok == true) {
        await _repo.deleteGroup(group.id);
        _load();
        return true;
      }
      return false;
    }

    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deleteRoutineTitle(group.name)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.deleteRoutineWithHabitsBody(habitCount),
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, 'only'),
              child: Text(context.l10n.deleteRoutineOnly),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'all'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              child: Text(context.l10n.deleteRoutineAndHabits),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(context.l10n.cancel),
          ),
        ],
      ),
    );

    if (choice == 'only') {
      await _repo.deleteGroup(group.id);
      _load();
      return true;
    } else if (choice == 'all') {
      final habits = _repo.habitsInGroup(group.id);
      for (final habit in habits) {
        await _safeCancel(habit);
      }
      await _repo.deleteGroupWithHabits(group.id);
      _load();
      return true;
    }
    return false;
  }

  // ─── Reorder ──────────────────────────────────────────────────────────────

  Future<void> _onGroupReorder(
    String groupId,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex--;
    final habits = <Habit>[...(_groupHabits[groupId] ?? [])];
    final habit = habits.removeAt(oldIndex);
    habits.insert(newIndex, habit);
    await _repo.reorderHabitsInGroup(habits);
    _load();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final all = _allHabits;
    final doneCount = all.where((h) => _repo.isCompletedToday(h.id)).length;
    final bestStreak = all.fold<int>(
      0,
      (b, h) => _repo.getStreak(h.id) > b ? _repo.getStreak(h.id) : b,
    );

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(context.l10n.habits),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () => context.push('/habits/history'),
          ),
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
          _TabBar(
            groups: _groups,
            selectedGroupId: _selectedGroupId,
            onSelect: (id) => setState(() => _selectedGroupId = id),
            onCreateGroup: _createGroup,
            onGroupActions: _showGroupActions,
          ),
          Expanded(
            child: _selectedGroupId == null
                ? _EditModeView(
                    flatItems: _flatItems,
                    groupHabits: _groupHabits,
                    expanded: _expanded,
                    repo: _repo,
                    total: all.length,
                    doneCount: doneCount,
                    bestStreak: bestStreak,
                    onTap: _markDone,
                    onMoreTap: _showHabitActions,
                    onToggleExpand: (id) => setState(
                      () => _expanded[id] = !(_expanded[id] ?? true),
                    ),
                    onGroupActions: _showGroupActions,
                    onGroupDelete: _deleteGroup,
                    onDelete: (h) async {
                      await _safeCancel(h);
                      await _repo.delete(h.id);
                      _load();
                    },
                    onReloaded: _load,
                    onEnsureExpanded: (id) =>
                        setState(() => _expanded[id] = true),
                    onCreateGroupFromPair: _createGroupFromPair,
                  )
                : _GroupView(
                    group: _groups.firstWhere((g) => g.id == _selectedGroupId),
                    habits: _groupHabits[_selectedGroupId] ?? [],
                    repo: _repo,
                    onTap: _markDone,
                    onMoreTap: _showHabitActions,
                    onReorder: (o, n) =>
                        _onGroupReorder(_selectedGroupId!, o, n),
                    onDelete: (h) async {
                      await _safeCancel(h);
                      await _repo.delete(h.id);
                      _load();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showGroupActions(HabitGroup g) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: Text(context.l10n.editNameAndEmoji),
              onTap: () {
                Navigator.pop(ctx);
                _renameGroup(g);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(context.l10n.deleteRoutine),
              onTap: () {
                Navigator.pop(ctx);
                _deleteGroup(g);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
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
    required this.onCreateGroup,
    required this.onGroupActions,
  });

  final List<HabitGroup> groups;
  final String? selectedGroupId;
  final void Function(String?) onSelect;
  final VoidCallback onCreateGroup;
  final void Function(HabitGroup) onGroupActions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _Tab(
            label: context.l10n.all,
            selected: selectedGroupId == null,
            onTap: () => onSelect(null),
          ),
          for (final g in groups)
            _Tab(
              label: '${g.emoji}  ${g.name}',
              selected: selectedGroupId == g.id,
              onTap: () => onSelect(g.id),
              onLongPress: () => onGroupActions(g),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Center(
              child: GestureDetector(
                onTap: onCreateGroup,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: AppTheme.muted,
                  ),
                ),
              ),
            ),
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
    this.onLongPress,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.noHabitsYet,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.habitsEmptyHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
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
        border: Border.all(color: AppTheme.habitsColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.smallStepsBigChange,
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
      key: ValueKey('swipe_${habit.id}'),
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
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.deleteHabitTitle),
          content: Text(context.l10n.deleteHabitBody(habit.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: cs.error),
              child: Text(context.l10n.delete),
            ),
          ],
        ),
      ),
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
            streak > 0
                ? context.l10n.streakDaysRow(streak)
                : context.l10n.noStreakYet,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: streak > 0 ? cs.primary : cs.onSurfaceVariant,
              fontWeight: streak > 0 ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            context.l10n.retireHabitDescription,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.retireHabitButton),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
        ],
      ),
    );
  }
}

// ─── Edit mode view ───────────────────────────────────────────────────────────

class _EditModeView extends StatefulWidget {
  const _EditModeView({
    required this.flatItems,
    required this.groupHabits,
    required this.expanded,
    required this.repo,
    required this.total,
    required this.doneCount,
    required this.bestStreak,
    required this.onTap,
    required this.onMoreTap,
    required this.onToggleExpand,
    required this.onGroupActions,
    required this.onGroupDelete,
    required this.onDelete,
    required this.onReloaded,
    required this.onEnsureExpanded,
    required this.onCreateGroupFromPair,
  });

  final List<dynamic> flatItems;
  final Map<String, List<Habit>> groupHabits;
  final Map<String, bool> expanded;
  final HabitRepository repo;
  final int total;
  final int doneCount;
  final int bestStreak;
  final void Function(Habit) onTap;
  final void Function(Habit) onMoreTap;
  final void Function(String) onToggleExpand;
  final void Function(HabitGroup) onGroupActions;
  final Future<bool> Function(HabitGroup) onGroupDelete;
  final Future<void> Function(Habit) onDelete;
  final VoidCallback onReloaded;
  final void Function(String groupId) onEnsureExpanded;
  final Future<void> Function(Habit dragged, Habit target)
  onCreateGroupFromPair;

  @override
  State<_EditModeView> createState() => _EditModeViewState();
}

class _EditModeViewState extends State<_EditModeView> {
  bool _isDragging = false;
  bool _draggingHabit = false;

  Future<void> _handleDrop(
    Object item, {
    int? flatIndex,
    String? intoGroupId,
    int? groupPos,
  }) async {
    if (item is Habit) {
      final oldGroupId = item.groupId;

      if (intoGroupId != null) {
        item.groupId = intoGroupId;
        await widget.repo.save(item);
        final gh = widget.repo.habitsInGroup(intoGroupId);
        gh.removeWhere((h) => h.id == item.id);
        final pos = (groupPos ?? gh.length).clamp(0, gh.length);
        gh.insert(pos, item);
        await widget.repo.reorderHabitsInGroup(gh);
        if (oldGroupId != intoGroupId) {
          await widget.repo.autoSortNewItem(intoGroupId, item.id);
        }
        widget.onEnsureExpanded(intoGroupId);
      } else {
        item.groupId = null;
        await widget.repo.save(item);
        final flat = widget.repo.getFlatList();
        final cur = flat.indexWhere((f) => f is Habit && f.id == item.id);
        if (cur != -1) flat.removeAt(cur);
        int idx = flatIndex ?? flat.length;
        if (cur != -1 && cur < idx) idx--;
        flat.insert(idx.clamp(0, flat.length), item);
        await widget.repo.reorderFlatList(flat);
      }
    } else if (item is HabitGroup) {
      final flat = widget.repo.getFlatList();
      final cur = flat.indexWhere((f) => f is HabitGroup && f.id == item.id);
      if (cur != -1) flat.removeAt(cur);
      int idx = flatIndex ?? flat.length;
      if (cur != -1 && cur < idx) idx--;
      flat.insert(idx.clamp(0, flat.length), item);
      await widget.repo.reorderFlatList(flat);
      widget.onEnsureExpanded(item.id);
    }

    widget.onReloaded();
  }

  Future<void> _handleMergeDrop(Habit dragged, Habit target) async {
    if (dragged.id == target.id) return;
    await widget.onCreateGroupFromPair(dragged, target);
    if (!mounted) return;
    setState(() {
      _isDragging = false;
      _draggingHabit = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final rows = <Widget>[];

    if (widget.total > 0) {
      rows.add(
        _TodayHeader(
          done: widget.doneCount,
          total: widget.total,
          bestStreak: widget.bestStreak,
        ),
      );
    }

    rows.add(
      _DropZone(
        active: _isDragging,
        onDrop: (item) => _handleDrop(item, flatIndex: 0),
      ),
    );

    for (var i = 0; i < widget.flatItems.length; i++) {
      final item = widget.flatItems[i];

      if (item is Habit) {
        rows.add(
          LongPressDraggable<Object>(
            data: item,
            delay: const Duration(milliseconds: 350),
            onDragStarted: () => setState(() {
              _isDragging = true;
              _draggingHabit = true;
            }),
            onDragEnd: (_) => setState(() {
              _isDragging = false;
              _draggingHabit = false;
            }),
            onDraggableCanceled: (_, _) => setState(() {
              _isDragging = false;
              _draggingHabit = false;
            }),
            feedback: _DragFeedback(
              width: sw - 32,
              child: HabitCard(
                habit: item,
                isDone: widget.repo.isCompletedToday(item.id),
                streak: widget.repo.getStreak(item.id),
                onTap: () {},
              ),
            ),
            childWhenDragging: _DragGhost(height: 64),
            child: _SwipeToDelete(
              habit: item,
              onDelete: () => widget.onDelete(item),
              child: _UngroupedHabitDropTarget(
                active: _isDragging && _draggingHabit,
                target: item,
                onAcceptHabit: _handleMergeDrop,
                child: HabitCard(
                  habit: item,
                  isDone: widget.repo.isCompletedToday(item.id),
                  streak: widget.repo.getStreak(item.id),
                  onTap: () => widget.onTap(item),
                  onMoreTap: () => widget.onMoreTap(item),
                ),
              ),
            ),
          ),
        );
      } else if (item is HabitGroup) {
        final habits = widget.groupHabits[item.id] ?? [];
        final isExpanded = widget.expanded[item.id] ?? true;
        rows.add(
          Dismissible(
            key: ValueKey('group_dismiss_${item.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
            confirmDismiss: (_) async {
              await widget.onGroupDelete(item);
              return false;
            },
            child: _EditGroupBlock(
              group: item,
              habits: habits,
              isExpanded: isExpanded,
              isDragging: _isDragging,
              draggingHabit: _draggingHabit,
              repo: widget.repo,
              screenWidth: sw,
              onToggleExpand: () => widget.onToggleExpand(item.id),
              onGroupActions: () => widget.onGroupActions(item),
              onHabitTap: widget.onTap,
              onHabitMoreTap: widget.onMoreTap,
              onHabitDelete: widget.onDelete,
              onGroupDragStart: () => setState(() {
                _isDragging = true;
                _draggingHabit = false;
              }),
              onGroupDragEnd: () => setState(() {
                _isDragging = false;
                _draggingHabit = false;
              }),
              onHabitDragStart: () => setState(() {
                _isDragging = true;
                _draggingHabit = true;
              }),
              onHabitDragEnd: () => setState(() {
                _isDragging = false;
                _draggingHabit = false;
              }),
              onDropIntoGroup: (dropped, pos) =>
                  _handleDrop(dropped, intoGroupId: item.id, groupPos: pos),
            ),
          ),
        );
      }

      rows.add(
        _DropZone(
          active: _isDragging,
          onDrop: (dropped) => _handleDrop(dropped, flatIndex: i + 1),
        ),
      );
    }

    if (widget.flatItems.isEmpty) {
      rows.add(const _EmptyState());
    }

    rows.add(const SizedBox(height: 16));
    rows.add(const _DragHint());
    rows.add(const SizedBox(height: 12));
    rows.add(const _MascotBanner());
    rows.add(const SizedBox(height: 80));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      children: rows,
    );
  }
}

// ─── Edit group block ─────────────────────────────────────────────────────────

class _EditGroupBlock extends StatelessWidget {
  const _EditGroupBlock({
    required this.group,
    required this.habits,
    required this.isExpanded,
    required this.isDragging,
    required this.draggingHabit,
    required this.repo,
    required this.screenWidth,
    required this.onToggleExpand,
    required this.onGroupActions,
    required this.onHabitTap,
    required this.onHabitMoreTap,
    required this.onHabitDelete,
    required this.onGroupDragStart,
    required this.onGroupDragEnd,
    required this.onHabitDragStart,
    required this.onHabitDragEnd,
    required this.onDropIntoGroup,
  });

  final HabitGroup group;
  final List<Habit> habits;
  final bool isExpanded;
  final bool isDragging;
  final bool draggingHabit;
  final HabitRepository repo;
  final double screenWidth;
  final VoidCallback onToggleExpand;
  final VoidCallback onGroupActions;
  final void Function(Habit) onHabitTap;
  final void Function(Habit) onHabitMoreTap;
  final Future<void> Function(Habit) onHabitDelete;
  final VoidCallback onGroupDragStart;
  final VoidCallback onGroupDragEnd;
  final VoidCallback onHabitDragStart;
  final VoidCallback onHabitDragEnd;
  final void Function(Object item, int pos) onDropIntoGroup;

  Widget _groupFeedback() => Container(
    width: screenWidth - 32,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: AppTheme.surfaceDark,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.habitsColor),
    ),
    child: Row(
      children: [
        Text(group.emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Text(
          group.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final doneCount = habits.where((h) => repo.isCompletedToday(h.id)).length;
    final stackStreak = habits.isEmpty
        ? 0
        : habits.fold<int>(
            repo.getStreak(habits.first.id),
            (min, h) {
              final s = repo.getStreak(h.id);
              return s < min ? s : min;
            },
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          LongPressDraggable<Object>(
            data: group,
            delay: const Duration(milliseconds: 350),
            onDragStarted: onGroupDragStart,
            onDragEnd: (_) => onGroupDragEnd(),
            onDraggableCanceled: (_, _) => onGroupDragEnd(),
            feedback: Material(
              color: Colors.transparent,
              child: _groupFeedback(),
            ),
            childWhenDragging: _DragGhost(height: 52),
            child: InkWell(
              onTap: onToggleExpand,
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(16),
                bottom: Radius.circular(isExpanded ? 0 : 16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                child: Row(
                  children: [
                    Text(group.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        group.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (habits.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.habitsColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$doneCount/${habits.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.habitsColor,
                          ),
                        ),
                      ),
                    if (stackStreak > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '🔥 $stackStreak',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.streakColor,
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onGroupActions,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.more_vert_rounded,
                          size: 18,
                          color: AppTheme.muted,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.muted,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: AppTheme.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  _DropZone(
                    active: isDragging && draggingHabit,
                    onDrop: (item) => onDropIntoGroup(item, 0),
                  ),
                  for (var j = 0; j < habits.length; j++) ...[
                    LongPressDraggable<Object>(
                      data: habits[j],
                      delay: const Duration(milliseconds: 350),
                      onDragStarted: onHabitDragStart,
                      onDragEnd: (_) => onHabitDragEnd(),
                      onDraggableCanceled: (_, _) => onHabitDragEnd(),
                      feedback: _DragFeedback(
                        width: screenWidth - 56,
                        child: HabitCard(
                          habit: habits[j],
                          isDone: false,
                          streak: 0,
                          onTap: () {},
                        ),
                      ),
                      childWhenDragging: _DragGhost(height: 64),
                      child: _SwipeToDelete(
                        habit: habits[j],
                        onDelete: () => onHabitDelete(habits[j]),
                        child: HabitCard(
                          habit: habits[j],
                          isDone: repo.isCompletedToday(habits[j].id),
                          streak: repo.getStreak(habits[j].id),
                          onTap: () => onHabitTap(habits[j]),
                          onMoreTap: () => onHabitMoreTap(habits[j]),
                        ),
                      ),
                    ),
                    _DropZone(
                      active: isDragging && draggingHabit,
                      onDrop: (item) => onDropIntoGroup(item, j + 1),
                    ),
                  ],
                  if (habits.isEmpty)
                    _DropZone(
                      active: isDragging && draggingHabit,
                      onDrop: (item) => onDropIntoGroup(item, 0),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Drag helpers ─────────────────────────────────────────────────────────────

class _DropZone extends StatelessWidget {
  const _DropZone({required this.active, required this.onDrop});

  final bool active;
  final void Function(Object) onDrop;

  @override
  Widget build(BuildContext context) {
    if (!active) return const SizedBox(height: 4);
    return DragTarget<Object>(
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (_, candidates, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: candidates.isNotEmpty ? 44 : 16,
        margin: candidates.isNotEmpty
            ? const EdgeInsets.symmetric(vertical: 2)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: candidates.isNotEmpty
              ? AppTheme.habitsColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: candidates.isNotEmpty
              ? Border.all(
                  color: AppTheme.habitsColor.withValues(alpha: 0.6),
                  width: 1.5,
                )
              : null,
        ),
        child: candidates.isNotEmpty
            ? const Center(
                child: Icon(
                  Icons.add_rounded,
                  color: AppTheme.habitsColor,
                  size: 20,
                ),
              )
            : null,
      ),
    );
  }
}

class _UngroupedHabitDropTarget extends StatelessWidget {
  const _UngroupedHabitDropTarget({
    required this.active,
    required this.target,
    required this.onAcceptHabit,
    required this.child,
  });

  final bool active;
  final Habit target;
  final Future<void> Function(Habit dragged, Habit target) onAcceptHabit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    return DragTarget<Object>(
      onWillAcceptWithDetails: (details) =>
          details.data is Habit &&
          (details.data as Habit).groupId == null &&
          target.groupId == null &&
          (details.data as Habit).id != target.id,
      onAcceptWithDetails: (details) async {
        final dragged = details.data;
        if (dragged is Habit) {
          await onAcceptHabit(dragged, target);
        }
      },
      builder: (context, candidates, rejected) {
        final highlighted = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: highlighted
                ? Border.all(
                    color: AppTheme.habitsColor.withValues(alpha: 0.7),
                    width: 1.5,
                  )
                : null,
          ),
          child: Stack(
            children: [
              child,
              if (highlighted)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.habitsColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTheme.habitsColor),
                        ),
                        child: Text(
                          context.l10n.combineIntoRoutine,
                          style: TextStyle(
                            color: AppTheme.habitsColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DragHint extends StatelessWidget {
  const _DragHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.touch_app_rounded, size: 13, color: AppTheme.muted),
        const SizedBox(width: 6),
        Text(
          'Tahan item untuk mengatur posisi',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.muted, fontSize: 11),
        ),
      ],
    );
  }
}

class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.width, required this.child});
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        elevation: 8,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(opacity: 0.92, child: child),
      ),
    );
  }
}

class _DragGhost extends StatelessWidget {
  const _DragGhost({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.habitsColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.habitsColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
    );
  }
}

class _GroupView extends StatelessWidget {
  const _GroupView({
    required this.group,
    required this.habits,
    required this.repo,
    required this.onTap,
    required this.onMoreTap,
    required this.onReorder,
    required this.onDelete,
  });

  final HabitGroup group;
  final List<Habit> habits;
  final HabitRepository repo;
  final void Function(Habit) onTap;
  final void Function(Habit) onMoreTap;
  final void Function(int, int) onReorder;
  final Future<void> Function(Habit) onDelete;

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            context.l10n.groupEmptyHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      onReorder: onReorder,
      itemCount: habits.length + 1,
      itemBuilder: (ctx, i) {
        if (i == habits.length) {
          return const Padding(
            key: ValueKey('mascot'),
            padding: EdgeInsets.only(top: 16),
            child: _MascotBanner(),
          );
        }
        final habit = habits[i];
        return ReorderableDelayedDragStartListener(
          key: ValueKey('group_h_${habit.id}'),
          index: i,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SwipeToDelete(
              habit: habit,
              onDelete: () => onDelete(habit),
              child: HabitCard(
                habit: habit,
                isDone: repo.isCompletedToday(habit.id),
                streak: repo.getStreak(habit.id),
                onTap: () => onTap(habit),
                onMoreTap: () => onMoreTap(habit),
              ),
            ),
          ),
        );
      },
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
      margin: const EdgeInsets.only(bottom: 12),
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
                  builder: (_, v, _) => SizedBox(
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
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
                  allDone ? context.l10n.allDone : context.l10n.doneToday,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  bestStreak > 0
                      ? '🔥 Beruntun terbaik $bestStreak hari'
                      : 'Centang kebiasaan untuk mulai streak',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
