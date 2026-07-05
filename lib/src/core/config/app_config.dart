/// App-wide configuration. Override the API base URL at build time with
/// `--dart-define=API_BASE_URL=...`.
class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8087/api/v1',
  );
}
