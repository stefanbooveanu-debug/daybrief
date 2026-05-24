# DayBrief — Detailed Execution Plan (Phases 1–4)

Per-subsection execution guide. Each item is a small, atomic checklist with verification.

This file is the **execution layer**; `REMEDIATION-PLAN.md` is the **design layer**. Read both.

**Governance:** `.cursor/rules/phase-execution.mdc` is mandatory. No exceptions.

---

## Pre-flight (run once per session)

```powershell
cd C:\Users\Mircea\projects\daybrief
git pull
git status                  # must be clean
flutter pub get
flutter analyze             # must show 0 errors
git log -1 --oneline        # confirm Phase 0 commit 14e8914 or later
```

If any of those fail, **stop and resolve** before writing code.

---

# Phase 1 — Delete and consolidate (~0.5 day)

Goal: remove ~2,200 LOC of dead code, unify theme + voice parser, port missing features from demo widgets.

## 1.1 Safe deletes (zero-reference files)

For **each** file below, run this verification before deleting:

```powershell
# Replace <FILENAME> with the file under check (no path, no extension)
rg "import.*<FILENAME>" lib/
```

If output is empty → safe to delete. If not → stop and report.

Deletion order (each is independent):

- [ ] `lib/screens/home_page.dart`
- [ ] `lib/screens/week_view_screen_demo.dart`
- [ ] `lib/widgets/events_list_widget.dart`
- [ ] `lib/widgets/event_categories.dart`
- [ ] `lib/services/firebase_service.dart`
- [ ] `lib/main_firebase.dart`
- [ ] `lib/main_demo.dart`

After each delete: `flutter analyze` → 0 errors.

**Hold** `lib/theme/theme.dart` until 1.3 is done (palette merge first).

## 1.2 Port AddEventSheet feature parity

The production sheet lacks features the demo has. Port these into `lib/widgets/add_event_sheet.dart`:

- [ ] **Category picker** — horizontal scrollable chips (source: `add_event_sheet_demo.dart:160-179`). Place between AI Quick Add section and the title field.
- [ ] **Location field** — `TextFormField` with `Icons.place_outlined`. Pass to `Event` constructor (add `String? location` to `Event` if missing — but defer model change to Phase 2).
- [ ] **Reminder switch** — `SwitchListTile` bound to `Event.reminderEnabled`.
- [ ] **Quick-time chips** — Morning (09:00) / Afternoon (14:00) / Evening (18:00) / Night (21:00). Tapping fills the time picker.
- [ ] **Theme tokens** — replace `Color(0xFFFAFAFA)` at lines 296, 321, 343, 367 with `Theme.of(context).colorScheme.surfaceContainerHighest` (or equivalent existing token).

After all five: `flutter analyze` → 0 errors, then:

- [ ] Verify nothing else imports `add_event_sheet_demo.dart`:
  ```powershell
  rg "add_event_sheet_demo" lib/
  ```
- [ ] Delete `lib/widgets/add_event_sheet_demo.dart`.
- [ ] `flutter analyze` → 0 errors.

## 1.3 Single `AppTheme`

- [ ] Open `lib/theme/app_theme.dart` (the **keeper** — brown/earth palette).
- [ ] Open `lib/theme/theme.dart` (the **delete** — peach palette). Copy nothing — `app_theme.dart` is canonical.
- [ ] Open `lib/main.dart` and locate `_buildTheme()` at L153-209 and the inline category color map at L44-50.
- [ ] In `lib/theme/app_theme.dart`, add a `CategoryColors` ThemeExtension below the theme class:

  ```dart
  @immutable
  class CategoryColors extends ThemeExtension<CategoryColors> {
    const CategoryColors(this.values);
    final Map<String, Color> values;

    @override
    CategoryColors copyWith({Map<String, Color>? values}) =>
        CategoryColors(values ?? this.values);

    @override
    CategoryColors lerp(ThemeExtension<CategoryColors>? other, double t) {
      if (other is! CategoryColors) return this;
      return CategoryColors({
        for (final key in values.keys)
          key: Color.lerp(values[key], other.values[key], t) ?? values[key]!,
      });
    }
  }
  ```

  Use `String` as the key for now; switch to `EventCategory` enum in Phase 2.

