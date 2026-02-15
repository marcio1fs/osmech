import 'dart:convert';
import 'api_client.dart';

/// Serviço de comunicação com a IA OSMECH.
class ChatService {
  final ApiClient _api;

  ChatService({required String token}) : _api = ApiClient(token: token);

  /// Enviar mensagem para a IA
  Future<Map<String, dynamic>> enviarMensagem(String message,
      {String? sessionId}) async {
    final body = {
      'message': message,
      if (sessionId != null) 'sessionId': sessionId,
    };
    final resp = await _api.post('/chat', body: body);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    throw Exception(
        jsonDecode(resp.body)['error'] ?? 'Erro ao enviar mensagem');
  }

  /// Buscar histórico de uma sessão
  Future<List<Map<String, dynamic>>> getHistorico(String sessionId) async {
    final resp = await _api.get('/chat/session/$sessionId');
    if (resp.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    }
    throw Exception('Erro ao buscar histórico');
  }

  /// Listar sessões
  Future<List<String>> getSessoes() async {
    final resp = await _api.get('/chat/sessions');
    if (resp.statusCode == 200) {
      return List<String>.from(jsonDecode(resp.body));
    }
    throw Exception('Erro ao listar sessões');
  }

  /// Deletar sessão
  Future<void> deletarSessao(String sessionId) async {
    final resp = await _api.delete('/chat/session/$sessionId');
    if (resp.statusCode != 200) {
      throw Exception('Erro ao deletar sessão');
    }
  }
}
