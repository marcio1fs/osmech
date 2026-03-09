import 'package:flutter/foundation.dart';

/// Configuracoes globais da API.
class ApiConfig {
  /// URL base da API.
  /// Pode ser definida via --dart-define=API_URL=...
  /// Fallback:
  /// - Web/iOS/Desktop: localhost
  /// - Android emulador: 10.0.2.2 (host machine loopback)
  static String get baseUrl {
    const definedUrl = String.fromEnvironment('API_URL', defaultValue: '');
    if (definedUrl.isNotEmpty) return definedUrl;

    if (kIsWeb) return 'http://localhost:8081';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8081';
    }
    return 'http://localhost:8081';
  }

  // Timeout padrao em segundos
  static const int timeoutSeconds = 30;
}
