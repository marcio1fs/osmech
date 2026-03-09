import 'dart:convert';
import 'api_client.dart';
import 'dto/assinatura_response.dart';

/// Serviço para comunicação com a API de Pagamentos e Assinaturas.
class PaymentService {
  final ApiClient _api;

  PaymentService({required String token}) : _api = ApiClient(token: token);

  // ========================
  // ASSINATURAS
  // ========================

  /// Inicia o fluxo de assinatura de um plano, retornando uma URL de checkout.
  Future<AssinaturaResponse> iniciarAssinatura({
    required String planoCodigo,
  }) async {
    final response = await _api.post(
      '/api/v1/assinaturas/iniciar',
      body: {'planoCodigo': planoCodigo},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AssinaturaResponse.fromJson(data);
    }
    // O ApiClient já trata os erros 4xx e 5xx, então podemos apenas lançar uma exceção genérica.
    throw Exception('Falha ao iniciar o processo de assinatura.');
  }

  /// Busca assinatura ativa do usuário.
  Future<Map<String, dynamic>> getAssinaturaAtiva() async {
    final response = await _api.get('/api/v1/assinaturas/ativa');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erro ao buscar assinatura');
  }

  /// Cria/atualiza assinatura (assinar plano).
  Future<Map<String, dynamic>> assinar({
    required String planoCodigo,
  }) async {
    final response = await _api.post('/api/v1/assinaturas/iniciar',
        body: {'planoCodigo': planoCodigo});

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao assinar plano');
  }

  /// Cancela assinatura ativa.
  Future<Map<String, dynamic>> cancelarAssinatura() async {
    final response = await _api.delete('/api/v1/assinaturas/cancelar');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao cancelar assinatura');
  }

  /// Verifica se assinatura está ativa.
  Future<bool> isAssinaturaAtiva() async {
    final response = await _api.get('/api/v1/assinaturas/status');

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['ativa'] == true;
    }
    return false;
  }

  /// Histórico de assinaturas.
  Future<List<Map<String, dynamic>>> getHistoricoAssinaturas() async {
    final response = await _api.get('/api/v1/assinaturas/historico');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Erro ao buscar histórico');
  }

  // ========================
  // PAGAMENTOS
  // ========================

  /// Lista todos os pagamentos.
  Future<List<Map<String, dynamic>>> listarPagamentos() async {
    final response = await _api.get('/api/pagamento');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Erro ao listar pagamentos');
  }

  /// Lista pagamentos por tipo (ASSINATURA ou OS).
  Future<List<Map<String, dynamic>>> listarPorTipo(String tipo) async {
    final response = await _api.get('/api/pagamento/tipo/$tipo');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Erro ao listar pagamentos');
  }

  /// Cria novo pagamento.
  Future<Map<String, dynamic>> criarPagamento({
    required String tipo,
    int? referenciaId,
    String? descricao,
    required String metodoPagamento,
    required double valor,
    String? observacoes,
  }) async {
    final body = <String, dynamic>{
      'tipo': tipo,
      'metodoPagamento': metodoPagamento,
      'valor': valor,
    };
    if (referenciaId != null) body['referenciaId'] = referenciaId;
    if (descricao != null) body['descricao'] = descricao;
    if (observacoes != null) body['observacoes'] = observacoes;

    final response = await _api.post('/api/pagamento', body: body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final responseBody = jsonDecode(response.body);
    throw Exception(responseBody['error'] ?? 'Erro ao criar pagamento');
  }

  /// Confirma um pagamento.
  Future<Map<String, dynamic>> confirmarPagamento(int id) async {
    final response = await _api.put('/api/pagamento/$id/confirmar');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao confirmar pagamento');
  }

  /// Cancela um pagamento pendente.
  Future<Map<String, dynamic>> cancelarPagamento(int id) async {
    final response = await _api.put('/api/pagamento/$id/cancelar');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao cancelar pagamento');
  }

  /// Resumo financeiro.
  Future<Map<String, dynamic>> getResumoFinanceiro() async {
    final response = await _api.get('/api/pagamento/resumo');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erro ao carregar resumo financeiro');
  }
}
