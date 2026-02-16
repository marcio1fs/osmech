import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import '../mixins/auth_error_mixin.dart';
import '../utils/formatters.dart';

/// Tela de Fluxo de Caixa com visualização diária.
class FluxoCaixaPage extends StatefulWidget {
  const FluxoCaixaPage({super.key});

  @override
  State<FluxoCaixaPage> createState() => _FluxoCaixaPageState();
}

class _FluxoCaixaPageState extends State<FluxoCaixaPage> with AuthErrorMixin {
  List<Map<String, dynamic>> _fluxo = [];
  bool _loading = true;
  String? _error;

  // Período padrão: últimos 30 dias
  late DateTime _inicio;
  late DateTime _fim;

  @override
  void initState() {
    super.initState();
    _fim = DateTime.now();
    _inicio = _fim.subtract(const Duration(days: 30));
    _loadFluxo();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadFluxo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = FinanceService(token: safeToken);
      final data =
          await service.getFluxoCaixa(_formatDate(_inicio), _formatDate(_fim));
      setState(() {
        _fluxo = data;
        _loading = false;
      });
    } catch (e) {
      if (!handleAuthError(e)) {
        setState(() {
          _error = 'Erro ao carregar fluxo de caixa';
          _loading = false;
        });
      }
    }
  }

  Future<void> _selecionarPeriodo() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _inicio, end: _fim),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accent,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _inicio = picked.start;
        _fim = picked.end;
      });
      _loadFluxo();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Totais do período
    double totalEntradas = 0;
    double totalSaidas = 0;
    for (var f in _fluxo) {
      totalEntradas += (f['totalEntradas'] ?? 0).toDouble();
      totalSaidas += (f['totalSaidas'] ?? 0).toDouble();
    }
    final saldoPeriodo = totalEntradas - totalSaidas;

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
                    Text('Fluxo de Caixa',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(
                        '${formatDateBR(_formatDate(_inicio))} a ${formatDateBR(_formatDate(_fim))}',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _selecionarPeriodo,
                  icon: const Icon(Icons.date_range_rounded, size: 18),
                  label: const Text('Período'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _loadFluxo,
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
                                onPressed: _loadFluxo,
                                child: const Text('Tentar novamente')),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Summary cards
                          Padding(
                            padding:
                                const EdgeInsets.all(32).copyWith(bottom: 0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _SummaryCard(
                                    label: 'Entradas',
                                    value: formatCurrency(totalEntradas),
                                    color: AppColors.success,
                                    icon: Icons.arrow_downward_rounded,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _SummaryCard(
                                    label: 'Saídas',
                                    value: formatCurrency(totalSaidas),
                                    color: AppColors.error,
                                    icon: Icons.arrow_upward_rounded,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _SummaryCard(
                                    label: 'Saldo do Período',
                                    value: formatCurrency(saldoPeriodo),
                                    color: saldoPeriodo >= 0
                                        ? AppColors.success
                                        : AppColors.error,
                                    icon: Icons.account_balance_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Table
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: _fluxo.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.bar_chart_rounded,
                                                size: 48,
                                                color: AppColors.textMuted
                                                    .withValues(alpha: 0.5)),
                                            const SizedBox(height: 8),
                                            Text(
                                                'Nenhum dado no período selecionado',
                                                style: GoogleFonts.inter(
                                                    color: AppColors
                                                        .textSecondary)),
                                          ],
                                        ),
                                      )
                                    : SingleChildScrollView(
                                        padding: const EdgeInsets.all(16),
                                        child: _buildTable(),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.5),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
        4: FlexColumnWidth(2),
      },
      border: TableBorder(
        horizontalInside:
            BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          children: [
            _tableHeader('Data'),
            _tableHeader('Entradas'),
            _tableHeader('Saídas'),
            _tableHeader('Saldo Dia'),
            _tableHeader('Acumulado'),
          ],
        ),
        // Data rows
        ..._fluxo.map((f) {
          final saldo = (f['saldo'] ?? 0).toDouble();
          final acumulado = (f['saldoAcumulado'] ?? 0).toDouble();
          return TableRow(
            children: [
              _tableCell(formatDateBR(f['data']?.toString())),
              _tableCell(
                formatCurrency(f['totalEntradas']),
                color: AppColors.success,
              ),
              _tableCell(
                formatCurrency(f['totalSaidas']),
                color: AppColors.error,
              ),
              _tableCell(
                formatCurrency(saldo),
                color: saldo >= 0 ? AppColors.success : AppColors.error,
                bold: true,
              ),
              _tableCell(
                formatCurrency(acumulado),
                color: acumulado >= 0 ? AppColors.textPrimary : AppColors.error,
                bold: true,
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary)),
    );
  }

  Widget _tableCell(String text, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? AppColors.textPrimary)),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _SummaryCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
