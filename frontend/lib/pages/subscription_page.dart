import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; // Requer: flutter pub add url_launcher
import '../services/payment_service.dart';
import '../theme/app_theme.dart';
import '../mixins/auth_error_mixin.dart';
import '../utils/formatters.dart';

/// Tela de assinatura — design moderno.
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage>
    with AuthErrorMixin {
  Map<String, dynamic>? _assinatura;
  bool _loading = true;
  String? _error;
  bool _processingPayment = false;

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
      final service = PaymentService(token: safeToken);
      final data = await service.getAssinaturaAtiva();
      setState(() {
        _assinatura = data;
        _loading = false;
      });
    } catch (e) {
      if (!handleAuthError(e)) {
        setState(() {
          _error = 'Erro ao carregar assinatura';
          _loading = false;
        });
      }
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
      final service = PaymentService(token: safeToken);
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
      if (!handleAuthError(e) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  /// Inicia o fluxo de pagamento no Mercado Pago
  Future<void> _assinarPlano(String planoCodigo) async {
    if (planoCodigo == 'FREE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'O plano Gratuito nao usa checkout. Para voltar ao FREE, cancele a assinatura atual.'),
        ),
      );
      return;
    }

    setState(() => _processingPayment = true);

    try {
      final service = PaymentService(token: safeToken);
      final assinatura = await service.iniciarAssinatura(
        planoCodigo: planoCodigo,
      );

      final checkoutUrl = assinatura.checkoutUrl;
      if (checkoutUrl.trim().isEmpty) {
        throw Exception('Link de pagamento não retornado pelo servidor.');
      }

      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Não foi possível abrir o link de pagamento.');
      }
    } catch (e) {
      if (!handleAuthError(e) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _processingPayment = false);
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
                            const Icon(Icons.error_outline_rounded,
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
                                      '${formatCurrency(_assinatura?['valorMensal'] ?? 0)}/mês',
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
                                          value: formatDateBR(
                                              _assinatura!['dataInicio'])),
                                    if (_assinatura?['proximaCobranca'] != null)
                                      _DetailItem(
                                          icon: Icons.event_rounded,
                                          label: 'Próxima cobrança',
                                          value: formatDateBR(
                                              _assinatura!['proximaCobranca'])),
                                    if (_assinatura?['dataCancelamento'] !=
                                        null)
                                      _DetailItem(
                                          icon: Icons.cancel_rounded,
                                          label: 'Cancelado em',
                                          value: formatDateBR(_assinatura![
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
                                    color: AppColors.warning
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.warning
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning_amber_rounded,
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

                              const SizedBox(height: 40),
                              const Divider(),
                              const SizedBox(height: 24),

                              Text('Planos Disponíveis',
                                  style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 16),
                              _buildPlansList(),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansList() {
    // Lista mockada de planos (idealmente viria da API /planos)
    final planos = [
      {
        'codigo': 'FREE',
        'nome': 'Gratuito',
        'preco': 0.00,
        'recursos': ['Até 10 OS/mês', 'Ideal para começar']
      },
      {
        'codigo': 'PRO',
        'nome': 'Profissional',
        'preco': 49.90,
        'recursos': ['Até 30 OS/mês', 'Financeiro Completo', 'Estoque']
      },
      {
        'codigo': 'PRO_PLUS',
        'nome': 'PRO+',
        'preco': 79.90,
        'recursos': ['Até 80 OS/mês', 'WhatsApp automático', 'IA (Básico)']
      },
      {
        'codigo': 'PREMIUM',
        'nome': 'Premium',
        'preco': 149.90,
        'recursos': ['Tudo do PRO+', 'OS ilimitadas', 'IA (Avançado)']
      },
    ];

    return Column(
      children: planos.map((plano) {
        final isCurrent = _assinatura?['planoCodigo'] == plano['codigo'] &&
            _assinatura?['status'] == 'ACTIVE';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isCurrent ? AppColors.success : AppColors.border,
                width: isCurrent ? 2 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plano['nome'] as String,
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(formatCurrency(plano['preco']),
                        style: GoogleFonts.inter(
                            fontSize: 14, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (isCurrent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Atual',
                      style: GoogleFonts.inter(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                )
              else
                FilledButton(
                  onPressed: _processingPayment || plano['codigo'] == 'FREE'
                      ? null
                      : () => _assinarPlano(plano['codigo'] as String),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                  child: _processingPayment
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          plano['codigo'] == 'FREE' ? 'Plano base' : 'Assinar'),
                ),
            ],
          ),
        );
      }).toList(),
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
