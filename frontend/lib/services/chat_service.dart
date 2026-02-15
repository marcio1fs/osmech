import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Serviço de comunicação com a IA OSMECH.
class ChatService {
  final String token;
  ChatService({required this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Enviar mensagem para a IA
  Future<Map<String, dynamic>> enviarMensagem(String message,
      {String? sessionId}) async {
    final body = {
      'message': message,
      if (sessionId != null) 'sessionId': sessionId,
    };
    final resp = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/chat'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    throw Exception(
        jsonDecode(resp.body)['error'] ?? 'Erro ao enviar mensagem');
  }

  /// Buscar histórico de uma sessão
  Future<List<Map<String, dynamic>>> getHistorico(String sessionId) async {
    final resp = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/chat/session/$sessionId'),
      headers: _headers,
    );
    if (resp.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    }
    throw Exception('Erro ao buscar histórico');
  }

  /// Listar sessões
  Future<List<String>> getSessoes() async {
    final resp = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/chat/sessions'),
      headers: _headers,
    );
    if (resp.statusCode == 200) {
      return List<String>.from(jsonDecode(resp.body));
    }
    throw Exception('Erro ao listar sessões');
  }

  /// Deletar sessão
  Future<void> deletarSessao(String sessionId) async {
    final resp = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/chat/session/$sessionId'),
      headers: _headers,
    );
    if (resp.statusCode != 200) {
      throw Exception('Erro ao deletar sessão');
    }
  }
}
