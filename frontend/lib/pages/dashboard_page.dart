import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/os_service.dart';
import '../services/finance_service.dart';
import '../services/stock_service.dart';
import '../theme/app_theme.dart';
import '../mixins/auth_error_mixin.dart';
import '../utils/formatters.dart';
import '../widgets/upper_text.dart';

class DashboardPage extends StatefulWidget {
  final void Function(int)? onNavigate;
  const DashboardPage({super.key, this.onNavigate});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with AuthErrorMixin {
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _finance;
  List<Map<String, dynamic>> _osRecentes = [];
  List<Map<String, dynamic>> _alertasEstoque = [];
  List<Map<String, dynamic>> _tendencia = [];
  bool _loading = true;
  String? _error;

  // Índices corretos do AppShell
  static const int _idxNovaOs      = 2;
  static const int _idxListaOs     = 1;
  static const int _idxFinanceiro  = 6;
  static const int _idxFluxoCaixa  = 9;
  static const int _idxEstoque     = 11;
  static const int _idxRelatorios  = 18;
  static const int _idxMecanicos   = 5;
  static const int _idxAlertas     = 14;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final os      = OsService(token: safeToken);
      final finance = FinanceService(token: safeToken);
      final stock   = StockService(token: safeToken);

      final results = await Future.wait([
        os.getDashboardStats().catchError((_) => <String, dynamic>{}),
        finance.getResumoFinanceiro().catchError((_) => <String, dynamic>{}),
        os.listar().catchError((_) => <Map<String, dynamic>>[]),
        stock.getAlertas().catchError((_) => <Map<String, dynamic>>[]),
        finance.getTendencia7Dias().catchError((_) => <Map<String, dynamic>>[]),
      ]);

      final ordens = (results[2] as List<Map<String, dynamic>>);
      // Últimas 5 OS abertas ou em andamento
      final recentes = ordens
          .where((o) => o['status'] == 'ABERTA' || o['status'] == 'EM_ANDAMENTO'
              || o['status'] == 'AGUARDANDO_PECA' || o['status'] == 'AGUARDANDO_APROVACAO')
          .take(5)
          .toList();

      setState(() {
        _stats          = results[0] as Map<String, dynamic>;
        _finance        = results[1] as Map<String, dynamic>;
        _osRecentes     = recentes;
        _alertasEstoque = (results[3] as List<Map<String, dynamic>>).take(5).toList();
        _tendencia      = results[4] as List<Map<String, dynamic>>;
        _loading        = false;
      });
    } catch (e) {
      if (!handleAuthError(e)) setState(() { _error = 'Erro ao carregar dados'; _loading = false; });
    }
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  int _toInt(dynamic v) => _toDouble(v).toInt();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final now  = DateTime.now();
    final hora = now.hour < 12 ? 'Bom dia' : now.hour < 18 ? 'Boa tarde' : 'Boa noite';

