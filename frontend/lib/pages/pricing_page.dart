import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_config.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Tela de Planos — design moderno com grid de pricing cards.
class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  List<dynamic> _planos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlanos();
  }

  Future<void> _loadPlanos() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/planos'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: ApiConfig.timeoutSeconds));
      if (response.statusCode == 200) {
        setState(() {
          _planos = jsonDecode(response.body);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Erro ao carregar planos';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro de conexão';
        _loading = false;
      });
    }
  }

  Color _planColor(String codigo) {
    switch (codigo) {
      case 'FREE':
        return const Color(0xFF10B981);
      case 'PRO':
        return const Color(0xFF3B82F6);
      case 'PRO_PLUS':
        return const Color(0xFF8B5CF6);
      case 'PREMIUM':
        return const Color(0xFFF59E0B);
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _planIcon(String codigo) {
    switch (codigo) {
      case 'FREE':
        return Icons.rocket_launch_rounded;
      case 'PRO':
        return Icons.star_outline_rounded;
      case 'PRO_PLUS':
        return Icons.star_half_rounded;
      case 'PREMIUM':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.card_membership_rounded;
    }
  }

  bool _isRecommended(String codigo) => codigo == 'PRO';

  Future<void> _assinarPlano(String codigo) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para assinar um plano')),
      );
      return;
    }

    if (codigo == 'FREE') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'O plano Gratuito nao precisa de pagamento. Ele ja e o plano base da conta.'),
          ),
        );
      }
      return;
    }

    try {
      final service = PaymentService(token: auth.token!);
      final result = await service.iniciarAssinatura(
        planoCodigo: codigo,
      );
      final checkoutUrl = result.checkoutUrl.trim();

      if (checkoutUrl.isEmpty) {
        throw Exception('Checkout não disponível para este plano.');
      }

      final uri = Uri.tryParse(checkoutUrl);
      if (uri == null) {
        throw Exception('URL de checkout inválida.');
      }

      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Não foi possível abrir o checkout do Mercado Pago.');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Redirecionando para o pagamento do plano $codigo...'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao assinar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
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
                    Text(
                      'Planos',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Escolha o melhor plano para sua oficina',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _loadPlanos,
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
                    child: CircularProgressIndicator(color: AppColors.accent),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _loadPlanos,
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth > 1100
                                ? 4
                                : constraints.maxWidth > 700
                                    ? 2
                                    : 1;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                childAspectRatio: 0.78, // Correção de Layout
                              ),
                              itemCount: _planos.length,
                              itemBuilder: (context, index) {
                                final plano = _planos[index];
                                final codigo = plano['codigo'] ?? '';
                                final color = _planColor(codigo);
                                final recommended = _isRecommended(codigo);

                                return Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: recommended
                                          ? color
                                          : AppColors.border,
                                      width: recommended ? 2 : 1,
                                    ),
                                    boxShadow: recommended
                                        ? [
                                            BoxShadow(
                                              color:
                                                  color.withValues(alpha: 0.1),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    children: [
                                      // Recommended badge
                                      if (recommended)
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color,
                                            borderRadius:
                                                const BorderRadius.vertical(
                                              top: Radius.circular(14),
                                            ),
                                          ),
                                          child: Text(
                                            'RECOMENDADO',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ),

                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: SingleChildScrollView(
                                            child: Column(
                                              children: [
                                                Container(
                                                  width: 52,
                                                  height: 52,
                                                  decoration: BoxDecoration(
                                                    color: color.withValues(
                                                      alpha: 0.1,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(14),
                                                  ),
                                                  child: Icon(
                                                    _planIcon(codigo),
                                                    color: color,
                                                    size: 26,
                                                  ),
                                                ),
                                                const SizedBox(height: 14),
                                                Text(
                                                  plano['nome'] ?? '',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                RichText(
                                                  text: TextSpan(
                                                    children: [
                                                      TextSpan(
                                                        text: formatCurrency(
                                                          plano['preco'] ?? 0,
                                                        ),
                                                        style: GoogleFonts.inter(
                                                          fontSize: 28,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: AppColors
                                                              .textPrimary,
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text: '/mês',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 14,
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  plano['descricao'] ?? '',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.textSecondary,
                                                    height: 1.4,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                const Divider(
                                                  color: AppColors.border,
                                                ),
                                                const SizedBox(height: 12),
                                                _FeatureItem(
                                                  label: 'OS por mês',
                                                  value: plano['limiteOs'] == 0
                                                      ? 'Ilimitado'
                                                      : '${plano['limiteOs']}',
                                                ),
                                                _FeatureItem(
                                                  label: 'WhatsApp',
                                                  value:
                                                      plano['whatsappHabilitado'] ==
                                                              true
                                                          ? 'Sim'
                                                          : 'Não',
                                                  enabled: plano[
                                                          'whatsappHabilitado'] ==
                                                      true,
                                                ),
                                                _FeatureItem(
                                                  label: 'IA',
                                                  value: plano['iaHabilitada'] ==
                                                          true
                                                      ? 'Sim'
                                                      : 'Não',
                                                  enabled:
                                                      plano['iaHabilitada'] ==
                                                          true,
                                                ),
                                                const SizedBox(height: 20), // Spacer replacement
                                                SizedBox(
                                                  width: double.infinity,
                                                  height: 44,
                                                  child: recommended
                                                      ? FilledButton(
                                                          onPressed: codigo ==
                                                                  'FREE'
                                                              ? null
                                                              : () =>
                                                                  _assinarPlano(
                                                                      codigo),
                                                          style: FilledButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                color,
                                                          ),
                                                          child: Text(
                                                            codigo == 'FREE'
                                                                ? 'Plano base'
                                                                : 'Assinar',
                                                            style:
                                                                GoogleFonts.inter(
                                                              fontWeight:
                                                                  FontWeight.w600,
                                                            ),
                                                          ),
                                                        )
                                                      : OutlinedButton(
                                                          onPressed: codigo ==
                                                                  'FREE'
                                                              ? null
                                                              : () =>
                                                                  _assinarPlano(
                                                                      codigo),
                                                          child: Text(
                                                            codigo == 'FREE'
                                                                ? 'Plano base'
                                                                : 'Assinar',
                                                            style:
                                                                GoogleFonts.inter(
                                                              fontWeight:
                                                                  FontWeight.w600,
                                                              ),
                                                          ),
                                                        ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String label;
  final String value;
  final bool enabled;
  const _FeatureItem({
    required this.label,
    required this.value,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: enabled ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
