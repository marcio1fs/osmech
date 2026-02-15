import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/os_service.dart';
import '../theme/app_theme.dart';

/// Formulário de criação/edição de OS — design moderno.
class OsFormPage extends StatefulWidget {
  final Map<String, dynamic>? osData;
  final VoidCallback? onSaved;
  const OsFormPage({super.key, this.osData, this.onSaved});

  @override
  State<OsFormPage> createState() => _OsFormPageState();
}

class _OsFormPageState extends State<OsFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _clienteNome;
  late final TextEditingController _clienteTelefone;
  late final TextEditingController _placa;
  late final TextEditingController _modelo;
  late final TextEditingController _ano;
  late final TextEditingController _km;
  late final TextEditingController _descricao;
  late final TextEditingController _diagnostico;
  late final TextEditingController _pecas;
  late final TextEditingController _valor;
  String _status = 'ABERTA';
  bool _notificarWhatsApp = false;
  bool _loading = false;

  bool get _isEditing => widget.osData != null;

  @override
  void initState() {
    super.initState();
    final d = widget.osData;
    _clienteNome = TextEditingController(text: d?['clienteNome'] ?? '');
    _clienteTelefone = TextEditingController(text: d?['clienteTelefone'] ?? '');
    _placa = TextEditingController(text: d?['placa'] ?? '');
    _modelo = TextEditingController(text: d?['modelo'] ?? '');
    _ano = TextEditingController(text: d?['ano']?.toString() ?? '');
    _km = TextEditingController(text: d?['quilometragem']?.toString() ?? '');
    _descricao = TextEditingController(text: d?['descricao'] ?? '');
    _diagnostico = TextEditingController(text: d?['diagnostico'] ?? '');
    _pecas = TextEditingController(text: d?['pecas'] ?? '');
    _valor = TextEditingController(text: d?['valor']?.toString() ?? '');
    _status = d?['status'] ?? 'ABERTA';
    _notificarWhatsApp = d?['whatsappConsentimento'] ?? false;
  }

  @override
  void dispose() {
    _clienteNome.dispose();
    _clienteTelefone.dispose();
    _placa.dispose();
    _modelo.dispose();
    _ano.dispose();
    _km.dispose();
    _descricao.dispose();
    _diagnostico.dispose();
    _pecas.dispose();
    _valor.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final osService = OsService(token: auth.token!);
      final data = {
        'clienteNome': _clienteNome.text.trim(),
        'clienteTelefone': _clienteTelefone.text.trim(),
        'placa': _placa.text.trim().toUpperCase(),
        'modelo': _modelo.text.trim(),
        'ano': int.tryParse(_ano.text.trim()),
        'quilometragem': int.tryParse(_km.text.trim()),
        'descricao': _descricao.text.trim(),
        'diagnostico': _diagnostico.text.trim(),
        'pecas': _pecas.text.trim(),
        'valor': double.tryParse(_valor.text.trim()) ?? 0,
        'status': _status,
        'whatsappConsentimento': _notificarWhatsApp,
      };
      if (_isEditing) {
        await osService.atualizar(widget.osData!['id'], data);
      } else {
        await osService.criar(data);
      }
      if (mounted) {
        if (widget.onSaved != null) {
          widget.onSaved!();
        } else {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao salvar: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
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
                if (Navigator.canPop(context))
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isEditing ? 'Editar OS' : 'Nova Ordem de Serviço',
                      style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    Text(
                      _isEditing
                          ? 'Placa: ${widget.osData?['placa'] ?? ''}'
                          : 'Preencha os dados da OS',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _loading ? null : _salvar,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(_isEditing ? 'Salvar Alterações' : 'Criar OS'),
                ),
              ],
            ),
          ),

          // Form content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section: Cliente
                      _SectionHeader(
                          icon: Icons.person_outline_rounded,
                          title: 'Dados do Cliente'),
                      const SizedBox(height: 16),
                      _CardSection(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _Field(
                                    label: 'Nome do Cliente',
                                    controller: _clienteNome,
                                    required: true),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _Field(
                                    label: 'Telefone (WhatsApp)',
                                    controller: _clienteTelefone,
                                    required: true,
                                    keyboard: TextInputType.phone),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Section: Veículo
                      _SectionHeader(
                          icon: Icons.directions_car_outlined,
                          title: 'Dados do Veículo'),
                      const SizedBox(height: 16),
                      _CardSection(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: _Field(
                                      label: 'Placa',
                                      controller: _placa,
                                      required: true)),
                              const SizedBox(width: 16),
                              Expanded(
                                  flex: 2,
                                  child: _Field(
                                      label: 'Modelo',
                                      controller: _modelo,
                                      required: true)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                  child: _Field(
                                      label: 'Ano',
                                      controller: _ano,
                                      keyboard: TextInputType.number)),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: _Field(
                                      label: 'Quilometragem',
                                      controller: _km,
                                      keyboard: TextInputType.number)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Section: Serviço
                      _SectionHeader(
                          icon: Icons.build_outlined, title: 'Serviço'),
                      const SizedBox(height: 16),
                      _CardSection(
                        children: [
                          _Field(
                              label: 'Descrição do Problema',
                              controller: _descricao,
                              required: true,
                              maxLines: 3),
                          const SizedBox(height: 16),
                          _Field(
                              label: 'Diagnóstico',
                              controller: _diagnostico,
                              maxLines: 3),
                          const SizedBox(height: 16),
                          _Field(
                              label: 'Peças Utilizadas',
                              controller: _pecas,
                              maxLines: 2),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _Field(
                                    label: 'Valor (R\$)',
                                    controller: _valor,
                                    required: true,
                                    keyboard: TextInputType.number),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Status',
                                        style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary)),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      value: _status,
                                      decoration: const InputDecoration(),
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'ABERTA',
                                            child: Text('Aberta')),
                                        DropdownMenuItem(
                                            value: 'EM_ANDAMENTO',
                                            child: Text('Em Andamento')),
                                        DropdownMenuItem(
                                            value: 'AGUARDANDO_PECA',
                                            child: Text('Aguardando Peça')),
                                        DropdownMenuItem(
                                            value: 'AGUARDANDO_APROVACAO',
                                            child: Text('Ag. Aprovação')),
                                        DropdownMenuItem(
                                            value: 'CONCLUIDA',
                                            child: Text('Concluída')),
                                        DropdownMenuItem(
                                            value: 'CANCELADA',
                                            child: Text('Cancelada')),
                                      ],
                                      onChanged: (v) => setState(
                                          () => _status = v ?? 'ABERTA'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // WhatsApp toggle
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: SwitchListTile(
                              value: _notificarWhatsApp,
                              onChanged: (v) =>
                                  setState(() => _notificarWhatsApp = v),
                              title: Text('Notificar cliente via WhatsApp',
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                              subtitle: Text(
                                  'Envia atualização de status ao cliente',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.textMuted)),
                              contentPadding: EdgeInsets.zero,
                              activeColor: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.accent),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ],
    );
  }
}

class _CardSection extends StatelessWidget {
  final List<Widget> children;
  const _CardSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool required;
  final int maxLines;
  final TextInputType? keyboard;
  const _Field(
      {required this.label,
      required this.controller,
      this.required = false,
      this.maxLines = 1,
      this.keyboard});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboard,
          validator: required
              ? (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null
              : null,
        ),
      ],
    );
  }
}
