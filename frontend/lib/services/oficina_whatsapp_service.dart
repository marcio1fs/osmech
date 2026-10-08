import 'dart:convert';
import 'api_client.dart';

/// Modelo de configuração de WhatsApp da Oficina (Z-API).
class OficinaWhatsAppConfig {
  final String provider;
  final String? instanceId;
  final String? token;
  final String? clientToken;
  final bool ativo;
  final bool? connected;

  OficinaWhatsAppConfig({
    required this.provider,
    this.instanceId,
    this.token,
    this.clientToken,
    required this.ativo,
    this.connected,
  });

  factory OficinaWhatsAppConfig.fromJson(Map<String, dynamic> json) {
    return OficinaWhatsAppConfig(
      provider: json['provider'] ?? 'ZAPI',
      instanceId: json['instanceId'],
      token: json['token'],
      clientToken: json['clientToken'],
      ativo: json['ativo'] ?? false,
      connected: json['connected'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'instanceId': instanceId,
      'token': token,
      'clientToken': clientToken,
      'ativo': ativo,
    };
  }
}

/// Serviço para consultar e gerenciar as credenciais do Z-API da oficina.
class OficinaWhatsAppService {
  final ApiClient _api;

  OficinaWhatsAppService({required String token})
      : _api = ApiClient(token: token);

  /// Obtém a configuração atual do WhatsApp da oficina e o status de conexão no Z-API.
  Future<OficinaWhatsAppConfig> getConfig() async {
    final response = await _api.get('/api/oficina/whatsapp');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OficinaWhatsAppConfig.fromJson(data);
    }
    throw Exception('Falha ao carregar configurações do WhatsApp');
  }

  /// Salva as credenciais do Z-API da oficina.
  Future<OficinaWhatsAppConfig> salvarConfig({
    required String provider,
    String? instanceId,
    String? token,
    String? clientToken,
    required bool ativo,
  }) async {
    final response = await _api.put('/api/oficina/whatsapp', body: {
      'provider': provider,
      'instanceId': instanceId,
      'token': token,
      'clientToken': clientToken,
      'ativo': ativo,
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OficinaWhatsAppConfig.fromJson(data);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Falha ao salvar configurações do WhatsApp');
  }

  /// Dispara uma mensagem de teste para verificar se o Z-API está funcional.
  Future<Map<String, dynamic>> testarEnvio({required String telefone}) async {
    final response = await _api.post('/api/oficina/whatsapp/testar', body: {
      'telefone': telefone,
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Falha ao enviar mensagem de teste');
  }
}
