import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Exceção lançada quando o token JWT expirou ou é inválido (HTTP 401).
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(
      [this.message = 'Sessão expirada. Faça login novamente.']);
  @override
  String toString() => message;
}

/// Cliente HTTP centralizado com interceptor de autenticação.
/// Garante timeout consistente, headers padrão e detecção de 401.
class ApiClient {
  final String token;

  ApiClient({required this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Duration get _timeout => Duration(seconds: ApiConfig.timeoutSeconds);

  /// Verifica se a resposta é 401 e lança [UnauthorizedException].
  void _checkUnauthorized(http.Response response) {
    if (response.statusCode == 401) {
      throw UnauthorizedException();
    }
  }

  /// GET request com autenticação.
  Future<http.Response> get(String path,
      {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(
        queryParameters:
            queryParams != null && queryParams.isNotEmpty ? queryParams : null);
    final response = await http.get(uri, headers: _headers).timeout(_timeout);
    _checkUnauthorized(response);
    return response;
  }

  /// POST request com autenticação.
  Future<http.Response> post(String path, {Object? body}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await http
        .post(uri,
            headers: _headers, body: body != null ? jsonEncode(body) : null)
        .timeout(_timeout);
    _checkUnauthorized(response);
    return response;
  }

  /// PUT request com autenticação.
  Future<http.Response> put(String path, {Object? body}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await http
        .put(uri,
            headers: _headers, body: body != null ? jsonEncode(body) : null)
        .timeout(_timeout);
    _checkUnauthorized(response);
    return response;
  }

  /// DELETE request com autenticação.
  Future<http.Response> delete(String path) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final response =
        await http.delete(uri, headers: _headers).timeout(_timeout);
    _checkUnauthorized(response);
    return response;
  }
}
