import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/habits/data/habit_model.dart';
import 'features/habits/presentation/add_habit_screen.dart';
import 'features/habits/presentation/habit_history_screen.dart';
import 'features/habits/presentation/habits_screen.dart';
import 'features/history/presentation/history_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/medicine/presentation/add_medicine_screen.dart';
import 'features/medicine/presentation/medicine_archive_screen.dart';
import 'features/medicine/presentation/medicine_history_screen.dart';
import 'features/medicine/presentation/medicine_list_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/settings/data/language_service.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/sleep/presentation/morning_gate_screen.dart';
import 'features/sleep/presentation/sleep_settings_screen.dart';
import 'features/sleep/presentation/wakeup_game_screen.dart';
import 'features/tb/presentation/treatment_detail_screen.dart';
import 'features/tb/presentation/treatment_onboarding_screen.dart';
import 'features/water/presentation/water_screen.dart';
import 'l10n/l10n.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellHomeKey = GlobalKey<NavigatorState>();
final _shellMedicineKey = GlobalKey<NavigatorState>();
final _shellWaterKey = GlobalKey<NavigatorState>();
final _shellHabitsKey = GlobalKey<NavigatorState>();
final _shellProfileKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => ShellScaffold(shell: shell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellHomeKey,
          routes: [GoRoute(path: '/', builder: (_, __) => const HomeScreen())],
        ),
        StatefulShellBranch(
          navigatorKey: _shellMedicineKey,
          routes: [
            GoRoute(
              path: '/medicine',
              builder: (_, __) => const MedicineListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellWaterKey,
          routes: [
            GoRoute(path: '/water', builder: (_, __) => const WaterScreen()),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellHabitsKey,
          routes: [
            GoRoute(path: '/habits', builder: (_, __) => const HabitsScreen()),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellProfileKey,
          routes: [
            GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    // Full-screen routes above the shell (no bottom nav)
    GoRoute(
      path: '/medicine/add',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const AddMedicineScreen(),
    ),
    GoRoute(
      path: '/medicine/history',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const MedicineHistoryScreen(),
    ),
    GoRoute(
      path: '/medicine/archive',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const MedicineArchiveScreen(),
    ),
    GoRoute(
      path: '/habits/add',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => AddHabitScreen(habit: state.extra as Habit?),
    ),
    GoRoute(
      path: '/habits/history',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const HabitHistoryScreen(),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/history',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/treatment/onboarding',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const TreatmentOnboardingScreen(),
    ),
    GoRoute(
      path: '/treatment/detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const TreatmentDetailScreen(),
    ),
    GoRoute(
      path: '/sleep-settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const SleepSettingsScreen(),
    ),
    GoRoute(
      path: '/morning-gate',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const MorningGateScreen(),
    ),
    GoRoute(
      path: '/wakeup-game',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) =>
          WakeupGameScreen(forceGameIndex: state.extra as int?),
    ),
  ],
);

// ─── Shell scaffold ───────────────────────────────────────────────────────────

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.shell});
  final StatefulNavigationShell shell;

  // 4 tab branches flank a central + FAB (add). Profile (branch 4) is reached
  // from the home header menu, matching the mockup's 4-tab + FAB layout.
  void _go(int branch) {
    HapticFeedback.selectionClick();
    shell.goBranch(branch, initialLocation: branch == shell.currentIndex);
  }

  void _showAdd(BuildContext context) {
    final l10n = context.l10n;
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF131C2B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.medication_rounded,
                color: Color(0xFFEE5A8C),
              ),
              title: Text(
                l10n.addMedicine,
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                context.push('/medicine/add');
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_rounded, color: Color(0xFFF4A92B)),
              title: Text(l10n.addHabit, style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(sheetCtx);
                context.push('/habits/add');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E1A),
      body: shell,
      bottomNavigationBar: _BottomNav(
        currentIndex: shell.currentIndex,
        onTap: _go,
        onAdd: () => _showAdd(context),
      ),
    );
  }
}

// ─── Custom bottom nav with raised center + FAB ────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.onAdd,
  });

  final int currentIndex;
  final void Function(int branch) onTap;
  final VoidCallback onAdd;

  static const _navBg = Color(0xFF131C2B);
  static const _green = Color(0xFF4CC56A);
  static const _inactive = Color(0xFF6B7688);

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewPadding.bottom;
    return SizedBox(
      height: 66 + inset,
      child: Stack(
        clipBehavior: Clip.none, // let the FAB poke above the bar
        children: [
          Positioned.fill(
            child: Container(
              padding: EdgeInsets.only(bottom: inset),
              decoration: const BoxDecoration(
                color: _navBg,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 16,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _Tab(
                      icon: Icons.home_rounded,
                      label: context.l10n.home,
                      active: currentIndex == 0,
                      onTap: () => onTap(0),
                    ),
                  ),
                  Expanded(
                    child: _Tab(
                      icon: Icons.medication_rounded,
                      label: context.l10n.medicine,
                      active: currentIndex == 1,
                      onTap: () => onTap(1),
                    ),
                  ),
                  const SizedBox(width: 72), // gap for the FAB
                  Expanded(
                    child: _Tab(
                      icon: Icons.water_drop_rounded,
                      label: context.l10n.water,
                      active: currentIndex == 2,
                      onTap: () => onTap(2),
                    ),
                  ),
                  Expanded(
                    child: _Tab(
                      icon: Icons.check_circle_rounded,
                      label: context.l10n.habits,
                      active: currentIndex == 3,
                      onTap: () => onTap(3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: -18,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5FD97E), _green],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _green.withOpacity(0.5),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: _navBg, width: 4),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? _BottomNav._green : _BottomNav._inactive;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: color,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Native→Flutter game launch listener ─────────────────────────────────────

class _LaunchGameListener extends StatefulWidget {
  const _LaunchGameListener({required this.child});
  final Widget child;
  @override
  State<_LaunchGameListener> createState() => _LaunchGameListenerState();
}

class _LaunchGameListenerState extends State<_LaunchGameListener> {
  static const _ch = MethodChannel('rutin/sleep');

  @override
  void initState() {
    super.initState();
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'launchGame') {
        appRouter.push('/morning-gate');
      }
    });
    _checkPendingGate();
  }

  Future<void> _checkPendingGate() async {
    try {
      final pending = await _ch.invokeMethod<bool>('checkPendingGate') ?? false;
      if (pending && mounted) appRouter.push('/morning-gate');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ─── App ─────────────────────────────────────────────────────────────────────

class HabitApp extends StatelessWidget {
  const HabitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LaunchGameListener(child: _AppRouter());
  }
}

class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<String>>(
      valueListenable: LanguageService.box.listenable(keys: const ['language']),
      builder: (context, _, __) => MaterialApp.router(
        onGenerateTitle: (context) => context.l10n.appTitle,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        routerConfig: appRouter,
        locale: Locale(LanguageService.current),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
