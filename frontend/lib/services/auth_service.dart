import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// Serviço de autenticação.
/// Gerencia login, cadastro, token JWT e estado do usuário.
class AuthService extends ChangeNotifier {
  String? _token;
  String? _email;
  String? _nome;
  String? _role;
  String? _plano;

  bool get isAuthenticated => _token != null;
  String? get token => _token;
  String? get email => _email;
  String? get nome => _nome;
  String? get role => _role;
  String? get plano => _plano;

  AuthService() {
    _loadFromPrefs();
  }

  /// Carrega token salvo no SharedPreferences.
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _email = prefs.getString('email');
    _nome = prefs.getString('nome');
    _role = prefs.getString('role');
    _plano = prefs.getString('plano');
    notifyListeners();
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
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

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
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

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

  /// Faz logout e limpa dados salvos.
  Future<void> logout() async {
    _token = null;
    _email = null;
    _nome = null;
    _role = null;
    _plano = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
