import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:day_brief/models/event.dart';
import 'package:day_brief/providers/event_provider.dart';
import 'package:day_brief/repositories/auth_repository.dart';
import 'package:day_brief/repositories/event_repository.dart';
import 'package:day_brief/services/local_event_store.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAuthRepository auth;
  late LocalEventStore store;
  late EventRepository events;
  late EventProvider provider;

  Event ev({
    required String id,
    required DateTime dt,
    String title = 't',
  }) =>
      Event(
        id: id,
        title: title,
        dateTime: dt,
        userId: 'demo_user',
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    auth = _MockAuthRepository();
    when(() => auth.currentUser).thenReturn(null);
    when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());

    store = LocalEventStore();
    await store.close();
    events = EventRepository(localStore: store);

    provider = EventProvider(
      authRepository: auth,
      eventRepository: events,
    );
    await provider.syncWithAuth(
      userId: null,
      isAuthenticated: false,
      isDemoMode: true,
    );
  });

  tearDown(() {
    provider.dispose();
  });

  group('getEventsForDay', () {
    test('includes events just after midnight and before next midnight',
        () async {
      await provider.addEvent(
        ev(id: 'midnight', dt: DateTime(2026, 5, 25)),
      );
      await provider.addEvent(
        ev(id: 'morning', dt: DateTime(2026, 5, 25, 9, 15)),
      );
      await provider.addEvent(
        ev(id: 'eod', dt: DateTime(2026, 5, 25, 23, 59)),
      );
      await provider.addEvent(
        ev(id: 'next-day', dt: DateTime(2026, 5, 26)),
      );

      final day = provider.getEventsForDay(DateTime(2026, 5, 25, 12));
      expect(day.map((e) => e.id).toList(), ['midnight', 'morning', 'eod']);
    });

    test('returns empty list for a day with no events', () async {
      await provider.addEvent(
        ev(id: 'only', dt: DateTime(2026, 5, 25, 10)),
      );
      expect(provider.getEventsForDay(DateTime(2026, 5, 26)), isEmpty);
    });
  });
}
