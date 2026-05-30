import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/notifications/alarm_service.dart';
import '../../../shared/providers/providers.dart';
import '../data/medicine_model.dart';

const _navy = Color(0xFF0B0E1A);
const _surface = Color(0xFF161D2E);
const _surfaceLine = Color(0xFF222C42);
const _medGradient = [Color(0xFFEE5A8C), Color(0xFFD93A6E)];
const _grey = Color(0xFF9AA3B2);

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
  String _mealTimingKey = MedicineMealTiming.bebas;
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
      ..colorValue = Colors.green.toARGB32()
      ..mealTimingKey = _mealTimingKey;

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
    context.pop();
  }

  Future<void> _scheduleInitialAlarm(Medicine medicine) async {
    for (final minutes in medicine.scheduleTimes) {
      await AlarmService.scheduleMedicineAlarm(
        alarmId: AlarmService.medicineRootAlarmId(medicine.id, minutes),
        scheduledTime: _nextTime(minutes),
        scheduledMinutes: minutes,
        medicineName: medicine.name,
        dosage: medicine.dosage,
      );
    }
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
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('Tambah Obat'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _SectionCard(
                child: Column(
                  children: [
                    _TextField(
                      controller: _nameController,
                      label: 'Nama obat',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nama obat wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _TextField(
                      controller: _dosageController,
                      label: 'Dosis',
                      hintText: 'Contoh: 1 tablet',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionTitle('WAKTU MINUM'),
              const SizedBox(height: 10),
              _SectionCard(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _pickTime,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _medGradient.first.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.access_time_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jadwal dosis',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Notifikasi akan terus muncul sampai diminum.',
                              style: TextStyle(color: _grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      _TimePill(label: _timeLabel(_selectedTime)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _SectionTitle('ATURAN MAKAN'),
              const SizedBox(height: 10),
              _SectionCard(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final option in MedicineMealTiming.values)
                      _MealChip(
                        label: MedicineMealTiming.label(option),
                        selected: option == _mealTimingKey,
                        onTap: () => setState(() => _mealTimingKey = option),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _medGradient.last,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                ),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
              ),
            ],
          ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _grey,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _surfaceLine),
      ),
      child: child,
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    this.hintText,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: const TextStyle(color: _grey),
        hintStyle: const TextStyle(color: _grey),
        filled: true,
        fillColor: const Color(0xFF0F1524),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _surfaceLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEE5A8C)),
        ),
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: _medGradient),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MealChip extends StatelessWidget {
  const _MealChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: selected ? const LinearGradient(colors: _medGradient) : null,
          color: selected ? null : const Color(0xFF0F1524),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.transparent : _surfaceLine,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: selected ? 1 : 0.88),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