    return Container(
      color: AppColors.background,
      child: Column(children: [
        _buildHeader(auth, hora, now),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : _error != null
                  ? _buildError()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _buildFinanceRow(),
                        const SizedBox(height: 24),
                        _buildOsRow(),
                        const SizedBox(height: 24),
                        _buildTendenciaRow(),
                        const SizedBox(height: 24),
                        _buildBottomRow(auth),
                        const SizedBox(height: 24),
                        _buildQuickActions(),
                      ]),
                    ),
        ),
      ]),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(AuthService auth, String hora, DateTime now) {
    final dia = '${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          UpperText('$hora, ${(auth.nome?.isNotEmpty == true ? auth.nome!.split(' ').first : null) ?? 'Usuário'}',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          UpperText(dia, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        ])),
        // Badge do plano
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
          ),
          child: UpperText('Plano ${auth.plano ?? "FREE"}',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent)),
        ),
        const SizedBox(width: 12),
        IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Atualizar', style: IconButton.styleFrom(foregroundColor: AppColors.textSecondary)),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () => widget.onNavigate?.call(_idxNovaOs),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const UpperText('Nova OS'),
        ),
      ]),
    );
  }

  // ── Linha financeira ─────────────────────────────────────────────────────────
  Widget _buildFinanceRow() {
    final entradasMes = _toDouble(_finance?['entradasMes']);
    final saidasMes   = _toDouble(_finance?['saidasMes']);
    final lucroMes    = _toDouble(_finance?['lucroMes']);
    final saldoAtual  = _toDouble(_finance?['saldoAtual']);
    final margem      = entradasMes > 0 ? (lucroMes / entradasMes * 100) : 0.0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Financeiro — Mês Atual'),
      const SizedBox(height: 12),
      Row(children: [
        _FinCard(label: 'Receitas', value: formatCurrency(entradasMes),
            icon: Icons.arrow_circle_down_rounded, color: AppColors.success,
            onTap: () => widget.onNavigate?.call(_idxFinanceiro)),
        const SizedBox(width: 12),
        _FinCard(label: 'Despesas', value: formatCurrency(saidasMes),
            icon: Icons.arrow_circle_up_rounded, color: AppColors.error,
            onTap: () => widget.onNavigate?.call(_idxFinanceiro)),
        const SizedBox(width: 12),
        _FinCard(label: 'Lucro', value: formatCurrency(lucroMes),
            icon: Icons.account_balance_wallet_rounded,
            color: lucroMes >= 0 ? AppColors.success : AppColors.error,
            onTap: () => widget.onNavigate?.call(_idxFluxoCaixa)),
        const SizedBox(width: 12),
        _FinCard(label: 'Saldo Acumulado', value: formatCurrency(saldoAtual),
            icon: Icons.savings_rounded,
            color: saldoAtual >= 0 ? AppColors.textPrimary : AppColors.error,
            onTap: () => widget.onNavigate?.call(_idxFluxoCaixa)),
        const SizedBox(width: 12),
        _FinCard(label: 'Margem', value: '${margem.toStringAsFixed(1)}%',
            icon: Icons.pie_chart_rounded,
            color: margem >= 20 ? AppColors.success : AppColors.warning,
            onTap: () => widget.onNavigate?.call(_idxRelatorios)),
      ]),
    ]);
  }

  // ── Linha de OS ──────────────────────────────────────────────────────────────
  Widget _buildOsRow() {
    final total            = _toInt(_stats?['total']);
    final abertas          = _toInt(_stats?['abertas']);
    final emAndamento      = _toInt(_stats?['emAndamento']);
    final concluidas       = _toInt(_stats?['concluidas']);
    final esteMes          = _toInt(_stats?['esteMes']);
    final aguardandoPeca   = _toInt(_stats?['aguardandoPeca']);
    final aguardandoAprov  = _toInt(_stats?['aguardandoAprovacao']);
    final canceladas       = _toInt(_stats?['canceladas']);
    final concluidasHoje   = _toInt(_stats?['concluidasHoje']);
    final taxa             = total > 0 ? (concluidas / total * 100) : 0.0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Ordens de Serviço'),
      const SizedBox(height: 12),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Contadores
        Expanded(flex: 3, child: Wrap(spacing: 12, runSpacing: 12, children: [
          _OsCountCard(label: 'Total', value: total, color: AppColors.textSecondary,
              icon: Icons.assignment_rounded, onTap: () => widget.onNavigate?.call(_idxListaOs)),
          _OsCountCard(label: 'Abertas', value: abertas, color: const Color(0xFFF59E0B),
              icon: Icons.radio_button_unchecked_rounded, onTap: () => widget.onNavigate?.call(_idxListaOs)),
          _OsCountCard(label: 'Em Andamento', value: emAndamento, color: const Color(0xFF3B82F6),
              icon: Icons.autorenew_rounded, onTap: () => widget.onNavigate?.call(_idxListaOs)),
          _OsCountCard(label: 'Ag. Peça', value: aguardandoPeca, color: const Color(0xFF8B5CF6),
              icon: Icons.inventory_2_outlined, onTap: () => widget.onNavigate?.call(_idxListaOs)),
          _OsCountCard(label: 'Ag. Aprovação', value: aguardandoAprov, color: const Color(0xFFF97316),
              icon: Icons.pending_outlined, onTap: () => widget.onNavigate?.call(_idxListaOs)),
          _OsCountCard(label: 'Concluídas', value: concluidas, color: AppColors.success,
              icon: Icons.check_circle_outline_rounded, onTap: () => widget.onNavigate?.call(_idxListaOs)),
          _OsCountCard(label: 'Hoje', value: concluidasHoje, color: AppColors.accent,
              icon: Icons.today_rounded, onTap: () => widget.onNavigate?.call(_idxListaOs)),
          _OsCountCard(label: 'Este Mês', value: esteMes, color: AppColors.textSecondary,
              icon: Icons.calendar_today_rounded, onTap: () => widget.onNavigate?.call(_idxListaOs)),
          _OsCountCard(label: 'Taxa Conclusão', value: null, valueStr: '${taxa.toStringAsFixed(0)}%',
              color: taxa >= 70 ? AppColors.success : AppColors.warning,
              icon: Icons.speed_rounded, onTap: () => widget.onNavigate?.call(_idxRelatorios)),
        ])),
        const SizedBox(width: 16),
        // OS recentes
        Expanded(flex: 2, child: _buildOsRecentes()),
      ]),
    ]);
  }

  Widget _buildOsRecentes() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Flexible(
              child: UpperText('OS em Aberto',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => widget.onNavigate?.call(_idxListaOs),
              child: UpperText('Ver todas', style: GoogleFonts.inter(fontSize: 12, color: AppColors.accent)),
            ),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border),
        if (_osRecentes.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(child: UpperText('Nenhuma OS aberta',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted))),
          )
        else
          ...(_osRecentes.map((os) => _OsRecenteTile(os: os,
              onTap: () => widget.onNavigate?.call(_idxListaOs)))),
      ]),
    );
  }

  // ── Tendência 7 dias ─────────────────────────────────────────────────────────
  Widget _buildTendenciaRow() {
    if (_tendencia.isEmpty) return const SizedBox.shrink();

    final maxVal = _tendencia.fold<double>(0, (m, d) {
      final e = _toDouble(d['entradas']);
      final s = _toDouble(d['saidas']);
      return [m, e, s].reduce((a, b) => a > b ? a : b);
    });

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Receita vs Despesa — Últimos 7 dias'),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          // Legenda
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            _LegendaDot(color: AppColors.success, label: 'Receita'),
            const SizedBox(width: 16),
            _LegendaDot(color: AppColors.error, label: 'Despesa'),
          ]),
          const SizedBox(height: 16),
          // Barras
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _tendencia.map((d) {
                final entradas = _toDouble(d['entradas']);
                final saidas   = _toDouble(d['saidas']);
                final hE = maxVal > 0 ? (entradas / maxVal * 80) : 0.0;
                final hS = maxVal > 0 ? (saidas   / maxVal * 80) : 0.0;
                final data = d['data']?.toString() ?? '';
                final dia  = data.length >= 10 ? data.substring(8, 10) : '';

                return Expanded(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _Bar(height: hE, color: AppColors.success),
                        const SizedBox(width: 2),
                        _Bar(height: hS, color: AppColors.error),
                      ],
                    ),
                    const SizedBox(height: 6),
                    UpperText(dia, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ));
              }).toList(),
            ),
          ),
        ]),
      ),
    ]);
  }

  // ── Linha inferior: alertas + plano ──────────────────────────────────────────
  Widget _buildBottomRow(AuthService auth) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Alertas de estoque
      if (_alertasEstoque.isNotEmpty)
        Expanded(child: _buildAlertasEstoque()),
      if (_alertasEstoque.isNotEmpty) const SizedBox(width: 16),
      // Indicador de plano FREE
      if ((auth.plano ?? 'FREE') == 'FREE')
        Expanded(child: _buildPlanoFreeCard(auth)),
    ]);
  }

  Widget _buildAlertasEstoque() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
            const SizedBox(width: 6),
            UpperText('Estoque Baixo (${_alertasEstoque.length})',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.warning)),
            const Spacer(),
            InkWell(
              onTap: () => widget.onNavigate?.call(_idxAlertas),
              child: UpperText('Ver todos', style: GoogleFonts.inter(fontSize: 12, color: AppColors.accent)),
            ),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border),
        ...(_alertasEstoque.map((item) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Expanded(child: UpperText(item['nome'] ?? '-',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: UpperText('${item['quantidade'] ?? 0} un',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.error)),
            ),
          ]),
        ))),
      ]),
    );
  }

  Widget _buildPlanoFreeCard(AuthService auth) {
    final esteMes  = _toInt(_stats?['esteMes']);
    const limiteOs = 10;
    final restam   = (limiteOs - esteMes).clamp(0, limiteOs);
    final progresso = esteMes / limiteOs;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.workspace_premium_rounded, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          UpperText('Plano FREE', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          UpperText('OS este mês', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          UpperText('$esteMes / $limiteOs', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
              color: restam <= 2 ? AppColors.error : AppColors.textPrimary)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progresso.clamp(0.0, 1.0),
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(restam <= 2 ? AppColors.error : AppColors.accent),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        UpperText(restam <= 0 ? 'Limite atingido este mês' : 'Restam $restam OS este mês',
            style: GoogleFonts.inter(fontSize: 12,
                color: restam <= 2 ? AppColors.error : AppColors.textMuted)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => widget.onNavigate?.call(17),
            icon: const Icon(Icons.upgrade_rounded, size: 16),
            label: const UpperText('Fazer Upgrade'),
          ),
        ),
      ]),
    );
  }

  // ── Ações rápidas ────────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Ações Rápidas'),
      const SizedBox(height: 12),
      Wrap(spacing: 10, runSpacing: 10, children: [
        _QuickAction(icon: Icons.add_circle_outline_rounded, label: 'Nova OS',         onTap: () => widget.onNavigate?.call(_idxNovaOs)),
        _QuickAction(icon: Icons.list_alt_rounded,           label: 'Ver OS',          onTap: () => widget.onNavigate?.call(_idxListaOs)),
        _QuickAction(icon: Icons.bar_chart_rounded,          label: 'Financeiro',      onTap: () => widget.onNavigate?.call(_idxFinanceiro)),
        _QuickAction(icon: Icons.trending_up_rounded,        label: 'Fluxo de Caixa', onTap: () => widget.onNavigate?.call(_idxFluxoCaixa)),
        _QuickAction(icon: Icons.inventory_2_rounded,        label: 'Estoque',         onTap: () => widget.onNavigate?.call(_idxEstoque)),
        _QuickAction(icon: Icons.engineering_rounded,        label: 'Mecânicos',       onTap: () => widget.onNavigate?.call(_idxMecanicos)),
        _QuickAction(icon: Icons.analytics_rounded,          label: 'Relatórios',      onTap: () => widget.onNavigate?.call(_idxRelatorios)),
      ]),
    ]);
  }

  Widget _buildError() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
    const SizedBox(height: 12),
    UpperText(_error!, style: GoogleFonts.inter(color: AppColors.textSecondary)),
    const SizedBox(height: 12),
    FilledButton.icon(onPressed: _loadData, icon: const Icon(Icons.refresh_rounded, size: 18), label: const UpperText('Tentar novamente')),
  ]));

  Widget _sectionTitle(String t) => UpperText(t,
      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary));
}

