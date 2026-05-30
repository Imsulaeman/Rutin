import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/providers.dart';
import '../../notifications/alarm_service.dart';
import '../data/medicine_model.dart';

const _navy = Color(0xFF0B0E1A);
const _surface = Color(0xFF161D2E);
const _surfaceLine = Color(0xFF222C42);
const _amber = Color(0xFFF4A92B);
const _grey = Color(0xFF9AA3B2);

class MedicineArchiveScreen extends ConsumerStatefulWidget {
  const MedicineArchiveScreen({super.key});

  @override
  ConsumerState<MedicineArchiveScreen> createState() =>
      _MedicineArchiveScreenState();
}

class _MedicineArchiveScreenState
    extends ConsumerState<MedicineArchiveScreen> {
  Future<void> _unarchive(String id, Medicine medicine) async {
    HapticFeedback.selectionClick();
    final repo = ref.read(medicineRepositoryProvider);
    await repo.unarchive(id);
    // Reschedule alarms
    for (final minutes in medicine.scheduleTimes) {
      await AlarmService.scheduleMedicineAlarm(
        alarmId: AlarmService.medicineRootAlarmId(id, minutes),
        scheduledTime: _nextTime(minutes),
        scheduledMinutes: minutes,
        medicineName: medicine.name,
        dosage: medicine.dosage,
      );
    }
    if (mounted) setState(() {});
  }

  DateTime _nextTime(int minutes) {
    final now = DateTime.now();
    var t = DateTime(now.year, now.month, now.day, minutes ~/ 60, minutes % 60);
    if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(medicineRepositoryProvider);
    final archived = repo
        .getAllIncludingInactive()
        .where((m) => !m.isActive)
        .toList();

    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('Arsip Obat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: archived.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              itemCount: archived.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _ArchivedCard(
                medicine: archived[i],
                onUnarchive: () => _unarchive(archived[i].id, archived[i]),
              ),
            ),
    );
  }
}

class _ArchivedCard extends StatelessWidget {
  const _ArchivedCard({required this.medicine, required this.onUnarchive});

  final Medicine medicine;
  final VoidCallback onUnarchive;

  @override
  Widget build(BuildContext context) {
    final times = medicine.scheduleTimes
        .map((m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}')
        .join(' - ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _surfaceLine),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ((medicine.dosage ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    medicine.dosage!,
                    style: const TextStyle(color: _grey, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  times,
                  style: const TextStyle(color: _grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _amber,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onUnarchive,
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.archive_outlined,
                size: 34,
                color: _amber,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Arsip kosong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Obat yang diarsipkan akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
