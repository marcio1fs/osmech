import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Tela do segundo fator (Fase 4): código de 6 dígitos enviado por e-mail.
/// Exibida pelo _AuthGate quando auth.requer2fa == true.
class DoisFaPage extends StatefulWidget {
  const DoisFaPage({super.key});

  @override
  State<DoisFaPage> createState() => _DoisFaPageState();
}

class _DoisFaPageState extends State<DoisFaPage> {
  final _codigoCtrl = TextEditingController();
  bool _enviando = false;
  bool _reenviando = false;
  String? _erro;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _verificar() async {
    final codigo = _codigoCtrl.text.trim();
    if (codigo.length != 6) {
      setState(() => _erro = 'Digite o código de 6 dígitos');
      return;
    }
    setState(() {
      _enviando = true;
      _erro = null;
    });
    final erro =
        await context.read<AuthService>().verificar2fa(codigo);
    if (mounted) {
      setState(() {
        _enviando = false;
        _erro = erro;
      });
    }
  }

  Future<void> _reenviar() async {
    setState(() => _reenviando = true);
    final erro = await context.read<AuthService>().reenviar2fa();
    if (!mounted) return;
    setState(() => _reenviando = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(erro ?? 'Novo código enviado!'),
      backgroundColor: erro == null ? AppColors.success : AppColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthService>().email2fa ?? 'seu e-mail';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.shield_rounded,
                      size: 56, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text('Verificação em duas etapas',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    'Enviamos um código de 6 dígitos para $email.\nEle expira em 10 minutos.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _codigoCtrl,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 8),
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '------',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _enviando ? null : _verificar(),
                  ),
                  if (_erro != null) ...[
                    const SizedBox(height: 12),
                    Text(_erro!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            color: AppColors.error, fontSize: 13)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _enviando ? null : _verificar,
                      child: _enviando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Verificar e entrar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _reenviando ? null : _reenviar,
                    child: Text(_reenviando
                        ? 'Reenviando...'
                        : 'Reenviar código'),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.read<AuthService>().cancelar2fa(),
                    child: Text(
                      'Voltar ao login',
                      style:
                          GoogleFonts.inter(color: AppColors.textSecondary),
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
