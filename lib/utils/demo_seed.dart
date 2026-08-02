import '../models/event.dart';

/// Sample schedule so Demo Mode never opens on an empty calendar.
/// Tuned for a live pitch at Nokia Timișoara.
List<Event> buildDemoSeedEvents({
  DateTime? now,
  String userId = 'demo_user',
}) {
  final n = now ?? DateTime.now();
  DateTime at(int dayOffset, int hour, int minute) => DateTime(
        n.year,
        n.month,
        n.day + dayOffset,
        hour,
        minute,
      );

  return [
    Event(
      id: 'demo_seed_1',
      title: 'DayBrief @ Nokia Timișoara',
      dateTime: at(0, 10, 0),
      description: 'Product demo — voice calendar assistant',
      category: EventCategory.work,
      location: 'Nokia, Bulevardul Take Ionescu, Timișoara',
      userId: userId,
    ),
    Event(
      id: 'demo_seed_2',
      title: 'Design sync',
      dateTime: at(0, 14, 0),
      description: 'UI polish before the pitch',
      category: EventCategory.work,
      location: 'Nokia TM — Meeting Room',
      userId: userId,
    ),
    Event(
      id: 'demo_seed_3',
      title: 'Team lunch',
      dateTime: at(0, 12, 30),
      category: EventCategory.social,
      location: 'Iulius Town, Timișoara',
      userId: userId,
    ),
    Event(
      id: 'demo_seed_4',
      title: 'Run along the Bega',
      dateTime: at(0, 18, 30),
      category: EventCategory.health,
      location: 'Malul Begăi, Timișoara',
      userId: userId,
    ),
    Event(
      id: 'demo_seed_5',
      title: 'Follow-up call',
      dateTime: at(1, 11, 0),
      description: 'Next steps after Nokia Timișoara presentation',
      category: EventCategory.work,
      location: 'Google Meet',
      userId: userId,
    ),
    Event(
      id: 'demo_seed_6',
      title: 'Grocery run',
      dateTime: at(1, 17, 0),
      category: EventCategory.shopping,
      location: 'Auchan Timișoara',
      userId: userId,
    ),
  ]..sort((a, b) => a.dateTime.compareTo(b.dateTime));
}
