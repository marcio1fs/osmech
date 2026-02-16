import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

/// Mixin para tratamento centralizado de erros de autenticação (401/403).
/// Qualquer State que faz chamadas API deve usar este mixin.
///
/// Funcionalidades:
/// - [safeToken]: retorna token validado (não expirado) ou faz logout
/// - [handleAuthError]: intercepta UnauthorizedException/ForbiddenException
///
/// Uso:
/// ```dart
/// class _MyPageState extends State<MyPage> with AuthErrorMixin {
///   Future<void> _loadData() async {
///     try {
///       final api = ApiClient(token: safeToken);
///       // ...chamada API...
///     } catch (e) {
///       if (!handleAuthError(e)) {
///         // tratar outros erros
///       }
///     }
///   }
/// }
/// ```
mixin AuthErrorMixin<T extends StatefulWidget> on State<T> {
  /// Retorna o token de forma segura.
  /// Verifica se o token existe E se não está expirado.
  /// Se o token for null ou expirado, faz logout e lança exceção.
  String get safeToken {
    final auth = Provider.of<AuthService>(context, listen: false);
    final token = auth.token;
    if (token == null) {
      if (mounted) auth.logout();
      throw UnauthorizedException('Token nulo — redirecionando ao login.');
    }
    if (auth.isTokenExpired) {
      if (mounted) {
        auth.logout();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sessão expirada. Faça login novamente.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      throw UnauthorizedException('Token expirado — redirecionando ao login.');
    }
    return token;
  }

  /// Verifica se o erro é [UnauthorizedException] (401) ou [ForbiddenException] (403)
  /// e faz logout automático. Retorna true se o erro foi tratado, false caso contrário.
  bool handleAuthError(Object error) {
    if (error is UnauthorizedException || error is ForbiddenException) {
      if (mounted) {
        final auth = Provider.of<AuthService>(context, listen: false);
        auth.logout();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ForbiddenException
                  ? 'Acesso negado. Faça login novamente.'
                  : 'Sessão expirada. Faça login novamente.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return true;
    }
    return false;
  }
}
