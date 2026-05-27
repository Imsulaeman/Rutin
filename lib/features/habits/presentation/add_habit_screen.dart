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
    final picked = await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked != null) setState(() => _reminderTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final habit = Habit()
      ..id = DateTime.now().millisecondsSinceEpoch.toString()
      ..name = _nameController.text.trim()
      ..emoji = _emojiController.text.trim().isEmpty ? '✅' : _emojiController.text.trim()
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
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Kebiasaan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama kebiasaan'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emojiController,
              decoration: const InputDecoration(labelText: 'Emoji'),
              maxLength: 4,
            ),
            const SizedBox(height: 16),
            const Text('Jadwal', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
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
            const SizedBox(height: 16),
            const Divider(),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pengingat',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Switch(
                  value: _reminderEnabled,
                  onChanged: (v) => setState(() => _reminderEnabled = v),
                ),
              ],
            ),
            if (_reminderEnabled)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Waktu pengingat'),
                subtitle: Text(_fmtTime(_reminderTime)),
                trailing: const Icon(Icons.access_time),
                onTap: _pickTime,
              ),
            const SizedBox(height: 32),
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