- [ ] Wire defaults into the theme in `app_theme.dart`:
  ```dart
  static ThemeData get lightTheme => ThemeData(/* existing */).copyWith(
        extensions: [CategoryColors(defaultCategoryColors)],
      );
  ```
- [ ] In `lib/main.dart`: delete `_buildTheme()` (L153-209). Replace `theme: _buildTheme(...)` with `theme: AppTheme.lightTheme.copyWith(extensions: [CategoryColors(currentColors)])`.
- [ ] Delete inline `_defaultCategoryColors` at L44-50; import from `app_theme.dart` instead.
- [ ] Replace duplicate category color maps in these files (each: read via `Theme.of(context).extension<CategoryColors>()!.values[name]`):
  - [ ] `lib/screens/auth_screen.dart:57-63`
  - [ ] `lib/screens/settings_screen.dart:40-46`
  - [ ] `lib/widgets/event_card.dart:23-29`
  - [ ] `lib/screens/time_report_screen.dart:28-35`
  - [ ] `lib/screens/share_calendar_screen.dart:151-159`
  - [ ] `lib/screens/voice_templates_screen.dart:153-167`

- [ ] Delete `lib/theme/theme.dart`.
- [ ] `flutter analyze` → 0 errors.
- [ ] Run app, verify colors look correct on home + month + settings.

## 1.4 Single voice parser — `VoiceCommandService`

- [ ] Open `lib/services/voice_command_service.dart`. Confirm it has: `processCommand`, `parseAddEvent`, `parseMoveEvent`, `parseDeleteEvent`, `parseQuery`, `formatScheduleForSpeech`.
- [ ] Define a sealed return type at the top of the file:
  ```dart
  sealed class VoiceAction {
    const VoiceAction();
  }
  class VoiceShowAddEvent extends VoiceAction { const VoiceShowAddEvent(); }
  class VoiceMoveEvent extends VoiceAction {
    const VoiceMoveEvent(this.eventId, this.newTime);
    final String eventId;
    final DateTime newTime;
  }
  class VoiceDeleteEvent extends VoiceAction {
    const VoiceDeleteEvent(this.eventName);
    final String eventName;
  }
  class VoiceSpoken extends VoiceAction {
    const VoiceSpoken(this.text);
    final String text;
  }
  ```
- [ ] Refactor `processCommand` to return `VoiceAction` (drop the `MOVE_EVENT:id|...` string sentinels).
- [ ] In `lib/providers/voice_provider.dart`:
  - Inject `VoiceCommandService` via constructor.
  - Replace internal parsing with `voiceCommandService.processCommand(...)`.
  - At top of `processCommand`, check `voiceTemplateProvider.matchTemplate(text)` first; if hit → short-circuit to `addEvent`.
- [ ] In `lib/widgets/voice_assistant_button.dart`: delete the inline regex parser (L73-100). Replace with `await voiceProvider.processCommand(text)`. Dispatch the returned `VoiceAction` via switch.
- [ ] In `lib/providers/event_provider.dart`: delete `parseVoiceEvent` (L189-207) and `formatEventsForSpeech` (L179-187). Move TTS formatting to a static helper on `VoiceCommandService` or a new `lib/services/voice_command_formatter.dart`.
- [ ] Verify `VoiceProvider.initialize()` is called once in `main.dart` or at provider construction. If not, wire it.
- [ ] `flutter analyze` → 0 errors.
- [ ] Manual test: voice FAB on home screen should respond (or at least not crash silently). Phase 1 doesn't require voice to be perfect — just not regressed.

## Phase 1 commit

```powershell
git add -A
git status              # review
flutter analyze         # 0 errors required
git -c user.name="DayBrief Dev" -c user.email="dev@daybrief.app" commit -m "refactor: Phase 1 — delete dead code, unify theme and voice parser"
```

Do **not** push until told.

---

# Phase 2 — Architectural backbone (~2–3 days)

## 2.1 freezed models + `EventCategory` enum

