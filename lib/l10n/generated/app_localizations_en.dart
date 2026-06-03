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
  String get waterToday => 'WATER TODAY';

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

  @override
  String get history => 'History';

  @override
  String get activityLogAcrossFeatures => 'Activity log across all features';

  @override
  String get treatmentProgram => 'Treatment Program';

  @override
  String get noActiveProgramYet => 'No active program yet';

  @override
  String programDay(int count) {
    return 'day $count';
  }

  @override
  String get routineName => 'Routine name';

  @override
  String get habitName => 'Habit name';

  @override
  String get routineLabel => 'ROUTINE';

  @override
  String get scheduleLabel => 'SCHEDULE';

  @override
  String get reminderLabel => 'REMINDER';

  @override
  String get noHabitsYet => 'No habits yet';

  @override
  String get noMedicineScheduledToday => 'No medicine scheduled today.';

  @override
  String get noHabitsScheduledToday => 'No habits scheduled today.';

  @override
  String get waterProgressToday => 'Water progress today';

  @override
  String get homePullDownHint =>
      'Pull down and enjoy the view.\nScroll a little and check today.';

  @override
  String get waterMascotNudge => 'Keep going. You are doing great.';

  @override
  String waterOfMl(Object value) {
    return 'of $value ml';
  }

  @override
  String waterAmountAdded(int value) {
    return '+$value ml added';
  }

  @override
  String get waterWhoGuidance =>
      'WHO recommends 2.0L (women) - 2.5L (men) per day. In hot climates like Indonesia, add 0.5-1.0L.';

  @override
  String waterReminderRange(int minutes) {
    return 'Every $minutes min within the active window';
  }

  @override
  String get archiveMedicineTitle => 'Archive medicine?';

  @override
  String archiveMedicineBody(Object name) {
    return '$name will be hidden from today\'s list. History stays saved.';
  }

  @override
  String deleteMedicineBody(Object name) {
    return '$name will be permanently deleted together with its history.';
  }

  @override
  String nextDose(Object dayLabel, Object time) {
    return 'Next $dayLabel $time';
  }

  @override
  String get bestStreakDays => 'best streak days';

  @override
  String get smallStepsBigChange =>
      'Small steps every day\ncreate big change ✨';

  @override
  String streakDaysRow(int count) {
    return '$count days in a row';
  }

  @override
  String get noStreakYet => 'No streak yet';

  @override
  String get medals => 'Medals';

  @override
  String get noMedalsYet => 'No medals yet';

  @override
  String get retireFirstHabitForMedal =>
      'Retire your first habit\nto earn your first medal.';

  @override
  String bestStreakLabel(int count) {
    return '🔥 Best streak: $count days';
  }

  @override
  String earnedOn(Object date) {
    return 'Earned $date';
  }

  @override
  String get all => 'All';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get greetingNight => 'Good night';

  @override
  String get tutorialSkip => 'SKIP';

  @override
  String get tutorialHintContinue => 'Tap anywhere to continue';

  @override
  String get tutorialHintFinish => 'Tap anywhere to finish';

  @override
  String get tutorialWelcomeTitle => 'Welcome to Rutin!';

  @override
  String get tutorialWelcomeBody =>
      'Your daily dashboard - everything is here. Tap anywhere to continue.';

  @override
  String get tutorialAddButtonTitle => 'The + button';

  @override
  String get tutorialAddButtonBody => 'Add a new medicine or habit from here.';

  @override
  String get tutorialMedicineBody =>
      'Full medicine schedule and daily dose logging.';

  @override
  String get tutorialWaterBody =>
      'Log water intake and set drinking reminders.';

  @override
  String get tutorialHabitsBody =>
      'Create and check off daily habits. Build streaks and earn medals.';

  @override
  String homeHiddenHabitsMore(int count) {
    return '+ $count more';
  }

  @override
  String homeHabitsDoneSummary(int done, int due) {
    return '$done / $due done';
  }

  @override
  String get permissionNotificationsTitle => 'Allow Notifications';

  @override
  String get permissionNotificationsBody =>
      'Required so medicine and water reminders appear on screen.';

  @override
  String get permissionExactAlarmTitle => 'Allow Exact Alarm';

  @override
  String get permissionExactAlarmBody =>
      'So reminders appear on time - open Alarms & Reminders and enable Rutin.';

  @override
  String get permissionFullScreenTitle => 'Allow Full Screen';

  @override
  String get permissionFullScreenBody =>
      'Medicine reminders can appear full screen while the device is locked.';

  @override
  String get skip => 'Skip';

  @override
  String get treatmentProgramComplete => 'Program complete';

  @override
  String treatmentDaysRemaining(int day, int left) {
    return 'Day $day - $left days remaining';
  }
}
