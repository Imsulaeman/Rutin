// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Rutin';

  @override
  String get home => 'Home';

  @override
  String get medicine => 'Medicine';

  @override
  String get water => 'Water';

  @override
  String get habits => 'Habits';

  @override
  String get taken => 'Taken';

  @override
  String get snooze => 'Snooze 1 min';

  @override
  String get missed => 'Missed';

  @override
  String streak(int count) {
    return '$count day streak';
  }

  @override
  String get addMedicine => 'Add Medicine';

  @override
  String get addHabit => 'Add Habit';

  @override
  String get dailyGoal => 'Daily Goal';

  @override
  String glasses(int count) {
    return '$count glasses';
  }

  @override
  String get settings => 'Settings';

  @override
  String get sleepMode => 'Sleep Mode';

  @override
  String get accessibility => 'Accessibility';

  @override
  String get language => 'LANGUAGE';

  @override
  String get about => 'ABOUT';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get allowed => 'Allowed';

  @override
  String get allow => 'Allow';

  @override
  String get version => 'Version';

  @override
  String get builtBy => 'Built by';

  @override
  String get freeForever => 'Daily health, free forever.';

  @override
  String get medicineToday => 'MEDICINE TODAY';

  @override
  String get habitsToday => 'TODAY\'S HABITS';

  @override
  String get done => 'Done';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get archive => 'Archive';

  @override
  String get undo => 'Undo';

  @override
  String get testSequence => 'Test Sequence';

  @override
  String get testRhythm => 'Test Rhythm';

  @override
  String get testDots => 'Test Dots';

  @override
  String get testSleepGate => 'Test Sleep Gate';

  @override
  String get sleepTime => 'Sleep time';

  @override
  String get wakeWindowStart => 'Wake window start';

  @override
  String get wakeWindowEnd => 'Wake window end';

  @override
  String get batteryOptimization => 'Battery Optimization';

  @override
  String get allowBackground => 'Allow background operation';

  @override
  String get configure => 'Configure';

  @override
  String get enableMorningGate => 'Enable the morning wake-up gate';

  @override
  String get mealFree => 'Any time';

  @override
  String get mealBefore => 'Before eating';

  @override
  String get mealAfter => 'After eating';

  @override
  String get mealDuring => 'With food';

  @override
  String get waterReminderTitle => 'Time to drink water';

  @override
  String get waterReminderBody => 'Have you had a glass of water?';

  @override
  String get waterTaken => 'Drank water';

  @override
  String get habitReminderChannel => 'Habit Reminder';

  @override
  String get habitReminderBody => 'Time for your habit!';

  @override
  String get medicineReminderChannel => 'Medicine Reminder';

  @override
  String get medicineReminderDescription => 'Medicine alarm';

  @override
  String get medicineReminderTitle => 'Time to take medicine';

  @override
  String get medicineFallback => 'Medicine';

  @override
  String get medicineTaken => 'Taken';

  @override
  String get medicineRepeat => 'Repeats until confirmed.';

  @override
  String get sleepActive => 'Sleep mode active';

  @override
  String get sleepPaused => 'Sleep mode paused for 30 minutes';

  @override
  String get sleepWaiting => 'Waiting for sleep time...';

  @override
  String get stillAwake => 'I\'m still awake';

  @override
  String get sleepChannel => 'Sleep Mode';

  @override
  String get sleepChannelDescription => 'Sleep detection service';
}
