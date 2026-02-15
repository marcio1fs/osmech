import 'dart:convert';
import 'api_client.dart';

/// Serviço para comunicação com a API do módulo financeiro.
class FinanceService {
  final ApiClient _api;

  FinanceService({required String token}) : _api = ApiClient(token: token);

  // ==========================================
  // TRANSAÇÕES
  // ==========================================

  /// Cria uma nova transação financeira.
  Future<Map<String, dynamic>> criarTransacao(
      Map<String, dynamic> dados) async {
    final response = await _api.post('/finance/transaction', body: dados);

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

    final response = await _api.get('/finance/transaction',
        queryParams: params.isNotEmpty ? params : null);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Erro ao listar transações');
  }

  /// Estorna uma transação.
  Future<Map<String, dynamic>> estornarTransacao(int transacaoId) async {
    final response =
        await _api.post('/finance/transaction/$transacaoId/estorno');

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
    final response = await _api.get('/finance/category');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Erro ao listar categorias');
  }

  /// Cria uma nova categoria.
  Future<Map<String, dynamic>> criarCategoria(
      Map<String, dynamic> dados) async {
    final response = await _api.post('/finance/category', body: dados);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao criar categoria');
  }

  /// Exclui uma categoria.
  Future<void> excluirCategoria(int categoriaId) async {
    final response = await _api.delete('/finance/category/$categoriaId');

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
    final response = await _api
        .get('/finance/cashflow', queryParams: {'inicio': inicio, 'fim': fim});

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
    final response = await _api.get('/finance/summary');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erro ao carregar resumo financeiro');
  }
}
