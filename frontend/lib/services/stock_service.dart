import 'dart:convert';
import 'api_client.dart';

/// Serviço para comunicação com a API do módulo de estoque.
class StockService {
  final ApiClient _api;

  StockService({required String token}) : _api = ApiClient(token: token);

  // ==========================================
  // ITENS DE ESTOQUE
  // ==========================================

  /// Criar novo item de estoque
  Future<Map<String, dynamic>> criarItem(Map<String, dynamic> dados) async {
    final response = await _api.post('/stock', body: dados);
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) return body;
    throw Exception(body['error'] ?? 'Erro ao criar item');
  }

  /// Listar itens (com filtros opcionais)
  Future<List<Map<String, dynamic>>> listarItens({
    String? categoria,
    String? busca,
  }) async {
    final params = <String, String>{};
    if (categoria != null) params['categoria'] = categoria;
    if (busca != null && busca.isNotEmpty) params['busca'] = busca;

    final response = await _api.get('/stock',
        queryParams: params.isNotEmpty ? params : null);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao listar itens');
  }

  /// Buscar item por ID
  Future<Map<String, dynamic>> buscarItem(int itemId) async {
    final response = await _api.get('/stock/$itemId');
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) return body;
    throw Exception(body['error'] ?? 'Erro ao buscar item');
  }

  /// Atualizar item existente
  Future<Map<String, dynamic>> atualizarItem(
      int itemId, Map<String, dynamic> dados) async {
    final response = await _api.put('/stock/$itemId', body: dados);
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) return body;
    throw Exception(body['error'] ?? 'Erro ao atualizar item');
  }

  /// Desativar item (soft delete)
  Future<void> desativarItem(int itemId) async {
    final response = await _api.delete('/stock/$itemId');
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Erro ao desativar item');
    }
  }

  // ==========================================
  // MOVIMENTAÇÕES
  // ==========================================

  /// Registrar movimentação (entrada ou saída)
  Future<Map<String, dynamic>> registrarMovimentacao(
      Map<String, dynamic> dados) async {
    final response = await _api.post('/stock/move', body: dados);
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) return body;
    throw Exception(body['error'] ?? 'Erro ao registrar movimentação');
  }

  /// Listar todas as movimentações
  Future<List<Map<String, dynamic>>> listarMovimentacoes() async {
    final response = await _api.get('/stock/movements');
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao listar movimentações');
  }

  /// Listar movimentações de um item específico
  Future<List<Map<String, dynamic>>> listarMovimentacoesItem(int itemId) async {
    final response = await _api.get('/stock/$itemId/movements');
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao listar movimentações do item');
  }

  // ==========================================
  // ALERTAS
  // ==========================================

  /// Obter alertas de estoque baixo/zerado
  Future<List<Map<String, dynamic>>> getAlertas() async {
    final response = await _api.get('/stock/alerts');
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao buscar alertas');
  }
}
