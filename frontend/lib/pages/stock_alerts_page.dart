import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../mixins/auth_error_mixin.dart';
import '../services/auth_service.dart';
import '../services/stock_service.dart';
import '../theme/app_theme.dart';

/// Tela de alertas de estoque (itens críticos e com estoque baixo).
class StockAlertsPage extends StatefulWidget {
  final Function(int)? onEntradaEstoque;

  const StockAlertsPage({super.key, this.onEntradaEstoque});

  @override
  State<StockAlertsPage> createState() => _StockAlertsPageState();
}

class _StockAlertsPageState extends State<StockAlertsPage> with AuthErrorMixin {
  List<Map<String, dynamic>> _alertas = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlertas();
  }

  Future<void> _loadAlertas() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = StockService(token: auth.token!);
      final data = await service.getAlertas();
      setState(() {
        _alertas = data;
        _loading = false;
      });
    } catch (e) {
      if (!handleAuthError(e)) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final criticos = _alertas.where((a) => a['nivel'] == 'CRITICO').toList();
    final avisos = _alertas.where((a) => a['nivel'] == 'ALERTA').toList();

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
                Text('Alertas de Estoque',
                    style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _loadAlertas,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Atualizar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
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
                                size: 64, color: AppColors.error),
                            const SizedBox(height: 12),
                            Text('Erro ao carregar alertas',
                                style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text(_error!,
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: AppColors.textMuted)),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _loadAlertas,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Tentar novamente'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _alertas.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline_rounded,
                                    size: 64, color: AppColors.success),
                                const SizedBox(height: 12),
                                Text('Estoque está em dia!',
                                    style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                Text('Nenhum alerta encontrado',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.textMuted)),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Summary cards
                                Row(
                                  children: [
                                    _SummaryCard(
                                      icon: Icons.error_rounded,
                                      label: 'Críticos',
                                      count: criticos.length,
                                      color: AppColors.error,
                                    ),
                                    const SizedBox(width: 16),
                                    _SummaryCard(
                                      icon: Icons.warning_rounded,
                                      label: 'Alertas',
                                      count: avisos.length,
                                      color: AppColors.warning,
                                    ),
                                    const SizedBox(width: 16),
                                    _SummaryCard(
                                      icon: Icons.inventory_2_rounded,
                                      label: 'Total itens',
                                      count: _alertas.length,
                                      color: AppColors.accent,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 28),

                                // Críticos
                                if (criticos.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      const Icon(Icons.error_rounded,
                                          size: 20, color: AppColors.error),
                                      const SizedBox(width: 8),
                                      Text('Estoque Zerado (Crítico)',
                                          style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.error)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ...criticos.map((a) => _AlertaCard(
                                        alerta: a,
                                        onEntrada: () => widget.onEntradaEstoque
                                            ?.call(a['id'] as int),
                                      )),
                                  const SizedBox(height: 24),
                                ],

                                // Alertas
                                if (avisos.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      const Icon(Icons.warning_rounded,
                                          size: 20, color: AppColors.warning),
                                      const SizedBox(width: 8),
                                      Text('Estoque Baixo (Alerta)',
                                          style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.warning)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ...avisos.map((a) => _AlertaCard(
                                        alerta: a,
                                        onEntrada: () => widget.onEntradaEstoque
                                            ?.call(a['id'] as int),
                                      )),
                                ],
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count',
                    style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: color)),
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertaCard extends StatelessWidget {
  final Map<String, dynamic> alerta;
  final VoidCallback? onEntrada;

  const _AlertaCard({required this.alerta, this.onEntrada});

  @override
  Widget build(BuildContext context) {
    final isCritico = alerta['nivel'] == 'CRITICO';
    final borderColor = isCritico
        ? AppColors.error.withValues(alpha: 0.4)
        : AppColors.warning.withValues(alpha: 0.4);
    final bgColor = isCritico
        ? AppColors.error.withValues(alpha: 0.03)
        : AppColors.warning.withValues(alpha: 0.03);
    final iconColor = isCritico ? AppColors.error : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            isCritico ? Icons.error_rounded : Icons.warning_rounded,
            size: 22,
            color: iconColor,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${alerta['codigo']}',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(alerta['categoria'] ?? '',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: iconColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${alerta['nome']}',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(alerta['mensagem'] ?? '',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Text('Atual',
                  style: GoogleFonts.inter(
                      fontSize: 10, color: AppColors.textMuted)),
              Text('${alerta['quantidade']}',
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: iconColor)),
              Text('Mín: ${alerta['quantidadeMinima']}',
                  style: GoogleFonts.inter(
                      fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: onEntrada,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text('Dar entrada', style: GoogleFonts.inter(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.success,
              side: const BorderSide(color: AppColors.success),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
