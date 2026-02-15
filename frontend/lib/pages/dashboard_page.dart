import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/os_service.dart';
import '../theme/app_theme.dart';

/// Dashboard moderno sem AppBar — renderizado dentro do AppShell.
class DashboardPage extends StatefulWidget {
  final void Function(int)? onNavigate;
  const DashboardPage({super.key, this.onNavigate});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final osService = OsService(token: auth.token!);
      final stats = await osService.getDashboardStats();
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar dados';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Top bar
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
                    Text(
                      'Dashboard',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Visão geral da sua oficina',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _ActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'Atualizar',
                  onTap: _loadStats,
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  icon: Icons.add_rounded,
                  label: 'Nova OS',
                  primary: true,
                  onTap: () => widget.onNavigate?.call(2),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 48, color: AppColors.error),
                            const SizedBox(height: 16),
                            Text(_error!,
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _loadStats,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Welcome card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0F172A),
                                    Color(0xFF1E40AF)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Olá, ${auth.nome ?? "Usuário"}! 👋',
                                          style: GoogleFonts.inter(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Acompanhe o desempenho da sua oficina',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'Plano ${auth.plano ?? "PRO"}',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.build_rounded,
                                        size: 36, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Stats grid
                            Text(
                              'Ordens de Serviço',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final crossAxisCount =
                                    constraints.maxWidth > 900
                                        ? 4
                                        : constraints.maxWidth > 600
                                            ? 2
                                            : 2;
                                return GridView.count(
                                  crossAxisCount: crossAxisCount,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 2.2,
                                  children: [
                                    _MetricCard(
                                      label: 'Total de OS',
                                      value: '${_stats?['total'] ?? 0}',
                                      icon: Icons.assignment_rounded,
                                      color: AppColors.accent,
                                      bgColor:
                                          AppColors.accent.withOpacity(0.08),
                                    ),
                                    _MetricCard(
                                      label: 'Abertas',
                                      value: '${_stats?['abertas'] ?? 0}',
                                      icon: Icons.folder_open_rounded,
                                      color: const Color(0xFFF59E0B),
                                      bgColor: const Color(0xFFF59E0B)
                                          .withOpacity(0.08),
                                    ),
                                    _MetricCard(
                                      label: 'Em Andamento',
                                      value: '${_stats?['emAndamento'] ?? 0}',
                                      icon: Icons.engineering_rounded,
                                      color: const Color(0xFF8B5CF6),
                                      bgColor: const Color(0xFF8B5CF6)
                                          .withOpacity(0.08),
                                    ),
                                    _MetricCard(
                                      label: 'Concluídas',
                                      value: '${_stats?['concluidas'] ?? 0}',
                                      icon: Icons.check_circle_rounded,
                                      color: AppColors.success,
                                      bgColor:
                                          AppColors.success.withOpacity(0.08),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 28),

                            // Quick actions
                            Text(
                              'Ações Rápidas',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _QuickAction(
                                  icon: Icons.add_circle_outline_rounded,
                                  label: 'Nova OS',
                                  onTap: () => widget.onNavigate?.call(2),
                                ),
                                _QuickAction(
                                  icon: Icons.list_alt_rounded,
                                  label: 'Ver todas OS',
                                  onTap: () => widget.onNavigate?.call(1),
                                ),
                                _QuickAction(
                                  icon: Icons.bar_chart_rounded,
                                  label: 'Financeiro',
                                  onTap: () => widget.onNavigate?.call(5),
                                ),
                                _QuickAction(
                                  icon: Icons.workspace_premium_rounded,
                                  label: 'Planos',
                                  onTap: () => widget.onNavigate?.call(6),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon,
      required this.label,
      this.primary = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _MetricCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.accent.withOpacity(0.06)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? AppColors.accent.withOpacity(0.3)
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 20, color: AppColors.accent),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
