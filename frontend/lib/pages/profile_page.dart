import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../mixins/auth_error_mixin.dart';
import '../services/api_config.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/upper_text.dart';
import '../utils/logo_picker.dart';

/// Página de perfil do usuário — exibe e permite editar dados pessoais e senha.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with AuthErrorMixin {
  // Form keys
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  // Perfil
  final _nomeCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _oficinaCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();
  final _logradouroCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _complementoCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();
  final _siteCtrl = TextEditingController();
  String _email = '';
  String _plano = '';
  String _role = '';
  String _criadoEm = '';
  String? _logoUrl;

  // Senha
  final _senhaAtualCtrl = TextEditingController();
  final _novaSenhaCtrl = TextEditingController();
  final _confirmaSenhaCtrl = TextEditingController();

  bool _loading = true;
  bool _savingProfile = false;
  bool _savingPassword = false;
  bool _doisFaAtivo = false;
  bool _salvando2fa = false;
  bool _carregandoSessoes = true;
  List<Map<String, dynamic>> _sessoes = [];
  bool _showSenhaAtual = false;
  bool _showNovaSenha = false;
  bool _applyingMask = false;
  bool _uploadingLogo = false;

  @override
  void initState() {
    super.initState();
    _cnpjCtrl.addListener(_onCnpjChanged);
    _cepCtrl.addListener(_onCepChanged);
    _loadProfile();
    _carregarSessoes();
  }

  /// Carrega a lista de sessões ativas (segurança da conta).
  Future<void> _carregarSessoes() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = UserService(token: safeToken);
      final lista =
          await service.listarSessoes(refreshToken: auth.refreshToken);
      if (mounted) {
        setState(() {
          _sessoes = lista;
          _carregandoSessoes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _carregandoSessoes = false);
    }
  }

  String _digitsOnly(String raw) => raw.replaceAll(RegExp(r'[^0-9]'), '');

  void _setMaskedText(TextEditingController controller, String value) {
    _applyingMask = true;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _applyingMask = false;
  }

  String _formatCnpj(String value) {
    final digits = _digitsOnly(value);
    if (digits.isEmpty) return '';
    final d = digits.length > 14 ? digits.substring(0, 14) : digits;
    if (d.length <= 2) return d;
    if (d.length <= 5) return '${d.substring(0, 2)}.${d.substring(2)}';
    if (d.length <= 8)
      return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5)}';
    if (d.length <= 12) {
      return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5, 8)}/${d.substring(8)}';
    }
    return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5, 8)}/${d.substring(8, 12)}-${d.substring(12)}';
  }

  String _formatCep(String value) {
    final digits = _digitsOnly(value);
    if (digits.isEmpty) return '';
    final d = digits.length > 8 ? digits.substring(0, 8) : digits;
    if (d.length <= 5) return d;
    return '${d.substring(0, 5)}-${d.substring(5)}';
  }

  void _onCnpjChanged() {
    if (_applyingMask) return;
    final masked = _formatCnpj(_cnpjCtrl.text);
    if (_cnpjCtrl.text != masked) {
      _setMaskedText(_cnpjCtrl, masked);
    }
  }

  void _onCepChanged() {
    if (_applyingMask) return;
    final masked = _formatCep(_cepCtrl.text);
    if (_cepCtrl.text != masked) {
      _setMaskedText(_cepCtrl, masked);
    }
  }

  bool _isValidCnpj(String cnpj) {
    final digits = _digitsOnly(cnpj);
    if (digits.length != 14) return false;
    if (RegExp(r'^(\d)\1{13}$').hasMatch(digits)) return false;

    int calcDigit(String base, List<int> weights) {
      int sum = 0;
      for (int i = 0; i < weights.length; i++) {
        sum += int.parse(base[i]) * weights[i];
      }
      final mod = sum % 11;
      return mod < 2 ? 0 : 11 - mod;
    }

    final d1 = calcDigit(
        digits.substring(0, 12), [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]);
    final d2 = calcDigit(
        digits.substring(0, 13), [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]);
    return digits[12] == d1.toString() && digits[13] == d2.toString();
  }

  @override
  void dispose() {
    _cnpjCtrl.removeListener(_onCnpjChanged);
    _cepCtrl.removeListener(_onCepChanged);
    _nomeCtrl.dispose();
    _telefoneCtrl.dispose();
    _oficinaCtrl.dispose();
    _cnpjCtrl.dispose();
    _logradouroCtrl.dispose();
    _numeroCtrl.dispose();
    _complementoCtrl.dispose();
    _bairroCtrl.dispose();
    _cidadeCtrl.dispose();
    _estadoCtrl.dispose();
    _cepCtrl.dispose();
    _siteCtrl.dispose();
    _senhaAtualCtrl.dispose();
    _novaSenhaCtrl.dispose();
    _confirmaSenhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final service = UserService(token: safeToken);
      final perfil = await service.getPerfil();
      setState(() {
        _nomeCtrl.text = perfil['nome'] ?? '';
        _telefoneCtrl.text = perfil['telefone'] ?? '';
        _oficinaCtrl.text = perfil['nomeOficina'] ?? '';
        _cnpjCtrl.text = perfil['cnpjOficina'] ?? '';
        _logradouroCtrl.text = perfil['enderecoLogradouro'] ?? '';
        _numeroCtrl.text = perfil['enderecoNumero'] ?? '';
        _complementoCtrl.text = perfil['enderecoComplemento'] ?? '';
        _bairroCtrl.text = perfil['enderecoBairro'] ?? '';
        _cidadeCtrl.text = perfil['enderecoCidade'] ?? '';
        _estadoCtrl.text =
            (perfil['enderecoEstado'] ?? '').toString().toUpperCase();
        _cepCtrl.text = perfil['enderecoCep'] ?? '';
        _siteCtrl.text = perfil['siteOficina'] ?? '';
        _email = perfil['email'] ?? '';
        _plano = perfil['plano'] ?? 'FREE';
        _role = perfil['role'] ?? 'USER';
        _criadoEm = perfil['criadoEm'] != null
            ? perfil['criadoEm'].toString().substring(0, 10)
            : '';
        _logoUrl = perfil['logoUrl'];
        _doisFaAtivo = perfil['doisFaAtivo'] == true;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (handleAuthError(e)) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              UpperText('Erro ao carregar perfil: $e', style: GoogleFonts.inter()),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _salvarPerfil() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _savingProfile = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = UserService(token: safeToken);
      await service.atualizarPerfil(
        nome: _nomeCtrl.text.trim(),
        telefone: _telefoneCtrl.text.trim().isEmpty
            ? null
            : _telefoneCtrl.text.trim(),
        nomeOficina:
            _oficinaCtrl.text.trim().isEmpty ? null : _oficinaCtrl.text.trim(),
        cnpjOficina:
            _cnpjCtrl.text.trim().isEmpty ? null : _digitsOnly(_cnpjCtrl.text),
        enderecoLogradouro: _logradouroCtrl.text.trim().isEmpty
            ? null
            : _logradouroCtrl.text.trim(),
        enderecoNumero:
            _numeroCtrl.text.trim().isEmpty ? null : _numeroCtrl.text.trim(),
        enderecoComplemento: _complementoCtrl.text.trim().isEmpty
            ? null
            : _complementoCtrl.text.trim(),
        enderecoBairro:
            _bairroCtrl.text.trim().isEmpty ? null : _bairroCtrl.text.trim(),
        enderecoCidade:
            _cidadeCtrl.text.trim().isEmpty ? null : _cidadeCtrl.text.trim(),
        enderecoEstado: _estadoCtrl.text.trim().isEmpty
            ? null
            : _estadoCtrl.text.trim().toUpperCase(),
        enderecoCep: _cepCtrl.text.trim().isEmpty ? null : _cepCtrl.text.trim(),
        siteOficina:
            _siteCtrl.text.trim().isEmpty ? null : _siteCtrl.text.trim(),
      );
      // Sincronizar nome no AuthService para atualizar sidebar
      await auth.updateNome(_nomeCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: UpperText('Perfil atualizado com sucesso!',
              style: GoogleFonts.inter()),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (!handleAuthError(e) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: UpperText('$e', style: GoogleFonts.inter()),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _alterarSenha() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _savingPassword = true);
    try {
      final service = UserService(token: safeToken);
      await service.alterarSenha(
        senhaAtual: _senhaAtualCtrl.text,
        novaSenha: _novaSenhaCtrl.text,
      );
      _senhaAtualCtrl.clear();
      _novaSenhaCtrl.clear();
      _confirmaSenhaCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              UpperText('Senha alterada com sucesso!', style: GoogleFonts.inter()),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (handleAuthError(e)) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: UpperText('$e', style: GoogleFonts.inter()),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _uploadLogo() async {
    final picked = await pickLogoImage();
    if (picked == null) return;

    setState(() => _uploadingLogo = true);
    try {
      final service = UserService(token: safeToken);
      final newUrl = await service.uploadLogo(picked.bytes, picked.filename);
      setState(() {
        _logoUrl = newUrl;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: UpperText('Logo atualizada com sucesso!', style: GoogleFonts.inter()),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (handleAuthError(e)) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: UpperText('$e', style: GoogleFonts.inter()),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    InkWell(
                      onTap: _uploadLogo,
                      borderRadius: BorderRadius.circular(32),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                            backgroundImage: _logoUrl != null && _logoUrl!.isNotEmpty
                                ? NetworkImage(ApiConfig.absoluteUrl(_logoUrl!))
                                : null,
                            child: _logoUrl == null || _logoUrl!.isEmpty
                                ? UpperText(
                                    (_nomeCtrl.text.isNotEmpty ? _nomeCtrl.text[0] : 'U')
                                        .toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accent,
                                    ),
                                  )
                                : null,
                          ),
                          if (_uploadingLogo)
                            const CircularProgressIndicator(),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UpperText('Meu Perfil',
                              style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _badge(_plano, AppColors.accent),
                              _badge(_role, AppColors.textSecondary),
                              if (_criadoEm.isNotEmpty)
                                UpperText('Desde $_criadoEm',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Card: Dados Pessoais
                _buildCard(
                  title: 'Dados Pessoais',
                  icon: Icons.person_rounded,
                  formKey: _profileFormKey,
                  children: [
                    _inputField('Email', null,
                        initialValue: _email, readOnly: true),
                    const SizedBox(height: 16),
                    _inputField('Nome', _nomeCtrl,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Nome é obrigatório'
                            : null),
                    const SizedBox(height: 16),
                    _inputField('Telefone', _telefoneCtrl,
                        hint: '(11) 99999-9999'),
                    const SizedBox(height: 16),
                    _inputField('Nome da Oficina', _oficinaCtrl,
                        hint: 'Ex: Auto Mecânica Silva'),
                    const SizedBox(height: 16),
                    _inputField(
                      'CNPJ da Oficina',
                      _cnpjCtrl,
                      hint: '00.000.000/0000-00',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return null;
                        return _isValidCnpj(value) ? null : 'CNPJ inválido';
                      },
                    ),
                    const SizedBox(height: 16),
                    _inputField('Logradouro', _logradouroCtrl,
                        hint: 'Ex: Av. Brasil'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _inputField(
                            'Número',
                            _numeroCtrl,
                            hint: 'Ex: 123',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _inputField('Complemento', _complementoCtrl,
                              hint: 'Sala, bloco, referência'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _inputField('Bairro', _bairroCtrl,
                              hint: 'Ex: Centro'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _inputField('Cidade', _cidadeCtrl,
                              hint: 'Ex: São Paulo'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _inputField(
                            'UF',
                            _estadoCtrl,
                            hint: 'SP',
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(2),
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z]')),
                            ],
                            validator: (v) {
                              final value = (v ?? '').trim();
                              if (value.isEmpty) return null;
                              return value.length == 2
                                  ? null
                                  : 'Informe UF com 2 letras';
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _inputField(
                            'CEP',
                            _cepCtrl,
                            hint: '00000-000',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final value = (v ?? '').trim();
                              if (value.isEmpty) return null;
                              return _digitsOnly(value).length == 8
                                  ? null
                                  : 'CEP inválido';
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _inputField('Site da Oficina', _siteCtrl,
                        hint: 'https://suaoficina.com.br'),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _savingProfile ? null : _salvarPerfil,
                        icon: _savingProfile
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_rounded, size: 18),
                        label: UpperText(
                            _savingProfile ? 'Salvando...' : 'Salvar Perfil'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Card: Alterar Senha
                _buildCard(
                  title: 'Alterar Senha',
                  icon: Icons.lock_rounded,
                  formKey: _passwordFormKey,
                  children: [
                    _passwordField('Senha Atual', _senhaAtualCtrl,
                        show: _showSenhaAtual,
                        onToggle: () =>
                            setState(() => _showSenhaAtual = !_showSenhaAtual),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Senha atual é obrigatória'
                            : null),
                    const SizedBox(height: 16),
                    _passwordField('Nova Senha', _novaSenhaCtrl,
                        show: _showNovaSenha,
                        onToggle: () =>
                            setState(() => _showNovaSenha = !_showNovaSenha),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Nova senha é obrigatória';
                          }
                          if (v.length < 8) return 'Mínimo de 8 caracteres';
                          return null;
                        }),
                    const SizedBox(height: 16),
                    _passwordField('Confirmar Nova Senha', _confirmaSenhaCtrl,
                        show: _showNovaSenha, onToggle: null, validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Confirme a nova senha';
                      }
                      if (v != _novaSenhaCtrl.text) {
                        return 'As senhas não coincidem';
                      }
                      return null;
                    }),
                    const SizedBox(height: 8),
                    UpperText('Mínimo de 8 caracteres',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _savingPassword ? null : _alterarSenha,
                        icon: _savingPassword
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.key_rounded, size: 18),
                        label: UpperText(
                            _savingPassword ? 'Alterando...' : 'Alterar Senha'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Card: Verificação em duas etapas (Fase 4)
                _buildCard(
                  title: 'Verificação em Duas Etapas',
                  icon: Icons.shield_rounded,
                  children: [
                    Text(
                      'Ao entrar, além da senha, você precisará digitar um código de 6 dígitos que enviamos para o seu e-mail.',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _doisFaAtivo
                                ? Icons.verified_user_rounded
                                : Icons.gpp_maybe_rounded,
                            color: _doisFaAtivo
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _doisFaAtivo ? '2FA ATIVADO' : '2FA DESATIVADO',
                              style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                          _salvando2fa
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : Switch(
                                  value: _doisFaAtivo,
                                  onChanged: _salvando2fa
                                      ? null
                                      : (v) => _confirmar2fa(v),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.devices_rounded, size: 18),
                        label: UpperText('Sair de todos os dispositivos'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: const BorderSide(color: AppColors.warning),
                        ),
                        onPressed: _confirmarLogoutTodos,
                      ),
                    ),
                    const SizedBox(height: 20),
                    UpperText(
                      'Dispositivos conectados',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    if (_carregandoSessoes)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_sessoes.isEmpty)
                      Text('Nenhuma sessão ativa encontrada.',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textSecondary))
                    else
                      ..._sessoes.take(10).map(_tileSessao),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tileSessao(Map<String, dynamic> sessao) {
    final atual = sessao['atual'] == true;
    final ua = (sessao['userAgent'] ?? 'Dispositivo desconhecido').toString();
    final criado = (sessao['criadoEm'] ?? '').toString();
    final desde = criado.length >= 10 ? criado.substring(0, 10) : criado;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: atual ? AppColors.success : AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            atual ? Icons.smartphone_rounded : Icons.devices_other_rounded,
            size: 22,
            color: atual ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ua.length > 60 ? '${ua.substring(0, 60)}…' : ua,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text('Desde $desde',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (atual) _badge('Este dispositivo', AppColors.success),
        ],
      ),
    );
  }

  /// Encerra todas as sessões no backend e faz logout local (Fase 4).
  Future<void> _confirmarLogoutTodos() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: UpperText('Sair de todos os dispositivos?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Você (e todas as outras sessões da sua conta) será desconectado e precisará entrar de novo.',
          style:
              GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: const Text('Sair de tudo'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    try {
      final service = UserService(token: safeToken);
      await service.logoutTodasSessoes();
    } catch (_) {
      // Mesmo offline, faz logout local — o refresh expira sozinho
    }
    if (!mounted) return;
    await context.read<AuthService>().logout();
  }

  /// Pede a senha atual e liga/desliga o 2FA (Fase 4).
  Future<void> _confirmar2fa(bool ativar) async {
    final senhaCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: UpperText(
            ativar ? 'Ativar 2FA' : 'Desativar 2FA',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ativar
                  ? 'Para ativar, confirme sua senha atual. No próximo login você usará o código enviado por e-mail.'
                  : 'Para desativar, confirme sua senha atual. Suas outras sessões serão encerradas.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: senhaCtrl,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Senha atual',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ativar ? 'Ativar' : 'Desativar'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    setState(() => _salvando2fa = true);
    try {
      final service = UserService(token: safeToken);
      await service.alterar2fa(senha: senhaCtrl.text, ativar: ativar);
      if (!mounted) return;
      setState(() {
        _doisFaAtivo = ativar;
        _salvando2fa = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: UpperText(
            ativar
                ? 'Verificação em duas etapas ativada!'
                : 'Verificação em duas etapas desativada.',
            style: GoogleFonts.inter()),
        backgroundColor: AppColors.success,
      ));

      // Ao desativar, o backend encerrou as outras sessões — renova a própria
      if (!ativar) {
        await context.read<AuthService>().refreshSession();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando2fa = false);
      if (handleAuthError(e)) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: UpperText(
            e.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.inter()),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: UpperText(text,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    GlobalKey<FormState>? formKey,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.accent),
            const SizedBox(width: 8),
            UpperText(title,
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 20),
        ...children,
      ],
    );
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: formKey != null ? Form(key: formKey, child: content) : content,
    );
  }

  Widget _inputField(String label, TextEditingController? controller,
      {String? hint,
      String? initialValue,
      bool readOnly = false,
      TextInputType? keyboardType,
      List<TextInputFormatter>? inputFormatters,
      TextCapitalization textCapitalization = TextCapitalization.none,
      String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UpperText(label,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          readOnly: readOnly,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          validator: validator,
          style: GoogleFonts.inter(
              fontSize: 14,
              color:
                  readOnly ? AppColors.textSecondary : AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: readOnly ? AppColors.background : AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _passwordField(String label, TextEditingController controller,
      {required bool show,
      VoidCallback? onToggle,
      String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UpperText(label,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: !show,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            suffixIcon: onToggle != null
                ? IconButton(
                    icon: Icon(show ? Icons.visibility_off : Icons.visibility,
                        size: 20, color: AppColors.textSecondary),
                    onPressed: onToggle,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
