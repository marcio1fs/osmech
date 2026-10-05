import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/equipe_service.dart';
import '../theme/app_theme.dart';

/// Tela de gestão da Equipe (exclusiva do DONO).
/// Membros: alterar papel e ativar/desativar.
/// Convites: criar, reenviar e revogar. Mostra uso vs. limite do plano.
class EquipePage extends StatefulWidget {
  const EquipePage({super.key});

  @override
  State<EquipePage> createState() => _EquipePageState();
}

class _EquipePageState extends State<EquipePage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _equipe = {};

  static const _papelLabel = {
    'ADMIN': 'Admin',
    'DONO': 'Dono',
    'GERENTE': 'Gerente',
    'ATENDENTE': 'Atendente',
    'VENDEDOR': 'Vendedor',
    'MECANICO': 'Mecânico',
  };

  static const _papelCor = {
    'ADMIN': Color(0xFFE53935),
    'DONO': Color(0xFF7C4DFF),
    'GERENTE': Color(0xFF2196F3),
    'ATENDENTE': Color(0xFFFF9800),
    'VENDEDOR': Color(0xFF00897B),
    'MECANICO': Color(0xFF4CAF50),
  };

  static const _papeisConvidaveis = ['GERENTE', 'ATENDENTE', 'VENDEDOR', 'MECANICO'];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = context.read<AuthService>().token!;
      final dados = await EquipeService(token: token).getEquipe();
      if (mounted) {
        setState(() {
          _equipe = dados;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  EquipeService get _service =>
      EquipeService(token: context.read<AuthService>().token!);

  void _snack(String msg, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: erro ? AppColors.error : AppColors.success,
    ));
  }

  Future<void> _executar(Future<void> Function() acao, String okMsg) async {
    try {
      await acao();
      if (!mounted) return;
      _snack(okMsg);
      _carregar();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''), erro: true);
    }
  }

  // ---------- dialog de convite ----------

  Future<void> _abrirDialogoConvite() async {
    final emailCtrl = TextEditingController();
    String papel = 'ATENDENTE';
    final formKey = GlobalKey<FormState>();

    final enviado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Convidar membro',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail do convidado',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || !v.contains('@')) {
                      return 'Informe um e-mail válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: papel,
                  decoration: const InputDecoration(
                    labelText: 'Papel na equipe',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: _papeisConvidaveis
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(_papelLabel[p] ?? p),
                          ))
                      .toList(),
                  onChanged: (v) => setDlg(() => papel = v ?? papel),
                ),
                const SizedBox(height: 8),
                Text(
                  'O convidado receberá um e-mail com link para criar o acesso.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Enviar convite'),
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                try {
                  await _service.convidar(emailCtrl.text.trim(), papel);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  _snack(e.toString().replaceFirst('Exception: ', ''),
                      erro: true);
                }
              },
            ),
          ],
        ),
      ),
    );

    if (enviado == true && mounted) {
      _snack('Convite enviado por e-mail!');
      _carregar();
    }
  }

  // ---------- seções ----------

  Widget _cardPlano() {
    final limite = _equipe['limiteUsuarios'];
    final emUso = (_equipe['usuariosEmUso'] ?? 0) as num;
    final atingido = _equipe['limiteAtingido'] == true;
    final ilimitado = limite == null || limite == 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: atingido ? AppColors.error : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            atingido ? Icons.warning_amber_rounded : Icons.groups_rounded,
            color: atingido ? AppColors.error : AppColors.primary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ilimitado
                      ? '$emUso usuário(s) — plano sem limite'
                      : '$emUso de $limite usuário(s) do plano',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  atingido
                      ? 'Limite atingido — faça upgrade para convidar mais membros.'
                      : 'Conta usuários ativos + convites pendentes.',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tileMembro(Map<String, dynamic> m, String emailLogado) {
    final papel = (m['papel'] ?? '') as String;
    final eDono = papel == 'DONO';
    final eEu = m['email'] == emailLogado;
    final ativo = m['ativo'] == true;
    final cor = _papelCor[papel] ?? AppColors.textSecondary;
    // Papéis fora da lista de convidáveis (ex.: ADMIN) não podem ser
    // gerenciados pela tela de equipe — evita rebaixar contas especiais.
    final papelGerenciavel = _papeisConvidaveis.contains(papel);
    final bloqueado = eDono || eEu || !papelGerenciavel;

    // O dropdown PRECISA conter o papel atual entre os itens, senão o
    // Flutter lança assertion ("exactly one item with value") quando um
    // membro tem papel fora da lista (ex.: ADMIN).
    final papeisDropdown = <String>{
      if (eDono) 'DONO' else ..._papeisConvidaveis,
      if (papel.isNotEmpty) papel,
    }.toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cor.withValues(alpha: 0.15),
          child: Icon(Icons.person_rounded, color: cor),
        ),
        title: Text(
          '${m['nome']}${eEu ? ' (você)' : ''}',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(m['email'] ?? '',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecondary)),
        trailing: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<String>(
              value: papel.isEmpty ? null : papel,
              underline: const SizedBox.shrink(),
              onChanged: bloqueado
                  ? null
                  : (novo) {
                      if (novo == null || novo == papel) return;
                      _executar(
                        () => _service.alterarPapel(m['id'], novo),
                        'Papel alterado para ${_papelLabel[novo]}',
                      );
                    },
              items: papeisDropdown
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(_papelLabel[p] ?? p),
                      ))
                  .toList(),
            ),
            Switch(
              value: ativo,
              onChanged: bloqueado
                  ? null
                  : (v) => _executar(
                        () => _service.alterarStatus(m['id'], v),
                        v ? 'Membro reativado' : 'Membro desativado',
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tileConvite(Map<String, dynamic> c) {
    final id = c['id'] as int;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.warning.withValues(alpha: 0.15),
          child:
              const Icon(Icons.mail_outline_rounded, color: AppColors.warning),
        ),
        title: Text(c['email'] ?? '',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${_papelLabel[c['papel']] ?? c['papel']} • convite pendente',
          style:
              GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Reenviar convite (novo link)',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _executar(
                () => _service.reenviarConvite(id).then((_) {}),
                'Convite reenviado!',
              ),
            ),
            IconButton(
              tooltip: 'Revogar convite',
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error),
              onPressed: () => _executar(
                () => _service.revogarConvite(id),
                'Convite revogado',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _secao(String titulo, List<Widget> filhos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(titulo,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5)),
        const SizedBox(height: 12),
        ...filhos,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final emailLogado = context.read<AuthService>().email;
    final membros = List<Map<String, dynamic>>.from(_equipe['membros'] ?? []);
    final convites = List<Map<String, dynamic>>.from(_equipe['convites'] ?? []);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: GoogleFonts.inter(color: AppColors.error)),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: _carregar,
                          child: const Text('Tentar novamente')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text('Equipe da oficina',
                          style: GoogleFonts.inter(
                              fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 20),
                      _cardPlano(),
                      _secao(
                        'MEMBROS (${membros.length})',
                        membros.isEmpty
                            ? [const Text('Nenhum membro ainda.')]
                            : membros
                                .map((m) => _tileMembro(m, emailLogado ?? ''))
                                .toList(),
                      ),
                      _secao(
                        'CONVITES PENDENTES (${convites.length})',
                        convites.isEmpty
                            ? [const Text('Nenhum convite pendente.')]
                            : convites.map(_tileConvite).toList(),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirDialogoConvite,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Convidar'),
      ),
    );
  }
}
