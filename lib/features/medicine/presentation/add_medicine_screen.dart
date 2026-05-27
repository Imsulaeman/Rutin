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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Obat')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama obat'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama obat wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosis (opsional)',
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Waktu minum'),
                subtitle: Text(_timeLabel(_selectedTime)),
                trailing: const Icon(Icons.access_time),
                onTap: _pickTime,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  static String _timeLabel(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
