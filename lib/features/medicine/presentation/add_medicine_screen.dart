import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/analytics_service.dart';
import '../../../features/notifications/alarm_service.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/providers.dart';
import '../data/medicine_model.dart';

const _navy = Color(0xFF0B0E1A);
const _surface = Color(0xFF161D2E);
const _surfaceLine = Color(0xFF222C42);
const _medGradient = [Color(0xFFEE5A8C), Color(0xFFD93A6E)];
const _grey = Color(0xFF9AA3B2);

class AddMedicineScreen extends ConsumerStatefulWidget {
  const AddMedicineScreen({super.key, this.medicineId});

  final String? medicineId;

  @override
  ConsumerState<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends ConsumerState<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  late List<TimeOfDay> _times;
  late String _mealTimingKey;
  bool _saving = false;
  Medicine? _existingMedicine;

  bool get _isEdit => _existingMedicine != null;

  @override
  void initState() {
    super.initState();
    final medicine = widget.medicineId == null
        ? null
        : ref.read(medicineRepositoryProvider).getById(widget.medicineId!);
    _existingMedicine = medicine;
    _nameController.text = medicine?.name ?? '';
    _dosageController.text = medicine?.dosage ?? '';
    _times = medicine != null && medicine.scheduleTimes.isNotEmpty
        ? medicine.scheduleTimes
              .map(
                (minutes) =>
                    TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
              )
              .toList()
        : [const TimeOfDay(hour: 8, minute: 0)];
    _mealTimingKey = medicine?.mealTimingKey ?? MedicineMealTiming.bebas;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(int index) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _times[index],
    );
    if (selected == null) return;
    setState(() => _times[index] = selected);
  }

  void _addTime() {
    setState(() => _times = [..._times, const TimeOfDay(hour: 8, minute: 0)]);
  }

  void _removeTime(int index) {
    setState(() => _times = [..._times]..removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repository = ref.read(medicineRepositoryProvider);
    final medicine =
        _existingMedicine ??
              (Medicine()
                ..id = DateTime.now().millisecondsSinceEpoch.toString())
          ..name = _nameController.text.trim()
          ..dosage = _dosageController.text.trim().isEmpty
              ? null
              : _dosageController.text.trim()
          ..scheduleTimes =
              (_times.map((t) => t.hour * 60 + t.minute).toSet().toList()
                ..sort())
          ..isActive = true
          ..colorValue =
              _existingMedicine?.colorValue ?? Colors.green.toARGB32()
          ..mealTimingKey = _mealTimingKey;

    try {
      if (_isEdit) {
        for (final minutes in _existingMedicine!.scheduleTimes) {
          await AlarmService.cancelAllForAlarm(
            AlarmService.medicineRootAlarmId(_existingMedicine!.id, minutes),
          );
        }
      }
      await repository.save(medicine);
      await _scheduleInitialAlarm(medicine);
      if (!_isEdit) {
        AnalyticsService.medicineAdded();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.failedToScheduleAlarm(e.toString())),
        ),
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
        title: Text(
          _isEdit
              ? '${context.l10n.edit} ${context.l10n.medicine}'
              : context.l10n.addMedicine,
        ),
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
                      label: context.l10n.medicineName,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? context.l10n.medicineNameRequired
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _TextField(
                      controller: _dosageController,
                      label: context.l10n.dosage,
                      hintText: context.l10n.dosageHint,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionTitle(context.l10n.scheduleTimes),
              const SizedBox(height: 10),
              _SectionCard(
                child: Column(
                  children: [
                    for (int i = 0; i < _times.length; i++) ...[
                      _TimeRow(
                        time: _times[i],
                        canRemove: _times.length > 1,
                        onTap: () => _pickTime(i),
                        onRemove: () => _removeTime(i),
                      ),
                      const Divider(color: _surfaceLine, height: 1),
                    ],
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _addTime,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: _medGradient.first,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              context.l10n.addTime,
                              style: TextStyle(
                                color: _medGradient.first,
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
              const SizedBox(height: 18),
              _SectionTitle(context.l10n.mealRule),
              const SizedBox(height: 10),
              _SectionCard(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final option in MedicineMealTiming.values)
                      _MealChip(
                        label: medicineMealTimingLabel(context, option),
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
                child: Text(_saving ? context.l10n.saving : context.l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
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

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.time,
    required this.canRemove,
    required this.onTap,
    required this.onRemove,
  });

  final TimeOfDay time;
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
                color: _medGradient.first.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.access_time_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Jadwal dosis',
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
                gradient: const LinearGradient(colors: _medGradient),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _fmtTime(time),
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
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: _grey.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _fmtTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
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
          gradient: selected
              ? const LinearGradient(colors: _medGradient)
              : null,
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
