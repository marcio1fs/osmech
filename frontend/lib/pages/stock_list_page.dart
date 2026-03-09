import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/stock_service.dart';
import '../theme/app_theme.dart';
import '../mixins/auth_error_mixin.dart';
import '../utils/formatters.dart';

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

  static const double _colCodigoWidth = 110;
  static const double _colNomeWidth = 240;
  static const double _colCategoriaWidth = 150;
  static const double _colMarcaWidth = 140;
  static const double _colQtdWidth = 90;
  static const double _colMinWidth = 90;
  static const double _colCustoWidth = 120;
  static const double _colVendaWidth = 120;
  static const double _colAcoesWidth = 120;

  double get _tableContentWidth =>
      _colCodigoWidth +
      _colNomeWidth +
      _colCategoriaWidth +
      _colMarcaWidth +
      _colQtdWidth +
      _colMinWidth +
      _colCustoWidth +
      _colVendaWidth +
      _colAcoesWidth;

  // Soma padding horizontal (20 + 20) + bordas (1 + 1) do container da tabela.
  double get _tableWidth => _tableContentWidth + 42;

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
      final token = safeToken;
      final tokenPreview =
          token.length <= 20 ? token : token.substring(0, 20);
      debugPrint('[StockList] Carregando itens com token: $tokenPreview...');
      final service = StockService(token: token);
      debugPrint('[StockList] Chamando API /api/stock');
      final data = await service.listarItens(
        categoria: _filtroCategoria,
        busca: _buscaCtrl.text.isNotEmpty ? _buscaCtrl.text : null,
      );
      debugPrint('[StockList] Recebeu ${data.length} itens do backend');
      setState(() {
        _itens = data;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[StockList] ERRO: $e');
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
      final service = StockService(token: safeToken);
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
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
                const SizedBox(width: 24),

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

                // Botão atualizar
                IconButton(
                  onPressed: _loading ? null : _loadItens,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Atualizar lista',
                ),
                const SizedBox(width: 8),

                FilledButton.icon(
                  onPressed: widget.onNavigateNovaPeca,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Nova Peça'),
                ),
                ],
              ),
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
                                    color: AppColors.textMuted
                                        .withValues(alpha: 0.4)),
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
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: _tableWidth,
                                child: _buildTable(),
                              ),
                            ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Row(
                    children: [
                _colHeader('Codigo', width: _colCodigoWidth),
                _colHeader('Nome', width: _colNomeWidth),
                _colHeader('Categoria', width: _colCategoriaWidth),
                _colHeader('Marca', width: _colMarcaWidth),
                _colHeader('Qtd', width: _colQtdWidth),
                _colHeader('Min', width: _colMinWidth),
                _colHeader('Custo', width: _colCustoWidth),
                _colHeader('Venda', width: _colVendaWidth),
                _colHeader('Acoes', width: _colAcoesWidth),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
                        : Colors.transparent,
                  ),
                ),
              ),
              child: Row(
                children: [
                  _colCell(item['codigo'] ?? '', width: _colCodigoWidth, bold: true),
                  _colCell(item['nome'] ?? '', width: _colNomeWidth),
                  _colCell(
                    _categoriaLabels[item['categoria']] ?? item['categoria'] ?? '',
                    width: _colCategoriaWidth,
                  ),
                  _colCell(item['marca'] ?? '', width: _colMarcaWidth),
                  SizedBox(
                    width: _colQtdWidth,
                    child: Row(
                      children: [
                        if (estoqueZerado)
                          const Icon(Icons.error_rounded, size: 14, color: AppColors.error)
                        else if (estoqueBaixo)
                          const Icon(Icons.warning_rounded, size: 14, color: AppColors.warning),
                        if (estoqueBaixo || estoqueZerado) const SizedBox(width: 4),
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
                  _colCell('${item['quantidadeMinima']}', width: _colMinWidth),
                  _colCell(formatCurrency(item['precoCusto']), width: _colCustoWidth),
                  _colCell(formatCurrency(item['precoVenda']), width: _colVendaWidth),
                  SizedBox(
                    width: _colAcoesWidth,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.accent),
                          tooltip: 'Editar',
                          onPressed: () => widget.onEditarItem?.call(item['id'] as int),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                          tooltip: 'Desativar',
                          onPressed: () => _desativarItem(item['id'] as int, item['nome'] ?? ''),
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

  Widget _colHeader(String text, {required double width}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _colCell(String text, {required double width, bool bold = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

