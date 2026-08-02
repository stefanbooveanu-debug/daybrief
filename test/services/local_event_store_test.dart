import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:day_brief/models/event.dart';
import 'package:day_brief/services/local_event_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalEventStore db;

  Event ev({
    required String id,
    DateTime? dt,
    String title = 't',
    String userId = 'u',
  }) =>
      Event(
        id: id,
        title: title,
        dateTime: dt ?? DateTime(2026, 5, 25, 9),
        userId: userId,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = LocalEventStore();
    await db.close();
    await db.setActiveUser('test_user');
  });

  group('insertEvent', () {
    test('adds a single event', () async {
      await db.insertEvent(ev(id: 'a'));
      final all = await db.getAllEvents();
      expect(all.length, 1);
      expect(all.single.id, 'a');
    });

    test('returns 1 (parity with previous SQL signature)', () async {
      final result = await db.insertEvent(ev(id: 'a'));
      expect(result, 1);
    });

    test('inserting same id twice replaces (no duplicates)', () async {
      await db.insertEvent(ev(id: 'a', title: 'first'));
      await db.insertEvent(ev(id: 'a', title: 'second'));
      final all = await db.getAllEvents();
      expect(all.length, 1);
      expect(all.single.title, 'second');
    });
  });

  group('getAllEvents', () {
    test('returns empty list when no events', () async {
      expect(await db.getAllEvents(), isEmpty);
    });

    test('returns events sorted by dateTime ascending', () async {
      await db.insertEvent(ev(id: 'late', dt: DateTime(2026, 5, 25, 18)));
      await db.insertEvent(ev(id: 'early', dt: DateTime(2026, 5, 25, 9)));
      await db.insertEvent(ev(id: 'mid', dt: DateTime(2026, 5, 25, 13)));
      final all = await db.getAllEvents();
      expect(all.map((e) => e.id).toList(), ['early', 'mid', 'late']);
    });
  });

  group('getEventsForDay', () {
    test('returns only events whose date matches y/m/d', () async {
      await db.insertEvent(ev(id: '24', dt: DateTime(2026, 5, 24, 9)));
      await db.insertEvent(ev(id: '25', dt: DateTime(2026, 5, 25, 9)));
      await db.insertEvent(ev(id: '26', dt: DateTime(2026, 5, 26, 9)));
      final result = await db.getEventsForDay(DateTime(2026, 5, 25, 23, 59));
      expect(result.map((e) => e.id), ['25']);
    });

    test('includes midnight (00:00) and 23:59 of the same day', () async {
      await db.insertEvent(ev(id: 'midnight', dt: DateTime(2026, 5, 25)));
      await db.insertEvent(ev(id: 'eod', dt: DateTime(2026, 5, 25, 23, 59)));
      final result = await db.getEventsForDay(DateTime(2026, 5, 25));
      expect(result.map((e) => e.id).toSet(), {'midnight', 'eod'});
    });

    test('sorted by dateTime', () async {
      await db.insertEvent(ev(id: 'pm', dt: DateTime(2026, 5, 25, 14)));
      await db.insertEvent(ev(id: 'am', dt: DateTime(2026, 5, 25, 8)));
      final out = await db.getEventsForDay(DateTime(2026, 5, 25));
      expect(out.map((e) => e.id).toList(), ['am', 'pm']);
    });
  });

  group('getUpcomingEvents', () {
    test('excludes past events, includes future', () async {
      final past = DateTime.now().subtract(const Duration(days: 1));
      final future = DateTime.now().add(const Duration(days: 1));
      await db.insertEvent(ev(id: 'past', dt: past));
      await db.insertEvent(ev(id: 'future', dt: future));
      final upcoming = await db.getUpcomingEvents();
      expect(upcoming.map((e) => e.id), ['future']);
    });
  });

  group('updateEvent', () {
    test('updates an existing event and returns 1', () async {
      await db.insertEvent(ev(id: 'a', title: 'old'));
      final result = await db.updateEvent(ev(id: 'a', title: 'new'));
      expect(result, 1);
      final all = await db.getAllEvents();
      expect(all.single.title, 'new');
    });

    test('returns 0 when id not found', () async {
      final result = await db.updateEvent(ev(id: 'missing'));
      expect(result, 0);
    });
  });

  group('deleteEvent', () {
    test('removes by id and returns the count removed', () async {
      await db.insertEvent(ev(id: 'a'));
      await db.insertEvent(ev(id: 'b'));
      final result = await db.deleteEvent('a');
      expect(result, 1);
      final all = await db.getAllEvents();
      expect(all.map((e) => e.id), ['b']);
    });

    test('returns 0 when id missing', () async {
      final result = await db.deleteEvent('nope');
      expect(result, 0);
    });
  });

  group('deleteAllEvents', () {
    test('clears store and returns prior count', () async {
      await db.insertEvent(ev(id: 'a'));
      await db.insertEvent(ev(id: 'b'));
      await db.insertEvent(ev(id: 'c'));
      final count = await db.deleteAllEvents();
      expect(count, 3);
      expect(await db.getAllEvents(), isEmpty);
    });
  });

  group('persistence', () {
    test('events written by one instance are visible to a fresh one', () async {
      await db.insertEvent(ev(id: 'persisted', title: 'survives'));
      await db.close();
      await db.setActiveUser('test_user');
      final reloaded = await db.getAllEvents();
      expect(reloaded.length, 1);
      expect(reloaded.single.id, 'persisted');
    });

    test('close() resets cache so the next read re-hydrates from prefs',
        () async {
      await db.insertEvent(ev(id: 'a'));
      await db.close();
      await db.setActiveUser('test_user');
      final all = await db.getAllEvents();
      expect(all.single.id, 'a');
    });
  });

  group('user scoping', () {
    test('migrates legacy daybrief_events key once', () async {
      SharedPreferences.setMockInitialValues({
        'daybrief_events':
            '[{"id":"legacy","userId":"u","title":"old","dateTime":"2026-05-25T09:00:00.000","reminderEnabled":false}]',
      });
      final prefs = await SharedPreferences.getInstance();
      await db.close();
      await db.setActiveUser('migrated_user');
      final all = await db.getAllEvents();
      expect(all.map((e) => e.id), ['legacy']);
      expect(prefs.getString('daybrief_events'), isNull);
      expect(prefs.getString('daybrief_events_migrated_user'), isNotNull);
    });

    test('keeps event buckets isolated per user', () async {
      await db.setActiveUser('alice');
      await db.insertEvent(ev(id: 'a1', title: 'Alice event'));

      await db.setActiveUser('bob');
      await db.insertEvent(ev(id: 'b1', title: 'Bob event'));
      expect((await db.getAllEvents()).map((e) => e.id), ['b1']);

      await db.setActiveUser('alice');
      expect((await db.getAllEvents()).map((e) => e.id), ['a1']);
    });
  });
}
