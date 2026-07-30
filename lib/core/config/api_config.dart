/// Backend connection settings.
///
/// Both values are provided at build/run time via `--dart-define` so that a
/// key is never committed to source. Local development can leave them blank —
/// [SeenRepository] will fall back to a fully offline pipeline when
/// [ApiConfig.isConfigured] is false, so the whole demo remains playable.
///
/// Example:
///   flutter run \
///     --dart-define=SEEN_API_BASE_URL=https://seen-backend-func-32653.azurewebsites.net/api \
///     --dart-define=SEEN_API_FUNCTION_KEY=`your-function-key`
class ApiConfig {
  const ApiConfig({required this.baseUrl, required this.functionKey});

  final String baseUrl;
  final String functionKey;

  static const _baseUrl =
      String.fromEnvironment('SEEN_API_BASE_URL', defaultValue: '');
  static const _functionKey =
      String.fromEnvironment('SEEN_API_FUNCTION_KEY', defaultValue: '');

  factory ApiConfig.fromEnvironment() =>
      const ApiConfig(baseUrl: _baseUrl, functionKey: _functionKey);

  bool get isConfigured => baseUrl.isNotEmpty && functionKey.isNotEmpty;
}
