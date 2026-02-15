import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';

/// Tela de assinatura — design moderno.
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  Map<String, dynamic>? _assinatura;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssinatura();
  }

  Future<void> _loadAssinatura() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = PaymentService(token: auth.token!);
      final data = await service.getAssinaturaAtiva();
      setState(() {
        _assinatura = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar assinatura';
        _loading = false;
      });
    }
  }

  Future<void> _cancelarAssinatura() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancelar Assinatura',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Tem certeza que deseja cancelar sua assinatura? Você perderá acesso aos recursos do plano atual.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Manter')),
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
      await service.cancelarAssinatura();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Assinatura cancelada com sucesso'),
              backgroundColor: AppColors.success),
        );
        _loadAssinatura();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: AppColors.error),
        );
      }
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
      case 'CANCELED':
        return AppColors.textMuted;
      default:
        return AppColors.accent;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'ACTIVE':
        return 'Ativa';
      case 'PAST_DUE':
        return 'Pagamento Atrasado';
      case 'SUSPENDED':
        return 'Suspensa';
      case 'CANCELED':
        return 'Cancelada';
      default:
        return 'Sem assinatura';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final parts = dateStr.split('-');
      return '${parts[2]}/${parts[1]}/${parts[0]}';
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
                    Text('Minha Assinatura',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text('Gerencie seu plano e pagamentos',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _loadAssinatura,
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
                                onPressed: _loadAssinatura,
                                child: const Text('Tentar novamente')),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color:
                                            _statusColor(_assinatura?['status'])
                                                .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(Icons.card_membership_rounded,
                                          size: 32,
                                          color: _statusColor(
                                              _assinatura?['status'])),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _assinatura?['planoNome'] ?? 'Sem plano',
                                      style: GoogleFonts.inter(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        color:
                                            _statusColor(_assinatura?['status'])
                                                .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _statusLabel(_assinatura?['status']),
                                        style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _statusColor(
                                                _assinatura?['status'])),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'R\$ ${(_assinatura?['valorMensal'] ?? 0).toStringAsFixed(2)}/mês',
                                      style: GoogleFonts.inter(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Details card
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
                                    Text('Detalhes',
                                        style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary)),
                                    const SizedBox(height: 16),
                                    if (_assinatura?['dataInicio'] != null)
                                      _DetailItem(
                                          icon: Icons.calendar_today_rounded,
                                          label: 'Início',
                                          value: _formatDate(
                                              _assinatura!['dataInicio'])),
                                    if (_assinatura?['proximaCobranca'] != null)
                                      _DetailItem(
                                          icon: Icons.event_rounded,
                                          label: 'Próxima cobrança',
                                          value: _formatDate(
                                              _assinatura!['proximaCobranca'])),
                                    if (_assinatura?['dataCancelamento'] !=
                                        null)
                                      _DetailItem(
                                          icon: Icons.cancel_rounded,
                                          label: 'Cancelado em',
                                          value: _formatDate(_assinatura![
                                              'dataCancelamento'])),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Warning
                              if (_assinatura?['status'] == 'PAST_DUE' ||
                                  _assinatura?['status'] == 'SUSPENDED')
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color:
                                            AppColors.warning.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded,
                                          color: AppColors.warning),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _assinatura?['status'] == 'PAST_DUE'
                                              ? 'Seu pagamento está atrasado. Regularize para evitar a suspensão.'
                                              : 'Sua conta está suspensa por inadimplência.',
                                          style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: AppColors.textPrimary,
                                              height: 1.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Cancel button
                              if (_assinatura?['status'] == 'ACTIVE' ||
                                  _assinatura?['status'] == 'PAST_DUE') ...[
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    onPressed: _cancelarAssinatura,
                                    icon: const Icon(Icons.cancel_outlined,
                                        color: AppColors.error, size: 18),
                                    label: Text('Cancelar Assinatura',
                                        style: GoogleFonts.inter(
                                            color: AppColors.error,
                                            fontWeight: FontWeight.w600)),
                                    style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: AppColors.error)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailItem(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text('$label:',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
