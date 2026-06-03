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
