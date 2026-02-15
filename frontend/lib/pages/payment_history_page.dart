import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';

/// Tela de histórico de pagamentos.
class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _todos = [];
  List<Map<String, dynamic>> _assinatura = [];
  List<Map<String, dynamic>> _os = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPagamentos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPagamentos() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = PaymentService(token: auth.token!);

      final todos = await service.listarPagamentos();
      setState(() {
        _todos = todos;
        _assinatura =
            todos.where((p) => p['tipo'] == 'ASSINATURA').toList();
        _os = todos.where((p) => p['tipo'] == 'OS').toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar pagamentos';
        _loading = false;
      });
    }
  }

  Future<void> _confirmarPagamento(int id) async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = PaymentService(token: auth.token!);
      await service.confirmarPagamento(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pagamento confirmado!')),
        );
        _loadPagamentos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Future<void> _cancelarPagamento(int id) async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = PaymentService(token: auth.token!);
      await service.cancelarPagamento(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pagamento cancelado')),
        );
        _loadPagamentos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagamentos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Assinatura'),
            Tab(text: 'OS'),
          ],
        ),
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
                        onPressed: _loadPagamentos,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_todos),
                    _buildList(_assinatura),
                    _buildList(_os),
                  ],
                ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> pagamentos) {
    if (pagamentos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Nenhum pagamento encontrado',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPagamentos,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: pagamentos.length,
        itemBuilder: (context, index) {
          final p = pagamentos[index];
          return _PagamentoCard(
            pagamento: p,
            onConfirmar: p['status'] == 'PENDENTE'
                ? () => _confirmarPagamento(p['id'])
                : null,
            onCancelar: p['status'] == 'PENDENTE'
                ? () => _cancelarPagamento(p['id'])
                : null,
          );
        },
      ),
    );
  }
}

class _PagamentoCard extends StatelessWidget {
  final Map<String, dynamic> pagamento;
  final VoidCallback? onConfirmar;
  final VoidCallback? onCancelar;

  const _PagamentoCard({
    required this.pagamento,
    this.onConfirmar,
    this.onCancelar,
  });

  Color _statusColor(String? status) {
    switch (status) {
      case 'PAGO':
        return Colors.green;
      case 'PENDENTE':
        return Colors.orange;
      case 'FALHOU':
        return Colors.red;
      case 'CANCELADO':
        return Colors.grey;
      case 'REEMBOLSADO':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'PAGO':
        return 'Pago';
      case 'PENDENTE':
        return 'Pendente';
      case 'FALHOU':
        return 'Falhou';
      case 'CANCELADO':
        return 'Cancelado';
      case 'REEMBOLSADO':
        return 'Reembolsado';
      default:
        return status ?? '-';
    }
  }

  IconData _tipoIcon(String? tipo) {
    switch (tipo) {
      case 'ASSINATURA':
        return Icons.card_membership;
      case 'OS':
        return Icons.build;
      default:
        return Icons.payment;
    }
  }

  String _metodoPagamentoLabel(String? metodo) {
    switch (metodo) {
      case 'PIX':
        return 'PIX';
      case 'CARTAO_CREDITO':
        return 'Cartão de Crédito';
      case 'CARTAO_DEBITO':
        return 'Cartão de Débito';
      case 'DINHEIRO':
        return 'Dinheiro';
      case 'BOLETO':
        return 'Boleto';
      case 'TRANSFERENCIA':
        return 'Transferência';
      default:
        return metodo ?? '-';
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = pagamento['status'] as String?;
    final color = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_tipoIcon(pagamento['tipo']), color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pagamento['descricao'] ?? pagamento['tipo'] ?? 'Pagamento',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'R\$ ${(pagamento['valor'] ?? 0).toStringAsFixed(2)}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  _metodoPagamentoLabel(pagamento['metodoPagamento']),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _formatDateTime(pagamento['criadoEm']),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
            if (pagamento['pagoEm'] != null) ...[
              Text(
                'Pago em: ${_formatDateTime(pagamento['pagoEm'])}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.green),
              ),
            ],
            if (onConfirmar != null || onCancelar != null) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onCancelar != null)
                    TextButton(
                      onPressed: onCancelar,
                      child: const Text('Cancelar',
                          style: TextStyle(color: Colors.red)),
                    ),
                  if (onConfirmar != null) ...[
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: onConfirmar,
                      icon: const Icon(Icons.check),
                      label: const Text('Confirmar'),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
