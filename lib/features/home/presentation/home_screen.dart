import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../../../main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static bool _permissionDialogShown = false;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowPermissionWizard(context);
    });

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Selamat pagi'
        : hour < 17
            ? 'Selamat siang'
            : 'Selamat malam';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text('Rutin', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 4),
              Text(
                _formattedDate(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 36),
              _FeatureCard(
                icon: Icons.medication_outlined,
                iconColor: Theme.of(context).colorScheme.primary,
                title: 'Obat',
                subtitle: 'Jadwal & pengingat minum obat',
                onTap: () => context.push('/medicine'),
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                icon: Icons.water_drop_outlined,
                iconColor: const Color(0xFF1565C0),
                title: 'Air',
                subtitle: 'Target harian & pengingat minum air',
                onTap: () => context.push('/water'),
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                icon: Icons.check_circle_outline,
                iconColor: const Color(0xFF5D4037),
                title: 'Kebiasaan',
                subtitle: 'Bangun rutinitas positif setiap hari',
                onTap: () => context.push('/habits'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formattedDate() {
    const days = [
      'Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'
    ];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final now = DateTime.now();
    return '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

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

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
