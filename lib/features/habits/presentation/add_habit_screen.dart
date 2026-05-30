import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../data/habit_model.dart';
import '../data/habit_repository.dart';
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
  late final TextEditingController _emojiController;

  static const _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  late final Set<int> _selectedDays;

  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _saving = false;

  String? _selectedGroupId;
  late final List<HabitGroup> _groups;

  bool get _isEdit => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _nameController = TextEditingController(text: h?.name ?? '');
    _emojiController = TextEditingController(text: h?.emoji ?? '✅');
    _selectedDays = h?.scheduleDays.toSet() ?? {1, 2, 3, 4, 5, 6, 7};
    _selectedGroupId = h?.groupId;
    _groups = _repo.getGroups();

    if (h?.reminderMinutes != null) {
      _reminderEnabled = true;
      _reminderTime = TimeOfDay(
        hour: h!.reminderMinutes! ~/ 60,
        minute: h.reminderMinutes! % 60,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked != null) setState(() => _reminderTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final habit = widget.habit ??
          (Habit()
            ..id = DateTime.now().millisecondsSinceEpoch.toString()
            ..colorValue = 0
            ..sortIndex = _repo.habitsInGroup(_selectedGroupId).length);
      habit
        ..name = _nameController.text.trim()
        ..emoji = _emojiController.text.trim().isEmpty
            ? '✅'
            : _emojiController.text.trim()
        ..scheduleDays = (_selectedDays.toList()..sort())
        ..groupId = _selectedGroupId
        ..reminderMinutes =
            _reminderEnabled ? _reminderTime.hour * 60 + _reminderTime.minute : null;

      await _repo.save(habit);

      try {
        if (_reminderEnabled) {
          await HabitReminderService.schedule(habit);
        } else {
          await HabitReminderService.cancel(habit.id);
        }
      } catch (_) {}

      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Kebiasaan' : 'Tambah Kebiasaan'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          children: [
            // Name + Emoji
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nama kebiasaan'),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: _emojiController,
                    decoration: const InputDecoration(labelText: 'Emoji'),
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22),
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Group picker
            _label(context, 'RUTINITAS'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Tanpa rutinitas'),
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
                  'Buat rutinitas dulu dari tab Kebiasaan',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            const SizedBox(height: 32),

            // Schedule
            _label(context, 'JADWAL'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (i) {
                final day = i + 1;
                final selected = _selectedDays.contains(day);
                return FilterChip(
                  label: Text(_dayLabels[i]),
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

            // Reminder
            _label(context, 'PENGINGAT'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        const Expanded(child: Text('Aktifkan pengingat')),
                        Switch(
                          value: _reminderEnabled,
                          onChanged: (v) => setState(() => _reminderEnabled = v),
                        ),
                      ],
                    ),
                  ),
                  if (_reminderEnabled) ...[
                    Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
                    InkWell(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      onTap: _pickTime,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 18, color: cs.onSurfaceVariant),
                            const SizedBox(width: 10),
                            const Text('Waktu pengingat'),
                            const Spacer(),
                            Text(
                              _fmtTime(_reminderTime),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: cs.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 40),

            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
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

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
