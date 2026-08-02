// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DayBrief';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navFamily => 'Family';

  @override
  String get navReports => 'Reports';

  @override
  String get emptyEventsTitle => 'No events';

  @override
  String get emptyEventsSubtitle => 'Tap + to add something';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get drivingModeTitle => 'Driving Mode';

  @override
  String get drivingModeSubtitle => 'Voice-only control';

  @override
  String get drivingTapToSpeak => 'Tap to speak';

  @override
  String get drivingListening => 'Listening…';

  @override
  String get drivingExit => 'Exit';

  @override
  String get drivingQuickCommands => 'Quick commands';

  @override
  String get drivingNext => 'Next';

  @override
  String get drivingWhatToday => 'What\'s today?';

  @override
  String get drivingWhatTime => 'What time is it?';

  @override
  String get drivingNoEventsToday => 'No events today';

  @override
  String get drivingUnderstood => 'Got it!';

  @override
  String get settingsLanguage => 'Language';
}
