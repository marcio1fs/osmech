import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';
import '../mixins/auth_error_mixin.dart';

/// Tela de histórico de pagamentos — design moderno com tabs.
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = PaymentService(token: auth.token!);
      final todos = await service.listarPagamentos();
      setState(() {
        _todos = todos;
        _assinatura = todos.where((p) => p['tipo'] == 'ASSINATURA').toList();
        _os = todos.where((p) => p['tipo'] == 'OS').toList();
        _loading = false;
      });
    } catch (e) {
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
        title: Text('Confirmar Pagamento',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Tem certeza que deseja confirmar este pagamento?',
          style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Não')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sim, confirmar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = PaymentService(token: auth.token!);
      await service.confirmarPagamento(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pagamento confirmado!'),
              backgroundColor: AppColors.success),
        );
        _loadPagamentos();
      }
    } catch (e) {
      if (!handleAuthError(e) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _cancelarPagamento(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancelar Pagamento',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Tem certeza que deseja cancelar este pagamento? Essa ação não pode ser desfeita.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Não')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sim, cancelar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = PaymentService(token: auth.token!);
      await service.cancelarPagamento(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pagamento cancelado'),
              backgroundColor: AppColors.warning),
        );
        _loadPagamentos();
      }
    } catch (e) {
      if (!handleAuthError(e) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'), backgroundColor: AppColors.error));
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
      case 'DINHEIRO':
        return 'Dinheiro';
      case 'BOLETO':
        return 'Boleto';
      case 'TRANSFERENCIA':
        return 'Transferência';
      default:
        return metodo ?? '-';
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
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
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pagamentos',
                            style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        Text('${_todos.length} registro(s)',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _loadPagamentos,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Atualizar'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
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
                                onPressed: _loadPagamentos,
                                child: const Text('Tentar novamente')),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPaymentTable(_todos),
                          _buildPaymentTable(_assinatura),
                          _buildPaymentTable(_os),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTable(List<Map<String, dynamic>> pagamentos) {
    if (pagamentos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('Nenhum pagamento encontrado',
                style: GoogleFonts.inter(
                    fontSize: 15, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
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
                DataColumn(label: Text('DESCRIÇÃO')),
                DataColumn(label: Text('TIPO')),
                DataColumn(label: Text('MÉTODO')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('VALOR'), numeric: true),
                DataColumn(label: Text('DATA')),
                DataColumn(label: Text('AÇÕES')),
              ],
              rows: pagamentos.map((p) {
                final status = p['status'] as String?;
                final color = _statusColor(status);
                return DataRow(
                  cells: [
                    DataCell(Text(p['descricao'] ?? p['tipo'] ?? 'Pagamento',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                    DataCell(Text(p['tipo'] ?? '-')),
                    DataCell(Text(_metodoPagamentoLabel(p['metodoPagamento']))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(_statusLabel(status),
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: color)),
                      ),
                    ),
                    DataCell(Text('R\$ ${(p['valor'] ?? 0).toStringAsFixed(2)}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
                    DataCell(Text(_formatDateTime(p['criadoEm']),
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
}
