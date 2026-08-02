import 'package:flutter/foundation.dart';

/// Base URL for DayBrief `server.js` API routes (`/api/claude/*`, `/api/places/*`).
///
/// - Production web build served by `node server.js` → same-origin (empty).
/// - `flutter run -d chrome` → defaults to local proxy on port 8080.
/// - Override with `--dart-define=DAYBRIEF_API_BASE=http://127.0.0.1:8080`
///   or `--dart-define=CLAUDE_API_BASE=...`.
class ApiBase {
  ApiBase._();

  static String get value {
    const claude = String.fromEnvironment('CLAUDE_API_BASE');
    if (claude.isNotEmpty) return claude;
    const daybrief = String.fromEnvironment('DAYBRIEF_API_BASE');
    if (daybrief.isNotEmpty) return daybrief;
    if (kIsWeb && kDebugMode) return 'http://127.0.0.1:8080';
    return '';
  }

  static Uri uri(String path, [Map<String, String>? query]) {
    final base = value;
    if (base.isNotEmpty) {
      return Uri.parse('$base$path').replace(queryParameters: query);
    }
    return Uri(path: path, queryParameters: query);
  }
}
