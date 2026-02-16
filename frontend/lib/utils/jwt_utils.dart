import 'dart:convert';

/// Utilitário para decodificar e validar tokens JWT no client-side.
/// Não requer dependências externas — JWT usa base64url padrão.
class JwtUtils {
  JwtUtils._();

  /// Decodifica o payload (claims) de um token JWT.
  /// Retorna null se o token for malformado.
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // O payload é a segunda parte do JWT
      String payload = parts[1];

      // Base64url → Base64 padding
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }

      final decoded = utf8.decode(base64Url.decode(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Verifica se o token JWT está expirado.
  /// Retorna true se expirado, malformado ou sem claim 'exp'.
  /// [bufferSeconds] — margem de segurança antes da expiração real.
  static bool isExpired(String token, {int bufferSeconds = 60}) {
    final payload = decodePayload(token);
    if (payload == null) return true;

    final exp = payload['exp'];
    if (exp == null || exp is! int) return true;

    final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    final now = DateTime.now().add(Duration(seconds: bufferSeconds));

    return now.isAfter(expiryDate);
  }

  /// Retorna a data de expiração do token, ou null se malformado.
  static DateTime? getExpiry(String token) {
    final payload = decodePayload(token);
    if (payload == null) return null;

    final exp = payload['exp'];
    if (exp == null || exp is! int) return null;

    return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
  }

  /// Retorna o email (subject) do token, ou null se malformado.
  static String? getEmail(String token) {
    final payload = decodePayload(token);
    return payload?['sub'] as String?;
  }

  /// Retorna o role do token, ou null se malformado.
  static String? getRole(String token) {
    final payload = decodePayload(token);
    return payload?['role'] as String?;
  }

  /// Retorna os segundos restantes até a expiração, ou 0 se expirado.
  static int secondsUntilExpiry(String token) {
    final expiry = getExpiry(token);
    if (expiry == null) return 0;

    final remaining = expiry.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }
}
