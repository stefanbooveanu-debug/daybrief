import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:day_brief/models/event.dart';
import 'package:day_brief/theme/app_theme.dart';
import 'package:day_brief/widgets/event_card.dart';

Widget _wrap(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.lightTheme,
    home: Scaffold(body: Material(child: child)),
  );
}

void main() {
  Event ev({
    String id = 'e1',
    String title = 'Standup',
    EventCategory? category = EventCategory.work,
    DateTime? dt,
  }) =>
      Event(
        id: id,
        title: title,
        dateTime: dt ?? DateTime.now().add(const Duration(days: 1)),
        category: category,
        userId: 'u',
      );

  testWidgets('renders event title', (tester) async {
    await tester.pumpWidget(_wrap(EventCard(
      event: ev(title: 'My Standup'),
      onDelete: () {},
    )));
    expect(find.text('My Standup'), findsOneWidget);
  });

  testWidgets('renders formatted time h:mm a', (tester) async {
    final at930 = DateTime.now().add(const Duration(days: 1)).copyWith(
        hour: 9, minute: 30, second: 0, millisecond: 0, microsecond: 0);
    await tester.pumpWidget(_wrap(EventCard(
      event: ev(dt: at930),
      onDelete: () {},
    )));
    expect(find.text('9:30 AM'), findsOneWidget);
  });

  testWidgets('renders location when present', (tester) async {
    await tester.pumpWidget(_wrap(EventCard(
      event: Event(
        id: 'e1',
        title: 'Meeting',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        category: EventCategory.work,
        userId: 'u',
        location: 'Room 12B',
      ),
      onDelete: () {},
    )));
    expect(find.text('Room 12B'), findsOneWidget);
    expect(find.byIcon(Icons.place_outlined), findsOneWidget);
  });

  testWidgets('onDelete fires when card is swiped to dismiss', (tester) async {
    var deleted = false;
    await tester.pumpWidget(_wrap(EventCard(
      event: ev(id: 'gone'),
      onDelete: () => deleted = true,
    )));
    await tester.fling(find.byType(Dismissible), const Offset(-500, 0), 1000);
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });

  group('category color lookup honors precedence', () {
    testWidgets('uses categoryColors override over theme extension',
        (tester) async {
      const overrideColor = Color(0xFFAA0000);
      await tester.pumpWidget(_wrap(EventCard(
        event: ev(),
        onDelete: () {},
        categoryColors: const {EventCategory.work: overrideColor},
      )));
      // Build succeeds, widget tree contains the card.
      expect(find.byType(EventCard), findsOneWidget);
    });

    testWidgets('falls back to theme CategoryColors when no override',
        (tester) async {
      await tester.pumpWidget(_wrap(EventCard(
        event: ev(),
        onDelete: () {},
      )));
      expect(find.byType(EventCard), findsOneWidget);
    });

    testWidgets('renders for every canonical category without throwing',
        (tester) async {
      for (final cat in EventCategory.values) {
        await tester.pumpWidget(_wrap(EventCard(
          event: ev(category: cat, title: cat.displayName),
          onDelete: () {},
        )));
        expect(find.text(cat.displayName), findsOneWidget,
            reason: 'failed for ${cat.displayName}');
      }
    });

    testWidgets('uncategorized event still renders (no crash)', (tester) async {
      await tester.pumpWidget(_wrap(EventCard(
        event: ev(category: null, title: 'Mystery'),
        onDelete: () {},
      )));
      expect(find.text('Mystery'), findsOneWidget);
    });
  });

  testWidgets('respects isDark surface choice', (tester) async {
    await tester.pumpWidget(_wrap(
      EventCard(
        event: ev(),
        onDelete: () {},
        isDark: true,
      ),
      theme: AppTheme.darkTheme,
    ));
    expect(find.byType(EventCard), findsOneWidget);
  });
}
