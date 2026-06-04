import 'package:flutter_test/flutter_test.dart';
import 'package:day_brief/models/event.dart';
import 'package:day_brief/models/voice_template.dart';

void main() {
  group('VoiceTemplate', () {
    test('constructor stores all fields, isCustom defaults to false', () {
      final t = VoiceTemplate(
        id: 'a1',
        name: 'Gym',
        phrase: 'workout',
        category: EventCategory.health,
        defaultTime: '18:00',
      );
      expect(t.id, 'a1');
      expect(t.name, 'Gym');
      expect(t.phrase, 'workout');
      expect(t.category, EventCategory.health);
      expect(t.defaultTime, '18:00');
      expect(t.isCustom, isFalse);
    });

    test('toMap / fromMap round-trip', () {
      final t = VoiceTemplate(
        id: 'a1',
        name: 'Gym',
        phrase: 'workout',
        category: EventCategory.health,
        defaultTime: '18:00',
        isCustom: true,
      );
      final restored = VoiceTemplate.fromMap(t.toMap());

      expect(restored.id, t.id);
      expect(restored.name, t.name);
      expect(restored.phrase, t.phrase);
      expect(restored.category, t.category);
      expect(restored.defaultTime, t.defaultTime);
      expect(restored.isCustom, t.isCustom);
    });

    test('fromMap with empty map throws (required fields)', () {
      expect(
        () => VoiceTemplate.fromMap(<String, dynamic>{}),
        throwsA(isA<TypeError>()),
      );
    });

    group('copyWith', () {
      final original = VoiceTemplate(
        id: '1',
        name: 'Standup',
        phrase: 'standup',
        category: EventCategory.work,
        defaultTime: '09:00',
      );

      test('with no overrides clones all fields', () {
        final clone = original.copyWith();
        expect(clone.id, original.id);
        expect(clone.name, original.name);
        expect(clone.phrase, original.phrase);
        expect(clone.category, original.category);
        expect(clone.defaultTime, original.defaultTime);
        expect(clone.isCustom, original.isCustom);
      });

      test('selectively overrides isCustom (used by addTemplate)', () {
        final clone = original.copyWith(isCustom: true);
        expect(clone.isCustom, isTrue);
        expect(clone.id, original.id);
        expect(clone.name, original.name);
      });

      test('passing null clears nullable category (freezed copyWith)', () {
        final clone = original.copyWith(category: null);
        expect(clone.category, isNull);
      });
    });

    group('defaultTemplates', () {
      final templates = VoiceTemplate.defaultTemplates;

      test('contains 8 entries', () {
        expect(templates.length, 8);
      });

      test('every entry has non-empty id, name, phrase', () {
        for (final t in templates) {
          expect(t.id, isNotEmpty);
          expect(t.name, isNotEmpty);
          expect(t.phrase, isNotEmpty);
        }
      });

      test('all entries have isCustom = false', () {
        for (final t in templates) {
          expect(t.isCustom, isFalse, reason: '${t.name} should be a builtin');
        }
      });

      test('ids are unique', () {
        final ids = templates.map((t) => t.id).toSet();
        expect(ids.length, templates.length);
      });

      test('every defaultTime is in HH:mm format', () {
        final re = RegExp(r'^\d{2}:\d{2}$');
        for (final t in templates) {
          expect(t.defaultTime, isNotNull);
          expect(re.hasMatch(t.defaultTime!), isTrue,
              reason: '${t.name} time = ${t.defaultTime}');
        }
      });

      test('categories come from the canonical set', () {
        const allowed = {
          EventCategory.work,
          EventCategory.personal,
          EventCategory.health,
          EventCategory.social,
          EventCategory.shopping,
        };
        for (final t in templates) {
          expect(allowed.contains(t.category), isTrue,
              reason: '${t.name} has unknown category ${t.category}');
        }
      });

      test('returns a fresh list on each call (no shared mutable state)', () {
        final a = VoiceTemplate.defaultTemplates;
        final b = VoiceTemplate.defaultTemplates;
        expect(identical(a, b), isFalse);
      });
    });
  });
}
