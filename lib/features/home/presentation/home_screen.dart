import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/services/haptics_service.dart';
import '../../../main.dart';
import '../../../shared/providers/providers.dart';
import '../../habits/data/habit_model.dart';
import '../../habits/data/habit_repository.dart';
import '../../medicine/data/medicine_model.dart';
import '../../medicine/data/medicine_repository.dart';
import '../../water/data/water_model.dart';
import '../../water/data/water_repository.dart';
import '../../water/presentation/water_progress_widget.dart';

const _bgTop = Color(0xFF0B0E1A);
const _panel = Color(0xCC111A2A);
const _panelLine = Color(0xFF26324A);
const _medGradient = [Color(0xFFEE5A8C), Color(0xFFD93A6E)];
const _waterColor = Color(0xFF3E8BF0);
const _habitColor = Color(0xFFF4A92B);
const _success = Color(0xFF4CC56A);
const _missed = Color(0xFFF36B5B);
const _muted = Color(0xFF9AA3B2);

enum _HomeDoseBucket { now, upcoming, taken, missed }

class _HomeDose {
  const _HomeDose(this.medicine, this.minute, this.scheduled);

  final Medicine medicine;
  final int minute;
  final DateTime scheduled;
}

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

  int _waterMl = 0;
  int _waterTargetMl = 2000;
  List<Habit> _todayHabits = const [];
  int _habitsDue = 0;
  int _habitsDone = 0;

  late final AnimationController _entrance;
  late final AnimationController _ambient;

  late final ValueListenable<Box<WaterLog>> _waterLogsL;
  late final ValueListenable<Box<Habit>> _habitsL;
  late final ValueListenable<Box<HabitLog>> _habitLogsL;
  late final ValueListenable<Box<Medicine>> _medicinesL;
  late final ValueListenable<Box<MedicineLog>> _medicineLogsL;

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

    _waterLogsL = Hive.box<WaterLog>('water_logs').listenable();
    _habitsL = Hive.box<Habit>('habits').listenable();
    _habitLogsL = Hive.box<HabitLog>('habit_logs').listenable();
    _medicinesL = Hive.box<Medicine>('medicines').listenable();
    _medicineLogsL = Hive.box<MedicineLog>('medicine_logs').listenable();
    _waterLogsL.addListener(_load);
    _habitsL.addListener(_load);
    _habitLogsL.addListener(_load);
    _medicinesL.addListener(_load);
    _medicineLogsL.addListener(_load);

    _load();
    _entrance.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowPermissionWizard(context);
    });
  }

  @override
  void dispose() {
    _waterLogsL.removeListener(_load);
    _habitsL.removeListener(_load);
    _habitLogsL.removeListener(_load);
    _medicinesL.removeListener(_load);
    _medicineLogsL.removeListener(_load);
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
    if (!mounted) return;
    final goal = _waterRepo.getGoal();
    final logToday = _waterRepo.getTodayLog();
    final weekday = DateTime.now().weekday;
    final todayHabits = _habitRepo.getAll()
        .where((habit) => habit.scheduleDays.contains(weekday))
        .toList();

    setState(() {
      _waterMl = logToday?.mlLogged ?? 0;
      _waterTargetMl = goal.dailyTargetMl;
      _todayHabits = todayHabits;
      _habitsDue = todayHabits.length;
      _habitsDone = todayHabits
          .where((habit) => _habitRepo.isCompletedToday(habit.id))
          .length;
    });
  }

  List<_HomeDose> _todayDoses(MedicineRepository repo) {
    final now = DateTime.now();
    final doses = <_HomeDose>[];
    for (final medicine in repo.getAll()) {
      for (final minute in medicine.scheduleTimes) {
        doses.add(
          _HomeDose(
            medicine,
            minute,
            DateTime(now.year, now.month, now.day, minute ~/ 60, minute % 60),
          ),
        );
      }
    }
    doses.sort((a, b) {
      final byMedicine = a.medicine.name.toLowerCase().compareTo(
        b.medicine.name.toLowerCase(),
      );
      if (byMedicine != 0) return byMedicine;
      return a.minute.compareTo(b.minute);
    });
    return doses;
  }

  _HomeDoseBucket _bucketFor(MedicineRepository repo, _HomeDose dose) {
    if (repo.isTaken(dose.medicine.id, dose.scheduled)) {
      return _HomeDoseBucket.taken;
    }
    final now = DateTime.now();
    final diff = now.difference(dose.scheduled);
    if (diff.inMinutes >= 60) return _HomeDoseBucket.missed;
    if (!dose.scheduled.isAfter(now)) return _HomeDoseBucket.now;
    return _HomeDoseBucket.upcoming;
  }

  Future<void> _toggleDose(MedicineRepository repo, _HomeDose dose) async {
    HapticsService.tap();
    final taken = _bucketFor(repo, dose) == _HomeDoseBucket.taken;
    await repo.setTaken(dose.medicine.id, dose.scheduled, !taken);
    if (mounted) setState(() {});
  }

  Future<void> _markHabitDone(Habit habit) async {
    if (_habitRepo.isCompletedToday(habit.id)) return;
    HapticsService.success();
    await _habitRepo.markDone(habit.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final medicineRepo = ref.watch(medicineRepositoryProvider);
    final todayDoses = _todayDoses(medicineRepo);
    final screen = MediaQuery.of(context).size;
    final heroHeight = (screen.height * 0.72).clamp(520.0, 760.0);
    const overlapLift = 40.0;
    final topInset = MediaQuery.of(context).padding.top;
    const navBarHeight = 64.0;
    final heroTopPadding = topInset + navBarHeight + 20;
    final waterPct = _waterTargetMl > 0
        ? (_waterMl / _waterTargetMl).clamp(0.0, 1.0)
        : 0.0;
    final shownHabits = _todayHabits.take(5).toList();
    final hiddenHabitCount = _todayHabits.length - shownHabits.length;

    final groupedDoses = <String, List<_HomeDose>>{};
    for (final dose in todayDoses) {
      groupedDoses.putIfAbsent(dose.medicine.id, () => []).add(dose);
    }
    final medicines = medicineRepo.getAll();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _bgTop,
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _HomeHero(
                    height: heroHeight,
                    topPadding: heroTopPadding,
                    ambient: _ambient,
                    onSunTap: HapticsService.fun,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed([
                      Padding(
                        padding: const EdgeInsets.only(top: overlapLift),
                        child: Transform.translate(
                          offset: const Offset(0, -overlapLift),
                          child: Column(
                            children: [
                        _FadeSlideIn(
                          animation: _entrance,
                          start: 0.10,
                          end: 0.60,
                          child: _SectionCard(
                            title: 'OBAT',
                            actionLabel: 'Semua',
                            onAction: () => context.go('/medicine'),
                            child: medicines.isEmpty
                                ? const _EmptyHint(
                                    text: 'Belum ada jadwal obat hari ini.',
                                  )
                                : Column(
                                    children: [
                                      for (int i = 0; i < medicines.length; i++) ...[
                                        _HomeMedicineCard(
                                          medicine: medicines[i],
                                          doses: groupedDoses[medicines[i].id] ?? const [],
                                          bucketFor: (dose) => _bucketFor(medicineRepo, dose),
                                          onTapDose: (dose) => _toggleDose(medicineRepo, dose),
                                        ),
                                        if (i != medicines.length - 1)
                                          const SizedBox(height: 12),
                                      ],
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _FadeSlideIn(
                          animation: _entrance,
                          start: 0.20,
                          end: 0.70,
                          child: _SectionCard(
                            title: 'AIR',
                            actionLabel: 'Semua',
                            onAction: () => context.go('/water'),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                HapticsService.tap();
                                context.go('/water');
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    WaterProgressWidget(
                                      current: _waterMl,
                                      goal: _waterTargetMl,
                                      size: 104,
                                      strokeWidth: 10,
                                      trackColor: _waterColor.withValues(alpha: 0.16),
                                      fillColor: _waterColor,
                                      center: Text(
                                        '${(waterPct * 100).round()}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Progress air hari ini',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '$_waterMl / $_waterTargetMl ml',
                                            style: const TextStyle(
                                              color: _muted,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _FadeSlideIn(
                          animation: _entrance,
                          start: 0.30,
                          end: 0.80,
                          child: _SectionCard(
                            title: 'KEBIASAAN HARI INI',
                            actionLabel: 'Semua',
                            onAction: () => context.go('/habits'),
                            child: _todayHabits.isEmpty
                                ? const _EmptyHint(
                                    text: 'Belum ada kebiasaan terjadwal hari ini.',
                                  )
                                : Column(
                                    children: [
                                      for (int i = 0; i < shownHabits.length; i++) ...[
                                        _TodayHabitRow(
                                          habit: shownHabits[i],
                                          done: _habitRepo.isCompletedToday(shownHabits[i].id),
                                          onTap: () => _markHabitDone(shownHabits[i]),
                                        ),
                                        if (i != shownHabits.length - 1)
                                          const SizedBox(height: 10),
                                      ],
                                      if (hiddenHabitCount > 0) ...[
                                        const SizedBox(height: 12),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            '+ $hiddenHabitCount lainnya',
                                            style: const TextStyle(
                                              color: _muted,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          '$_habitsDone / $_habitsDue selesai',
                                          style: const TextStyle(
                                            color: _habitColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
            SafeArea(
              bottom: false,
              child: _FadeSlideIn(
                animation: _entrance,
                start: 0.0,
                end: 0.45,
                child: _Header(
                  title: _timeGreeting(),
                  date: _formattedDate(),
                  onMenu: () {
                    HapticFeedback.selectionClick();
                    context.go('/profile');
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formattedDate() {
    const days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final now = DateTime.now();
    return '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  static String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 19) return 'Selamat sore';
    return 'Selamat malam';
  }

  Future<void> _maybeShowPermissionWizard(BuildContext context) async {
    if (_permissionDialogShown || !context.mounted) return;
    _permissionDialogShown = true;

    final android = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    final notifEnabled = await android.areNotificationsEnabled() ?? false;
    final exactEnabled = await android.canScheduleExactNotifications() ?? false;
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

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.height,
    required this.topPadding,
    required this.ambient,
    required this.onSunTap,
  });

  final double height;
  final double topPadding;
  final Animation<double> ambient;
  final Future<void> Function() onSunTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/home_background.webp',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _bgTop.withValues(alpha: 0.10),
                    _bgTop.withValues(alpha: 0.22),
                    _bgTop.withValues(alpha: 0.72),
                    _bgTop,
                  ],
                  stops: const [0.0, 0.36, 0.78, 1.0],
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.35),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSunTap,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: _BobbingSun(ambient: ambient),
              ),
            ),
          ),
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
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, topPadding, 0, 0),
              child: Column(
                children: [
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 56),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tarik ke bawah, nikmati suasananya.\nScroll sedikit, lihat hari ini.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.date,
    required this.onMenu,
  });

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
          Text(date, style: const TextStyle(fontSize: 13, color: _muted)),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.child,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _panelLine),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              _Pressable(
                onTap: onAction,
                child: Text(
                  '→ $actionLabel',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _HomeMedicineCard extends StatelessWidget {
  const _HomeMedicineCard({
    required this.medicine,
    required this.doses,
    required this.bucketFor,
    required this.onTapDose,
  });

  final Medicine medicine;
  final List<_HomeDose> doses;
  final _HomeDoseBucket Function(_HomeDose dose) bucketFor;
  final Future<void> Function(_HomeDose dose) onTapDose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xAA0D1423),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _panelLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  medicine.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if ((medicine.dosage ?? '').isNotEmpty)
                Text(
                  medicine.dosage!,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final dose in doses)
                _HomeDoseChip(
                  label: _fmtMinute(dose.minute),
                  bucket: bucketFor(dose),
                  onTap: () => onTapDose(dose),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            MedicineMealTiming.label(medicine.mealTimingKey),
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _HomeDoseChip extends StatelessWidget {
  const _HomeDoseChip({
    required this.label,
    required this.bucket,
    required this.onTap,
  });

  final String label;
  final _HomeDoseBucket bucket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isNow = bucket == _HomeDoseBucket.now;
    final isTaken = bucket == _HomeDoseBucket.taken;
    final isMissed = bucket == _HomeDoseBucket.missed;

    final foreground = switch (bucket) {
      _HomeDoseBucket.now => Colors.white,
      _HomeDoseBucket.taken => _success,
      _HomeDoseBucket.missed => _missed,
      _HomeDoseBucket.upcoming => _muted,
    };

    final background = switch (bucket) {
      _HomeDoseBucket.taken => _success.withValues(alpha: 0.16),
      _HomeDoseBucket.missed => _missed.withValues(alpha: 0.16),
      _HomeDoseBucket.upcoming => const Color(0xFF1A2236),
      _HomeDoseBucket.now => null,
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isNow ? const LinearGradient(colors: _medGradient) : null,
          color: isNow ? null : background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isTaken
                ? _success.withValues(alpha: 0.45)
                : isMissed
                    ? _missed.withValues(alpha: 0.35)
                    : isNow
                        ? Colors.transparent
                        : _panelLine,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isTaken) ...[
              const Icon(Icons.check_rounded, size: 13, color: _success),
              const SizedBox(width: 4),
            ] else if (isMissed) ...[
              const Icon(Icons.close_rounded, size: 13, color: _missed),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayHabitRow extends StatelessWidget {
  const _TodayHabitRow({
    required this.habit,
    required this.done,
    required this.onTap,
  });

  final Habit habit;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xAA0D1423),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _panelLine),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? _success : Colors.transparent,
                border: Border.all(
                  color: done ? _success : _muted.withValues(alpha: 0.65),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.check_rounded,
                size: 15,
                color: done ? Colors.white : Colors.transparent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                habit.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: _muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _muted,
        fontSize: 13,
        height: 1.4,
      ),
    );
  }
}

class _BobbingSun extends StatelessWidget {
  const _BobbingSun({required this.ambient});

  final Animation<double> ambient;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: ambient,
      builder: (_, child) {
        final phase = math.sin(ambient.value * 2 * math.pi);
        return Transform.translate(
          offset: Offset(0, -5 * phase),
          child: Transform.scale(scale: 1 + 0.02 * phase, child: child),
        );
      },
      child: Image.asset(
        'assets/home_sun.webp',
        width: width * 0.34,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.child,
    required this.onTap,
    this.scale = 0.97,
  });

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
        HapticsService.softTap();
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

String _fmtMinute(int minutes) {
  final hour = (minutes ~/ 60).toString().padLeft(2, '0');
  final minute = (minutes % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}
