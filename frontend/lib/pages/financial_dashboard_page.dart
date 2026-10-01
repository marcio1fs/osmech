import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import '../mixins/auth_error_mixin.dart';
import '../utils/formatters.dart';
import '../widgets/upper_text.dart';

/// Dashboard Financeiro completo — módulo financeiro.
class FinancialDashboardPage extends StatefulWidget {
  final VoidCallback? onNavigateTransacoes;
  final VoidCallback? onNavigateNovaTransacao;
  final VoidCallback? onNavigateFluxoCaixa;
  final VoidCallback? onNavigateCategorias;

  const FinancialDashboardPage({
    super.key,
    this.onNavigateTransacoes,
    this.onNavigateNovaTransacao,
    this.onNavigateFluxoCaixa,
    this.onNavigateCategorias,
  });

  @override
  State<FinancialDashboardPage> createState() => _FinancialDashboardPageState();
}

class _FinancialDashboardPageState extends State<FinancialDashboardPage>
    with AuthErrorMixin {
  Map<String, dynamic>? _resumo;
  List<Map<String, dynamic>> _ultimasTransacoes = [];
  List<Map<String, dynamic>> _allTransacoes = [];
  List<Map<String, dynamic>> _tendencia = [];
  bool _loading = true;
  String? _error;

  DateTime? _dataInicio;
  DateTime? _dataFim;

  double? _entradasFiltradas;
  double? _saidasFiltradas;
  double? _lucroFiltrado;
  int? _qtdTransacoesFiltradas;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = FinanceService(token: safeToken);
      final results = await Future.wait([
        service.getResumoFinanceiro(),
        service.listarTransacoes(),
        service.getTendencia7Dias().catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _resumo = results[0] as Map<String, dynamic>;
        _allTransacoes = results[1] as List<Map<String, dynamic>>;
        _ultimasTransacoes = _allTransacoes.take(5).toList();
        _tendencia = results[2] as List<Map<String, dynamic>>;
        
        _aplicarFiltroPeriodo();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (!handleAuthError(e)) {
        setState(() {
          _error = 'Erro ao carregar dados financeiros';
          _loading = false;
        });
      }
    }
  }

  void _aplicarFiltroPeriodo() {
    if (_dataInicio == null || _dataFim == null) {
      _entradasFiltradas = null;
      _saidasFiltradas = null;
      _lucroFiltrado = null;
      _qtdTransacoesFiltradas = null;
      return;
    }

    double entradas = 0;
    double saidas = 0;
    int count = 0;

    final inicio = DateTime(_dataInicio!.year, _dataInicio!.month, _dataInicio!.day);
    final fim = DateTime(_dataFim!.year, _dataFim!.month, _dataFim!.day, 23, 59, 59);

    for (var tx in _allTransacoes) {
      final dataStr = tx['dataMovimentacao'] ?? tx['data'];
      if (dataStr == null) continue;
      final dt = DateTime.tryParse(dataStr.toString());
      if (dt == null) continue;

      if (dt.isAfter(inicio.subtract(const Duration(seconds: 1))) &&
          dt.isBefore(fim.add(const Duration(seconds: 1)))) {
        final valor = double.tryParse(tx['valor']?.toString() ?? '0') ?? 0.0;
        final tipo = tx['tipo']?.toString();

        if (tipo == 'ENTRADA') {
          entradas += valor;
        } else if (tipo == 'SAIDA') {
          saidas += valor;
        }
        count++;
      }
    }

    _entradasFiltradas = entradas;
    _saidasFiltradas = saidas;
    _lucroFiltrado = entradas - saidas;
    _qtdTransacoesFiltradas = count;
  }

  Future<void> _selecionarPeriodo() async {
    final picked = await showDateRangePicker(
      context: context,
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
        _aplicarFiltroPeriodo();
      });
    }
  }

  void _limparFiltros() {
    setState(() {
      _dataInicio = null;
      _dataFim = null;
      _aplicarFiltroPeriodo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Header
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 860;

                final periodBtnText = _dataInicio != null && _dataFim != null
                    ? '${formatDateBR(_dataInicio)} − ${formatDateBR(_dataFim)}'
                    : 'Período';

                if (isCompact) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.start,
                    children: [
                      SizedBox(
                        width: (constraints.maxWidth - 64).clamp(0, double.infinity),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            UpperText('Dashboard Financeiro',
                                style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            UpperText('Visão geral das finanças da oficina',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: widget.onNavigateNovaTransacao,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const UpperText('Novo Lançamento'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _selecionarPeriodo,
                        icon: const Icon(Icons.date_range_rounded, size: 18),
                        label: UpperText(periodBtnText),
                      ),
                      if (_dataInicio != null || _dataFim != null)
                        IconButton(
                          onPressed: _limparFiltros,
                          icon: const Icon(Icons.clear_rounded, size: 20, color: AppColors.error),
                          tooltip: 'Limpar filtros',
                        ),
                      OutlinedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const UpperText('Atualizar'),
                      ),
                    ],
                  );
                }

                // Sem Row no header: usar Wrap sempre evita RenderFlex overflow no Web.
                return Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.start,
                  children: [
                    SizedBox(
                      width: (constraints.maxWidth - 64).clamp(0, double.infinity),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          UpperText('Dashboard Financeiro',
                              style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          UpperText('Visão geral das finanças da oficina',
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: widget.onNavigateNovaTransacao,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const UpperText('Novo Lançamento'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _selecionarPeriodo,
                      icon: const Icon(Icons.date_range_rounded, size: 18),
                      label: UpperText(periodBtnText),
                    ),
                    if (_dataInicio != null || _dataFim != null)
                      IconButton(
                        onPressed: _limparFiltros,
                        icon: const Icon(Icons.clear_rounded, size: 20, color: AppColors.error),
                        tooltip: 'Limpar filtros',
                      ),
                    OutlinedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const UpperText('Atualizar'),
                    ),
                  ],
                );
              },
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 48, color: AppColors.error),
                            const SizedBox(height: 12),
                            UpperText(_error!,
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 12),
                            FilledButton(
                                onPressed: _loadData,
                                child: const UpperText('Tentar novamente')),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Metric cards grid
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isFiltrado = _dataInicio != null && _dataFim != null;
                                final saldo = isFiltrado ? _lucroFiltrado : _resumo?['saldoAtual'];
                                final entradas = isFiltrado ? _entradasFiltradas : _resumo?['entradasMes'];
                                final saidas = isFiltrado ? _saidasFiltradas : _resumo?['saidasMes'];
                                final lucro = isFiltrado ? _lucroFiltrado : _resumo?['lucroMes'];
                                final qtdTransacoes = isFiltrado ? _qtdTransacoesFiltradas : _resumo?['qtdTransacoesMes'];

                                final crossAxisCount =
                                    constraints.maxWidth > 1000
                                        ? 4
                                        : constraints.maxWidth > 600
                                            ? 2
                                            : 1;
                                return GridView.count(
                                  crossAxisCount: crossAxisCount,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 2.4,
                                  children: [
                                    _MetricCard(
                                      label: isFiltrado ? 'Saldo do Período' : 'Saldo Atual',
                                      value: formatCurrency(saldo),
                                      icon: Icons.account_balance_wallet_rounded,
                                      color: _toDouble(saldo) >= 0
                                          ? AppColors.success
                                          : AppColors.error,
                                      subtitle: isFiltrado ? 'No período filtrado' : 'Total acumulado',
                                      isFiltrado: isFiltrado,
                                    ),
                                    _MetricCard(
                                      label: isFiltrado ? 'Entradas do Período' : 'Entradas do Mês',
                                      value: formatCurrency(entradas),
                                      icon: Icons.trending_up_rounded,
                                      color: AppColors.success,
                                      subtitle: isFiltrado ? '$qtdTransacoes lançamentos' : '${_resumo?['qtdTransacoesMes'] ?? 0} transações',
                                      isFiltrado: isFiltrado,
                                    ),
                                    _MetricCard(
                                      label: isFiltrado ? 'Saídas do Período' : 'Saídas do Mês',
                                      value: formatCurrency(saidas),
                                      icon: Icons.trending_down_rounded,
                                      color: AppColors.error,
                                      subtitle: isFiltrado ? 'Despesas do período' : 'Despesas atuais',
                                      isFiltrado: isFiltrado,
                                    ),
                                    _MetricCard(
                                      label: isFiltrado ? 'Lucro do Período' : 'Lucro do Mês',
                                      value: formatCurrency(lucro),
                                      icon: Icons.show_chart_rounded,
                                      color: _toDouble(lucro) >= 0
                                          ? const Color(0xFF14B8A6)
                                          : AppColors.warning,
                                      subtitle: 'Entradas − Saídas',
                                      isFiltrado: isFiltrado,
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 32),

                            // Mini Gráfico de Tendência
                            _buildTendenciaChart(),

                            // Two-column layout
                            LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth > 800) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                          flex: 3,
                                          child: _buildUltimasTransacoes()),
                                      const SizedBox(width: 24),
                                      Expanded(
                                          flex: 2, child: _buildAcoesPaineis()),
                                    ],
                                  );
                                }
                                return Column(
                                  children: [
                                    _buildUltimasTransacoes(),
                                    const SizedBox(height: 24),
                                    _buildAcoesPaineis(),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUltimasTransacoes() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: UpperText('Últimas Transações',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis)),
              TextButton(
                onPressed: widget.onNavigateTransacoes,
                child: UpperText('Ver todas',
                    style: GoogleFonts.inter(
                        color: AppColors.accent, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_ultimasTransacoes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_rounded,
                        size: 48,
                        color: AppColors.textMuted.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    UpperText('Nenhuma transação registrada',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
            )
          else
            ..._ultimasTransacoes.map((tx) => _TransacaoItem(tx: tx)),
        ],
      ),
    );
  }

  Widget _buildAcoesPaineis() {
    return Column(
      children: [
        // Resumo geral
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UpperText('Resumo Geral',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              _IndicatorRow(
                  label: 'Total Entradas',
                  value: formatCurrency(_resumo?['totalEntradas']),
                  valueColor: AppColors.success),
              const Divider(color: AppColors.border, height: 20),
              _IndicatorRow(
                  label: 'Total Saídas',
                  value: formatCurrency(_resumo?['totalSaidas']),
                  valueColor: AppColors.error),
              const Divider(color: AppColors.border, height: 20),
              _IndicatorRow(
                  label: 'Lucro Total',
                  value: formatCurrency(_resumo?['lucroTotal']),
                  valueColor: (_resumo?['lucroTotal'] ?? 0) >= 0
                      ? AppColors.success
                      : AppColors.error),
              const Divider(color: AppColors.border, height: 20),
              _IndicatorRow(
                  label: 'Sem categoria',
                  value: '${_resumo?['qtdSemCategoria'] ?? 0}',
                  valueColor: (_resumo?['qtdSemCategoria'] ?? 0) > 0
                      ? AppColors.warning
                      : AppColors.success),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Ações rápidas
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UpperText('Ações Rápidas',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              _ActionButton(
                label: 'Nova Transação',
                icon: Icons.add_circle_outline_rounded,
                onTap: widget.onNavigateNovaTransacao,
              ),
              _ActionButton(
                label: 'Fluxo de Caixa',
                icon: Icons.bar_chart_rounded,
                onTap: widget.onNavigateFluxoCaixa,
              ),
              _ActionButton(
                label: 'Categorias',
                icon: Icons.category_rounded,
                onTap: widget.onNavigateCategorias,
              ),
              _ActionButton(
                label: 'Histórico',
                icon: Icons.history_rounded,
                onTap: widget.onNavigateTransacoes,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTendenciaChart() {
    if (_tendencia.isEmpty) return const SizedBox.shrink();

    final maxVal = _tendencia.fold<double>(0, (m, d) {
      final e = _toDouble(d['entradas']);
      final s = _toDouble(d['saidas']);
      return [m, e, s].reduce((a, b) => a > b ? a : b);
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UpperText(
                      'Tendência dos Últimos 7 Dias',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    UpperText(
                      'Comparativo diário de receitas e despesas',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  _LegendaDot(color: AppColors.success, label: 'Receitas'),
                  const SizedBox(width: 16),
                  _LegendaDot(color: AppColors.error, label: 'Saídas'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _tendencia.map((d) {
                final entradas = _toDouble(d['entradas']);
                final saidas = _toDouble(d['saidas']);
                
                final hE = maxVal > 0 ? (entradas / maxVal * 110) : 0.0;
                final hS = maxVal > 0 ? (saidas / maxVal * 110) : 0.0;
                
                final data = d['data']?.toString() ?? '';
                final dia = data.length >= 10 ? data.substring(8, 10) : '';
                final mes = data.length >= 10 ? data.substring(5, 7) : '';
                final labelData = '$dia/$mes';

                return Expanded(
                  child: Tooltip(
                    message: 'Receitas: ${formatCurrency(entradas)}\nSaídas: ${formatCurrency(saidas)}',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _Bar(height: hE, color: AppColors.success),
                            const SizedBox(width: 4),
                            _Bar(height: hS, color: AppColors.error),
                          ],
                        ),
                        const SizedBox(height: 8),
                        UpperText(
                          labelData,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  final bool isFiltrado;
  const _MetricCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      required this.subtitle,
      this.isFiltrado = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: UpperText(label,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600)),
                    ),
                    if (isFiltrado)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: UpperText(
                          'FILTRADO',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                UpperText(value,
                    style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                UpperText(subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final Color color;
  const _Bar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 14,
      height: height.clamp(2.0, 110.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        UpperText(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TransacaoItem extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TransacaoItem({required this.tx});

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
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isEstorno
                  ? Icons.undo_rounded
                  : isEntrada
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UpperText(tx['descricao'] ?? '',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis),
                UpperText(tx['categoriaNome'] ?? 'Sem categoria',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          UpperText(
            '${isEntrada ? '+' : '-'} ${formatCurrency(tx['valor'] ?? 0)}',
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _IndicatorRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _IndicatorRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: UpperText(label,
            style: GoogleFonts.inter(
                fontSize: 14, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        UpperText(value,
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const _ActionButton({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.accent),
            const SizedBox(width: 12),
            UpperText(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
