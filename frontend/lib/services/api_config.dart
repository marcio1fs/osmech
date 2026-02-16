/// Configurações globais da API.
class ApiConfig {
  /// URL base da API. Pode ser definida via --dart-define=API_URL=...
  /// Default: localhost para desenvolvimento.
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8081/api',
  );

  // Timeout padrão em segundos
  static const int timeoutSeconds = 30;
}
