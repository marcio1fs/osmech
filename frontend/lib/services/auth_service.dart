import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import '../utils/jwt_utils.dart';

/// Serviço de autenticação.
/// Gerencia login, cadastro, token JWT e estado do usuário.
/// Valida expiração do JWT ao carregar do cache e antes de cada uso.
class AuthService extends ChangeNotifier {
  String? _token;
  String? _refreshToken;
  String? _email;
  String? _nome;
  String? _role;
  String? _plano;
  bool _initialized = false;

  /// Estado do 2FA pendente (Fase 4): id do desafio + e-mail alvo.
  int? _sessao2fa;
  String? _email2fa;

  /// Retorna true apenas se o token existe E não está expirado.
  bool get isAuthenticated => _token != null && !isTokenExpired;
  bool get initialized => _initialized;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  String? get email => _email;
  String? get nome => _nome;
  String? get role => _role;
  String? get plano => _plano;

  /// true quando o login parou no 2FA (senha correta, aguardando código)
  bool get requer2fa => _sessao2fa != null;
  int? get sessao2fa => _sessao2fa;
  String? get email2fa => _email2fa;

  /// Verifica se o token atual está expirado (com margem de 60s).
  bool get isTokenExpired {
    if (_token == null) return true;
    return JwtUtils.isExpired(_token!, bufferSeconds: 60);
  }

  /// Segundos restantes até a expiração do token.
  int get tokenSecondsRemaining {
    if (_token == null) return 0;
    return JwtUtils.secondsUntilExpiry(_token!);
  }

  AuthService() {
    _loadFromPrefs();
  }

  /// Carrega tokens salvos no SharedPreferences.
  /// Fase 4: com o access token expirado e um refresh token válido,
  /// a sessão é renovada silenciosamente; só limpa se a renovação falhar.
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token');
    final savedRefresh = prefs.getString('refreshToken');
    final savedEmail = prefs.getString('email');
    final savedNome = prefs.getString('nome');
    final savedRole = prefs.getString('role');
    final savedPlano = prefs.getString('plano');

    if (savedRefresh != null && savedRefresh.isNotEmpty) {
      _refreshToken = savedRefresh;
      _email = savedEmail;
      _nome = savedNome;
      _role = savedRole;
      _plano = savedPlano;

      final acessoValido = savedToken != null &&
          !JwtUtils.isExpired(savedToken, bufferSeconds: 60);
      if (acessoValido) {
        _token = savedToken;
        // Renovação oportunista: expira em menos de 5 min? já troca
        if (JwtUtils.secondsUntilExpiry(savedToken) < 300) {
          debugPrint('[AuthService] Access token quase expirado — renovando.');
          await refreshSession();
        }
      } else {
        // Access expirado — tenta renovar com o refresh token.
        // Se o servidor revogar a sessão, refreshSession() já limpa tudo;
        // em falha de rede, mantém os dados para a próxima inicialização.
        debugPrint('[AuthService] Access token expirado — tentando refresh.');
        await refreshSession();
      }
    } else if (savedToken != null &&
        !JwtUtils.isExpired(savedToken, bufferSeconds: 60)) {
      // Sessão antiga (pré-Fase 4): sem refresh — aceita até expirar
      _token = savedToken;
      _email = savedEmail;
      _nome = savedNome;
      _role = savedRole;
      _plano = savedPlano;
    } else if (savedToken != null) {
      // Token expirado e sem refresh — limpar dados salvos
      debugPrint(
          '[AuthService] Token expirado detectado ao iniciar. Limpando cache.');
      await _clearPrefs(prefs);
    }

