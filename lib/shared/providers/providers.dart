import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/medicine/data/medicine_repository.dart';
import '../../features/water/data/water_repository.dart';
import '../../features/habits/data/habit_repository.dart';

final medicineRepositoryProvider = Provider<MedicineRepository>(
  (_) => MedicineRepository(),
);

final waterRepositoryProvider = Provider<WaterRepository>(
  (_) => WaterRepository(),
);

final habitRepositoryProvider = Provider<HabitRepository>(
  (_) => HabitRepository(),
);
