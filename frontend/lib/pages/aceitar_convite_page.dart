import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/equipe_service.dart';
import '../theme/app_theme.dart';

/// Tela PÚBLICA de aceite de convite (/aceitar-convite?token=...).
/// Lê o token da URL, valida no backend, cria a conta e faz auto-login.
class AceitarConvitePage extends StatefulWidget {
  const AceitarConvitePage({super.key});

  @override
  State<AceitarConvitePage> createState() => _AceitarConvitePageState();
}

class _AceitarConvitePageState extends State<AceitarConvitePage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmaCtrl = TextEditingController();

  String _token = '';
  bool _carregandoInfo = true;
  bool _enviando = false;
  bool _sucesso = false;
  String? _erroInfo;
  Map<String, dynamic>? _info;

  static const _papelLabel = {
    'GERENTE': 'Gerente',
    'ATENDENTE': 'Atendente',
    'MECANICO': 'Mecânico',
    'DONO': 'Dono',
  };

  @override
  void initState() {
    super.initState();
    _token = _extrairToken();
    if (_token.isEmpty) {
      _carregandoInfo = false;
      _erroInfo = 'Link de convite inválido (token ausente).';
    } else {
      _carregarInfo();
    }
  }

  /// Aceita token tanto em /aceitar-convite?token=X quanto em
  /// /#/aceitar-convite?token=X (hash strategy).
  String _extrairToken() {
    final base = Uri.base;
    final direto = base.queryParameters['token'];
    if (direto != null && direto.isNotEmpty) return direto;
    final frag = base.fragment;
    final q = frag.indexOf('?');
    if (q >= 0 && q + 1 < frag.length) {
      final params =
          Uri.parse('http://placeholder/?${frag.substring(q + 1)}')
              .queryParameters;
      return params['token'] ?? '';
    }
    return '';
  }

  Future<void> _carregarInfo() async {
    try {
      final dados = await ConvitePublicoService().info(_token);
      if (mounted) {
        setState(() {
          _info = dados;
          _carregandoInfo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erroInfo = e.toString().replaceFirst('Exception: ', '');
          _carregandoInfo = false;
        });
      }
    }
  }

  Future<void> _aceitar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _enviando = true);
    try {
      final resp = await ConvitePublicoService().aceitar(
        token: _token,
        nome: _nomeCtrl.text,
        telefone: _telefoneCtrl.text,
        senha: _senhaCtrl.text,
      );
      if (!mounted) return;
      await context.read<AuthService>().aplicarAutenticacao(
            token: resp['token'] as String,
            email: resp['email'] as String?,
            nome: resp['nome'] as String?,
            role: resp['role'] as String?,
            plano: resp['plano'] as String?,
          );
      if (mounted) {
        setState(() {
          _sucesso = true;
          _enviando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: _buildConteudo(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConteudo() {
    if (_carregandoInfo) {
      return const SizedBox(
          height: 200, child: Center(child: CircularProgressIndicator()));
    }

    if (_sucesso) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded,
              size: 64, color: AppColors.success),
          const SizedBox(height: 16),
          Text('Bem-vindo(a) à equipe!',
              style: GoogleFonts.inter(
                  fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Sua conta foi criada e você já está conectado(a).',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () =>
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false),
              child: const Text('Entrar no OSMECH'),
            ),
          ),
        ],
      );
    }

    if (_erroInfo != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Convite indisponível',
              style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(_erroInfo!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (_) => false),
            child: const Text('Voltar para o início'),
          ),
        ],
      );
    }

    final oficina = _info?['nomeOficina'] ?? '';
    final papel = _papelLabel[_info?['papel']] ?? _info?['papel'] ?? '';
    final email = _info?['email'] ?? '';

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.handshake_rounded, size: 56, color: AppColors.primary),
          const SizedBox(height: 16),
          Text('Você foi convidado!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            '$oficina convidou você para ser $papel no OSMECH.\nComplete seu cadastro para entrar:',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          TextFormField(
            initialValue: email,
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'E-mail convidado',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nomeCtrl,
            decoration: const InputDecoration(
              labelText: 'Seu nome',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) =>
                (v == null || v.trim().length < 2) ? 'Informe seu nome' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _telefoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telefone (com DDD)',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: (v) => (v == null || v.trim().length < 10)
                ? 'Informe um telefone válido'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _senhaCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Crie uma senha',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? 'Mínimo de 6 caracteres' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmaCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirmar senha',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (v) =>
                v != _senhaCtrl.text ? 'As senhas não conferem' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _enviando ? null : _aceitar,
              child: _enviando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Aceitar convite e entrar'),
            ),
          ),
        ],
      ),
    );
  }
}
