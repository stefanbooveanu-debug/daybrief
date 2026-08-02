import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:day_brief/models/voice_template.dart';
import 'package:day_brief/providers/voice_template_provider.dart';
import 'package:day_brief/repositories/voice_template_repository.dart';

/// VoiceTemplateProvider does async work in its constructor (_loadTemplates).
/// This helper builds the provider and pumps the microtask queue until the
/// initial load finishes.
Future<VoiceTemplateProvider> _ready() async {
  final prefs = await SharedPreferences.getInstance();
  final p = VoiceTemplateProvider(VoiceTemplateRepository(prefs: prefs));
  // _loadTemplates kicks off; let microtasks settle.
  while (p.isLoading) {
    await Future<void>.delayed(Duration.zero);
  }
  return p;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('initial load', () {
    test('falls back to defaultTemplates when SharedPreferences is empty',
        () async {
      final p = await _ready();
      expect(p.templates.length, VoiceTemplate.defaultTemplates.length);
      expect(p.isLoading, isFalse);
      expect(p.customTemplates, isEmpty);
    });

    test('loads existing templates from SharedPreferences', () async {
      final stored = jsonEncode([
        const VoiceTemplate(
          id: 'x',
          name: 'Stored',
          phrase: 'stored',
          isCustom: true,
        ).toMap(),
      ]);
      SharedPreferences.setMockInitialValues({'voiceTemplates': stored});

      final p = await _ready();
      expect(p.templates.length, 1);
      expect(p.templates.single.name, 'Stored');
      expect(p.customTemplates.length, 1);
    });

    test('malformed JSON in prefs falls back to defaults silently', () async {
      SharedPreferences.setMockInitialValues({'voiceTemplates': 'not-json'});
      final p = await _ready();
      expect(p.templates.length, VoiceTemplate.defaultTemplates.length);
    });
  });

  group('addTemplate', () {
    test('appends with isCustom=true regardless of input', () async {
      final p = await _ready();
      final base = p.templates.length;
      await p.addTemplate(const VoiceTemplate(
        id: 'mine',
        name: 'Mine',
        phrase: 'mine',
      ));
      expect(p.templates.length, base + 1);
      expect(p.templates.last.isCustom, isTrue);
      expect(p.customTemplates, hasLength(1));
    });

    test('persists across a new provider instance', () async {
      var p = await _ready();
      await p.addTemplate(
        const VoiceTemplate(id: 'mine', name: 'Mine', phrase: 'mine'),
      );
      final beforeCount = p.templates.length;

      p = await _ready();
      expect(p.templates.length, beforeCount);
      expect(p.customTemplates.map((t) => t.name), contains('Mine'));
    });
  });

  group('updateTemplate', () {
    test('replaces by id', () async {
      final p = await _ready();
      final orig = p.templates.first;
      await p.updateTemplate(orig.copyWith(name: 'Renamed'));
      expect(p.templates.first.id, orig.id);
      expect(p.templates.first.name, 'Renamed');
    });

    test('no-op for unknown id', () async {
      final p = await _ready();
      final before = p.templates.length;
      await p.updateTemplate(
        const VoiceTemplate(id: 'ghost', name: 'g', phrase: 'g'),
      );
      expect(p.templates.length, before);
    });
  });

  group('deleteTemplate', () {
    test('removes by id', () async {
      final p = await _ready();
      final id = p.templates.first.id;
      await p.deleteTemplate(id);
      expect(p.templates.any((t) => t.id == id), isFalse);
    });
  });

  group('matchTemplate', () {
    test('matches case-insensitive substring of phrase', () async {
      final p = await _ready();
      expect(p.matchTemplate('time to WORKOUT now')?.name, 'Gym Time');
      expect(
          p.matchTemplate('Schedule MEETING with team')?.name, 'Quick Meeting');
    });

    test('returns null on no match', () async {
      final p = await _ready();
      expect(p.matchTemplate('xyz nonsense input'), isNull);
    });
  });

  group('resetToDefaults', () {
    test('overwrites all custom templates with the defaults', () async {
      final p = await _ready();
      await p.addTemplate(
        const VoiceTemplate(id: 'mine', name: 'Mine', phrase: 'mine'),
      );
      expect(p.customTemplates, isNotEmpty);

      await p.resetToDefaults();
      expect(p.templates.length, VoiceTemplate.defaultTemplates.length);
      expect(p.customTemplates, isEmpty);
    });
  });
}
