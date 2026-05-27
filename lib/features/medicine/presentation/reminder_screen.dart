import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../notifications/notification_handler.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({
    super.key,
    required this.alarmId,
    required this.medicineName,
    this.dosage,
  });

  final int alarmId;
  final String medicineName;
  final String? dosage;

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Pengingat Obat'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.medication_outlined, size: 72),
              const SizedBox(height: 16),
              Text(
                widget.medicineName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if ((widget.dosage ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.dosage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Jangan diabaikan. Pilih salah satu aksi.',
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: _working ? null : _handleTaken,
                child: const Text('Sudah diminum'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _working ? null : _handleSnooze,
                child: Text('Tunda ${AppConstants.snoozeMinutes} menit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleTaken() async {
    setState(() => _working = true);
    await NotificationHandler.handleTaken(widget.alarmId);
    if (!mounted) return;
    context.go('/medicine');
  }

  Future<void> _handleSnooze() async {
    setState(() => _working = true);
    await NotificationHandler.handleSnooze(
      widget.alarmId,
      medicineName: widget.medicineName,
      dosage: (widget.dosage ?? '').isEmpty ? null : widget.dosage,
    );
    if (!mounted) return;
    context.go('/medicine');
  }
}