// ── Card financeiro ───────────────────────────────────────────────────────────
class _FinCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _FinCard({required this.label, required this.value, required this.icon,
      required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, color: color, size: 17),
              ),
              const Spacer(),
              if (onTap != null)
                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
            ]),
            const SizedBox(height: 10),
            UpperText(value,
                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: color),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            UpperText(label,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ),
      ),
    );
  }
}

// ── Card contador de OS ───────────────────────────────────────────────────────
class _OsCountCard extends StatelessWidget {
  final String label;
  final int? value;
  final String? valueStr;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  const _OsCountCard({required this.label, this.value, this.valueStr,
      required this.color, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 148,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            UpperText(valueStr ?? '${value ?? 0}',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            UpperText(label,
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
          ])),
        ]),
      ),
    );
  }
}

// ── Tile de OS recente ────────────────────────────────────────────────────────
class _OsRecenteTile extends StatelessWidget {
  final Map<String, dynamic> os;
  final VoidCallback? onTap;
  const _OsRecenteTile({required this.os, this.onTap});

  static const _statusColors = {
    'ABERTA':               Color(0xFFF59E0B),
    'EM_ANDAMENTO':         Color(0xFF3B82F6),
    'AGUARDANDO_PECA':      Color(0xFF8B5CF6),
    'AGUARDANDO_APROVACAO': Color(0xFFF97316),
  };
  static const _statusLabels = {
    'ABERTA': 'Aberta', 'EM_ANDAMENTO': 'Em And.',
    'AGUARDANDO_PECA': 'Ag. Peça', 'AGUARDANDO_APROVACAO': 'Ag. Aprov.',
  };

