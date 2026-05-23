# DayBrief Architecture Decisions

Choices made during planning that the remediation plan depends on. Recorded here so future chats / contributors don't have to re-litigate them.

## 1. Claude API backend: extend `server.js`

**Decision:** Add a `/api/claude/*` proxy to the existing 55-line `server.js`. Zero new npm deps (uses Node builtins: `http`, `https`, `URL`). `ANTHROPIC_API_KEY` lives in `process.env`, never in client code.

**Alternatives considered:**
- Firebase Cloud Functions — works on mobile too, but requires bootstrapping Functions + billing infrastructure (no `firebase.json`, `.firebaserc`, or `functions/` folder exists today).
- Separate Node/Express backend — most flexible but biggest new surface area.
- Drop AI features — simplest, but loses the parse-event + daily-summary features actively used in `add_event_sheet.dart` and `home_screen.dart`.

**Rationale:** `server.js` is already the documented dev path for web (`SETUP.md` Step 4), uses zero npm deps, and Flutter web at `http://localhost:8080` calls the proxy same-origin (no CORS). Mobile gets a `kIsWeb` UI gate for v1; mobile AI requires a hosted proxy (deferred).

**Endpoint shape:** Domain endpoints (`/api/claude/parse-event`, `/daily-summary`, `/answer-question`, `/smart-suggestions`) rather than a generic passthrough. Server holds prompt templates, model, max_tokens, and version header. Client sends minimal JSON.

## 2. Orphan + stub screens policy: wire all, complete all

**Decision:** Wire up the 2 orphaned screens (`CalendarSyncScreen`, `VoiceTemplatesScreen`) AND complete the 3 stub screens with real Firestore backends (`FamilyCalendarScreen`, `ShareCalendarScreen`, `QuickPollScreen`).

**Alternatives considered:**
- Wire orphans, delete stubs — pragmatic 2-day cut.
- Delete all 6 — most aggressive, smallest surface.
- Status quo — just fix bugs in active core.

**Rationale:** User wants the full product. Cost is ~3–4 extra days in Phase 3 versus shipping faster. Each stub gets a focused Firestore schema (see Phase 3 in `REMEDIATION-PLAN.md`).

## 3. Bundle ID: `com.daybrief.app`

**Decision:** Unify all platforms on `com.daybrief.app`. Currently Android uses `com.daybrief.app`, iOS uses `com.voiscal.voiceCal`, Firebase iOS expects `com.example.dayBrief`, and Linux uses `com.voiscal.voice_cal`.

**Rationale:** Android already has it. Aligns with repo name (`daybrief`). Run `flutterfire configure` against `daybrief-d6bf6` to regenerate config files in lockstep.

**Migration impact:** Firebase Auth users tied to the old iOS bundle ID may need to re-authenticate.

## 4. Theme keeper: `app_theme.dart` (brown/earth palette)

**Decision:** Keep `lib/theme/app_theme.dart` (brown/cream/tan editorial palette). Delete `lib/theme/theme.dart` (peach/apricot warm palette). Delete the third inline theme in `lib/main.dart:153-209`.

**Rationale:** Brown palette is more cohesive across light/dark and reads as more "professional" for a calendar app. Both theme files are currently dead code (unimported); only the inline `_buildTheme()` in `main.dart` is actually rendered. User-customizable category colors move into a `ThemeExtension<CategoryColors>` so settings UI can still override them.

## 5. Voice command parser keeper: `VoiceCommandService`

**Decision:** Make `lib/services/voice_command_service.dart` (271 LOC, currently orphaned with 0 imports) the single voice intent router. Delete the duplicate parsers in `EventProvider.parseVoiceEvent` and the inline regex in `voice_assistant_button.dart`.

**Rationale:** `VoiceCommandService` is the only implementation covering move, delete, insights, date/time Q&A, and rich schedule TTS. The duplicates only overlap on "query schedule" and "add event" (with weaker parsing). The TTS side-channel pattern (`MOVE_EVENT:id|...`) gets replaced with a proper sealed `VoiceAction` return type.

## 6. State management: stay on Provider + ChangeNotifier

**Decision:** Don't migrate to Riverpod or Bloc. Keep `package:provider` (currently v6.1.2) and `ChangeNotifier`. Fix the lifecycle bugs (subscription leaks, missing dispose), introduce a small `AsyncValue<T>` sealed class for loading/error state, and move to `ChangeNotifierProxyProvider` for the auth-dependent providers.

