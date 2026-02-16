import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import '../mixins/auth_error_mixin.dart';
import '../utils/formatters.dart';

/// Tela de histórico de transações financeiras com filtros e estorno.
class TransacoesHistoricoPage extends StatefulWidget {
  const TransacoesHistoricoPage({super.key});

  @override
  State<TransacoesHistoricoPage> createState() =>
      _TransacoesHistoricoPageState();
}

class _TransacoesHistoricoPageState extends State<TransacoesHistoricoPage>
    with AuthErrorMixin {
  List<Map<String, dynamic>> _transacoes = [];
  bool _loading = true;
  String? _error;
  String? _filtroTipo;
  DateTime? _dataInicio;
  DateTime? _dataFim;

  @override
  void initState() {
    super.initState();
    _loadTransacoes();
  }

  String _formatDateParam(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadTransacoes() async {
    setState(() {
      _loading = true;
      _error = null;
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
        _loading = false;
      });
    } catch (e) {
      if (!handleAuthError(e)) {
        setState(() {
          _error = 'Erro ao carregar transações';
          _loading = false;
        });
      }
    }
  }

  Future<void> _estornar(int transacaoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Estornar Transação'),
        content: const Text(
            'Deseja estornar esta transação? Uma transação inversa será criada automaticamente.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Estornar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final service = FinanceService(token: safeToken);
      await service.estornarTransacao(transacaoId);
      _loadTransacoes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Transação estornada com sucesso!',
                  style: GoogleFonts.inter()),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (!handleAuthError(e)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
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
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dataInicio != null && _dataFim != null
          ? DateTimeRange(start: _dataInicio!, end: _dataFim!)
          : null,
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
        _dataInicio = picked.start;
        _dataFim = picked.end;
      });
      _loadTransacoes();
    }
  }

  void _limparFiltros() {
    setState(() {
      _filtroTipo = null;
      _dataInicio = null;
      _dataFim = null;
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
        return 'Cartão';
      case 'BOLETO':
        return 'Boleto';
      case 'TRANSFERENCIA':
        return 'Transferência';
      default:
        return metodo ?? '-';
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
                    Text('Histórico de Transações',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text('${_transacoes.length} transações encontradas',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
                const Spacer(),

                // Filtro de tipo
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filtroTipo,
                      hint: Text('Tipo',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.textMuted)),
                      items: const [
                        DropdownMenuItem(
                            value: 'ENTRADA', child: Text('Entradas')),
                        DropdownMenuItem(value: 'SAIDA', child: Text('Saídas')),
                      ],
                      onChanged: (v) {
                        setState(() => _filtroTipo = v);
                        _loadTransacoes();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _selecionarPeriodo,
                  icon: const Icon(Icons.date_range_rounded, size: 18),
                  label: const Text('Período'),
                ),
                if (_filtroTipo != null || _dataInicio != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _limparFiltros,
                    icon: const Icon(Icons.clear_rounded, size: 20),
                    tooltip: 'Limpar filtros',
                  ),
                ],
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
                                onPressed: _loadTransacoes,
                                child: const Text('Tentar novamente')),
                          ],
                        ),
                      )
                    : _transacoes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long_rounded,
                                    size: 64,
                                    color: AppColors.textMuted
                                        .withValues(alpha: 0.4)),
                                const SizedBox(height: 12),
                                Text('Nenhuma transação encontrada',
                                    style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Text('Crie um lançamento para começar',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.textMuted)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(32),
                            itemCount: _transacoes.length,
                            itemBuilder: (context, index) {
                              final tx = _transacoes[index];
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
      ),
    );
  }
}

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tx['descricao'] ?? '',
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
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
                        text: 'OS #${tx['referenciaId']}',
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
                  Text(tx['observacoes'],
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
        Text(text,
            style: GoogleFonts.inter(
                fontSize: 12, color: color ?? AppColors.textSecondary)),
      ],
    );
  }
}
