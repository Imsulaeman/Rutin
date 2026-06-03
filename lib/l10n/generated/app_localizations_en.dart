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
  String get startStreakHint => 'Check off habits to start your streak.';

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

  @override
  String get saving => 'Saving...';

  @override
  String get create => 'Create';

  @override
  String get add => 'Add';

  @override
  String get enable => 'Enable';

  @override
  String get later => 'Later';

  @override
  String get next => 'Next';

  @override
  String get replace => 'Replace';

  @override
  String get end => 'End';

  @override
  String get complete => 'Complete';

  @override
  String get incomplete => 'Incomplete';

  @override
  String get completed => 'Completed';

  @override
  String get logged => 'logged';

  @override
  String get partial => 'Partial';

  @override
  String get offDay => 'Off day';

  @override
  String get startToday => 'Start today';

  @override
  String get everyDay => 'Every day';

  @override
  String get notScheduledToday => 'Not scheduled today';

  @override
  String get days => 'days';

  @override
  String get date => 'Date';

  @override
  String get status => 'Status';

  @override
  String get condition => 'Condition';

  @override
  String get startDate => 'Start Date';

  @override
  String get duration => 'Duration';

  @override
  String get dosage => 'Dosage';

  @override
  String get medicineName => 'Medicine name';

  @override
  String get name => 'Name';

  @override
  String get age => 'Age';

  @override
  String get perfect => 'Perfect';

  @override
  String get good => 'Good';

  @override
  String get miss => 'Miss';

  @override
  String get noRoutine => 'No routine';

  @override
  String get newRoutine => 'New routine';

  @override
  String get combineIntoRoutine => 'Combine into routine';

  @override
  String get deleteRoutine => 'Delete routine';

  @override
  String get editRoutine => 'Edit routine';

  @override
  String get editNameAndEmoji => 'Edit name & emoji';

  @override
  String get deleteRoutineBody => 'This routine will be deleted.';

  @override
  String get deleteRoutineOnly => 'Delete routine only';

  @override
  String get deleteRoutineAndHabits => 'Delete routine and habits';

  @override
  String get editHabit => 'Edit Habit';

  @override
  String get habitAlreadyCompleted => 'Already completed today';

  @override
  String get habitMoveToRoutine => 'Move to routine';

  @override
  String get habitTurnIntoMedal => 'Turn into medal';

  @override
  String get moveTo => 'Move to';

  @override
  String get retireHabitDescription =>
      'This habit will leave the active list and be saved as a medal.';

  @override
  String get retireHabitButton => '🏅  Turn into Medal';

  @override
  String get habitsEmptyHint =>
      'Tap + to add a habit, then create a routine from the All tab.';

  @override
  String get groupEmptyHint =>
      'No habits here yet.\nTap + or use \"Move to routine\" from All.';

  @override
  String get allDone => 'All done! 🎉';

  @override
  String get doneToday => 'Done today';

  @override
  String get combine => 'Combine';

  @override
  String get createRoutineHint => 'Create a routine first from the Habits tab';

  @override
  String get enableReminder => 'Enable reminder';

  @override
  String get addTime => 'Add time';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get chooseEmoji => 'Choose an emoji';

  @override
  String get emojiCategoryActivity => 'Activity';

  @override
  String get emojiCategoryMorningNight => 'Morning & Night';

  @override
  String get emojiCategoryFoodDrink => 'Food & Drink';

  @override
  String get emojiCategoryStudyWork => 'Study & Work';

  @override
  String get emojiCategoryHealth => 'Health';

  @override
  String get emojiCategoryGeneral => 'General';

  @override
  String get habitHistory => 'Habit History';

  @override
  String get noHabitsScheduled => 'No habits were scheduled.';

  @override
  String get noHabitsYetShort => 'No habits yet.';

  @override
  String get medicineHistory => 'Medicine History';

  @override
  String get allTaken => 'All taken';

  @override
  String get noSchedule => 'No schedule';

  @override
  String get reviewDoses =>
      'Review doses that were taken, missed, or are not due yet.';

  @override
  String get noMedicineForDay => 'No medicine scheduled for this day.';

  @override
  String get notDueYet => 'Not due yet';

  @override
  String get noLogYet => 'No log yet';

  @override
  String get noDoseSchedule => 'No dose schedule yet';

  @override
  String get deleteMedicineTitle => 'Delete medicine?';

  @override
  String get noMedicineToday => 'No medicine today';

  @override
  String get habitCompletedLog => 'Habit completed';

  @override
  String get recentActivityForDay => 'Recent activity for this day.';

  @override
  String get nothingLoggedToday => 'Nothing logged on this day.';

  @override
  String get scheduleTimes => 'SCHEDULE TIMES';

  @override
  String get mealRule => 'MEAL RULE';

  @override
  String get medicineNameRequired => 'Medicine name is required';

  @override
  String get dosageHint => 'Example: 1 tablet';

  @override
  String get enableAndStart => 'Enable & Start';

  @override
  String get onboarding1Headline => 'Struggling to\nstay consistent?';

  @override
  String get onboarding1Body =>
      'Medicine, water, exercise — small habits that are easy to forget but matter for your health.';

  @override
  String get onboarding2Headline => 'Rutin keeps all\nyour routines.';

  @override
  String get onboarding2Body =>
      'Medicine reminders, habits, water tracking, and morning wake-up games — free, offline, forever.';

  @override
  String get onboarding3Headline => 'One last\nstep.';

  @override
  String get onboarding3Body =>
      'Rutin needs notification permission so reminders work when the app is closed.';

  @override
  String get tapToSetName => 'Tap to set your name';

  @override
  String get bestStreak => 'Best streak';

  @override
  String get habitsDone => 'Habits done';

  @override
  String get habitsAchieved => 'Habits you have achieved';

  @override
  String get chooseCharacter => 'Choose your character';

  @override
  String get sleepModeSubtitle => 'Settings and morning wake-up games';

  @override
  String get settingsSubtitle => 'Language, accessibility, about';

  @override
  String get accessibilityNotAllowed =>
      'Not allowed yet, required for Sleep Mode';

  @override
  String get medicineAlarmSection => 'MEDICINE ALARM';

  @override
  String get fullScreenAlarm => 'Full-screen alarm';

  @override
  String get fullScreenAlarmAllowed =>
      'Allowed, alarms can take over the screen';

  @override
  String get fullScreenAlarmNotAllowed =>
      'Not allowed yet, alarms may stay as heads-up only';

  @override
  String get soundSection => 'SOUND';

  @override
  String get appSound => 'Rutin Drop';

  @override
  String get appSoundSubtitle => 'Short crisp chime';

  @override
  String get appRingtone => 'Rutin Ring';

  @override
  String get appRingtoneSubtitle => 'Full ringtone';

  @override
  String get phoneDefaultSound => 'Phone default';

  @override
  String get phoneDefaultSoundSubtitle =>
      'Use the phone default notification or ringtone';

  @override
  String get notificationSound => 'Notification sound';

  @override
  String get notificationSoundSubtitle => 'Used for Water and Habit reminders';

  @override
  String get medicineAlarmSound => 'Medicine alarm sound';

  @override
  String get medicineAlarmSoundSubtitle =>
      'Used for full-screen medicine alarms';

  @override
  String get otherSection => 'OTHER';

  @override
  String get tutorial => 'Tutorial';

  @override
  String get tutorialSubtitle => 'Replay the onboarding screens';

  @override
  String get dataSection => 'DATA';

  @override
  String get exportBackup => 'Export backup (JSON)';

  @override
  String get exportBackupSubtitle => 'All medicines, habits, water, and logs';

  @override
  String get skipGateTitle => 'Skip the gate?';

  @override
  String get skipGateBody =>
      'This morning game will be skipped. Your streak stays safe.';

  @override
  String get streakFirstDay => 'First day!';

  @override
  String get noHabitsToday => 'No habits today';

  @override
  String get sleepModeStartError =>
      'Sleep mode could not start. Try enabling it again after updating the app.';

  @override
  String get allowBackgroundTitle => 'Allow Background Activity';

  @override
  String get allowBackgroundBody =>
      'Rutin needs background access so medicine alarms, water reminders, and Sleep Mode can still appear on time.\n\nAfter the Rutin app settings page opens, go to Battery, then turn off battery optimization or allow background activity.';

  @override
  String get enableAccessibilityHint =>
      'For the best experience, enable Accessibility Service.';

  @override
  String get accessibilityService => 'Accessibility Service';

  @override
  String get notAllowedYet => 'Not allowed yet';

  @override
  String get backgroundAllowed => 'Background access is already allowed';

  @override
  String get backgroundNotConfirmed =>
      'Not confirmed yet. On some phones this status may stay unchanged even after background access is enabled.';

  @override
  String get sleepTriggerSimulated =>
      'The morning gate should appear now. If not, check whether Sleep Mode is enabled.';

  @override
  String get skipArrow => 'Skip →';

  @override
  String get watchClosely => 'Watch closely...';

  @override
  String get tapTheSequence => 'Tap the sequence!';

  @override
  String get wrongRepeatRound => 'Wrong! Repeat the round...';

  @override
  String get connectTheColors => 'Connect the Colors';

  @override
  String get gameComplete => 'Game complete. Have a great day!';

  @override
  String get noActiveProgramDot => 'No active program.';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get endProgram => 'End program';

  @override
  String get endProgramTitle => 'End program?';

  @override
  String get endProgramBody => 'The active program will be stopped.';

  @override
  String get pdfTitle => 'Rutin - Treatment Adherence Report';

  @override
  String get startDateLabel => 'Start date';

  @override
  String get conditionName => 'Condition name';

  @override
  String get treatmentDuration => 'Treatment duration';

  @override
  String get other => 'Other';

  @override
  String get numberOfDays => 'Number of days';

  @override
  String get linkedMedicine => 'Linked medicine (optional)';

  @override
  String get noLinkedMedicine => 'No linked medicine';

  @override
  String get treatmentValidationError =>
      'Enter a condition and valid duration.';

  @override
  String get replaceActiveProgram => 'Replace active program?';

  @override
  String get replaceProgramBody => 'The previous program will be stopped.';

  @override
  String get waterSettings => 'Water Settings';

  @override
  String get waterGoalReached => 'Goal reached! Great job!';

  @override
  String get remindersStart => 'Reminders start';

  @override
  String get remindersFinished => 'Reminders finished for today';

  @override
  String get comingSoon => 'Coming soon...';

  @override
  String get glassSize => 'Glass size';

  @override
  String get start => 'Start';

  @override
  String get reminder => 'Reminder';

  @override
  String get scheduledDoses => 'Scheduled Doses';

  @override
  String get takenDoses => 'Taken Doses';

  @override
  String get exportedFrom => 'Exported from Rutin';

  @override
  String failedToSave(Object error) {
    return 'Failed to save: $error';
  }

  @override
  String failedToScheduleAlarm(Object error) {
    return 'Failed to schedule alarm: $error';
  }

  @override
  String exportBackupFailed(Object error) {
    return 'Export failed: $error';
  }

  @override
  String get deleteHabitTitle => 'Delete habit?';

  @override
  String deleteHabitBody(Object name) {
    return '$name will be permanently deleted.';
  }

  @override
  String deleteRoutineTitle(Object name) {
    return 'Delete \"$name\"?';
  }

  @override
  String deleteRoutineWithHabitsBody(int count) {
    return 'This routine has $count habits. What should happen to them?';
  }

  @override
  String habitsCompletedCount(int completed, int total) {
    return '$completed of $total habits completed';
  }

  @override
  String habitTurnedIntoMedal(Object emoji, Object name) {
    return '$emoji $name turned into a medal!';
  }

  @override
  String tookMedicine(Object name) {
    return 'Took $name';
  }

  @override
  String drankWaterMl(int ml) {
    return 'Drank $ml ml of water';
  }

  @override
  String ageYearsOld(int age) {
    return '$age years old';
  }

  @override
  String medicineDueNow(int count) {
    return '$count due now';
  }

  @override
  String medicineMissedCount(int count) {
    return '$count missed';
  }

  @override
  String medicineDoneProgress(int taken, int total) {
    return '$taken/$total done';
  }

  @override
  String get noMedicineTodayHint =>
      'Add a medicine schedule with + so today\'s doses appear here.';

  @override
  String streakDay(int streak) {
    return 'Day $streak';
  }

  @override
  String daysRemaining(int count) {
    return '$count days remaining';
  }

  @override
  String adherenceLabel(int pct) {
    return 'Adherence: $pct%';
  }

  @override
  String last7Days(int taken, int total) {
    return 'Last 7 days: $taken/$total doses';
  }

  @override
  String months(Object count) {
    return '$count months';
  }

  @override
  String gameRoundInfo(int round, int colors) {
    return 'Round $round/3  •  $colors colors';
  }

  @override
  String reminderInMinutes(int minutes) {
    return 'Reminder in $minutes min';
  }

  @override
  String reminderInHours(int hours) {
    return 'Reminder in ${hours}h';
  }

  @override
  String reminderInHoursMinutes(int hours, int minutes) {
    return 'Reminder in ${hours}h ${minutes}m';
  }

  @override
  String waterGlassesSummary(int glasses, int minutes) {
    return '$glasses glasses/day - reminder every $minutes min';
  }

  @override
  String ofGoalGlasses(int goal) {
    return 'of $goal glasses';
  }

  @override
  String get medalWaterTitle => 'Water Intake';

  @override
  String get medalMedicineTitle => 'Medicine Streak';

  @override
  String get medalHabitTitle => 'Habit Streak';

  @override
  String get medalPersonalBest => 'Personal best';

  @override
  String get medalStartStreak => 'Start your streak';

  @override
  String get medalNoBestYet => 'No record yet';

  @override
  String get medalWaterDesc =>
      'Consecutive days hitting your daily water goal.';

  @override
  String get medalMedicineDesc =>
      'Based on your best medicine adherence streak.';

  @override
  String get medalHabitDesc => 'Based on your best habit completion streak.';

  @override
  String medalCurrentCount(int count) {
    return '↑ $count days';
  }

  @override
  String medalBestAchieved(Object date) {
    return 'Best: $date';
  }
}
