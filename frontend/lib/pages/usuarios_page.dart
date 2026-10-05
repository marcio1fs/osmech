import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import '../theme/app_theme.dart';

/// Tela de gerenciamento de usuários da oficina.
/// Acessível por ADMIN e GERENTE com permissão 'usuarios.visualizar'.
class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  late AdminService _adminService;
  List<Map<String, dynamic>> _usuarios = [];
  bool _loading = true;
  String? _erro;
  int _pagina = 0;
  int _totalPages = 1;
  String _filtroRole = 'TODOS';
  String _filtroStatus = 'TODOS';

  static const _roles = [
    'TODOS',
    'ADMIN',
    'DONO',
    'GERENTE',
    'OFICINA',
    'VENDEDOR',
    'ATENDENTE',
    'MECANICO',
    'ESTOQUISTA',
    'FINANCEIRO',
  ];

  static const _rolesParaCadastro = [
    'GERENTE',
    'VENDEDOR',
    'ATENDENTE',
    'MECANICO',
    'ESTOQUISTA',
    'FINANCEIRO',
  ];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _adminService = AdminService(token: auth.token ?? '');
    _carregarUsuarios();
  }

  Future<void> _carregarUsuarios() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final data = await _adminService.listarUsuarios(page: _pagina, size: 20);
      final content = (data['content'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [];
      if (!mounted) return;
      setState(() {
        _usuarios = content;
        _totalPages = data['totalPages'] ?? 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _usuariosFiltrados {
    return _usuarios.where((u) {
      final roleOk = _filtroRole == 'TODOS' || u['role'] == _filtroRole;
      final statusOk = _filtroStatus == 'TODOS' ||
          (_filtroStatus == 'ATIVO' && u['ativo'] == true) ||
          (_filtroStatus == 'BLOQUEADO' && u['ativo'] == false);
      return roleOk && statusOk;
    }).toList();
  }

  // ─── Ações ─────────────────────────────────────────────────────────────────

  void _abrirModalNovoUsuario() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UsuarioFormDialog(
        adminService: _adminService,
        rolesDisponiveis: _rolesParaCadastro,
        onSalvo: _carregarUsuarios,
      ),
    );
  }

  void _abrirModalEditarUsuario(Map<String, dynamic> usuario) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UsuarioFormDialog(
        adminService: _adminService,
        rolesDisponiveis: _rolesParaCadastro,
        usuario: usuario,
        onSalvo: _carregarUsuarios,
      ),
    );
  }

  Future<void> _alterarStatus(Map<String, dynamic> usuario) async {
    final bool novoStatus = !(usuario['ativo'] == true);
    final acao = novoStatus ? 'desbloquear' : 'bloquear';
    final confirmado = await _confirmar(
      'Confirmar ação',
      'Deseja $acao o usuário "${usuario['nome']}"?',
    );
    if (!confirmado) return;
    try {
      await _adminService.alterarStatus(usuario['id'], ativo: novoStatus);
      _carregarUsuarios();
      _mostrarSucesso(novoStatus ? 'Usuário desbloqueado' : 'Usuário bloqueado');
    } catch (e) {
      _mostrarErro(e.toString());
    }
  }

  Future<void> _alterarRole(Map<String, dynamic> usuario) async {
    final auth = context.read<AuthService>();
    String? selectedRole = usuario['role'];

    final roles = auth.isAdmin
        ? ['ADMIN', ..._rolesParaCadastro]
        : _rolesParaCadastro;

    await showDialog(
      context: context,
      builder: (ctx) {
        String? localRole = selectedRole;
        return AlertDialog(
          backgroundColor: AppColors.cardBg,
          title: Text(
            'Alterar Perfil — ${usuario['nome']}',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) => RadioGroup<String>(
              groupValue: localRole,
              onChanged: (v) => setStateDialog(() => localRole = v),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: roles.map((r) {
                  return RadioListTile<String>(
                    value: r,
                    title: Text(
                      _labelRole(r),
                      style: GoogleFonts.inter(color: Colors.white70),
                    ),
                    activeColor: AppColors.accent,
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancelar',
                  style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: localRole == null
                  ? null
                  : () async {
                      Navigator.of(ctx).pop();
                      try {
                        await _adminService.alterarRole(
                            usuario['id'], localRole!);
                        _carregarUsuarios();
                        _mostrarSucesso('Perfil alterado com sucesso');
                      } catch (e) {
                        _mostrarErro(e.toString());
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetarSenha(Map<String, dynamic> usuario) async {
    final confirmado = await _confirmar(
      'Resetar Senha',
      'Gerar uma senha temporária para "${usuario['nome']}"?',
    );
    if (!confirmado) return;
    try {
      final senhaTemp = await _adminService.resetarSenha(usuario['id']);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          title: Text('Senha Temporária Gerada',
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Compartilhe com o usuário:',
                  style: GoogleFonts.inter(color: Colors.white60)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.sidebarBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                ),
                child: SelectableText(
                  senhaTemp,
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 18,
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Text('O usuário deve alterar a senha no próximo login.',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Fechar',
                  style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
      );
    } catch (e) {
      _mostrarErro(e.toString());
    }
  }

  Future<void> _excluirUsuario(Map<String, dynamic> usuario) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text('Excluir Usuário',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          'Tem certeza que deseja excluir o usuário "${usuario['nome']}" (${usuario['email']})?\nEsta ação não poderá ser desfeita.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir Definitivamente'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await _adminService.excluirUsuario(usuario['id']);
      _carregarUsuarios();
      _mostrarSucesso('Usuário excluído com sucesso');
    } catch (e) {
      _mostrarErro(e.toString());
    }
  }

  void _abrirModalPermissoesUsuario(Map<String, dynamic> usuario) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UsuarioPermissoesDialog(
        usuario: usuario,
        adminService: _adminService,
        onAtualizado: _carregarUsuarios,
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<bool> _confirmar(String titulo, String mensagem) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text(titulo,
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w600)),
        content:
            Text(mensagem, style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _mostrarSucesso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _mostrarErro(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg.replaceAll('Exception: ', '')),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _labelRole(String role) {
    switch (role) {
      case 'ADMIN': return 'Administrador';
      case 'DONO': return 'Dono da Oficina';
      case 'GERENTE': return 'Gerente';
      case 'OFICINA': return 'Dono de Oficina';
      case 'VENDEDOR': return 'Vendedor';
      case 'ATENDENTE': return 'Atendente';
      case 'MECANICO': return 'Mecânico';
      case 'ESTOQUISTA': return 'Estoquista';
      case 'FINANCEIRO': return 'Financeiro';
      default: return role;
    }
  }

  Color _corRole(String role) {
    switch (role) {
      case 'ADMIN': return const Color(0xFFE040FB);
      case 'DONO': return const Color(0xFF7C4DFF);
      case 'GERENTE':
      case 'OFICINA': return const Color(0xFF42A5F5);
      case 'VENDEDOR': return const Color(0xFF26A69A);
      case 'ATENDENTE': return const Color(0xFF26C6DA);
      case 'MECANICO': return const Color(0xFF66BB6A);
      case 'ESTOQUISTA': return const Color(0xFFFF7043);
      case 'FINANCEIRO': return const Color(0xFFFFCA28);
      default: return Colors.grey;
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final podecriar = auth.hasPermission('usuarios.criar');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Cabeçalho ────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.manage_accounts_rounded,
                      color: AppColors.accent, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gerenciamento de Usuários',
                          style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text(
                          'Crie, edite e gerencie os membros da sua oficina',
                          style: GoogleFonts.inter(
                              color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ),
                if (podecriar)
                  ElevatedButton.icon(
                    onPressed: _abrirModalNovoUsuario,
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: const Text('Novo Usuário'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── Filtros ──────────────────────────────────────────────────
            Row(
              children: [
                _filtroChip('Perfil:', _filtroRole, _roles,
                    (v) => setState(() => _filtroRole = v)),
                const SizedBox(width: 16),
                _filtroChip('Status:', _filtroStatus,
                    ['TODOS', 'ATIVO', 'BLOQUEADO'],
                    (v) => setState(() => _filtroStatus = v)),
                const Spacer(),
                IconButton(
                  onPressed: _carregarUsuarios,
                  icon: const Icon(Icons.refresh_rounded),
                  color: Colors.white60,
                  tooltip: 'Atualizar lista',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ─── Conteúdo principal ────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accent))
                  : _erro != null
                      ? _buildErro()
                      : _buildTabela(),
            ),

            // ─── Paginação ────────────────────────────────────────────────
            if (!_loading && _erro == null && _totalPages > 1)
              _buildPaginacao(),
          ],
        ),
      ),
    );
  }

  Widget _filtroChip(String label, String valor, List<String> opcoes,
      void Function(String) onChanged) {
    return Row(
      children: [
        Text(label,
            style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: valor,
              dropdownColor: AppColors.cardBg,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              items: opcoes
                  .map((o) => DropdownMenuItem(
                      value: o,
                      child: Text(o == 'TODOS' ? 'Todos' : _labelRole(o))))
                  .toList(),
              onChanged: (v) => v != null ? onChanged(v) : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErro() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 48),
          const SizedBox(height: 12),
          Text(_erro!.replaceAll('Exception: ', ''),
              style: GoogleFonts.inter(color: Colors.red.shade300)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _carregarUsuarios,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabela() {
    final lista = _usuariosFiltrados;
    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_rounded, size: 56, color: Colors.white24),
            const SizedBox(height: 12),
            Text('Nenhum usuário encontrado',
                style: GoogleFonts.inter(color: Colors.white54)),
          ],
        ),
      );
    }

    final auth = context.read<AuthService>();
    final podeEditar = auth.hasPermission('usuarios.editar');
    final podeBloq = auth.hasPermission('usuarios.bloquear');
    final podeAlterarPerfil = auth.hasPermission('usuarios.alterar_perfil');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 980),
            child: SingleChildScrollView(
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: const {
                  0: FlexColumnWidth(2.3),
                  1: FlexColumnWidth(2.3),
                  2: FlexColumnWidth(1.3),
                  3: FlexColumnWidth(1.1),
                  4: FlexColumnWidth(1.6),
                  5: FixedColumnWidth(225),
                },
                children: [
                  // Header
                  TableRow(
                    decoration: BoxDecoration(
                      color: AppColors.sidebarBg,
                    ),
                    children: [
                      _headerCell('Nome'),
                      _headerCell('E-mail'),
                      _headerCell('Perfil'),
                      _headerCell('Status'),
                      _headerCell('Último acesso'),
                      _headerCell('Ações'),
                    ],
                  ),
                  ...lista.map((u) {
                    final ativo = u['ativo'] == true;
                    final role = u['role'] as String? ?? '—';
                    return TableRow(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.04)),
                        ),
                      ),
                      children: [
                        _cell(InkWell(
                          onTap: () => _abrirModalPermissoesUsuario(u),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                      _corRole(role).withValues(alpha: 0.15),
                                  child: Text(
                                    (u['nome'] as String? ?? '?')
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: GoogleFonts.inter(
                                        color: _corRole(role),
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        u['nome'] as String? ?? '—',
                                        style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Ver permissões ↗',
                                        style: GoogleFonts.inter(
                                            color: AppColors.accentLight
                                                .withValues(alpha: 0.7),
                                            fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                        _cell(Text(
                          u['email'] as String? ?? '—',
                          style: GoogleFonts.inter(
                              color: Colors.white70, fontSize: 12),
                        )),
                        _cell(_roleBadge(role)),
                        _cell(_statusBadge(ativo)),
                        _cell(Text(
                          _formatarData(u['ultimoAcesso']),
                          style: GoogleFonts.inter(
                              color: Colors.white54, fontSize: 12),
                        )),
                        _cell(Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _actionButton(
                              icon: Icons.shield_outlined,
                              tooltip: 'Permissões customizadas',
                              color: Colors.cyan.shade300,
                              onTap: () => _abrirModalPermissoesUsuario(u),
                            ),
                            if (podeEditar)
                              _actionButton(
                                icon: Icons.edit_rounded,
                                tooltip: 'Editar dados',
                                onTap: () => _abrirModalEditarUsuario(u),
                              ),
                            if (podeAlterarPerfil)
                              _actionButton(
                                icon: Icons.swap_horiz_rounded,
                                tooltip: 'Alterar perfil',
                                onTap: () => _alterarRole(u),
                              ),
                            if (podeBloq)
                              _actionButton(
                                icon: ativo
                                    ? Icons.block_rounded
                                    : Icons.check_circle_rounded,
                                tooltip: ativo ? 'Bloquear' : 'Desbloquear',
                                color: ativo
                                    ? Colors.orange.shade400
                                    : Colors.green.shade400,
                                onTap: () => _alterarStatus(u),
                              ),
                            if (podeEditar)
                              _actionButton(
                                icon: Icons.key_rounded,
                                tooltip: 'Resetar senha',
                                color: Colors.purple.shade300,
                                onTap: () => _resetarSenha(u),
                              ),
                            if (podeBloq)
                              _actionButton(
                                icon: Icons.delete_outline_rounded,
                                tooltip: 'Excluir usuário',
                                color: Colors.red.shade400,
                                onTap: () => _excluirUsuario(u),
                              ),
                          ],
                        )),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
            color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600,
            letterSpacing: 0.5),
      ),
    );
  }

  Widget _cell(Widget child) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: child);
  }

  Widget _roleBadge(String role) {
    final cor = _corRole(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withValues(alpha: 0.4)),
      ),
      child: Text(_labelRole(role),
          style: GoogleFonts.inter(
              color: cor, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _statusBadge(bool ativo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ativo
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: ativo
                ? Colors.green.withValues(alpha: 0.4)
                : Colors.red.withValues(alpha: 0.4)),
      ),
      child: Text(ativo ? 'Ativo' : 'Bloqueado',
          style: GoogleFonts.inter(
              color: ativo ? Colors.green.shade400 : Colors.red.shade400,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 17, color: color ?? Colors.white60),
        ),
      ),
    );
  }

  Widget _buildPaginacao() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _pagina > 0
                ? () {
                    setState(() => _pagina--);
                    _carregarUsuarios();
                  }
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
            color: Colors.white70,
          ),
          Text('Página ${_pagina + 1} de $_totalPages',
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
          IconButton(
            onPressed: _pagina < _totalPages - 1
                ? () {
                    setState(() => _pagina++);
                    _carregarUsuarios();
                  }
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
            color: Colors.white70,
          ),
        ],
      ),
    );
  }

  String _formatarData(dynamic iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso.toString());
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '—';
    }
  }
}

