import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/os_service.dart';
import 'os_list_page.dart';
import 'pricing_page.dart';
import 'subscription_page.dart';
import 'payment_history_page.dart';
import 'financial_dashboard_page.dart';

/// Tela principal — Dashboard com estatísticas.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('OSMECH'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Atualizar',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'planos') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PricingPage()),
                );
              } else if (value == 'assinatura') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubscriptionPage()),
                );
              } else if (value == 'pagamentos') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentHistoryPage()),
                );
              } else if (value == 'financeiro') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FinancialDashboardPage()),
                );
              } else if (value == 'logout') {
                auth.logout();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'planos', child: Text('Planos')),
              const PopupMenuItem(value: 'assinatura', child: Text('Minha Assinatura')),
              const PopupMenuItem(value: 'pagamentos', child: Text('Pagamentos')),
              const PopupMenuItem(value: 'financeiro', child: Text('Financeiro')),
              const PopupMenuItem(value: 'logout', child: Text('Sair')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loadStats,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Saudação
                    Text(
                      'Olá, ${auth.nome ?? "Usuário"}!',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Plano: ${auth.plano ?? "PRO"}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    // Cards de estatísticas
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _StatCard(
                          title: 'Total',
                          value: '${_stats?['total'] ?? 0}',
                          icon: Icons.assignment,
                          color: Colors.blue,
                        ),
                        _StatCard(
                          title: 'Abertas',
                          value: '${_stats?['abertas'] ?? 0}',
                          icon: Icons.folder_open,
                          color: Colors.orange,
                        ),
                        _StatCard(
                          title: 'Em Andamento',
                          value: '${_stats?['emAndamento'] ?? 0}',
                          icon: Icons.build,
                          color: Colors.amber,
                        ),
                        _StatCard(
                          title: 'Concluídas',
                          value: '${_stats?['concluidas'] ?? 0}',
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OsListPage()),
          );
        },
        icon: const Icon(Icons.list_alt),
        label: const Text('Ver OS'),
      ),
    );
  }
}

/// Card de estatística do dashboard.
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
