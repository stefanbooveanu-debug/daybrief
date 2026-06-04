import 'event.dart' show EventCategory;
import 'voice_template.dart';

/// Returns a fresh list of the built-in voice templates each call so callers
/// can mutate the list without leaking state.
List<VoiceTemplate> voiceTemplateDefaults() => [
      const VoiceTemplate(
        id: '1',
        name: 'Quick Meeting',
        phrase: 'schedule meeting',
        category: EventCategory.work,
        defaultTime: '10:00',
      ),
      const VoiceTemplate(
        id: '2',
        name: 'Gym Time',
        phrase: 'workout',
        category: EventCategory.health,
        defaultTime: '18:00',
      ),
      const VoiceTemplate(
        id: '3',
        name: 'Lunch Break',
        phrase: 'lunch',
        category: EventCategory.personal,
        defaultTime: '12:00',
      ),
      const VoiceTemplate(
        id: '4',
        name: 'Doctor Visit',
        phrase: 'doctor',
        category: EventCategory.health,
        defaultTime: '09:00',
      ),
      const VoiceTemplate(
        id: '5',
        name: 'Team Standup',
        phrase: 'standup',
        category: EventCategory.work,
        defaultTime: '09:00',
      ),
      const VoiceTemplate(
        id: '6',
        name: 'Coffee Break',
        phrase: 'coffee',
        category: EventCategory.personal,
        defaultTime: '14:30',
      ),
      const VoiceTemplate(
        id: '7',
        name: 'Grocery Shopping',
        phrase: 'shopping',
        category: EventCategory.shopping,
        defaultTime: '17:00',
      ),
      const VoiceTemplate(
        id: '8',
        name: 'Birthday',
        phrase: 'birthday',
        category: EventCategory.social,
        defaultTime: '12:00',
      ),
    ];
