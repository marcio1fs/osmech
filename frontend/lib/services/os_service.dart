import 'dart:convert';
import 'api_client.dart';

/// Serviço para comunicação com a API de Ordens de Serviço.
class OsService {
  final ApiClient _api;

  OsService({required String token}) : _api = ApiClient(token: token);

  /// Lista todas as OS do usuário logado.
  Future<List<Map<String, dynamic>>> listar() async {
    final response = await _api.get('/api/os');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao listar ordens de serviço');
  }

  /// Busca uma OS por ID.
  Future<Map<String, dynamic>> buscarPorId(int id) async {
    final response = await _api.get('/api/os/$id');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao buscar ordem de serviço');
  }

  /// Cria uma nova OS.
  Future<Map<String, dynamic>> criar(Map<String, dynamic> dados) async {
    final response = await _api.post('/api/os', body: dados);

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
    final response = await _api.put('/api/os/$id', body: dados);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao atualizar OS');
  }

  /// Exclui uma OS.
  Future<void> excluir(int id) async {
    final response = await _api.delete('/api/os/$id');

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Erro ao excluir OS');
    }
  }

  /// Encerra uma OS com método de pagamento e recibo.
  Future<Map<String, dynamic>> encerrar(
    int id,
    Map<String, dynamic> dados,
  ) async {
    final response = await _api.post('/api/os/$id/encerrar', body: dados);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao encerrar OS');
  }

  /// Obtém estatísticas do dashboard.
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _api.get('/api/os/dashboard');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao carregar dashboard');
  }

  /// Envia o recibo via WhatsApp para uma OS já concluída.
  Future<Map<String, dynamic>> enviarReciboWhatsApp(int id, {String? telefoneWhatsapp}) async {
    final response = await _api.post(
      '/api/os/$id/enviar-recibo-whatsapp',
      body: {
        if (telefoneWhatsapp != null) 'telefoneWhatsapp': telefoneWhatsapp,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao enviar recibo via WhatsApp');
  }
}
