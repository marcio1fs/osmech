import 'package:flutter/material.dart';
import 'package:provider/provider.dart' show Provider;
import '../mixins/auth_error_mixin.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';

class CheckoutReturnPage extends StatefulWidget {
  final String result;

  const CheckoutReturnPage({super.key, required this.result});

  @override
  State<CheckoutReturnPage> createState() => _CheckoutReturnPageState();
}

class _CheckoutReturnPageState extends State<CheckoutReturnPage>
    with AuthErrorMixin {
  bool _loading = true;
  String? _assinaturaStatus;
  String? _error;

  @override
  void initState() {
    super.initState();
    _syncAssinatura();
  }

  Future<void> _syncAssinatura() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (!auth.isAuthenticated || auth.token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final service = PaymentService(token: auth.token!);
      for (var i = 0; i < 3; i++) {
        final assinatura = await service.getAssinaturaAtiva();
        _assinaturaStatus = assinatura['status']?.toString();
        if (_assinaturaStatus == 'ACTIVE') {
          break;
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    } catch (e) {
      if (!handleAuthError(e)) {
        _error = 'Nao foi possivel atualizar o status da assinatura.';
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Color _resultColor() {
    switch (widget.result) {
      case 'sucesso':
        return AppColors.success;
      case 'pendente':
        return AppColors.warning;
      case 'falha':
        return AppColors.error;
      default:
        return AppColors.accent;
    }
  }

  IconData _resultIcon() {
    switch (widget.result) {
      case 'sucesso':
        return Icons.check_circle_rounded;
      case 'pendente':
        return Icons.hourglass_top_rounded;
      case 'falha':
        return Icons.error_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _resultTitle() {
    switch (widget.result) {
      case 'sucesso':
        return 'Pagamento aprovado';
      case 'pendente':
        return 'Pagamento pendente';
      case 'falha':
        return 'Pagamento nao aprovado';
      default:
        return 'Retorno do pagamento';
    }
  }

  String _resultDescription() {
    if (_error != null) {
      return _error!;
    }
    if (_assinaturaStatus == 'ACTIVE') {
      return 'Assinatura ativa confirmada.';
    }
    switch (widget.result) {
      case 'sucesso':
        return 'Estamos confirmando os dados do pagamento.';
      case 'pendente':
        return 'Seu pagamento ainda esta em analise no Mercado Pago.';
      case 'falha':
        return 'Voce pode tentar novamente escolhendo outro meio de pagamento.';
      default:
        return 'Confira o status da assinatura para continuar.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: CircularProgressIndicator(color: AppColors.accent),
                    )
                  else
                    Icon(_resultIcon(), size: 56, color: _resultColor()),
                  const SizedBox(height: 12),
                  Text(
                    _resultTitle(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _resultDescription(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const AppShell(initialIndex: 4),
                          ),
                        );
                      },
                      child: const Text('Ir para Assinatura'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
