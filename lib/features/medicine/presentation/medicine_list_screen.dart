import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../app.dart';
import '../../notifications/alarm_service.dart';
import '../data/medicine_model.dart';
import '../../../shared/providers/providers.dart';

class MedicineListScreen extends ConsumerWidget {
  const MedicineListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(medicineRepositoryProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Obat')),
      body: ValueListenableBuilder<Box<Medicine>>(
        valueListenable: Hive.box<Medicine>('medicines').listenable(),
        builder: (context, _, __) {
          final medicines = repository.getAll();
          if (medicines.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      size: 56,
                      color: cs.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada obat',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tambah jadwal minum obat\ndengan tombol + di bawah.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: medicines.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final medicine = medicines[index];
              final timeLabel =
                  medicine.scheduleTimes.map(_formatMinutes).join(', ');
              return Dismissible(
                key: ValueKey(medicine.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: cs.error,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: cs.onError,
                  ),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Hapus obat?'),
                      content: Text(
                          '${medicine.name} akan dihapus permanen.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Batal'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: cs.error,
                          ),
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) async {
                  await AlarmService.cancelAllForAlarm(
                    medicine.id.hashCode & 0x7fffffff,
                  );
                  await repository.delete(medicine.id);
                },
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            timeLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                medicine.name,
                                style:
                                    Theme.of(context).textTheme.titleMedium,
                              ),
                              if (medicine.dosage != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  medicine.dosage!,
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'test-full-block',
            onPressed: () => _openFullBlockNow(context),
            child: const Icon(Icons.lock_outline),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add-medicine',
            onPressed: () => context.push('/medicine/add'),
            child: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }

  static String _formatMinutes(int minutes) {
    final hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final min = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$min';
  }

  Future<void> _openFullBlockNow(BuildContext context) async {
    try {
      await AlarmService.scheduleMedicineAlarm(
        alarmId: 777002,
        scheduledTime: DateTime.now().add(const Duration(seconds: 10)),
        medicineName: 'TEST Full Block',
        dosage: 'debug',
        renotifyMinutes: 1,
      );
      openReminderScreen(
        alarmId: 777002,
        medicineName: 'TEST Full Block',
        dosage: 'debug',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Full-block dibuka. Notif ulang tetap jalan tiap 1 menit.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal test full-block: $e')),
      );
    }
  }
}
