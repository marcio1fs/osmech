import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Serviço para comunicação com a API do módulo de estoque.
class StockService {
  final String token;

  StockService({required this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ==========================================
  // ITENS DE ESTOQUE
  // ==========================================

  /// Criar novo item de estoque
  Future<Map<String, dynamic>> criarItem(Map<String, dynamic> dados) async {
    final response = await http
        .post(Uri.parse('${ApiConfig.baseUrl}/stock'),
            headers: _headers, body: jsonEncode(dados))
        .timeout(const Duration(seconds: 15));
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

    final uri = Uri.parse('${ApiConfig.baseUrl}/stock')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Erro ao listar itens');
  }

  /// Buscar item por ID
  Future<Map<String, dynamic>> buscarItem(int itemId) async {
    final response = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/stock/$itemId'),
            headers: _headers)
        .timeout(const Duration(seconds: 15));
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) return body;
    throw Exception(body['error'] ?? 'Erro ao buscar item');
  }

  /// Atualizar item existente
  Future<Map<String, dynamic>> atualizarItem(
      int itemId, Map<String, dynamic> dados) async {
    final response = await http
        .put(Uri.parse('${ApiConfig.baseUrl}/stock/$itemId'),
            headers: _headers, body: jsonEncode(dados))
        .timeout(const Duration(seconds: 15));
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) return body;
    throw Exception(body['error'] ?? 'Erro ao atualizar item');
  }

  /// Desativar item (soft delete)
  Future<void> desativarItem(int itemId) async {
    final response = await http
        .delete(Uri.parse('${ApiConfig.baseUrl}/stock/$itemId'),
            headers: _headers)
        .timeout(const Duration(seconds: 15));
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
    final response = await http
        .post(Uri.parse('${ApiConfig.baseUrl}/stock/move'),
            headers: _headers, body: jsonEncode(dados))
        .timeout(const Duration(seconds: 15));
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) return body;
    throw Exception(body['error'] ?? 'Erro ao registrar movimentação');
  }

  /// Listar todas as movimentações
  Future<List<Map<String, dynamic>>> listarMovimentacoes() async {
    final response = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/stock/movements'),
            headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Erro ao listar movimentações');
  }

  /// Listar movimentações de um item específico
  Future<List<Map<String, dynamic>>> listarMovimentacoesItem(
      int itemId) async {
    final response = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/stock/$itemId/movements'),
            headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Erro ao listar movimentações do item');
  }

  // ==========================================
  // ALERTAS
  // ==========================================

  /// Obter alertas de estoque baixo/zerado
  Future<List<Map<String, dynamic>>> getAlertas() async {
    final response = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/stock/alerts'),
            headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Erro ao buscar alertas');
  }
}
