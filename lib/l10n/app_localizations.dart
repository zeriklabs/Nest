import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'QUICK ACTIONS'**
  String get quickActions;

  /// No description provided for @skipClass.
  ///
  /// In en, this message translates to:
  /// **'Skip Class'**
  String get skipClass;

  /// No description provided for @noActiveClass.
  ///
  /// In en, this message translates to:
  /// **'No active class'**
  String get noActiveClass;

  /// No description provided for @noActiveClassToSkip.
  ///
  /// In en, this message translates to:
  /// **'No active class to skip'**
  String get noActiveClassToSkip;

  /// No description provided for @startPomodoro.
  ///
  /// In en, this message translates to:
  /// **'Start Pomodoro'**
  String get startPomodoro;

  /// No description provided for @newGoal.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get newGoal;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'MY PROFILE'**
  String get myProfile;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get preferences;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @calendarSync.
  ///
  /// In en, this message translates to:
  /// **'Calendar Synchronization'**
  String get calendarSync;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appData.
  ///
  /// In en, this message translates to:
  /// **'App Data'**
  String get appData;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT'**
  String get support;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @aboutNest.
  ///
  /// In en, this message translates to:
  /// **'About Nest'**
  String get aboutNest;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @activated.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get activated;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @themes.
  ///
  /// In en, this message translates to:
  /// **'THEMES'**
  String get themes;

  /// No description provided for @material3.
  ///
  /// In en, this message translates to:
  /// **'ANDROID MATERIAL 3'**
  String get material3;

  /// No description provided for @homeLayout.
  ///
  /// In en, this message translates to:
  /// **'Home Layout'**
  String get homeLayout;

  /// No description provided for @originalLayout.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get originalLayout;

  /// No description provided for @simplifiedLayout.
  ///
  /// In en, this message translates to:
  /// **'Simplified'**
  String get simplifiedLayout;

  /// No description provided for @layoutDescOriginal.
  ///
  /// In en, this message translates to:
  /// **'Dynamic header with greeting based on the time of day.'**
  String get layoutDescOriginal;

  /// No description provided for @layoutDescSimplified.
  ///
  /// In en, this message translates to:
  /// **'Fixed header and \'Now Brief\' style design for better clarity.'**
  String get layoutDescSimplified;

  /// No description provided for @scheduleStyle.
  ///
  /// In en, this message translates to:
  /// **'Schedule Style'**
  String get scheduleStyle;

  /// No description provided for @gridStyle.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get gridStyle;

  /// No description provided for @timelineStyle.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get timelineStyle;

  /// No description provided for @changeView.
  ///
  /// In en, this message translates to:
  /// **'Change view'**
  String get changeView;

  /// No description provided for @dynamicColor.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Color'**
  String get dynamicColor;

  /// No description provided for @dynamicColorDesc.
  ///
  /// In en, this message translates to:
  /// **'Use system accent colors'**
  String get dynamicColorDesc;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColor;

  /// No description provided for @accentColorDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose a custom highlight color'**
  String get accentColorDesc;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'PREVIEW'**
  String get preview;

  /// No description provided for @primaryButton.
  ///
  /// In en, this message translates to:
  /// **'Primary Button'**
  String get primaryButton;

  /// No description provided for @nestSlogan.
  ///
  /// In en, this message translates to:
  /// **'Your study, in sync.'**
  String get nestSlogan;

  /// No description provided for @loginToAccount.
  ///
  /// In en, this message translates to:
  /// **'Login to my account'**
  String get loginToAccount;

  /// No description provided for @loginAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Login as guest'**
  String get loginAsGuest;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @loginToNest.
  ///
  /// In en, this message translates to:
  /// **'Login to Nest'**
  String get loginToNest;

  /// No description provided for @noAccountRegister.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get noAccountRegister;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get sendResetLink;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent to your email'**
  String get resetEmailSent;

  /// No description provided for @enterEmailToReset.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a reset link'**
  String get enterEmailToReset;

  /// No description provided for @tellUsYourName.
  ///
  /// In en, this message translates to:
  /// **'Tell us your name'**
  String get tellUsYourName;

  /// No description provided for @startNow.
  ///
  /// In en, this message translates to:
  /// **'Start now'**
  String get startNow;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @recentNotes.
  ///
  /// In en, this message translates to:
  /// **'Recent notes'**
  String get recentNotes;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @everythingUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Everything up to date ✨'**
  String get everythingUpToDate;

  /// No description provided for @noNotesYet.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have notes yet'**
  String get noNotesYet;

  /// No description provided for @currentClass.
  ///
  /// In en, this message translates to:
  /// **'Current class'**
  String get currentClass;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @nestStudio.
  ///
  /// In en, this message translates to:
  /// **'Nest Studio'**
  String get nestStudio;

  /// No description provided for @scheduleManagement.
  ///
  /// In en, this message translates to:
  /// **'Schedule Management'**
  String get scheduleManagement;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @focus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focus;

  /// No description provided for @noGroupsYet.
  ///
  /// In en, this message translates to:
  /// **'You don\'t belong to any group yet.'**
  String get noGroupsYet;

  /// No description provided for @noActiveProjects.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have active projects.'**
  String get noActiveProjects;

  /// No description provided for @noFocusSessions.
  ///
  /// In en, this message translates to:
  /// **'There are no active focus sessions.'**
  String get noFocusSessions;

  /// No description provided for @almostReady.
  ///
  /// In en, this message translates to:
  /// **'Almost ready, {name}!'**
  String almostReady(Object name);

  /// No description provided for @missingDetails.
  ///
  /// In en, this message translates to:
  /// **'Just a couple of details left to complete your profile.'**
  String get missingDetails;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Alias'**
  String get username;

  /// No description provided for @dob.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dob;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @morningGreetings.
  ///
  /// In en, this message translates to:
  /// **'Good morning!|New day, [name]!|What\'s the plan?|Have a great day.|Go for it!|Ready for today?|Hello! Rested?|Good day to start.|Coffee and go!'**
  String get morningGreetings;

  /// No description provided for @afternoonGreetings.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon!|How\'s it going?|Coffee and go.|What\'s next today?|How\'s the afternoon?|Productive afternoon?|Keep it up!|Halfway there!'**
  String get afternoonGreetings;

  /// No description provided for @eveningGreetings.
  ///
  /// In en, this message translates to:
  /// **'Good evening!|Finishing the day?|Plan for tomorrow?|Rest well, [name].|Tomorrow is big!|Time to disconnect.|All done today?|Good night!|Day completed.'**
  String get eveningGreetings;

  /// No description provided for @noTasksGreetings.
  ///
  /// In en, this message translates to:
  /// **'Clear day. Enjoy!|Nothing pending. Relax!|Everything up to date!'**
  String get noTasksGreetings;

  /// No description provided for @busyDayGreetings.
  ///
  /// In en, this message translates to:
  /// **'Busy day, ready?|Challenges today.|Go for it, [name]!|Productive day ahead.|Full agenda, stay focused.'**
  String get busyDayGreetings;

  /// No description provided for @examGreetings.
  ///
  /// In en, this message translates to:
  /// **'Ready for the exam, [name]?|Good luck on your exam!|Coffee before the exam?'**
  String get examGreetings;

  /// No description provided for @postExamGreetings.
  ///
  /// In en, this message translates to:
  /// **'Exam done! How was it?|How was the exam?|How did it go, [name]?|Exam over! Take a breath'**
  String get postExamGreetings;

  /// No description provided for @birthdayGreetings.
  ///
  /// In en, this message translates to:
  /// **'Happy birthday, [name]!|One more year, [name]!|🎊🎂🥳|Today is your day, [name]!'**
  String get birthdayGreetings;

  /// No description provided for @weWantToKnowYou.
  ///
  /// In en, this message translates to:
  /// **'We want to\nknow you!'**
  String get weWantToKnowYou;

  /// No description provided for @tellUsWhoYouAre.
  ///
  /// In en, this message translates to:
  /// **'Tell us who you are to start personalizing your experience in Nest.'**
  String get tellUsWhoYouAre;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @writeYourName.
  ///
  /// In en, this message translates to:
  /// **'Write your name'**
  String get writeYourName;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @accountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account\nsecurity'**
  String get accountSecurity;

  /// No description provided for @securityDesc.
  ///
  /// In en, this message translates to:
  /// **'Use a valid email and a secure password to protect your data.'**
  String get securityDesc;

  /// No description provided for @finishRegistration.
  ///
  /// In en, this message translates to:
  /// **'Finish registration'**
  String get finishRegistration;

  /// No description provided for @termsAgreed.
  ///
  /// In en, this message translates to:
  /// **'By registering, you agree to our Terms and Conditions.'**
  String get termsAgreed;

  /// No description provided for @myNotes.
  ///
  /// In en, this message translates to:
  /// **'My Notes'**
  String get myNotes;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @quick.
  ///
  /// In en, this message translates to:
  /// **'Quick'**
  String get quick;

  /// No description provided for @notebooks.
  ///
  /// In en, this message translates to:
  /// **'Notebooks'**
  String get notebooks;

  /// No description provided for @noQuickNotes.
  ///
  /// In en, this message translates to:
  /// **'No quick notes'**
  String get noQuickNotes;

  /// No description provided for @noNotebooksYet.
  ///
  /// In en, this message translates to:
  /// **'No notebooks yet'**
  String get noNotebooksYet;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get deleteNote;

  /// No description provided for @deleteNoteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this note?'**
  String get deleteNoteConfirm;

  /// No description provided for @deleteNotebook.
  ///
  /// In en, this message translates to:
  /// **'Delete notebook'**
  String get deleteNotebook;

  /// No description provided for @deleteNotebookConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" and all its notes?'**
  String deleteNotebookConfirm(Object name);

  /// No description provided for @deleteReminder.
  ///
  /// In en, this message translates to:
  /// **'Delete reminder'**
  String get deleteReminder;

  /// No description provided for @deleteReminderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this reminder?'**
  String get deleteReminderConfirm;

  /// No description provided for @deleteReminderConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteReminderConfirmDesc;

  /// No description provided for @attachmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'ATTACHMENTS'**
  String get attachmentsLabel;

  /// No description provided for @sharedWithLabel.
  ///
  /// In en, this message translates to:
  /// **'SHARED WITH'**
  String get sharedWithLabel;

  /// No description provided for @markAsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark as completed'**
  String get markAsCompleted;

  /// No description provided for @atTime.
  ///
  /// In en, this message translates to:
  /// **'at'**
  String get atTime;

  /// No description provided for @allDayLabel.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get allDayLabel;

  /// No description provided for @dateTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Date and Time'**
  String get dateTimeLabel;

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

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAll;

  /// No description provided for @myReminders.
  ///
  /// In en, this message translates to:
  /// **'My Reminders'**
  String get myReminders;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @viewAsList.
  ///
  /// In en, this message translates to:
  /// **'View as list'**
  String get viewAsList;

  /// No description provided for @viewAsCalendar.
  ///
  /// In en, this message translates to:
  /// **'View as calendar'**
  String get viewAsCalendar;

  /// No description provided for @viewAsBoard.
  ///
  /// In en, this message translates to:
  /// **'View as timeline'**
  String get viewAsBoard;

  /// No description provided for @board.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get board;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @noDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get noDate;

  /// No description provided for @programs.
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get programs;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @exams.
  ///
  /// In en, this message translates to:
  /// **'Exams'**
  String get exams;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @task.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get task;

  /// No description provided for @project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// No description provided for @exam.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get exam;

  /// No description provided for @event.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get event;

  /// No description provided for @orderBy.
  ///
  /// In en, this message translates to:
  /// **'Order by'**
  String get orderBy;

  /// No description provided for @defaultOrder.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultOrder;

  /// No description provided for @byDate.
  ///
  /// In en, this message translates to:
  /// **'By date'**
  String get byDate;

  /// No description provided for @alphabetically.
  ///
  /// In en, this message translates to:
  /// **'Alphabetically'**
  String get alphabetically;

  /// No description provided for @dayTasks.
  ///
  /// In en, this message translates to:
  /// **'Daily Tasks'**
  String get dayTasks;

  /// No description provided for @freeDay.
  ///
  /// In en, this message translates to:
  /// **'Free day!'**
  String get freeDay;

  /// No description provided for @noScheduledTasks.
  ///
  /// In en, this message translates to:
  /// **'No scheduled tasks'**
  String get noScheduledTasks;

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get addReminder;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @monthlyPerformance.
  ///
  /// In en, this message translates to:
  /// **'Monthly performance'**
  String get monthlyPerformance;

  /// No description provided for @performanceDesc.
  ///
  /// In en, this message translates to:
  /// **'You have completed {percentage}% of your tasks for {month}'**
  String performanceDesc(Object month, Object percentage);

  /// No description provided for @noRemindersHere.
  ///
  /// In en, this message translates to:
  /// **'No reminders here'**
  String get noRemindersHere;

  /// No description provided for @weeklySchedule.
  ///
  /// In en, this message translates to:
  /// **'Weekly Schedule'**
  String get weeklySchedule;

  /// No description provided for @addSubjectBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Subject'**
  String get addSubjectBtn;

  /// No description provided for @exportSchedule.
  ///
  /// In en, this message translates to:
  /// **'Export Schedule'**
  String get exportSchedule;

  /// No description provided for @exportScheduleDesc.
  ///
  /// In en, this message translates to:
  /// **'A .json file will be generated with your schedule that you can share or save.'**
  String get exportScheduleDesc;

  /// No description provided for @shareFile.
  ///
  /// In en, this message translates to:
  /// **'Share File'**
  String get shareFile;

  /// No description provided for @shareFileDesc.
  ///
  /// In en, this message translates to:
  /// **'Here is my Nest schedule'**
  String get shareFileDesc;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @fileSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'File saved successfully'**
  String get fileSavedSuccess;

  /// No description provided for @importSchedule.
  ///
  /// In en, this message translates to:
  /// **'Import Schedule'**
  String get importSchedule;

  /// No description provided for @selectJsonFile.
  ///
  /// In en, this message translates to:
  /// **'Select .json file'**
  String get selectJsonFile;

  /// No description provided for @orPasteCode.
  ///
  /// In en, this message translates to:
  /// **'OR PASTE THE CODE'**
  String get orPasteCode;

  /// No description provided for @importLabel.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importLabel;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Schedule imported successfully'**
  String get importSuccess;

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'Error importing: Invalid JSON format'**
  String get importError;

  /// No description provided for @importFileSuccess.
  ///
  /// In en, this message translates to:
  /// **'Schedule successfully imported from file'**
  String get importFileSuccess;

  /// No description provided for @importFileError.
  ///
  /// In en, this message translates to:
  /// **'Error importing file: Invalid format'**
  String get importFileError;

  /// No description provided for @manageSchedule.
  ///
  /// In en, this message translates to:
  /// **'Manage Schedule'**
  String get manageSchedule;

  /// No description provided for @deleteSchedule.
  ///
  /// In en, this message translates to:
  /// **'Delete schedule'**
  String get deleteSchedule;

  /// No description provided for @deleteAllScheduleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all schedule?'**
  String get deleteAllScheduleConfirm;

  /// No description provided for @deleteAllScheduleDesc.
  ///
  /// In en, this message translates to:
  /// **'This action will permanently delete all subjects and their schedules. It cannot be undone.'**
  String get deleteAllScheduleDesc;

  /// No description provided for @lockScheduleAutoScroll.
  ///
  /// In en, this message translates to:
  /// **'Lock auto-scroll'**
  String get lockScheduleAutoScroll;

  /// No description provided for @unlockScheduleAutoScroll.
  ///
  /// In en, this message translates to:
  /// **'Unlock auto-scroll'**
  String get unlockScheduleAutoScroll;

  /// No description provided for @exportAndShare.
  ///
  /// In en, this message translates to:
  /// **'Export and Share'**
  String get exportAndShare;

  /// No description provided for @editSubject.
  ///
  /// In en, this message translates to:
  /// **'Edit Subject'**
  String get editSubject;

  /// No description provided for @newSubject.
  ///
  /// In en, this message translates to:
  /// **'New Subject'**
  String get newSubject;

  /// No description provided for @generalInfo.
  ///
  /// In en, this message translates to:
  /// **'GENERAL INFORMATION'**
  String get generalInfo;

  /// No description provided for @subjectNameHint.
  ///
  /// In en, this message translates to:
  /// **'Subject name'**
  String get subjectNameHint;

  /// No description provided for @roomLabel.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get roomLabel;

  /// No description provided for @teacherLabel.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacherLabel;

  /// No description provided for @groupNoun.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get groupNoun;

  /// No description provided for @buildingLabel.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get buildingLabel;

  /// No description provided for @buildingHint.
  ///
  /// In en, this message translates to:
  /// **'Ex. Building A'**
  String get buildingHint;

  /// No description provided for @distinctiveColor.
  ///
  /// In en, this message translates to:
  /// **'DISTINCTIVE COLOR'**
  String get distinctiveColor;

  /// No description provided for @schedulesLabel.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULES'**
  String get schedulesLabel;

  /// No description provided for @addScheduleBtn.
  ///
  /// In en, this message translates to:
  /// **'Add schedule'**
  String get addScheduleBtn;

  /// No description provided for @updateLabel.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateLabel;

  /// No description provided for @saveSubjectBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Subject'**
  String get saveSubjectBtn;

  /// No description provided for @colorSelector.
  ///
  /// In en, this message translates to:
  /// **'Color Selector'**
  String get colorSelector;

  /// No description provided for @confirmColor.
  ///
  /// In en, this message translates to:
  /// **'Confirm Color'**
  String get confirmColor;

  /// No description provided for @deleteSubjectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this subject?'**
  String get deleteSubjectConfirm;

  /// No description provided for @whatToCreate.
  ///
  /// In en, this message translates to:
  /// **'What do you want to create?'**
  String get whatToCreate;

  /// No description provided for @newGroupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Collaborate with a full team'**
  String get newGroupSubtitle;

  /// No description provided for @newProjectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Organize your tasks and goals'**
  String get newProjectSubtitle;

  /// No description provided for @focusSessionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Group Pomodoro with your team'**
  String get focusSessionSubtitle;

  /// No description provided for @focusSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Focus Session'**
  String get focusSessionLabel;

  /// No description provided for @nestStudioForTeams.
  ///
  /// In en, this message translates to:
  /// **'Nest Studio is for teams'**
  String get nestStudioForTeams;

  /// No description provided for @nestStudioGuestDesc.
  ///
  /// In en, this message translates to:
  /// **'To create groups, collaborate on projects and join group study rooms, you need a real account.'**
  String get nestStudioGuestDesc;

  /// No description provided for @registerAccount.
  ///
  /// In en, this message translates to:
  /// **'Register Account'**
  String get registerAccount;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @scheduledForStatus.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for {time}'**
  String scheduledForStatus(Object time);

  /// No description provided for @peopleFocusing.
  ///
  /// In en, this message translates to:
  /// **'{count} people focusing'**
  String peopleFocusing(Object count);

  /// No description provided for @noActiveSession.
  ///
  /// In en, this message translates to:
  /// **'No active session'**
  String get noActiveSession;

  /// No description provided for @membersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String membersCount(Object count);

  /// No description provided for @inviteCodeShort.
  ///
  /// In en, this message translates to:
  /// **'Code: {code}'**
  String inviteCodeShort(Object code);

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Be the first!'**
  String get noCommentsYet;

  /// No description provided for @writeCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get writeCommentHint;

  /// No description provided for @initialPhase.
  ///
  /// In en, this message translates to:
  /// **'Initial Phase'**
  String get initialPhase;

  /// No description provided for @finishPhase.
  ///
  /// In en, this message translates to:
  /// **'Finish Current Phase'**
  String get finishPhase;

  /// No description provided for @finishPhaseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to finish \"{title}\"?'**
  String finishPhaseConfirm(Object title);

  /// No description provided for @nextPhaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Next phase name (optional)'**
  String get nextPhaseLabel;

  /// No description provided for @nextPhaseHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Development, Testing...'**
  String get nextPhaseHint;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @individual.
  ///
  /// In en, this message translates to:
  /// **'Individual'**
  String get individual;

  /// No description provided for @groupLabelShort.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get groupLabelShort;

  /// No description provided for @completedPercentage.
  ///
  /// In en, this message translates to:
  /// **'{percentage}% completed'**
  String completedPercentage(Object percentage);

  /// No description provided for @addTaskHint.
  ///
  /// In en, this message translates to:
  /// **'Add new task...'**
  String get addTaskHint;

  /// No description provided for @newPost.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get newPost;

  /// No description provided for @shareNote.
  ///
  /// In en, this message translates to:
  /// **'Share note'**
  String get shareNote;

  /// No description provided for @shareReminder.
  ///
  /// In en, this message translates to:
  /// **'Share reminder'**
  String get shareReminder;

  /// No description provided for @newPoll.
  ///
  /// In en, this message translates to:
  /// **'New poll'**
  String get newPoll;

  /// No description provided for @insertLink.
  ///
  /// In en, this message translates to:
  /// **'Insert Link'**
  String get insertLink;

  /// No description provided for @textToShow.
  ///
  /// In en, this message translates to:
  /// **'Text to show'**
  String get textToShow;

  /// No description provided for @urlLabel.
  ///
  /// In en, this message translates to:
  /// **'URL (https://...)'**
  String get urlLabel;

  /// No description provided for @insertBtn.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get insertBtn;

  /// No description provided for @errorOpeningUrl.
  ///
  /// In en, this message translates to:
  /// **'Error opening: '**
  String get errorOpeningUrl;

  /// No description provided for @pageTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Page title'**
  String get pageTitleHint;

  /// No description provided for @noTitle.
  ///
  /// In en, this message translates to:
  /// **'No title'**
  String get noTitle;

  /// No description provided for @noContent.
  ///
  /// In en, this message translates to:
  /// **'No content'**
  String get noContent;

  /// No description provided for @quickNote.
  ///
  /// In en, this message translates to:
  /// **'Quick note'**
  String get quickNote;

  /// No description provided for @writeSomethingAmazing.
  ///
  /// In en, this message translates to:
  /// **'Write something amazing...'**
  String get writeSomethingAmazing;

  /// No description provided for @modifiedAt.
  ///
  /// In en, this message translates to:
  /// **'Modified: '**
  String get modifiedAt;

  /// No description provided for @bullets.
  ///
  /// In en, this message translates to:
  /// **'Bullets'**
  String get bullets;

  /// No description provided for @numbering.
  ///
  /// In en, this message translates to:
  /// **'Numbering'**
  String get numbering;

  /// No description provided for @checklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get checklist;

  /// No description provided for @alignLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get alignLeft;

  /// No description provided for @alignCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get alignCenter;

  /// No description provided for @alignRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get alignRight;

  /// No description provided for @justify.
  ///
  /// In en, this message translates to:
  /// **'Justify'**
  String get justify;

  /// No description provided for @imageLabel.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get imageLabel;

  /// No description provided for @audioLabel.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audioLabel;

  /// No description provided for @h1.
  ///
  /// In en, this message translates to:
  /// **'Heading 1'**
  String get h1;

  /// No description provided for @h2.
  ///
  /// In en, this message translates to:
  /// **'Heading 2'**
  String get h2;

  /// No description provided for @h3.
  ///
  /// In en, this message translates to:
  /// **'Heading 3'**
  String get h3;

  /// No description provided for @normalText.
  ///
  /// In en, this message translates to:
  /// **'Normal text'**
  String get normalText;

  /// No description provided for @datePattern.
  ///
  /// In en, this message translates to:
  /// **'MMMM d'**
  String get datePattern;

  /// No description provided for @fullDatePattern.
  ///
  /// In en, this message translates to:
  /// **'EEEE, MMMM d'**
  String get fullDatePattern;

  /// No description provided for @defaultMode.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT MODE'**
  String get defaultMode;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightMode;

  /// No description provided for @yourAgendaEverywhere.
  ///
  /// In en, this message translates to:
  /// **'Your agenda everywhere'**
  String get yourAgendaEverywhere;

  /// No description provided for @syncDescription.
  ///
  /// In en, this message translates to:
  /// **'Sync your Nest events, reminders, and tasks directly with your device\'s calendar so you don\'t miss a thing.'**
  String get syncDescription;

  /// No description provided for @activeSync.
  ///
  /// In en, this message translates to:
  /// **'Active Sync'**
  String get activeSync;

  /// No description provided for @enableSync.
  ///
  /// In en, this message translates to:
  /// **'Enable Sync'**
  String get enableSync;

  /// No description provided for @alreadyConnected.
  ///
  /// In en, this message translates to:
  /// **'You can now connect services!'**
  String get alreadyConnected;

  /// No description provided for @unlockFunctions.
  ///
  /// In en, this message translates to:
  /// **'Click to unlock functions'**
  String get unlockFunctions;

  /// No description provided for @availableServices.
  ///
  /// In en, this message translates to:
  /// **'Available services'**
  String get availableServices;

  /// No description provided for @activeBenefits.
  ///
  /// In en, this message translates to:
  /// **'Your active benefits'**
  String get activeBenefits;

  /// No description provided for @whyActivate.
  ///
  /// In en, this message translates to:
  /// **'Why activate it?'**
  String get whyActivate;

  /// No description provided for @smartAlerts.
  ///
  /// In en, this message translates to:
  /// **'Integrated Alerts'**
  String get smartAlerts;

  /// No description provided for @smartAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Your Nest tasks and reminders will automatically appear in your chosen device calendar.'**
  String get smartAlertsDesc;

  /// No description provided for @noConflicts.
  ///
  /// In en, this message translates to:
  /// **'Centralized Management'**
  String get noConflicts;

  /// No description provided for @noConflictsDesc.
  ///
  /// In en, this message translates to:
  /// **'Keep your academic, work, and personal schedules organized in one place without conflicts.'**
  String get noConflictsDesc;

  /// No description provided for @multiplatform.
  ///
  /// In en, this message translates to:
  /// **'Widgets & Device Sync'**
  String get multiplatform;

  /// No description provided for @multiplatformDesc.
  ///
  /// In en, this message translates to:
  /// **'View your Nest events directly from your home screen widgets or smartwatch.'**
  String get multiplatformDesc;

  /// No description provided for @howCanWeHelp.
  ///
  /// In en, this message translates to:
  /// **'How can we help you?'**
  String get howCanWeHelp;

  /// No description provided for @popularTopics.
  ///
  /// In en, this message translates to:
  /// **'Popular topics'**
  String get popularTopics;

  /// No description provided for @whatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new in this version'**
  String get whatsNew;

  /// No description provided for @whatsNewDesc.
  ///
  /// In en, this message translates to:
  /// **'Discover what\'s new in version 6.0.0.'**
  String get whatsNewDesc;

  /// No description provided for @syncProblems.
  ///
  /// In en, this message translates to:
  /// **'Sync problems'**
  String get syncProblems;

  /// No description provided for @syncProblemsDesc.
  ///
  /// In en, this message translates to:
  /// **'How to fix errors with Google Calendar.'**
  String get syncProblemsDesc;

  /// No description provided for @securityPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Security and privacy'**
  String get securityPrivacy;

  /// No description provided for @securityPrivacyDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your data and account permissions.'**
  String get securityPrivacyDesc;

  /// No description provided for @directContact.
  ///
  /// In en, this message translates to:
  /// **'Direct contact'**
  String get directContact;

  /// No description provided for @sendEmail.
  ///
  /// In en, this message translates to:
  /// **'Send an email'**
  String get sendEmail;

  /// No description provided for @supportChat.
  ///
  /// In en, this message translates to:
  /// **'Support chat'**
  String get supportChat;

  /// No description provided for @supportChatDesc.
  ///
  /// In en, this message translates to:
  /// **'Talk to our team in real time.'**
  String get supportChatDesc;

  /// No description provided for @weAreHereToHelp.
  ///
  /// In en, this message translates to:
  /// **'We are here to help 24/7'**
  String get weAreHereToHelp;

  /// No description provided for @termsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and conditions'**
  String get termsConditions;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @allowNotifications.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get allowNotifications;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @remindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts for your notes and pending tasks'**
  String get remindersSubtitle;

  /// No description provided for @groupActivity.
  ///
  /// In en, this message translates to:
  /// **'Group activity'**
  String get groupActivity;

  /// No description provided for @groupActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Messages and changes in shared groups'**
  String get groupActivitySubtitle;

  /// No description provided for @calendarEvents.
  ///
  /// In en, this message translates to:
  /// **'Calendar events'**
  String get calendarEvents;

  /// No description provided for @calendarEventsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts for your schedule and agenda'**
  String get calendarEventsSubtitle;

  /// No description provided for @updates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updates;

  /// No description provided for @updatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nest news and updates'**
  String get updatesSubtitle;

  /// No description provided for @systemConfiguration.
  ///
  /// In en, this message translates to:
  /// **'System configuration'**
  String get systemConfiguration;

  /// No description provided for @systemConfigurationDesc.
  ///
  /// In en, this message translates to:
  /// **'If you are not receiving notifications, make sure Nest has the necessary permissions in your phone settings.'**
  String get systemConfigurationDesc;

  /// No description provided for @openSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'Open system settings'**
  String get openSystemSettings;

  /// No description provided for @appDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your data and backups locally on your device.'**
  String get appDataDesc;

  /// No description provided for @localBackup.
  ///
  /// In en, this message translates to:
  /// **'Local Backup'**
  String get localBackup;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get createBackup;

  /// No description provided for @createBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save a copy of your notes and reminders to internal storage.'**
  String get createBackupSubtitle;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get restoreBackup;

  /// No description provided for @restoreBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recover your data from a previous backup file.'**
  String get restoreBackupSubtitle;

  /// No description provided for @cloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get cloudSync;

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: Synced'**
  String get syncStatus;

  /// No description provided for @syncStatusDesc.
  ///
  /// In en, this message translates to:
  /// **'Your data is protected in your Nest account.'**
  String get syncStatusDesc;

  /// No description provided for @syncInfo.
  ///
  /// In en, this message translates to:
  /// **'As long as you stay logged in, all your changes will automatically sync with our servers whenever you have an internet connection.'**
  String get syncInfo;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @linkedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Linked Accounts'**
  String get linkedAccounts;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccount;

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Your security comes first'**
  String get securityTitle;

  /// No description provided for @securitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage how you protect your account and application access.'**
  String get securitySubtitle;

  /// No description provided for @access.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get access;

  /// No description provided for @passwordDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your account security'**
  String get passwordDesc;

  /// No description provided for @biometrics.
  ///
  /// In en, this message translates to:
  /// **'Biometrics'**
  String get biometrics;

  /// No description provided for @useBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics'**
  String get useBiometrics;

  /// No description provided for @useBiometricsDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlock the app with FaceID or Fingerprint'**
  String get useBiometricsDesc;

  /// No description provided for @requireOnStartup.
  ///
  /// In en, this message translates to:
  /// **'Request on startup'**
  String get requireOnStartup;

  /// No description provided for @requireOnStartupDesc.
  ///
  /// In en, this message translates to:
  /// **'Ask for biometrics every time you open Nest'**
  String get requireOnStartupDesc;

  /// No description provided for @biometricPrivacyInfo.
  ///
  /// In en, this message translates to:
  /// **'Nest never stores your biometric data. The entire process is managed securely through your device.'**
  String get biometricPrivacyInfo;

  /// No description provided for @deviceLock.
  ///
  /// In en, this message translates to:
  /// **'Device Lock'**
  String get deviceLock;

  /// No description provided for @deviceLockDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlock the app with your PIN, pattern or password'**
  String get deviceLockDesc;

  /// No description provided for @material3Error.
  ///
  /// In en, this message translates to:
  /// **'Requires Android 12 or higher'**
  String get material3Error;

  /// No description provided for @editReminder.
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get editReminder;

  /// No description provided for @newReminder.
  ///
  /// In en, this message translates to:
  /// **'New reminder'**
  String get newReminder;

  /// No description provided for @enterTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder title'**
  String get enterTitle;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @place.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get place;

  /// No description provided for @locationHint.
  ///
  /// In en, this message translates to:
  /// **'Ex. Room 100'**
  String get locationHint;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @linkSubject.
  ///
  /// In en, this message translates to:
  /// **'Link to subject (Tag)'**
  String get linkSubject;

  /// No description provided for @noSubjectsYet.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any subjects added yet.'**
  String get noSubjectsYet;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @earlyAlerts.
  ///
  /// In en, this message translates to:
  /// **'Early alerts'**
  String get earlyAlerts;

  /// No description provided for @addAlert.
  ///
  /// In en, this message translates to:
  /// **'Add alert'**
  String get addAlert;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @writeNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Write an additional note...'**
  String get writeNoteHint;

  /// No description provided for @shareWithOthers.
  ///
  /// In en, this message translates to:
  /// **'Share with others'**
  String get shareWithOthers;

  /// No description provided for @searchUsersHint.
  ///
  /// In en, this message translates to:
  /// **'Search users or contacts...'**
  String get searchUsersHint;

  /// No description provided for @markAsUrgent.
  ///
  /// In en, this message translates to:
  /// **'Mark as urgent'**
  String get markAsUrgent;

  /// No description provided for @allDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get allDay;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @setupRepeat.
  ///
  /// In en, this message translates to:
  /// **'Setup Repeat'**
  String get setupRepeat;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @weeks.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get weeks;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get months;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get years;

  /// No description provided for @scheduleType.
  ///
  /// In en, this message translates to:
  /// **'Schedule type'**
  String get scheduleType;

  /// No description provided for @fixedInterval.
  ///
  /// In en, this message translates to:
  /// **'Fixed interval'**
  String get fixedInterval;

  /// No description provided for @specificHours.
  ///
  /// In en, this message translates to:
  /// **'Specific hours'**
  String get specificHours;

  /// No description provided for @repeatOnDays.
  ///
  /// In en, this message translates to:
  /// **'Repeat on days'**
  String get repeatOnDays;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'V'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get sun;

  /// No description provided for @monFri.
  ///
  /// In en, this message translates to:
  /// **'Mon-Fri'**
  String get monFri;

  /// No description provided for @weekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get weekend;

  /// No description provided for @ends.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get ends;

  /// No description provided for @neverEnd.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get neverEnd;

  /// No description provided for @onDay.
  ///
  /// In en, this message translates to:
  /// **'On day '**
  String get onDay;

  /// No description provided for @after.
  ///
  /// In en, this message translates to:
  /// **'After '**
  String get after;

  /// No description provided for @times.
  ///
  /// In en, this message translates to:
  /// **' times'**
  String get times;

  /// No description provided for @repeatEvery.
  ///
  /// In en, this message translates to:
  /// **'Repeat every'**
  String get repeatEvery;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get hour;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get day;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get week;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get month;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get year;

  /// No description provided for @specificSchedules.
  ///
  /// In en, this message translates to:
  /// **'Specific schedules'**
  String get specificSchedules;

  /// No description provided for @defaultTimeMsg.
  ///
  /// In en, this message translates to:
  /// **'The default selected time will be used'**
  String get defaultTimeMsg;

  /// No description provided for @removeRepeat.
  ///
  /// In en, this message translates to:
  /// **'Remove repeat'**
  String get removeRepeat;

  /// No description provided for @newGroup.
  ///
  /// In en, this message translates to:
  /// **'New Group'**
  String get newGroup;

  /// No description provided for @groupNameLabel.
  ///
  /// In en, this message translates to:
  /// **'GROUP NAME'**
  String get groupNameLabel;

  /// No description provided for @groupNameHint.
  ///
  /// In en, this message translates to:
  /// **'Ex. Thesis Team'**
  String get groupNameHint;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'INVITATION CODE'**
  String get inviteCodeLabel;

  /// No description provided for @shareCodeMsg.
  ///
  /// In en, this message translates to:
  /// **'Share this code for others to join.'**
  String get shareCodeMsg;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroup;

  /// No description provided for @joinGroup.
  ///
  /// In en, this message translates to:
  /// **'Join a Group'**
  String get joinGroup;

  /// No description provided for @joinGroupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter with an invitation code'**
  String get joinGroupSubtitle;

  /// No description provided for @enterInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invitation code'**
  String get enterInviteCode;

  /// No description provided for @joinBtn.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinBtn;

  /// No description provided for @invalidCodeError.
  ///
  /// In en, this message translates to:
  /// **'The entered code is not valid'**
  String get invalidCodeError;

  /// No description provided for @alreadyInGroupError.
  ///
  /// In en, this message translates to:
  /// **'You are already a member of this group'**
  String get alreadyInGroupError;

  /// No description provided for @enterGroupNameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name for the group'**
  String get enterGroupNameError;

  /// No description provided for @newProject.
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get newProject;

  /// No description provided for @projectTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'PROJECT TITLE'**
  String get projectTitleLabel;

  /// No description provided for @projectTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Ex. Market Research'**
  String get projectTitleHint;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What is this project about?'**
  String get descriptionHint;

  /// No description provided for @projectTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'PROJECT TYPE'**
  String get projectTypeLabel;

  /// No description provided for @personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personal;

  /// No description provided for @groupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get groupLabel;

  /// No description provided for @selectGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'SELECT GROUP'**
  String get selectGroupLabel;

  /// No description provided for @chooseGroupHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a group'**
  String get chooseGroupHint;

  /// No description provided for @dates.
  ///
  /// In en, this message translates to:
  /// **'DATES'**
  String get dates;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @endOptional.
  ///
  /// In en, this message translates to:
  /// **'End (optional)'**
  String get endOptional;

  /// No description provided for @undefined.
  ///
  /// In en, this message translates to:
  /// **'Undefined'**
  String get undefined;

  /// No description provided for @createProject.
  ///
  /// In en, this message translates to:
  /// **'Create Project'**
  String get createProject;

  /// No description provided for @enterProjectTitleError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title for the project'**
  String get enterProjectTitleError;

  /// No description provided for @newFocusSession.
  ///
  /// In en, this message translates to:
  /// **'New Session'**
  String get newFocusSession;

  /// No description provided for @sessionTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'SESSION TITLE'**
  String get sessionTitleLabel;

  /// No description provided for @focusModeLabel.
  ///
  /// In en, this message translates to:
  /// **'STUDY MODE'**
  String get focusModeLabel;

  /// No description provided for @focusDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'DURATION (MIN)'**
  String get focusDurationLabel;

  /// No description provided for @breakDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'BREAK (MIN)'**
  String get breakDurationLabel;

  /// No description provided for @privateSession.
  ///
  /// In en, this message translates to:
  /// **'Private session'**
  String get privateSession;

  /// No description provided for @strictMode.
  ///
  /// In en, this message translates to:
  /// **'Strict mode'**
  String get strictMode;

  /// No description provided for @createSession.
  ///
  /// In en, this message translates to:
  /// **'Create Session'**
  String get createSession;

  /// No description provided for @soloInvitados.
  ///
  /// In en, this message translates to:
  /// **'Solo / Guests'**
  String get soloInvitados;

  /// No description provided for @howWillYouStudyHint.
  ///
  /// In en, this message translates to:
  /// **'Which group will you study with?'**
  String get howWillYouStudyHint;

  /// No description provided for @focusTimesLabel.
  ///
  /// In en, this message translates to:
  /// **'TIMES (MINUTES)'**
  String get focusTimesLabel;

  /// No description provided for @focusLabel.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focusLabel;

  /// No description provided for @breakLabel.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get breakLabel;

  /// No description provided for @focusSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'FOCUS SETTINGS'**
  String get focusSettingsLabel;

  /// No description provided for @dndModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Do Not Disturb Mode'**
  String get dndModeLabel;

  /// No description provided for @dndModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Silence phone when focusing'**
  String get dndModeSubtitle;

  /// No description provided for @strictModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Requires host permission to exit'**
  String get strictModeDesc;

  /// No description provided for @schedulingLabel.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULING (OPTIONAL)'**
  String get schedulingLabel;

  /// No description provided for @startNowLabel.
  ///
  /// In en, this message translates to:
  /// **'Start now'**
  String get startNowLabel;

  /// No description provided for @permissionRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequiredTitle;

  /// No description provided for @dndPermissionDesc.
  ///
  /// In en, this message translates to:
  /// **'To silence notifications, Nest needs access to the system\'s \"Do Not Disturb\" mode.'**
  String get dndPermissionDesc;

  /// No description provided for @configureBtn.
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get configureBtn;

  /// No description provided for @breakSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'BREAK SETTINGS'**
  String get breakSettingsLabel;

  /// No description provided for @useRingtoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Ringtone on finish'**
  String get useRingtoneLabel;

  /// No description provided for @useRingtoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the ringtone to notify when the break has ended'**
  String get useRingtoneSubtitle;

  /// No description provided for @breakFinished.
  ///
  /// In en, this message translates to:
  /// **'Break finished!'**
  String get breakFinished;

  /// No description provided for @backToWork.
  ///
  /// In en, this message translates to:
  /// **'Back to work'**
  String get backToWork;

  /// No description provided for @startFocus.
  ///
  /// In en, this message translates to:
  /// **'Start Focus'**
  String get startFocus;

  /// No description provided for @startBreak.
  ///
  /// In en, this message translates to:
  /// **'Start Break'**
  String get startBreak;

  /// No description provided for @resetSession.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetSession;

  /// No description provided for @enterSessionTitleError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title for the session'**
  String get enterSessionTitleError;

  /// No description provided for @selectGroupError.
  ///
  /// In en, this message translates to:
  /// **'Please select a group'**
  String get selectGroupError;

  /// No description provided for @newNotebook.
  ///
  /// In en, this message translates to:
  /// **'New Notebook'**
  String get newNotebook;

  /// No description provided for @notebookNameLabel.
  ///
  /// In en, this message translates to:
  /// **'NOTEBOOK NAME'**
  String get notebookNameLabel;

  /// No description provided for @notebookNameHint.
  ///
  /// In en, this message translates to:
  /// **'Ex. Math, Ideas...'**
  String get notebookNameHint;

  /// No description provided for @colorLabel.
  ///
  /// In en, this message translates to:
  /// **'COLOR'**
  String get colorLabel;

  /// No description provided for @iconLabel.
  ///
  /// In en, this message translates to:
  /// **'ICON'**
  String get iconLabel;

  /// No description provided for @createNotebook.
  ///
  /// In en, this message translates to:
  /// **'Create Notebook'**
  String get createNotebook;

  /// No description provided for @myNewNotebook.
  ///
  /// In en, this message translates to:
  /// **'My New Notebook'**
  String get myNewNotebook;

  /// No description provided for @chooseIcon.
  ///
  /// In en, this message translates to:
  /// **'Choose an Icon'**
  String get chooseIcon;

  /// No description provided for @coverColor.
  ///
  /// In en, this message translates to:
  /// **'Cover Color'**
  String get coverColor;

  /// No description provided for @createLabel.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createLabel;

  /// No description provided for @notesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no notes} =1{1 note} other{{count} notes}}'**
  String notesCount(num count);

  /// No description provided for @emptyNotebook.
  ///
  /// In en, this message translates to:
  /// **'This notebook is empty'**
  String get emptyNotebook;

  /// No description provided for @newPage.
  ///
  /// In en, this message translates to:
  /// **'New page'**
  String get newPage;

  /// No description provided for @newPageTitle.
  ///
  /// In en, this message translates to:
  /// **'New Page'**
  String get newPageTitle;

  /// No description provided for @choosePageStyle.
  ///
  /// In en, this message translates to:
  /// **'Choose page style:'**
  String get choosePageStyle;

  /// No description provided for @pageStylePlain.
  ///
  /// In en, this message translates to:
  /// **'Plain'**
  String get pageStylePlain;

  /// No description provided for @pageStyleRuled.
  ///
  /// In en, this message translates to:
  /// **'Ruled'**
  String get pageStyleRuled;

  /// No description provided for @pageStyleGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get pageStyleGrid;

  /// No description provided for @pageStyleDotted.
  ///
  /// In en, this message translates to:
  /// **'Dotted'**
  String get pageStyleDotted;

  /// No description provided for @startWriting.
  ///
  /// In en, this message translates to:
  /// **'Start writing'**
  String get startWriting;

  /// No description provided for @recurringPrograms.
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get recurringPrograms;

  /// No description provided for @noProgramsYet.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have recurring programs yet.'**
  String get noProgramsYet;

  /// No description provided for @deleteProgram.
  ///
  /// In en, this message translates to:
  /// **'Delete program'**
  String get deleteProgram;

  /// No description provided for @deleteProgramConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this program? No more reminders will be created automatically.'**
  String get deleteProgramConfirm;

  /// No description provided for @whatsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s New v6.0.0'**
  String get whatsNewTitle;

  /// No description provided for @changelog1.
  ///
  /// In en, this message translates to:
  /// **'• New UI based on Material 3'**
  String get changelog1;

  /// No description provided for @changelog2.
  ///
  /// In en, this message translates to:
  /// **'• Improved Google Calendar sync'**
  String get changelog2;

  /// No description provided for @changelog3.
  ///
  /// In en, this message translates to:
  /// **'• Dynamic themes and customization'**
  String get changelog3;

  /// No description provided for @changelog4.
  ///
  /// In en, this message translates to:
  /// **'• General performance optimization'**
  String get changelog4;

  /// No description provided for @understood.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get understood;

  /// No description provided for @backupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully'**
  String get backupSuccess;

  /// No description provided for @createPassword.
  ///
  /// In en, this message translates to:
  /// **'Create Password'**
  String get createPassword;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @enableEmailAccess.
  ///
  /// In en, this message translates to:
  /// **'Enable email access'**
  String get enableEmailAccess;

  /// No description provided for @updateSecurity.
  ///
  /// In en, this message translates to:
  /// **'Update security'**
  String get updateSecurity;

  /// No description provided for @enableEmailAccessDesc.
  ///
  /// In en, this message translates to:
  /// **'By creating a password, you will be able to log in to Nest using your Google email directly, without needing to use the Google button every time.'**
  String get enableEmailAccessDesc;

  /// No description provided for @changePasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Change your current password to keep your account secure.'**
  String get changePasswordDesc;

  /// No description provided for @passwordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Requirements'**
  String get passwordRequirements;

  /// No description provided for @min8Chars.
  ///
  /// In en, this message translates to:
  /// **'Minimum 8 characters'**
  String get min8Chars;

  /// No description provided for @passwordsMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords match'**
  String get passwordsMatch;

  /// No description provided for @verifyWithGoogleFirst.
  ///
  /// In en, this message translates to:
  /// **'Verify with Google first'**
  String get verifyWithGoogleFirst;

  /// No description provided for @passwordSetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password successfully set. You can now log in with your email and this password.'**
  String get passwordSetSuccess;

  /// No description provided for @requiresRecentLoginError.
  ///
  /// In en, this message translates to:
  /// **'For security, we need to verify your identity with Google before creating the password.'**
  String get requiresRecentLoginError;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @freeSlot.
  ///
  /// In en, this message translates to:
  /// **'Free slot'**
  String get freeSlot;

  /// No description provided for @dayFinished.
  ///
  /// In en, this message translates to:
  /// **'Day finished'**
  String get dayFinished;

  /// No description provided for @nextClassPrefix.
  ///
  /// In en, this message translates to:
  /// **'Next: {subject}'**
  String nextClassPrefix(Object subject);

  /// No description provided for @restTime.
  ///
  /// In en, this message translates to:
  /// **'Time to rest!'**
  String get restTime;

  /// No description provided for @noClasses.
  ///
  /// In en, this message translates to:
  /// **'No classes'**
  String get noClasses;

  /// No description provided for @todayAt.
  ///
  /// In en, this message translates to:
  /// **'Today at {time}'**
  String todayAt(Object time);

  /// No description provided for @tomorrowAt.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow at {time}'**
  String tomorrowAt(Object time);

  /// No description provided for @advanceClass.
  ///
  /// In en, this message translates to:
  /// **'Advance class'**
  String get advanceClass;

  /// No description provided for @resumeSchedule.
  ///
  /// In en, this message translates to:
  /// **'Resume schedule'**
  String get resumeSchedule;

  /// No description provided for @pauseSchedule.
  ///
  /// In en, this message translates to:
  /// **'Pause schedule'**
  String get pauseSchedule;

  /// No description provided for @configureSchedule.
  ///
  /// In en, this message translates to:
  /// **'Configure schedule'**
  String get configureSchedule;

  /// No description provided for @resumeScheduleOn.
  ///
  /// In en, this message translates to:
  /// **'RESUME SCHEDULE ON...'**
  String get resumeScheduleOn;

  /// No description provided for @pauseBtn.
  ///
  /// In en, this message translates to:
  /// **'PAUSE'**
  String get pauseBtn;

  /// No description provided for @discardLabel.
  ///
  /// In en, this message translates to:
  /// **'Discard...'**
  String get discardLabel;

  /// No description provided for @thisClass.
  ///
  /// In en, this message translates to:
  /// **'This class'**
  String get thisClass;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @tomorrowLabel.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrowLabel;

  /// No description provided for @weekLabel.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get weekLabel;

  /// No description provided for @reprogramClass.
  ///
  /// In en, this message translates to:
  /// **'Reprogram class'**
  String get reprogramClass;

  /// No description provided for @restoreSession.
  ///
  /// In en, this message translates to:
  /// **'Restore session'**
  String get restoreSession;

  /// No description provided for @discardSession.
  ///
  /// In en, this message translates to:
  /// **'Discard session'**
  String get discardSession;

  /// No description provided for @selectFreeSlot.
  ///
  /// In en, this message translates to:
  /// **'Select free slot'**
  String get selectFreeSlot;

  /// No description provided for @detectedFreeSlots.
  ///
  /// In en, this message translates to:
  /// **'The following slots were detected:'**
  String get detectedFreeSlots;

  /// No description provided for @noFreeSlotsToday.
  ///
  /// In en, this message translates to:
  /// **'No free slots today'**
  String get noFreeSlotsToday;

  /// No description provided for @noClassesProgrammed.
  ///
  /// In en, this message translates to:
  /// **'No classes programmed'**
  String get noClassesProgrammed;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @allSettled.
  ///
  /// In en, this message translates to:
  /// **'All settled'**
  String get allSettled;

  /// No description provided for @sessionDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Session discarded'**
  String get sessionDiscarded;

  /// No description provided for @suggestion1.
  ///
  /// In en, this message translates to:
  /// **'Hey {name}, how about pushing \"{title}\" forward?'**
  String suggestion1(Object name, Object title);

  /// No description provided for @suggestion2.
  ///
  /// In en, this message translates to:
  /// **'{name}, how about moving forward with \"{title}\" now?'**
  String suggestion2(Object name, Object title);

  /// No description provided for @suggestion3.
  ///
  /// In en, this message translates to:
  /// **'We have a gap, {name}. Should we advance \"{title}\"?'**
  String suggestion3(Object name, Object title);

  /// No description provided for @suggestion4.
  ///
  /// In en, this message translates to:
  /// **'What if we cross \"{title}\" off the list once and for all, {name}?'**
  String suggestion4(Object name, Object title);

  /// No description provided for @eventLabel.
  ///
  /// In en, this message translates to:
  /// **'EVENT'**
  String get eventLabel;

  /// No description provided for @mobileData.
  ///
  /// In en, this message translates to:
  /// **'Mobile data'**
  String get mobileData;

  /// No description provided for @noConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get noConnection;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @searchNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Search notes and notebooks...'**
  String get searchNotesHint;

  /// No description provided for @startTypingToSearch.
  ///
  /// In en, this message translates to:
  /// **'Start typing to search notes'**
  String get startTypingToSearch;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @untitledNote.
  ///
  /// In en, this message translates to:
  /// **'Untitled note'**
  String get untitledNote;

  /// No description provided for @contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// No description provided for @addFriend.
  ///
  /// In en, this message translates to:
  /// **'Add friend'**
  String get addFriend;

  /// No description provided for @scanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQr;

  /// No description provided for @myNestId.
  ///
  /// In en, this message translates to:
  /// **'My Nest ID'**
  String get myNestId;

  /// No description provided for @enterNestId.
  ///
  /// In en, this message translates to:
  /// **'Enter Nest ID (N-XXXX)'**
  String get enterNestId;

  /// No description provided for @nestIdHint.
  ///
  /// In en, this message translates to:
  /// **'Ex. N-1234'**
  String get nestIdHint;

  /// No description provided for @qrScanner.
  ///
  /// In en, this message translates to:
  /// **'QR Scanner'**
  String get qrScanner;

  /// No description provided for @qrScannerInstruction.
  ///
  /// In en, this message translates to:
  /// **'Ask the other user to open their Settings and select the QR icon so you can scan it.'**
  String get qrScannerInstruction;

  /// No description provided for @inviteToProject.
  ///
  /// In en, this message translates to:
  /// **'Invite to a project'**
  String get inviteToProject;

  /// No description provided for @selectProject.
  ///
  /// In en, this message translates to:
  /// **'Select Project'**
  String get selectProject;

  /// No description provided for @livePreview.
  ///
  /// In en, this message translates to:
  /// **'LIVE PREVIEW'**
  String get livePreview;

  /// No description provided for @fullPanel.
  ///
  /// In en, this message translates to:
  /// **'Full Panel'**
  String get fullPanel;

  /// No description provided for @essentialMinimalist.
  ///
  /// In en, this message translates to:
  /// **'Essential Minimalist'**
  String get essentialMinimalist;

  /// No description provided for @hoursAndDaysGrid.
  ///
  /// In en, this message translates to:
  /// **'Hourly & daily grid'**
  String get hoursAndDaysGrid;

  /// No description provided for @chronologicalList.
  ///
  /// In en, this message translates to:
  /// **'Chronological list'**
  String get chronologicalList;

  /// No description provided for @phoneDevice.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneDevice;

  /// No description provided for @webBrowserDevice.
  ///
  /// In en, this message translates to:
  /// **'Web Browser'**
  String get webBrowserDevice;

  /// No description provided for @tabletDevice.
  ///
  /// In en, this message translates to:
  /// **'Tablet'**
  String get tabletDevice;

  /// No description provided for @foldableDevice.
  ///
  /// In en, this message translates to:
  /// **'Foldable'**
  String get foldableDevice;

  /// No description provided for @material3Aesthetic.
  ///
  /// In en, this message translates to:
  /// **'Material 3 Aesthetic'**
  String get material3Aesthetic;

  /// No description provided for @material3Desc.
  ///
  /// In en, this message translates to:
  /// **'Use dynamic colors and native Android design'**
  String get material3Desc;

  /// No description provided for @appMode.
  ///
  /// In en, this message translates to:
  /// **'App Mode'**
  String get appMode;

  /// No description provided for @groupSettings.
  ///
  /// In en, this message translates to:
  /// **'Group Settings'**
  String get groupSettings;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupName;

  /// No description provided for @groupColor.
  ///
  /// In en, this message translates to:
  /// **'Group color'**
  String get groupColor;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCode;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied to clipboard'**
  String get codeCopied;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @makeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Make admin'**
  String get makeAdmin;

  /// No description provided for @removeFromGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove from group'**
  String get removeFromGroup;

  /// No description provided for @leaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get leaveGroup;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get deleteGroup;

  /// No description provided for @syncAndData.
  ///
  /// In en, this message translates to:
  /// **'Sync & Data'**
  String get syncAndData;

  /// No description provided for @infoSection.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get infoSection;

  /// No description provided for @accountManagement.
  ///
  /// In en, this message translates to:
  /// **'Account Management'**
  String get accountManagement;

  /// No description provided for @deleteAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Request account and data deletion in 30 days'**
  String get deleteAccountDesc;

  /// No description provided for @requestAccountDeletion.
  ///
  /// In en, this message translates to:
  /// **'Request account deletion'**
  String get requestAccountDeletion;

  /// No description provided for @gracePeriod30Days.
  ///
  /// In en, this message translates to:
  /// **'30-day grace period'**
  String get gracePeriod30Days;

  /// No description provided for @whatHappensOnDeletion.
  ///
  /// In en, this message translates to:
  /// **'What happens when you request deletion?'**
  String get whatHappensOnDeletion;

  /// No description provided for @whyAreYouLeaving.
  ///
  /// In en, this message translates to:
  /// **'Why are you leaving?'**
  String get whyAreYouLeaving;

  /// No description provided for @noLongerUseApp.
  ///
  /// In en, this message translates to:
  /// **'I no longer use the app'**
  String get noLongerUseApp;

  /// No description provided for @foundAlternative.
  ///
  /// In en, this message translates to:
  /// **'Found another alternative'**
  String get foundAlternative;

  /// No description provided for @technicalIssues.
  ///
  /// In en, this message translates to:
  /// **'Technical issues or bugs'**
  String get technicalIssues;

  /// No description provided for @privacyConcerns.
  ///
  /// In en, this message translates to:
  /// **'Privacy concerns'**
  String get privacyConcerns;

  /// No description provided for @otherReason.
  ///
  /// In en, this message translates to:
  /// **'Other reason'**
  String get otherReason;

  /// No description provided for @writeFeedbackOptional.
  ///
  /// In en, this message translates to:
  /// **'Write a comment (optional)'**
  String get writeFeedbackOptional;

  /// No description provided for @requestTotalWipeCheck.
  ///
  /// In en, this message translates to:
  /// **'I request the complete and irreversible deletion of all my Nest data after 30 days.'**
  String get requestTotalWipeCheck;

  /// No description provided for @automaticCloudSync.
  ///
  /// In en, this message translates to:
  /// **'Automatic Cloud Sync'**
  String get automaticCloudSync;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get upToDate;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear local cache'**
  String get clearCache;

  /// No description provided for @clearCacheDesc.
  ///
  /// In en, this message translates to:
  /// **'Free up temporary storage space on your device'**
  String get clearCacheDesc;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully'**
  String get cacheCleared;

  /// No description provided for @alias.
  ///
  /// In en, this message translates to:
  /// **'Alias'**
  String get alias;

  /// No description provided for @notDefined.
  ///
  /// In en, this message translates to:
  /// **'Not defined'**
  String get notDefined;

  /// No description provided for @nestIdCopied.
  ///
  /// In en, this message translates to:
  /// **'Nest ID copied to clipboard'**
  String get nestIdCopied;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'QUESTION'**
  String get question;

  /// No description provided for @votingDuration.
  ///
  /// In en, this message translates to:
  /// **'VOTING DURATION'**
  String get votingDuration;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'IMAGES'**
  String get images;

  /// No description provided for @addImages.
  ///
  /// In en, this message translates to:
  /// **'Add images'**
  String get addImages;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'OPTIONS'**
  String get options;

  /// No description provided for @addOption.
  ///
  /// In en, this message translates to:
  /// **'Add option'**
  String get addOption;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @postTitle.
  ///
  /// In en, this message translates to:
  /// **'Title of your post'**
  String get postTitle;

  /// No description provided for @addImage.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get addImage;

  /// No description provided for @selectCalendar.
  ///
  /// In en, this message translates to:
  /// **'Select a calendar'**
  String get selectCalendar;

  /// No description provided for @unnamed.
  ///
  /// In en, this message translates to:
  /// **'Unnamed'**
  String get unnamed;

  /// No description provided for @targetCalendar.
  ///
  /// In en, this message translates to:
  /// **'Destination calendar'**
  String get targetCalendar;

  /// No description provided for @openNestOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Open Nest on your phone'**
  String get openNestOnPhone;

  /// No description provided for @stepsToActivateMobile.
  ///
  /// In en, this message translates to:
  /// **'Steps to enable it on your mobile device'**
  String get stepsToActivateMobile;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @userAlreadyInContacts.
  ///
  /// In en, this message translates to:
  /// **'This user is already in your contacts'**
  String get userAlreadyInContacts;

  /// No description provided for @idCopied.
  ///
  /// In en, this message translates to:
  /// **'ID copied'**
  String get idCopied;

  /// No description provided for @editField.
  ///
  /// In en, this message translates to:
  /// **'Edit {label}'**
  String editField(Object label);

  /// No description provided for @enterField.
  ///
  /// In en, this message translates to:
  /// **'Enter your {label}'**
  String enterField(Object label);

  /// No description provided for @aliasMinLength.
  ///
  /// In en, this message translates to:
  /// **'Alias must be at least 3 characters'**
  String get aliasMinLength;

  /// No description provided for @aliasInUse.
  ///
  /// In en, this message translates to:
  /// **'This alias is already taken. Please choose another.'**
  String get aliasInUse;

  /// No description provided for @nestIdCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Nest ID copied to clipboard'**
  String get nestIdCopiedToClipboard;

  /// No description provided for @confirmLogoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get confirmLogoutMessage;

  /// No description provided for @cannotAddSelf.
  ///
  /// In en, this message translates to:
  /// **'You cannot add yourself'**
  String get cannotAddSelf;

  /// No description provided for @addedToContacts.
  ///
  /// In en, this message translates to:
  /// **'{name} added to contacts'**
  String addedToContacts(Object name);

  /// No description provided for @addToMyContacts.
  ///
  /// In en, this message translates to:
  /// **'Add to my contacts'**
  String get addToMyContacts;

  /// No description provided for @searchUser.
  ///
  /// In en, this message translates to:
  /// **'Search User'**
  String get searchUser;

  /// No description provided for @reloadingWeb.
  ///
  /// In en, this message translates to:
  /// **'Reloading Nest Web and applying update...'**
  String get reloadingWeb;

  /// No description provided for @reloadApplyUpdate.
  ///
  /// In en, this message translates to:
  /// **'Reload and apply update'**
  String get reloadApplyUpdate;

  /// No description provided for @restorationCompleted.
  ///
  /// In en, this message translates to:
  /// **'Restoration completed successfully'**
  String get restorationCompleted;

  /// No description provided for @clearCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear local cache'**
  String get clearCacheTitle;

  /// No description provided for @clearCacheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Frees up temporary storage space on your device'**
  String get clearCacheSubtitle;

  /// No description provided for @cacheClearedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully'**
  String get cacheClearedSuccessfully;

  /// No description provided for @cloudSyncCompleted.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync completed'**
  String get cloudSyncCompleted;

  /// No description provided for @browserCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Browser cache cleared successfully'**
  String get browserCacheCleared;

  /// No description provided for @pollMinOptionsError.
  ///
  /// In en, this message translates to:
  /// **'The poll requires a question and at least 2 options'**
  String get pollMinOptionsError;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get pleaseFillAllFields;

  /// No description provided for @titleOfPost.
  ///
  /// In en, this message translates to:
  /// **'Title of your post'**
  String get titleOfPost;

  /// No description provided for @sharedANote.
  ///
  /// In en, this message translates to:
  /// **'{name} shared a note'**
  String sharedANote(Object name);

  /// No description provided for @addedAReminder.
  ///
  /// In en, this message translates to:
  /// **'{name} added a reminder'**
  String addedAReminder(Object name);

  /// No description provided for @startedAPoll.
  ///
  /// In en, this message translates to:
  /// **'{name} started a poll'**
  String startedAPoll(Object name);

  /// No description provided for @viewPreviousVersionPosts.
  ///
  /// In en, this message translates to:
  /// **'View posts from previous version'**
  String get viewPreviousVersionPosts;

  /// No description provided for @messageArchive.
  ///
  /// In en, this message translates to:
  /// **'Message Archive'**
  String get messageArchive;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'FINISHED'**
  String get finished;

  /// No description provided for @votesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} votes'**
  String votesCount(Object count);

  /// No description provided for @noteImportedToPersonal.
  ///
  /// In en, this message translates to:
  /// **'Note imported to your personal notes'**
  String get noteImportedToPersonal;

  /// No description provided for @reminderAddedToPersonal.
  ///
  /// In en, this message translates to:
  /// **'Reminder added to your personal list'**
  String get reminderAddedToPersonal;

  /// No description provided for @deletePostConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete post?'**
  String get deletePostConfirmTitle;

  /// No description provided for @deletePostConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone and content will be deleted for all group members.'**
  String get deletePostConfirmContent;

  /// No description provided for @renameGroup.
  ///
  /// In en, this message translates to:
  /// **'Rename group'**
  String get renameGroup;

  /// No description provided for @selectGroupColor.
  ///
  /// In en, this message translates to:
  /// **'Select group color'**
  String get selectGroupColor;

  /// No description provided for @uploadingImage.
  ///
  /// In en, this message translates to:
  /// **'Uploading image...'**
  String get uploadingImage;

  /// No description provided for @groupImageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Group image updated'**
  String get groupImageUpdated;

  /// No description provided for @errorUploadingImage.
  ///
  /// In en, this message translates to:
  /// **'Error uploading image'**
  String get errorUploadingImage;

  /// No description provided for @appointAdmin.
  ///
  /// In en, this message translates to:
  /// **'Appoint administrator'**
  String get appointAdmin;

  /// No description provided for @appointAdminConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want {name} to also be an administrator of this group?'**
  String appointAdminConfirm(Object name);

  /// No description provided for @appointAdminBtn.
  ///
  /// In en, this message translates to:
  /// **'Appoint Admin'**
  String get appointAdminBtn;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get removeMember;

  /// No description provided for @removeMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {name} from the group?'**
  String removeMemberConfirm(Object name);

  /// No description provided for @leaveGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this group?'**
  String get leaveGroupConfirm;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @deleteGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this group? All data will be erased for all members.'**
  String get deleteGroupConfirm;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get dangerZone;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @pleaseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterTitle;

  /// No description provided for @identityVerified.
  ///
  /// In en, this message translates to:
  /// **'Identity verified. You can now save your password.'**
  String get identityVerified;

  /// No description provided for @pleaseEnterNotebookName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name for your notebook'**
  String get pleaseEnterNotebookName;

  /// No description provided for @oneHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get oneHour;

  /// No description provided for @twelveHours.
  ///
  /// In en, this message translates to:
  /// **'12 hours'**
  String get twelveHours;

  /// No description provided for @oneDay.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get oneDay;

  /// No description provided for @threeDays.
  ///
  /// In en, this message translates to:
  /// **'3 days'**
  String get threeDays;

  /// No description provided for @sevenDays.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get sevenDays;

  /// No description provided for @noLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get noLimit;

  /// No description provided for @noActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get noActivityYet;

  /// No description provided for @postType.
  ///
  /// In en, this message translates to:
  /// **'POST'**
  String get postType;

  /// No description provided for @pollType.
  ///
  /// In en, this message translates to:
  /// **'POLL'**
  String get pollType;

  /// No description provided for @noteType.
  ///
  /// In en, this message translates to:
  /// **'NOTE'**
  String get noteType;

  /// No description provided for @reminderType.
  ///
  /// In en, this message translates to:
  /// **'REMINDER'**
  String get reminderType;

  /// No description provided for @createJointReminder.
  ///
  /// In en, this message translates to:
  /// **'Create joint reminder'**
  String get createJointReminder;

  /// No description provided for @createSharedNote.
  ///
  /// In en, this message translates to:
  /// **'Create shared note'**
  String get createSharedNote;

  /// No description provided for @deleteContact.
  ///
  /// In en, this message translates to:
  /// **'Delete contact'**
  String get deleteContact;

  /// No description provided for @defaultCalendar.
  ///
  /// In en, this message translates to:
  /// **'Default calendar'**
  String get defaultCalendar;

  /// No description provided for @cloudSyncActive.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync Active'**
  String get cloudSyncActive;

  /// No description provided for @personalSession.
  ///
  /// In en, this message translates to:
  /// **'Personal Session'**
  String get personalSession;

  /// No description provided for @silence.
  ///
  /// In en, this message translates to:
  /// **'Silence'**
  String get silence;

  /// No description provided for @strict.
  ///
  /// In en, this message translates to:
  /// **'Strict'**
  String get strict;

  /// No description provided for @alarm.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get alarm;

  /// No description provided for @reminderCategory.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminderCategory;

  /// No description provided for @taskCategory.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get taskCategory;

  /// No description provided for @projectCategory.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get projectCategory;

  /// No description provided for @examCategory.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get examCategory;

  /// No description provided for @eventCategory.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get eventCategory;

  /// No description provided for @networkAndCloudPreferences.
  ///
  /// In en, this message translates to:
  /// **'NETWORK & CLOUD PREFERENCES'**
  String get networkAndCloudPreferences;

  /// No description provided for @syncWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Sync only with Wi-Fi'**
  String get syncWifiOnly;

  /// No description provided for @syncWifiOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Save mobile data by syncing only when connected to a Wi-Fi network.'**
  String get syncWifiOnlyDesc;

  /// No description provided for @automaticCloudSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic Cloud Sync'**
  String get automaticCloudSyncTitle;

  /// No description provided for @automaticCloudSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Your notes, tasks, and changes are saved and synced to the cloud in real time.'**
  String get automaticCloudSyncDesc;

  /// No description provided for @webVersionAndUpdates.
  ///
  /// In en, this message translates to:
  /// **'WEB VERSION & UPDATES'**
  String get webVersionAndUpdates;

  /// No description provided for @webAppNest.
  ///
  /// In en, this message translates to:
  /// **'Nest Web Application'**
  String get webAppNest;

  /// No description provided for @webAppBuildInfo.
  ///
  /// In en, this message translates to:
  /// **'Web Version v1.2.0 • Cloud Build'**
  String get webAppBuildInfo;

  /// No description provided for @storageManagement.
  ///
  /// In en, this message translates to:
  /// **'STORAGE MANAGEMENT'**
  String get storageManagement;

  /// No description provided for @resyncCloudData.
  ///
  /// In en, this message translates to:
  /// **'Re-sync data with Cloud'**
  String get resyncCloudData;

  /// No description provided for @resyncCloudDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Re-download the latest information from your cloud account.'**
  String get resyncCloudDataDesc;

  /// No description provided for @clearBrowserCache.
  ///
  /// In en, this message translates to:
  /// **'Clear local browser cache'**
  String get clearBrowserCache;

  /// No description provided for @clearBrowserCacheDesc.
  ///
  /// In en, this message translates to:
  /// **'Frees up temporary data stored in IndexedDB / LocalStorage.'**
  String get clearBrowserCacheDesc;

  /// No description provided for @onlineWeb.
  ///
  /// In en, this message translates to:
  /// **'Online (Web)'**
  String get onlineWeb;

  /// No description provided for @cloudServerActive.
  ///
  /// In en, this message translates to:
  /// **'Active connection with Cloud server'**
  String get cloudServerActive;

  /// No description provided for @cannotSyncNow.
  ///
  /// In en, this message translates to:
  /// **'We cannot sync your data right now'**
  String get cannotSyncNow;

  /// No description provided for @classStartWarnings.
  ///
  /// In en, this message translates to:
  /// **'Class Start Warnings'**
  String get classStartWarnings;

  /// No description provided for @notifyBeforeClassStarts.
  ///
  /// In en, this message translates to:
  /// **'Notify before each class starts'**
  String get notifyBeforeClassStarts;

  /// No description provided for @noticeAnticipation.
  ///
  /// In en, this message translates to:
  /// **'Notice anticipation:'**
  String get noticeAnticipation;

  /// No description provided for @atClassStart.
  ///
  /// In en, this message translates to:
  /// **'At start time'**
  String get atClassStart;

  /// No description provided for @minutesBefore.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min before'**
  String minutesBefore(Object minutes);

  /// No description provided for @oneHourBefore.
  ///
  /// In en, this message translates to:
  /// **'1 hour before'**
  String get oneHourBefore;

  /// No description provided for @browserNotifications.
  ///
  /// In en, this message translates to:
  /// **'Web Browser Notifications'**
  String get browserNotifications;

  /// No description provided for @browserAlerts.
  ///
  /// In en, this message translates to:
  /// **'Browser Alerts'**
  String get browserAlerts;

  /// No description provided for @browserPermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Browser permission granted'**
  String get browserPermissionGranted;

  /// No description provided for @browserAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive reminder alerts directly in your browser'**
  String get browserAlertsDesc;

  /// No description provided for @sendTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Send test notification'**
  String get sendTestNotification;

  /// No description provided for @enableBrowserNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable browser notifications'**
  String get enableBrowserNotifications;

  /// No description provided for @testNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'🔔 Nest Notifications'**
  String get testNotificationTitle;

  /// No description provided for @testNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Browser notifications are enabled successfully.'**
  String get testNotificationBody;

  /// No description provided for @nestStorage.
  ///
  /// In en, this message translates to:
  /// **'Nest Storage'**
  String get nestStorage;

  /// No description provided for @totalUsed.
  ///
  /// In en, this message translates to:
  /// **'{size} MB used in total'**
  String totalUsed(Object size);

  /// No description provided for @appDataSize.
  ///
  /// In en, this message translates to:
  /// **'App Data ({size} MB)'**
  String appDataSize(Object size);

  /// No description provided for @cacheSize.
  ///
  /// In en, this message translates to:
  /// **'Cache ({size} MB)'**
  String cacheSize(Object size);

  /// No description provided for @cacheClearedReleased.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully ({size} MB freed)'**
  String cacheClearedReleased(Object size);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
