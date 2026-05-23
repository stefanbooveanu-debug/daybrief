/// Copy this file to `app_config.dart` if older tooling still expects it.
/// Claude calls now go through `server.js` — set `ANTHROPIC_API_KEY` in the
/// environment before running `node server.js`.
class AppConfig {
  /// Optional override when testing against a remote proxy, e.g.
  /// `http://localhost:8080`. Leave empty for same-origin `/api/claude/*`.
  static const String claudeApiBase = '';
}
