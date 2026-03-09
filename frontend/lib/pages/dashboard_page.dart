import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/os_service.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import '../mixins/auth_error_mixin.dart';
import '../utils/formatters.dart';

/// Dashboard profissional com métricas e visualizações detalhadas.
class DashboardPage extends StatefulWidget {
  final void Function(int)? onNavigate;
  const DashboardPage({super.key, this.onNavigate});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with AuthErrorMixin {
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _financeSummary;
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
      final osService = OsService(token: safeToken);
      final financeService = FinanceService(token: safeToken);

      final results = await Future.wait([
        osService.getDashboardStats().catchError((e) {
          debugPrint('[Dashboard] Falha ao carregar stats OS: $e');
          return <String, dynamic>{
            'total': 0,
            'abertas': 0,
            'emAndamento': 0,
            'concluidas': 0,
            'esteMes': 0,
          };
        }),
        financeService.getResumoFinanceiro().catchError((e) {
          debugPrint('[Dashboard] Falha ao carregar resumo financeiro: $e');
          return <String, dynamic>{};
        }),
      ]);

      setState(() {
        _stats = results[0];
        _financeSummary = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!handleAuthError(e)) {
        setState(() {
          _error = 'Erro ao carregar dados';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Dashboard', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Text('Visão geral da sua oficina', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
                const Spacer(),
                _ActionButton(icon: Icons.refresh_rounded, label: 'Atualizar', onTap: _loadData),
                const SizedBox(width: 12),
                _ActionButton(icon: Icons.add_rounded, label: 'Nova OS', primary: true, onTap: () => widget.onNavigate?.call(2)),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                            const SizedBox(height: 16),
                            Text(_error!, style: GoogleFonts.inter(color: AppColors.textSecondary)),
                            const SizedBox(height: 16),
                            FilledButton.icon(onPressed: _loadData, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Tentar novamente')),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWelcomeCard(auth),
                            const SizedBox(height: 28),
                            _buildSectionTitle('Resumo Financeiro'),
                            const SizedBox(height: 16),
                            _buildFinanceMetrics(),
                            const SizedBox(height: 28),
                            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Expanded(flex: 1, child: _buildOsStatusVisual()),
                              const SizedBox(width: 24),
                              Expanded(flex: 2, child: _buildOsMetricsCard()),
                            ]),
                            const SizedBox(height: 28),
                            _buildSectionTitle('Indicadores de Performance'),
                            const SizedBox(height: 16),
                            _buildPerformanceIndicators(),
                            const SizedBox(height: 28),
                            _buildSectionTitle('Ações Rápidas'),
                            const SizedBox(height: 16),
                            _buildQuickActions(),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(AuthService auth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E40AF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Olá, ${auth.nome ?? "Usuário"}! 👋', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 6),
                Text('Acompanhe o desempenho da sua oficina', style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text('Plano ${auth.plano ?? "PRO"}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ],
            ),
          ),
          Container(width: 72, height: 72, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.build_rounded, size: 36, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary));

  Widget _buildFinanceMetrics() {
    final totalReceitas = _financeSummary?['totalReceitas'] ?? 0;
    final totalDespesas = _financeSummary?['totalDespesas'] ?? 0;
    final lucro = totalReceitas - totalDespesas;
    final margemLucro = totalReceitas > 0 ? (lucro / totalReceitas * 100) : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        return Wrap(
          spacing: 16, runSpacing: 16,
          children: [
            _FinanceMetricCard(label: 'Receitas do Mês', value: formatCurrency(totalReceitas), icon: Icons.trending_up_rounded, color: AppColors.success, trend: '+12%', isPositive: true, width: isWide ? 200 : null),
            _FinanceMetricCard(label: 'Despesas do Mês', value: formatCurrency(totalDespesas), icon: Icons.trending_down_rounded, color: AppColors.error, trend: '-5%', isPositive: false, width: isWide ? 200 : null),
            _FinanceMetricCard(label: 'Lucro do Mês', value: formatCurrency(lucro), icon: Icons.account_balance_wallet_rounded, color: lucro >= 0 ? AppColors.success : AppColors.error, trend: lucro >= 0 ? '+8%' : '-15%', isPositive: lucro >= 0, width: isWide ? 200 : null),
            _FinanceMetricCard(label: 'Margem de Lucro', value: '${margemLucro.toStringAsFixed(1)}%', icon: Icons.pie_chart_rounded, color: margemLucro >= 20 ? AppColors.success : Colors.orange, trend: margemLucro >= 20 ? 'Excelente' : 'Atenção', isPositive: margemLucro >= 20, width: isWide ? 200 : null),
          ],
        );
      },
    );
  }

  Widget _buildOsStatusVisual() {
    final total = _stats?['total'] ?? 0;
    final abertas = _stats?['abertas'] ?? 0;
    final emAndamento = _stats?['emAndamento'] ?? 0;
    final concluidas = _stats?['concluidas'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status das OS', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(width: 160, height: 160, child: CircularProgressIndicator(value: 1, strokeWidth: 24, backgroundColor: Colors.transparent, valueColor: AlwaysStoppedAnimation<Color>(AppColors.border.withValues(alpha: 0.3)))),
                if (total > 0) SizedBox(width: 160, height: 160, child: CircularProgressIndicator(value: concluidas / total, strokeWidth: 24, backgroundColor: Colors.transparent, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success))),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$total', style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  Text('Total OS', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _LegendItem(color: AppColors.success, label: 'Concluídas', value: '$concluidas', percentage: total > 0 ? ((concluidas / total) * 100).toStringAsFixed(0) : '0'),
          const SizedBox(height: 8),
          _LegendItem(color: const Color(0xFF8B5CF6), label: 'Em Andamento', value: '$emAndamento', percentage: total > 0 ? ((emAndamento / total) * 100).toStringAsFixed(0) : '0'),
          const SizedBox(height: 8),
          _LegendItem(color: const Color(0xFFF59E0B), label: 'Abertas', value: '$abertas', percentage: total > 0 ? ((abertas / total) * 100).toStringAsFixed(0) : '0'),
        ],
      ),
    );
  }

  Widget _buildOsMetricsCard() {
    final total = _stats?['total'] ?? 0;
    final esteMes = _stats?['esteMes'] ?? 0;
    final abertas = _stats?['abertas'] ?? 0;
    final emAndamento = _stats?['emAndamento'] ?? 0;
    final concluidas = _stats?['concluidas'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Métricas de OS', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('Este mês: $esteMes OS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ProgressBar(label: 'Concluídas', value: concluidas.toDouble(), maxValue: total > 0 ? total.toDouble() : 1, color: AppColors.success),
          const SizedBox(height: 16),
          _ProgressBar(label: 'Em Andamento', value: emAndamento.toDouble(), maxValue: total > 0 ? total.toDouble() : 1, color: const Color(0xFF8B5CF6)),
          const SizedBox(height: 16),
          _ProgressBar(label: 'Abertas', value: abertas.toDouble(), maxValue: total > 0 ? total.toDouble() : 1, color: const Color(0xFFF59E0B)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _MiniStat(label: 'Média/Dia', value: total > 0 ? (total / 30).toStringAsFixed(1) : '0', icon: Icons.speed)),
              const SizedBox(width: 12),
              Expanded(child: _MiniStat(label: 'Taxa Conclusão', value: total > 0 ? '${((concluidas / total) * 100).toStringAsFixed(0)}%' : '0%', icon: Icons.check_circle_outline)),
              const SizedBox(width: 12),
              Expanded(child: _MiniStat(label: 'Em Andamento', value: '$emAndamento', icon: Icons.engineering)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicators() {
    final total = _stats?['total'] ?? 0;
    final concluidas = _stats?['concluidas'] ?? 0;
    final taxaConclusao = total > 0 ? (concluidas / total * 100) : 0;
    final mediaDiaria = total > 0 ? total / 30 : 0;

    return Row(
      children: [
        Expanded(child: _PerformanceCard(title: 'Taxa de Conclusão', value: '${taxaConclusao.toStringAsFixed(1)}%', subtitle: taxaConclusao >= 70 ? 'Excelente performance' : 'Precisa melhorar', icon: Icons.check_circle_outline, color: taxaConclusao >= 70 ? AppColors.success : Colors.orange, progress: taxaConclusao / 100)),
        const SizedBox(width: 16),
        Expanded(child: _PerformanceCard(title: 'Média Diária', value: mediaDiaria.toStringAsFixed(1), subtitle: 'OS por dia', icon: Icons.speed, color: AppColors.accent, progress: mediaDiaria / 10)),
        const SizedBox(width: 16),
        Expanded(child: _PerformanceCard(title: 'Eficiência', value: taxaConclusao >= 70 ? 'Alta' : 'Média', subtitle: taxaConclusao >= 70 ? '>70% concluídas' : '<70% concluídas', icon: Icons.trending_up, color: taxaConclusao >= 70 ? AppColors.success : Colors.orange, progress: taxaConclusao / 100)),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Wrap(
      spacing: 12, runSpacing: 12,
      children: [
        _QuickAction(icon: Icons.add_circle_outline_rounded, label: 'Nova OS', onTap: () => widget.onNavigate?.call(2)),
        _QuickAction(icon: Icons.list_alt_rounded, label: 'Ver todas OS', onTap: () => widget.onNavigate?.call(1)),
        _QuickAction(icon: Icons.bar_chart_rounded, label: 'Financeiro', onTap: () => widget.onNavigate?.call(5)),
        _QuickAction(icon: Icons.analytics_rounded, label: 'Relatórios', onTap: () => widget.onNavigate?.call(7)),
        _QuickAction(icon: Icons.inventory_2_rounded, label: 'Estoque', onTap: () => widget.onNavigate?.call(8)),
        _QuickAction(icon: Icons.people_rounded, label: 'Clientes', onTap: () => widget.onNavigate?.call(9)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, this.primary = false, required this.onTap});

  @override
  Widget build(BuildContext context) => primary ? FilledButton.icon(onPressed: onTap, icon: Icon(icon, size: 18), label: Text(label)) : OutlinedButton.icon(onPressed: onTap, icon: Icon(icon, size: 18), label: Text(label));
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final String percentage;
  const _LegendItem({required this.color, required this.label, required this.value, required this.percentage});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary))),
      Text('$value ($percentage%)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    ],
  );
}

class _ProgressBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;
  const _ProgressBar({required this.label, required this.value, required this.maxValue, required this.color});

  @override
  Widget build(BuildContext context) {
    final percentage = maxValue > 0 ? value / maxValue : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          Text(value.toInt().toString(), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: percentage, backgroundColor: color.withValues(alpha: 0.15), valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 8)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MiniStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.accent),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
      ])),
    ]),
  );
}

class _FinanceMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  final bool isPositive;
  final double? width;
  const _FinanceMetricCard({required this.label, required this.value, required this.icon, required this.color, required this.trend, required this.isPositive, this.width});

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: isPositive ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 12, color: isPositive ? AppColors.success : AppColors.error),
            const SizedBox(width: 2),
            Text(trend, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: isPositive ? AppColors.success : AppColors.error)),
          ]),
        ),
      ]),
      const SizedBox(height: 16),
      Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      const SizedBox(height: 4),
      Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
    ]),
  );
}

class _PerformanceCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double progress;
  const _PerformanceCard({required this.title, required this.value, required this.subtitle, required this.icon, required this.color, required this.progress});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(value, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
      const SizedBox(height: 12),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0), backgroundColor: color.withValues(alpha: 0.15), valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 6)),
    ]),
  );
}

class _QuickAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.accent.withValues(alpha: 0.06) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _hovered ? AppColors.accent.withValues(alpha: 0.3) : AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(widget.icon, size: 20, color: AppColors.accent),
          const SizedBox(width: 10),
          Text(widget.label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ]),
      ),
    ),
  );
}
