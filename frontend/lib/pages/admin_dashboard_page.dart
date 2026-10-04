import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/upper_text.dart';
import '../mixins/auth_error_mixin.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with AuthErrorMixin {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  List<Map<String, dynamic>> _usuarios = [];
  List<Map<String, dynamic>> _filtered = [];
  Map<String, dynamic> _assinaturas = {};
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String _planFilter = 'TODOS';
  String _statusFilter = 'TODOS';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userService = UserService(token: safeToken);
      final data = await userService.getAdminDashboard();
      setState(() {
        _usuarios = List<Map<String, dynamic>>.from(data['usuarios'] ?? []);
        _assinaturas = Map<String, dynamic>.from(data['assinaturas'] ?? {});
        _applyFilters();
        _loading = false;
      });
    } catch (e) {
      if (!handleAuthError(e)) {
        setState(() {
          _error = 'Falha ao carregar dados administrativos: $e';
          _loading = false;
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filtered = _usuarios.where((u) {
        final matchesSearch = _searchQuery.isEmpty ||
            (u['nome'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (u['email'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (u['nomeOficina'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesPlan = _planFilter == 'TODOS' || (u['plano'] ?? '') == _planFilter;

        final matchesStatus = _statusFilter == 'TODOS' ||
            (_statusFilter == 'ATIVO' && u['ativo'] == true) ||
            (_statusFilter == 'INATIVO' && u['ativo'] != true);

        return matchesSearch && matchesPlan && matchesStatus;
      }).toList();
    });
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    try {
      final dateTime = DateTime.parse(value.toString());
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (_) {
      return value.toString();
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty) return;
    final ddiPhone = cleanPhone.length == 11 ? '55$cleanPhone' : cleanPhone;
    final url = 'https://wa.me/$ddiPhone';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: UpperText('Não foi possível abrir o WhatsApp: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text, String fieldName) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: UpperText('$fieldName copiado para a área de transferência!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1024;
    final pagePadding = isMobile ? 16.0 : 24.0;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                        const SizedBox(height: 16),
                        UpperText(_error!, style: GoogleFonts.inter(fontSize: 16), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadDashboardData,
                          icon: const Icon(Icons.refresh),
                          label: const UpperText('Tentar Novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  color: AppColors.primary,
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: ListView(
                      controller: _scrollController,
                      padding: EdgeInsets.all(pagePadding),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        _buildHeader(isMobile),
                        const SizedBox(height: 24),
                        _buildMetricsGrid(isMobile),
                        const SizedBox(height: 24),
                        _buildFilterBar(isMobile),
                        const SizedBox(height: 16),
                        if (_filtered.isEmpty)
                          _buildEmptyState()
                        else if (isMobile)
                          _buildMobileList()
                        else
                          _buildDesktopTable(pagePadding),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final headerText = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UpperText(
          'Administração do Sistema',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 20 : 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        UpperText(
          'Visão geral das assinaturas e usuários cadastrados',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    if (isMobile) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: headerText),
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: AppColors.primary),
            onPressed: _loadDashboardData,
            tooltip: 'Sincronizar Dados',
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: headerText),
        IconButton(
          icon: const Icon(Icons.sync_rounded, color: AppColors.primary),
          onPressed: _loadDashboardData,
          tooltip: 'Sincronizar Dados',
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(bool isMobile) {
    final total = _usuarios.length;
    final ativos = _usuarios.where((u) => u['ativo'] == true).length;
    final premium = _usuarios.where((u) => u['plano'] == 'PREMIUM' || u['plano'] == 'PRO_PLUS').length;
    final free = _usuarios.where((u) => u['plano'] == 'FREE').length;
    final assinaturasEmDia = (_assinaturas['ativas'] ?? 0).toString();
    final inadimplentes = (_assinaturas['inadimplentes'] ?? 0).toString();

    return GridView.count(
      crossAxisCount: isMobile ? 2 : 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isMobile ? 1.5 : 1.9,
      children: [
        _buildMetricCard('Total Usuários', total.toString(), Icons.people_rounded, AppColors.info),
        _buildMetricCard('Contas Ativas', ativos.toString(), Icons.check_circle_rounded, AppColors.success),
        _buildMetricCard('Planos Pagos (Pro+)', premium.toString(), Icons.workspace_premium_rounded, AppColors.primary),
        _buildMetricCard('Plano Gratuito', free.toString(), Icons.money_off_rounded, AppColors.textSecondary),
        _buildMetricCard('Assinaturas em Dia', assinaturasEmDia, Icons.verified_rounded, AppColors.success),
        _buildMetricCard('Inadimplentes', inadimplentes, Icons.warning_amber_rounded, AppColors.error),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: UpperText(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(icon, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 4),
            UpperText(
              value,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(bool isMobile) {
    final searchField = TextField(
      onChanged: (val) {
        _searchQuery = val;
        _applyFilters();
      },
      decoration: InputDecoration(
        hintText: 'Buscar por nome, email ou oficina...',
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );

    final filters = Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildDropdownFilter(
          label: 'Plano',
          value: _planFilter,
          items: const ['TODOS', 'FREE', 'PRO', 'PRO_PLUS', 'PREMIUM'],
          onChanged: (val) {
            if (val != null) {
              _planFilter = val;
              _applyFilters();
            }
          },
        ),
        _buildDropdownFilter(
          label: 'Status',
          value: _statusFilter,
          items: const ['TODOS', 'ATIVO', 'INATIVO'],
          onChanged: (val) {
            if (val != null) {
              _statusFilter = val;
              _applyFilters();
            }
          },
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 12),
          filters,
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: searchField,
        ),
        const SizedBox(width: 12),
        filters,
      ],
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          dropdownColor: AppColors.surface,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: UpperText(item),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.people_outline_rounded, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 16),
          UpperText(
            'Nenhum usuário encontrado para os filtros selecionados.',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final u = _filtered[index];
        final plano = (u['plano'] ?? 'FREE').toString();
        final role = (u['role'] ?? 'OFICINA').toString();
        final ativo = u['ativo'] == true;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: UpperText(
                        u['nome'] ?? '-',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                    _buildStatusChip(plano, isPlano: true),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.storefront_rounded, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: UpperText(
                        u['nomeOficina'] ?? 'Sem oficina',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _copyToClipboard(u['email'] ?? '', 'Email'),
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          u['email'] ?? '-',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.info),
                        ),
                      ),
                      const Icon(Icons.copy_rounded, size: 12, color: AppColors.textMuted),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _launchWhatsApp(u['telefone'] ?? ''),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_android_rounded, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: UpperText(
                          u['telefone'] ?? '-',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.success),
                        ),
                      ),
                      const Icon(Icons.chat_rounded, size: 12, color: AppColors.success),
                    ],
                  ),
                ),
                const Divider(height: 20),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatusChip(role, isRole: true),
                        const SizedBox(width: 8),
                        _buildStatusChip(ativo ? 'ATIVO' : 'INATIVO'),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        UpperText(
                          _formatDate(u['criadoEm']),
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                        ),
                        const SizedBox(width: 4),
                        _buildAcoesMenu(u),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(double pagePadding) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
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
              horizontalMargin: 16,
              columns: const [
                DataColumn(label: UpperText('NOME')),
                DataColumn(label: UpperText('EMAIL')),
                DataColumn(label: UpperText('TELEFONE')),
                DataColumn(label: UpperText('OFICINA')),
                DataColumn(label: UpperText('PERMISSÃO')),
                DataColumn(label: UpperText('PLANO')),
                DataColumn(label: UpperText('STATUS')),
                DataColumn(label: UpperText('CADASTRO')),
                DataColumn(label: UpperText('AÇÕES')),
              ],
            rows: _filtered.map((u) {
              final plano = (u['plano'] ?? 'FREE').toString();
              final role = (u['role'] ?? 'OFICINA').toString();
              final ativo = u['ativo'] == true;

              return DataRow(
                cells: [
                  DataCell(
                    UpperText(
                      u['nome'] ?? '-',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          u['email'] ?? '-',
                          style: GoogleFonts.inter(color: AppColors.textPrimary),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.textMuted),
                          onPressed: () => _copyToClipboard(u['email'] ?? '', 'Email'),
                          tooltip: 'Copiar Email',
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        UpperText(u['telefone'] ?? '-'),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.chat_rounded, size: 14, color: AppColors.success),
                          onPressed: () => _launchWhatsApp(u['telefone'] ?? ''),
                          tooltip: 'Abrir no WhatsApp',
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  DataCell(UpperText(u['nomeOficina'] ?? '-')),
                  DataCell(_buildStatusChip(role, isRole: true)),
                  DataCell(_buildStatusChip(plano, isPlano: true)),
                  DataCell(_buildStatusChip(ativo ? 'ATIVO' : 'INATIVO')),
                  DataCell(UpperText(_formatDate(u['criadoEm']))),
                  DataCell(_buildAcoesMenu(u)),
                ],
              );
            }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  /// Menu de ações administrativas por usuário.
  Widget _buildAcoesMenu(Map<String, dynamic> u) {
    final ativo = u['ativo'] == true;
    final isAdmin = (u['role'] ?? '').toString().toUpperCase() == 'ADMIN';
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
      tooltip: 'Ações',
      onSelected: (v) {
        switch (v) {
          case 'ativo':
            _confirmarAtivo(u, !ativo);
            break;
          case 'plano':
            _dialogPlano(u);
            break;
          case 'papel':
            _dialogPapel(u);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'ativo',
          enabled: !isAdmin,
          child: Row(
            children: [
              Icon(ativo ? Icons.block_rounded : Icons.check_circle_rounded,
                  size: 18, color: ativo ? AppColors.error : AppColors.success),
              const SizedBox(width: 10),
              Text(ativo ? 'Inativar conta' : 'Ativar conta'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'plano',
          child: Row(
            children: [
              Icon(Icons.workspace_premium_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Alterar plano'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'papel',
          enabled: !isAdmin,
          child: const Row(
            children: [
              Icon(Icons.badge_rounded, size: 18, color: AppColors.info),
              SizedBox(width: 10),
              Text('Alterar papel'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmarAtivo(Map<String, dynamic> u, bool ativar) async {
    final nome = (u['nome'] ?? u['email'] ?? 'usuário').toString();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ativar ? 'Ativar conta' : 'Inativar conta'),
        content: Text(ativar
            ? 'Reativar o acesso de "$nome"?'
            : 'Inativar "$nome"? As sessões abertas serão encerradas e a pessoa não conseguirá entrar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: ativar ? AppColors.success : AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ativar ? 'Ativar' : 'Inativar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _executarAcao(() =>
        UserService(token: safeToken).adminDefinirAtivo(u['id'] as int, ativar));
  }

  Future<void> _dialogPlano(Map<String, dynamic> u) async {
    const planos = ['FREE', 'PRO', 'PRO_PLUS', 'PREMIUM'];
    String selecionado = (u['plano'] ?? 'FREE').toString().toUpperCase();
    if (!planos.contains(selecionado)) selecionado = 'FREE';
    final escolha = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Alterar plano'),
          content: RadioGroup<String>(
            groupValue: selecionado,
            onChanged: (v) => setLocal(() => selecionado = v!),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: planos
                  .map((p) => RadioListTile<String>(
                        value: p,
                        title: Text(p),
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, selecionado),
                child: const Text('Salvar')),
          ],
        ),
      ),
    );
    if (escolha == null) return;
    await _executarAcao(() =>
        UserService(token: safeToken).adminDefinirPlano(u['id'] as int, escolha));
  }

  Future<void> _dialogPapel(Map<String, dynamic> u) async {
    const papeis = ['GERENTE', 'ATENDENTE', 'MECANICO'];
    String selecionado = (u['role'] ?? 'MECANICO').toString().toUpperCase();
    if (!papeis.contains(selecionado)) selecionado = 'MECANICO';
    final escolha = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Alterar papel'),
          content: RadioGroup<String>(
            groupValue: selecionado,
            onChanged: (v) => setLocal(() => selecionado = v!),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'DONO e ADMIN não são alteráveis por aqui.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
                ...papeis.map((p) => RadioListTile<String>(
                      value: p,
                      title: Text(p),
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, selecionado),
                child: const Text('Salvar')),
          ],
        ),
      ),
    );
    if (escolha == null) return;
    await _executarAcao(() =>
        UserService(token: safeToken).adminDefinirPapel(u['id'] as int, escolha));
  }

  /// Executa uma ação admin, mostra feedback e recarrega a lista.
  Future<void> _executarAcao(Future<Map<String, dynamic>> Function() acao) async {
    try {
      await acao();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Alteração aplicada com sucesso.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      await _loadDashboardData();
    } catch (e) {
      if (handleAuthError(e)) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Widget _buildStatusChip(String value, {bool isPlano = false, bool isRole = false}) {
    Color bg = AppColors.surfaceVariant;
    Color fg = AppColors.textPrimary;

    if (isRole) {
      if (value == 'ADMIN') {
        bg = AppColors.error.withValues(alpha: 0.15);
        fg = AppColors.error;
      } else {
        bg = AppColors.textSecondary.withValues(alpha: 0.1);
        fg = AppColors.textSecondary;
      }
    } else if (isPlano) {
      if (value == 'FREE') {
        bg = AppColors.textSecondary.withValues(alpha: 0.1);
        fg = AppColors.textSecondary;
      } else if (value == 'PRO') {
        bg = AppColors.info.withValues(alpha: 0.15);
        fg = AppColors.info;
      } else if (value == 'PRO_PLUS' || value == 'PREMIUM') {
        bg = AppColors.primary.withValues(alpha: 0.15);
        fg = AppColors.accentLight;
      }
    } else {
      if (value == 'ATIVO') {
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.success;
      } else {
        bg = AppColors.error.withValues(alpha: 0.15);
        fg = AppColors.error;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: UpperText(
        value,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
