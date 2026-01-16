import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/ordem_servico.dart';

class OrdemServicoService {
  static const String _baseUrl = 'http://localhost:8080/api/os';

  static Future<List<OrdemServico>> getOrdens() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Token não encontrado. Faça login novamente.');
    }

    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => OrdemServico.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Não autorizado. Faça login novamente.');
    } else {
      throw Exception('Erro ao buscar ordens de serviço');
    }
  }

  static Future<OrdemServico> createOrdem(OrdemServico ordem) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Token não encontrado. Faça login novamente.');
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nomeCliente': ordem.nomeCliente,
        'telefone': ordem.telefone,
        'placa': ordem.placa,
        'modelo': ordem.modelo,
        'descricaoProblema': ordem.descricaoProblema,
        'servicosRealizados': ordem.servicosRealizados,
        'valor': ordem.valor,
        'status': ordem.status,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return OrdemServico.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erro ao cadastrar OS');
    }
  }

  static Future<OrdemServico> updateOrdem(int id, OrdemServico ordem) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Token não encontrado. Faça login novamente.');
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nomeCliente': ordem.nomeCliente,
        'telefone': ordem.telefone,
        'placa': ordem.placa,
        'modelo': ordem.modelo,
        'descricaoProblema': ordem.descricaoProblema,
        'servicosRealizados': ordem.servicosRealizados,
        'valor': ordem.valor,
        'status': ordem.status,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OrdemServico.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erro ao editar OS');
    }
  }

  static Future<void> deleteOrdem(int id) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Token não encontrado. Faça login novamente.');
    }

    final response = await http.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro ao excluir OS');
    }
  }
}
