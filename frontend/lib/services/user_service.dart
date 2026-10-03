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
  /// Lista as sessões ativas do usuário (a atual vem marcada).
  Future<List<Map<String, dynamic>>> listarSessoes({String? refreshToken}) async {
    final response = await _api.post('/api/usuario/sessoes',
        body: refreshToken == null ? {} : {'refreshToken': refreshToken});
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao listar sessões');
  }

  /// Encerra todas as sessões do usuário ("sair de todos os dispositivos").
  Future<void> logoutTodasSessoes() async {
    final response = await _api.post('/api/usuario/logout-todos', body: {});
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Erro ao encerrar sessões');
    }
  }

  /// Ativa ou desativa o 2FA por código de e-mail (Fase 4). Exige a senha.
  Future<void> alterar2fa({required String senha, required bool ativar}) async {
    final path = ativar ? '/api/usuario/2fa/ativar' : '/api/usuario/2fa/desativar';
    final response = await _api.put(path, body: {'senha': senha});
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Erro ao alterar 2FA');
    }
  }

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

  /// Faz o upload da logo da oficina.
  Future<String> uploadLogo(List<int> bytes, String filename) async {
    final response = await _api.multipart('/api/usuario/logo', fileField: 'file', fileBytes: bytes, filename: filename);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['logoUrl'];
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao fazer upload da logo');
  }

  /// Busca dados consolidados de usuários para a tela de administração.
  Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await _api.get('/api/admin/dashboard');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao carregar dados do admin');
  }

  /// Lista usuários paginados para a administração (busca por nome/e-mail/oficina).
  Future<Map<String, dynamic>> listarUsuariosAdmin(
      {String? termo, int pagina = 0, int tamanho = 25}) async {
    final params = <String, String>{
      'pagina': '$pagina',
      'tamanho': '$tamanho',
    };
    if (termo != null && termo.trim().isNotEmpty) params['termo'] = termo.trim();
    final query = Uri(queryParameters: params).query;
    final response = await _api.get('/api/admin/contas?$query');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao listar usuários');
  }

  /// Ativa/inativa a conta de um usuário (admin).
  Future<Map<String, dynamic>> adminDefinirAtivo(int id, bool ativo) async {
    final response =
        await _api.put('/api/admin/usuarios/$id/ativo', body: {'ativo': ativo});
    if (response.statusCode == 200) return jsonDecode(response.body);
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao atualizar status');
  }

  /// Altera o plano de um usuário (admin).
  Future<Map<String, dynamic>> adminDefinirPlano(int id, String plano) async {
    final response = await _api
        .put('/api/admin/usuarios/$id/plano', body: {'plano': plano});
    if (response.statusCode == 200) return jsonDecode(response.body);
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao alterar plano');
  }

  /// Altera o papel (role) de um usuário (admin).
  Future<Map<String, dynamic>> adminDefinirPapel(int id, String role) async {
    final response =
        await _api.put('/api/admin/usuarios/$id/role', body: {'role': role});
    if (response.statusCode == 200) return jsonDecode(response.body);
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao alterar papel');
  }
}