- [ ] `flutter pub add freezed_annotation json_annotation`
- [ ] `flutter pub add --dev freezed json_serializable build_runner`
- [ ] Run `flutter pub get`.

### `lib/models/event.dart`

- [ ] Add `enum EventCategory { work, personal, health, social, shopping, other }` above the class. Serialize via `.name` (not `.index`).
- [ ] Replace class body with freezed:
  ```dart
  @freezed
  class Event with _$Event {
    const factory Event({
      required String id,
      required String userId,
      required String title,
      required DateTime dateTime,
      String? description,
      String? location,
      EventCategory? category,
      @Default(false) bool reminderEnabled,
      RecurrenceType? recurrenceType,
    }) = _Event;

    factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
  }
  ```
- [ ] Add a top-level helper `DateTime _parseEventDateTime(dynamic raw)` that handles `String`, `int` (ms), Firestore `Timestamp`, and `DateTime`. Use it in a custom `JsonConverter<DateTime, Object>` so freezed/json_serializable picks it up.
- [ ] For `RecurrenceType`: use `.name`-based serialization with a fallback to `RecurrenceType.none` when the string is unknown.
- [ ] Throw `FormatException` if `title` or `userId` is empty/null (no silent default empty strings).

### `lib/models/voice_template.dart`

- [ ] Same freezed treatment.
- [ ] Move `defaultTemplates` (L58-115) to a new file `lib/models/voice_template_defaults.dart`.
- [ ] Parse `defaultTime` (e.g. `"09:00"`) into `TimeOfDay` at construction.

### Codegen + cleanup

- [ ] Run `dart run build_runner build --delete-conflicting-outputs`.
- [ ] Verify generated files: `event.freezed.dart`, `event.g.dart`, `voice_template.freezed.dart`, `voice_template.g.dart`.
- [ ] Update all `Event(` constructor callsites to use named params (analyzer will guide you).
- [ ] Replace all `'Work'`/`'Personal'`/etc. string literals across the codebase with `EventCategory.work` etc. Switch sites should be exhaustive.
- [ ] Update `CategoryColors` ThemeExtension (from 1.3) to use `Map<EventCategory, Color>` instead of `Map<String, Color>`.
- [ ] `flutter analyze` → 0 errors.

## 2.2 Repository layer

Create these files (each ~30–80 LOC, thin wrappers):

- [ ] `lib/repositories/auth_repository.dart` — wraps `FirebaseAuth`. Methods: `signIn`, `signUp`, `signOut`, `currentUser`, `authStateChanges`.
- [ ] `lib/repositories/event_repository.dart` — wraps Firestore + `LocalEventStore`. Branches on auth state internally. Methods: `watchEvents(userId)`, `addEvent(Event)`, `updateEvent(Event)`, `deleteEvent(id)`.
- [ ] `lib/repositories/voice_template_repository.dart` — wraps SharedPreferences. Methods: `load`, `save(List<VoiceTemplate>)`.
- [ ] Stub files for Phase 3 (empty classes for now, just so DI is consistent):
  - `lib/repositories/family_repository.dart`
  - `lib/repositories/poll_repository.dart`
  - `lib/repositories/share_calendar_repository.dart`

### Wire into providers

- [ ] `AuthProvider` accepts `AuthRepository` via constructor; remove direct `FirebaseAuth.instance` usage.
- [ ] `EventProvider` accepts `EventRepository` + `AuthRepository`; subscribes to `authStateChanges` from `AuthRepository` only.
- [ ] `VoiceTemplateProvider` accepts `VoiceTemplateRepository`.
- [ ] Update `lib/main.dart` MultiProvider:
  ```dart
  MultiProvider(
    providers: [
      Provider(create: (_) => AuthRepository()),
      Provider(create: (_) => EventRepository()),
      // ...
      ChangeNotifierProvider(create: (ctx) => AuthProvider(ctx.read<AuthRepository>())),
      ChangeNotifierProxyProvider2<AuthRepository, EventRepository, EventProvider>(
        create: (ctx) => EventProvider(ctx.read<AuthRepository>(), ctx.read<EventRepository>()),
        update: (_, auth, events, prev) => prev ?? EventProvider(auth, events),
      ),
      // ...
    ],
  )
  ```
