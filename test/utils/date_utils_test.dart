import 'package:flutter_test/flutter_test.dart';
import 'package:day_brief/utils/date_utils.dart';

void main() {
  // Mon 25 May 2026, 09:30
  final dt = DateTime(2026, 5, 25, 9, 30);

  group('DateUtils formatters', () {
    test('formatTime → 12h h:mm a', () {
      expect(DateUtils.formatTime(dt), '9:30 AM');
      expect(DateUtils.formatTime(DateTime(2026, 5, 25, 13, 45)), '1:45 PM');
      expect(DateUtils.formatTime(DateTime(2026, 5, 25, 0, 0)), '12:00 AM');
      expect(DateUtils.formatTime(DateTime(2026, 5, 25, 12, 0)), '12:00 PM');
    });

    test('formatTime24 → 24h HH:mm', () {
      expect(DateUtils.formatTime24(dt), '09:30');
      expect(DateUtils.formatTime24(DateTime(2026, 5, 25, 23, 5)), '23:05');
      expect(DateUtils.formatTime24(DateTime(2026, 5, 25, 0, 0)), '00:00');
    });

    test('formatDateShort → MMM d', () {
      expect(DateUtils.formatDateShort(dt), 'May 25');
    });

    test('formatDateMedium → EEE, MMM d', () {
      expect(DateUtils.formatDateMedium(dt), 'Mon, May 25');
    });

    test('formatDateFull → EEEE, MMM d, yyyy', () {
      expect(DateUtils.formatDateFull(dt), 'Monday, May 25, 2026');
    });

    test('formatMonthYear → MMMM yyyy', () {
      expect(DateUtils.formatMonthYear(dt), 'May 2026');
    });

    test('formatMonthDayYear → MMMM d, yyyy', () {
      expect(DateUtils.formatMonthDayYear(dt), 'May 25, 2026');
    });

    test('formatDateTime → EEE, MMM d • h:mm a', () {
      expect(DateUtils.formatDateTime(dt), 'Mon, May 25 • 9:30 AM');
    });

    test('formatDayName → full weekday name', () {
      expect(DateUtils.formatDayName(dt), 'Monday');
      expect(DateUtils.formatDayName(DateTime(2026, 5, 24)), 'Sunday');
    });

    test('formatDayAbbrev → first letter of abbreviation', () {
      expect(DateUtils.formatDayAbbrev(dt), 'M');                       // Mon
      expect(DateUtils.formatDayAbbrev(DateTime(2026, 5, 24)), 'S');    // Sun
      expect(DateUtils.formatDayAbbrev(DateTime(2026, 5, 27)), 'W');    // Wed
    });

    test('formatMonthName → MMMM', () {
      expect(DateUtils.formatMonthName(dt), 'May');
      expect(DateUtils.formatMonthName(DateTime(2026, 12, 1)), 'December');
    });
  });

  group('formatter instances are cached (same reference)', () {
    test('formatters expose stable static instances', () {
      expect(identical(DateUtils.timeFormat, DateUtils.timeFormat), isTrue);
      expect(identical(DateUtils.dateFullFormat, DateUtils.dateFullFormat), isTrue);
    });
  });
}
