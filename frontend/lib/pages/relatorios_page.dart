import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/relatorio_service.dart';
import '../services/stock_service.dart';
import '../theme/app_theme.dart';
import '../mixins/auth_error_mixin.dart';
import '../utils/formatters.dart';
import '../utils/file_download.dart';
import '../widgets/upper_text.dart';

import 'relatorios/relatorio_os_tab.dart';
import 'relatorios/relatorio_financeiro_tab.dart';
import 'relatorios/relatorio_clientes_tab.dart';
import 'relatorios/relatorio_estoque_tab.dart';

/// Página de Relatórios — atalhos: F5 atualiza, Ctrl+E exporta PDF
class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({super.key});

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage>
    with SingleTickerProviderStateMixin, AuthErrorMixin {
  late TabController _tabController;
  late FocusNode _focusNode;
  bool _loading = false;
  bool _exportando = false;
  String? _error;

  late DateTime _dataInicio;
  late DateTime _dataFim;

  // OS
  Map<String, dynamic>? _relatorioOsPeriodo;
  List<Map<String, dynamic>> _relatorioOsMecanico = [];
  List<Map<String, dynamic>> _relatorioOsVeiculo = [];
  List<Map<String, dynamic>> _relatorioOsCliente = [];

  // Financeiro
  Map<String, dynamic>? _relatorioReceitas;
  Map<String, dynamic>? _relatorioDespesas;
  Map<String, dynamic>? _relatorioFluxoCaixa;
  List<Map<String, dynamic>> _relatorioMetodoPagamento = [];

  // Clientes
  List<Map<String, dynamic>> _relatorioClientesGasto = [];
  List<Map<String, dynamic>> _relatorioClientesQuantidade = [];
  List<Map<String, dynamic>> _relatorioContatos = [];

  // Estoque
  Map<String, dynamic>? _relatorioValuationEstoque;
  List<Map<String, dynamic>> _relatorioEstoqueBaixo = [];
  List<Map<String, dynamic>> _relatorioMovimentacoes = [];
  List<Map<String, dynamic>> _todosItensEstoque = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _focusNode = FocusNode();
    final now = DateTime.now();
    _dataInicio = DateTime(now.year, now.month, 1);
    _dataFim = DateTime(now.year, now.month + 1, 0);
    _carregarRelatorios();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _token =>
      Provider.of<AuthService>(context, listen: false).token ?? '';

  String get _tipoExportacaoAtual {
    switch (_tabController.index) {
      case 0: return 'os';
      case 1: return 'financeiro';
      case 2: return 'clientes';
      case 3: return 'estoque';
      default: return 'os';
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    final ctrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    // F5 — atualizar relatórios
    if (key == LogicalKeyboardKey.f5 && !_loading) {
      _carregarRelatorios();
      return;
    }
    // Ctrl+E — exportar PDF
    if (ctrl && key == LogicalKeyboardKey.keyE && !_exportando) {
      _exportarRelatorio('pdf');
      return;
    }
    // Ctrl+P — selecionar período
    if (ctrl && key == LogicalKeyboardKey.keyP) {
      _selecionarPeriodo();
      return;
    }
    // Ctrl+1..4 — trocar aba
    if (ctrl && key == LogicalKeyboardKey.digit1) {
      _tabController.animateTo(0); _carregarRelatorios(); return;
    }
    if (ctrl && key == LogicalKeyboardKey.digit2) {
      _tabController.animateTo(1); _carregarRelatorios(); return;
    }
    if (ctrl && key == LogicalKeyboardKey.digit3) {
      _tabController.animateTo(2); _carregarRelatorios(); return;
    }
    if (ctrl && key == LogicalKeyboardKey.digit4) {
      _tabController.animateTo(3); _carregarRelatorios(); return;
    }
  }

  Future<void> _exportarRelatorio(String formato) async {
    if (_exportando) return;
    setState(() => _exportando = true);
    try {
      final svc = RelatorioService(token: _token);
      final arquivo = await svc.exportarRelatorio(
        formato: formato,
        tipo: _tipoExportacaoAtual,
        inicio: _dataInicio,
        fim: _dataFim,
        formatoPdf: 'resumido',
      );
      saveBytesAsFile(arquivo.bytes, arquivo.filename, arquivo.contentType);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: UpperText('Relatório exportado: ${arquivo.filename}'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: UpperText('Erro ao exportar: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _carregarRelatorios() async {
    setState(() { _loading = true; _error = null; });
    try {
      final svc = RelatorioService(token: _token);
      switch (_tabController.index) {
        case 0:
          await Future.wait([
            svc.getRelatorioOsPeriodo(_dataInicio, _dataFim, null)
                .then((r) => setState(() => _relatorioOsPeriodo = r)),
            svc.getRelatorioOsPorMecanico(_dataInicio, _dataFim)
                .then((r) => setState(() => _relatorioOsMecanico = r)),
            svc.getRelatorioOsPorVeiculo(_dataInicio, _dataFim)
                .then((r) => setState(() => _relatorioOsVeiculo = r)),
            svc.getRelatorioOsPorCliente(_dataInicio, _dataFim)
                .then((r) => setState(() => _relatorioOsCliente = r)),
          ]);
          break;
        case 1:
          await Future.wait([
            svc.getRelatorioReceitas(_dataInicio, _dataFim)
                .then((r) => setState(() => _relatorioReceitas = r)),
            svc.getRelatorioDespesas(_dataInicio, _dataFim)
                .then((r) => setState(() => _relatorioDespesas = r)),
            svc.getRelatorioFluxoCaixa(_dataInicio, _dataFim)
                .then((r) => setState(() => _relatorioFluxoCaixa = r)),
            svc.getRelatorioPorMetodoPagamento(_dataInicio, _dataFim)
                .then((r) => setState(() => _relatorioMetodoPagamento = r)),
          ]);
          break;
        case 2:
          await Future.wait([
            svc.getRelatorioClientesPorGasto(limite: 50)
                .then((r) => setState(() => _relatorioClientesGasto = r)),
            svc.getRelatorioClientesPorQuantidadeOs(limite: 50)
                .then((r) => setState(() => _relatorioClientesQuantidade = r)),
            svc.getRelatorioContatos()
                .then((r) => setState(() => _relatorioContatos = r)),
          ]);
          break;
        case 3:
          final stockSvc = StockService(token: _token);
          await Future.wait([
            svc.getRelatorioValuationEstoque()
                .then((r) => setState(() => _relatorioValuationEstoque = r)),
            svc.getRelatorioEstoqueBaixo(limite: 50)
                .then((r) => setState(() => _relatorioEstoqueBaixo = r)),
            svc.getRelatorioMovimentacoes(_dataInicio, _dataFim)
                .then((r) => setState(() => _relatorioMovimentacoes = r)),
            stockSvc.listarItens()
                .then((r) => setState(() => _todosItensEstoque = r)),
          ]);
          break;
      }
    } catch (e) {
      if (!handleAuthError(e)) {
        setState(() => _error = 'Erro ao carregar relatórios: $e');
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _selecionarPeriodo() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5, 12, 31),
      initialDateRange: DateTimeRange(
        start: _dataInicio.isAfter(DateTime(now.year + 5, 12, 31)) ? DateTime(now.year, now.month, 1) : _dataInicio,
        end: _dataFim.isAfter(DateTime(now.year + 5, 12, 31)) ? DateTime(now.year, now.month + 1, 0) : _dataFim,
      ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary, onPrimary: Colors.white, surface: AppColors.surface, onSurface: AppColors.textPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() { _dataInicio = picked.start; _dataFim = picked.end; });
      _carregarRelatorios();
    }
  }

  void _definirPeriodoRapido(String tipo) {
    final now = DateTime.now();
    DateTime inicio;
    DateTime fim;

    switch (tipo) {
      case 'mes_atual':
        inicio = DateTime(now.year, now.month, 1);
        fim = DateTime(now.year, now.month + 1, 0);
        break;
      case 'mes_anterior':
        inicio = DateTime(now.year, now.month - 1, 1);
        fim = DateTime(now.year, now.month, 0);
        break;
      case 'ultimos_30':
        inicio = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
        fim = DateTime(now.year, now.month, now.day);
        break;
      case 'ano_atual':
        inicio = DateTime(now.year, 1, 1);
        fim = DateTime(now.year, 12, 31);
        break;
      default:
        return;
    }

    setState(() {
      _dataInicio = inicio;
      _dataFim = fim;
    });
    _carregarRelatorios();
  }

  Widget _buildQuickPeriodFilters() {
    final now = DateTime.now();
    
    bool isSelected(DateTime start, DateTime end) {
      return _dataInicio.year == start.year &&
          _dataInicio.month == start.month &&
          _dataInicio.day == start.day &&
          _dataFim.year == end.year &&
          _dataFim.month == end.month &&
          _dataFim.day == end.day;
    }

    final mesAtualStart = DateTime(now.year, now.month, 1);
    final mesAtualEnd = DateTime(now.year, now.month + 1, 0);
    final mesAnteriorStart = DateTime(now.year, now.month - 1, 1);
    final mesAnteriorEnd = DateTime(now.year, now.month, 0);
    final ultimos30Start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
    final ultimos30End = DateTime(now.year, now.month, now.day);
    final anoAtualStart = DateTime(now.year, 1, 1);
    final anoAtualEnd = DateTime(now.year, 12, 31);

    Widget periodChip(String label, String tipo, bool active) {
      return InkWell(
        onTap: () => _definirPeriodoRapido(tipo),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.border.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: UpperText(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        periodChip('Mês Atual', 'mes_atual', isSelected(mesAtualStart, mesAtualEnd)),
        periodChip('Mês Anterior', 'mes_anterior', isSelected(mesAnteriorStart, mesAnteriorEnd)),
        periodChip('Últimos 30 Dias', 'ultimos_30', isSelected(ultimos30Start, ultimos30End)),
        periodChip('Ano Atual', 'ano_atual', isSelected(anoAtualStart, anoAtualEnd)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        color: AppColors.background,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: LayoutBuilder(builder: (context, constraints) {
                final compact = constraints.maxWidth < 750;

                final exportButton = PopupMenuButton<String>(
                  tooltip: 'Exportar (Ctrl+E = PDF)',
                  enabled: !_loading && !_exportando,
                  onSelected: _exportarRelatorio,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'pdf', child: ListTile(
                      leading: Icon(Icons.picture_as_pdf_outlined),
                      title: UpperText('Exportar PDF'),
                      contentPadding: EdgeInsets.zero,
                    )),
                    PopupMenuItem(value: 'excel', child: ListTile(
                      leading: Icon(Icons.table_chart_outlined),
                      title: UpperText('Exportar Excel'),
                      contentPadding: EdgeInsets.zero,
                    )),
                    PopupMenuItem(value: 'csv', child: ListTile(
                      leading: Icon(Icons.description_outlined),
                      title: UpperText('Exportar CSV'),
                      contentPadding: EdgeInsets.zero,
                    )),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_exportando)
                          const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        else
                          const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        UpperText(_exportando ? 'Exportando...' : 'Exportar',
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );

                final title = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UpperText('Relatórios',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    UpperText(
                      '${formatDateBR(_dataInicio)} – ${formatDateBR(_dataFim)}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                );

                final actions = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _selecionarPeriodo,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const UpperText('Período'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.textPrimary),
                    ),
                    FilledButton.icon(
                      onPressed: _loading ? null : _carregarRelatorios,
                      icon: _loading
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.refresh, size: 18),
                      label: const UpperText('F5'),
                    ),
                    exportButton,
                  ],
                );

                if (compact) {
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    title,
                    const SizedBox(height: 12),
                    actions,
                    const SizedBox(height: 12),
                    _buildQuickPeriodFilters(),
                  ]);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: title),
                        const SizedBox(width: 16),
                        actions,
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildQuickPeriodFilters(),
                  ],
                );
              }),
            ),

            // Tabs
            Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.accent,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.accent,
                onTap: (_) => _carregarRelatorios(),
                tabs: const [
                  Tab(text: 'OS'),
                  Tab(text: 'Financeiro'),
                  Tab(text: 'Clientes'),
                  Tab(text: 'Estoque'),
                ],
              ),
            ),
            // Conteúdo
            Expanded(
              child: _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                          const SizedBox(height: 12),
                          UpperText(_error!, style: GoogleFonts.inter(color: AppColors.textSecondary)),
                          const SizedBox(height: 12),
                          FilledButton(onPressed: _carregarRelatorios, child: const UpperText('Tentar novamente')),
                        ],
                      ),
                    )
                  : _loading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            RelatorioOsTab(
                              relatorioOsPeriodo: _relatorioOsPeriodo,
                              relatorioOsMecanico: _relatorioOsMecanico,
                              relatorioOsVeiculo: _relatorioOsVeiculo,
                              relatorioOsCliente: _relatorioOsCliente,
                            ),
                            RelatorioFinanceiroTab(
                              relatorioReceitas: _relatorioReceitas,
                              relatorioDespesas: _relatorioDespesas,
                              relatorioFluxoCaixa: _relatorioFluxoCaixa,
                              relatorioMetodoPagamento: _relatorioMetodoPagamento,
                            ),
                            RelatorioClientesTab(
                              relatorioClientesGasto: _relatorioClientesGasto,
                              relatorioClientesQuantidade: _relatorioClientesQuantidade,
                              relatorioContatos: _relatorioContatos,
                            ),
                            RelatorioEstoqueTab(
                              relatorioValuationEstoque: _relatorioValuationEstoque,
                              relatorioEstoqueBaixo: _relatorioEstoqueBaixo,
                              relatorioMovimentacoes: _relatorioMovimentacoes,
                              todosItensEstoque: _todosItensEstoque,
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
