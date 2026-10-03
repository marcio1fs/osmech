import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';
import '../mixins/auth_error_mixin.dart';
import '../utils/formatters.dart';
import '../widgets/upper_text.dart';

/// Tela de histórico de pagamentos.
class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage>
    with SingleTickerProviderStateMixin, AuthErrorMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _todos = [];
  List<Map<String, dynamic>> _assinatura = [];
  List<Map<String, dynamic>> _os = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPagamentos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPagamentos() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = PaymentService(token: safeToken);
      final todos = await service.listarPagamentos();
      if (!mounted) return;
      setState(() {
        _todos = todos;
        _assinatura = todos.where((p) => p['tipo'] == 'ASSINATURA').toList();
        _os = todos.where((p) => p['tipo'] == 'OS').toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (!handleAuthError(e)) {
        setState(() {
          _error = 'Erro ao carregar pagamentos';
          _loading = false;
        });
      }
    }
  }

  Future<void> _confirmarPagamento(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: UpperText('Confirmar Pagamento',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: UpperText(
          'Tem certeza que deseja confirmar este pagamento?',
          style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const UpperText('Não')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const UpperText('Sim, confirmar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final service = PaymentService(token: safeToken);
      await service.confirmarPagamento(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: UpperText('Pagamento confirmado!'),
              backgroundColor: AppColors.success),
        );
        _loadPagamentos();
      }
    } catch (e) {
      if (!handleAuthError(e) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: UpperText('Erro: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _cancelarPagamento(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: UpperText('Cancelar Pagamento',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: UpperText(
          'Tem certeza que deseja cancelar este pagamento? Essa ação não pode ser desfeita.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const UpperText('Não')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const UpperText('Sim, cancelar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final service = PaymentService(token: safeToken);
      await service.cancelarPagamento(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: UpperText('Pagamento cancelado'),
              backgroundColor: AppColors.warning),
        );
        _loadPagamentos();
      }
    } catch (e) {
      if (!handleAuthError(e) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: UpperText('Erro: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'PAGO':
        return AppColors.success;
      case 'PENDENTE':
        return AppColors.warning;
      case 'FALHOU':
        return AppColors.error;
      case 'CANCELADO':
        return AppColors.textMuted;
      case 'REEMBOLSADO':
        return AppColors.accent;
      default:
        return AppColors.textMuted;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'PAGO':
        return 'Pago';
      case 'PENDENTE':
        return 'Pendente';
      case 'FALHOU':
        return 'Falhou';
      case 'CANCELADO':
        return 'Cancelado';
      case 'REEMBOLSADO':
        return 'Reembolsado';
      default:
        return status ?? '-';
    }
  }

  String _metodoPagamentoLabel(String? metodo) {
    switch (metodo) {
      case 'PIX':
        return 'PIX';
      case 'CARTAO_CREDITO':
        return 'Cartão de Crédito';
      case 'CARTAO_DEBITO':
        return 'Cartão de Débito';
      case 'CARTAO':
        return 'Cartão';
      case 'DINHEIRO':
        return 'Dinheiro';
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

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 640;
    final horizontalPadding = isCompact ? 16.0 : 32.0;

    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            UpperText('Pagamentos',
                                style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            UpperText('${_todos.length} registro(s)',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _loadPagamentos,
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        tooltip: 'Atualizar',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabController,
                    isScrollable: isCompact,
                    labelStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    unselectedLabelStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w400, fontSize: 13),
                    labelColor: AppColors.accent,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.accent,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: [
                      Tab(text: 'Todos (${_todos.length})'),
                      Tab(text: 'Assinatura (${_assinatura.length})'),
                      Tab(text: 'OS (${_os.length})'),
                    ],
                  ),
                ],
              ),
            ),
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
                                  onPressed: _loadPagamentos,
                                  child: const UpperText('Tentar novamente')),
                            ],
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildPayments(_todos),
                            _buildPayments(_assinatura),
                            _buildPayments(_os),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayments(List<Map<String, dynamic>> pagamentos) {
    if (pagamentos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 12),
            UpperText('Nenhum pagamento encontrado',
                style: GoogleFonts.inter(
                    fontSize: 15, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return _buildPaymentCards(pagamentos);
        }
        return _buildPaymentTable(pagamentos);
      },
    );
  }

  Widget _buildPaymentCards(List<Map<String, dynamic>> pagamentos) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: pagamentos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = pagamentos[index];
        final status = p['status'] as String?;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: UpperText(
                      p['descricao'] ?? p['tipo'] ?? 'Pagamento',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(status),
                ],
              ),
              const SizedBox(height: 10),
              _MobilePaymentRow(
                label: 'Valor',
                value: formatCurrency(p['valor'] ?? 0),
                valueWeight: FontWeight.w800,
              ),
              _MobilePaymentRow(
                label: 'Método',
                value: _metodoPagamentoLabel(p['metodoPagamento']),
              ),
              _MobilePaymentRow(
                label: 'Tipo',
                value: p['tipo'] ?? '-',
              ),
              _MobilePaymentRow(
                label: 'Data',
                value: formatDateTimeBR(p['criadoEm']),
              ),
              if (status == 'PENDENTE') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _cancelarPagamento(p['id']),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const UpperText('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _confirmarPagamento(p['id']),
                        icon: const Icon(Icons.check_circle_outline_rounded,
                            size: 18),
                        label: const UpperText('Confirmar'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentTable(List<Map<String, dynamic>> pagamentos) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(AppColors.surfaceVariant),
              headingTextStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary),
              dataTextStyle:
                  GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
              columnSpacing: 20,
              horizontalMargin: 20,
              columns: const [
                DataColumn(label: UpperText('DESCRIÇÃO')),
                DataColumn(label: UpperText('TIPO')),
                DataColumn(label: UpperText('MÉTODO')),
                DataColumn(label: UpperText('STATUS')),
                DataColumn(label: UpperText('VALOR'), numeric: true),
                DataColumn(label: UpperText('DATA')),
                DataColumn(label: UpperText('AÇÕES')),
              ],
              rows: pagamentos.map((p) {
                final status = p['status'] as String?;
                return DataRow(
                  cells: [
                    DataCell(UpperText(p['descricao'] ?? p['tipo'] ?? 'Pagamento',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                    DataCell(UpperText(p['tipo'] ?? '-')),
                    DataCell(UpperText(_metodoPagamentoLabel(p['metodoPagamento']))),
                    DataCell(_buildStatusChip(status)),
                    DataCell(UpperText(formatCurrency(p['valor'] ?? 0),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
                    DataCell(UpperText(formatDateTimeBR(p['criadoEm']),
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textSecondary))),
                    DataCell(
                      status == 'PENDENTE'
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: 18,
                                      color: AppColors.success),
                                  onPressed: () => _confirmarPagamento(p['id']),
                                  tooltip: 'Confirmar',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel_outlined,
                                      size: 18, color: AppColors.error),
                                  onPressed: () => _cancelarPagamento(p['id']),
                                  tooltip: 'Cancelar',
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: UpperText(
        _statusLabel(status),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MobilePaymentRow extends StatelessWidget {
  final String label;
  final String value;
  final FontWeight valueWeight;

  const _MobilePaymentRow({
    required this.label,
    required this.value,
    this.valueWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: UpperText(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: UpperText(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: valueWeight,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
