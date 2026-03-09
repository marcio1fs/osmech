import 'dart:convert';
import 'api_client.dart';

/// Serviço para gerenciamento do perfil do usuário.
class UserService {
  final ApiClient _api;

  UserService({required String token}) : _api = ApiClient(token: token);

  /// Busca dados do perfil do usuário logado.
  Future<Map<String, dynamic>> getPerfil() async {
    final response = await _api.get('/api/usuario/perfil');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erro ao carregar perfil');
  }

  /// Atualiza dados do perfil.
  Future<Map<String, dynamic>> atualizarPerfil({
    required String nome,
    String? telefone,
    String? nomeOficina,
    String? cnpjOficina,
    String? enderecoLogradouro,
    String? enderecoNumero,
    String? enderecoComplemento,
    String? enderecoBairro,
    String? enderecoCidade,
    String? enderecoEstado,
    String? enderecoCep,
    String? siteOficina,
  }) async {
    final response = await _api.put('/api/usuario/perfil', body: {
      'nome': nome,
      if (telefone != null) 'telefone': telefone,
      if (nomeOficina != null) 'nomeOficina': nomeOficina,
      if (cnpjOficina != null) 'cnpjOficina': cnpjOficina,
      if (enderecoLogradouro != null) 'enderecoLogradouro': enderecoLogradouro,
      if (enderecoNumero != null) 'enderecoNumero': enderecoNumero,
      if (enderecoComplemento != null)
        'enderecoComplemento': enderecoComplemento,
      if (enderecoBairro != null) 'enderecoBairro': enderecoBairro,
      if (enderecoCidade != null) 'enderecoCidade': enderecoCidade,
      if (enderecoEstado != null) 'enderecoEstado': enderecoEstado,
      if (enderecoCep != null) 'enderecoCep': enderecoCep,
      if (siteOficina != null) 'siteOficina': siteOficina,
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao atualizar perfil');
  }

  /// Altera a senha do usuário.
  Future<void> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    final response = await _api.put('/api/usuario/senha', body: {
      'senhaAtual': senhaAtual,
      'novaSenha': novaSenha,
    });
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Erro ao alterar senha');
    }
  }
}
