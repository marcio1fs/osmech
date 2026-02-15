import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/stock_service.dart';
import '../theme/app_theme.dart';
import '../mixins/auth_error_mixin.dart';

/// Lista de itens de estoque com busca, filtro por categoria e indicadores visuais.
class StockListPage extends StatefulWidget {
  final VoidCallback? onNavigateNovaPeca;
  final VoidCallback? onNavigateMovimentacao;
  final VoidCallback? onNavigateAlertas;
  final void Function(int itemId)? onEditarItem;

  const StockListPage({
    super.key,
    this.onNavigateNovaPeca,
    this.onNavigateMovimentacao,
    this.onNavigateAlertas,
    this.onEditarItem,
  });

  @override
  State<StockListPage> createState() => _StockListPageState();
}

class _StockListPageState extends State<StockListPage> with AuthErrorMixin {
  List<Map<String, dynamic>> _itens = [];
  bool _loading = true;
  String? _error;
  String? _filtroCategoria;
  final TextEditingController _buscaCtrl = TextEditingController();

  static const List<String> _categorias = [
    'MOTOR',
    'SUSPENSAO',
    'FREIOS',
    'ELETRICA',
    'TRANSMISSAO',
    'ARREFECIMENTO',
    'FILTROS',
    'OLEOS',
    'FUNILARIA',
    'ACESSORIOS',
    'OUTROS',
  ];

  static const Map<String, String> _categoriaLabels = {
    'MOTOR': 'Motor',
    'SUSPENSAO': 'Suspensão',
    'FREIOS': 'Freios',
    'ELETRICA': 'Elétrica',
    'TRANSMISSAO': 'Transmissão',
    'ARREFECIMENTO': 'Arrefecimento',
    'FILTROS': 'Filtros',
    'OLEOS': 'Óleos',
    'FUNILARIA': 'Funilaria',
    'ACESSORIOS': 'Acessórios',
    'OUTROS': 'Outros',
  };

  @override
  void initState() {
    super.initState();
    _loadItens();
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadItens() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = StockService(token: auth.token!);
      final data = await service.listarItens(
        categoria: _filtroCategoria,
        busca: _buscaCtrl.text.isNotEmpty ? _buscaCtrl.text : null,
      );
      setState(() {
        _itens = data;
        _loading = false;
      });
    } catch (e) {
      if (!handleAuthError(e)) {
        setState(() {
          _error = 'Erro ao carregar estoque';
          _loading = false;
        });
      }
    }
  }

  Future<void> _desativarItem(int id, String nome) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desativar Item'),
        content:
            Text('Deseja desativar "$nome"? Ele não aparecerá mais na lista.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = StockService(token: auth.token!);
      await service.desativarItem(id);
      _loadItens();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Item desativado', style: GoogleFonts.inter()),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (!handleAuthError(e)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Erro ao desativar item', style: GoogleFonts.inter()),
                backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  String _formatCurrency(dynamic v) {
    final val = (v is num) ? v.toDouble() : 0.0;
    return 'R\$ ${val.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final alertCount = _itens.where((e) => e['estoqueBaixo'] == true).length;

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
                    Text('Estoque',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text('${_itens.length} itens cadastrados',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
                if (alertCount > 0) ...[
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: widget.onNavigateAlertas,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 16, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text('$alertCount alertas',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning)),
                        ],
                      ),
                    ),
                  ),
                ],
                const Spacer(),

                // Busca
                SizedBox(
                  width: 220,
                  height: 38,
                  child: TextField(
                    controller: _buscaCtrl,
                    onSubmitted: (_) => _loadItens(),
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Buscar peça...',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      suffixIcon: _buscaCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _buscaCtrl.clear();
                                _loadItens();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Filtro de categoria
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filtroCategoria,
                      hint: Text('Categoria',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.textMuted)),
                      items: _categorias
                          .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(_categoriaLabels[c] ?? c,
                                  style: GoogleFonts.inter(fontSize: 13))))
                          .toList(),
                      onChanged: (v) {
                        setState(() => _filtroCategoria = v);
                        _loadItens();
                      },
                    ),
                  ),
                ),
                if (_filtroCategoria != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    tooltip: 'Limpar filtro',
                    onPressed: () {
                      setState(() => _filtroCategoria = null);
                      _loadItens();
                    },
                  ),
                ],
                const SizedBox(width: 12),

                FilledButton.icon(
                  onPressed: widget.onNavigateNovaPeca,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Nova Peça'),
                ),
              ],
            ),
          ),

          // Table
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
                                onPressed: _loadItens,
                                child: const Text('Tentar novamente')),
                          ],
                        ),
                      )
                    : _itens.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inventory_2_outlined,
                                    size: 64,
                                    color:
                                        AppColors.textMuted.withValues(alpha: 0.4)),
                                const SizedBox(height: 12),
                                Text('Nenhuma peça cadastrada',
                                    style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: AppColors.textSecondary)),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: widget.onNavigateNovaPeca,
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Cadastrar Peça'),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(32),
                            child: _buildTable(),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                _colHeader('Código', flex: 1),
                _colHeader('Nome', flex: 2),
                _colHeader('Categoria', flex: 1),
                _colHeader('Qtd', flex: 1),
                _colHeader('Mín', flex: 1),
                _colHeader('Custo', flex: 1),
                _colHeader('Venda', flex: 1),
                _colHeader('Ações', flex: 1),
              ],
            ),
          ),
          // Rows
          ...List.generate(_itens.length, (i) {
            final item = _itens[i];
            final estoqueBaixo = item['estoqueBaixo'] == true;
            final estoqueZerado = item['estoqueZerado'] == true;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: estoqueZerado
                    ? AppColors.error.withValues(alpha: 0.04)
                    : estoqueBaixo
                        ? AppColors.warning.withValues(alpha: 0.04)
                        : Colors.transparent,
                border: Border(
                    bottom: BorderSide(
                        color: i < _itens.length - 1
                            ? AppColors.border
                            : Colors.transparent)),
              ),
              child: Row(
                children: [
                  _colCell(item['codigo'] ?? '', flex: 1, bold: true),
                  _colCell(item['nome'] ?? '', flex: 2),
                  Expanded(
                    flex: 1,
                    child: Text(
                      _categoriaLabels[item['categoria']] ??
                          item['categoria'] ??
                          '',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        if (estoqueZerado)
                          const Icon(Icons.error_rounded,
                              size: 14, color: AppColors.error)
                        else if (estoqueBaixo)
                          const Icon(Icons.warning_rounded,
                              size: 14, color: AppColors.warning),
                        if (estoqueBaixo || estoqueZerado)
                          const SizedBox(width: 4),
                        Text(
                          '${item['quantidade']}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: estoqueZerado
                                ? AppColors.error
                                : estoqueBaixo
                                    ? AppColors.warning
                                    : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _colCell('${item['quantidadeMinima']}', flex: 1),
                  _colCell(_formatCurrency(item['precoCusto']), flex: 1),
                  _colCell(_formatCurrency(item['precoVenda']), flex: 1),
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded,
                              size: 18, color: AppColors.accent),
                          tooltip: 'Editar',
                          onPressed: () =>
                              widget.onEditarItem?.call(item['id'] as int),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppColors.error),
                          tooltip: 'Desativar',
                          onPressed: () => _desativarItem(
                              item['id'] as int, item['nome'] ?? ''),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _colHeader(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.5)),
    );
  }

  Widget _colCell(String text, {int flex = 1, bool bold = false}) {
    return Expanded(
      flex: flex,
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: AppColors.textPrimary),
          overflow: TextOverflow.ellipsis),
    );
  }
}
