import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/relatorio_service.dart';
import '../theme/app_theme.dart';
import '../mixins/auth_error_mixin.dart';
import '../utils/formatters.dart';
import '../utils/file_download.dart';

/// Página de Relatórios do sistema
class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({super.key});

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage>
    with SingleTickerProviderStateMixin, AuthErrorMixin {
  late TabController _tabController;
  bool _loading = false;
  bool _exportando = false;
  String? _error;

  // Período padrão: último mês
  late DateTime _dataInicio;
  late DateTime _dataFim;

  // Dados dos relatórios
  Map<String, dynamic>? _relatorioOsPeriodo;
  List<Map<String, dynamic>> _relatorioOsMecanico = [];
  List<Map<String, dynamic>> _relatorioOsVeiculo = [];
  List<Map<String, dynamic>> _relatorioOsCliente = [];
  Map<String, dynamic>? _relatorioReceitas;
  Map<String, dynamic>? _relatorioDespesas;
  Map<String, dynamic>? _relatorioFluxoCaixa;
  List<Map<String, dynamic>> _relatorioMetodoPagamento = [];
  List<Map<String, dynamic>> _relatorioClientesGasto = [];
  List<Map<String, dynamic>> _relatorioEstoqueBaixo = [];
  Map<String, dynamic>? _relatorioValuationEstoque;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Período padrão: mês atual
    final now = DateTime.now();
    _dataInicio = DateTime(now.year, now.month, 1);
    _dataFim = DateTime(now.year, now.month + 1, 0);

    _carregarRelatorios();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _token =>
      Provider.of<AuthService>(context, listen: false).token ?? '';

  String get _tipoExportacaoAtual {
    switch (_tabController.index) {
      case 0:
        return 'os';
      case 1:
        return 'financeiro';
      case 2:
        return 'clientes';
      case 3:
        return 'estoque';
      default:
        return 'os';
    }
  }

  Future<void> _exportarRelatorio(String formato) async {
    if (_exportando) return;
    setState(() => _exportando = true);
    try {
      final relatorioService = RelatorioService(token: _token);
      final arquivo = await relatorioService.exportarRelatorio(
        formato: formato,
        tipo: _tipoExportacaoAtual,
        inicio: _dataInicio,
        fim: _dataFim,
        formatoPdf: 'resumido',
      );

      saveBytesAsFile(arquivo.bytes, arquivo.filename, arquivo.contentType);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Relatório exportado: ${arquivo.filename}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar relatório: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _carregarRelatorios() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final relatorioService = RelatorioService(token: _token);

      // Carregar relatórios baseados na aba atual
      switch (_tabController.index) {
        case 0: // OS
          await Future.wait([
            relatorioService
                .getRelatorioOsPeriodo(_dataInicio, _dataFim, null)
                .then((r) => setState(() => _relatorioOsPeriodo = r)),
            relatorioService
                .getRelatorioOsPorMecanico(_dataInicio, _dataFim)
                .then((r) => setState(() => _relatorioOsMecanico = r)),
            relatorioService
                .getRelatorioOsPorVeiculo(_dataInicio, _dataFim)
                .then((r) => setState(() => _relatorioOsVeiculo = r)),
            relatorioService
                .getRelatorioOsPorCliente(_dataInicio, _dataFim)
                .then((r) => setState(() => _relatorioOsCliente = r)),
          ]);
          break;
        case 1: // Financeiro
          await Future.wait([
            relatorioService
                .getRelatorioReceitas(_dataInicio, _dataFim)
                .then((r) => setState(() => _relatorioReceitas = r)),
            relatorioService
                .getRelatorioDespesas(_dataInicio, _dataFim)
                .then((r) => setState(() => _relatorioDespesas = r)),
            relatorioService
                .getRelatorioFluxoCaixa(_dataInicio, _dataFim)
                .then((r) => setState(() => _relatorioFluxoCaixa = r)),
            relatorioService
                .getRelatorioPorMetodoPagamento(_dataInicio, _dataFim)
                .then((r) => setState(() => _relatorioMetodoPagamento = r)),
          ]);
          break;
        case 2: // Clientes
          await Future.wait([
            relatorioService
                .getRelatorioClientesPorGasto(limite: 20)
                .then((r) => setState(() => _relatorioClientesGasto = r)),
          ]);
          break;
        case 3: // Estoque
          await Future.wait([
            relatorioService
                .getRelatorioValuationEstoque()
                .then((r) => setState(() => _relatorioValuationEstoque = r)),
            relatorioService
                .getRelatorioEstoqueBaixo(limite: 20)
                .then((r) => setState(() => _relatorioEstoqueBaixo = r)),
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dataInicio = picked.start;
        _dataFim = picked.end;
      });
      _carregarRelatorios();
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
                      Text(
                        'Relatórios',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${formatDateBR(_dataInicio)} - ${formatDateBR(_dataFim)}',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _selecionarPeriodo,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('Período'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _loading ? null : _carregarRelatorios,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh, size: 18),
                  label: const Text('Atualizar'),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  tooltip: 'Exportar relatório',
                  enabled: !_loading && !_exportando,
                  onSelected: _exportarRelatorio,
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'pdf',
                      child: ListTile(
                        leading: Icon(Icons.picture_as_pdf_outlined),
                        title: Text('Exportar PDF'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'excel',
                      child: ListTile(
                        leading: Icon(Icons.table_chart_outlined),
                        title: Text('Exportar Excel'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'csv',
                      child: ListTile(
                        leading: Icon(Icons.description_outlined),
                        title: Text('Exportar CSV'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_exportando)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          const Icon(Icons.download_rounded,
                              size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          _exportando ? 'Exportando...' : 'Exportar',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(_error!,
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 12),
                        FilledButton(
                            onPressed: _carregarRelatorios,
                            child: const Text('Tentar novamente')),
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
    );
  }

  Widget _buildTabOs() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accent));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumo
          if (_relatorioOsPeriodo != null) ...[
            _buildCard(
              title: 'Resumo de OS',
              child: Row(
                children: [
                  _buildStatCard(
                      'Total', '${_relatorioOsPeriodo!['totalOs'] ?? 0}'),
                  _buildStatCard(
                      'Abertas', '${_relatorioOsPeriodo!['osAbertas'] ?? 0}'),
                  _buildStatCard('Em Andamento',
                      '${_relatorioOsPeriodo!['osEmAndamento'] ?? 0}'),
                  _buildStatCard('Concluídas',
                      '${_relatorioOsPeriodo!['osConcluidas'] ?? 0}'),
                  _buildStatCard('Valor Total',
                      formatCurrency(_relatorioOsPeriodo!['valorTotal'] ?? 0)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Por Mecânico
          if (_relatorioOsMecanico.isNotEmpty) ...[
            _buildCard(
              title: 'OS por Mecânico',
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Mecânico')),
                  DataColumn(label: Text('Quantidade'), numeric: true),
                  DataColumn(label: Text('Valor Total'), numeric: true),
                ],
                rows: _relatorioOsMecanico
                    .map((item) => DataRow(cells: [
                          DataCell(Text(item['mecanico'] ?? '-')),
                          DataCell(Text('${item['quantidade'] ?? 0}')),
                          DataCell(
                              Text(formatCurrency(item['valorTotal'] ?? 0))),
                        ]))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Por Veículo
          if (_relatorioOsVeiculo.isNotEmpty) ...[
            _buildCard(
              title: 'OS por Veículo',
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Veículo')),
                  DataColumn(label: Text('Placa')),
                  DataColumn(label: Text('Quantidade'), numeric: true),
                ],
                rows: _relatorioOsVeiculo
                    .map((item) => DataRow(cells: [
                          DataCell(Text(item['veiculo'] ?? '-')),
                          DataCell(Text(item['placa'] ?? '-')),
                          DataCell(Text('${item['quantidade'] ?? 0}')),
                        ]))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Por Cliente
          if (_relatorioOsCliente.isNotEmpty) ...[
            _buildCard(
              title: 'OS por Cliente',
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Cliente')),
                  DataColumn(label: Text('Quantidade'), numeric: true),
                  DataColumn(label: Text('Valor Total'), numeric: true),
                ],
                rows: _relatorioOsCliente
                    .map((item) => DataRow(cells: [
                          DataCell(Text(item['cliente'] ?? '-')),
                          DataCell(Text('${item['quantidade'] ?? 0}')),
                          DataCell(
                              Text(formatCurrency(item['valorTotal'] ?? 0))),
                        ]))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabFinanceiro() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accent));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumo Financeiro
          Row(
            children: [
              if (_relatorioReceitas != null)
                Expanded(
                  child: _buildCard(
                    title: 'Receitas',
                    child: Text(
                      formatCurrency(_relatorioReceitas!['totalReceitas'] ?? 0),
                      style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success),
                    ),
                  ),
                ),
              if (_relatorioReceitas != null && _relatorioDespesas != null)
                const SizedBox(width: 16),
              if (_relatorioDespesas != null)
                Expanded(
                  child: _buildCard(
                    title: 'Despesas',
                    child: Text(
                      formatCurrency(_relatorioDespesas!['totalDespesas'] ?? 0),
                      style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          // Fluxo de Caixa
          if (_relatorioFluxoCaixa != null) ...[
            _buildCard(
              title: 'Fluxo de Caixa',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                            'Saldo Inicial',
                            formatCurrency(
                                _relatorioFluxoCaixa!['saldoInicial'] ?? 0)),
                      ),
                      Expanded(
                        child: _buildStatCard(
                            'Total Entradas',
                            formatCurrency(
                                _relatorioFluxoCaixa!['totalEntradas'] ?? 0)),
                      ),
                      Expanded(
                        child: _buildStatCard(
                            'Total Saídas',
                            formatCurrency(
                                _relatorioFluxoCaixa!['totalSaidas'] ?? 0)),
                      ),
                      Expanded(
                        child: _buildStatCard(
                            'Saldo Final',
                            formatCurrency(
                                _relatorioFluxoCaixa!['saldoFinal'] ?? 0)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Por Método de Pagamento
          if (_relatorioMetodoPagamento.isNotEmpty) ...[
            _buildCard(
              title: 'Por Método de Pagamento',
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Método')),
                  DataColumn(label: Text('Quantidade'), numeric: true),
                  DataColumn(label: Text('Valor Total'), numeric: true),
                ],
                rows: _relatorioMetodoPagamento
                    .map((item) => DataRow(cells: [
                          DataCell(Text(item['metodoPagamento'] ?? '-')),
                          DataCell(Text('${item['quantidade'] ?? 0}')),
                          DataCell(
                              Text(formatCurrency(item['valorTotal'] ?? 0))),
                        ]))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabClientes() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accent));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clientes por Gasto
          if (_relatorioClientesGasto.isNotEmpty) ...[
            _buildCard(
              title: 'Clientes por Gasto Total',
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Cliente')),
                  DataColumn(label: Text('OS'), numeric: true),
                  DataColumn(label: Text('Total Gasto'), numeric: true),
                ],
                rows: _relatorioClientesGasto
                    .map((item) => DataRow(cells: [
                          DataCell(Text(item['cliente'] ?? '-')),
                          DataCell(Text('${item['quantidadeOs'] ?? 0}')),
                          DataCell(
                              Text(formatCurrency(item['totalGasto'] ?? 0))),
                        ]))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabEstoque() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accent));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Valuation
          if (_relatorioValuationEstoque != null) ...[
            _buildCard(
              title: 'Valuation de Estoque',
              child: Row(
                children: [
                  _buildStatCard(
                    'Valor Total',
                    formatCurrency(
                        _relatorioValuationEstoque!['valorTotal'] ?? 0),
                  ),
                  _buildStatCard(
                    'Quantidade Items',
                    '${_relatorioValuationEstoque!['quantidadeItens'] ?? 0}',
                  ),
                  _buildStatCard(
                    'Custo Total',
                    formatCurrency(
                        _relatorioValuationEstoque!['custoTotal'] ?? 0),
                  ),
                  _buildStatCard(
                    'Margem',
                    '${_relatorioValuationEstoque!['margemPercentual'] ?? 0}%',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Estoque Baixo
          if (_relatorioEstoqueBaixo.isNotEmpty) ...[
            _buildCard(
              title: 'Itens com Estoque Baixo',
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Código')),
                  DataColumn(label: Text('Nome')),
                  DataColumn(label: Text('Quantidade'), numeric: true),
                  DataColumn(label: Text('Mínimo'), numeric: true),
                ],
                rows: _relatorioEstoqueBaixo
                    .map((item) => DataRow(
                          cells: [
                            DataCell(Text(item['codigo'] ?? '-')),
                            DataCell(Text(item['nome'] ?? '-')),
                            DataCell(Text('${item['quantidade'] ?? 0}')),
                            DataCell(Text('${item['quantidadeMinima'] ?? 0}')),
                          ],
                          color: WidgetStateProperty.all(
                            (item['quantidade'] ?? 0) <
                                    (item['quantidadeMinima'] ?? 0)
                                ? AppColors.error.withValues(alpha: 0.1)
                                : null,
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style:
                GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