- [ ] **Eliminate duplicate auth listener** at `lib/providers/event_provider.dart:28-35`. `EventProvider` now reacts to its injected `AuthRepository` only.
- [ ] `flutter analyze` → 0 errors.

## 2.3 Provider lifecycle fixes

- [ ] `lib/providers/auth_provider.dart:16-19`: store `StreamSubscription` in field; `@override void dispose() { _sub?.cancel(); super.dispose(); }`.
- [ ] `lib/providers/event_provider.dart:28-35`: same `dispose()` pattern.
- [ ] `lib/providers/event_provider.dart` sign-out: synchronously set `_events = []; notifyListeners();` **before** `_loadLocalEvents()`.
- [ ] `lib/providers/voice_provider.dart:72-74`: add `@override` and `super.dispose()` (already partially done in Phase 0 — verify).
- [ ] Make list getters immutable everywhere: `List<Event> get events => List.unmodifiable(_events);` and same for templates.
- [ ] `flutter analyze` → 0 errors.

## 2.4 `AsyncValue<T>`

- [ ] Create `lib/utils/async_value.dart`:
  ```dart
  sealed class AsyncValue<T> { const AsyncValue(); }
  class AsyncIdle<T> extends AsyncValue<T> { const AsyncIdle(); }
  class AsyncLoading<T> extends AsyncValue<T> { const AsyncLoading(); }
  class AsyncData<T> extends AsyncValue<T> {
    const AsyncData(this.value);
    final T value;
  }
  class AsyncError<T> extends AsyncValue<T> {
    const AsyncError(this.error, [this.stackTrace]);
    final Object error;
    final StackTrace? stackTrace;
  }
  ```
- [ ] Replace `bool isLoading + String? error` pairs in `EventProvider`, `AuthProvider`, `VoiceProvider` with `AsyncValue<T>`.
- [ ] Update UI sites to `switch (state) { AsyncLoading() => ..., AsyncError(:final error) => ..., AsyncData(:final value) => ..., AsyncIdle() => ... }`.
- [ ] Pay special attention to surfacing `EventProvider.error` — currently set but never shown.
- [ ] `flutter analyze` → 0 errors.

## 2.5 go_router

- [ ] `flutter pub add go_router`
- [ ] Create `lib/router/app_router.dart`:
  ```dart
  final appRouter = GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final auth = context.read<AuthProvider>();
      final loggingIn = state.matchedLocation == '/auth';
      if (!auth.isAuthenticated && !loggingIn) return '/auth';
      if (auth.isAuthenticated && loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const DayView()),
          GoRoute(path: '/week', builder: (_, __) => const WeekViewScreen()),
          GoRoute(path: '/month', builder: (_, __) => const MonthViewScreen()),
        ],
      ),
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/driving', builder: (_, __) => const DrivingModeScreen()),
      GoRoute(path: '/calendar-sync', builder: (_, __) => const CalendarSyncScreen()),
      GoRoute(path: '/voice-templates', builder: (_, __) => const VoiceTemplatesScreen()),
      GoRoute(path: '/family', builder: (_, __) => const FamilyCalendarScreen()),
      GoRoute(path: '/share', builder: (_, __) => const ShareCalendarScreen()),
      GoRoute(
        path: '/poll/:pollId',
        builder: (_, state) => QuickPollScreen(pollId: state.pathParameters['pollId']),
      ),
      GoRoute(path: '/time-report', builder: (_, __) => const TimeReportScreen()),
      GoRoute(path: '/shared/:code', builder: (_, state) => SharedCalendarViewScreen(code: state.pathParameters['code']!)),
    ],
  );
  ```
