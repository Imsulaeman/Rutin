import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../l10n/l10n.dart';
import '../../medicine/data/medicine_repository.dart';
import '../data/tb_model.dart';

class TreatmentDetailScreen extends StatelessWidget {
  const TreatmentDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<TBTreatmentProfile>>(
      valueListenable: Hive.box<TBTreatmentProfile>('tb_profiles').listenable(),
      builder: (context, box, _) {
        final profile = box.values.where((p) => p.isActive).firstOrNull;
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(
                localized(
                  context,
                  id: 'Tidak ada program aktif.',
                  en: 'No active program.',
                ),
              ),
            ),
          );
        }
        final repo = MedicineRepository();
        final days = _dayNumber(profile);
        final left = (profile.durationDays - days).clamp(
          0,
          profile.durationDays,
        );
        final adherence = _adherence(profile, repo);
        final recent = _recent(profile, repo);
        return Scaffold(
          appBar: AppBar(title: Text(profile.conditionName)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localized(
                          context,
                          id: 'Hari ke-$days',
                          en: 'Day $days',
                        ),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: days / profile.durationDays,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        left == 0
                            ? localized(
                                context,
                                id: 'Program selesai',
                                en: 'Program complete',
                              )
                            : localized(
                                context,
                                id: '$left hari tersisa',
                                en: '$left days remaining',
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              if (profile.medicineId.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localized(
                            context,
                            id: 'Kepatuhan: ${(adherence * 100).round()}%',
                            en: 'Adherence: ${(adherence * 100).round()}%',
                          ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          localized(
                            context,
                            id: '7 hari terakhir: ${recent.$1}/${recent.$2} dosis',
                            en: 'Last 7 days: ${recent.$1}/${recent.$2} doses',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => _sharePdf(context, profile, repo),
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: Text(
                  localized(context, id: 'Ekspor PDF', en: 'Export PDF'),
                ),
              ),
              TextButton(
                onPressed: () => _end(context, profile),
                child: Text(
                  localized(context, id: 'Akhiri program', en: 'End program'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _end(BuildContext context, TBTreatmentProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          localized(context, id: 'Akhiri program?', en: 'End program?'),
        ),
        content: Text(
          localized(
            context,
            id: 'Program aktif akan dihentikan.',
            en: 'The active program will be stopped.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(localized(context, id: 'Akhiri', en: 'End')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      profile.isActive = false;
      await profile.save();
      if (context.mounted) context.pop();
    }
  }

  Future<void> _sharePdf(
    BuildContext context,
    TBTreatmentProfile profile,
    MedicineRepository repo,
  ) async {
    final medicine = repo.getById(profile.medicineId);
    final pdf = pw.Document();
    final rows = <List<String>>[];
    for (
      var day = DateTime(
        profile.startDate.year,
        profile.startDate.month,
        profile.startDate.day,
      );
      !day.isAfter(DateTime.now());
      day = day.add(const Duration(days: 1))
    ) {
      final scheduled = medicine?.scheduleTimes.length ?? 0;
      var taken = 0;
      for (final minute in medicine?.scheduleTimes ?? const <int>[]) {
        if (repo.isTaken(
          medicine!.id,
          DateTime(day.year, day.month, day.day, minute ~/ 60, minute % 60),
        )) {
          taken++;
        }
      }
      rows.add([
        _date(day),
        '$scheduled',
        '$taken',
        taken == scheduled && scheduled > 0
            ? localized(context, id: 'Lengkap', en: 'Complete')
            : localized(context, id: 'Tidak lengkap', en: 'Incomplete'),
      ]);
    }
    pdf.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              localized(
                context,
                id: 'Rutin - Laporan Kepatuhan Pengobatan',
                en: 'Rutin - Treatment Adherence Report',
              ),
            ),
          ),
          pw.Text(
            '${localized(context, id: 'Kondisi', en: 'Condition')}: ${profile.conditionName}',
          ),
          pw.Text(
            '${localized(context, id: 'Tanggal Mulai', en: 'Start Date')}: ${_date(profile.startDate)}',
          ),
          pw.Text(
            '${localized(context, id: 'Durasi', en: 'Duration')}: ${profile.durationDays} ${localized(context, id: 'hari', en: 'days')}',
          ),
          pw.Text(
            '${localized(context, id: 'Obat', en: 'Medicine')}: ${medicine?.name ?? '-'}',
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: [
              localized(context, id: 'Tanggal', en: 'Date'),
              localized(context, id: 'Dosis Terjadwal', en: 'Scheduled Doses'),
              localized(context, id: 'Dosis Diminum', en: 'Taken Doses'),
              localized(context, id: 'Status', en: 'Status'),
            ],
            data: rows,
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            '${localized(context, id: 'Diekspor dari Rutin', en: 'Exported from Rutin')} - ${_date(DateTime.now())}',
          ),
        ],
      ),
    );
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'rutin-${profile.conditionName.toLowerCase()}.pdf',
    );
  }
}

int _dayNumber(TBTreatmentProfile profile) =>
    (DateTime.now().difference(profile.startDate).inDays + 1).clamp(
      1,
      profile.durationDays,
    );
double _adherence(TBTreatmentProfile profile, MedicineRepository repo) {
  final medicine = repo.getById(profile.medicineId);
  if (medicine == null) return 0;
  var scheduled = 0;
  var taken = 0;
  for (
    var day = profile.startDate;
    !day.isAfter(DateTime.now());
    day = day.add(const Duration(days: 1))
  ) {
    for (final minute in medicine.scheduleTimes) {
      if (_sameDay(day, DateTime.now()) &&
          minute > DateTime.now().hour * 60 + DateTime.now().minute) {
        continue;
      }
      scheduled++;
      if (repo.isTaken(
        medicine.id,
        DateTime(day.year, day.month, day.day, minute ~/ 60, minute % 60),
      )) {
        taken++;
      }
    }
  }
  return scheduled == 0 ? 0 : taken / scheduled;
}

(int, int) _recent(TBTreatmentProfile profile, MedicineRepository repo) {
  final medicine = repo.getById(profile.medicineId);
  if (medicine == null) return (0, 0);
  var scheduled = 0;
  var taken = 0;
  for (var i = 6; i >= 0; i--) {
    final day = DateTime.now().subtract(Duration(days: i));
    if (day.isBefore(profile.startDate)) {
      continue;
    }
    for (final minute in medicine.scheduleTimes) {
      if (_sameDay(day, DateTime.now()) &&
          minute > DateTime.now().hour * 60 + DateTime.now().minute) {
        continue;
      }
      scheduled++;
      if (repo.isTaken(
        medicine.id,
        DateTime(day.year, day.month, day.day, minute ~/ 60, minute % 60),
      )) {
        taken++;
      }
    }
  }
  return (taken, scheduled);
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
