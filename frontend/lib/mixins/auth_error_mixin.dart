import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

/// Mixin para tratamento centralizado de [UnauthorizedException] (401).
/// Qualquer State que faz chamadas API deve usar este mixin.
///
/// Uso:
/// ```dart
/// class _MyPageState extends State<MyPage> with AuthErrorMixin {
///   Future<void> _loadData() async {
///     try {
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
  /// Retorna o token de forma segura. Se for null, faz logout e lança exceção.
  /// Use no lugar de `token!` para evitar crashes.
  String get safeToken {
    final token = Provider.of<AuthService>(context, listen: false).token;
    if (token == null) {
      if (mounted) {
        final auth = Provider.of<AuthService>(context, listen: false);
        auth.logout();
      }
      throw UnauthorizedException('Token nulo — redirecionando ao login.');
    }
    return token;
  }

  /// Verifica se o erro é [UnauthorizedException] e faz logout automático.
  /// Retorna true se o erro foi tratado (401), false caso contrário.
  bool handleAuthError(Object error) {
    if (error is UnauthorizedException) {
      if (mounted) {
        final auth = Provider.of<AuthService>(context, listen: false);
        auth.logout();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sessão expirada. Faça login novamente.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return true;
    }
    return false;
  }
}
