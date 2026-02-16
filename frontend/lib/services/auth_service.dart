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
  String? _email;
  String? _nome;
  String? _role;
  String? _plano;
  bool _initialized = false;

  /// Retorna true apenas se o token existe E não está expirado.
  bool get isAuthenticated => _token != null && !isTokenExpired;
  bool get initialized => _initialized;
  String? get token => _token;
  String? get email => _email;
  String? get nome => _nome;
  String? get role => _role;
  String? get plano => _plano;

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

  /// Carrega token salvo no SharedPreferences.
  /// Se o token estiver expirado, limpa automaticamente e redireciona ao login.
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token');

    // Verifica se o token salvo ainda é válido
    if (savedToken != null &&
        !JwtUtils.isExpired(savedToken, bufferSeconds: 60)) {
      _token = savedToken;
      _email = prefs.getString('email');
      _nome = prefs.getString('nome');
      _role = prefs.getString('role');
      _plano = prefs.getString('plano');
    } else if (savedToken != null) {
      // Token expirado — limpar dados salvos
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
            Uri.parse('${ApiConfig.baseUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'senha': senha}),
          )
          .timeout(const Duration(seconds: ApiConfig.timeoutSeconds));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _token = body['token'];
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
            Uri.parse('${ApiConfig.baseUrl}/auth/register'),
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

  /// Faz logout e limpa dados de autenticação.
  Future<void> logout() async {
    _token = null;
    _email = null;
    _nome = null;
    _role = null;
    _plano = null;
    final prefs = await SharedPreferences.getInstance();
    await _clearPrefs(prefs);
    notifyListeners();
  }

  /// Atualiza o nome do usuário no estado e SharedPreferences.
  Future<void> updateNome(String nome) async {
    _nome = nome;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nome', nome);
    notifyListeners();
  }
}
