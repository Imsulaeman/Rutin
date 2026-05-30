import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../main.dart';
import '../../../shared/providers/providers.dart';
import '../../habits/data/habit_repository.dart';
import '../../medicine/data/medicine_model.dart';
import '../../water/data/water_repository.dart';

// ─── Palette (sampled from preview/02_today_dashboard) ──────────────────────────
const _bgTop  = Color(0xFF0B0E1A); // scaffold fallback behind the background image
const _medGradient   = [Color(0xFFEE5A8C), Color(0xFFD93A6E)]; // magenta-pink
const _waterGradient = [Color(0xFF3E8BF0), Color(0xFF2168D8)]; // sky → blue
const _habitGradient = [Color(0xFFFCD15B), Color(0xFFF4A92B)]; // gold → amber
const _accentGreen   = Color(0xFF4CC56A);
const _dateGrey      = Color(0xFF9AA3B2);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static bool _permissionDialogShown = false;

  final _waterRepo = WaterRepository();
  final _habitRepo = HabitRepository();

  int _waterMl       = 0;
  int _waterTargetMl = 2000;
  int _habitsDue    = 0;
  int _habitsDone   = 0;

  // Staggered fade+slide entrance (transform/opacity only).
  late final AnimationController _entrance;
  // Ambient loop: drives star twinkle + sun bob in the night scene.
  late final AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _load();
    _entrance.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowPermissionWizard(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entrance.dispose();
    _ambient.dispose();
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
      _waterMl       = logToday?.mlLogged ?? 0;
      _waterTargetMl = goal.dailyTargetMl;
      _habitsDue    = today.length;
      _habitsDone   = today.where((h) => _habitRepo.isCompletedToday(h.id)).length;
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
    final waterPct  = _waterTargetMl > 0 ? (_waterMl / _waterTargetMl).clamp(0.0, 1.0) : 0.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Dark background → light status-bar icons.
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _bgTop,
        body: Stack(
          children: [
            // Full-screen night background fills the whole screen, so the cards
            // sit inside the scene instead of floating on an empty navy gap.
            Positioned.fill(
              child: Image.asset(
                'assets/home_background.webp',
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
            // Sun rising between the hills, with a gentle bob.
            Align(
              alignment: const Alignment(0, 0.44),
              child: _BobbingSun(ambient: _ambient),
            ),
            // Foreground hills (sky keyed out of the background) drawn OVER the
            // sun so it reads as rising from behind them.
            Positioned.fill(
              child: IgnorePointer(
                child: Image.asset(
                  'assets/home_foreground.webp',
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _FadeSlideIn(
                    animation: _entrance,
                    start: 0.0,
                    end: 0.5,
                    child: _Header(
                      title: 'Hari Ini',
                      date: _formattedDate(),
                      onMenu: () {
                        HapticFeedback.selectionClick();
                        context.go('/profile');
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _FadeSlideIn(
                          animation: _entrance,
                          start: 0.12,
                          end: 0.6,
                          child: _MedicineCard(
                            count: medicines.length,
                            nextName: nextMed?.name,
                            timeLabel: nextMed != null
                                ? _fmtMinutes(_nextMedicineMinutes(nextMed))
                                : null,
                            onTap: () => context.go('/medicine'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _FadeSlideIn(
                          animation: _entrance,
                          start: 0.22,
                          end: 0.7,
                          child: _WaterCard(
                            currentMl: _waterMl,
                            targetMl: _waterTargetMl,
                            pct: waterPct,
                            onTap: () => context.go('/water'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _FadeSlideIn(
                          animation: _entrance,
                          start: 0.32,
                          end: 0.8,
                          child: _HabitsCard(
                            done: _habitsDone,
                            due: _habitsDue,
                            onTap: () => context.go('/habits'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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

// ─── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.date, required this.onMenu});

  final String title;
  final String date;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              _IconButton(icon: Icons.menu_rounded, onTap: onMenu),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              _IconButton(icon: Icons.calendar_today_rounded, onTap: onMenu),
            ],
          ),
          const SizedBox(height: 4),
          Text(date, style: const TextStyle(fontSize: 13, color: _dateGrey)),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      scale: 0.85,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

// ─── Cards ──────────────────────────────────────────────────────────────────

/// Shared full-width gradient card shell: icon badge + title/subtitle + trailing.
class _GradientCard extends StatelessWidget {
  const _GradientCard({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final List<Color> gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // 3-stop gradient: a lighter sheen at the very top reads as gloss.
          gradient: LinearGradient(
            colors: [
              Color.lerp(gradient.first, Colors.white, 0.16)!,
              gradient.first,
              gradient.last,
            ],
            stops: const [0.0, 0.28, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            // Colored bloom — bleeds the card's hue into the dark scene so it
            // fuses with the background instead of floating on top of it.
            BoxShadow(
              color: gradient.last.withOpacity(0.50),
              blurRadius: 34,
              spreadRadius: -6,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: gradient.first.withOpacity(0.22),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Frosted badge
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({
    required this.count,
    required this.nextName,
    required this.timeLabel,
    required this.onTap,
  });

  final int count;
  final String? nextName;
  final String? timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GradientCard(
      gradient: _medGradient,
      icon: Icons.medication_rounded,
      title: 'Obat',
      subtitle: count == 0 ? 'Tidak ada jadwal' : '$count obat hari ini',
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeLabel ?? '—',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.8), size: 22),
        ],
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  const _WaterCard({
    required this.currentMl,
    required this.targetMl,
    required this.pct,
    required this.onTap,
  });

  final int currentMl;
  final int targetMl;
  final double pct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GradientCard(
      gradient: _waterGradient,
      icon: Icons.water_drop_rounded,
      title: 'Air',
      subtitle: '$currentMl / $targetMl ml',
      onTap: onTap,
      trailing: _PercentRing(progress: pct),
    );
  }
}

/// Small trailing ring used on the water card. Animates fill on (re)build.
class _PercentRing extends StatelessWidget {
  const _PercentRing({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, value, __) => SizedBox(
        width: 48,
        height: 48,
        child: CustomPaint(
          painter: _RingPainter(value),
          child: Center(
            child: Text(
              '${(value * 100).round()}%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withOpacity(0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    if (progress > 0.001) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _HabitsCard extends StatelessWidget {
  const _HabitsCard({required this.done, required this.due, required this.onTap});

  final int done;
  final int due;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dots = due == 0 ? 0 : math.min(due, 5);
    return _GradientCard(
      gradient: _habitGradient,
      icon: Icons.star_rounded,
      title: 'Kebiasaan',
      subtitle: due == 0 ? 'Tidak ada hari ini' : '$done / $due selesai',
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < dots; i++)
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < done ? _accentGreen : Colors.white.withOpacity(0.4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Sun mascot ───────────────────────────────────────────────────────────────
// Separate transparent layer over the background so it can move independently.

class _BobbingSun extends StatelessWidget {
  const _BobbingSun({required this.ambient});
  final Animation<double> ambient;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: ambient,
      builder: (_, child) {
        final phase = math.sin(ambient.value * 2 * math.pi);
        return Transform.translate(
          offset: Offset(0, -5 * phase),                       // gentle vertical bob
          child: Transform.scale(scale: 1 + 0.02 * phase, child: child), // soft glow breath
        );
      },
      child: Image.asset('assets/home_sun.webp', width: w * 0.34, fit: BoxFit.contain),
    );
  }
}

// ─── Shared interaction helpers ──────────────────────────────────────────────

/// Press-to-scale + haptic wrapper. transform/opacity only → GPU-safe.
class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, required this.onTap, this.scale = 0.97});

  final Widget child;
  final VoidCallback onTap;
  final double scale;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Staggered entrance: fade + 16px upward slide.
class _FadeSlideIn extends StatelessWidget {
  const _FadeSlideIn({
    required this.animation,
    required this.start,
    required this.end,
    required this.child,
  });

  final Animation<double> animation;
  final double start;
  final double end;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (_, child) => Opacity(
        opacity: curved.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - curved.value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