- [ ] Build a `HomeShell` widget that holds the bottom nav (Day/Week/Month) and renders `child` in an `IndexedStack`-like container. **This fixes the view-selector push-stack bug.**
- [ ] In `lib/main.dart`: replace `MaterialApp(home: ...)` with `MaterialApp.router(routerConfig: appRouter)`. Delete the `Consumer<AuthProvider>` auth gate — redirect handles it.
- [ ] Replace every `Navigator.push(MaterialPageRoute(...))` with `context.go(...)` or `context.push(...)`. There are 13 sites — analyzer will find them after MaterialApp.router lands.
- [ ] Fix the `Navigator.pop(context); Navigator.push(...)` anti-pattern at `lib/screens/settings_screen.dart:150-184` — becomes `context.go(...)`.
- [ ] Drop dead constructor params: `TimeReportScreen.events`, `ShareCalendarScreen.events`, `FamilyCalendarScreen.onAddEvent`, `MonthViewScreen.events`. Screens read from `EventProvider` directly.
- [ ] `flutter analyze` → 0 errors.

## Phase 2 commit

```powershell
flutter analyze
git add -A
git -c user.name="DayBrief Dev" -c user.email="dev@daybrief.app" commit -m "refactor: Phase 2 — freezed models, repositories, AsyncValue, go_router"
```

---

# Phase 3 — Feature completion (~2–3 days)

## 3.1 Wire `CalendarSyncScreen`

- [ ] Remove unused import `package:url_launcher/url_launcher.dart` at L4.
- [ ] Drop constructor params (events, onImport). Read from `EventProvider`.
- [ ] Import callback becomes `for (final e in imported) await eventProvider.addEvent(e);`.
- [ ] Add a "Calendar & Sync" section in `lib/screens/settings_screen.dart` between Notifications and Analytics. Add a nav tile `Sync` → `context.go('/calendar-sync')`.
- [ ] `flutter analyze` → 0 errors.

## 3.2 Wire `VoiceTemplatesScreen`

- [ ] In `lib/screens/settings_screen.dart`, add nav tile as the **first row** of the existing "Voice Assistant" section → `context.go('/voice-templates')`.
- [ ] `flutter pub add uuid`
- [ ] Replace `millisecondsSinceEpoch` IDs at L259 with `const Uuid().v4()`.
- [ ] Add an **edit flow**: tap a template → opens the same form pre-filled → save calls `updateTemplate`.
- [ ] `flutter analyze` → 0 errors.

## 3.3 Family calendar — real backend

### Firestore

- [ ] Add to `firestore.rules`:
  ```
  match /families/{familyId} {
    allow read: if request.auth != null && exists(/databases/$(database)/documents/families/$(familyId)/members/$(request.auth.uid));
    allow create: if request.auth != null && request.resource.data.ownerId == request.auth.uid;
    allow update, delete: if request.auth != null && resource.data.ownerId == request.auth.uid;

    match /members/{uid} {
      allow read: if request.auth != null && exists(/databases/$(database)/documents/families/$(familyId)/members/$(request.auth.uid));
      allow write: if request.auth != null && get(/databases/$(database)/documents/families/$(familyId)).data.ownerId == request.auth.uid;
    }

    match /events/{eventId} {
      allow read, write: if request.auth != null && exists(/databases/$(database)/documents/families/$(familyId)/members/$(request.auth.uid));
    }
  }
  ```

### Code

- [ ] `lib/repositories/family_repository.dart` — methods:
  - `Future<String> createFamily({required String name})`
  - `Future<void> joinFamily({required String inviteCode})`
  - `Future<void> inviteMember({required String familyId, required String email})`
  - `Stream<List<Event>> watchFamilyEvents(String familyId)`
  - `Future<void> addFamilyEvent(String familyId, Event event)`
  - `Future<void> removeFamilyEvent(String familyId, String eventId)`
- [ ] `lib/providers/family_provider.dart` — wraps repo, exposes `AsyncValue` state.
- [ ] Register in MultiProvider.
- [ ] Refactor `lib/screens/family_calendar_screen.dart`:
  - Delete hardcoded `_familyMembers` (L15-19) and `_familyEvents` (L21-25).
  - Wire to `FamilyProvider`.
  - Implement "Send Invite" button (L182) — calls `inviteMember`.
  - Implement add-event handler (L255-262) — calls `addFamilyEvent`.
- [ ] `flutter analyze` → 0 errors.

