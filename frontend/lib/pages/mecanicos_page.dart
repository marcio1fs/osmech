import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../mixins/auth_error_mixin.dart';
import '../services/mecanico_service.dart';
import '../theme/app_theme.dart';
import '../widgets/upper_text.dart';

class MecanicosPage extends StatefulWidget {
  const MecanicosPage({super.key});

  @override
  State<MecanicosPage> createState() => _MecanicosPageState();
}

class _MecanicosPageState extends State<MecanicosPage> with AuthErrorMixin {
  List<Map<String, dynamic>> _mecanicos = [];
  bool _loading = true;
  bool _ativosOnly = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMecanicos();
  }

  Future<void> _loadMecanicos() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = MecanicoService(token: safeToken);
      final data = await service.listar(ativosOnly: _ativosOnly);
      setState(() {
        _mecanicos = data;
        _loading = false;
      });
    } catch (e) {
      if (!handleAuthError(e)) {
        setState(() {
          _error = 'Erro ao carregar mecânicos';
          _loading = false;
        });
      }
    }
  }

  double? _parsePercentualComissao(String raw) {
    final normalized = raw.replaceAll(',', '.').trim();
    if (normalized.isEmpty) return 0;
    return double.tryParse(normalized);
  }

  Future<void> _abrirDialogo({Map<String, dynamic>? mecanico}) async {
    final nomeCtrl = TextEditingController(text: mecanico?['nome'] ?? '');
    final telCtrl = TextEditingController(text: mecanico?['telefone'] ?? '');
    final espCtrl =
        TextEditingController(text: mecanico?['especialidade'] ?? '');
    final comissaoCtrl = TextEditingController(
      text: (mecanico?['percentualComissao'] ?? 0).toString(),
    );
    final isEdit = mecanico != null;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: UpperText(isEdit ? 'Editar Mecânico' : 'Novo Mecânico',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: telCtrl,
                decoration: const InputDecoration(labelText: 'Telefone'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: espCtrl,
                decoration: const InputDecoration(labelText: 'Especialidade'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: comissaoCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Comissao (%)',
                  hintText: '0 a 100',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const UpperText('Cancelar')),
          FilledButton(
            onPressed: () {
              final nome = nomeCtrl.text.trim();
              if (nome.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: UpperText('Nome do mecânico é obrigatório'),
                        backgroundColor: AppColors.error),
                  );
                }
                return;
              }

              final percentualComissao =
                  _parsePercentualComissao(comissaoCtrl.text);
              if (percentualComissao == null ||
                  percentualComissao < 0 ||
                  percentualComissao > 100) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: UpperText('Informe uma comissao entre 0 e 100%'),
                        backgroundColor: AppColors.error),
                  );
                }
                return;
              }

              Navigator.pop(ctx, true);
            },
            child: const UpperText('Salvar'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final percentualComissao =
        _parsePercentualComissao(comissaoCtrl.text) ?? 0;

    try {
      final service = MecanicoService(token: safeToken);
      final payload = {
        'nome': nomeCtrl.text.trim(),
        'telefone': telCtrl.text.trim(),
        'especialidade': espCtrl.text.trim(),
        'percentualComissao': percentualComissao,
      };
      if (isEdit) {
        await service.atualizar(mecanico['id'] as int, payload);
      } else {
        await service.criar(payload);
      }
      await _loadMecanicos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  UpperText(isEdit ? 'Mecânico atualizado' : 'Mecânico cadastrado'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (!handleAuthError(e) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: UpperText('Erro: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _toggleAtivo(Map<String, dynamic> mecanico) async {
    final ativo = mecanico['ativo'] == true;
    try {
      final service = MecanicoService(token: safeToken);
      if (ativo) {
        await service.desativar(mecanico['id'] as int);
      } else {
        await service.reativar(mecanico['id'] as int);
      }
      await _loadMecanicos();
    } catch (e) {
      if (!handleAuthError(e) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: UpperText('Erro: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UpperText('Mecânicos',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    UpperText('${_mecanicos.length} registro(s)',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
                const Spacer(),
                Switch(
                  value: _ativosOnly,
                  onChanged: (v) {
                    setState(() => _ativosOnly = v);
                    _loadMecanicos();
                  },
                ),
                UpperText('Somente ativos', style: GoogleFonts.inter(fontSize: 12)),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _loadMecanicos,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const UpperText('Atualizar'),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: () => _abrirDialogo(),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const UpperText('Novo Mecânico'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent))
                : _error != null
                    ? Center(child: UpperText(_error!, style: GoogleFonts.inter()))
                    : ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: _mecanicos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final m = _mecanicos[i];
                          final ativo = m['ativo'] == true;
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.accent
                                    .withValues(alpha: 0.12),
                                child: const Icon(Icons.engineering_rounded,
                                    color: AppColors.accent),
                              ),
                              title: UpperText(m['nome'] ?? '-',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600)),
                              subtitle: UpperText(
                                '${m['especialidade'] ?? 'Sem especialidade'} • ${m['telefone'] ?? 'Sem telefone'} • Comissao: ${m['percentualComissao'] ?? 0}%',
                                style: GoogleFonts.inter(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: ativo
                                          ? AppColors.success
                                              .withValues(alpha: 0.12)
                                          : AppColors.error
                                              .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: UpperText(
                                      ativo ? 'Ativo' : 'Inativo',
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: ativo
                                              ? AppColors.success
                                              : AppColors.error),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _abrirDialogo(mecanico: m),
                                    icon: const Icon(Icons.edit_rounded),
                                  ),
                                  IconButton(
                                    onPressed: () => _toggleAtivo(m),
                                    icon: Icon(
                                      ativo
                                          ? Icons.person_off_rounded
                                          : Icons.restart_alt_rounded,
                                      color: ativo
                                          ? AppColors.error
                                          : AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}



