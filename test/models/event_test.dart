import 'package:flutter_test/flutter_test.dart';
import 'package:day_brief/models/event.dart';

void main() {
  group('Event', () {
    Event sample({
      String id = 'e1',
      String title = 'Standup',
      DateTime? dt,
      String? description = 'Team sync',
      EventCategory? category = EventCategory.work,
      bool reminderEnabled = true,
      bool isCompleted = false,
      String userId = 'u1',
      String? location = 'Zoom',
      RecurrenceType recurrence = RecurrenceType.weekly,
    }) =>
        Event(
          id: id,
          title: title,
          dateTime: dt ?? DateTime(2026, 5, 25, 9, 30),
          description: description,
          category: category,
          reminderEnabled: reminderEnabled,
          isCompleted: isCompleted,
          userId: userId,
          location: location,
          recurrenceType: recurrence,
        );

    test('constructor stores all fields', () {
      final e = sample();
      expect(e.id, 'e1');
      expect(e.title, 'Standup');
      expect(e.dateTime, DateTime(2026, 5, 25, 9, 30));
      expect(e.description, 'Team sync');
      expect(e.category, EventCategory.work);
      expect(e.reminderEnabled, isTrue);
      expect(e.isCompleted, isFalse);
      expect(e.userId, 'u1');
      expect(e.location, 'Zoom');
      expect(e.recurrenceType, RecurrenceType.weekly);
    });

    test('defaults: reminderEnabled=true, isCompleted=false, recurrenceType=none', () {
      final e = Event(
        id: '1',
        title: 't',
        dateTime: DateTime(2026),
        userId: 'u',
      );
      expect(e.reminderEnabled, isTrue);
      expect(e.isCompleted, isFalse);
      expect(e.recurrenceType, RecurrenceType.none);
      expect(e.description, isNull);
      expect(e.category, isNull);
      expect(e.location, isNull);
    });

    group('reminderTime', () {
      test('is 1 hour before dateTime when reminderEnabled', () {
        final e = sample(dt: DateTime(2026, 5, 25, 10));
        expect(e.reminderTime, DateTime(2026, 5, 25, 9));
      });

      test('is null when reminderEnabled is false', () {
        final e = sample(reminderEnabled: false);
        expect(e.reminderTime, isNull);
      });

      test('handles midnight crossover (1am minus 1h = previous day 0:00)', () {
        final e = sample(dt: DateTime(2026, 5, 25, 0, 30));
        expect(e.reminderTime, DateTime(2026, 5, 24, 23, 30));
      });
    });

    group('toMap / fromMap round-trip', () {
      test('preserves every field', () {
        final original = sample();
        final restored = Event.fromMap(original.toMap());

        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.dateTime, original.dateTime);
        expect(restored.description, original.description);
        expect(restored.category, original.category);
        expect(restored.reminderEnabled, original.reminderEnabled);
        expect(restored.isCompleted, original.isCompleted);
        expect(restored.userId, original.userId);
        expect(restored.location, original.location);
        expect(restored.recurrenceType, original.recurrenceType);
      });

      test('serializes dateTime as ISO-8601 string', () {
        final e = sample(dt: DateTime(2026, 5, 25, 9, 30));
        expect(e.toMap()['dateTime'], '2026-05-25T09:30:00.000');
      });

      test('serializes recurrenceType as its enum name', () {
        for (final rt in RecurrenceType.values) {
          final e = sample(recurrence: rt);
          expect(e.toMap()['recurrenceType'], rt.name,
              reason: 'expected name for $rt');
        }
      });

      test('serializes category as enum name', () {
        final e = sample(category: EventCategory.health);
        expect(e.toMap()['category'], 'health');
      });

      test('fromMap parses legacy title-cased category strings', () {
        final restored = Event.fromMap({
          'id': '1',
          'title': 't',
          'dateTime': DateTime(2026).toIso8601String(),
          'userId': 'u',
          'category': 'Work',
        });
        expect(restored.category, EventCategory.work);
      });

      test('fromMap accepts all RecurrenceType indices', () {
        for (var i = 0; i < RecurrenceType.values.length; i++) {
          final restored = Event.fromMap({
            'id': 'x',
            'title': 't',
            'dateTime': DateTime(2026).toIso8601String(),
            'userId': 'u',
            'recurrenceType': i,
          });
          expect(restored.recurrenceType, RecurrenceType.values[i]);
        }
      });

      test('fromMap throws on malformed or incomplete JSON', () {
        expect(
          () => Event.fromMap({'dateTime': 'not-a-date'}),
          throwsA(anything),
        );
      });
    });

    group('copyWith', () {
      test('with no overrides returns a clone (value-equal field-by-field)', () {
        final original = sample();
        final clone = original.copyWith();

        expect(clone.id, original.id);
        expect(clone.title, original.title);
        expect(clone.dateTime, original.dateTime);
        expect(clone.description, original.description);
        expect(clone.category, original.category);
        expect(clone.reminderEnabled, original.reminderEnabled);
        expect(clone.isCompleted, original.isCompleted);
        expect(clone.userId, original.userId);
        expect(clone.location, original.location);
        expect(clone.recurrenceType, original.recurrenceType);
      });

      test('overrides individual fields without touching others', () {
        final e = sample().copyWith(
          title: 'New title',
          isCompleted: true,
          recurrenceType: RecurrenceType.monthly,
        );
        expect(e.title, 'New title');
        expect(e.isCompleted, isTrue);
        expect(e.recurrenceType, RecurrenceType.monthly);
        expect(e.id, 'e1');
        expect(e.userId, 'u1');
      });

      test('passing null clears nullable fields (freezed copyWith)', () {
        final original = sample(description: 'keep me');
        final clone = original.copyWith(description: null);
        expect(clone.description, isNull);
      });
    });

    group('RecurrenceType enum', () {
      test('has exactly 5 values in fixed order', () {
        expect(RecurrenceType.values, [
          RecurrenceType.none,
          RecurrenceType.daily,
          RecurrenceType.weekly,
          RecurrenceType.monthly,
          RecurrenceType.yearly,
        ]);
      });
    });
  });
}