## 3.4 Share calendar — real backend

### Firestore

- [ ] Add to `firestore.rules`:
  ```
  match /share_codes/{code} {
    allow read: if true;  // public link
    allow create: if request.auth != null && request.resource.data.ownerId == request.auth.uid;
    allow update, delete: if request.auth != null && resource.data.ownerId == request.auth.uid;
  }
  ```

### Code

- [ ] `lib/services/share_calendar_service.dart` + `lib/repositories/share_calendar_repository.dart` — methods:
  - `Future<String> createShareCode({Duration? ttl})`
  - `Future<void> revokeShareCode(String code)`
  - `Stream<List<Event>> watchSharedEvents(String code)`
- [ ] Generate codes with `uuid` v4 (collision-safe) instead of timestamp-base36 at `share_calendar_screen.dart:24-32`.
- [ ] Add `share_plus` integration (already in pubspec) for the share button.
- [ ] New screen `lib/screens/shared_calendar_view_screen.dart` for the `/shared/:code` route (viewer flow).
- [ ] `flutter analyze` → 0 errors.

## 3.5 Quick poll — real backend

### Firestore

- [ ] Add to `firestore.rules`:
  ```
  match /polls/{pollId} {
    allow read: if true;
    allow create: if request.auth != null && request.resource.data.createdBy == request.auth.uid;
    allow update, delete: if request.auth != null && resource.data.createdBy == request.auth.uid;

    match /options/{optionId} { allow read: if true; allow write: if request.auth != null; }
    match /votes/{voteId}     { allow read: if true; allow create: if true; allow update, delete: if false; }
  }
  ```

### Code

- [ ] `lib/services/poll_service.dart` + `lib/providers/poll_provider.dart`. Methods:
  - `Future<String> createPoll({required String title, required List<DateTime> options})`
  - `Future<void> castVote({required String pollId, required String optionId, required String voterName})`
  - `Stream<PollWithResults> watchPoll(String pollId)`
- [ ] Refactor `lib/screens/quick_poll_screen.dart`:
  - Replace in-memory `_options` (L13-17) with the stream.
  - Persist `_titleController` value.
  - Add a share button to invite voters (uses `share_plus`).
- [ ] `/poll/:pollId` route renders shared poll for participants.
- [ ] `flutter analyze` → 0 errors.

## 3.6 SpeechService hardening

- [ ] In `lib/services/speech_service.dart`:
  - Wire `onStatus` callback (L18-19): on `'done'` or `'notListening'` reset `_isListening = false` and invoke `onListeningStopped`.
  - Add `finally { _isListening = false; }` block in `startListening` after L71.
  - In `initialize()`: `await Permission.microphone.request();` (uses existing `permission_handler`).
  - Accept `String languageCode` param; set `'ro-RO'` or `'en-US'` based on locale.
- [ ] Add to `ios/Runner/Info.plist`:
  ```xml
  <key>NSMicrophoneUsageDescription</key>
  <string>DayBrief needs microphone access for voice commands and driving mode.</string>
  <key>NSSpeechRecognitionUsageDescription</key>
  <string>DayBrief uses speech recognition to understand your schedule commands.</string>
  ```

## 3.7 LocalEventStore user scoping

- [ ] Rename `lib/services/database_service.dart` → `lib/services/local_event_store.dart`. Rename the class accordingly.
- [ ] Key scheme: `daybrief_events_$userId`. Anonymous user → `daybrief_events_anonymous`.
- [ ] Add `setActiveUser(String? userId)`; called from `AuthProvider` state changes.
- [ ] One-time migration: on first read, if `daybrief_events` (legacy) exists, copy to the current user's key and delete the legacy key.
- [ ] Keep SharedPreferences. Do **not** add sqflite.
- [ ] Update imports across `lib/`.
- [ ] `flutter analyze` → 0 errors.

## 3.8 GoogleCalendarService fixes

