import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/os_service.dart';
import '../theme/app_theme.dart';
import 'os_form_page.dart';
import 'os_detail_page.dart';
import '../mixins/auth_error_mixin.dart';
import '../utils/formatters.dart';
import '../widgets/upper_text.dart';

/// Lista de OS com layout moderno — sem AppBar, renderiza dentro do AppShell.
class OsListPage extends StatefulWidget {
  const OsListPage({super.key});

  @override
  State<OsListPage> createState() => _OsListPageState();
}

class _OsListPageState extends State<OsListPage> with AuthErrorMixin {
  List<Map<String, dynamic>> _ordens = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String _statusFilter = 'TODOS';
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _loadOrdens();
  }

  Future<void> _loadOrdens() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final osService = OsService(token: safeToken);
      final ordens = await osService.listar();
      setState(() {
        _ordens = ordens;
        _applyFilters();
        _loading = false;
      });
    } catch (e) {
      if (!handleAuthError(e)) {
        setState(() {
          _error = 'Erro ao carregar ordens de serviço';
          _loading = false;
        });
      }
    }
  }

  void _applyFilters() {
    _filtered = _ordens.where((os) {
      final matchesSearch = _searchQuery.isEmpty ||
          (os['clienteNome'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (os['placa'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (os['modelo'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      final matchesStatus =
          _statusFilter == 'TODOS' || os['status'] == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _excluirOs(Map<String, dynamic> os) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: UpperText('Excluir Ordem de Serviço',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: UpperText(
          'Tem certeza que deseja excluir a OS do cliente "${os['clienteNome'] ?? '-'}" (placa ${os['placa'] ?? '-'})?\n\nEssa ação não pode ser desfeita.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const UpperText('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const UpperText('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _deleting = true);
    try {
      final osService = OsService(token: safeToken);
      await osService.excluir(os['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: UpperText('OS excluída com sucesso'),
              backgroundColor: AppColors.success),
        );
        _loadOrdens();
      }
    } catch (e) {
      if (!handleAuthError(e) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: UpperText('Erro ao excluir: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _deleting = false);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ABERTA':
        return const Color(0xFFF59E0B);
      case 'EM_ANDAMENTO':
        return const Color(0xFF3B82F6);
      case 'AGUARDANDO_PECA':
        return const Color(0xFF8B5CF6);
      case 'AGUARDANDO_APROVACAO':
        return const Color(0xFFF97316);
      case 'CONCLUIDA':
        return const Color(0xFF10B981);
      case 'CANCELADA':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ABERTA':
        return 'Aberta';
      case 'EM_ANDAMENTO':
        return 'Em Andamento';
      case 'AGUARDANDO_PECA':
        return 'Aguardando Peça';
      case 'AGUARDANDO_APROVACAO':
        return 'Ag. Aprovação';
      case 'CONCLUIDA':
        return 'Concluída';
      case 'CANCELADA':
        return 'Cancelada';
      default:
        return status;
    }
  }


  Future<void> _abrirNovaOs() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OsFormPage()),
    );
    if (!mounted) return;
    _loadOrdens();
  }

  Future<void> _abrirDetalhes(Map<String, dynamic> os) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OsDetailPage(osData: os)),
    );
    if (!mounted) return;
    if (result != null) _loadOrdens();
  }

  Future<void> _abrirEdicao(Map<String, dynamic> os) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OsFormPage(osData: os)),
    );
    if (!mounted) return;
    _loadOrdens();
  }

  Widget _buildStatusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: UpperText(
        _statusLabel(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildOsCard(Map<String, dynamic> os) {
    final status = (os['status'] ?? 'ABERTA').toString();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: UpperText(
                            formatOsNumber(os['numero'] ?? os['id']),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: UpperText(
                            os['clienteNome'] ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    UpperText(
                      '${os['modelo'] ?? '-'} ${os['ano'] ?? ''}'.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusChip(status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: UpperText(
                  'Placa: ${os['placa'] ?? '-'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              UpperText(
                formatCurrency(os['valor'] ?? 0),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _abrirDetalhes(os),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const UpperText('Ver'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _abrirEdicao(os),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const UpperText('Editar'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _deleting ? null : () => _excluirOs(os),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: _deleting ? AppColors.textMuted : AppColors.error,
                ),
                tooltip: 'Excluir',
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 640;
    final pagePadding = isCompact ? 16.0 : 32.0;

    Widget searchAndFilter() {
      final search = TextField(
        onChanged: (v) {
          if (!mounted) return;
          setState(() {
            _searchQuery = v;
            _applyFilters();
          });
        },
        decoration: InputDecoration(
          hintText: isCompact ? 'Buscar OS...' : 'Buscar por cliente, placa ou modelo...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          filled: true,
          fillColor: AppColors.surfaceVariant,
        ),
      );

      final filter = DropdownButtonFormField<String>(
        initialValue: _statusFilter,
        isExpanded: true,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          filled: true,
          fillColor: AppColors.surfaceVariant,
        ),
        items: const [
          DropdownMenuItem(value: 'TODOS', child: UpperText('Todos')),
          DropdownMenuItem(value: 'ABERTA', child: UpperText('Aberta')),
          DropdownMenuItem(value: 'EM_ANDAMENTO', child: UpperText('Em Andamento')),
          DropdownMenuItem(value: 'AGUARDANDO_PECA', child: UpperText('Ag. Peca')),
          DropdownMenuItem(value: 'AGUARDANDO_APROVACAO', child: UpperText('Ag. Aprovacao')),
          DropdownMenuItem(value: 'CONCLUIDA', child: UpperText('Concluida')),
          DropdownMenuItem(value: 'CANCELADA', child: UpperText('Cancelada')),
        ],
        onChanged: (v) {
          if (!mounted) return;
          setState(() {
            _statusFilter = v ?? 'TODOS';
            _applyFilters();
          });
        },
      );

      if (isCompact) {
        return Column(children: [
          search,
          const SizedBox(height: 10),
          filter,
        ]);
      }

      return Row(children: [
        Expanded(flex: 3, child: search),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: filter),
      ]);
    }

    Widget content() {
      if (_loading) {
        return const Center(child: CircularProgressIndicator(color: AppColors.accent));
      }
      if (_error != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              UpperText(_error!, style: GoogleFonts.inter(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              FilledButton(onPressed: _loadOrdens, child: const UpperText('Tentar novamente')),
            ],
          ),
        );
      }
      if (_filtered.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_rounded, size: 56, color: AppColors.textMuted),
              const SizedBox(height: 12),
              UpperText('Nenhuma OS encontrada',
                  style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary)),
            ],
          ),
        );
      }

      if (isCompact) {
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(pagePadding, 16, pagePadding, 24),
          itemCount: _filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _buildOsCard(_filtered[index]),
        );
      }

      return SingleChildScrollView(
        padding: EdgeInsets.all(pagePadding),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                headingTextStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
                dataTextStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                columnSpacing: 24,
                horizontalMargin: 20,
                columns: const [
                  DataColumn(label: UpperText('N° OS')),
                  DataColumn(label: UpperText('CLIENTE')),
                  DataColumn(label: UpperText('VEICULO')),
                  DataColumn(label: UpperText('PLACA')),
                  DataColumn(label: UpperText('STATUS')),
                  DataColumn(label: UpperText('VALOR'), numeric: true),
                  DataColumn(label: UpperText('ACOES')),
                ],
                rows: _filtered.map((os) {
                  final status = (os['status'] ?? 'ABERTA').toString();
                  return DataRow(cells: [
                    DataCell(UpperText(formatOsNumber(os['numero'] ?? os['id']),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.accent))),
                    DataCell(UpperText(os['clienteNome'] ?? '-',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                    DataCell(UpperText('${os['modelo'] ?? '-'} ${os['ano'] ?? ''}'.trim())),
                    DataCell(UpperText(os['placa'] ?? '-',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, letterSpacing: 0.5))),
                    DataCell(_buildStatusChip(status)),
                    DataCell(UpperText(formatCurrency(os['valor'] ?? 0),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
                    DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.accent),
                        onPressed: () => _abrirDetalhes(os),
                        tooltip: 'Ver Detalhes',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                        onPressed: () => _abrirEdicao(os),
                        tooltip: 'Editar',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded,
                            size: 18,
                            color: _deleting ? AppColors.textMuted : AppColors.error),
                        onPressed: _deleting ? null : () => _excluirOs(os),
                        tooltip: 'Excluir',
                      ),
                    ])),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: pagePadding, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: isCompact ? double.infinity : 260,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UpperText(
                            'Ordens de Servico',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          UpperText(
                            '${_ordens.length} registro(s)',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      OutlinedButton.icon(
                        onPressed: _loadOrdens,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const UpperText('Atualizar'),
                      ),
                      FilledButton.icon(
                        onPressed: _abrirNovaOs,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const UpperText('Nova OS'),
                      ),
                    ]),
                  ],
                ),
                const SizedBox(height: 14),
                searchAndFilter(),
              ],
            ),
          ),
          Expanded(child: content()),
        ],
      ),
    );
  }

}