// ─── Dialog de formulário de usuário ─────────────────────────────────────────

class _UsuarioFormDialog extends StatefulWidget {
  final AdminService adminService;
  final List<String> rolesDisponiveis;
  final Map<String, dynamic>? usuario;
  final VoidCallback onSalvo;

  const _UsuarioFormDialog({
    required this.adminService,
    required this.rolesDisponiveis,
    this.usuario,
    required this.onSalvo,
  });

  @override
  State<_UsuarioFormDialog> createState() => _UsuarioFormDialogState();
}

class _UsuarioFormDialogState extends State<_UsuarioFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nome;
  late TextEditingController _email;
  final _senha = TextEditingController();
  late TextEditingController _telefone;
  String? _roleSelecionada;
  bool _ativo = true;
  bool _saving = false;
  bool _obscureSenha = true;

  bool get isEdicao => widget.usuario != null;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _nome = TextEditingController(text: u?['nome'] ?? '');
    _email = TextEditingController(text: u?['email'] ?? '');
    _telefone = TextEditingController(text: u?['telefone'] ?? '');
    final roleAtual = (u?['role'] as String?) ?? '';
    _roleSelecionada =
        roleAtual.isNotEmpty ? roleAtual : widget.rolesDisponiveis.first;
    _ativo = u?['ativo'] ?? true;
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _telefone.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      if (isEdicao) {
        await widget.adminService.editarUsuario(
          widget.usuario!['id'],
          nome: _nome.text.trim(),
          telefone: _telefone.text.trim().isNotEmpty ? _telefone.text.trim() : null,
          senha: _senha.text.isNotEmpty ? _senha.text : null,
          ativo: _ativo,
          role: _roleSelecionada,
        );
      } else {
        await widget.adminService.criarUsuario(
          nome: _nome.text.trim(),
          email: _email.text.trim(),
          senha: _senha.text,
          role: _roleSelecionada!,
          telefone: _telefone.text.trim().isNotEmpty ? _telefone.text.trim() : null,
          ativo: _ativo,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSalvo();
    } catch (e) {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: Colors.red.shade700,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Row(children: [
                Icon(
                    isEdicao
                        ? Icons.edit_rounded
                        : Icons.person_add_rounded,
                    color: AppColors.accent),
                const SizedBox(width: 10),
                Text(
                  isEdicao ? 'Editar Usuário' : 'Novo Usuário',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ]),
              const SizedBox(height: 24),

              // Nome
              _buildField(
                controller: _nome,
                label: 'Nome completo',
                icon: Icons.person_rounded,
                validator: (v) =>
                    (v == null || v.trim().length < 2) ? 'Nome inválido' : null,
              ),
              const SizedBox(height: 14),

              // E-mail (desabilitado na edição)
              _buildField(
                controller: _email,
                label: 'E-mail',
                icon: Icons.email_rounded,
                enabled: !isEdicao,
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
              ),
              const SizedBox(height: 14),

              // Senha
              _buildField(
                controller: _senha,
                label: isEdicao ? 'Nova senha (opcional)' : 'Senha',
                icon: Icons.lock_rounded,
                obscure: _obscureSenha,
                suffix: IconButton(
                  icon: Icon(
                      _obscureSenha
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 18,
                      color: Colors.white38),
                  onPressed: () =>
                      setState(() => _obscureSenha = !_obscureSenha),
                ),
                validator: (v) {
                  if (!isEdicao && (v == null || v.length < 8)) {
                    return 'Senha deve ter ao menos 8 caracteres';
                  }
                  if (isEdicao && v != null && v.isNotEmpty && v.length < 8) {
                    return 'Nova senha deve ter ao menos 8 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Telefone
              _buildField(
                controller: _telefone,
                label: 'Telefone (opcional)',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),

              // Role
              DropdownButtonFormField<String>(
                initialValue: _roleSelecionada,
                dropdownColor: AppColors.sidebarBg,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: _inputDecoration('Perfil de Acesso',
                    Icons.verified_user_rounded),
                // Garante que a role atual do usuário sempre esteja entre os
                // itens (ex.: ADMIN/DONO/OFICINA ao editar) — caso contrário o
                // Flutter lança assertion de "exactly one item with value".
                items: <String>{
                  ...widget.rolesDisponiveis,
                  if (_roleSelecionada != null && _roleSelecionada!.isNotEmpty)
                    _roleSelecionada!,
                }
                    .map((r) => DropdownMenuItem(
                        value: r, child: Text(_labelRole(r))))
                    .toList(),
                onChanged: (v) => setState(() => _roleSelecionada = v),
                validator: (v) =>
                    v == null ? 'Selecione um perfil' : null,
              ),
              const SizedBox(height: 14),

              // Status
              SwitchListTile(
                value: _ativo,
                onChanged: (v) => setState(() => _ativo = v),
                title: Text('Usuário ativo',
                    style: GoogleFonts.inter(
                        color: Colors.white70, fontSize: 14)),
                activeThumbColor: AppColors.accent,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),

              // Botões
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    child: Text('Cancelar',
                        style: TextStyle(color: Colors.white60)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _saving ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(isEdicao ? 'Salvar' : 'Criar Usuário'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscure = false,
    Widget? suffix,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: _inputDecoration(label, icon).copyWith(suffixIcon: suffix),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.white38, size: 18),
      filled: true,
      fillColor: AppColors.sidebarBg,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white12)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white12)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.accent, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade400)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5)),
      disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
    );
  }

  String _labelRole(String role) {
    switch (role) {
      case 'ADMIN': return 'Administrador';
      case 'GERENTE': return 'Gerente';
      case 'VENDEDOR': return 'Vendedor';
      case 'ATENDENTE': return 'Atendente';
      case 'MECANICO': return 'Mecânico';
      case 'ESTOQUISTA': return 'Estoquista';
      case 'FINANCEIRO': return 'Financeiro';
      default: return role;
    }
  }
}

