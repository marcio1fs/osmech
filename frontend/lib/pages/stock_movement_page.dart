import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/stock_service.dart';
import '../theme/app_theme.dart';

/// Tela de movimentação de estoque (entrada/saída manual).
class StockMovementPage extends StatefulWidget {
  final VoidCallback? onSaved;

  const StockMovementPage({super.key, this.onSaved});

  @override
  State<StockMovementPage> createState() => _StockMovementPageState();
}

class _StockMovementPageState extends State<StockMovementPage> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _itens = [];
  List<Map<String, dynamic>> _movimentacoes = [];
  bool _loading = true;
  bool _saving = false;

  int? _selectedItemId;
  String _tipo = 'ENTRADA';
  String _motivo = 'COMPRA';
  final _quantidadeCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();

  static const Map<String, String> _motivosEntrada = {
    'COMPRA': 'Compra',
    'AJUSTE': 'Ajuste manual',
    'DEVOLUCAO': 'Devolução',
  };

  static const Map<String, String> _motivosSaida = {
    'CONSUMO_INTERNO': 'Consumo interno',
    'PERDA': 'Perda / Avaria',
    'AJUSTE': 'Ajuste manual',
    'OS': 'Ordem de Serviço',
  };

  Map<String, String> get _motivosAtuais =>
      _tipo == 'ENTRADA' ? _motivosEntrada : _motivosSaida;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _quantidadeCtrl.dispose();
    _descricaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = StockService(token: auth.token!);
      final itens = await service.listarItens();
      final movs = await service.listarMovimentacoes();
      setState(() {
        _itens = itens;
        _movimentacoes = movs;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Selecione um item', style: GoogleFonts.inter()),
            backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = StockService(token: auth.token!);
      await service.registrarMovimentacao({
        'stockItemId': _selectedItemId,
        'tipo': _tipo,
        'quantidade': int.tryParse(_quantidadeCtrl.text) ?? 1,
        'motivo': _motivo,
        'descricao': _descricaoCtrl.text.trim().isNotEmpty
            ? _descricaoCtrl.text.trim()
            : null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Movimentação registrada!', style: GoogleFonts.inter()),
              backgroundColor: AppColors.success),
        );
        // Limpar form e recarregar
        _quantidadeCtrl.clear();
        _descricaoCtrl.clear();
        setState(() => _selectedItemId = null);
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', ''),
                  style: GoogleFonts.inter()),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
                Text('Movimentação de Estoque',
                    style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Form
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Nova Movimentação',
                                      style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(height: 20),

                                  // Tipo toggle
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _TipoButton(
                                          label: 'Entrada',
                                          icon: Icons.arrow_downward_rounded,
                                          selected: _tipo == 'ENTRADA',
                                          color: AppColors.success,
                                          onTap: () => setState(() {
                                            _tipo = 'ENTRADA';
                                            _motivo = 'COMPRA';
                                          }),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _TipoButton(
                                          label: 'Saída',
                                          icon: Icons.arrow_upward_rounded,
                                          selected: _tipo == 'SAIDA',
                                          color: AppColors.error,
                                          onTap: () => setState(() {
                                            _tipo = 'SAIDA';
                                            _motivo = 'CONSUMO_INTERNO';
                                          }),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Item
                                  DropdownButtonFormField<int>(
                                    value: _selectedItemId,
                                    decoration: const InputDecoration(
                                      labelText: 'Peça / Item *',
                                      prefixIcon: Icon(Icons.build_rounded),
                                    ),
                                    items: _itens
                                        .map((i) => DropdownMenuItem<int>(
                                            value: i['id'] as int,
                                            child: Text(
                                                '${i['codigo']} - ${i['nome']} (${i['quantidade']} un)',
                                                style: GoogleFonts.inter(
                                                    fontSize: 13))))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _selectedItemId = v),
                                    validator: (v) =>
                                        v == null ? 'Selecione um item' : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // Quantidade + Motivo
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _quantidadeCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Quantidade *',
                                            prefixIcon:
                                                Icon(Icons.numbers_rounded),
                                          ),
                                          validator: (v) {
                                            if (v == null || v.isEmpty) {
                                              return 'Obrigatório';
                                            }
                                            final n = int.tryParse(v);
                                            if (n == null || n < 1) {
                                              return 'Mín. 1';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: _motivo,
                                          decoration: const InputDecoration(
                                            labelText: 'Motivo',
                                            prefixIcon: Icon(
                                                Icons.info_outline_rounded),
                                          ),
                                          items: _motivosAtuais.entries
                                              .map((e) => DropdownMenuItem(
                                                  value: e.key,
                                                  child: Text(e.value)))
                                              .toList(),
                                          onChanged: (v) =>
                                              setState(() => _motivo = v!),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Descrição
                                  TextFormField(
                                    controller: _descricaoCtrl,
                                    maxLines: 2,
                                    decoration: const InputDecoration(
                                      labelText: 'Descrição (opcional)',
                                      prefixIcon: Icon(Icons.notes_rounded),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  FilledButton.icon(
                                    onPressed: _saving ? null : _registrar,
                                    icon: _saving
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white))
                                        : const Icon(Icons.check_rounded,
                                            size: 18),
                                    label: Text(_saving
                                        ? 'Registrando...'
                                        : 'Registrar Movimentação'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Últimas movimentações
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Últimas Movimentações',
                                    style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary)),
                                const SizedBox(height: 16),
                                if (_movimentacoes.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 32),
                                    child: Center(
                                      child: Text('Nenhuma movimentação',
                                          style: GoogleFonts.inter(
                                              color: AppColors.textMuted)),
                                    ),
                                  )
                                else
                                  ...(_movimentacoes.take(20).map((m) {
                                    final isEntrada = m['tipo'] == 'ENTRADA';
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isEntrada
                                                ? Icons.arrow_downward_rounded
                                                : Icons.arrow_upward_rounded,
                                            size: 18,
                                            color: isEntrada
                                                ? AppColors.success
                                                : AppColors.error,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${m['stockItemCodigo']} - ${m['stockItemNome']}',
                                                  style: GoogleFonts.inter(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  '${m['motivo']} • ${_formatDate(m['criadoEm']?.toString())}',
                                                  style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color:
                                                          AppColors.textMuted),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '${isEntrada ? '+' : '-'}${m['quantidade']}',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: isEntrada
                                                  ? AppColors.success
                                                  : AppColors.error,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${m['quantidadeAnterior']} → ${m['quantidadePosterior']}',
                                            style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    );
                                  })),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TipoButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TipoButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? color : AppColors.textMuted),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected ? color : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
