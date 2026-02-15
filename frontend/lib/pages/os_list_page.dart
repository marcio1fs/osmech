import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/os_service.dart';
import '../theme/app_theme.dart';
import 'os_form_page.dart';

/// Lista de OS com layout moderno — sem AppBar, renderiza dentro do AppShell.
class OsListPage extends StatefulWidget {
  const OsListPage({super.key});

  @override
  State<OsListPage> createState() => _OsListPageState();
}

class _OsListPageState extends State<OsListPage> {
  List<Map<String, dynamic>> _ordens = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String _statusFilter = 'TODOS';

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
      final auth = Provider.of<AuthService>(context, listen: false);
      final osService = OsService(token: auth.token!);
      final ordens = await osService.listar();
      setState(() {
        _ordens = ordens;
        _applyFilters();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar ordens de serviço';
        _loading = false;
      });
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
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ordens de Serviço',
                            style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_ordens.length} registro(s)',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _loadOrdens,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Atualizar'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const OsFormPage()));
                        _loadOrdens();
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Nova OS'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search and filter
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        onChanged: (v) => setState(() {
                          _searchQuery = v;
                          _applyFilters();
                        }),
                        decoration: InputDecoration(
                          hintText: 'Buscar por cliente, placa ou modelo...',
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 20),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppColors.border)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppColors.border)),
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: _statusFilter,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppColors.border)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppColors.border)),
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'TODOS', child: Text('Todos')),
                          DropdownMenuItem(
                              value: 'ABERTA', child: Text('Aberta')),
                          DropdownMenuItem(
                              value: 'EM_ANDAMENTO',
                              child: Text('Em Andamento')),
                          DropdownMenuItem(
                              value: 'AGUARDANDO_PECA',
                              child: Text('Ag. Peça')),
                          DropdownMenuItem(
                              value: 'CONCLUIDA', child: Text('Concluída')),
                          DropdownMenuItem(
                              value: 'CANCELADA', child: Text('Cancelada')),
                        ],
                        onChanged: (v) => setState(() {
                          _statusFilter = v ?? 'TODOS';
                          _applyFilters();
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 48, color: AppColors.error),
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 12),
                            FilledButton(
                                onPressed: _loadOrdens,
                                child: const Text('Tentar novamente')),
                          ],
                        ),
                      )
                    : _filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inbox_rounded,
                                    size: 56, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                Text('Nenhuma OS encontrada',
                                    style: GoogleFonts.inter(
                                        fontSize: 15,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(32),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                      AppColors.surfaceVariant),
                                  headingTextStyle: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary),
                                  dataTextStyle: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textPrimary),
                                  columnSpacing: 24,
                                  horizontalMargin: 20,
                                  columns: const [
                                    DataColumn(label: Text('CLIENTE')),
                                    DataColumn(label: Text('VEÍCULO')),
                                    DataColumn(label: Text('PLACA')),
                                    DataColumn(label: Text('STATUS')),
                                    DataColumn(
                                        label: Text('VALOR'), numeric: true),
                                    DataColumn(label: Text('')),
                                  ],
                                  rows: _filtered.map((os) {
                                    final status = os['status'] ?? 'ABERTA';
                                    final color = _statusColor(status);
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(os['clienteNome'] ?? '-',
                                            style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w600))),
                                        DataCell(Text(
                                            '${os['modelo'] ?? '-'} ${os['ano'] ?? ''}'
                                                .trim())),
                                        DataCell(Text(os['placa'] ?? '-',
                                            style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5))),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              _statusLabel(status),
                                              style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: color),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(
                                          'R\$ ${(os['valor'] ?? 0).toStringAsFixed(2)}',
                                          style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700),
                                        )),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 18,
                                                color: AppColors.textSecondary),
                                            onPressed: () async {
                                              await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          OsFormPage(
                                                              osData: os)));
                                              _loadOrdens();
                                            },
                                            tooltip: 'Editar',
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
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
