import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Serviço para comunicação com a API de Ordens de Serviço.
class OsService {
  final String token;

  OsService({required this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// Lista todas as OS do usuário logado.
  Future<List<Map<String, dynamic>>> listar() async {
    final response = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/os'), headers: _headers)
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Erro ao listar ordens de serviço');
  }

  /// Busca uma OS por ID.
  Future<Map<String, dynamic>> buscarPorId(int id) async {
    final response = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/os/$id'), headers: _headers)
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erro ao buscar ordem de serviço');
  }

  /// Cria uma nova OS.
  Future<Map<String, dynamic>> criar(Map<String, dynamic> dados) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/os'),
          headers: _headers,
          body: jsonEncode(dados),
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao criar OS');
  }

  /// Atualiza uma OS existente.
  Future<Map<String, dynamic>> atualizar(
    int id,
    Map<String, dynamic> dados,
  ) async {
    final response = await http
        .put(
          Uri.parse('${ApiConfig.baseUrl}/os/$id'),
          headers: _headers,
          body: jsonEncode(dados),
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao atualizar OS');
  }

  /// Exclui uma OS.
  Future<void> excluir(int id) async {
    final response = await http
        .delete(Uri.parse('${ApiConfig.baseUrl}/os/$id'), headers: _headers)
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode != 200) {
      throw Exception('Erro ao excluir OS');
    }
  }

  /// Obtém estatísticas do dashboard.
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/os/dashboard'), headers: _headers)
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erro ao carregar dashboard');
  }
}
