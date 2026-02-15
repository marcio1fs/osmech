import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../pages/dashboard_page.dart';
import '../pages/os_list_page.dart';
import '../pages/os_form_page.dart';
import '../pages/pricing_page.dart';
import '../pages/subscription_page.dart';
import '../pages/payment_history_page.dart';
import '../pages/financial_dashboard_page.dart';
import '../pages/transacao_form_page.dart';
import '../pages/categorias_page.dart';
import '../pages/fluxo_caixa_page.dart';
import '../pages/transacoes_historico_page.dart';
import '../pages/stock_list_page.dart';
import '../pages/stock_form_page.dart';
import '../pages/stock_movement_page.dart';
import '../pages/stock_alerts_page.dart';

/// Shell principal com sidebar persistente para navegação web.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  bool _sidebarExpanded = true;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.assignment_rounded, label: 'Ordens de Serviço'),
    _NavItem(icon: Icons.add_circle_outline_rounded, label: 'Nova OS'),
    _NavItem(icon: Icons.payments_rounded, label: 'Pagamentos'),
    _NavItem(icon: Icons.card_membership_rounded, label: 'Assinatura'),
    _NavItem(
        icon: Icons.bar_chart_rounded,
        label: 'Financeiro',
        section: 'FINANCEIRO'),
    _NavItem(icon: Icons.add_card_rounded, label: 'Novo Lançamento'),
    _NavItem(icon: Icons.category_rounded, label: 'Categorias'),
    _NavItem(icon: Icons.trending_up_rounded, label: 'Fluxo de Caixa'),
    _NavItem(icon: Icons.receipt_long_rounded, label: 'Histórico'),
    _NavItem(
        icon: Icons.inventory_2_rounded, label: 'Estoque', section: 'ESTOQUE'),
    _NavItem(icon: Icons.add_box_rounded, label: 'Nova Peça'),
    _NavItem(icon: Icons.swap_vert_rounded, label: 'Movimentação'),
    _NavItem(icon: Icons.notification_important_rounded, label: 'Alertas'),
    _NavItem(
        icon: Icons.workspace_premium_rounded,
        label: 'Planos',
        section: 'CONTA'),
  ];

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return DashboardPage(
            onNavigate: (i) => setState(() => _selectedIndex = i));
      case 1:
        return const OsListPage();
      case 2:
        return OsFormPage(
          onSaved: () => setState(() => _selectedIndex = 1),
        );
      case 3:
        return const PaymentHistoryPage();
      case 4:
        return const SubscriptionPage();
      case 5:
        return FinancialDashboardPage(
          onNavigateTransacoes: () => setState(() => _selectedIndex = 9),
          onNavigateNovaTransacao: () => setState(() => _selectedIndex = 6),
          onNavigateFluxoCaixa: () => setState(() => _selectedIndex = 8),
          onNavigateCategorias: () => setState(() => _selectedIndex = 7),
        );
      case 6:
        return TransacaoFormPage(
          onSaved: () => setState(() => _selectedIndex = 9),
        );
      case 7:
        return const CategoriasPage();
      case 8:
        return const FluxoCaixaPage();
      case 9:
        return const TransacoesHistoricoPage();
      case 10:
        return StockListPage(
          onNavigateNovaPeca: () => setState(() => _selectedIndex = 11),
          onNavigateMovimentacao: () => setState(() => _selectedIndex = 12),
          onNavigateAlertas: () => setState(() => _selectedIndex = 13),
          onEditarItem: (id) {
            setState(() => _selectedIndex = 11);
          },
        );
      case 11:
        return StockFormPage(
          onSaved: () => setState(() => _selectedIndex = 10),
        );
      case 12:
        return StockMovementPage(
          onSaved: () => setState(() => _selectedIndex = 10),
        );
      case 13:
        return StockAlertsPage(
          onEntradaEstoque: (id) {
            setState(() => _selectedIndex = 12);
          },
        );
      case 14:
        return const PricingPage();
      default:
        return DashboardPage(
            onNavigate: (i) => setState(() => _selectedIndex = i));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (isMobile) {
      return _buildMobileLayout(auth);
    }
    return _buildDesktopLayout(auth);
  }

  Widget _buildDesktopLayout(AuthService auth) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _sidebarExpanded ? 260 : 72,
            decoration: const BoxDecoration(
              color: AppColors.sidebarBg,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 10,
                  offset: Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header da sidebar
                Container(
                  height: 72,
                  padding: EdgeInsets.symmetric(
                    horizontal: _sidebarExpanded ? 20 : 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.build_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      if (_sidebarExpanded) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'OSMECH',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF1E293B), height: 1),

                // Toggle sidebar
                InkWell(
                  onTap: () =>
                      setState(() => _sidebarExpanded = !_sidebarExpanded),
                  child: Container(
                    height: 44,
                    padding: EdgeInsets.symmetric(
                      horizontal: _sidebarExpanded ? 20 : 0,
                    ),
                    alignment: _sidebarExpanded
                        ? Alignment.centerRight
                        : Alignment.center,
                    child: Icon(
                      _sidebarExpanded
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      color: AppColors.sidebarText,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Nav items
                Expanded(
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: _navItems.length,
                    itemBuilder: (context, index) {
                      final item = _navItems[index];
                      final selected = _selectedIndex == index;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.section != null) ...[
                            const SizedBox(height: 8),
                            const Divider(color: Color(0xFF1E293B), height: 1),
                            if (_sidebarExpanded)
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 14, top: 12, bottom: 4),
                                child: Text(
                                  item.section!,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        AppColors.sidebarText.withOpacity(0.5),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              )
                            else
                              const SizedBox(height: 12),
                          ],
                          _SidebarItem(
                            icon: item.icon,
                            label: item.label,
                            selected: selected,
                            expanded: _sidebarExpanded,
                            onTap: () => setState(() => _selectedIndex = index),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // User section
                const Divider(color: Color(0xFF1E293B), height: 1),
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Sair'),
                        content: const Text('Deseja sair da sua conta?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              auth.logout();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
                            child: const Text('Sair'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    height: 64,
                    padding: EdgeInsets.symmetric(
                      horizontal: _sidebarExpanded ? 20 : 12,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.accent.withOpacity(0.2),
                          child: Text(
                            (auth.nome ?? 'U')[0].toUpperCase(),
                            style: GoogleFonts.inter(
                              color: AppColors.accentLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (_sidebarExpanded) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  auth.nome ?? 'Usuário',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  auth.plano ?? 'PRO',
                                  style: GoogleFonts.inter(
                                    color: AppColors.sidebarText,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.logout_rounded,
                            color: AppColors.sidebarText,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: _getPage(_selectedIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(AuthService auth) {
    return Scaffold(
      body: _getPage(_selectedIndex),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent.withOpacity(0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'OS',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle_rounded),
            label: 'Nova OS',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments_rounded),
            label: 'Pagamentos',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'Mais',
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String? section;
  const _NavItem({required this.icon, required this.label, this.section});
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 44,
            padding: EdgeInsets.symmetric(
              horizontal: widget.expanded ? 14 : 0,
            ),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.accent.withOpacity(0.15)
                  : _hovered
                      ? AppColors.sidebarHover
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: widget.expanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 20,
                  color: widget.selected
                      ? AppColors.accentLight
                      : AppColors.sidebarText,
                ),
                if (widget.expanded) ...[
                  const SizedBox(width: 12),
                  Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      color: widget.selected
                          ? Colors.white
                          : AppColors.sidebarText,
                      fontSize: 13,
                      fontWeight:
                          widget.selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
