import 'package:flutter_test/flutter_test.dart';

import 'package:day_brief/models/event.dart';
import 'package:day_brief/services/google_calendar_service.dart';

void main() {
  late GoogleCalendarService service;

  setUp(() {
    service = GoogleCalendarService();
  });

  group('generateIcsFile', () {
    test('escapes RFC 5545 special characters in SUMMARY and DESCRIPTION', () {
      final ics = service.generateIcsFile([
        Event(
          id: 'e1',
          title: r'Meet; Bob, Alice\path',
          dateTime: DateTime.utc(2026, 5, 25, 9),
          description: 'Line1\nLine2',
          userId: 'u1',
        ),
      ]);

      expect(ics, contains('BEGIN:VCALENDAR'));
      expect(ics, contains(r'SUMMARY:Meet\; Bob\, Alice\\path'));
      expect(ics, contains(r'DESCRIPTION:Line1\nLine2'));
      expect(ics, contains('END:VCALENDAR'));
    });

    test('round-trips a simple event through parseIcsEvents', () {
      final original = Event(
        id: 'ignored',
        title: 'Standup',
        dateTime: DateTime.utc(2026, 5, 25, 10),
        description: 'Daily sync',
        userId: 'u1',
      );
      final ics = service.generateIcsFile([original]);
      final parsed = service.parseIcsEvents(ics);

      expect(parsed, hasLength(1));
      expect(parsed.single.title, 'Standup');
      expect(parsed.single.description, 'Daily sync');
    });
  });

  group('connection state', () {
    test('isConnected is false before sign-in', () {
      expect(service.isConnected, isFalse);
    });
  });
}