- [ ] L17-20: null-check `signInResult`; return `bool` (`false` on cancel).
- [ ] L12: delete `_accessToken` field. Fetch `(await _currentUser!.authHeaders)` per request (auto-refreshes).
- [ ] `flutter pub add flutter_timezone`.
- [ ] L59, L63: replace hardcoded `'UTC'` with `await FlutterTimezone.getLocalTimezone()`.
- [ ] L79-81: add helper `String _escapeIcs(String input)` per RFC 5545 — escape `\\`, `\n`, `;`, `,`. Apply to SUMMARY + DESCRIPTION fields.
- [ ] `flutter analyze` → 0 errors.

## 3.9 Settings persistence

- [ ] Create `lib/providers/settings_provider.dart` keyed under `settings_*` in SharedPreferences.
- [ ] Replace UI-only `setState` toggles (14 of 22 rows) with `settingsProvider.set(...)`.
- [ ] Wire notification toggles to a no-op service for now (real scheduling out of scope).
- [ ] Delete the dead "Smart Shortcuts" toggle at L159 (empty `(value) {}` handler).
- [ ] Add Sign Out tile in an "Account" section — calls `authProvider.signOut()`.
- [ ] `flutter analyze` → 0 errors.

## 3.10 i18n with gen-l10n

- [ ] Add to `pubspec.yaml`:
  ```yaml
  dependencies:
    flutter_localizations:
      sdk: flutter
  flutter:
    generate: true
  ```
- [ ] Create `l10n.yaml`:
  ```yaml
  arb-dir: lib/l10n
  template-arb-file: app_en.arb
  output-localization-file: app_localizations.dart
  ```
- [ ] Create `lib/l10n/app_en.arb` and `lib/l10n/app_ro.arb`.
- [ ] Extract priority strings first:
  - [ ] `lib/screens/home_screen.dart` empty state (L559-574) + bottom nav labels (L630-647)
  - [ ] `lib/screens/driving_mode_screen.dart` (~32 strings; fix `Urmatorul` → `Următorul` at L161; fix lone English string at L138)
- [ ] In `lib/services/speech_service.dart:23,90`: set TTS locale dynamically (`ro-RO` vs `en-US`) based on `Localizations.localeOf(context)`.
- [ ] Add Language picker in `lib/screens/settings_screen.dart` under Appearance. Persist via `SettingsProvider`.
- [ ] In `MaterialApp.router`: set `locale`, `localizationsDelegates: AppLocalizations.localizationsDelegates`, `supportedLocales: const [Locale('en'), Locale('ro')]`.
- [ ] In `main()`: `await initializeDateFormatting('en_US'); await initializeDateFormatting('ro_RO');`.
- [ ] Replace hardcoded `'en_US'` in `home_screen.dart:454-465` with `Localizations.localeOf(context).toString()`.
- [ ] `flutter analyze` → 0 errors.

## Phase 3 commit

```powershell
flutter analyze
git add -A
git -c user.name="DayBrief Dev" -c user.email="dev@daybrief.app" commit -m "feat: Phase 3 — wire orphans, complete stub screens, hardening, i18n"
```

---

# Phase 4 — Hardening & polish (~1–2 days)

## 4.1 Accessibility

- [ ] Wrap header buttons in `lib/screens/home_screen.dart:342-366` with `Semantics(button: true, label: '...')`. Enforce 48dp min via `SizedBox(width: 48, height: 48)`.
- [ ] Add `tooltip:` to every `IconButton` in: `home_screen.dart`, `week_view_screen.dart`, `month_view_screen.dart`, `auth_screen.dart`, `voice_templates_screen.dart`.
- [ ] In `lib/screens/auth_screen.dart`:
  - Wrap email + password fields in `AutofillGroup`.
  - Set `autofillHints: const [AutofillHints.email]` on email, `[AutofillHints.password]` on password, `[AutofillHints.givenName]` on name, `[AutofillHints.familyName]` on surname.
  - Replace `value.contains('@')` validator with a proper email regex.
- [ ] Bottom nav at `home_screen.dart:662-686`: 48dp min height + `Semantics(selected: isActive, label: '...')`.
- [ ] Replace hardcoded `fontSize:` literals with `Theme.of(context).textTheme.*` (supports system text scaling).
- [ ] `flutter analyze` → 0 errors.

