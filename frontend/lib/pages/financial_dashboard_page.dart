import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';

/// Dashboard Financeiro — design moderno.
class FinancialDashboardPage extends StatefulWidget {
  const FinancialDashboardPage({super.key});

  @override
  State<FinancialDashboardPage> createState() => _FinancialDashboardPageState();
}

class _FinancialDashboardPageState extends State<FinancialDashboardPage> {
  Map<String, dynamic>? _resumo;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadResumo();
  }

  Future<void> _loadResumo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = PaymentService(token: auth.token!);
      final data = await service.getResumoFinanceiro();
      setState(() {
        _resumo = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar resumo financeiro';
        _loading = false;
      });
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'ACTIVE':
        return AppColors.success;
      case 'PAST_DUE':
        return AppColors.warning;
      case 'SUSPENDED':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'ACTIVE':
        return 'Ativa';
      case 'PAST_DUE':
        return 'Atrasada';
      case 'SUSPENDED':
        return 'Suspensa';
      case 'NONE':
        return 'Sem assinatura';
      default:
        return status ?? '-';
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
                    Text('Financeiro',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text('Acompanhe receitas e pagamentos',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _loadResumo,
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
                            Icon(Icons.error_outline_rounded,
                                size: 48, color: AppColors.error),
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 12),
                            FilledButton(
                                onPressed: _loadResumo,
                                child: const Text('Tentar novamente')),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Subscription status bar
                            Container(
                              width: double.infinity,
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
                                      color: _statusColor(
                                              _resumo?['statusAssinatura'])
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.card_membership_rounded,
                                        color: _statusColor(
                                            _resumo?['statusAssinatura']),
                                        size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Plano ${_resumo?['planoAtual'] ?? '-'}',
                                          style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _statusColor(_resumo?[
                                                    'statusAssinatura']),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                                _statusLabel(_resumo?[
                                                    'statusAssinatura']),
                                                style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    color: AppColors
                                                        .textSecondary)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'R\$ ${(_resumo?['valorAssinatura'] ?? 0).toStringAsFixed(2)}/mês',
                                    style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Metrics grid
                            Text('Resumo Financeiro',
                                style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final crossAxisCount =
                                    constraints.maxWidth > 900 ? 4 : 2;
                                return GridView.count(
                                  crossAxisCount: crossAxisCount,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 2.2,
                                  children: [
                                    _FinMetricCard(
                                      label: 'Receita Total',
                                      value:
                                          'R\$ ${(_resumo?['receitaTotal'] ?? 0).toStringAsFixed(2)}',
                                      icon:
                                          Icons.account_balance_wallet_rounded,
                                      color: AppColors.success,
                                    ),
                                    _FinMetricCard(
                                      label: 'Receita do Mês',
                                      value:
                                          'R\$ ${(_resumo?['receitaMesAtual'] ?? 0).toStringAsFixed(2)}',
                                      icon: Icons.trending_up_rounded,
                                      color: AppColors.accent,
                                    ),
                                    _FinMetricCard(
                                      label: 'Pendente',
                                      value:
                                          'R\$ ${(_resumo?['totalPendente'] ?? 0).toStringAsFixed(2)}',
                                      icon: Icons.hourglass_empty_rounded,
                                      color: AppColors.warning,
                                    ),
                                    _FinMetricCard(
                                      label: 'OS Pagas (Mês)',
                                      value:
                                          '${_resumo?['qtdOsPagasMes'] ?? 0}',
                                      icon: Icons.check_circle_outline_rounded,
                                      color: const Color(0xFF14B8A6),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 24),

                            // Additional indicators
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
                                  Text('Indicadores',
                                      style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(height: 16),
                                  _IndicatorRow(
                                    label: 'Pagamentos no mês',
                                    value:
                                        '${_resumo?['qtdPagamentosMes'] ?? 0}',
                                  ),
                                  const Divider(
                                      color: AppColors.border, height: 24),
                                  _IndicatorRow(
                                    label: 'Pagamentos pendentes',
                                    value: '${_resumo?['qtdPendentes'] ?? 0}',
                                    valueColor:
                                        (_resumo?['qtdPendentes'] ?? 0) > 0
                                            ? AppColors.warning
                                            : AppColors.success,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FinMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _FinMetricCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

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
              color: color.withOpacity(0.08),
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
                Text(
                  value,
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
              ],
            ),
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
        Text(
          value,
          style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary),
        ),
      ],
    );
  }
}
