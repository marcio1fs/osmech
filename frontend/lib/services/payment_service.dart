import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Serviço para comunicação com a API de Pagamentos e Assinaturas.
class PaymentService {
  final String token;

  PaymentService({required this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ========================
  // ASSINATURAS
  // ========================

  /// Busca assinatura ativa do usuário.
  Future<Map<String, dynamic>> getAssinaturaAtiva() async {
    final response = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/assinatura'), headers: _headers)
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erro ao buscar assinatura');
  }

  /// Cria/atualiza assinatura (assinar plano).
  Future<Map<String, dynamic>> assinar({
    required String planoCodigo,
    required String metodoPagamento,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/assinatura'),
          headers: _headers,
          body: jsonEncode({
            'planoCodigo': planoCodigo,
            'metodoPagamento': metodoPagamento,
          }),
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao assinar plano');
  }

  /// Cancela assinatura ativa.
  Future<Map<String, dynamic>> cancelarAssinatura() async {
    final response = await http
        .delete(
          Uri.parse('${ApiConfig.baseUrl}/assinatura'),
          headers: _headers,
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao cancelar assinatura');
  }

  /// Verifica se assinatura está ativa.
  Future<bool> isAssinaturaAtiva() async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/assinatura/status'),
          headers: _headers,
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['ativa'] == true;
    }
    return false;
  }

  /// Histórico de assinaturas.
  Future<List<Map<String, dynamic>>> getHistoricoAssinaturas() async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/assinatura/historico'),
          headers: _headers,
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

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
    final response = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/pagamento'), headers: _headers)
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Erro ao listar pagamentos');
  }

  /// Lista pagamentos por tipo (ASSINATURA ou OS).
  Future<List<Map<String, dynamic>>> listarPorTipo(String tipo) async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/pagamento/tipo/$tipo'),
          headers: _headers,
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

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

    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/pagamento'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final responseBody = jsonDecode(response.body);
    throw Exception(responseBody['error'] ?? 'Erro ao criar pagamento');
  }

  /// Confirma um pagamento.
  Future<Map<String, dynamic>> confirmarPagamento(int id) async {
    final response = await http
        .put(
          Uri.parse('${ApiConfig.baseUrl}/pagamento/$id/confirmar'),
          headers: _headers,
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao confirmar pagamento');
  }

  /// Cancela um pagamento pendente.
  Future<Map<String, dynamic>> cancelarPagamento(int id) async {
    final response = await http
        .put(
          Uri.parse('${ApiConfig.baseUrl}/pagamento/$id/cancelar'),
          headers: _headers,
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao cancelar pagamento');
  }

  /// Resumo financeiro.
  Future<Map<String, dynamic>> getResumoFinanceiro() async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/pagamento/resumo'),
          headers: _headers,
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erro ao carregar resumo financeiro');
  }
}
