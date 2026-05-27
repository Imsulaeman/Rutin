import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../../../main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowPermissionWizard(context);
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Beranda')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NavCard(
            label: 'Obat',
            icon: Icons.medication_outlined,
            onTap: () => context.push('/medicine'),
          ),
          const SizedBox(height: 12),
          _NavCard(
            label: 'Air',
            icon: Icons.water_drop_outlined,
            onTap: () => context.push('/water'),
          ),
          const SizedBox(height: 12),
          _NavCard(
            label: 'Kebiasaan',
            icon: Icons.check_circle_outline,
            onTap: () => context.push('/habits'),
          ),
        ],
      ),
    );
  }

  static bool _permissionDialogShown = false;

  Future<void> _maybeShowPermissionWizard(BuildContext context) async {
    if (_permissionDialogShown || !context.mounted) return;
    _permissionDialogShown = true;

    final android = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    final notifEnabled = await android.areNotificationsEnabled() ?? false;
    final exactEnabled = await android.canScheduleExactNotifications() ?? false;

    if (notifEnabled && exactEnabled) return;

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Izin Wajib'),
          content: const Text(
            'Aktifkan semua izin agar reminder jalan:\n'
            '1) Notifikasi\n'
            '2) Exact alarm (Alarms & reminders)\n'
            '3) Full-screen intent',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await android.requestNotificationsPermission();
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('Notifikasi'),
            ),
            TextButton(
              onPressed: () async {
                await android.requestExactAlarmsPermission();
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('Exact Alarm'),
            ),
            TextButton(
              onPressed: () async {
                await android.requestFullScreenIntentPermission();
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('Full Screen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Selesai'),
            ),
          ],
        );
      },
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
