import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class Plan {
  final String name;
  final double price;
  final String description;

  Plan({required this.name, required this.price, required this.description});

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      description: json['description'],
    );
  }
}

class PlanService {
  static const String _baseUrl = 'http://localhost:8080/api/plans';

  static Future<List<Plan>> getPlans() async {
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
      return data.map((e) => Plan.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Não autorizado. Faça login novamente.');
    } else {
      throw Exception('Erro ao buscar planos');
    }
  }
}
