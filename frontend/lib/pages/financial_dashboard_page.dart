import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';

/// Tela de resumo financeiro (Dashboard Financeiro).
class FinancialDashboardPage extends StatefulWidget {
  const FinancialDashboardPage({super.key});

  @override
  State<FinancialDashboardPage> createState() => _FinancialDashboardPageState();
}

class _FinancialDashboardPageState extends State<FinancialDashboardPage> {
  Map<String, dynamic>? _resumo;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadResumo();
  }

  Future<void> _loadResumo() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = PaymentService(token: auth.token!);
      final data = await service.getResumoFinanceiro();
      setState(() {
        _resumo = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar resumo financeiro';
        _loading = false;
      });
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'PAST_DUE':
        return Colors.orange;
      case 'SUSPENDED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'ACTIVE':
        return 'Ativa';
      case 'PAST_DUE':
        return 'Atrasada';
      case 'SUSPENDED':
        return 'Suspensa';
      case 'NONE':
        return 'Sem assinatura';
      default:
        return status ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financeiro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadResumo,
            tooltip: 'Atualizar',
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
                      Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadResumo,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadResumo,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card de assinatura resumida
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.card_membership,
                                  size: 40,
                                  color: _statusColor(
                                      _resumo?['statusAssinatura']),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Plano: ${_resumo?['planoAtual'] ?? '-'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _statusColor(
                                                  _resumo?[
                                                      'statusAssinatura']),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(_statusLabel(
                                              _resumo?['statusAssinatura'])),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'R\$ ${(_resumo?['valorAssinatura'] ?? 0).toStringAsFixed(2)}/mês',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          'Resumo Financeiro',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        // Cards de métricas
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.4,
                          children: [
                            _MetricCard(
                              title: 'Receita Total',
                              value:
                                  'R\$ ${(_resumo?['receitaTotal'] ?? 0).toStringAsFixed(2)}',
                              icon: Icons.account_balance_wallet,
                              color: Colors.green,
                            ),
                            _MetricCard(
                              title: 'Receita do Mês',
                              value:
                                  'R\$ ${(_resumo?['receitaMesAtual'] ?? 0).toStringAsFixed(2)}',
                              icon: Icons.trending_up,
                              color: Colors.blue,
                            ),
                            _MetricCard(
                              title: 'Pendente',
                              value:
                                  'R\$ ${(_resumo?['totalPendente'] ?? 0).toStringAsFixed(2)}',
                              icon: Icons.hourglass_empty,
                              color: Colors.orange,
                            ),
                            _MetricCard(
                              title: 'OS Pagas (Mês)',
                              value: '${_resumo?['qtdOsPagasMes'] ?? 0}',
                              icon: Icons.check_circle_outline,
                              color: Colors.teal,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Indicadores adicionais
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _InfoRow(
                                  label: 'Pagamentos no mês',
                                  value:
                                      '${_resumo?['qtdPagamentosMes'] ?? 0}',
                                ),
                                const Divider(),
                                _InfoRow(
                                  label: 'Pagamentos pendentes',
                                  value: '${_resumo?['qtdPendentes'] ?? 0}',
                                  valueColor:
                                      (_resumo?['qtdPendentes'] ?? 0) > 0
                                          ? Colors.orange
                                          : Colors.green,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
