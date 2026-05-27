import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/habits/presentation/add_habit_screen.dart';
import 'features/habits/presentation/habits_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/medicine/presentation/add_medicine_screen.dart';
import 'features/medicine/presentation/medicine_list_screen.dart';
import 'features/medicine/presentation/reminder_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/water/presentation/water_screen.dart';

final _rootNavigatorKey    = GlobalKey<NavigatorState>();
final _shellHomeKey        = GlobalKey<NavigatorState>();
final _shellMedicineKey    = GlobalKey<NavigatorState>();
final _shellWaterKey       = GlobalKey<NavigatorState>();
final _shellHabitsKey      = GlobalKey<NavigatorState>();
final _shellProfileKey     = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => ShellScaffold(shell: shell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellHomeKey,
          routes: [
            GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellMedicineKey,
          routes: [
            GoRoute(path: '/medicine', builder: (_, __) => const MedicineListScreen()),
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
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
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
      path: '/habits/add',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const AddHabitScreen(),
    ),
    GoRoute(
      path: '/reminder',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ReminderScreen(
        alarmId: int.tryParse(state.uri.queryParameters['id'] ?? '') ?? 0,
        medicineName: state.uri.queryParameters['name'] ?? 'Obat',
        dosage: state.uri.queryParameters['dosage'],
      ),
    ),
  ],
);

void openReminderScreen({
  required int alarmId,
  required String medicineName,
  String? dosage,
}) {
  final encodedName   = Uri.encodeQueryComponent(medicineName);
  final encodedDosage = Uri.encodeQueryComponent(dosage ?? '');
  appRouter.push('/reminder?id=$alarmId&name=$encodedName&dosage=$encodedDosage');
}

// ─── Shell scaffold ───────────────────────────────────────────────────────────

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(
          i,
          initialLocation: i == shell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication_rounded),
            label: 'Obat',
          ),
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop_rounded),
            label: 'Air',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle_rounded),
            label: 'Kebiasaan',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ─── App ─────────────────────────────────────────────────────────────────────

class HabitApp extends StatelessWidget {
  const HabitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Rutin',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
      supportedLocales: const [
        Locale('id'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
