import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class RelatorioService {
  final String? token;

  RelatorioService({this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<RelatorioExportado> exportarRelatorio({
    required String formato,
    required String tipo,
    DateTime? inicio,
    DateTime? fim,
    String? formatoPdf,
  }) async {
    final fmt = formato.toLowerCase();
    final endpoint = switch (fmt) {
      'pdf' => '/api/relatorios/exportar/pdf',
      'excel' => '/api/relatorios/exportar/excel',
      'csv' => '/api/relatorios/exportar/csv',
      _ => throw Exception('Formato de exportação inválido: $formato'),
    };

    final queryParams = <String, String>{
      'tipo': tipo,
      if (inicio != null) 'inicio': inicio.toIso8601String().split('T')[0],
      if (fim != null) 'fim': fim.toIso8601String().split('T')[0],
      if (fmt == 'pdf' && formatoPdf != null && formatoPdf.isNotEmpty)
        'formato': formatoPdf,
    };

    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final disposition = response.headers['content-disposition'];
      final filename = _parseFilename(disposition) ??
          'relatorio_${tipo}_${DateTime.now().toIso8601String().split('T')[0]}.$fmt';
      final contentType =
          response.headers['content-type'] ?? 'application/octet-stream';

      return RelatorioExportado(
        filename: filename,
        contentType: contentType,
        bytes: response.bodyBytes,
      );
    }

    throw Exception('Erro ao exportar relatório ($formato)');
  }

  String? _parseFilename(String? contentDisposition) {
    if (contentDisposition == null) return null;
    final match =
        RegExp(r'filename=\"?([^\";]+)\"?').firstMatch(contentDisposition);
    return match?.group(1);
  }

  // ==================== RELATÓRIOS DE OS ====================

  Future<List<Map<String, dynamic>>> getTiposRelatorioOs() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/relatorios/os/tipos'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Erro ao carregar tipos de relatório');
  }

  Future<Map<String, dynamic>> getRelatorioOsPeriodo(
      DateTime inicio, DateTime fim, String? status) async {
    final queryParams = {
      'inicio': inicio.toIso8601String().split('T')[0],
      'fim': fim.toIso8601String().split('T')[0],
      if (status != null) 'status': status,
    };
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/relatorios/os/periodo')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Erro ao gerar relatório de OS por período');
  }

  Future<List<Map<String, dynamic>>> getRelatorioOsPorMecanico(
      DateTime inicio, DateTime fim) async {
    final queryParams = {
      'inicio': inicio.toIso8601String().split('T')[0],
      'fim': fim.toIso8601String().split('T')[0],
    };
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/relatorios/os/mecanico')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Erro ao gerar relatório de OS por mecânico');
  }

  Future<List<Map<String, dynamic>>> getRelatorioOsPorVeiculo(
      DateTime inicio, DateTime fim) async {
    final queryParams = {
      'inicio': inicio.toIso8601String().split('T')[0],
      'fim': fim.toIso8601String().split('T')[0],
    };
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/relatorios/os/veiculo')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Erro ao gerar relatório de OS por veículo');
  }

  Future<List<Map<String, dynamic>>> getRelatorioOsPorCliente(
      DateTime inicio, DateTime fim) async {
    final queryParams = {
      'inicio': inicio.toIso8601String().split('T')[0],
      'fim': fim.toIso8601String().split('T')[0],
    };
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/relatorios/os/cliente')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Erro ao gerar relatório de OS por cliente');
  }

  // ==================== RELATÓRIOS FINANCEIROS ====================

  Future<Map<String, dynamic>> getRelatorioReceitas(
      DateTime inicio, DateTime fim) async {
    final queryParams = {
      'inicio': inicio.toIso8601String().split('T')[0],
      'fim': fim.toIso8601String().split('T')[0],
    };
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/relatorios/financeiro/receitas')
            .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Erro ao gerar relatório de receitas');
  }

  Future<Map<String, dynamic>> getRelatorioDespesas(
      DateTime inicio, DateTime fim) async {
    final queryParams = {
      'inicio': inicio.toIso8601String().split('T')[0],
      'fim': fim.toIso8601String().split('T')[0],
    };
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/relatorios/financeiro/despesas')
            .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Erro ao gerar relatório de despesas');
  }

  Future<Map<String, dynamic>> getRelatorioFluxoCaixa(
      DateTime inicio, DateTime fim) async {
    final queryParams = {
      'inicio': inicio.toIso8601String().split('T')[0],
      'fim': fim.toIso8601String().split('T')[0],
    };
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/relatorios/financeiro/caixa')
            .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Erro ao gerar relatório de fluxo de caixa');
  }

  Future<List<Map<String, dynamic>>> getRelatorioPorMetodoPagamento(
      DateTime inicio, DateTime fim) async {
    final queryParams = {
      'inicio': inicio.toIso8601String().split('T')[0],
      'fim': fim.toIso8601String().split('T')[0],
    };
    final uri = Uri.parse(
            '${ApiConfig.baseUrl}/api/relatorios/financeiro/metodo-pagamento')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Erro ao gerar relatório por método de pagamento');
  }

  // ==================== RELATÓRIOS DE CLIENTES ====================

  Future<List<Map<String, dynamic>>> getRelatorioClientesPorGasto(
      {int? limite}) async {
    final queryParams = {
      if (limite != null) 'limite': limite.toString(),
    };
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/relatorios/cliente/gastos')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Erro ao gerar relatório de clientes por gasto');
  }

  Future<List<Map<String, dynamic>>> getRelatorioClientesPorQuantidadeOs(
      {int? limite}) async {
    final queryParams = {
      if (limite != null) 'limite': limite.toString(),
    };
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/relatorios/cliente/quantidade-os')
            .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Erro ao gerar relatório de clientes por quantidade de OS');
  }

  Future<List<Map<String, dynamic>>> getRelatorioContatos() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/relatorios/cliente/contatos'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Erro ao gerar relatório de contatos');
  }

  // ==================== RELATÓRIOS DE ESTOQUE ====================

  Future<Map<String, dynamic>> getRelatorioValuationEstoque() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/relatorios/estoque/valuation'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Erro ao gerar relatório de valuation de estoque');
  }

  Future<List<Map<String, dynamic>>> getRelatorioEstoqueBaixo(
      {int limite = 10}) async {
    final queryParams = {'limite': limite.toString()};
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/relatorios/estoque/baixo-estoque')
            .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Erro ao gerar relatório de estoque baixo');
  }

  Future<List<Map<String, dynamic>>> getRelatorioMovimentacoes(
      DateTime inicio, DateTime fim) async {
    final queryParams = {
      'inicio': inicio.toIso8601String().split('T')[0],
      'fim': fim.toIso8601String().split('T')[0],
    };
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/relatorios/estoque/movimentacoes')
            .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Erro ao gerar relatório de movimentações de estoque');
  }
}

class RelatorioExportado {
  final String filename;
  final String contentType;
  final List<int> bytes;

  RelatorioExportado({
    required this.filename,
    required this.contentType,
    required this.bytes,
  });
}
