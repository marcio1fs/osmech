import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class OrdemServico {
  final int id;
  final String descricao;
  final String status;
  final String usuario;
  final String telefone;

  OrdemServico({required this.id, required this.descricao, required this.status, required this.usuario, required this.telefone});

  factory OrdemServico.fromJson(Map<String, dynamic> json) {
    return OrdemServico(
      id: json['id'],
      descricao: json['descricao'],
      status: json['status'],
      usuario: json['usuario'] ?? '',
      telefone: json['telefone'] ?? '',
    );
  }
}

class OrdemServicoService {
    static Future<void> deleteOrdem(int id) async {
      final token = await AuthService.getToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Erro ao excluir OS');
      }
    }
  static Future<void> updateOrdem(OrdemServico ordem, String descricao, String status) async {
    final token = await AuthService.getToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/${ordem.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'descricao': descricao,
        'status': status,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao editar OS');
    }
  }
  static const String _baseUrl = 'http://localhost:8080/api/os';

  static Future<List<OrdemServico>> getOrdens() async {
    final token = await AuthService.getToken();
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

  static Future<void> createOrdem(String descricao, String status) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'descricao': descricao,
        'status': status,
        // 'usuarioId': ... // pode ser preenchido pelo backend via JWT
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao cadastrar OS');
    }
  }
}
