import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../../core/services/haptics_service.dart';
import '../../../core/services/tutorial_trigger.dart';
import '../../../main.dart';
import '../../../l10n/l10n.dart';
import '../../../app.dart';
import '../../../shared/providers/providers.dart';
import '../../habits/data/habit_model.dart';
import '../../habits/data/habit_repository.dart';
import '../../medicine/data/medicine_model.dart';
import '../../medicine/data/medicine_repository.dart';
import '../../tb/data/tb_model.dart';
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

  final _headerKey = GlobalKey();

  final _waterRepo = WaterRepository();
  final _habitRepo = HabitRepository();

  int _waterMl = 0;
  int _waterTargetMl = 2000;
  List<Habit> _todayHabits = const [];
  Map<String, HabitGroup> _groupMap = {};
  int _habitsDue = 0;
  int _habitsDone = 0;
  TBTreatmentProfile? _treatment;

  late final AnimationController _entrance;
  late final AnimationController _ambient;

  late final ValueListenable<Box<WaterLog>> _waterLogsL;
  late final ValueListenable<Box<Habit>> _habitsL;
  late final ValueListenable<Box<HabitLog>> _habitLogsL;
  late final ValueListenable<Box<Medicine>> _medicinesL;
  late final ValueListenable<Box<MedicineLog>> _medicineLogsL;
  late final ValueListenable<Box<TBTreatmentProfile>> _treatmentsL;

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
    _treatmentsL = Hive.box<TBTreatmentProfile>('tb_profiles').listenable();
    _waterLogsL.addListener(_load);
    _habitsL.addListener(_load);
    _habitLogsL.addListener(_load);
    _medicinesL.addListener(_load);
    _medicineLogsL.addListener(_load);
    _treatmentsL.addListener(_load);

    TutorialTrigger.notifier.addListener(_onTutorialTrigger);
    _load();
    _entrance.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowPermissionWizard(context);
    });
  }

  void _onTutorialTrigger() {
    // Delay so ShellScaffold keys are fully laid out after any navigation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _startTutorial();
    });
  }

  void _startTutorial() {
    // Build all targets, skip any whose key is not yet in the tree
    TargetFocus makeTarget({
      required GlobalKey key,
      required ShapeLightFocus shape,
      required ContentAlign align,
      required String titleId,
      required String titleEn,
      required String bodyId,
      required String bodyEn,
      required String hintText,
      double radius = 8,
    }) {
      return TargetFocus(
        keyTarget: key,
        color: const Color(0xFF0B0E1A),
        shape: shape,
        radius: radius,
        enableOverlayTab: true,
        enableTargetTab: true,
        focusAnimationDuration: const Duration(milliseconds: 300),
        unFocusAnimationDuration: const Duration(milliseconds: 200),
        contents: [
          TargetContent(
            align: align,
            child: _TutorialContent(
              title: localized(context, id: titleId, en: titleEn),
              body: localized(context, id: bodyId, en: bodyEn),
              hint: hintText,
            ),
          ),
        ],
      );
    }

    String hint(int i) => i == 4
        ? localized(context, id: 'Ketuk di mana saja untuk selesai', en: 'Tap anywhere to finish')
        : localized(context, id: 'Ketuk di mana saja untuk lanjut', en: 'Tap anywhere to continue');

    final candidates = [
      (i: 0, key: _headerKey,                   shape: ShapeLightFocus.RRect,  align: ContentAlign.bottom, radius: 12.0,
       titleId: 'Selamat datang di Rutin!',      titleEn: 'Welcome to Rutin!',
       bodyId:  'Dashboard harian kamu — semua ada di sini. Ketuk di mana saja untuk lanjut.',
       bodyEn:  'Your daily dashboard — everything is here. Tap anywhere to continue.'),

      (i: 1, key: ShellScaffold.fabKey,          shape: ShapeLightFocus.Circle, align: ContentAlign.top,    radius: 50.0,
       titleId: 'Tombol +',                      titleEn: 'The + button',
       bodyId:  'Tambah obat atau kebiasaan baru dari sini.',
       bodyEn:  'Add a new medicine or habit from here.'),

      (i: 2, key: ShellScaffold.medicineTabKey,  shape: ShapeLightFocus.RRect,  align: ContentAlign.top,    radius: 8.0,
       titleId: 'Obat',                          titleEn: 'Medicine',
       bodyId:  'Jadwal obat lengkap dan pencatatan dosis harian.',
       bodyEn:  'Full medicine schedule and daily dose logging.'),

      (i: 3, key: ShellScaffold.waterTabKey,     shape: ShapeLightFocus.RRect,  align: ContentAlign.top,    radius: 8.0,
       titleId: 'Air',                           titleEn: 'Water',
       bodyId:  'Catat asupan air dan aktifkan pengingat minum.',
       bodyEn:  'Log water intake and set drinking reminders.'),

      (i: 4, key: ShellScaffold.habitsTabKey,    shape: ShapeLightFocus.RRect,  align: ContentAlign.top,    radius: 8.0,
       titleId: 'Kebiasaan',                     titleEn: 'Habits',
       bodyId:  'Buat dan centang kebiasaan harian. Bangun streak dan raih medali.',
       bodyEn:  'Create and check off daily habits. Build streaks and earn medals.'),
    ];

    final targets = candidates
        .where((c) => c.key.currentContext != null)
        .map((c) => makeTarget(
              key: c.key, shape: c.shape, align: c.align, radius: c.radius,
              titleId: c.titleId, titleEn: c.titleEn,
              bodyId: c.bodyId, bodyEn: c.bodyEn,
              hintText: hint(c.i),
            ))
        .toList();

    if (targets.isEmpty) return;

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.88,
      paddingFocus: 8,
      pulseEnable: true,
      hideSkip: false,
      alignSkip: Alignment.topRight,
      textSkip: localized(context, id: 'LEWATI', en: 'SKIP'),
      textStyleSkip: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ).show(context: context, rootOverlay: true);
  }

  @override
  void dispose() {
    TutorialTrigger.notifier.removeListener(_onTutorialTrigger);
    _waterLogsL.removeListener(_load);
    _habitsL.removeListener(_load);
    _habitLogsL.removeListener(_load);
    _medicinesL.removeListener(_load);
    _medicineLogsL.removeListener(_load);
    _treatmentsL.removeListener(_load);
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
    final todayHabits = _habitRepo
        .getAll()
        .where((habit) => habit.scheduleDays.contains(weekday))
        .toList();

    final groupBox = Hive.box<HabitGroup>('habit_groups');
    final treatments = Hive.box<TBTreatmentProfile>(
      'tb_profiles',
    ).values.where((profile) => profile.isActive);
    setState(() {
      _waterMl = logToday?.mlLogged ?? 0;
      _waterTargetMl = goal.dailyTargetMl;
      _todayHabits = todayHabits;
      _groupMap = {for (final g in groupBox.values) g.id: g};
      _habitsDue = todayHabits.length;
      _habitsDone = todayHabits
          .where((habit) => _habitRepo.isCompletedToday(habit.id))
          .length;
      _treatment = treatments.isEmpty ? null : treatments.first;
    });
  }

  /// Build an ordered list of sections: (null, [habit]) for standalone,
  /// (group, [h1, h2, ...]) for stacks.
  List<(HabitGroup?, List<Habit>)> _buildSections(List<Habit> habits) {
    final sections = <(HabitGroup?, List<Habit>)>[];
    final seenGroups = <String>{};
    for (final habit in habits) {
      final gid = habit.groupId;
      if (gid != null && _groupMap.containsKey(gid)) {
        if (!seenGroups.contains(gid)) {
          seenGroups.add(gid);
          final groupHabits = habits.where((h) => h.groupId == gid).toList();
          sections.add((_groupMap[gid], groupHabits));
        }
      } else {
        sections.add((null, [habit]));
      }
    }
    return sections;
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

  Future<void> _setHabitCompletions(Habit habit, int count) async {
    final current = _habitRepo.completionsToday(habit.id);
    final target = _habitRepo.dailyTarget(habit);
    if (count < current) {
      HapticsService.softTap();
    } else if (count == target) {
      HapticsService.success();
    } else {
      HapticsService.tap();
    }
    await _habitRepo.setCompletionsToday(habit, count);
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
                                  title: context.l10n.medicine.toUpperCase(),
                                  actionLabel: localized(
                                    context,
                                    id: 'Semua',
                                    en: 'All',
                                  ),
                                  onAction: () => context.go('/medicine'),
                                  child: medicines.isEmpty
                                      ? _EmptyHint(
                                          text: context
                                              .l10n
                                              .noMedicineScheduledToday,
                                        )
                                      : Column(
                                          children: [
                                            for (
                                              int i = 0;
                                              i < medicines.length;
                                              i++
                                            ) ...[
                                              _HomeMedicineRow(
                                                medicine: medicines[i],
                                                doses:
                                                    groupedDoses[medicines[i]
                                                        .id] ??
                                                    const [],
                                                bucketFor: (dose) => _bucketFor(
                                                  medicineRepo,
                                                  dose,
                                                ),
                                                onTapDose: (dose) =>
                                                    _toggleDose(
                                                      medicineRepo,
                                                      dose,
                                                    ),
                                              ),
                                              if (i != medicines.length - 1)
                                                const SizedBox(height: 12),
                                            ],
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              if (_treatment != null) ...[
                                _FadeSlideIn(
                                  animation: _entrance,
                                  start: 0.25,
                                  end: 0.75,
                                  child: _TreatmentCountdownCard(
                                    profile: _treatment!,
                                    onTap: () =>
                                        context.push('/treatment/detail'),
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                              _FadeSlideIn(
                                animation: _entrance,
                                start: 0.20,
                                end: 0.70,
                                child: _SectionCard(
                                  title: context.l10n.water.toUpperCase(),
                                  actionLabel: localized(
                                    context,
                                    id: 'Semua',
                                    en: 'All',
                                  ),
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
                                            trackColor: _waterColor.withValues(
                                              alpha: 0.16,
                                            ),
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  context
                                                      .l10n
                                                      .waterProgressToday,
                                                  style: const TextStyle(
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
                                  title: context.l10n.habitsToday,
                                  actionLabel: localized(
                                    context,
                                    id: 'Semua',
                                    en: 'All',
                                  ),
                                  onAction: () => context.go('/habits'),
                                  child: _todayHabits.isEmpty
                                      ? _EmptyHint(
                                          text: context
                                              .l10n
                                              .noHabitsScheduledToday,
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ..._buildSections(shownHabits).map((
                                              section,
                                            ) {
                                              final (group, habits) = section;
                                              if (group == null) {
                                                // Standalone habit
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 10,
                                                      ),
                                                  child: _TodayHabitRow(
                                                    habit: habits.first,
                                                    done: _habitRepo
                                                        .isCompletedToday(
                                                          habits.first.id,
                                                        ),
                                                    streak: _habitRepo
                                                        .getStreak(
                                                          habits.first.id,
                                                        ),
                                                    target: _habitRepo
                                                        .dailyTarget(
                                                          habits.first,
                                                        ),
                                                    completions: _habitRepo
                                                        .completionsToday(
                                                          habits.first.id,
                                                        ),
                                                    onSetCompletions: (count) =>
                                                        _setHabitCompletions(
                                                          habits.first,
                                                          count,
                                                        ),
                                                    onTap: () => _markHabitDone(
                                                      habits.first,
                                                    ),
                                                  ),
                                                );
                                              }
                                              // Stacked habits — header + indented rows
                                              final stackStreak = habits.isEmpty
                                                  ? 0
                                                  : habits.fold<int>(
                                                      _habitRepo.getStreak(habits.first.id),
                                                      (min, h) {
                                                        final s = _habitRepo.getStreak(h.id);
                                                        return s < min ? s : min;
                                                      },
                                                    );
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 10,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 6,
                                                          ),
                                                      child: Row(
                                                        children: [
                                                          Text(
                                                            group.emoji,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 13,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Text(
                                                            group.name,
                                                            style:
                                                                const TextStyle(
                                                                  color: _muted,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  letterSpacing:
                                                                      0.3,
                                                                ),
                                                          ),
                                                          if (stackStreak > 0) ...[
                                                            const SizedBox(width: 6),
                                                            Text(
                                                              '🔥 $stackStreak',
                                                              style: const TextStyle(
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w700,
                                                                color: _habitColor,
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                    ...List.generate(habits.length, (i) {
                                                      final h = habits[i];
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              bottom: 6,
                                                            ),
                                                        child: IntrinsicHeight(
                                                          child: Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .stretch,
                                                            children: [
                                                              Container(
                                                                width: 2,
                                                                margin:
                                                                    const EdgeInsets.only(
                                                                      left: 6,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color: _habitColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.35,
                                                                      ),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        1,
                                                                      ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 10,
                                                              ),
                                                              Expanded(
                                                                child: _TodayHabitRow(
                                                                  habit: h,
                                                                  done: _habitRepo
                                                                      .isCompletedToday(h.id),
                                                                  streak: _habitRepo
                                                                      .getStreak(h.id),
                                                                  target: _habitRepo
                                                                      .dailyTarget(h),
                                                                  completions: _habitRepo
                                                                      .completionsToday(h.id),
                                                                  onSetCompletions: (count) =>
                                                                      _setHabitCompletions(h, count),
                                                                  onTap: () =>
                                                                      _markHabitDone(h),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    }),
                                                  ],
                                                ),
                                              );
                                            }),
                                            if (hiddenHabitCount > 0) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                localized(
                                                  context,
                                                  id: '+ $hiddenHabitCount lainnya',
                                                  en: '+ $hiddenHabitCount more',
                                                ),
                                                style: const TextStyle(
                                                  color: _muted,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                            Text(
                                              localized(
                                                context,
                                                id: '$_habitsDone / $_habitsDue selesai',
                                                en: '$_habitsDone / $_habitsDue done',
                                              ),
                                              style: const TextStyle(
                                                color: _habitColor,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
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
            _FadeSlideIn(
              animation: _entrance,
              start: 0.0,
              end: 0.45,
              child: _Header(
                key: _headerKey,
                topInset: topInset,
                title: _timeGreeting(context),
                date: _formattedDate(context),
                onMenu: () {
                  HapticFeedback.selectionClick();
                  context.go('/profile');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formattedDate(BuildContext context) {
    return formatLongDate(context, DateTime.now());
  }

  static String _timeGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      return localized(context, id: 'Selamat pagi', en: 'Good morning');
    }
    if (hour < 15) {
      return localized(context, id: 'Selamat siang', en: 'Good afternoon');
    }
    if (hour < 19) {
      return localized(context, id: 'Selamat sore', en: 'Good evening');
    }
    return localized(context, id: 'Selamat malam', en: 'Good night');
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
        title: Text(
          localized(context, id: 'Izin Wajib', en: 'Required Permissions'),
        ),
        content: Text(
          localized(
                context,
                id: 'Aktifkan semua izin agar reminder jalan:\n',
                en: 'Enable all permissions so reminders work:\n',
              ) +
              localized(
                context,
                id: '1) Notifikasi\n2) Exact alarm (Alarm & pengingat)\n3) Full-screen intent',
                en: '1) Notifications\n2) Exact alarm (Alarms & reminders)\n3) Full-screen intent',
              ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await android.requestNotificationsPermission();
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
            child: Text(
              localized(context, id: 'Notifikasi', en: 'Notifications'),
            ),
          ),
          TextButton(
            onPressed: () async {
              await android.requestExactAlarmsPermission();
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
            child: Text(
              localized(context, id: 'Exact Alarm', en: 'Exact Alarm'),
            ),
          ),
          TextButton(
            onPressed: () async {
              await android.requestFullScreenIntentPermission();
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
            child: Text(
              localized(context, id: 'Layar Penuh', en: 'Full Screen'),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.done),
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
                        context.l10n.homePullDownHint,
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
    super.key,
    required this.topInset,
    required this.title,
    required this.date,
    required this.onMenu,
  });

  final double topInset;
  final String title;
  final String date;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: _bgTop),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, topInset + 8, 20, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

class _HomeMedicineRow extends StatelessWidget {
  const _HomeMedicineRow({
    required this.medicine,
    required this.doses,
    required this.bucketFor,
    required this.onTapDose,
  });

  final Medicine medicine;
  final List<_HomeDose> doses;
  final _HomeDoseBucket Function(_HomeDose dose) bucketFor;
  final Future<void> Function(_HomeDose dose) onTapDose;

  Color _dotColor() {
    if (doses.any((d) => bucketFor(d) == _HomeDoseBucket.now)) {
      return _medGradient[0];
    }
    if (doses.any((d) => bucketFor(d) == _HomeDoseBucket.missed)) {
      return _missed;
    }
    if (doses.isNotEmpty &&
        doses.every((d) => bucketFor(d) == _HomeDoseBucket.taken)) {
      return _success;
    }
    return _muted;
  }

  String _nextDoseLabel(BuildContext context) {
    final nowDose = doses.where((d) => bucketFor(d) == _HomeDoseBucket.now);
    if (nowDose.isNotEmpty) return _fmtMinute(nowDose.first.minute);
    final upcoming = doses.where(
      (d) => bucketFor(d) == _HomeDoseBucket.upcoming,
    );
    if (upcoming.isNotEmpty) return _fmtMinute(upcoming.first.minute);
    if (doses.isNotEmpty &&
        doses.every((d) => bucketFor(d) == _HomeDoseBucket.taken)) {
      return '✓ ${context.l10n.done}';
    }
    return context.l10n.missed;
  }

  _HomeDose? _nowDose() {
    for (final dose in doses) {
      if (bucketFor(dose) == _HomeDoseBucket.now) return dose;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final nowDose = _nowDose();
    final dosage = (medicine.dosage ?? '').trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xAA0D1423),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _panelLine),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _dotColor(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (dosage.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    dosage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            _nextDoseLabel(context),
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          if (nowDose != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => onTapDose(nowDose),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _medGradient[0].withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Color(0xFFEE5A8C),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TodayHabitRow extends StatelessWidget {
  const _TodayHabitRow({
    required this.habit,
    required this.done,
    required this.streak,
    required this.target,
    required this.completions,
    required this.onSetCompletions,
    required this.onTap,
  });

  final Habit habit;
  final bool done;
  final int streak;
  final int target;
  final int completions;
  final Future<void> Function(int count) onSetCompletions;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: target == 1
          ? onTap
          : completions < target
              ? () => onSetCompletions(completions + 1)
              : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xAA0D1423),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _panelLine),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _habitColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(habit.emoji, style: const TextStyle(fontSize: 17)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: _muted,
                    ),
                  ),
                  if (habit.reminderMinutes != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.alarm_rounded,
                          size: 11,
                          color: _muted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _fmtMinute(habit.reminderMinutes!),
                          style: const TextStyle(color: _muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                  if (target > 1) ...[
                    const SizedBox(height: 6),
                    _HomeCompletionDots(
                      target: target,
                      completions: completions,
                      onTap: (index) => onSetCompletions(
                        index + 1 == completions ? index : index + 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (streak > 0) ...[
              const SizedBox(width: 6),
              Text(
                '🔥 $streak',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _habitColor,
                ),
              ),
            ],
            if (target == 1) ...[
              const SizedBox(width: 10),
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
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeCompletionDots extends StatelessWidget {
  const _HomeCompletionDots({
    required this.target,
    required this.completions,
    required this.onTap,
  });

  final int target;
  final int completions;
  final Future<void> Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // List.generate gives each i as a fresh function parameter,
        // avoiding the for-loop closure capture bug.
        ...List.generate(target, (i) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(i),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < completions ? _habitColor : Colors.transparent,
                border: Border.all(
                  color: i < completions ? _habitColor : _muted,
                ),
              ),
              child: i < completions
                  ? const Icon(Icons.check_rounded, size: 11, color: Colors.white)
                  : null,
            ),
          ),
        )).expand((dot) => [dot, const SizedBox(width: 2)]).take(target * 2 - 1),
      ],
    );
  }
}

class _TreatmentCountdownCard extends StatelessWidget {
  const _TreatmentCountdownCard({required this.profile, required this.onTap});

  final TBTreatmentProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final day = (DateTime.now().difference(profile.startDate).inDays + 1).clamp(
      1,
      profile.durationDays,
    );
    final left = (profile.durationDays - day).clamp(0, profile.durationDays);
    return _Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _panelLine),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _medGradient.first.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: Color(0xFFEE5A8C),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.conditionName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    left == 0
                        ? localized(
                            context,
                            id: 'Program selesai',
                            en: 'Program complete',
                          )
                        : localized(
                            context,
                            id: 'Hari ke-$day - $left hari tersisa',
                            en: 'Day $day - $left days remaining',
                          ),
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted),
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
      style: const TextStyle(color: _muted, fontSize: 13, height: 1.4),
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

class _TutorialContent extends StatelessWidget {
  const _TutorialContent({
    required this.title,
    required this.body,
    required this.hint,
  });

  final String title;
  final String body;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          hint,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
