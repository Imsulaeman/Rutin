import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../data/habit_model.dart';
import '../data/habit_repository.dart';
import 'emoji_picker.dart';
import 'habit_reminder_service.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key, this.habit});

  final Habit? habit;

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = HabitRepository();
  late final TextEditingController _nameController;
  late String _emoji;

  late final Set<int> _selectedDays;

  bool _reminderEnabled = false;
  List<int> _reminderTimes = [];
  bool _saving = false;

  String? _selectedGroupId;
  late final List<HabitGroup> _groups;

  bool get _isEdit => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _nameController = TextEditingController(text: h?.name ?? '');
    _emoji = h?.emoji ?? '✅';
    _selectedDays = h?.scheduleDays.toSet() ?? {1, 2, 3, 4, 5, 6, 7};
    _selectedGroupId = h?.groupId;
    _groups = _repo.getGroups();

    if (h != null) {
      _reminderTimes = h.reminderTimes.isNotEmpty
          ? List.of(h.reminderTimes)
          : (h.reminderMinutes != null ? [h.reminderMinutes!] : []);
      _reminderEnabled = _reminderTimes.isNotEmpty;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<TimeOfDay?> _showReminderPicker(int initialMinutes) {
    return showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: initialMinutes ~/ 60,
        minute: initialMinutes % 60,
      ),
    );
  }

  void _toggleReminder(bool enabled) {
    setState(() {
      _reminderEnabled = enabled;
      if (enabled && _reminderTimes.isEmpty) {
        _reminderTimes = [8 * 60];
      } else if (!enabled) {
        _reminderTimes = [];
      }
    });
  }

  void _addTime() {
    setState(() => _reminderTimes = [..._reminderTimes, 8 * 60]);
  }

  Future<void> _pickTime(int index) async {
    final picked = await _showReminderPicker(_reminderTimes[index]);
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    setState(() {
      final next = [..._reminderTimes];
      next[index] = minutes;
      _reminderTimes = next;
    });
  }

  void _removeTime(int index) {
    setState(() => _reminderTimes = [..._reminderTimes]..removeAt(index));
  }

  Future<void> _createGroup() async {
    final nameController = TextEditingController();
    String emoji = '📋';
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.l10n.newRoutine),
          content: Row(
            children: [
              GestureDetector(
                onTap: () async {
                  final picked = await showEmojiPicker(dialogContext);
                  if (picked != null) {
                    setDialogState(() => emoji = picked);
                  }
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: nameController,
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
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.create),
            ),
          ],
        ),
      ),
    );

    final name = nameController.text.trim();
    Future.delayed(const Duration(milliseconds: 300), nameController.dispose);
    if (created != true || name.isEmpty) return;

    final group = HabitGroup()
      ..id = DateTime.now().millisecondsSinceEpoch.toString()
      ..name = name
      ..emoji = emoji
      ..sortIndex = _groups.length;
    await _repo.saveGroup(group);
    if (!mounted) return;
    setState(() {
      _groups.add(group);
      _selectedGroupId = group.id;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      if (widget.habit != null) {
        try {
          await HabitReminderService.cancelAll(widget.habit!);
        } catch (_) {}
      }
      final habit =
          widget.habit ??
          (Habit()
            ..id = DateTime.now().millisecondsSinceEpoch.toString()
            ..colorValue = 0
            ..sortIndex = _repo.habitsInGroup(_selectedGroupId).length);
      final reminderTimes = _reminderTimes.toSet().toList()..sort();
      final scheduleDays = _selectedDays.length == 7
          ? <int>[]
          : (_selectedDays.toList()..sort());
      habit
        ..name = _nameController.text.trim()
        ..emoji = _emoji
        ..scheduleDays = scheduleDays
        ..groupId = _selectedGroupId
        ..reminderTimes = reminderTimes
        ..reminderMinutes = reminderTimes.isNotEmpty
            ? reminderTimes.first
            : null;

      await _repo.save(habit);

      if (_selectedGroupId != null) {
        await _repo.autoSortNewItem(_selectedGroupId!, habit.id);
      }

      try {
        await HabitReminderService.scheduleAll(habit);
      } catch (_) {}

      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.failedToSave(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dayLabels = localizedWeekdayShortLabels(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? context.l10n.editHabit : context.l10n.addHabit),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: context.l10n.habitName,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showEmojiPicker(context);
                    if (picked != null) setState(() => _emoji = picked);
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Center(
                      child: Text(_emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                _label(context, context.l10n.routineLabel),
                const Spacer(),
                TextButton.icon(
                  onPressed: _createGroup,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(context.l10n.add),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(context.l10n.noRoutine),
                  selected: _selectedGroupId == null,
                  onSelected: (_) => setState(() => _selectedGroupId = null),
                ),
                for (final g in _groups)
                  ChoiceChip(
                    label: Text('${g.emoji}  ${g.name}'),
                    selected: _selectedGroupId == g.id,
                    selectedColor: AppTheme.habitsColor.withValues(alpha: 0.25),
                    onSelected: (_) => setState(() => _selectedGroupId = g.id),
                  ),
              ],
            ),
            if (_groups.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  context.l10n.createRoutineHint,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            const SizedBox(height: 32),
            _label(context, context.l10n.scheduleLabel),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (i) {
                final day = i + 1;
                final selected = _selectedDays.contains(day);
                return FilterChip(
                  label: Text(dayLabels[i]),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _selectedDays.add(day);
                    } else {
                      _selectedDays.remove(day);
                    }
                  }),
                );
              }),
            ),
            const SizedBox(height: 32),
            _label(context, context.l10n.reminderLabel),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(context.l10n.enableReminder)),
                        Switch(
                          value: _reminderEnabled,
                          onChanged: _toggleReminder,
                        ),
                      ],
                    ),
                  ),
                  if (_reminderEnabled) ...[
                    Divider(
                      height: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          for (int i = 0; i < _reminderTimes.length; i++) ...[
                            _TimePickerRow(
                              minutes: _reminderTimes[i],
                              canRemove: _reminderTimes.length > 1,
                              onTap: () => _pickTime(i),
                              onRemove: () => _removeTime(i),
                            ),
                            Divider(
                              height: 1,
                              color: cs.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ],
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _addTime,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_rounded,
                                    size: 16,
                                    color: AppTheme.habitsColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    context.l10n.addTime,
                                    style: TextStyle(
                                      color: AppTheme.habitsColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 40),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? context.l10n.saving : context.l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Text(
    text,
    style: Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );

  static String _fmtMinutes(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
}

class _TimePickerRow extends StatelessWidget {
  const _TimePickerRow({
    required this.minutes,
    required this.canRemove,
    required this.onTap,
    required this.onRemove,
  });

  final int minutes;
  final bool canRemove;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.habitsColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.access_time_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.reminderTime,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.habitsColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _AddHabitScreenState._fmtMinutes(minutes),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (canRemove) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppTheme.muted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
