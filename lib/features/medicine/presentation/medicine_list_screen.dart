import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/theme/app_theme.dart';
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
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.medicineColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.medication_outlined,
                        size: 36,
                        color: AppTheme.medicineColor,
                      ),
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.delete_outline_rounded, color: cs.onError),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Hapus obat?'),
                      content: Text('${medicine.name} akan dihapus permanen.'),
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
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.medicineColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            timeLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.medicineColor,
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
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (medicine.dosage != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  medicine.dosage!,
                                  style: Theme.of(context).textTheme.bodySmall,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/medicine/add'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  static String _formatMinutes(int minutes) {
    final hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final min = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$min';
  }
}
