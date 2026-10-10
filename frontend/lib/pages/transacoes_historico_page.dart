import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/finance_service.dart';
import '../services/equipe_service.dart';
import '../theme/app_theme.dart';
import '../mixins/auth_error_mixin.dart';
import '../utils/formatters.dart';
import '../widgets/upper_text.dart';

/// Tela unificada de Histórico:
/// 1. Transações Financeiras (com filtros avançados de busca, tipo, método, status e cards de resumo)
/// 2. Auditoria & Rastreamento do Sistema (timeline de eventos: OS, financeiro, segurança, equipe, estoque)
class TransacoesHistoricoPage extends StatefulWidget {
  const TransacoesHistoricoPage({super.key});

  @override
  State<TransacoesHistoricoPage> createState() =>
      _TransacoesHistoricoPageState();
}

class _TransacoesHistoricoPageState extends State<TransacoesHistoricoPage>
    with AuthErrorMixin, SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Estado de Transações Financeiras ---
  List<Map<String, dynamic>> _transacoes = [];
  bool _loadingFinanceiro = true;
  String? _errorFinanceiro;
  String? _filtroTipo;
  String? _filtroMetodo;
  String? _filtroStatus; // 'TODOS', 'NORMAIS', 'ESTORNOS'
  DateTime? _dataInicio;
  DateTime? _dataFim;
  final TextEditingController _searchFinanceiroController = TextEditingController();
  String _searchFinanceiroTerm = '';

  // --- Estado de Auditoria / Rastreamento ---
  List<Map<String, dynamic>> _logsAuditoria = [];
  bool _loadingAuditoria = false;
  String? _errorAuditoria;
  final TextEditingController _searchAuditoriaController = TextEditingController();
  String _searchAuditoriaTerm = '';
  String? _filtroAcaoAuditoria;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _logsAuditoria.isEmpty && !_loadingAuditoria) {
        _loadAuditoria();
      }
    });
    _loadTransacoes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchFinanceiroController.dispose();
    _searchAuditoriaController.dispose();
    super.dispose();
  }

  String _formatDateParam(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ==========================================
  // CARREGAR TRANSAÇÕES FINANCEIRAS
  // ==========================================
  Future<void> _loadTransacoes() async {
    setState(() {
      _loadingFinanceiro = true;
      _errorFinanceiro = null;
    });
    try {
      final service = FinanceService(token: safeToken);
      final data = await service.listarTransacoes(
        tipo: _filtroTipo,
        dataInicio: _dataInicio != null ? _formatDateParam(_dataInicio!) : null,
        dataFim: _dataFim != null ? _formatDateParam(_dataFim!) : null,
      );
      setState(() {
        _transacoes = data;
        _loadingFinanceiro = false;
      });
    } catch (e) {
      if (!handleAuthError(e)) {
        setState(() {
          _errorFinanceiro = 'Erro ao carregar transações financeiras';
          _loadingFinanceiro = false;
        });
      }
    }
  }

  // ==========================================
  // CARREGAR AUDITORIA / RASTREAMENTO
  // ==========================================
  Future<void> _loadAuditoria() async {
    setState(() {
      _loadingAuditoria = true;
      _errorAuditoria = null;
    });
    try {
      final service = EquipeService(token: safeToken);
      final data = await service.getAuditoria();
      setState(() {
        _logsAuditoria = data;
        _loadingAuditoria = false;
      });
    } catch (e) {
      if (!handleAuthError(e)) {
        setState(() {
          _errorAuditoria = 'Erro ao carregar histórico de auditoria';
          _loadingAuditoria = false;
        });
      }
    }
  }

  Future<void> _estornar(int transacaoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const UpperText('Estornar Transação'),
        content: const UpperText(
            'Deseja estornar esta transação? Uma movimentação inversa e o registro de auditoria serão gerados automaticamente.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const UpperText('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            child: const UpperText('Estornar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final service = FinanceService(token: safeToken);
      await service.estornarTransacao(transacaoId);
      _loadTransacoes();
      if (_logsAuditoria.isNotEmpty) {
        _loadAuditoria();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: UpperText('Transação estornada com sucesso!',
                  style: GoogleFonts.inter()),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (!handleAuthError(e)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: UpperText(
                    'Erro: ${e.toString().replaceAll('Exception: ', '')}',
                    style: GoogleFonts.inter()),
                backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _selecionarPeriodo() async {
    final picked = await showDateRangePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dataInicio != null && _dataFim != null
          ? DateTimeRange(start: _dataInicio!, end: _dataFim!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dataInicio = picked.start;
        _dataFim = picked.end;
      });
      _loadTransacoes();
    }
  }

  void _limparFiltrosFinanceiro() {
    setState(() {
      _filtroTipo = null;
      _filtroMetodo = null;
      _filtroStatus = null;
      _dataInicio = null;
      _dataFim = null;
      _searchFinanceiroController.clear();
      _searchFinanceiroTerm = '';
    });
    _loadTransacoes();
  }

  String _metodoLabel(String? metodo) {
    switch (metodo) {
      case 'PIX':
        return 'PIX';
      case 'DINHEIRO':
        return 'Dinheiro';
      case 'CARTAO':
      case 'CARTAO_CREDITO':
        return 'Cartão de Crédito';
      case 'CARTAO_DEBITO':
        return 'Cartão de Débito';
      case 'BOLETO':
        return 'Boleto';
      case 'TRANSFERENCIA':
        return 'Transferência';
      case 'PRAZO_30_DIAS':
        return 'A Prazo (30 dias)';
      default:
        return metodo ?? '-';
    }
  }

  // Filtragem local complementar para Financeiro (busca textual, método e estorno)
  List<Map<String, dynamic>> get _transacoesFiltradas {
    return _transacoes.where((tx) {
      // Filtro por método de pagamento
      if (_filtroMetodo != null && _filtroMetodo!.isNotEmpty) {
        final m = (tx['metodoPagamento'] ?? '').toString().toUpperCase();
        if (_filtroMetodo == 'CARTAO') {
          if (!m.contains('CARTAO')) return false;
        } else if (m != _filtroMetodo) {
          return false;
        }
      }

      // Filtro por status de estorno
      if (_filtroStatus == 'ESTORNOS') {
        if (tx['estorno'] != true) return false;
      } else if (_filtroStatus == 'NORMAIS') {
        if (tx['estorno'] == true) return false;
      }

      // Busca textual por descrição, OS ou observação
      if (_searchFinanceiroTerm.isNotEmpty) {
        final term = _searchFinanceiroTerm.toLowerCase();
        final desc = (tx['descricao'] ?? '').toString().toLowerCase();
        final obs = (tx['observacoes'] ?? '').toString().toLowerCase();
        final refId = (tx['referenciaId'] ?? '').toString().toLowerCase();
        final osNumber = formatOsNumber(tx['referenciaId']).toLowerCase();
        final cat = (tx['categoriaNome'] ?? '').toString().toLowerCase();

        final match = desc.contains(term) ||
            obs.contains(term) ||
            refId.contains(term) ||
            osNumber.contains(term) ||
            cat.contains(term);
        if (!match) return false;
      }

      return true;
    }).toList();
  }

  // Filtragem de Auditoria
  List<Map<String, dynamic>> get _auditoriaFiltrada {
    return _logsAuditoria.where((log) {
      // Filtro por categoria de ação
      if (_filtroAcaoAuditoria != null && _filtroAcaoAuditoria!.isNotEmpty) {
        final acao = (log['acao'] ?? '').toString();
        if (_filtroAcaoAuditoria == 'OS' && !acao.startsWith('OS_')) return false;
        if (_filtroAcaoAuditoria == 'FINANCEIRO' &&
            !acao.contains('TRANSACAO') &&
            !acao.contains('PLANO')) return false;
        if (_filtroAcaoAuditoria == 'SEGURANCA' &&
            !acao.contains('LOGIN') &&
            !acao.contains('SENHA') &&
            !acao.contains('SESSAO') &&
            !acao.contains('2FA')) return false;
        if (_filtroAcaoAuditoria == 'EQUIPE' &&
            !acao.contains('MEMBRO') &&
            !acao.contains('CONVITE')) return false;
      }

      // Busca textual
      if (_searchAuditoriaTerm.isNotEmpty) {
        final term = _searchAuditoriaTerm.toLowerCase();
        final acao = (log['acao'] ?? '').toString().toLowerCase();
        final email = (log['usuarioEmail'] ?? '').toString().toLowerCase();
        final detalhes = (log['detalhes'] ?? '').toString().toLowerCase();

        return acao.contains(term) ||
            email.contains(term) ||
            detalhes.contains(term);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Header unificado com Abas
          Container(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 18),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UpperText(
                            'Módulo de Histórico & Rastreabilidade',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          UpperText(
                            'Controle de movimentações financeiras e trilha completa de eventos do sistema',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        if (_tabController.index == 0) {
                          _loadTransacoes();
                        } else {
                          _loadAuditoria();
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
                      tooltip: 'Atualizar dados',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // TabBar moderna
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: AppColors.accent,
                  indicatorWeight: 3,
                  labelColor: AppColors.accent,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.receipt_long_rounded, size: 18),
                      text: 'MOVIMENTAÇÕES FINANCEIRAS',
                    ),
                    Tab(
                      icon: Icon(Icons.history_rounded, size: 18),
                      text: 'RASTREIO & AUDITORIA DO SISTEMA',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Conteúdo das Abas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAbaFinanceira(),
                _buildAbaAuditoria(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // ABA 1: MOVIMENTAÇÕES FINANCEIRAS (COM FILTROS & RESUMO)
  // ===============================================================
  Widget _buildAbaFinanceira() {
    final filtradas = _transacoesFiltradas;

    // Calcular totais do resultado filtrado
    double totalEntradas = 0;
    double totalSaidas = 0;
    int totalEstornos = 0;

    for (final tx in filtradas) {
      final v = (tx['valor'] is num)
          ? (tx['valor'] as num).toDouble()
          : double.tryParse(tx['valor'].toString()) ?? 0.0;
      final isEstorno = tx['estorno'] == true;

      if (isEstorno) {
        totalEstornos++;
      }

      if (tx['tipo'] == 'ENTRADA') {
        totalEntradas += v;
      } else if (tx['tipo'] == 'SAIDA') {
        totalSaidas += v;
      }
    }

    final saldoPeriodo = totalEntradas - totalSaidas;

    return Column(
      children: [
        // Barra de Filtros Avançados
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Campo de Pesquisa Textual
                  SizedBox(
                    width: 250,
                    height: 40,
                    child: TextField(
                      controller: _searchFinanceiroController,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Buscar por OS, cliente, descrição...',
                        hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() => _searchFinanceiroTerm = val.trim());
                      },
                    ),
                  ),

                  // Filtro por Tipo (Entrada / Saída)
                  SizedBox(
                    width: 135,
                    height: 40,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _filtroTipo,
                          hint: UpperText('Tipo: Todos',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                          items: const [
                            DropdownMenuItem(value: null, child: UpperText('Todos os Tipos')),
                            DropdownMenuItem(value: 'ENTRADA', child: UpperText('Entradas')),
                            DropdownMenuItem(value: 'SAIDA', child: UpperText('Saídas')),
                          ],
                          onChanged: (v) {
                            setState(() => _filtroTipo = v);
                            _loadTransacoes();
                          },
                        ),
                      ),
                    ),
                  ),

                  // Filtro por Método de Pagamento
                  SizedBox(
                    width: 145,
                    height: 40,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _filtroMetodo,
                          hint: UpperText('Método: Todos',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                          items: const [
                            DropdownMenuItem(value: null, child: UpperText('Todos Métodos')),
                            DropdownMenuItem(value: 'PIX', child: UpperText('PIX')),
                            DropdownMenuItem(value: 'CARTAO', child: UpperText('Cartão')),
                            DropdownMenuItem(value: 'DINHEIRO', child: UpperText('Dinheiro')),
                            DropdownMenuItem(value: 'BOLETO', child: UpperText('Boleto')),
                            DropdownMenuItem(value: 'TRANSFERENCIA', child: UpperText('Transferência')),
                          ],
                          onChanged: (v) => setState(() => _filtroMetodo = v),
                        ),
                      ),
                    ),
                  ),

                  // Filtro de Estornos
                  SizedBox(
                    width: 140,
                    height: 40,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _filtroStatus,
                          hint: UpperText('Status: Todos',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                          items: const [
                            DropdownMenuItem(value: null, child: UpperText('Status: Todos')),
                            DropdownMenuItem(value: 'NORMAIS', child: UpperText('Sem Estorno')),
                            DropdownMenuItem(value: 'ESTORNOS', child: UpperText('Apenas Estornos')),
                          ],
                          onChanged: (v) => setState(() => _filtroStatus = v),
                        ),
                      ),
                    ),
                  ),

                  // Botão de Período
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(110, 40),
                      side: BorderSide(
                        color: (_dataInicio != null) ? AppColors.accent : AppColors.border,
                      ),
                    ),
                    onPressed: _selecionarPeriodo,
                    icon: Icon(Icons.date_range_rounded,
                        size: 16,
                        color: (_dataInicio != null) ? AppColors.accent : AppColors.textMuted),
                    label: UpperText(
                      _dataInicio != null
                          ? '${_dataInicio!.day}/${_dataInicio!.month} a ${_dataFim!.day}/${_dataFim!.month}'
                          : 'Período',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: (_dataInicio != null) ? AppColors.accent : AppColors.textPrimary,
                      ),
                    ),
                  ),

                  // Limpar Filtros
                  if (_filtroTipo != null ||
                      _filtroMetodo != null ||
                      _filtroStatus != null ||
                      _dataInicio != null ||
                      _searchFinanceiroTerm.isNotEmpty)
                    TextButton.icon(
                      onPressed: _limparFiltrosFinanceiro,
                      icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.error),
                      label: UpperText('Limpar',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.error)),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Cards de Resumo Rápido dos Resultados Filtrados
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 650;
                  final cards = [
                    _buildResumoCard(
                      label: 'Entradas Filtradas',
                      valor: '+ ${formatCurrency(totalEntradas)}',
                      cor: AppColors.success,
                      icon: Icons.arrow_downward_rounded,
                    ),
                    _buildResumoCard(
                      label: 'Saídas Filtradas',
                      valor: '- ${formatCurrency(totalSaidas)}',
                      cor: AppColors.error,
                      icon: Icons.arrow_upward_rounded,
                    ),
                    _buildResumoCard(
                      label: 'Saldo no Filtro',
                      valor: formatCurrency(saldoPeriodo),
                      cor: saldoPeriodo >= 0 ? AppColors.primary : AppColors.warning,
                      icon: Icons.account_balance_wallet_rounded,
                    ),
                    _buildResumoCard(
                      label: 'Total de Registros',
                      valor: '${filtradas.length} mov. ${totalEstornos > 0 ? "($totalEstornos estornos)" : ""}',
                      cor: AppColors.textSecondary,
                      icon: Icons.receipt_long_rounded,
                    ),
                  ];

                  if (isCompact) {
                    final itemWidth = (constraints.maxWidth - 10) / 2;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: cards
                          .map((c) => SizedBox(width: itemWidth > 140 ? itemWidth : constraints.maxWidth, child: c))
                          .toList(),
                    );
                  }

                  return Row(
                    children: [
                      for (int i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(child: cards[i]),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        // Lista de Transações
        Expanded(
          child: _loadingFinanceiro
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : _errorFinanceiro != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 48, color: AppColors.error),
                          const SizedBox(height: 12),
                          UpperText(_errorFinanceiro!,
                              style: GoogleFonts.inter(color: AppColors.textSecondary)),
                          const SizedBox(height: 12),
                          FilledButton(
                              onPressed: _loadTransacoes,
                              child: const UpperText('Tentar novamente')),
                        ],
                      ),
                    )
                  : filtradas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long_rounded,
                                  size: 64,
                                  color: AppColors.textMuted.withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              UpperText('Nenhuma transação encontrada para estes filtros',
                                  style: GoogleFonts.inter(
                                      fontSize: 16, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              UpperText('Ajuste os filtros ou crie um novo lançamento',
                                  style: GoogleFonts.inter(
                                      fontSize: 13, color: AppColors.textMuted)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: filtradas.length,
                          itemBuilder: (context, index) {
                            final tx = filtradas[index];
                            return _TransacaoCard(
                              tx: tx,
                              formatCurrency: formatCurrency,
                              formatDate: formatDateTimeBR,
                              metodoLabel: _metodoLabel,
                              onEstornar: tx['estorno'] == true
                                  ? null
                                  : () => _estornar(tx['id'] as int),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  // ===============================================================
  // ABA 2: RASTREIO & TRILHA DE AUDITORIA DO SISTEMA
  // ===============================================================
  Widget _buildAbaAuditoria() {
    final filtrados = _auditoriaFiltrada;

    return Column(
      children: [
        // Barra de Filtros de Auditoria
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              // Pesquisa Textual na Auditoria
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchAuditoriaController,
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Pesquisar evento, usuário ou detalhes (ex: OS os01, login, estorno)...',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() => _searchAuditoriaTerm = val.trim());
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Categoria de Eventos
              SizedBox(
                width: 180,
                height: 40,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _filtroAcaoAuditoria,
                      hint: UpperText('Área: Todas',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                      items: const [
                        DropdownMenuItem(value: null, child: UpperText('Todas as Áreas')),
                        DropdownMenuItem(value: 'OS', child: UpperText('Ordens de Serviço')),
                        DropdownMenuItem(value: 'FINANCEIRO', child: UpperText('Financeiro & Pagamentos')),
                        DropdownMenuItem(value: 'EQUIPE', child: UpperText('Equipe & Convites')),
                        DropdownMenuItem(value: 'SEGURANCA', child: UpperText('Segurança & Logins')),
                      ],
                      onChanged: (v) => setState(() => _filtroAcaoAuditoria = v),
                    ),
                  ),
                ),
              ),

              if (_searchAuditoriaTerm.isNotEmpty || _filtroAcaoAuditoria != null) ...[
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _searchAuditoriaController.clear();
                      _searchAuditoriaTerm = '';
                      _filtroAcaoAuditoria = null;
                    });
                  },
                  icon: const Icon(Icons.clear_rounded, size: 20, color: AppColors.error),
                  tooltip: 'Limpar filtros de auditoria',
                ),
              ],
            ],
          ),
        ),

        // Lista / Timeline de Auditoria
        Expanded(
          child: _loadingAuditoria
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : _errorAuditoria != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 48, color: AppColors.error),
                          const SizedBox(height: 12),
                          UpperText(_errorAuditoria!,
                              style: GoogleFonts.inter(color: AppColors.textSecondary)),
                          const SizedBox(height: 12),
                          FilledButton(
                              onPressed: _loadAuditoria,
                              child: const UpperText('Tentar novamente')),
                        ],
                      ),
                    )
                  : filtrados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined,
                                  size: 64,
                                  color: AppColors.textMuted.withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              UpperText('Nenhum evento registrado com esses critérios',
                                  style: GoogleFonts.inter(
                                      fontSize: 16, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              UpperText('As ações sensíveis realizadas na oficina aparecerão aqui',
                                  style: GoogleFonts.inter(
                                      fontSize: 13, color: AppColors.textMuted)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(24),
                          itemCount: filtrados.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final log = filtrados[index];
                            return _AuditoriaCard(log: log);
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildResumoCard({
    required String label,
    required String valor,
    required Color cor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: cor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                UpperText(label,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                UpperText(valor,
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w700, color: cor),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================================================
// CARD DE AUDITORIA & RASTREAMENTO
// ===============================================================
class _AuditoriaCard extends StatelessWidget {
  final Map<String, dynamic> log;

  const _AuditoriaCard({required this.log});

  Color _corPorAcao(String acao) {
    if (acao.contains('EXCLUIDA') || acao.contains('DESATIVADO') || acao.contains('RECUSADO')) {
      return AppColors.error;
    }
    if (acao.contains('ESTORNO') || acao.contains('STATUS') || acao.contains('SENHA')) {
      return AppColors.warning;
    }
    if (acao.contains('CRIADA') || acao.contains('ENCERRADA') || acao.contains('ATIVADO') || acao.contains('OK')) {
      return AppColors.success;
    }
    return AppColors.primary;
  }

  IconData _iconPorAcao(String acao) {
    if (acao.startsWith('OS_')) return Icons.assignment_rounded;
    if (acao.contains('TRANSACAO')) return Icons.payments_rounded;
    if (acao.contains('LOGIN') || acao.contains('SESSAO')) return Icons.login_rounded;
    if (acao.contains('SENHA')) return Icons.key_rounded;
    if (acao.contains('MEMBRO') || acao.contains('CONVITE')) return Icons.people_rounded;
    if (acao.startsWith('ESTOQUE_')) return Icons.inventory_2_rounded;
    return Icons.notifications_active_rounded;
  }

  String _formatarAcaoLabel(String acao) {
    switch (acao) {
      case 'OS_CRIADA':
        return 'OS Aberta';
      case 'OS_STATUS_ALTERADO':
        return 'Status de OS Alterado';
      case 'OS_ENCERRADA':
        return 'OS Concluída & Paga';
      case 'OS_EXCLUIDA':
        return 'OS Excluída';
      case 'TRANSACAO_CRIADA':
        return 'Novo Lançamento Financeiro';
      case 'TRANSACAO_ESTORNADA':
        return 'Transação Estornada';
      case 'LOGIN':
        return 'Login Efetuado';
      case 'LOGIN_RECUSADO':
        return 'Tentativa de Login Recusada';
      case 'LOGOUT':
        return 'Logout';
      case 'SENHA_ALTERADA':
        return 'Senha Alterada';
      case 'CONVITE_CRIADO':
        return 'Convite de Membro Enviado';
      case 'MEMBRO_PAPEL_ALTERADO':
        return 'Permissão de Membro Alterada';
      case 'MEMBRO_DESATIVADO':
        return 'Membro Desativado';
      case 'MEMBRO_ATIVADO':
        return 'Membro Reativado';
      default:
        return acao.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final acao = (log['acao'] ?? '').toString();
    final usuario = (log['usuarioEmail'] ?? 'Sistema').toString();
    final detalhes = (log['detalhes'] ?? '').toString();
    final criadoEm = (log['criadoEm'] ?? '').toString();
    final cor = _corPorAcao(acao);
    final icon = _iconPorAcao(acao);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: cor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: cor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: UpperText(
                        _formatarAcaoLabel(acao),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cor,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        UpperText(
                          formatDateTimeBR(criadoEm),
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                UpperText(
                  detalhes.isNotEmpty ? detalhes : 'Sem detalhes adicionais',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: UpperText(
                        'Operado por: $usuario',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================================================
// CARD DE TRANSAÇÃO FINANCEIRA
// ===============================================================
class _TransacaoCard extends StatelessWidget {
  final Map<String, dynamic> tx;
  final String Function(dynamic) formatCurrency;
  final String Function(String?) formatDate;
  final String Function(String?) metodoLabel;
  final VoidCallback? onEstornar;

  const _TransacaoCard({
    required this.tx,
    required this.formatCurrency,
    required this.formatDate,
    required this.metodoLabel,
    this.onEstornar,
  });

  @override
  Widget build(BuildContext context) {
    final isEntrada = tx['tipo'] == 'ENTRADA';
    final isEstorno = tx['estorno'] == true;
    final color = isEstorno
        ? AppColors.warning
        : isEntrada
            ? AppColors.success
            : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEstorno
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isEstorno
                  ? Icons.undo_rounded
                  : isEntrada
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    UpperText(
                      tx['descricao'] ?? '',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    UpperText(
                      '${isEntrada ? '+' : '-'} ${formatCurrency(tx['valor'])}',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_today_rounded,
                      text: formatDate(tx['dataMovimentacao']?.toString()),
                    ),
                    _InfoChip(
                      icon: Icons.category_rounded,
                      text: tx['categoriaNome'] ?? 'Sem categoria',
                    ),
                    _InfoChip(
                      icon: Icons.payment_rounded,
                      text: metodoLabel(tx['metodoPagamento']),
                    ),
                    if (tx['referenciaTipo'] == 'OS')
                      _InfoChip(
                        icon: Icons.assignment_rounded,
                        text: formatOsNumber(tx['referenciaId']),
                        color: AppColors.accent,
                      ),
                    if (isEstorno)
                      _InfoChip(
                        icon: Icons.info_rounded,
                        text: 'Estorno #${tx['transacaoEstornadaId']}',
                        color: AppColors.warning,
                      ),
                  ],
                ),
                if (tx['observacoes'] != null &&
                    tx['observacoes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  UpperText(tx['observacoes'],
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          if (onEstornar != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IconButton(
                icon: const Icon(Icons.undo_rounded,
                    size: 20, color: AppColors.warning),
                onPressed: onEstornar,
                tooltip: 'Estornar',
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _InfoChip({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color ?? AppColors.textMuted),
        const SizedBox(width: 4),
        Flexible(
          child: UpperText(
            text,
            style: GoogleFonts.inter(
                fontSize: 12, color: color ?? AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
