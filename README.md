# DayBrief

Flutter calendar assistant with voice commands, Firebase auth, and Provider state management.

DayBrief helps you manage a daily schedule: add/edit/delete events, switch Day/Week/Month views, sync with Google Calendar / ICS, share calendars, run quick polls, and use voice templates (web AI features via a local Node proxy).

## Quick start

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

For the full setup (Firebase, `ANTHROPIC_API_KEY`, `node server.js`, platform notes), see **[SETUP.md](SETUP.md)**.

## Architecture (short)

```
lib/
  main.dart          # MultiProvider + MaterialApp.router
  models/            # Freezed Event, VoiceTemplate, Family
  providers/         # ChangeNotifier state
  repositories/      # Auth, Event, Family, Poll, Share…
  services/          # Claude proxy client, speech, Google Calendar, LocalEventStore
  router/            # go_router + HomeShell
  screens/           # full-page routes
  l10n/              # gen-l10n (en / ro)
```

## Commands

| Command | Purpose |
|---------|---------|
| `flutter analyze` | Must be clean before commits |
| `flutter test` | Unit + widget tests |
| `dart run build_runner build --delete-conflicting-outputs` | After Freezed/JSON model changes |
| `node server.js` | Serve web build + Claude API proxy |

## Docs

- [SETUP.md](SETUP.md) — run on another machine
- [DOCUMENTATION.md](DOCUMENTATION.md) — product/history notes
- [docs/REMEDIATION-PLAN.md](docs/REMEDIATION-PLAN.md) — phased cleanup plan
