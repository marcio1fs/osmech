import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import '../mixins/auth_error_mixin.dart';

/// Formulário para criar nova transação financeira.
class TransacaoFormPage extends StatefulWidget {
  final VoidCallback? onSaved;

  const TransacaoFormPage({super.key, this.onSaved});

  @override
  State<TransacaoFormPage> createState() => _TransacaoFormPageState();
}

class _TransacaoFormPageState extends State<TransacaoFormPage>
    with AuthErrorMixin {
  final _formKey = GlobalKey<FormState>();
  String _tipo = 'ENTRADA';
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacoesController = TextEditingController();
  String _metodoPagamento = 'DINHEIRO';
  int? _categoriaId;
  List<Map<String, dynamic>> _categorias = [];
  bool _saving = false;
  bool _loadingCategorias = true;

  @override
  void initState() {
    super.initState();
    _loadCategorias();
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _loadCategorias() async {
    try {
      final service = FinanceService(token: safeToken);
      final cats = await service.listarCategorias();
      setState(() {
        _categorias = cats;
        _loadingCategorias = false;
      });
    } catch (e) {
      if (!handleAuthError(e)) {
        setState(() => _loadingCategorias = false);
      }
    }
  }

  List<Map<String, dynamic>> get _categoriasFiltradas {
    return _categorias.where((c) => c['tipo'] == _tipo).toList();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final service = FinanceService(token: safeToken);

      final valorStr = _valorController.text
          .replaceAll('R\$', '')
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim();

      await service.criarTransacao({
        'tipo': _tipo,
        'descricao': _descricaoController.text.trim(),
        'valor': double.parse(valorStr),
        'metodoPagamento': _metodoPagamento,
        'categoriaId': _categoriaId,
        'observacoes': _observacoesController.text.trim().isEmpty
            ? null
            : _observacoesController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transação registrada com sucesso!',
                style: GoogleFonts.inter()),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onSaved?.call();
      }
    } catch (e) {
      if (!handleAuthError(e)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Erro: ${e.toString().replaceAll('Exception: ', '')}',
                  style: GoogleFonts.inter()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
                    Text('Novo Lançamento',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text('Registre uma entrada ou saída financeira',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),

          // Form content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tipo selector
                        Text('Tipo de Lançamento',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _TipoButton(
                                label: 'Entrada',
                                icon: Icons.arrow_downward_rounded,
                                color: AppColors.success,
                                selected: _tipo == 'ENTRADA',
                                onTap: () => setState(() {
                                  _tipo = 'ENTRADA';
                                  _categoriaId = null;
                                }),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TipoButton(
                                label: 'Saída',
                                icon: Icons.arrow_upward_rounded,
                                color: AppColors.error,
                                selected: _tipo == 'SAIDA',
                                onTap: () => setState(() {
                                  _tipo = 'SAIDA';
                                  _categoriaId = null;
                                }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Descrição
                        _buildLabel('Descrição *'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descricaoController,
                          decoration:
                              _inputDecoration('Ex: Serviço de alinhamento'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Obrigatório'
                              : null,
                        ),
                        const SizedBox(height: 20),

                        // Valor
                        _buildLabel('Valor (R\$) *'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _valorController,
                          decoration: _inputDecoration('0,00'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[\d,.]')),
                          ],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Obrigatório';
                            }
                            final parsed = double.tryParse(v
                                .replaceAll('R\$', '')
                                .replaceAll('.', '')
                                .replaceAll(',', '.')
                                .trim());
                            if (parsed == null || parsed <= 0) {
                              return 'Valor deve ser positivo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Categoria
                        _buildLabel('Categoria'),
                        const SizedBox(height: 8),
                        _loadingCategorias
                            ? const LinearProgressIndicator()
                            : DropdownButtonFormField<int>(
                                value: _categoriaId,
                                decoration: _inputDecoration('Selecione...'),
                                isExpanded: true,
                                items: [
                                  const DropdownMenuItem<int>(
                                    value: null,
                                    child: Text('Sem categoria'),
                                  ),
                                  ..._categoriasFiltradas
                                      .map((c) => DropdownMenuItem<int>(
                                            value: c['id'] as int,
                                            child: Text(c['nome'] ?? ''),
                                          )),
                                ],
                                onChanged: (v) =>
                                    setState(() => _categoriaId = v),
                              ),
                        const SizedBox(height: 20),

                        // Método de Pagamento
                        _buildLabel('Método de Pagamento'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _metodoPagamento,
                          decoration: _inputDecoration(''),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                                value: 'DINHEIRO', child: Text('Dinheiro')),
                            DropdownMenuItem(value: 'PIX', child: Text('PIX')),
                            DropdownMenuItem(
                                value: 'CARTAO', child: Text('Cartão')),
                            DropdownMenuItem(
                                value: 'BOLETO', child: Text('Boleto')),
                            DropdownMenuItem(
                                value: 'TRANSFERENCIA',
                                child: Text('Transferência')),
                            DropdownMenuItem(
                                value: 'OUTRO', child: Text('Outro')),
                          ],
                          onChanged: (v) =>
                              setState(() => _metodoPagamento = v!),
                        ),
                        const SizedBox(height: 20),

                        // Observações
                        _buildLabel('Observações'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _observacoesController,
                          decoration:
                              _inputDecoration('Observações opcionais...'),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 32),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _salvar,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.save_rounded, size: 20),
                            label: Text(_saving
                                ? 'Salvando...'
                                : 'Registrar Lançamento'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _tipo == 'ENTRADA'
                                  ? AppColors.success
                                  : AppColors.error,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              textStyle: GoogleFonts.inter(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary));
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _TipoButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TipoButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? color : AppColors.textMuted, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? color : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