    _initialized = true;
    notifyListeners();
  }

  /// Limpa todos os dados de autenticação do SharedPreferences.
  Future<void> _clearPrefs(SharedPreferences prefs) async {
    await prefs.remove('token');
    await prefs.remove('refreshToken');
    await prefs.remove('email');
    await prefs.remove('nome');
    await prefs.remove('role');
    await prefs.remove('plano');
  }

  /// Salva dados do usuário no SharedPreferences.
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString('token', _token!);
      if (_refreshToken != null) {
        await prefs.setString('refreshToken', _refreshToken!);
      }
      await prefs.setString('email', _email ?? '');
      await prefs.setString('nome', _nome ?? '');
      await prefs.setString('role', _role ?? '');
      await prefs.setString('plano', _plano ?? '');
    }
  }

  /// Realiza login na API.
  Future<String?> login(String email, String senha) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'senha': senha}),
          )
          .timeout(const Duration(seconds: ApiConfig.timeoutSeconds));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (body['requer2fa'] == true) {
          // Senha correta, mas falta o código de verificação (Fase 4)
          _sessao2fa = body['sessao'] as int?;
          _email2fa = body['email'];
          notifyListeners();
          return null; // sem erro — gate exibe a tela de código
        }
        _token = body['token'];
        _refreshToken = body['refreshToken'];
        _email = body['email'];
        _nome = body['nome'];
        _role = body['role'];
        _plano = body['plano'];
        await _saveToPrefs();
        notifyListeners();
        return null; // sucesso
      } else {
        return body['error'] ?? 'Erro ao fazer login';
      }
    } catch (e) {
      return 'Erro de conexão: verifique sua internet';
    }
  }

  /// Verifica o código 2FA e conclui o login (Fase 4).
  Future<String?> verificar2fa(String codigo) async {
    final sessao = _sessao2fa;
    if (sessao == null) return 'Sessão expirada. Faça login novamente.';
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/2fa/verificar'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'sessao': sessao, 'codigo': codigo}),
          )
          .timeout(const Duration(seconds: ApiConfig.timeoutSeconds));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _sessao2fa = null;
        _email2fa = null;
        _token = body['token'];
        _refreshToken = body['refreshToken'];
        _email = body['email'];
        _nome = body['nome'];
        _role = body['role'];
        _plano = body['plano'];
        await _saveToPrefs();
        notifyListeners();
        return null; // sucesso
      } else {
        return body['error'] ?? 'Código inválido';
      }
    } catch (e) {
      return 'Erro de conexão: verifique sua internet';
    }
  }

  /// Reenvia o código 2FA do desafio pendente (Fase 4).
  Future<String?> reenviar2fa() async {
    final sessao = _sessao2fa;
    if (sessao == null) return 'Sessão expirada. Faça login novamente.';
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/2fa/reenviar'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'sessao': sessao}),
          )
          .timeout(const Duration(seconds: ApiConfig.timeoutSeconds));
      if (response.statusCode == 200) return null;
      final body = jsonDecode(response.body);
      return body['error'] ?? 'Erro ao reenviar código';
    } catch (e) {
      return 'Erro de conexão: verifique sua internet';
    }
  }

  /// Desiste do 2FA e volta para a tela de login.
  void cancelar2fa() {
    _sessao2fa = null;
    _email2fa = null;
    notifyListeners();
  }

  /// Renova a sessão usando o refresh token (Fase 4).
  /// Retorna true se renovou; false se a sessão morreu (limpa o cache local).
  Future<bool> refreshSession() async {
    final refresh = _refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refresh}),
          )
          .timeout(const Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _token = body['token'];
        _refreshToken = body['refreshToken'];
        _email = body['email'] ?? _email;
        _nome = body['nome'] ?? _nome;
        _role = body['role'] ?? _role;
        _plano = body['plano'] ?? _plano;
        await _saveToPrefs();
        notifyListeners();
        return true;
      }

      // Refresh rejeitado (revogado/expirado/reuso) — sessão morreu
      await _limparEstadoLocal();
      return false;
    } catch (e) {
      // Sem rede: mantém a sessão local — a próxima tentativa decide.
      return false;
    }
  }

  /// Limpa estado local + prefs (sem chamar o backend).
  Future<void> _limparEstadoLocal() async {
    _token = null;
    _refreshToken = null;
    _email = null;
    _nome = null;
    _role = null;
    _plano = null;
    _sessao2fa = null;
    _email2fa = null;
    final prefs = await SharedPreferences.getInstance();
    await _clearPrefs(prefs);
    notifyListeners();
  }

  /// Aplica uma sessão já autenticada (ex.: retorno do aceite de convite,
  /// que já vem com token JWT). Persiste e notifica ouvintes.
  Future<void> aplicarAutenticacao({
    required String token,
    String? refreshToken,
    String? email,
    String? nome,
    String? role,
    String? plano,
  }) async {
    _token = token;
    _refreshToken = refreshToken;
    _email = email;
    _nome = nome;
    _role = role;
    _plano = plano;
    await _saveToPrefs();
    notifyListeners();
  }

  /// Realiza cadastro na API.
  Future<String?> register({
    required String nome,
    required String email,
    required String senha,
    required String telefone,
    String? nomeOficina,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nome': nome,
              'email': email,
              'senha': senha,
              'telefone': telefone,
              'nomeOficina': nomeOficina,
            }),
          )
          .timeout(const Duration(seconds: ApiConfig.timeoutSeconds));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _token = body['token'];
        _refreshToken = body['refreshToken'] ?? _refreshToken;
        _email = body['email'];
        _nome = body['nome'];
        _role = body['role'];
        _plano = body['plano'];
        await _saveToPrefs();
        notifyListeners();
        return null; // sucesso
      } else {
        return body['error'] ?? 'Erro ao fazer cadastro';
      }
    } catch (e) {
      return 'Erro de conexão: verifique sua internet';
    }
  }

  /// Faz logout: revoga a sessão no backend (best effort) e limpa o local.
  Future<void> logout() async {
    final refresh = _refreshToken;
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await http
            .post(
              Uri.parse('${ApiConfig.baseUrl}/api/auth/logout'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'refreshToken': refresh}),
            )
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Sem rede: a revogação local já basta; o token expira sozinho.
      }
    }
    await _limparEstadoLocal();
  }

  /// Atualiza o nome do usuário no estado e SharedPreferences.
  Future<void> updateNome(String nome) async {
    _nome = nome;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nome', nome);
    notifyListeners();
  }

  /// Envia e-mail de recuperação de senha.
  Future<String?> forgotPassword(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode == 200) {
        return null; // sucesso
      } else {
        final body = jsonDecode(response.body);
        return body['error'] ?? 'Erro ao solicitar recuperação de senha';
      }
    } catch (e) {
      return 'Erro de conexão: verifique sua internet';
    }
  }

  /// Redefine a senha com o token de recuperação.
  Future<String?> resetPassword(String token, String newPassword) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': token, 'novaSenha': newPassword}),
          )
          .timeout(const Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode == 200) {
        return null; // sucesso
      } else {
        final body = jsonDecode(response.body);
        return body['error'] ?? 'Erro ao redefinir senha';
      }
    } catch (e) {
      return 'Erro de conexão: verifique sua internet';
    }
  }

  /// Verifica o e-mail do usuário com o token.
  Future<String?> verifyEmail(String token) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/verify-email?token=$token'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode == 200) {
        return null; // sucesso
      } else {
        final body = jsonDecode(response.body);
        return body['error'] ?? 'Erro ao verificar e-mail';
      }
    } catch (e) {
      return 'Erro de conexão: verifique sua internet';
    }
  }
}
