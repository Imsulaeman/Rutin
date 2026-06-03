import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
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
            body: Center(child: Text(context.l10n.noActiveProgramDot)),
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
                        context.l10n.streakDay(days),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: days / profile.durationDays,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        left == 0
                            ? context.l10n.treatmentProgramComplete
                            : context.l10n.daysRemaining(left),
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
                          context.l10n.adherenceLabel(
                            (adherence * 100).round(),
                          ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.l10n.last7Days(recent.$1, recent.$2),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => _sharePdf(context, profile, repo),
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: Text(context.l10n.exportPdf),
              ),
              TextButton(
                onPressed: () => _end(context, profile),
                child: Text(context.l10n.endProgram),
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
        title: Text(context.l10n.endProgramTitle),
        content: Text(context.l10n.endProgramBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.end),
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
        _date(context, day),
        '$scheduled',
        '$taken',
        taken == scheduled && scheduled > 0
            ? context.l10n.complete
            : context.l10n.incomplete,
      ]);
    }
    pdf.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Header(
            level: 0,
            child: pw.Text(context.l10n.pdfTitle),
          ),
          pw.Text('${context.l10n.condition}: ${profile.conditionName}'),
          pw.Text(
            '${context.l10n.startDate}: ${_date(context, profile.startDate)}',
          ),
          pw.Text(
            '${context.l10n.duration}: ${profile.durationDays} ${context.l10n.days}',
          ),
          pw.Text(
            '${context.l10n.medicine}: ${medicine?.name ?? '-'}',
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: [
              context.l10n.date,
              context.l10n.scheduledDoses,
              context.l10n.takenDoses,
              context.l10n.status,
            ],
            data: rows,
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            '${context.l10n.exportedFrom} - ${_date(context, DateTime.now())}',
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

String _date(BuildContext context, DateTime date) =>
    DateFormat('d MMM yyyy', context.localeTag).format(date);
