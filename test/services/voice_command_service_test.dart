import 'package:flutter_test/flutter_test.dart';
import 'package:day_brief/models/event.dart';
import 'package:day_brief/services/voice_command_service.dart';

void main() {
  late VoiceCommandService svc;

  setUp(() {
    svc = VoiceCommandService();
  });

  Event ev({
    String id = 'e1',
    String title = 'Standup',
    DateTime? dt,
    String? category = 'Work',
    String? description,
  }) =>
      Event(
        id: id,
        title: title,
        dateTime: dt ?? DateTime.now(),
        category: category,
        description: description,
        userId: 'u',
      );

  group('processCommand — wake word', () {
    test('returns VoiceNoOp when wake word is missing', () async {
      final result = await svc.processCommand('schedule a meeting', []);
      expect(result, isA<VoiceNoOp>());
    });

    test('"hey daybrief" alone returns VoiceNoOp', () async {
      final result = await svc.processCommand('hey daybrief', []);
      expect(result, isA<VoiceNoOp>());
    });

    test('plain "daybrief" also triggers wake (lenient mode)', () async {
      final result = await svc.processCommand('daybrief help', []);
      expect(result, isA<VoiceSpoken>());
    });
  });

  group('processCommand — date/time queries', () {
    test('"what day is it" speaks today\'s date', () async {
      final result = await svc.processCommand(
          'hey daybrief what day is it', []) as VoiceSpoken;
      expect(result.text, contains('Today is '));
      expect(result.text, contains('${DateTime.now().year}'));
    });

    test('"what time is it" speaks current time', () async {
      final result = await svc.processCommand(
          'hey daybrief what time is it', []) as VoiceSpoken;
      expect(result.text, startsWith("It's "));
      expect(result.text, anyOf(contains('AM'), contains('PM')));
    });
  });

  group('processCommand — schedule queries', () {
    test('"my schedule" with no events returns the empty-day message',
        () async {
      final result =
          await svc.processCommand('hey daybrief my schedule', []) as VoiceSpoken;
      expect(result.text, contains('nothing planned'));
    });

    test('"what do I have today" mentions today\'s event titles', () async {
      final today = DateTime.now();
      final events = [
        ev(title: 'Standup', dt: DateTime(today.year, today.month, today.day, 9)),
        ev(title: 'Gym',     dt: DateTime(today.year, today.month, today.day, 18)),
      ];
      final result = await svc.processCommand(
          'hey daybrief what do i have today', events) as VoiceSpoken;
      expect(result.text, contains('Standup'));
      expect(result.text, contains('Gym'));
      expect(result.text, contains('2 things'));
    });
  });

  group('processCommand — intent routing', () {
    test('"add event" → VoiceShowAddEvent', () async {
      final r = await svc.processCommand('hey daybrief add event', []);
      expect(r, isA<VoiceShowAddEvent>());
    });

    test('"schedule" → VoiceShowAddEvent', () async {
      final r = await svc.processCommand('daybrief schedule lunch', []);
      expect(r, isA<VoiceShowAddEvent>());
    });

    test('"book" → VoiceShowAddEvent', () async {
      final r = await svc.processCommand('daybrief book the room', []);
      expect(r, isA<VoiceShowAddEvent>());
    });

    test('"hello" → greeting VoiceSpoken', () async {
      final r =
          await svc.processCommand('daybrief hello', []) as VoiceSpoken;
      expect(r.text, contains('How can I help'));
    });

    test('"help" → help text', () async {
      final r =
          await svc.processCommand('daybrief help', []) as VoiceSpoken;
      expect(r.text, contains('what do I have today'));
    });

    test('"thanks" → polite reply', () async {
      final r =
          await svc.processCommand('daybrief thanks', []) as VoiceSpoken;
      expect(r.text, "You're welcome!");
    });

    test('unknown command → "not sure how to help"', () async {
      final r = await svc.processCommand(
          'daybrief asdfqwerzxcv', []) as VoiceSpoken;
      expect(r.text, contains("I'm not sure"));
    });
  });

  group('parseMoveEvent', () {
    test('moves an event when both times are present and event exists today',
        () {
      final today = DateTime.now();
      final e = ev(
        id: 'meet-3',
        title: 'Project sync',
        dt: DateTime(today.year, today.month, today.day, 15, 0),
      );
      final result = svc.parseMoveEvent('move my 3pm to 5pm', [e]) as VoiceMoveEvent;

      expect(result.eventId, 'meet-3');
      expect(result.newTime.hour, 17);
      expect(result.newTime.minute, 0);
      expect(result.newTime.day, today.day);
    });

    test('returns VoiceSpoken hint when times are missing', () {
      final r = svc.parseMoveEvent('move my meeting', []) as VoiceSpoken;
      expect(r.text, contains('Try saying'));
    });

    test('returns VoiceSpoken when event cannot be found', () {
      final r = svc.parseMoveEvent('move my 3pm to 5pm', []) as VoiceSpoken;
      expect(r.text, contains("couldn't find"));
    });

    test('returns VoiceSpoken when only fromTime is given but toTime is not',
        () {
      final today = DateTime.now();
      final e = ev(dt: DateTime(today.year, today.month, today.day, 15));
      final r = svc.parseMoveEvent('move my 3pm', [e]) as VoiceSpoken;
      expect(r.text, contains('Which time'));
    });
  });

  group('parseDeleteEvent', () {
    test('matches an event by title substring', () {
      final e = ev(title: 'Dentist');
      final r =
          svc.parseDeleteEvent('delete the dentist', [e]) as VoiceDeleteEvent;
      expect(r.eventName, 'Dentist');
    });

    test('prompts when no event matches', () {
      final r = svc.parseDeleteEvent('delete x', []) as VoiceSpoken;
      expect(r.text, contains('Which event'));
    });
  });

  group('parseAddEvent', () {
    test('returns null on empty / whitespace-only input', () {
      expect(svc.parseAddEvent('   ', 'u'), isNull);
    });

    test('extracts title, time, and infers Personal category for "lunch"', () {
      final e = svc.parseAddEvent('schedule lunch tomorrow at 1pm', 'u1');
      expect(e, isNotNull);
      expect(e!.title.toLowerCase(), contains('lunch'));
      expect(e.dateTime.hour, 13);
      expect(e.dateTime.minute, 0);
      expect(e.category, 'Personal');
      expect(e.userId, 'u1');
      // tomorrow
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(e.dateTime.day, tomorrow.day);
    });

    test('infers Health category for "gym"', () {
      final e = svc.parseAddEvent('gym today at 6pm', 'u');
      expect(e!.category, 'Health');
      expect(e.dateTime.hour, 18);
    });

    test('infers Work category from title keyword', () {
      // Note: parseAddEvent strips the words schedule/book/event/meeting/call
      // from the final title, so use a title keyword that survives.
      final e = svc.parseAddEvent('work standup at 10am', 'u');
      expect(e, isNotNull);
      expect(e!.category, 'Work');
      expect(e.dateTime.hour, 10);
    });

    test('infers Social category for "birthday"', () {
      final e = svc.parseAddEvent('birthday party at 7pm', 'u');
      expect(e!.category, 'Social');
    });

    test('infers Shopping category for "grocery"', () {
      final e = svc.parseAddEvent('grocery shopping at 5pm', 'u');
      expect(e!.category, 'Shopping');
    });

    test('falls back to 9am default when no time is given', () {
      final e = svc.parseAddEvent('lunch', 'u');
      expect(e, isNotNull);
      expect(e!.dateTime.hour, 9);
    });

    test('resolves "monday" to the next monday (not today\'s weekday)', () {
      final e = svc.parseAddEvent('standup monday at 9am', 'u');
      expect(e, isNotNull);
      expect(e!.dateTime.weekday, DateTime.monday);
      final now = DateTime.now();
      // strictly in the future
      expect(e.dateTime.isAfter(now) || e.dateTime.day != now.day, isTrue);
    });

    test('converts 12am → 00 and 12pm → 12', () {
      // "call" is in the title strip-regex, so use a surviving keyword.
      final am = svc.parseAddEvent('standup at 12am', 'u');
      final pm = svc.parseAddEvent('standup at 12pm', 'u');
      expect(am, isNotNull, reason: 'AM parse returned null');
      expect(pm, isNotNull, reason: 'PM parse returned null');
      expect(am!.dateTime.hour, 0);
      expect(pm!.dateTime.hour, 12);
    });
  });

  group('formatScheduleForSpeech', () {
    test('empty schedule', () {
      expect(svc.formatScheduleForSpeech([]), contains('nothing planned'));
    });

    test('one event, no description', () {
      final today = DateTime.now();
      final e = ev(
        title: 'Standup',
        dt: DateTime(today.year, today.month, today.day, 9, 0),
        description: null,
      );
      final out = svc.formatScheduleForSpeech([e]);
      expect(out, contains('Standup'));
      expect(out, contains('9:00 AM'));
    });

    test('one event with description includes "for <description>"', () {
      final today = DateTime.now();
      final e = ev(
        title: 'Lunch',
        dt: DateTime(today.year, today.month, today.day, 12, 30),
        description: 'with Sam',
      );
      final out = svc.formatScheduleForSpeech([e]);
      expect(out, contains('Lunch for with Sam at 12:30 PM'));
    });

    test('filters out events not on today', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final e = ev(title: 'Old', dt: yesterday);
      expect(svc.formatScheduleForSpeech([e]), contains('nothing planned'));
    });
  });

  group('static formatEventsForSpeech', () {
    test('empty', () {
      expect(VoiceCommandService.formatEventsForSpeech([]), 'No events scheduled');
    });

    test('singular vs plural pluralization', () {
      final one = VoiceCommandService.formatEventsForSpeech([
        Event(id: '1', title: 'A', dateTime: DateTime(2026, 1, 1, 9), userId: 'u'),
      ]);
      expect(one, startsWith('You have 1 event.'));

      final two = VoiceCommandService.formatEventsForSpeech([
        Event(id: '1', title: 'A', dateTime: DateTime(2026, 1, 1, 9), userId: 'u'),
        Event(id: '2', title: 'B', dateTime: DateTime(2026, 1, 1, 10), userId: 'u'),
      ]);
      expect(two, startsWith('You have 2 events.'));
      expect(two, contains('A at 9:00 AM'));
      expect(two, contains('B at 10:00 AM'));
    });
  });

  group('insights', () {
    test('no events this week', () async {
      final r = await svc.processCommand('daybrief give me insights', [])
          as VoiceSpoken;
      expect(r.text, contains('no events'));
    });

    test('busy week (>10 work/personal with some health) recommends breaks',
        () async {
      // The insights branch order is: (no health && lots of work) FIRST, then
      // (work > 10) SECOND. To reach the "busy week" branch we need at least
      // one Health event so the first branch doesn't fire.
      final today = DateTime.now();
      final events = [
        ...List.generate(
          12,
          (i) => ev(
            id: 'w$i',
            title: 'Meeting $i',
            dt: DateTime(today.year, today.month, today.day, 9 + (i % 8)),
            category: 'Work',
          ),
        ),
        ev(
          id: 'gym',
          title: 'Gym',
          dt: DateTime(today.year, today.month, today.day, 18),
          category: 'Health',
        ),
      ];
      final r = await svc.processCommand('daybrief insights', events)
          as VoiceSpoken;
      expect(r.text, contains('busy week'));
    });

    test('work-heavy with no health → recommends exercise', () async {
      final today = DateTime.now();
      final events = List.generate(
        5,
        (i) => ev(
          id: 'w$i',
          title: 'Work $i',
          dt: DateTime(today.year, today.month, today.day, 9 + i),
          category: 'Work',
        ),
      );
      final r = await svc.processCommand('daybrief insights', events)
          as VoiceSpoken;
      expect(r.text, contains('exercise'));
    });
  });

  group('VoiceAction value semantics', () {
    test('VoiceMoveEvent stores eventId and newTime', () {
      final t = DateTime(2026, 1, 1, 17);
      const _ = VoiceShowAddEvent(); // sanity: const constructible
      final m = VoiceMoveEvent('x', t);
      expect(m.eventId, 'x');
      expect(m.newTime, t);
    });

    test('VoiceDeleteEvent stores name', () {
      expect(const VoiceDeleteEvent('Gym').eventName, 'Gym');
    });

    test('VoiceSpoken stores text', () {
      expect(const VoiceSpoken('hello').text, 'hello');
    });

    test('wakeWord constant', () {
      expect(VoiceCommandService.wakeWord, 'hey daybrief');
    });
  });
}
