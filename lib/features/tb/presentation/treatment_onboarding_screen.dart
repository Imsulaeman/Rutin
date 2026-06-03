import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../../l10n/l10n.dart';
import '../../medicine/data/medicine_model.dart';
import '../data/tb_model.dart';

class TreatmentOnboardingScreen extends StatefulWidget {
  const TreatmentOnboardingScreen({super.key});

  @override
  State<TreatmentOnboardingScreen> createState() =>
      _TreatmentOnboardingScreenState();
}

class _TreatmentOnboardingScreenState extends State<TreatmentOnboardingScreen> {
  final _condition = TextEditingController();
  final _customDays = TextEditingController();
  DateTime _start = DateTime.now();
  int _duration = 180;
  String _medicineId = '';
  bool _custom = false;

  @override
  void dispose() {
    _condition.dispose();
    _customDays.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final medicines = Hive.box<Medicine>(
      'medicines',
    ).values.where((m) => m.isActive).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.treatmentProgram),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _condition,
            decoration: InputDecoration(
              labelText: context.l10n.conditionName,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final name in [
                'TB',
                'Tifus',
                'Malaria',
                'ARV',
                'Diabetes',
                'Hipertensi',
              ])
                ActionChip(
                  label: Text(name),
                  onPressed: () => setState(() => _condition.text = name),
                ),
            ],
          ),
          const SizedBox(height: 18),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.l10n.startDateLabel),
            trailing: Text(_date(context, _start)),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          Text(context.l10n.treatmentDuration),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in const [
                (30, '1'),
                (90, '3'),
                (180, '6'),
                (270, '9'),
                (365, '12'),
              ])
                ChoiceChip(
                  selected: !_custom && _duration == option.$1,
                  label: Text(context.l10n.months(option.$2)),
                  onSelected: (_) => setState(() {
                    _duration = option.$1;
                    _custom = false;
                  }),
                ),
              ChoiceChip(
                selected: _custom,
                label: Text(context.l10n.other),
                onSelected: (_) => setState(() => _custom = true),
              ),
            ],
          ),
          if (_custom) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _customDays,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.l10n.numberOfDays,
              ),
            ),
          ],
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: _medicineId,
            decoration: InputDecoration(
              labelText: context.l10n.linkedMedicine,
            ),
            items: [
              DropdownMenuItem(
                value: '',
                child: Text(context.l10n.noLinkedMedicine),
              ),
              for (final medicine in medicines)
                DropdownMenuItem(
                  value: medicine.id,
                  child: Text(medicine.name),
                ),
            ],
            onChanged: (value) => setState(() => _medicineId = value ?? ''),
          ),
          const SizedBox(height: 28),
          FilledButton(onPressed: _save, child: Text(context.l10n.save)),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: Localizations.localeOf(context),
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _save() async {
    final days = _custom ? int.tryParse(_customDays.text) ?? 0 : _duration;
    if (_condition.text.trim().isEmpty || days <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.treatmentValidationError)),
      );
      return;
    }
    final box = Hive.box<TBTreatmentProfile>('tb_profiles');
    final active = box.values.where((profile) => profile.isActive).toList();
    if (active.isNotEmpty) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.replaceActiveProgram),
          content: Text(context.l10n.replaceProgramBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.replace),
            ),
          ],
        ),
      );
      if (replace != true) return;
    }
    for (final profile in active) {
      profile.isActive = false;
      await profile.save();
    }
    await box.add(
      TBTreatmentProfile()
        ..conditionName = _condition.text.trim()
        ..startDate = _start
        ..durationDays = days
        ..medicineId = _medicineId
        ..isActive = true,
    );
    if (mounted) context.pop();
  }
}

String _date(BuildContext context, DateTime date) =>
    DateFormat('d MMM yyyy', context.localeTag).format(date);
