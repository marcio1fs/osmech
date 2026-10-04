import 'dart:convert';
import 'api_client.dart';

/// Serviço para operações administrativas de gerenciamento de usuários.
/// Requer permissão 'usuarios.*' no backend.
class AdminService {
  final ApiClient _api;

  AdminService({required String token}) : _api = ApiClient(token: token);

  // ─── Listagem ────────────────────────────────────────────────────────────

  /// Lista usuários com paginação.
  /// [page] começa em 0, [size] é o número de itens por página.
  Future<Map<String, dynamic>> listarUsuarios({int page = 0, int size = 20}) async {
    final response = await _api.get('/api/admin/usuarios?page=$page&size=$size');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao listar usuários');
  }

  /// Busca detalhes de um usuário específico.
  Future<Map<String, dynamic>> buscarUsuario(int id) async {
    final response = await _api.get('/api/admin/usuarios/$id');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Usuário não encontrado');
  }

  // ─── Criação ─────────────────────────────────────────────────────────────

  /// Cria um novo usuário.
  Future<Map<String, dynamic>> criarUsuario({
    required String nome,
    required String email,
    required String senha,
    required String role,
    String? telefone,
    bool ativo = true,
  }) async {
    final response = await _api.post('/api/admin/usuarios', body: {
      'nome': nome,
      'email': email,
      'senha': senha,
      'role': role,
      if (telefone != null) 'telefone': telefone,
      'ativo': ativo,
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao criar usuário');
  }

  // ─── Edição ──────────────────────────────────────────────────────────────

  /// Edita dados básicos de um usuário.
  Future<Map<String, dynamic>> editarUsuario(
    int id, {
    required String nome,
    String? telefone,
    String? senha,
    bool? ativo,
    String? role,
  }) async {
    final body = <String, dynamic>{
      'nome': nome,
      if (telefone != null) 'telefone': telefone,
      if (senha != null && senha.isNotEmpty) 'senha': senha,
      if (ativo != null) 'ativo': ativo,
      if (role != null) 'role': role,
    };
    final response = await _api.put('/api/admin/usuarios/$id', body: body);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final bodyResp = jsonDecode(response.body);
    throw Exception(bodyResp['error'] ?? 'Erro ao editar usuário');
  }

  // ─── Alteração de Role ────────────────────────────────────────────────────

  /// Altera o perfil/role de um usuário.
  Future<Map<String, dynamic>> alterarRole(int id, String novaRole) async {
    final response = await _api.patch('/api/admin/usuarios/$id/role', body: {
      'novaRole': novaRole,
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao alterar perfil');
  }

  // ─── Bloqueio / Desbloqueio ───────────────────────────────────────────────

  /// Bloqueia ou desbloqueia um usuário.
  Future<Map<String, dynamic>> alterarStatus(int id, {required bool ativo}) async {
    final response = await _api.patch(
      '/api/admin/usuarios/$id/status?ativo=$ativo',
      body: {},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao alterar status');
  }

  // ─── Reset de Senha ───────────────────────────────────────────────────────

  /// Reseta a senha do usuário e retorna a senha temporária.
  Future<String> resetarSenha(int id) async {
    final response = await _api.post('/api/admin/usuarios/$id/reset-senha', body: {});
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['senhaTemporaria'] ?? '';
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao resetar senha');
  }

  // ─── Exclusão ─────────────────────────────────────────────────────────────

  /// Exclui um usuário da oficina.
  Future<void> excluirUsuario(int id) async {
    final response = await _api.delete('/api/admin/usuarios/$id');
    if (response.statusCode == 200) return;
    try {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Erro ao excluir usuário');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro ao excluir usuário');
    }
  }

  // ─── Permissões Customizadas ──────────────────────────────────────────────

  /// Busca permissões detalhadas de um usuário (role + customizadas).
  Future<Map<String, dynamic>> buscarPermissoesUsuario(int id) async {
    final response = await _api.get('/api/admin/usuarios/$id/permissoes');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao buscar permissões do usuário');
  }

  /// Salva as permissões customizadas individuais de um usuário.
  Future<void> salvarPermissoesUsuario(int id, List<String> permissoes) async {
    final response = await _api.put('/api/admin/usuarios/$id/permissoes', body: permissoes);
    if (response.statusCode == 200) return;
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao salvar permissões');
  }

  // ─── Roles disponíveis ────────────────────────────────────────────────────

  /// Retorna o mapa de roles disponíveis com suas permissões.
  Future<Map<String, dynamic>> listarRoles() async {
    final response = await _api.get('/api/admin/usuarios/roles');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erro ao carregar roles');
  }

  // ─── Dashboard Admin (legado) ─────────────────────────────────────────────

  /// Busca dados consolidados de usuários para a tela de administração.
  Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await _api.get('/api/admin/dashboard');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Erro ao carregar dados do admin');
  }
}
