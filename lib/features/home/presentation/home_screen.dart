import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../main.dart';
import '../../../shared/providers/providers.dart';
import '../../habits/data/habit_model.dart';
import '../../habits/data/habit_repository.dart';
import '../../medicine/data/medicine_model.dart';
import '../../water/data/water_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  static bool _permissionDialogShown = false;

  final _waterRepo = WaterRepository();
  final _habitRepo = HabitRepository();

  int _waterCurrent = 0;
  int _waterGoal    = 8;
  int _glassSizeMl  = 250;
  int _habitsDue    = 0;
  int _habitsDone   = 0;
  List<Habit> _todayHabits = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowPermissionWizard(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  void _load() {
    final goal     = _waterRepo.getGoal();
    final logToday = _waterRepo.getTodayLog();
    final weekday  = DateTime.now().weekday;
    final all      = _habitRepo.getAll();
    final today    = all.where((h) => h.scheduleDays.contains(weekday)).toList();

    setState(() {
      _waterCurrent = logToday?.glassesLogged ?? 0;
      _waterGoal    = goal.goalGlasses;
      _glassSizeMl  = goal.glassSizeMl;
      _habitsDue    = today.length;
      _habitsDone   = today.where((h) => _habitRepo.isCompletedToday(h.id)).length;
      _todayHabits  = today;
    });
  }

  static Medicine? _nextMedicine(List<Medicine> medicines) {
    if (medicines.isEmpty) return null;
    final nowMin = DateTime.now().hour * 60 + DateTime.now().minute;
    Medicine? best;
    int bestDelta = 999999;
    for (final m in medicines) {
      for (final t in m.scheduleTimes) {
        final delta = t >= nowMin ? t - nowMin : t + 1440 - nowMin;
        if (delta < bestDelta) {
          bestDelta = delta;
          best = m;
        }
      }
    }
    return best;
  }

  static int _nextMedicineMinutes(Medicine m) {
    final nowMin = DateTime.now().hour * 60 + DateTime.now().minute;
    return m.scheduleTimes.firstWhere((t) => t >= nowMin,
        orElse: () => m.scheduleTimes.first);
  }

  static String _fmtMinutes(int m) {
    final h = (m ~/ 60).toString().padLeft(2, '0');
    final min = (m % 60).toString().padLeft(2, '0');
    return '$h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final medicines = ref.watch(medicineRepositoryProvider).getAll();
    final nextMed   = _nextMedicine(medicines);
    final hour      = DateTime.now().hour;
    final greeting  = hour < 5 ? 'Selamat malam' : hour < 12 ? 'Selamat pagi' : hour < 17 ? 'Selamat siang' : 'Selamat malam';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.muted,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rutin',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.person_outline_rounded, size: 22, color: AppTheme.muted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formattedDate(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 28),

              // Medicine card
              _FeatureCard(
                color: AppTheme.medicineColor,
                icon: Icons.medication_rounded,
                label: 'Obat',
                onTap: () => context.go('/medicine'),
                child: nextMed != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nextMed.name,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (nextMed.dosage != null)
                            Text(
                              nextMed.dosage!,
                              style: const TextStyle(fontSize: 12, color: Colors.white54),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            _fmtMinutes(_nextMedicineMinutes(nextMed)),
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1.0,
                              height: 1,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Tidak ada jadwal',
                        style: TextStyle(fontSize: 15, color: Colors.white60),
                      ),
              ),
              const SizedBox(height: 12),

              // Water card
              _FeatureCard(
                color: AppTheme.waterColor,
                icon: Icons.water_drop_rounded,
                label: 'Air',
                onTap: () => context.go('/water'),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_waterCurrent * _glassSizeMl}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1.0,
                              height: 1,
                            ),
                          ),
                          Text(
                            'ml dari ${_waterGoal * _glassSizeMl} ml target',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    _MiniArc(
                      progress: _waterGoal > 0
                          ? (_waterCurrent / _waterGoal).clamp(0.0, 1.0)
                          : 0.0,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Habits card
              _FeatureCard(
                color: AppTheme.habitsColor,
                icon: Icons.check_circle_rounded,
                label: 'Kebiasaan',
                onTap: () => context.go('/habits'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _habitsDue == 0
                          ? 'Tidak ada kebiasaan hari ini'
                          : '$_habitsDone dari $_habitsDue selesai',
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    if (_todayHabits.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (final h in _todayHabits.take(4))
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Opacity(
                                opacity: _habitRepo.isCompletedToday(h.id) ? 1.0 : 0.35,
                                child: Text(h.emoji, style: const TextStyle(fontSize: 26)),
                              ),
                            ),
                          if (_todayHabits.length > 4)
                            Text(
                              '+${_todayHabits.length - 4}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
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
  }

  static String _formattedDate() {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
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

    final notifEnabled  = await android.areNotificationsEnabled() ?? false;
    final exactEnabled  = await android.canScheduleExactNotifications() ?? false;
    if (notifEnabled && exactEnabled) return;
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
      ),
    );
  }
}

// ─── Feature card ─────────────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.child,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, Color.lerp(color, Colors.black, 0.25)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 13),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

// ─── Mini arc (home water card) ───────────────────────────────────────────────

class _MiniArc extends StatelessWidget {
  const _MiniArc({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (_, value, __) => CustomPaint(
        size: const Size(72, 72),
        painter: _MiniArcPainter(value),
      ),
    );
  }
}

class _MiniArcPainter extends CustomPainter {
  const _MiniArcPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const startAngle = math.pi * 0.75;
    const sweep = math.pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, sweep, false,
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    if (progress > 0.01) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, sweep * progress, false,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_MiniArcPainter old) => old.progress != progress;
}
