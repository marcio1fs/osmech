import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'api_config.dart';

/// Service da área do DONO: gestão de membros e convites da equipe.
class EquipeService {
  final ApiClient _api;

  EquipeService({required String token}) : _api = ApiClient(token: token);

  /// GET /api/oficina/equipe — membros + convites + uso vs. limite do plano.
  Future<Map<String, dynamic>> getEquipe() async {
    final response = await _api.get('/api/oficina/equipe');
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(body);
    }
    throw Exception(body['error'] ?? 'Erro ao carregar equipe');
  }

  /// POST /api/oficina/equipe/convites
  Future<Map<String, dynamic>> convidar(String email, String papel) async {
    final response = await _api.post('/api/oficina/equipe/convites', body: {
      'email': email,
      'papel': papel,
    });
    final body = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(body);
    }
    throw Exception(body['error'] ?? 'Erro ao criar convite');
  }

  /// DELETE /api/oficina/equipe/convites/{id}
  Future<void> revogarConvite(int id) async {
    final response = await _api.delete('/api/oficina/equipe/convites/$id');
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Erro ao revogar convite');
    }
  }

  /// POST /api/oficina/equipe/convites/{id}/reenviar
  Future<Map<String, dynamic>> reenviarConvite(int id) async {
    final response =
        await _api.post('/api/oficina/equipe/convites/$id/reenviar', body: {});
    final body = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(body);
    }
    throw Exception(body['error'] ?? 'Erro ao reenviar convite');
  }

  /// PUT /api/oficina/equipe/usuarios/{id}/papel
  Future<Map<String, dynamic>> alterarPapel(int id, String papel) async {
    final response = await _api
        .put('/api/oficina/equipe/usuarios/$id/papel', body: {'papel': papel});
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) return Map<String, dynamic>.from(body);
    throw Exception(body['error'] ?? 'Erro ao alterar papel');
  }

  /// PUT /api/oficina/equipe/usuarios/{id}/status
  Future<Map<String, dynamic>> alterarStatus(int id, bool ativo) async {
    final response = await _api
        .put('/api/oficina/equipe/usuarios/$id/status', body: {'ativo': ativo});
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) return Map<String, dynamic>.from(body);
    throw Exception(body['error'] ?? 'Erro ao alterar status');
  }
}

/// Service PÚBLICO do convite (sem token — telas de aceite).
class ConvitePublicoService {
  /// GET /api/auth/convites/{token}
  Future<Map<String, dynamic>> info(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/convites/$token'),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) return Map<String, dynamic>.from(body);
    throw Exception(body['error'] ?? 'Convite inválido');
  }

  /// POST /api/auth/convites/aceitar
  Future<Map<String, dynamic>> aceitar({
    required String token,
    required String nome,
    required String telefone,
    required String senha,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/convites/aceitar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'nome': nome,
        'telefone': telefone,
        'senha': senha,
      }),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) return Map<String, dynamic>.from(body);
    throw Exception(body['error'] ?? 'Erro ao aceitar convite');
  }
}
