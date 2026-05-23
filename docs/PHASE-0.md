# Phase 0 — Complete

Security fixes and broken production paths. Safe to demo without an Anthropic API key.

## Checklist

| Item | Status |
|------|--------|
| 0.1 Claude proxy in `server.js` + `claude_service.dart` rewrite | Done |
| 0.1 `app_config.example.dart` + `SETUP.md` (env var, no client key) | Done |
| 0.1 AI UI gated to web (`kIsWeb`) | Done |
| 0.2 Auth: removed `pushReplacement` bypass | Done |
| 0.3 Month view: real `AddEventSheet` + `deleteEvent` | Done |
| 0.4 `VoiceTemplateProvider` in `MultiProvider` | Done |
| 0.5 Bundle ID `com.daybrief.app` (Android, iOS, macOS, Linux, web, firebase_options) | Done |
| 0.5 iOS display name `DayBrief` in `Info.plist` | Done |
| 0.6 `firebase.json`, `.firebaserc`, `firestore.rules`, `firestore.indexes.json` | Done |
| `flutter analyze` — 0 errors | Done |

## Deferred (not blocking Phase 0)

- **`flutterfire configure`** on a machine with Firebase CLI login — regenerates `firebase_options.dart` / iOS `GoogleService-Info.plist` against `daybrief-d6bf6`. Do on Mac when testing iOS.
- **Deploy Firestore rules:** `firebase deploy --only firestore:rules` (requires Firebase CLI + project access).
- **Anthropic API key** — optional; AI features only when `ANTHROPIC_API_KEY` is set and app is served via `node server.js`.
- **Rotate old API key** if one was ever committed in local `app_config.dart`.

## How to run (no API key)

```powershell
cd daybrief
flutter pub get
flutter run -d chrome
```

## Next session

Paste the prompt from **`docs/CONTINUE-PHASES.md`** to start Phases 1–4.
