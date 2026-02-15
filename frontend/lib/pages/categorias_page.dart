import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';

/// Tela de gerenciamento de categorias financeiras.
class CategoriasPage extends StatefulWidget {
  const CategoriasPage({super.key});

  @override
  State<CategoriasPage> createState() => _CategoriasPageState();
}

class _CategoriasPageState extends State<CategoriasPage> {
  List<Map<String, dynamic>> _categorias = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategorias();
  }

  Future<void> _loadCategorias() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = FinanceService(token: auth.token!);
      final cats = await service.listarCategorias();
      setState(() {
        _categorias = cats;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar categorias';
        _loading = false;
      });
    }
  }

  Future<void> _excluir(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Categoria'),
        content: const Text('Deseja realmente excluir esta categoria?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = FinanceService(token: auth.token!);
      await service.excluirCategoria(id);
      _loadCategorias();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Categoria excluída', style: GoogleFonts.inter()),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Erro: ${e.toString().replaceAll('Exception: ', '')}',
                  style: GoogleFonts.inter()),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showCriarDialog() {
    final nomeCtrl = TextEditingController();
    String tipo = 'ENTRADA';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Nova Categoria',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nome',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: nomeCtrl,
                decoration: InputDecoration(
                  hintText: 'Nome da categoria',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Tipo',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Entrada'),
                      selected: tipo == 'ENTRADA',
                      selectedColor: AppColors.success.withOpacity(0.2),
                      onSelected: (_) => setDialogState(() => tipo = 'ENTRADA'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Saída'),
                      selected: tipo == 'SAIDA',
                      selectedColor: AppColors.error.withOpacity(0.2),
                      onSelected: (_) => setDialogState(() => tipo = 'SAIDA'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (nomeCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  final auth = Provider.of<AuthService>(context, listen: false);
                  final service = FinanceService(token: auth.token!);
                  await service.criarCategoria({
                    'nome': nomeCtrl.text.trim(),
                    'tipo': tipo,
                  });
                  _loadCategorias();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Categoria criada!',
                              style: GoogleFonts.inter()),
                          backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Erro: ${e.toString().replaceAll('Exception: ', '')}',
                              style: GoogleFonts.inter()),
                          backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entradas = _categorias.where((c) => c['tipo'] == 'ENTRADA').toList();
    final saidas = _categorias.where((c) => c['tipo'] == 'SAIDA').toList();

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
                    Text('Categorias',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text('Gerencie categorias de entradas e saídas',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _showCriarDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Nova Categoria'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
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
                            const Icon(Icons.error_outline_rounded,
                                size: 48, color: AppColors.error),
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 12),
                            FilledButton(
                                onPressed: _loadCategorias,
                                child: const Text('Tentar novamente')),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 800) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                      child: _buildSection(
                                          'Entradas',
                                          Icons.arrow_downward_rounded,
                                          AppColors.success,
                                          entradas)),
                                  const SizedBox(width: 24),
                                  Expanded(
                                      child: _buildSection(
                                          'Saídas',
                                          Icons.arrow_upward_rounded,
                                          AppColors.error,
                                          saidas)),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                _buildSection(
                                    'Entradas',
                                    Icons.arrow_downward_rounded,
                                    AppColors.success,
                                    entradas),
                                const SizedBox(height: 24),
                                _buildSection(
                                    'Saídas',
                                    Icons.arrow_upward_rounded,
                                    AppColors.error,
                                    saidas),
                              ],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Color color,
      List<Map<String, dynamic>> items) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${items.length}',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('Nenhuma categoria',
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 13)),
              ),
            )
          else
            ...items.map((cat) => _CategoriaItem(
                  cat: cat,
                  color: color,
                  onDelete: cat['sistema'] == true
                      ? null
                      : () => _excluir(cat['id'] as int),
                )),
        ],
      ),
    );
  }
}

class _CategoriaItem extends StatelessWidget {
  final Map<String, dynamic> cat;
  final Color color;
  final VoidCallback? onDelete;
  const _CategoriaItem({required this.cat, required this.color, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isSistema = cat['sistema'] == true;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.label_rounded, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat['nome'] ?? '',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                if (isSistema)
                  Text('Categoria do sistema',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (!isSistema)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 18, color: AppColors.error),
              onPressed: onDelete,
              tooltip: 'Excluir',
            ),
          if (isSistema)
            const Icon(Icons.lock_outline_rounded,
                size: 16, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
