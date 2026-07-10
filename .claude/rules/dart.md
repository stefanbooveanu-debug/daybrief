---
paths:
  - "**/*.dart"
  - "!**/*.g.dart"
  - "!**/*.freezed.dart"
---

# Dart / Flutter rules (scoped)

These apply when editing hand-written Dart source. Generated `*.g.dart` and `*.freezed.dart` are excluded.

## Analyzer is the source of truth

- Run `flutter analyze` after substantive edits.
- When `many_lints` is enabled, treat its diagnostics as mandatory unless explicitly suppressed.
- Do not restate the full many_lints catalog here—browse https://nikoro.github.io/many_lints when unsure.

## Provider (this project)

- Business logic belongs in `ChangeNotifier` classes under `lib/providers/`, not in `build` methods.
- Use `context.read<T>()` for one-off actions; `context.watch<T>()` when the widget must rebuild.
- Do not introduce BLoC, Riverpod, or GetX unless explicitly requested.

## Widgets

- Prefer `StatelessWidget` when there is no local ephemeral state.
- Dispose controllers, listeners, and subscriptions in `dispose()`.
- After `await` in `State`, guard with `if (!mounted) return;` before `setState` or navigation.

## Models

- Use existing Freezed patterns in `lib/models/`.
- After model field changes: `dart run build_runner build --delete-conflicting-outputs`.

## Testing

- Tests live in `test/` mirroring `lib/` layout.
- Use `mocktail` for mocks; prefer testing real parsing/logic over mocked everything.
