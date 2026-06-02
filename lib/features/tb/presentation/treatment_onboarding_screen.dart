import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
        title: Text(
          localized(context, id: 'Program Pengobatan', en: 'Treatment Program'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _condition,
            decoration: InputDecoration(
              labelText: localized(
                context,
                id: 'Nama kondisi',
                en: 'Condition name',
              ),
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
            title: Text(
              localized(context, id: 'Tanggal mulai', en: 'Start date'),
            ),
            trailing: Text(_date(_start)),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          Text(
            localized(
              context,
              id: 'Durasi pengobatan',
              en: 'Treatment duration',
            ),
          ),
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
                  label: Text(
                    localized(
                      context,
                      id: '${option.$2} bulan',
                      en: '${option.$2} months',
                    ),
                  ),
                  onSelected: (_) => setState(() {
                    _duration = option.$1;
                    _custom = false;
                  }),
                ),
              ChoiceChip(
                selected: _custom,
                label: Text(localized(context, id: 'Lainnya', en: 'Other')),
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
                labelText: localized(
                  context,
                  id: 'Jumlah hari',
                  en: 'Number of days',
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            value: _medicineId,
            decoration: InputDecoration(
              labelText: localized(
                context,
                id: 'Obat yang digunakan (opsional)',
                en: 'Linked medicine (optional)',
              ),
            ),
            items: [
              DropdownMenuItem(
                value: '',
                child: Text(
                  localized(
                    context,
                    id: 'Tanpa obat terhubung',
                    en: 'No linked medicine',
                  ),
                ),
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
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _save() async {
    final days = _custom ? int.tryParse(_customDays.text) ?? 0 : _duration;
    if (_condition.text.trim().isEmpty || days <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localized(
              context,
              id: 'Isi nama kondisi dan durasi yang valid.',
              en: 'Enter a condition and valid duration.',
            ),
          ),
        ),
      );
      return;
    }
    final box = Hive.box<TBTreatmentProfile>('tb_profiles');
    final active = box.values.where((profile) => profile.isActive).toList();
    if (active.isNotEmpty) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            localized(
              context,
              id: 'Ganti program aktif?',
              en: 'Replace active program?',
            ),
          ),
          content: Text(
            localized(
              context,
              id: 'Program sebelumnya akan dihentikan.',
              en: 'The previous program will be stopped.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(localized(context, id: 'Ganti', en: 'Replace')),
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

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
