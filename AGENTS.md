# DayBrief — agent instructions

Flutter calendar assistant with voice commands, Firebase auth, and Provider state management.

## Commands

```bash
flutter pub get
flutter analyze          # must be clean before commits
flutter test
flutter run
dart run build_runner build --delete-conflicting-outputs   # after Freezed/JSON model changes
dart format lib test
```

## Lint strategy (important)

**Do not copy lint rules into markdown.** Style and Flutter patterns are enforced by the analyzer:

- Today: `flutter_lints` + strict rules in `analysis_options.yaml`
- After upgrading to **Dart 3.10+ / Flutter 3.38+**: enable `many_lints` in `analysis_options.yaml` (see commented block). That package ships ~100 Flutter/Dart rules with quick fixes—see https://nikoro.github.io/many_lints

When writing or reviewing Dart code:

1. Run `flutter analyze` and fix all issues.
2. Prefer analyzer quick fixes over hand-rolled rewrites.
3. Suppress a rule only with `// ignore: rule_name` and a one-line reason.

## Architecture

```
lib/
  main.dart                 # app entry, MultiProvider setup
  models/                   # Freezed + json_serializable (Event, VoiceTemplate)
  providers/                # ChangeNotifier + Provider (not BLoC/Riverpod)
  services/                 # Firebase, speech, calendar, Claude API, DB
  screens/                  # full-page routes
  widgets/                  # reusable UI
  theme/                    # AppTheme
  utils/                    # helpers
  config/                   # app_config.example.dart (copy for secrets)
```

## Stack conventions

- **State**: `provider` — `ChangeNotifier` in `providers/`, expose via `context.watch` / `context.read`
- **Models**: `freezed` + `json_serializable`; run build_runner after changes
- **Firebase**: `firebase_options.dart`, `google-services.json` — do not regenerate or edit unless explicitly asked
- **Theme**: use `AppTheme` / `Theme.of(context)`; avoid hard-coded colors in widgets
- **Async in widgets**: check `mounted` before `setState` after awaits

## Code style (project-specific only)

- Match existing file patterns before introducing new abstractions
- Keep widgets small; extract when a `build` method grows hard to scan
- Prefer `const` constructors where the analyzer suggests them
- Use `Gap`-style spacing patterns only if already used in the file (until `many_lints` enforces `use_gap`)

## Remediation / phase work

For structured refactors, follow `.cursor/rules/phase-execution.mdc` and `docs/REMEDIATION-PLAN.md` when present.

## Locked / sensitive paths

Do not modify without explicit approval:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- Platform bundle IDs and signing config

## Gotchas

- `AppConfig` secrets: use `lib/config/app_config.dart` (gitignored), not the `.example` file
- Voice and calendar flows touch multiple providers—trace data flow before changing event shape
- Generated files: `*.freezed.dart`, `*.g.dart` — regenerate, do not hand-edit
