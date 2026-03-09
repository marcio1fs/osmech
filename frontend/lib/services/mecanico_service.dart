import 'dart:convert';
import 'api_client.dart';

class MecanicoService {
  final ApiClient _api;

  MecanicoService({required String token}) : _api = ApiClient(token: token);

  Future<List<Map<String, dynamic>>> listar({bool ativosOnly = true}) async {
    final response = await _api.get('/api/mecanicos', queryParams: {
      'ativosOnly': ativosOnly.toString(),
    });
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao listar mecânicos');
  }

  Future<Map<String, dynamic>> criar(Map<String, dynamic> dados) async {
    final response = await _api.post('/api/mecanicos', body: dados);
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) return body;
    throw Exception(body['error'] ?? 'Erro ao criar mecânico');
  }

  Future<Map<String, dynamic>> atualizar(int id, Map<String, dynamic> dados) async {
    final response = await _api.put('/api/mecanicos/$id', body: dados);
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) return body;
    throw Exception(body['error'] ?? 'Erro ao atualizar mecânico');
  }

  Future<void> desativar(int id) async {
    final response = await _api.delete('/api/mecanicos/$id');
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Erro ao desativar mecânico');
    }
  }

  Future<void> reativar(int id) async {
    final response = await _api.patch('/api/mecanicos/$id/reativar');
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Erro ao reativar mecânico');
    }
  }
}