// ─── Modal de Gestão de Permissões Granulares por Usuário ────────────────────

class _UsuarioPermissoesDialog extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final AdminService adminService;
  final VoidCallback onAtualizado;

  const _UsuarioPermissoesDialog({
    required this.usuario,
    required this.adminService,
    required this.onAtualizado,
  });

  @override
  State<_UsuarioPermissoesDialog> createState() =>
      _UsuarioPermissoesDialogState();
}

class _UsuarioPermissoesDialogState extends State<_UsuarioPermissoesDialog> {
  bool _loading = true;
  bool _saving = false;
  String? _erro;

  List<dynamic> _todasPermissoes = [];
  Set<String> _rolePermissions = {};
  Set<String> _customPermissions = {};
  String _filtroModulo = 'TODOS';
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final dados = await widget.adminService
          .buscarPermissoesUsuario(widget.usuario['id']);
      if (!mounted) return;

      setState(() {
        _todasPermissoes = dados['todasPermissoes'] as List? ?? [];
        _rolePermissions = ((dados['rolePermissions'] as List?) ?? [])
            .map((e) => e.toString())
            .toSet();
        _customPermissions = ((dados['customPermissions'] as List?) ?? [])
            .map((e) => e.toString())
            .toSet();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _salvar() async {
    setState(() => _saving = true);
    try {
      await widget.adminService.salvarPermissoesUsuario(
        widget.usuario['id'],
        _customPermissions.toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onAtualizado();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissões do usuário atualizadas com sucesso!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<String> get _modulosDisponiveis {
    final mods = <String>{'TODOS'};
    for (final p in _todasPermissoes) {
      if (p is Map && p['modulo'] != null) {
        mods.add(p['modulo'].toString());
      }
    }
    return mods.toList();
  }

  List<dynamic> get _permissoesFiltradas {
    return _todasPermissoes.where((p) {
      if (p is! Map) return false;
      final mod = p['modulo']?.toString() ?? '';
      final code = p['code']?.toString().toLowerCase() ?? '';
      final desc = p['descricao']?.toString().toLowerCase() ?? '';

      final modOk = _filtroModulo == 'TODOS' || mod == _filtroModulo;
      final buscaOk = _busca.isEmpty ||
          code.contains(_busca.toLowerCase()) ||
          desc.contains(_busca.toLowerCase());

      return modOk && buscaOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final nome = widget.usuario['nome'] ?? 'Usuário';
    final email = widget.usuario['email'] ?? '';
    final role = widget.usuario['role'] ?? '—';

    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 780,
        height: 640,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ──────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: Colors.cyanAccent, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Permissões de Acesso — $nome',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            email,
                            style: GoogleFonts.inter(
                                color: Colors.white54, fontSize: 13),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Perfil: $role',
                              style: GoogleFonts.inter(
                                color: AppColors.accentLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white60),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.sidebarBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Colors.cyanAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'As permissões marcadas em azul vêm do perfil base ($role). '
                      'Você pode ativar permissões adicionais exclusivas (verde) sob medida para este usuário.',
                      style: GoogleFonts.inter(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Barra de Filtros ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _busca = v),
                    style:
                        GoogleFonts.inter(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome ou código da permissão...',
                      hintStyle: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: Colors.white38, size: 18),
                      filled: true,
                      fillColor: AppColors.sidebarBg,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColors.accent, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.sidebarBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filtroModulo,
                      dropdownColor: AppColors.sidebarBg,
                      style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 13),
                      items: _modulosDisponiveis
                          .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m == 'TODOS' ? 'Todos Módulos' : m)))
                          .toList(),
                      onChanged: (v) =>
                          v != null ? setState(() => _filtroModulo = v) : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ─── Lista de Permissões ──────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accent))
                  : _erro != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_erro!,
                                  style: GoogleFonts.inter(
                                      color: Colors.red.shade300)),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _carregar,
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: AppColors.sidebarBg.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(8),
                            itemCount: _permissoesFiltradas.length,
                            separatorBuilder: (_, __) => Divider(
                              color: Colors.white.withValues(alpha: 0.04),
                              height: 1,
                            ),
                            itemBuilder: (context, index) {
                              final p = _permissoesFiltradas[index] as Map;
                              final code = p['code']?.toString() ?? '';
                              final desc = p['descricao']?.toString() ?? code;
                              final modulo = p['modulo']?.toString() ?? '';

                              final isHerdada = _rolePermissions.contains(code);
                              final isCustom = _customPermissions.contains(code);

                              return InkWell(
                                onTap: isHerdada
                                    ? null // já concedida pelo perfil
                                    : () {
                                        setState(() {
                                          if (_customPermissions.contains(code)) {
                                            _customPermissions.remove(code);
                                          } else {
                                            _customPermissions.add(code);
                                          }
                                        });
                                      },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  child: Row(
                                    children: [
                                      // Switch / Checkbox
                                      if (isHerdada)
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.accent.withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.lock_rounded,
                                              color: AppColors.accentLight,
                                              size: 16),
                                        )
                                      else
                                        Checkbox(
                                          value: isCustom,
                                          activeColor: Colors.greenAccent.shade700,
                                          checkColor: Colors.black,
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true) {
                                                _customPermissions.add(code);
                                              } else {
                                                _customPermissions.remove(code);
                                              }
                                            });
                                          },
                                        ),
                                      const SizedBox(width: 12),

                                      // Descrição e código
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              desc,
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              code,
                                              style: GoogleFonts.jetBrainsMono(
                                                color: Colors.white38,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Tag de status
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isHerdada
                                              ? AppColors.accent.withValues(alpha: 0.12)
                                              : isCustom
                                                  ? Colors.green.withValues(alpha: 0.15)
                                                  : Colors.white.withValues(alpha: 0.04),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isHerdada
                                                ? AppColors.accent.withValues(alpha: 0.3)
                                                : isCustom
                                                    ? Colors.greenAccent
                                                        .withValues(alpha: 0.4)
                                                    : Colors.white10,
                                          ),
                                        ),
                                        child: Text(
                                          isHerdada
                                              ? 'Perfil ($role)'
                                              : isCustom
                                                  ? 'Personalizada'
                                                  : modulo,
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isHerdada
                                                ? AppColors.accentLight
                                                : isCustom
                                                    ? Colors.greenAccent
                                                    : Colors.white38,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
            const SizedBox(height: 16),

            // ─── Ações Rodapé ──────────────────────────────────────────────
            Row(
              children: [
                Text(
                  '${_customPermissions.length} permissões personalizadas concedidas',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.white60)),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _salvar,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Salvar Permissões'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