## 4.2 Tests — first wave

- [ ] `flutter pub add --dev mocktail`
- [ ] Create test files:
  - `test/models/event_test.dart` — `fromJson`/`toJson` round-trip; malformed `dateTime` (`String`, `Timestamp`, `int`); out-of-range `RecurrenceType`; `copyWith` semantics.
  - `test/services/local_event_store_test.dart` — user scoping isolation; legacy key migration.
  - `test/services/google_calendar_service_test.dart` — local timezone; ICS escaping round-trip; cancelled sign-in returns false.
  - `test/services/voice_command_service_test.dart` — wake-word detection; intent routing; move/delete parsing.
  - `test/providers/event_provider_test.dart` — `getEventsForDay` across midnight boundary.
  - `test/repositories/auth_repository_test.dart` — sign-in/out happy path with mocked `FirebaseAuth`.
- [ ] Run `flutter test` after each file. All green before committing.
- [ ] Target: ~30 tests covering highest-risk units.

## 4.3 Logger + analyzer tightening

- [ ] Create `lib/utils/logger.dart`:
  ```dart
  import 'dart:developer' as developer;
  class DayBriefLog {
    static void debug(String msg, {Object? error, StackTrace? st}) =>
        developer.log(msg, name: 'daybrief', level: 500, error: error, stackTrace: st);
    static void info(String msg) => developer.log(msg, name: 'daybrief', level: 800);
    static void warning(String msg, {Object? error}) =>
        developer.log(msg, name: 'daybrief', level: 900, error: error);
    static void error(String msg, {required Object error, StackTrace? st}) =>
        developer.log(msg, name: 'daybrief', level: 1000, error: error, stackTrace: st);
  }
  ```
- [ ] Replace all `print()` / `debugPrint()` calls (15+ across services and `main.dart`) with `DayBriefLog.*`.
- [ ] Update `analysis_options.yaml`:
  ```yaml
  include: package:flutter_lints/flutter.yaml
  analyzer:
    language:
      strict-casts: true
  linter:
    rules:
      avoid_print: true
      prefer_const_constructors: true
      unawaited_futures: true
      use_build_context_synchronously: true
      always_declare_return_types: true
  ```
- [ ] `flutter analyze` — fix any new errors (info-level lint hints can be batched).

## 4.4 Documentation refresh

- [ ] Replace `README.md` (currently default Flutter template) with a real project overview (name, what it does, quick start, link to `SETUP.md`).
- [ ] `SETUP.md` — already updated in Phase 0; verify it still matches.
- [ ] Reconcile `DOCUMENTATION.md`:
  - Remove SQLite / mock-auth claims.
  - Drop deleted files from the file tree (`firebase_service.dart`, `theme.dart`, `add_event_sheet_demo.dart`, etc.).
  - Document `VoiceCommandService` as canonical voice router.
- [ ] Fix `create_icons.ps1:3` — replace hardcoded path `C:\Users\Mircea\Desktop\cal2.0\...` with a parameter or relative path.
- [ ] Update `set_java_home.ps1` to JDK 17 (matches Gradle 8.x), not JDK 25.

## Phase 4 commit

```powershell
flutter test
flutter analyze
git add -A
git -c user.name="DayBrief Dev" -c user.email="dev@daybrief.app" commit -m "chore: Phase 4 — a11y, tests, logger, docs refresh"
```

---

# Push

Only when the user says "push":

```powershell
git push origin master
```

---

# Definition of Done (whole remediation)

- [ ] All 4 phases committed (4 commits at minimum, more is fine if split sensibly).
- [ ] `flutter analyze` reports **0 errors**.
- [ ] `flutter test` passes all tests.
- [ ] App runs cleanly on Chrome (`flutter run -d chrome`) — sign in, add event, delete event, switch views, change language.
- [ ] `docs/REMEDIATION-PLAN.md`, `docs/DETAILED-PLAN.md`, and `.cursor/rules/phase-execution.mdc` still match reality (update them if the plan diverged).

If anything in the plan is ambiguous or impossible: **stop and ask**. Do not invent.
