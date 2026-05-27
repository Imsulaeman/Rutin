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

    return Scaffold(
      appBar: AppBar(title: const Text('Obat')),
      body: ValueListenableBuilder<Box<Medicine>>(
        valueListenable: Hive.box<Medicine>('medicines').listenable(),
        builder: (context, _, __) {
          final medicines = repository.getAll();
          if (medicines.isEmpty) {
            return const Center(child: Text('Belum ada obat.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: medicines.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final medicine = medicines[index];
              final timeLabel = medicine.scheduleTimes
                  .map(_formatMinutes)
                  .join(', ');
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.medication_outlined),
                  title: Text(medicine.name),
                  subtitle: Text(
                    medicine.dosage == null
                        ? 'Jam: $timeLabel'
                        : '${medicine.dosage} • Jam: $timeLabel',
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
            onPressed: () {
              context.push('/medicine/add');
            },
            child: const Icon(Icons.add),
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
          content: Text('Full-block dibuka. Notif ulang tetap jalan tiap 1 menit.'),
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
