import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import '../mixins/auth_error_mixin.dart';
import '../utils/formatters.dart';

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
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = FinanceService(token: safeToken);
      final results = await Future.wait([
        service.getResumoFinanceiro(),
        service.listarTransacoes(),
      ]);
      setState(() {
        _resumo = results[0] as Map<String, dynamic>;
        final allTx = results[1] as List<Map<String, dynamic>>;
        _ultimasTransacoes = allTx.take(5).toList();
        _loading = false;
      });
    } catch (e) {
      if (!handleAuthError(e)) {
        setState(() {
          _error = 'Erro ao carregar dados financeiros';
          _loading = false;
        });
      }
    }
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
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Dashboard Financeiro',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text('Visão geral das finanças da oficina',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: widget.onNavigateNovaTransacao,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Novo Lançamento'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Atualizar'),
                ),
              ],
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
                            Text(_error!,
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 12),
                            FilledButton(
                                onPressed: _loadData,
                                child: const Text('Tentar novamente')),
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
                                      label: 'Saldo Atual',
                                      value: formatCurrency(
                                          _resumo?['saldoAtual']),
                                      icon:
                                          Icons.account_balance_wallet_rounded,
                                      color: (_resumo?['saldoAtual'] ?? 0) >= 0
                                          ? AppColors.success
                                          : AppColors.error,
                                      subtitle: 'Total acumulado',
                                    ),
                                    _MetricCard(
                                      label: 'Entradas do Mês',
                                      value: formatCurrency(
                                          _resumo?['entradasMes']),
                                      icon: Icons.trending_up_rounded,
                                      color: AppColors.success,
                                      subtitle:
                                          '${_resumo?['qtdTransacoesMes'] ?? 0} transações',
                                    ),
                                    _MetricCard(
                                      label: 'Saídas do Mês',
                                      value:
                                          formatCurrency(_resumo?['saidasMes']),
                                      icon: Icons.trending_down_rounded,
                                      color: AppColors.error,
                                      subtitle: 'Despesas atuais',
                                    ),
                                    _MetricCard(
                                      label: 'Lucro do Mês',
                                      value:
                                          formatCurrency(_resumo?['lucroMes']),
                                      icon: Icons.show_chart_rounded,
                                      color: (_resumo?['lucroMes'] ?? 0) >= 0
                                          ? const Color(0xFF14B8A6)
                                          : AppColors.warning,
                                      subtitle: 'Entradas − Saídas',
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 32),

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
              Text('Últimas Transações',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              TextButton(
                onPressed: widget.onNavigateTransacoes,
                child: Text('Ver todas',
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
                    Text('Nenhuma transação registrada',
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
              Text('Resumo Geral',
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
              Text('Ações Rápidas',
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
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  const _MetricCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value,
                    style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis),
                Text(subtitle,
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
                Text(tx['descricao'] ?? '',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis),
                Text(tx['categoriaNome'] ?? 'Sem categoria',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(
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
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 14, color: AppColors.textSecondary)),
        Text(value,
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
            Text(label,
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
