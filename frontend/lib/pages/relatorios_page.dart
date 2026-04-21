import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/relatorio_service.dart';
import '../theme/app_theme.dart';
import '../mixins/auth_error_mixin.dart';
import '../utils/formatters.dart';
import '../utils/file_download.dart';
import '../widgets/upper_text.dart';

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
          await Future.wait([
            svc.getRelatorioValuationEstoque()
                .then((r) => setState(() => _relatorioValuationEstoque = r)),
            svc.getRelatorioEstoqueBaixo(limite: 50)
                .then((r) => setState(() => _relatorioEstoqueBaixo = r)),
            svc.getRelatorioMovimentacoes(_dataInicio, _dataFim)
                .then((r) => setState(() => _relatorioMovimentacoes = r)),
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
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _dataInicio, end: _dataFim),
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
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UpperText('Relatórios',
                            style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        UpperText(
                          '${formatDateBR(_dataInicio)} – ${formatDateBR(_dataFim)}  •  F5 atualizar  •  Ctrl+E exportar PDF  •  Ctrl+P período  •  Ctrl+1-4 abas',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _selecionarPeriodo,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const UpperText('Período'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _loading ? null : _carregarRelatorios,
                    icon: _loading
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.refresh, size: 18),
                    label: const UpperText('F5'),
                  ),
                  const SizedBox(width: 12),
                  PopupMenuButton<String>(
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
                  ),
                ],
              ),
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
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTabOs(),
                        _buildTabFinanceiro(),
                        _buildTabClientes(),
                        _buildTabEstoque(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ABA OS ====================
  Widget _buildTabOs() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_relatorioOsPeriodo != null) ...[
            _buildCard(
              title: 'Resumo de OS',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatCard('Total', '${_relatorioOsPeriodo!['totalOs'] ?? 0}'),
                  _buildStatCard('Abertas', '${_relatorioOsPeriodo!['osAbertas'] ?? 0}'),
                  _buildStatCard('Em Andamento', '${_relatorioOsPeriodo!['osEmAndamento'] ?? 0}'),
                  _buildStatCard('Concluídas', '${_relatorioOsPeriodo!['osConcluidas'] ?? 0}'),
                  _buildStatCard('Canceladas', '${_relatorioOsPeriodo!['osCanceladas'] ?? 0}'),
                  _buildStatCard('Valor Total', formatCurrency(_relatorioOsPeriodo!['valorTotal'] ?? 0)),
                  _buildStatCard('Ticket Médio', formatCurrency(_relatorioOsPeriodo!['valorMedioOs'] ?? 0)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (_relatorioOsMecanico.isNotEmpty) ...[
            _buildCard(
              title: 'OS por Mecânico',
              child: _buildDataTable(
                columns: const ['Mecânico', 'Total OS', 'Concluídas', 'Valor Total', 'Ticket Médio'],
                rows: _relatorioOsMecanico.map((item) => [
                  item['mecanico'] ?? '-',
                  '${item['totalOs'] ?? 0}',
                  '${item['osConcluidas'] ?? 0}',
                  formatCurrency(item['valorTotal'] ?? 0),
                  formatCurrency(item['valorMedio'] ?? 0),
                ]).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (_relatorioOsVeiculo.isNotEmpty) ...[
            _buildCard(
              title: 'OS por Veículo',
              child: _buildDataTable(
                columns: const ['Placa', 'Modelo', 'Montadora', 'Total OS', 'Valor Total', 'Última OS'],
                rows: _relatorioOsVeiculo.map((item) => [
                  item['placa'] ?? '-',
                  item['modelo'] ?? '-',
                  item['montadora'] ?? '-',
                  '${item['totalOs'] ?? 0}',
                  formatCurrency(item['valorTotal'] ?? 0),
                  item['ultimaOs'] != null ? _formatDate(item['ultimaOs'].toString()) : '-',
                ]).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (_relatorioOsCliente.isNotEmpty) ...[
            _buildCard(
              title: 'OS por Cliente',
              child: _buildDataTable(
                columns: const ['Cliente', 'Telefone', 'Total OS', 'Valor Total', 'Última OS'],
                rows: _relatorioOsCliente.map((item) => [
                  item['clienteNome'] ?? '-',
                  item['clienteTelefone'] ?? '-',
                  '${item['totalOs'] ?? 0}',
                  formatCurrency(item['valorTotal'] ?? 0),
                  item['ultimaOs'] != null ? _formatDate(item['ultimaOs'].toString()) : '-',
                ]).toList(),
              ),
            ),
          ],
          if (_relatorioOsPeriodo == null && _relatorioOsMecanico.isEmpty &&
              _relatorioOsVeiculo.isEmpty && _relatorioOsCliente.isEmpty)
            _buildEmpty('Nenhuma OS encontrada no período selecionado.'),
        ],
      ),
    );
  }

  // ==================== ABA FINANCEIRO ====================
  Widget _buildTabFinanceiro() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_relatorioReceitas != null)
                Expanded(child: _buildCard(
                  title: 'Receitas',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UpperText(formatCurrency(_relatorioReceitas!['totalReceitas'] ?? 0),
                          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.success)),
                      UpperText('${_relatorioReceitas!['totalTransacoes'] ?? 0} transações',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                )),
              if (_relatorioReceitas != null && _relatorioDespesas != null) const SizedBox(width: 16),
              if (_relatorioDespesas != null)
                Expanded(child: _buildCard(
                  title: 'Despesas',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UpperText(formatCurrency(_relatorioDespesas!['totalDespesas'] ?? 0),
                          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.error)),
                      UpperText('${_relatorioDespesas!['totalTransacoes'] ?? 0} transações',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                )),
            ],
          ),
          const SizedBox(height: 24),
          if (_relatorioFluxoCaixa != null) ...[
            _buildCard(
              title: 'Fluxo de Caixa',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatCard('Saldo Inicial', formatCurrency(_relatorioFluxoCaixa!['saldoInicial'] ?? 0)),
                  _buildStatCard('Total Entradas', formatCurrency(_relatorioFluxoCaixa!['totalEntradas'] ?? 0)),
                  _buildStatCard('Total Saídas', formatCurrency(_relatorioFluxoCaixa!['totalSaidas'] ?? 0)),
                  _buildStatCard('Saldo Final', formatCurrency(_relatorioFluxoCaixa!['saldoFinal'] ?? 0)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (_relatorioMetodoPagamento.isNotEmpty) ...[
            _buildCard(
              title: 'Por Método de Pagamento',
              child: _buildDataTable(
                columns: const ['Método', 'Quantidade', 'Valor Total'],
                rows: _relatorioMetodoPagamento.map((item) => [
                  item['metodoPagamento'] ?? '-',
                  '${item['quantidade'] ?? 0}',
                  formatCurrency(item['valorTotal'] ?? 0),
                ]).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== ABA CLIENTES ====================
  Widget _buildTabClientes() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_relatorioClientesGasto.isNotEmpty) ...[
            _buildCard(
              title: 'Clientes por Gasto Total',
              child: _buildDataTable(
                columns: const ['#', 'Cliente', 'Telefone', 'OS', 'Total Gasto'],
                rows: _relatorioClientesGasto.asMap().entries.map((e) => [
                  '${e.key + 1}',
                  e.value['nome'] ?? '-',
                  e.value['telefone'] ?? '-',
                  '${e.value['quantidadeOs'] ?? 0}',
                  formatCurrency(e.value['totalGasto'] ?? 0),
                ]).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (_relatorioClientesQuantidade.isNotEmpty) ...[
            _buildCard(
              title: 'Clientes por Quantidade de OS',
              child: _buildDataTable(
                columns: const ['#', 'Cliente', 'Telefone', 'OS', 'Valor Total', 'Última OS'],
                rows: _relatorioClientesQuantidade.asMap().entries.map((e) => [
                  '${e.key + 1}',
                  e.value['nome'] ?? '-',
                  e.value['telefone'] ?? '-',
                  '${e.value['quantidadeOs'] ?? 0}',
                  formatCurrency(e.value['valorTotal'] ?? 0),
                  e.value['ultimaOs'] ?? '-',
                ]).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (_relatorioContatos.isNotEmpty) ...[
            _buildCard(
              title: 'Lista de Contatos',
              child: _buildDataTable(
                columns: const ['Cliente', 'Telefone'],
                rows: _relatorioContatos.map((item) => [
                  item['nome'] ?? '-',
                  item['telefone'] ?? '-',
                ]).toList(),
              ),
            ),
          ],
          if (_relatorioClientesGasto.isEmpty && _relatorioClientesQuantidade.isEmpty && _relatorioContatos.isEmpty)
            _buildEmpty('Nenhum cliente encontrado.'),
        ],
      ),
    );
  }

  // ==================== ABA ESTOQUE ====================
  Widget _buildTabEstoque() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_relatorioValuationEstoque != null) ...[
            _buildCard(
              title: 'Valuation de Estoque',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatCard('Itens Cadastrados', '${_relatorioValuationEstoque!['totalItens'] ?? 0}'),
                  _buildStatCard('Qtd. Total', '${_relatorioValuationEstoque!['totalQuantidade'] ?? 0}'),
                  _buildStatCard('Valor de Venda', formatCurrency(_relatorioValuationEstoque!['valorTotalEstoque'] ?? 0)),
                  _buildStatCard('Custo Total', formatCurrency(_relatorioValuationEstoque!['custoTotal'] ?? 0)),
                  _buildStatCard('Margem Estimada', '${(_relatorioValuationEstoque!['margemEstimada'] ?? 0).toStringAsFixed != null ? double.tryParse(_relatorioValuationEstoque!['margemEstimada'].toString())?.toStringAsFixed(1) ?? "0.0" : "0.0"}%'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (_relatorioEstoqueBaixo.isNotEmpty) ...[
            _buildCard(
              title: 'Itens com Estoque Baixo',
              child: _buildDataTable(
                columns: const ['Código', 'Nome', 'Categoria', 'Atual', 'Mínimo'],
                rows: _relatorioEstoqueBaixo.map((item) => [
                  item['codigo'] ?? '-',
                  item['nome'] ?? '-',
                  item['categoria'] ?? '-',
                  '${item['quantidadeAtual'] ?? 0}',
                  '${item['quantidadeMinima'] ?? 0}',
                ]).toList(),
                rowColor: (i) {
                  final atual = _relatorioEstoqueBaixo[i]['quantidadeAtual'] ?? 0;
                  final min = _relatorioEstoqueBaixo[i]['quantidadeMinima'] ?? 0;
                  return (atual as num) < (min as num)
                      ? AppColors.error.withValues(alpha: 0.08)
                      : null;
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (_relatorioMovimentacoes.isNotEmpty) ...[
            _buildCard(
              title: 'Movimentações de Estoque',
              child: _buildDataTable(
                columns: const ['Item', 'Código', 'Tipo', 'Qtd', 'Anterior', 'Atual', 'Motivo', 'Data'],
                rows: _relatorioMovimentacoes.map((item) => [
                  item['itemNome'] ?? '-',
                  item['itemCodigo'] ?? '-',
                  item['tipoMovimentacao'] ?? '-',
                  '${item['quantidade'] ?? 0}',
                  '${item['saldoAnterior'] ?? 0}',
                  '${item['saldoAtual'] ?? 0}',
                  item['motivo'] ?? '-',
                  item['data'] != null ? _formatDate(item['data'].toString()) : '-',
                ]).toList(),
              ),
            ),
          ],
          if (_relatorioValuationEstoque == null && _relatorioEstoqueBaixo.isEmpty && _relatorioMovimentacoes.isEmpty)
            _buildEmpty('Nenhum dado de estoque encontrado.'),
        ],
      ),
    );
  }

  // ==================== WIDGETS AUXILIARES ====================

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: UpperText(title,
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UpperText(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          UpperText(value,
              style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildDataTable({
    required List<String> columns,
    required List<List<dynamic>> rows,
    Color? Function(int index)? rowColor,
  }) {
    if (rows.isEmpty) return _buildEmpty('Sem dados para exibir.');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.background),
        dataRowMinHeight: 40,
        dataRowMaxHeight: 48,
        columnSpacing: 24,
        columns: columns
            .map((c) => DataColumn(
                  label: UpperText(c,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                ))
            .toList(),
        rows: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          return DataRow(
            color: rowColor != null
                ? WidgetStateProperty.resolveWith((_) => rowColor(i))
                : null,
            cells: row
                .map((cell) => DataCell(UpperText('${cell ?? '-'}',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textPrimary))))
                .toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmpty(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: UpperText(msg,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}
