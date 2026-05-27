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
import 'features/water/presentation/water_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, _) => const HomeScreen()),
    GoRoute(path: '/medicine', builder: (context, _) => const MedicineListScreen()),
    GoRoute(path: '/medicine/add', builder: (context, _) => const AddMedicineScreen()),
    GoRoute(
      path: '/reminder',
      builder: (context, state) => ReminderScreen(
        alarmId: int.tryParse(state.uri.queryParameters['id'] ?? '') ?? 0,
        medicineName: state.uri.queryParameters['name'] ?? 'Obat',
        dosage: state.uri.queryParameters['dosage'],
      ),
    ),
    GoRoute(path: '/water', builder: (context, _) => const WaterScreen()),
    GoRoute(path: '/habits', builder: (context, _) => const HabitsScreen()),
    GoRoute(path: '/habits/add', builder: (context, _) => const AddHabitScreen()),
  ],
);

void openReminderScreen({
  required int alarmId,
  required String medicineName,
  String? dosage,
}) {
  final encodedName = Uri.encodeQueryComponent(medicineName);
  final encodedDosage = Uri.encodeQueryComponent(dosage ?? '');
  appRouter.push('/reminder?id=$alarmId&name=$encodedName&dosage=$encodedDosage');
}

class HabitApp extends StatelessWidget {
  const HabitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Habit App',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: appRouter,
      supportedLocales: const [
        Locale('id'), // Bahasa Indonesia (default)
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
