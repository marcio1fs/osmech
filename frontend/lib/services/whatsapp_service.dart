import 'package:http/http.dart' as http;
import 'auth_service.dart';

class WhatsAppService {
  static const String _baseUrl = 'http://localhost:8080/api/whatsapp/send';

  static Future<void> sendMessage(String to, String message) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse(_baseUrl + '?to=$to&message=${Uri.encodeComponent(message)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao enviar WhatsApp: ${response.body}');
    }
  }
}