  String _fmtDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final status = os['status'] ?? 'ABERTA';
    final cor = _statusColors[status] ?? const Color(0xFF94A3B8);
    final label = _statusLabels[status] ?? status;
    final valor = double.tryParse(os['valor']?.toString() ?? '0') ?? 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Container(width: 3, height: 36,
              decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            UpperText(os['clienteNome'] ?? '-',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis),
            UpperText(
              [
                '${os['modelo'] ?? '-'} • ${os['placa'] ?? '-'}',
                if (os['criadoEm'] != null) _fmtDate(os['criadoEm'].toString()),
              ].join('  '),
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6)),
              child: UpperText(label,
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: cor)),
            ),
            if (valor > 0) ...[
              const SizedBox(height: 2),
              UpperText(formatCurrency(valor),
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary)),
            ],
          ]),
        ]),
      ),
    );
  }
}

// ── Ação rápida ───────────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _QuickAction({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          UpperText(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
        ]),
      ),
    );
  }
}

// ── Widgets do mini gráfico ───────────────────────────────────────────────────
class _Bar extends StatelessWidget {
  final double height;
  final Color color;
  const _Bar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 10,
      height: height.clamp(2.0, 90.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      ),
    );
  }
}

class _LegendaDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendaDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 4),
      UpperText(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }
}
