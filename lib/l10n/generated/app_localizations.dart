import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Rutin'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @medicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get medicine;

  /// No description provided for @water.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get water;

  /// No description provided for @habits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get habits;

  /// No description provided for @taken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get taken;

  /// No description provided for @snooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze 1 min'**
  String get snooze;

  /// No description provided for @missed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get missed;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak'**
  String streak(int count);

  /// No description provided for @addMedicine.
  ///
  /// In en, this message translates to:
  /// **'Add Medicine'**
  String get addMedicine;

  /// No description provided for @addHabit.
  ///
  /// In en, this message translates to:
  /// **'Add Habit'**
  String get addHabit;

  /// No description provided for @dailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Goal'**
  String get dailyGoal;

  /// No description provided for @glasses.
  ///
  /// In en, this message translates to:
  /// **'{count} glasses'**
  String glasses(int count);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @sleepMode.
  ///
  /// In en, this message translates to:
  /// **'Sleep Mode'**
  String get sleepMode;

  /// No description provided for @accessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibility;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get language;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get about;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @allowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get allowed;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @builtBy.
  ///
  /// In en, this message translates to:
  /// **'Built by'**
  String get builtBy;

  /// No description provided for @freeForever.
  ///
  /// In en, this message translates to:
  /// **'Daily health, free forever.'**
  String get freeForever;

  /// No description provided for @medicineToday.
  ///
  /// In en, this message translates to:
  /// **'MEDICINE TODAY'**
  String get medicineToday;

  /// No description provided for @waterToday.
  ///
  /// In en, this message translates to:
  /// **'WATER TODAY'**
  String get waterToday;

  /// No description provided for @habitsToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S HABITS'**
  String get habitsToday;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @testSequence.
  ///
  /// In en, this message translates to:
  /// **'Test Sequence'**
  String get testSequence;

  /// No description provided for @testRhythm.
  ///
  /// In en, this message translates to:
  /// **'Test Rhythm'**
  String get testRhythm;

  /// No description provided for @testDots.
  ///
  /// In en, this message translates to:
  /// **'Test Dots'**
  String get testDots;

  /// No description provided for @testSleepGate.
  ///
  /// In en, this message translates to:
  /// **'Test Sleep Gate'**
  String get testSleepGate;

  /// No description provided for @sleepTime.
  ///
  /// In en, this message translates to:
  /// **'Sleep time'**
  String get sleepTime;

  /// No description provided for @wakeWindowStart.
  ///
  /// In en, this message translates to:
  /// **'Wake window start'**
  String get wakeWindowStart;

  /// No description provided for @wakeWindowEnd.
  ///
  /// In en, this message translates to:
  /// **'Wake window end'**
  String get wakeWindowEnd;

  /// No description provided for @batteryOptimization.
  ///
  /// In en, this message translates to:
  /// **'Battery Optimization'**
  String get batteryOptimization;

  /// No description provided for @allowBackground.
  ///
  /// In en, this message translates to:
  /// **'Allow background operation'**
  String get allowBackground;

  /// No description provided for @configure.
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get configure;

  /// No description provided for @enableMorningGate.
  ///
  /// In en, this message translates to:
  /// **'Enable the morning wake-up gate'**
  String get enableMorningGate;

  /// No description provided for @mealFree.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get mealFree;

  /// No description provided for @mealBefore.
  ///
  /// In en, this message translates to:
  /// **'Before eating'**
  String get mealBefore;

  /// No description provided for @mealAfter.
  ///
  /// In en, this message translates to:
  /// **'After eating'**
  String get mealAfter;

  /// No description provided for @mealDuring.
  ///
  /// In en, this message translates to:
  /// **'With food'**
  String get mealDuring;

  /// No description provided for @waterReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to drink water'**
  String get waterReminderTitle;

  /// No description provided for @waterReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Have you had a glass of water?'**
  String get waterReminderBody;

  /// No description provided for @waterTaken.
  ///
  /// In en, this message translates to:
  /// **'Drank water'**
  String get waterTaken;

  /// No description provided for @habitReminderChannel.
  ///
  /// In en, this message translates to:
  /// **'Habit Reminder'**
  String get habitReminderChannel;

  /// No description provided for @habitReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Time for your habit!'**
  String get habitReminderBody;

  /// No description provided for @medicineReminderChannel.
  ///
  /// In en, this message translates to:
  /// **'Medicine Reminder'**
  String get medicineReminderChannel;

  /// No description provided for @medicineReminderDescription.
  ///
  /// In en, this message translates to:
  /// **'Medicine alarm'**
  String get medicineReminderDescription;

  /// No description provided for @medicineReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to take medicine'**
  String get medicineReminderTitle;

  /// No description provided for @medicineFallback.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get medicineFallback;

  /// No description provided for @medicineTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get medicineTaken;

  /// No description provided for @medicineRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeats until confirmed.'**
  String get medicineRepeat;

  /// No description provided for @sleepActive.
  ///
  /// In en, this message translates to:
  /// **'Sleep mode active'**
  String get sleepActive;

  /// No description provided for @sleepPaused.
  ///
  /// In en, this message translates to:
  /// **'Sleep mode paused for 30 minutes'**
  String get sleepPaused;

  /// No description provided for @sleepWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for sleep time...'**
  String get sleepWaiting;

  /// No description provided for @stillAwake.
  ///
  /// In en, this message translates to:
  /// **'I\'m still awake'**
  String get stillAwake;

  /// No description provided for @sleepChannel.
  ///
  /// In en, this message translates to:
  /// **'Sleep Mode'**
  String get sleepChannel;

  /// No description provided for @sleepChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Sleep detection service'**
  String get sleepChannelDescription;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @activityLogAcrossFeatures.
  ///
  /// In en, this message translates to:
  /// **'Activity log across all features'**
  String get activityLogAcrossFeatures;

  /// No description provided for @treatmentProgram.
  ///
  /// In en, this message translates to:
  /// **'Treatment Program'**
  String get treatmentProgram;

  /// No description provided for @noActiveProgramYet.
  ///
  /// In en, this message translates to:
  /// **'No active program yet'**
  String get noActiveProgramYet;

  /// No description provided for @programDay.
  ///
  /// In en, this message translates to:
  /// **'day {count}'**
  String programDay(int count);

  /// No description provided for @routineName.
  ///
  /// In en, this message translates to:
  /// **'Routine name'**
  String get routineName;

  /// No description provided for @habitName.
  ///
  /// In en, this message translates to:
  /// **'Habit name'**
  String get habitName;

  /// No description provided for @routineLabel.
  ///
  /// In en, this message translates to:
  /// **'ROUTINE'**
  String get routineLabel;

  /// No description provided for @scheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULE'**
  String get scheduleLabel;

  /// No description provided for @reminderLabel.
  ///
  /// In en, this message translates to:
  /// **'REMINDER'**
  String get reminderLabel;

  /// No description provided for @noHabitsYet.
  ///
  /// In en, this message translates to:
  /// **'No habits yet'**
  String get noHabitsYet;

  /// No description provided for @noMedicineScheduledToday.
  ///
  /// In en, this message translates to:
  /// **'No medicine scheduled today.'**
  String get noMedicineScheduledToday;

  /// No description provided for @noHabitsScheduledToday.
  ///
  /// In en, this message translates to:
  /// **'No habits scheduled today.'**
  String get noHabitsScheduledToday;

  /// No description provided for @waterProgressToday.
  ///
  /// In en, this message translates to:
  /// **'Water progress today'**
  String get waterProgressToday;

  /// No description provided for @homePullDownHint.
  ///
  /// In en, this message translates to:
  /// **'Pull down and enjoy the view.\nScroll a little and check today.'**
  String get homePullDownHint;

  /// No description provided for @waterMascotNudge.
  ///
  /// In en, this message translates to:
  /// **'Keep going. You are doing great.'**
  String get waterMascotNudge;

  /// No description provided for @waterOfMl.
  ///
  /// In en, this message translates to:
  /// **'of {value} ml'**
  String waterOfMl(Object value);

  /// No description provided for @waterAmountAdded.
  ///
  /// In en, this message translates to:
  /// **'+{value} ml added'**
  String waterAmountAdded(int value);

  /// No description provided for @waterWhoGuidance.
  ///
  /// In en, this message translates to:
  /// **'WHO recommends 2.0L (women) - 2.5L (men) per day. In hot climates like Indonesia, add 0.5-1.0L.'**
  String get waterWhoGuidance;

  /// No description provided for @waterReminderRange.
  ///
  /// In en, this message translates to:
  /// **'Every {minutes} min within the active window'**
  String waterReminderRange(int minutes);

  /// No description provided for @archiveMedicineTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive medicine?'**
  String get archiveMedicineTitle;

  /// No description provided for @archiveMedicineBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will be hidden from today\'s list. History stays saved.'**
  String archiveMedicineBody(Object name);

  /// No description provided for @deleteMedicineBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will be permanently deleted together with its history.'**
  String deleteMedicineBody(Object name);

  /// No description provided for @nextDose.
  ///
  /// In en, this message translates to:
  /// **'Next {dayLabel} {time}'**
  String nextDose(Object dayLabel, Object time);

  /// No description provided for @bestStreakDays.
  ///
  /// In en, this message translates to:
  /// **'best streak days'**
  String get bestStreakDays;

  /// No description provided for @smallStepsBigChange.
  ///
  /// In en, this message translates to:
  /// **'Small steps every day\ncreate big change ✨'**
  String get smallStepsBigChange;

  /// No description provided for @streakDaysRow.
  ///
  /// In en, this message translates to:
  /// **'{count} days in a row'**
  String streakDaysRow(int count);

  /// No description provided for @noStreakYet.
  ///
  /// In en, this message translates to:
  /// **'No streak yet'**
  String get noStreakYet;

  /// No description provided for @medals.
  ///
  /// In en, this message translates to:
  /// **'Medals'**
  String get medals;

  /// No description provided for @noMedalsYet.
  ///
  /// In en, this message translates to:
  /// **'No medals yet'**
  String get noMedalsYet;

  /// No description provided for @retireFirstHabitForMedal.
  ///
  /// In en, this message translates to:
  /// **'Retire your first habit\nto earn your first medal.'**
  String get retireFirstHabitForMedal;

  /// No description provided for @bestStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'🔥 Best streak: {count} days'**
  String bestStreakLabel(int count);

  /// No description provided for @startStreakHint.
  ///
  /// In en, this message translates to:
  /// **'Check off habits to start your streak.'**
  String get startStreakHint;

  /// No description provided for @earnedOn.
  ///
  /// In en, this message translates to:
  /// **'Earned {date}'**
  String earnedOn(Object date);

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @greetingNight.
  ///
  /// In en, this message translates to:
  /// **'Good night'**
  String get greetingNight;

  /// No description provided for @tutorialSkip.
  ///
  /// In en, this message translates to:
  /// **'SKIP'**
  String get tutorialSkip;

  /// No description provided for @tutorialHintContinue.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere to continue'**
  String get tutorialHintContinue;

  /// No description provided for @tutorialHintFinish.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere to finish'**
  String get tutorialHintFinish;

  /// No description provided for @tutorialWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Rutin!'**
  String get tutorialWelcomeTitle;

  /// No description provided for @tutorialWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Your daily dashboard - everything is here. Tap anywhere to continue.'**
  String get tutorialWelcomeBody;

  /// No description provided for @tutorialAddButtonTitle.
  ///
  /// In en, this message translates to:
  /// **'The + button'**
  String get tutorialAddButtonTitle;

  /// No description provided for @tutorialAddButtonBody.
  ///
  /// In en, this message translates to:
  /// **'Add a new medicine or habit from here.'**
  String get tutorialAddButtonBody;

  /// No description provided for @tutorialMedicineBody.
  ///
  /// In en, this message translates to:
  /// **'Full medicine schedule and daily dose logging.'**
  String get tutorialMedicineBody;

  /// No description provided for @tutorialWaterBody.
  ///
  /// In en, this message translates to:
  /// **'Log water intake and set drinking reminders.'**
  String get tutorialWaterBody;

  /// No description provided for @tutorialHabitsBody.
  ///
  /// In en, this message translates to:
  /// **'Create and check off daily habits. Build streaks and earn medals.'**
  String get tutorialHabitsBody;

  /// No description provided for @homeHiddenHabitsMore.
  ///
  /// In en, this message translates to:
  /// **'+ {count} more'**
  String homeHiddenHabitsMore(int count);

  /// No description provided for @homeHabitsDoneSummary.
  ///
  /// In en, this message translates to:
  /// **'{done} / {due} done'**
  String homeHabitsDoneSummary(int done, int due);

  /// No description provided for @permissionNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow Notifications'**
  String get permissionNotificationsTitle;

  /// No description provided for @permissionNotificationsBody.
  ///
  /// In en, this message translates to:
  /// **'Required so medicine and water reminders appear on screen.'**
  String get permissionNotificationsBody;

  /// No description provided for @permissionExactAlarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow Exact Alarm'**
  String get permissionExactAlarmTitle;

  /// No description provided for @permissionExactAlarmBody.
  ///
  /// In en, this message translates to:
  /// **'So reminders appear on time - open Alarms & Reminders and enable Rutin.'**
  String get permissionExactAlarmBody;

  /// No description provided for @permissionFullScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow Full Screen'**
  String get permissionFullScreenTitle;

  /// No description provided for @permissionFullScreenBody.
  ///
  /// In en, this message translates to:
  /// **'Medicine reminders can appear full screen while the device is locked.'**
  String get permissionFullScreenBody;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @treatmentProgramComplete.
  ///
  /// In en, this message translates to:
  /// **'Program complete'**
  String get treatmentProgramComplete;

  /// No description provided for @treatmentDaysRemaining.
  ///
  /// In en, this message translates to:
  /// **'Day {day} - {left} days remaining'**
  String treatmentDaysRemaining(int day, int left);

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @incomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get incomplete;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @logged.
  ///
  /// In en, this message translates to:
  /// **'logged'**
  String get logged;

  /// No description provided for @partial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partial;

  /// No description provided for @offDay.
  ///
  /// In en, this message translates to:
  /// **'Off day'**
  String get offDay;

  /// No description provided for @startToday.
  ///
  /// In en, this message translates to:
  /// **'Start today'**
  String get startToday;

  /// No description provided for @everyDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get everyDay;

  /// No description provided for @notScheduledToday.
  ///
  /// In en, this message translates to:
  /// **'Not scheduled today'**
  String get notScheduledToday;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @dosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// No description provided for @medicineName.
  ///
  /// In en, this message translates to:
  /// **'Medicine name'**
  String get medicineName;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @perfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect'**
  String get perfect;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @miss.
  ///
  /// In en, this message translates to:
  /// **'Miss'**
  String get miss;

  /// No description provided for @noRoutine.
  ///
  /// In en, this message translates to:
  /// **'No routine'**
  String get noRoutine;

  /// No description provided for @newRoutine.
  ///
  /// In en, this message translates to:
  /// **'New routine'**
  String get newRoutine;

  /// No description provided for @combineIntoRoutine.
  ///
  /// In en, this message translates to:
  /// **'Combine into routine'**
  String get combineIntoRoutine;

  /// No description provided for @deleteRoutine.
  ///
  /// In en, this message translates to:
  /// **'Delete routine'**
  String get deleteRoutine;

  /// No description provided for @editRoutine.
  ///
  /// In en, this message translates to:
  /// **'Edit routine'**
  String get editRoutine;

  /// No description provided for @editNameAndEmoji.
  ///
  /// In en, this message translates to:
  /// **'Edit name & emoji'**
  String get editNameAndEmoji;

  /// No description provided for @deleteRoutineBody.
  ///
  /// In en, this message translates to:
  /// **'This routine will be deleted.'**
  String get deleteRoutineBody;

  /// No description provided for @deleteRoutineOnly.
  ///
  /// In en, this message translates to:
  /// **'Delete routine only'**
  String get deleteRoutineOnly;

  /// No description provided for @deleteRoutineAndHabits.
  ///
  /// In en, this message translates to:
  /// **'Delete routine and habits'**
  String get deleteRoutineAndHabits;

  /// No description provided for @editHabit.
  ///
  /// In en, this message translates to:
  /// **'Edit Habit'**
  String get editHabit;

  /// No description provided for @habitAlreadyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Already completed today'**
  String get habitAlreadyCompleted;

  /// No description provided for @habitMoveToRoutine.
  ///
  /// In en, this message translates to:
  /// **'Move to routine'**
  String get habitMoveToRoutine;

  /// No description provided for @habitTurnIntoMedal.
  ///
  /// In en, this message translates to:
  /// **'Turn into medal'**
  String get habitTurnIntoMedal;

  /// No description provided for @moveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to'**
  String get moveTo;

  /// No description provided for @retireHabitDescription.
  ///
  /// In en, this message translates to:
  /// **'This habit will leave the active list and be saved as a medal.'**
  String get retireHabitDescription;

  /// No description provided for @retireHabitButton.
  ///
  /// In en, this message translates to:
  /// **'🏅  Turn into Medal'**
  String get retireHabitButton;

  /// No description provided for @habitsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a habit, then create a routine from the All tab.'**
  String get habitsEmptyHint;

  /// No description provided for @groupEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No habits here yet.\nTap + or use \"Move to routine\" from All.'**
  String get groupEmptyHint;

  /// No description provided for @allDone.
  ///
  /// In en, this message translates to:
  /// **'All done! 🎉'**
  String get allDone;

  /// No description provided for @doneToday.
  ///
  /// In en, this message translates to:
  /// **'Done today'**
  String get doneToday;

  /// No description provided for @combine.
  ///
  /// In en, this message translates to:
  /// **'Combine'**
  String get combine;

  /// No description provided for @createRoutineHint.
  ///
  /// In en, this message translates to:
  /// **'Create a routine first from the Habits tab'**
  String get createRoutineHint;

  /// No description provided for @enableReminder.
  ///
  /// In en, this message translates to:
  /// **'Enable reminder'**
  String get enableReminder;

  /// No description provided for @addTime.
  ///
  /// In en, this message translates to:
  /// **'Add time'**
  String get addTime;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTime;

  /// No description provided for @chooseEmoji.
  ///
  /// In en, this message translates to:
  /// **'Choose an emoji'**
  String get chooseEmoji;

  /// No description provided for @emojiCategoryActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get emojiCategoryActivity;

  /// No description provided for @emojiCategoryMorningNight.
  ///
  /// In en, this message translates to:
  /// **'Morning & Night'**
  String get emojiCategoryMorningNight;

  /// No description provided for @emojiCategoryFoodDrink.
  ///
  /// In en, this message translates to:
  /// **'Food & Drink'**
  String get emojiCategoryFoodDrink;

  /// No description provided for @emojiCategoryStudyWork.
  ///
  /// In en, this message translates to:
  /// **'Study & Work'**
  String get emojiCategoryStudyWork;

  /// No description provided for @emojiCategoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get emojiCategoryHealth;

  /// No description provided for @emojiCategoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get emojiCategoryGeneral;

  /// No description provided for @habitHistory.
  ///
  /// In en, this message translates to:
  /// **'Habit History'**
  String get habitHistory;

  /// No description provided for @noHabitsScheduled.
  ///
  /// In en, this message translates to:
  /// **'No habits were scheduled.'**
  String get noHabitsScheduled;

  /// No description provided for @noHabitsYetShort.
  ///
  /// In en, this message translates to:
  /// **'No habits yet.'**
  String get noHabitsYetShort;

  /// No description provided for @medicineHistory.
  ///
  /// In en, this message translates to:
  /// **'Medicine History'**
  String get medicineHistory;

  /// No description provided for @allTaken.
  ///
  /// In en, this message translates to:
  /// **'All taken'**
  String get allTaken;

  /// No description provided for @noSchedule.
  ///
  /// In en, this message translates to:
  /// **'No schedule'**
  String get noSchedule;

  /// No description provided for @reviewDoses.
  ///
  /// In en, this message translates to:
  /// **'Review doses that were taken, missed, or are not due yet.'**
  String get reviewDoses;

  /// No description provided for @noMedicineForDay.
  ///
  /// In en, this message translates to:
  /// **'No medicine scheduled for this day.'**
  String get noMedicineForDay;

  /// No description provided for @notDueYet.
  ///
  /// In en, this message translates to:
  /// **'Not due yet'**
  String get notDueYet;

  /// No description provided for @noLogYet.
  ///
  /// In en, this message translates to:
  /// **'No log yet'**
  String get noLogYet;

  /// No description provided for @noDoseSchedule.
  ///
  /// In en, this message translates to:
  /// **'No dose schedule yet'**
  String get noDoseSchedule;

  /// No description provided for @deleteMedicineTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete medicine?'**
  String get deleteMedicineTitle;

  /// No description provided for @noMedicineToday.
  ///
  /// In en, this message translates to:
  /// **'No medicine today'**
  String get noMedicineToday;

  /// No description provided for @habitCompletedLog.
  ///
  /// In en, this message translates to:
  /// **'Habit completed'**
  String get habitCompletedLog;

  /// No description provided for @recentActivityForDay.
  ///
  /// In en, this message translates to:
  /// **'Recent activity for this day.'**
  String get recentActivityForDay;

  /// No description provided for @nothingLoggedToday.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged on this day.'**
  String get nothingLoggedToday;

  /// No description provided for @scheduleTimes.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULE TIMES'**
  String get scheduleTimes;

  /// No description provided for @mealRule.
  ///
  /// In en, this message translates to:
  /// **'MEAL RULE'**
  String get mealRule;

  /// No description provided for @medicineNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Medicine name is required'**
  String get medicineNameRequired;

  /// No description provided for @dosageHint.
  ///
  /// In en, this message translates to:
  /// **'Example: 1 tablet'**
  String get dosageHint;

  /// No description provided for @enableAndStart.
  ///
  /// In en, this message translates to:
  /// **'Enable & Start'**
  String get enableAndStart;

  /// No description provided for @onboarding1Headline.
  ///
  /// In en, this message translates to:
  /// **'Struggling to\nstay consistent?'**
  String get onboarding1Headline;

  /// No description provided for @onboarding1Body.
  ///
  /// In en, this message translates to:
  /// **'Medicine, water, exercise — small habits that are easy to forget but matter for your health.'**
  String get onboarding1Body;

  /// No description provided for @onboarding2Headline.
  ///
  /// In en, this message translates to:
  /// **'Rutin keeps all\nyour routines.'**
  String get onboarding2Headline;

  /// No description provided for @onboarding2Body.
  ///
  /// In en, this message translates to:
  /// **'Medicine reminders, habits, water tracking, and morning wake-up games — free, offline, forever.'**
  String get onboarding2Body;

  /// No description provided for @onboarding3Headline.
  ///
  /// In en, this message translates to:
  /// **'One last\nstep.'**
  String get onboarding3Headline;

  /// No description provided for @onboarding3Body.
  ///
  /// In en, this message translates to:
  /// **'Rutin needs notification permission so reminders work when the app is closed.'**
  String get onboarding3Body;

  /// No description provided for @tapToSetName.
  ///
  /// In en, this message translates to:
  /// **'Tap to set your name'**
  String get tapToSetName;

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get bestStreak;

  /// No description provided for @habitsDone.
  ///
  /// In en, this message translates to:
  /// **'Habits done'**
  String get habitsDone;

  /// No description provided for @habitsAchieved.
  ///
  /// In en, this message translates to:
  /// **'Habits you have achieved'**
  String get habitsAchieved;

  /// No description provided for @chooseCharacter.
  ///
  /// In en, this message translates to:
  /// **'Choose your character'**
  String get chooseCharacter;

  /// No description provided for @sleepModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Settings and morning wake-up games'**
  String get sleepModeSubtitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Language, accessibility, about'**
  String get settingsSubtitle;

  /// No description provided for @accessibilityNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Not allowed yet, required for Sleep Mode'**
  String get accessibilityNotAllowed;

  /// No description provided for @medicineAlarmSection.
  ///
  /// In en, this message translates to:
  /// **'MEDICINE ALARM'**
  String get medicineAlarmSection;

  /// No description provided for @fullScreenAlarm.
  ///
  /// In en, this message translates to:
  /// **'Full-screen alarm'**
  String get fullScreenAlarm;

  /// No description provided for @fullScreenAlarmAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed, alarms can take over the screen'**
  String get fullScreenAlarmAllowed;

  /// No description provided for @fullScreenAlarmNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Not allowed yet, alarms may stay as heads-up only'**
  String get fullScreenAlarmNotAllowed;

  /// No description provided for @soundSection.
  ///
  /// In en, this message translates to:
  /// **'SOUND'**
  String get soundSection;

  /// No description provided for @appSound.
  ///
  /// In en, this message translates to:
  /// **'Rutin Drop'**
  String get appSound;

  /// No description provided for @appSoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Short crisp chime'**
  String get appSoundSubtitle;

  /// No description provided for @appRingtone.
  ///
  /// In en, this message translates to:
  /// **'Rutin Ring'**
  String get appRingtone;

  /// No description provided for @appRingtoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Full ringtone'**
  String get appRingtoneSubtitle;

  /// No description provided for @phoneDefaultSound.
  ///
  /// In en, this message translates to:
  /// **'Phone default'**
  String get phoneDefaultSound;

  /// No description provided for @phoneDefaultSoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the phone default notification or ringtone'**
  String get phoneDefaultSoundSubtitle;

  /// No description provided for @notificationSound.
  ///
  /// In en, this message translates to:
  /// **'Notification sound'**
  String get notificationSound;

  /// No description provided for @notificationSoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used for Water and Habit reminders'**
  String get notificationSoundSubtitle;

  /// No description provided for @medicineAlarmSound.
  ///
  /// In en, this message translates to:
  /// **'Medicine alarm sound'**
  String get medicineAlarmSound;

  /// No description provided for @medicineAlarmSoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used for full-screen medicine alarms'**
  String get medicineAlarmSoundSubtitle;

  /// No description provided for @otherSection.
  ///
  /// In en, this message translates to:
  /// **'OTHER'**
  String get otherSection;

  /// No description provided for @tutorial.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get tutorial;

  /// No description provided for @tutorialSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replay the onboarding screens'**
  String get tutorialSubtitle;

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'DATA'**
  String get dataSection;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export backup (JSON)'**
  String get exportBackup;

  /// No description provided for @exportBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All medicines, habits, water, and logs'**
  String get exportBackupSubtitle;

  /// No description provided for @skipGateTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip the gate?'**
  String get skipGateTitle;

  /// No description provided for @skipGateBody.
  ///
  /// In en, this message translates to:
  /// **'This morning game will be skipped. Your streak stays safe.'**
  String get skipGateBody;

  /// No description provided for @streakFirstDay.
  ///
  /// In en, this message translates to:
  /// **'First day!'**
  String get streakFirstDay;

  /// No description provided for @noHabitsToday.
  ///
  /// In en, this message translates to:
  /// **'No habits today'**
  String get noHabitsToday;

  /// No description provided for @sleepModeStartError.
  ///
  /// In en, this message translates to:
  /// **'Sleep mode could not start. Try enabling it again after updating the app.'**
  String get sleepModeStartError;

  /// No description provided for @allowBackgroundTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow Background Activity'**
  String get allowBackgroundTitle;

  /// No description provided for @allowBackgroundBody.
  ///
  /// In en, this message translates to:
  /// **'Rutin needs background access so medicine alarms, water reminders, and Sleep Mode can still appear on time.\n\nAfter the Rutin app settings page opens, go to Battery, then turn off battery optimization or allow background activity.'**
  String get allowBackgroundBody;

  /// No description provided for @enableAccessibilityHint.
  ///
  /// In en, this message translates to:
  /// **'For the best experience, enable Accessibility Service.'**
  String get enableAccessibilityHint;

  /// No description provided for @accessibilityService.
  ///
  /// In en, this message translates to:
  /// **'Accessibility Service'**
  String get accessibilityService;

  /// No description provided for @notAllowedYet.
  ///
  /// In en, this message translates to:
  /// **'Not allowed yet'**
  String get notAllowedYet;

  /// No description provided for @backgroundAllowed.
  ///
  /// In en, this message translates to:
  /// **'Background access is already allowed'**
  String get backgroundAllowed;

  /// No description provided for @backgroundNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed yet. On some phones this status may stay unchanged even after background access is enabled.'**
  String get backgroundNotConfirmed;

  /// No description provided for @sleepTriggerSimulated.
  ///
  /// In en, this message translates to:
  /// **'The morning gate should appear now. If not, check whether Sleep Mode is enabled.'**
  String get sleepTriggerSimulated;

  /// No description provided for @skipArrow.
  ///
  /// In en, this message translates to:
  /// **'Skip →'**
  String get skipArrow;

  /// No description provided for @watchClosely.
  ///
  /// In en, this message translates to:
  /// **'Watch closely...'**
  String get watchClosely;

  /// No description provided for @tapTheSequence.
  ///
  /// In en, this message translates to:
  /// **'Tap the sequence!'**
  String get tapTheSequence;

  /// No description provided for @wrongRepeatRound.
  ///
  /// In en, this message translates to:
  /// **'Wrong! Repeat the round...'**
  String get wrongRepeatRound;

  /// No description provided for @connectTheColors.
  ///
  /// In en, this message translates to:
  /// **'Connect the Colors'**
  String get connectTheColors;

  /// No description provided for @gameComplete.
  ///
  /// In en, this message translates to:
  /// **'Game complete. Have a great day!'**
  String get gameComplete;

  /// No description provided for @noActiveProgramDot.
  ///
  /// In en, this message translates to:
  /// **'No active program.'**
  String get noActiveProgramDot;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @endProgram.
  ///
  /// In en, this message translates to:
  /// **'End program'**
  String get endProgram;

  /// No description provided for @endProgramTitle.
  ///
  /// In en, this message translates to:
  /// **'End program?'**
  String get endProgramTitle;

  /// No description provided for @endProgramBody.
  ///
  /// In en, this message translates to:
  /// **'The active program will be stopped.'**
  String get endProgramBody;

  /// No description provided for @pdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Rutin - Treatment Adherence Report'**
  String get pdfTitle;

  /// No description provided for @startDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDateLabel;

  /// No description provided for @conditionName.
  ///
  /// In en, this message translates to:
  /// **'Condition name'**
  String get conditionName;

  /// No description provided for @treatmentDuration.
  ///
  /// In en, this message translates to:
  /// **'Treatment duration'**
  String get treatmentDuration;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @numberOfDays.
  ///
  /// In en, this message translates to:
  /// **'Number of days'**
  String get numberOfDays;

  /// No description provided for @linkedMedicine.
  ///
  /// In en, this message translates to:
  /// **'Linked medicine (optional)'**
  String get linkedMedicine;

  /// No description provided for @noLinkedMedicine.
  ///
  /// In en, this message translates to:
  /// **'No linked medicine'**
  String get noLinkedMedicine;

  /// No description provided for @treatmentValidationError.
  ///
  /// In en, this message translates to:
  /// **'Enter a condition and valid duration.'**
  String get treatmentValidationError;

  /// No description provided for @replaceActiveProgram.
  ///
  /// In en, this message translates to:
  /// **'Replace active program?'**
  String get replaceActiveProgram;

  /// No description provided for @replaceProgramBody.
  ///
  /// In en, this message translates to:
  /// **'The previous program will be stopped.'**
  String get replaceProgramBody;

  /// No description provided for @waterSettings.
  ///
  /// In en, this message translates to:
  /// **'Water Settings'**
  String get waterSettings;

  /// No description provided for @waterGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached! Great job!'**
  String get waterGoalReached;

  /// No description provided for @remindersStart.
  ///
  /// In en, this message translates to:
  /// **'Reminders start'**
  String get remindersStart;

  /// No description provided for @remindersFinished.
  ///
  /// In en, this message translates to:
  /// **'Reminders finished for today'**
  String get remindersFinished;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon...'**
  String get comingSoon;

  /// No description provided for @glassSize.
  ///
  /// In en, this message translates to:
  /// **'Glass size'**
  String get glassSize;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @scheduledDoses.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Doses'**
  String get scheduledDoses;

  /// No description provided for @takenDoses.
  ///
  /// In en, this message translates to:
  /// **'Taken Doses'**
  String get takenDoses;

  /// No description provided for @exportedFrom.
  ///
  /// In en, this message translates to:
  /// **'Exported from Rutin'**
  String get exportedFrom;

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String failedToSave(Object error);

  /// No description provided for @failedToScheduleAlarm.
  ///
  /// In en, this message translates to:
  /// **'Failed to schedule alarm: {error}'**
  String failedToScheduleAlarm(Object error);

  /// No description provided for @exportBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportBackupFailed(Object error);

  /// No description provided for @deleteHabitTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete habit?'**
  String get deleteHabitTitle;

  /// No description provided for @deleteHabitBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will be permanently deleted.'**
  String deleteHabitBody(Object name);

  /// No description provided for @deleteRoutineTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteRoutineTitle(Object name);

  /// No description provided for @deleteRoutineWithHabitsBody.
  ///
  /// In en, this message translates to:
  /// **'This routine has {count} habits. What should happen to them?'**
  String deleteRoutineWithHabitsBody(int count);

  /// No description provided for @habitsCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} habits completed'**
  String habitsCompletedCount(int completed, int total);

  /// No description provided for @habitTurnedIntoMedal.
  ///
  /// In en, this message translates to:
  /// **'{emoji} {name} turned into a medal!'**
  String habitTurnedIntoMedal(Object emoji, Object name);

  /// No description provided for @tookMedicine.
  ///
  /// In en, this message translates to:
  /// **'Took {name}'**
  String tookMedicine(Object name);

  /// No description provided for @drankWaterMl.
  ///
  /// In en, this message translates to:
  /// **'Drank {ml} ml of water'**
  String drankWaterMl(int ml);

  /// No description provided for @ageYearsOld.
  ///
  /// In en, this message translates to:
  /// **'{age} years old'**
  String ageYearsOld(int age);

  /// No description provided for @medicineDueNow.
  ///
  /// In en, this message translates to:
  /// **'{count} due now'**
  String medicineDueNow(int count);

  /// No description provided for @medicineMissedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} missed'**
  String medicineMissedCount(int count);

  /// No description provided for @medicineDoneProgress.
  ///
  /// In en, this message translates to:
  /// **'{taken}/{total} done'**
  String medicineDoneProgress(int taken, int total);

  /// No description provided for @noMedicineTodayHint.
  ///
  /// In en, this message translates to:
  /// **'Add a medicine schedule with + so today\'s doses appear here.'**
  String get noMedicineTodayHint;

  /// No description provided for @streakDay.
  ///
  /// In en, this message translates to:
  /// **'Day {streak}'**
  String streakDay(int streak);

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} days remaining'**
  String daysRemaining(int count);

  /// No description provided for @adherenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Adherence: {pct}%'**
  String adherenceLabel(int pct);

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days: {taken}/{total} doses'**
  String last7Days(int taken, int total);

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'{count} months'**
  String months(Object count);

  /// No description provided for @gameRoundInfo.
  ///
  /// In en, this message translates to:
  /// **'Round {round}/3  •  {colors} colors'**
  String gameRoundInfo(int round, int colors);

  /// No description provided for @reminderInMinutes.
  ///
  /// In en, this message translates to:
  /// **'Reminder in {minutes} min'**
  String reminderInMinutes(int minutes);

  /// No description provided for @reminderInHours.
  ///
  /// In en, this message translates to:
  /// **'Reminder in {hours}h'**
  String reminderInHours(int hours);

  /// No description provided for @reminderInHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'Reminder in {hours}h {minutes}m'**
  String reminderInHoursMinutes(int hours, int minutes);

  /// No description provided for @waterGlassesSummary.
  ///
  /// In en, this message translates to:
  /// **'{glasses} glasses/day - reminder every {minutes} min'**
  String waterGlassesSummary(int glasses, int minutes);

  /// No description provided for @ofGoalGlasses.
  ///
  /// In en, this message translates to:
  /// **'of {goal} glasses'**
  String ofGoalGlasses(int goal);

  /// No description provided for @medalWaterTitle.
  ///
  /// In en, this message translates to:
  /// **'Water Intake'**
  String get medalWaterTitle;

  /// No description provided for @medalMedicineTitle.
  ///
  /// In en, this message translates to:
  /// **'Medicine Streak'**
  String get medalMedicineTitle;

  /// No description provided for @medalHabitTitle.
  ///
  /// In en, this message translates to:
  /// **'Habit Streak'**
  String get medalHabitTitle;

  /// No description provided for @medalPersonalBest.
  ///
  /// In en, this message translates to:
  /// **'Personal best'**
  String get medalPersonalBest;

  /// No description provided for @medalStartStreak.
  ///
  /// In en, this message translates to:
  /// **'Start your streak'**
  String get medalStartStreak;

  /// No description provided for @medalNoBestYet.
  ///
  /// In en, this message translates to:
  /// **'No record yet'**
  String get medalNoBestYet;

  /// No description provided for @medalWaterDesc.
  ///
  /// In en, this message translates to:
  /// **'Consecutive days hitting your daily water goal.'**
  String get medalWaterDesc;

  /// No description provided for @medalMedicineDesc.
  ///
  /// In en, this message translates to:
  /// **'Based on your best medicine adherence streak.'**
  String get medalMedicineDesc;

  /// No description provided for @medalHabitDesc.
  ///
  /// In en, this message translates to:
  /// **'Based on your best habit completion streak.'**
  String get medalHabitDesc;

  /// No description provided for @medalCurrentCount.
  ///
  /// In en, this message translates to:
  /// **'↑ {count} days'**
  String medalCurrentCount(int count);

  /// No description provided for @medalBestAchieved.
  ///
  /// In en, this message translates to:
  /// **'Best: {date}'**
  String medalBestAchieved(Object date);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
