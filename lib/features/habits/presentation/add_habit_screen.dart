import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/habit_model.dart';
import '../data/habit_repository.dart';
import 'habit_reminder_service.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emojiController = TextEditingController(text: '✅');
  final _repo = HabitRepository();

  static const _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  final _selectedDays = {1, 2, 3, 4, 5, 6, 7};

  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked != null) setState(() => _reminderTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final habit = Habit()
      ..id = DateTime.now().millisecondsSinceEpoch.toString()
      ..name = _nameController.text.trim()
      ..emoji = _emojiController.text.trim().isEmpty
          ? '✅'
          : _emojiController.text.trim()
      ..scheduleDays = (_selectedDays.toList()..sort())
      ..reminderMinutes = _reminderEnabled
          ? _reminderTime.hour * 60 + _reminderTime.minute
          : null
      ..colorValue = 0;

    await _repo.save(habit);
    if (_reminderEnabled) await HabitReminderService.schedule(habit);

    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Kebiasaan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          children: [
            // Name + Emoji row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration:
                        const InputDecoration(labelText: 'Nama kebiasaan'),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama wajib diisi'
                        : null,
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

            // Schedule section
            Text(
              'JADWAL',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
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

            // Reminder section
            Text(
              'PENGINGAT',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.outlineVariant.withOpacity(0.7),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        const Text('Aktifkan pengingat'),
                        const Spacer(),
                        Switch(
                          value: _reminderEnabled,
                          onChanged: (v) =>
                              setState(() => _reminderEnabled = v),
                        ),
                      ],
                    ),
                  ),
                  if (_reminderEnabled) ...[
                    Divider(
                      height: 1,
                      color: cs.outlineVariant.withOpacity(0.5),
                    ),
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
                            Icon(
                              Icons.access_time_rounded,
                              size: 18,
                              color: cs.onSurfaceVariant,
                            ),
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

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
