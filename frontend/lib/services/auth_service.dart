import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/usuario.dart';

class AuthService {
  static const String _baseUrl = 'http://localhost:8080/api/auth';
  static const _storage = FlutterSecureStorage();

  static Future<AuthResponse> login(String email, String senha) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': senha}),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(data);
      
      await _storage.write(key: 'jwt_token', value: authResponse.token);
      await _storage.write(key: 'usuario_id', value: authResponse.usuarioId.toString());
      await _storage.write(key: 'nome_oficina', value: authResponse.nomeOficina);
      await _storage.write(key: 'email', value: authResponse.email);
      
      return authResponse;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Login inválido');
    }
  }

  static Future<AuthResponse> register(String nomeOficina, String email, String senha) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nomeOficina': nomeOficina,
        'email': email,
        'senha': senha,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(data);
      
      await _storage.write(key: 'jwt_token', value: authResponse.token);
      await _storage.write(key: 'usuario_id', value: authResponse.usuarioId.toString());
      await _storage.write(key: 'nome_oficina', value: authResponse.nomeOficina);
      await _storage.write(key: 'email', value: authResponse.email);
      
      return authResponse;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Cadastro inválido');
    }
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<int?> getUsuarioId() async {
    final id = await _storage.read(key: 'usuario_id');
    return id != null ? int.tryParse(id) : null;
  }

  static Future<String?> getNomeOficina() async {
    return await _storage.read(key: 'nome_oficina');
  }

  static Future<String?> getEmail() async {
    return await _storage.read(key: 'email');
  }

  static Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'usuario_id');
    await _storage.delete(key: 'nome_oficina');
    await _storage.delete(key: 'email');
  }
}
