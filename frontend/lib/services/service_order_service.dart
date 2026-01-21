import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/service_order.dart';
import 'auth_service.dart';

class ServiceOrderService {
  static const String baseUrl = 'http://localhost:8080/api/service-orders';
  final AuthService authService;

  ServiceOrderService(this.authService);

  /// Lista todas as ordens de serviço do usuário
  Future<List<ServiceOrder>> getServiceOrders() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: authService.authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ServiceOrder.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao buscar ordens de serviço');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao buscar ordens de serviço: $e');
      }
      rethrow;
    }
  }

  /// Cria uma nova ordem de serviço
  Future<ServiceOrder?> createServiceOrder(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: authService.authHeaders,
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        return ServiceOrder.fromJson(jsonDecode(response.body));
      } else {
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao criar ordem de serviço: $e');
      }
      return null;
    }
  }

  /// Atualiza uma ordem de serviço
  Future<ServiceOrder?> updateServiceOrder(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: authService.authHeaders,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return ServiceOrder.fromJson(jsonDecode(response.body));
      } else {
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao atualizar ordem de serviço: $e');
      }
      return null;
    }
  }

  /// Deleta uma ordem de serviço
  Future<bool> deleteServiceOrder(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: authService.authHeaders,
      );

      return response.statusCode == 204;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao deletar ordem de serviço: $e');
      }
      return false;
    }
  }
}
