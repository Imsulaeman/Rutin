import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/notifications/alarm_service.dart';
import '../../../shared/providers/providers.dart';
import '../data/medicine_model.dart';

class AddMedicineScreen extends ConsumerStatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  ConsumerState<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends ConsumerState<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (selected == null) return;
    setState(() => _selectedTime = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repository = ref.read(medicineRepositoryProvider);
    final medicine = Medicine()
      ..id = DateTime.now().millisecondsSinceEpoch.toString()
      ..name = _nameController.text.trim()
      ..dosage = _dosageController.text.trim().isEmpty
          ? null
          : _dosageController.text.trim()
      ..scheduleTimes = [_selectedTime.hour * 60 + _selectedTime.minute]
      ..isActive = true
      ..colorValue = Colors.green.value;

    try {
      await repository.save(medicine);
      await _scheduleInitialAlarm(medicine);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal jadwalkan alarm: $e')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _saving = false);
    context.go('/medicine');
  }

  Future<void> _scheduleInitialAlarm(Medicine medicine) async {
    final minutes = medicine.scheduleTimes.first;
    final next = _nextTime(minutes);
    final alarmId = medicine.id.hashCode & 0x7fffffff;

    await AlarmService.scheduleMedicineAlarm(
      alarmId: alarmId,
      scheduledTime: next,
      medicineName: medicine.name,
      dosage: medicine.dosage,
    );
  }

  DateTime _nextTime(int minutes) {
    final now = DateTime.now();
    var dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      minutes ~/ 60,
      minutes % 60,
    );
    if (!dateTime.isAfter(now)) {
      dateTime = dateTime.add(const Duration(days: 1));
    }
    return dateTime;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Obat')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama obat'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama obat wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(labelText: 'Dosis (opsional)'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),

            Text(
              'WAKTU MINUM',
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
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
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
                      const Text('Waktu minum'),
                      const Spacer(),
                      Text(
                        _timeLabel(_selectedTime),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
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

  static String _timeLabel(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
