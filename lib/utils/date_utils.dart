import 'package:intl/intl.dart';

class DateUtils {
  static final DateFormat timeFormat = DateFormat('h:mm a');
  static final DateFormat time24Format = DateFormat('HH:mm');
  static final DateFormat dateShortFormat = DateFormat('MMM d');
  static final DateFormat dateMediumFormat = DateFormat('EEE, MMM d');
  static final DateFormat dateFullFormat = DateFormat('EEEE, MMM d, yyyy');
  static final DateFormat monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat monthDayYearFormat = DateFormat('MMMM d, yyyy');
  static final DateFormat dateTimeFormat = DateFormat('EEE, MMM d • h:mm a');
  static final DateFormat dayNameFormat = DateFormat('EEEE');
  static final DateFormat dayAbbrevFormat = DateFormat('E');
  static final DateFormat monthNameFormat = DateFormat('MMMM');

  static String formatTime(DateTime dt) => timeFormat.format(dt);
  static String formatTime24(DateTime dt) => time24Format.format(dt);
  static String formatDateShort(DateTime dt) => dateShortFormat.format(dt);
  static String formatDateMedium(DateTime dt) => dateMediumFormat.format(dt);
  static String formatDateFull(DateTime dt) => dateFullFormat.format(dt);
  static String formatMonthYear(DateTime dt) => monthYearFormat.format(dt);
  static String formatMonthDayYear(DateTime dt) => monthDayYearFormat.format(dt);
  static String formatDateTime(DateTime dt) => dateTimeFormat.format(dt);
  static String formatDayName(DateTime dt) => dayNameFormat.format(dt);
  static String formatDayAbbrev(DateTime dt) => dayAbbrevFormat.format(dt).substring(0, 1);
  static String formatMonthName(DateTime dt) => monthNameFormat.format(dt);
}