**Rationale:** The 4-provider split is reasonable and not a god store. A framework migration would be expensive for marginal gain. The real issues (duplicate auth listeners, leaks, inconsistent error surfacing) are fixable within Provider.

## 7. Local storage: keep SharedPreferences (defer sqflite)

**Decision:** Rename `DatabaseService` → `LocalEventStore`. Keep SharedPreferences as the backend; key scheme `daybrief_events_$userId`. The `sqflite` package (currently unused despite being in `pubspec.yaml`) gets removed.

**Rationale:** Current CRUD loads the entire list into memory anyway; no complex queries; fastest path to fix the user-data-leak bug (currently all users share one global key). Defer sqflite until per-field updates, full-text search, or >1000 events per user are needed.

## 8. i18n: built-in `gen-l10n` with en + ro

**Decision:** Use Flutter's built-in `gen-l10n` with ARB files (`lib/l10n/app_en.arb`, `lib/l10n/app_ro.arb`). Add a Language picker in settings. Persist locale via SharedPreferences.

**Alternatives considered:**
- `intl_utils` — adds codegen + dev dep, redundant when `gen-l10n` is built-in.
- `easy_localization` — JSON/asset-based, third-party API, overkill for 2 locales.

**Rationale:** ~400 user-facing strings across 22 files. Built-in tooling, no extra deps, plural/gender support, works with existing `intl` package. Locale also drives TTS language in `SpeechService` (currently hardcoded `en-US`).

## 9. Routing: `go_router`

**Decision:** Add `go_router`. Create `lib/router/app_router.dart` with `ShellRoute` wrapping Day/Week/Month in an `IndexedStack`. Replace all 13 `Navigator.push(MaterialPageRoute(...))` sites.

**Rationale:** Fixes the view-selector bug at `home_screen.dart:191-200` where Week/Month push new routes while Day content remains underneath. Eliminates the `Navigator.pop` → `Navigator.push` anti-pattern in `settings_screen.dart:150-184`. Sets up deep linking and `/shared/:code` viewer routes for Phase 3 features.

## 10. Models: `freezed` + `json_serializable`

**Decision:** Migrate `Event` and `VoiceTemplate` to `freezed`. Introduce `enum EventCategory { work, personal, health, social, shopping, other }` with `String name` serialization (not `.index`).

**Rationale:** Fixes in one pass: missing `==`/`hashCode`, the `RecurrenceType.values[index]` crash on enum reorder (L56), the `DateTime.parse` crash on Firestore `Timestamp` (L49), and the inability to set nullable fields to `null` via `copyWith`. Eliminates the ~40 hardcoded `'Work'`/`'Personal'` string literals scattered across the codebase by making them an enum (switch-exhaustive).

## 11. Repository pattern: yes, lightweight

**Decision:** Introduce `lib/repositories/` with thin wrappers (`AuthRepository`, `EventRepository`, `LocalEventStore`, etc.). Providers accept repositories via constructor instead of instantiating `FirebaseAuth.instance` / `DatabaseService()` directly.

**Rationale:** Makes the providers testable (mockable repositories instead of mocking Firebase plugins). Consolidates the duplicate auth listener (currently in both `AuthProvider` and `EventProvider`) by making `EventProvider` a `ChangeNotifierProxyProvider2<AuthRepository, EventRepository, EventProvider>`.

## 12. Tests: `mocktail` over `mockito`

**Decision:** Add `mocktail` to dev_deps for first wave of tests. Skip `mockito`.

**Rationale:** `mocktail` requires no codegen (`build_runner` is already needed for `freezed` — no need to add more codegen for mocks). Works well with Provider + manual repository injection. Sufficient for mocking `SharedPreferences`, `FirebaseAuth`, `SpeechToText`.

---

## Decisions deferred

- **Hosted Claude proxy for mobile** — Phase 0 ships with `kIsWeb` UI gates; mobile AI is web-only until a hosted backend exists.
- **Real release signing for Android** — needed before store submission but not for dev.
- **`GoogleService-Info.plist` for iOS** — needed when first running on iOS simulator/device; download from Firebase Console after `flutterfire configure`.
- **Notification scheduling** — `SettingsProvider` persists the toggles but the actual reminder system is out of scope for this remediation.
- **Crash reporting (Crashlytics/Sentry)** — `DayBriefLog` is designed with a future sink hook but no integration in v1.
