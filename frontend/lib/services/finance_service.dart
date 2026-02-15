import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Serviço para comunicação com a API do módulo financeiro.
class FinanceService {
  final String token;

  FinanceService({required this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ==========================================
  // TRANSAÇÕES
  // ==========================================

  /// Cria uma nova transação financeira.
  Future<Map<String, dynamic>> criarTransacao(
      Map<String, dynamic> dados) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/finance/transaction'),
          headers: _headers,
          body: jsonEncode(dados),
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao criar transação');
  }

  /// Lista transações com filtros opcionais.
  Future<List<Map<String, dynamic>>> listarTransacoes({
    String? dataInicio,
    String? dataFim,
    String? tipo,
  }) async {
    final params = <String, String>{};
    if (dataInicio != null) params['dataInicio'] = dataInicio;
    if (dataFim != null) params['dataFim'] = dataFim;
    if (tipo != null) params['tipo'] = tipo;

    final uri = Uri.parse('${ApiConfig.baseUrl}/finance/transaction')
        .replace(queryParameters: params.isNotEmpty ? params : null);

    final response = await http
        .get(uri, headers: _headers)
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Erro ao listar transações');
  }

  /// Estorna uma transação.
  Future<Map<String, dynamic>> estornarTransacao(int transacaoId) async {
    final response = await http
        .post(
          Uri.parse(
              '${ApiConfig.baseUrl}/finance/transaction/$transacaoId/estorno'),
          headers: _headers,
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao estornar transação');
  }

  // ==========================================
  // CATEGORIAS
  // ==========================================

  /// Lista todas as categorias (usuário + sistema).
  Future<List<Map<String, dynamic>>> listarCategorias() async {
    final response = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/finance/category'),
            headers: _headers)
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Erro ao listar categorias');
  }

  /// Cria uma nova categoria.
  Future<Map<String, dynamic>> criarCategoria(
      Map<String, dynamic> dados) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/finance/category'),
          headers: _headers,
          body: jsonEncode(dados),
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao criar categoria');
  }

  /// Exclui uma categoria.
  Future<void> excluirCategoria(int categoriaId) async {
    final response = await http
        .delete(
          Uri.parse('${ApiConfig.baseUrl}/finance/category/$categoriaId'),
          headers: _headers,
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Erro ao excluir categoria');
    }
  }

  // ==========================================
  // FLUXO DE CAIXA
  // ==========================================

  /// Retorna o fluxo de caixa de um período.
  Future<List<Map<String, dynamic>>> getFluxoCaixa(
      String inicio, String fim) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/finance/cashflow')
        .replace(queryParameters: {'inicio': inicio, 'fim': fim});

    final response = await http
        .get(uri, headers: _headers)
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Erro ao carregar fluxo de caixa');
  }

  // ==========================================
  // RESUMO FINANCEIRO
  // ==========================================

  /// Retorna o resumo financeiro para o dashboard.
  Future<Map<String, dynamic>> getResumoFinanceiro() async {
    final response = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/finance/summary'),
            headers: _headers)
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erro ao carregar resumo financeiro');
  }
}
