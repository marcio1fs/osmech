import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';

/// Tela de status da assinatura e gerenciamento de plano.
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  Map<String, dynamic>? _assinatura;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssinatura();
  }

  Future<void> _loadAssinatura() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = PaymentService(token: auth.token!);
      final data = await service.getAssinaturaAtiva();
      setState(() {
        _assinatura = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar assinatura';
        _loading = false;
      });
    }
  }

  Future<void> _cancelarAssinatura() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Assinatura'),
        content: const Text(
          'Tem certeza que deseja cancelar sua assinatura? '
          'Você perderá acesso aos recursos do plano atual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Não'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sim, cancelar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = PaymentService(token: auth.token!);
      await service.cancelarAssinatura();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assinatura cancelada com sucesso')),
        );
        _loadAssinatura();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
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
      case 'CANCELED':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'ACTIVE':
        return 'Ativa';
      case 'PAST_DUE':
        return 'Pagamento Atrasado';
      case 'SUSPENDED':
        return 'Suspensa';
      case 'CANCELED':
        return 'Cancelada';
      default:
        return 'Sem assinatura';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha Assinatura')),
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
                        onPressed: _loadAssinatura,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAssinatura,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card principal da assinatura
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.card_membership,
                                  size: 48,
                                  color: _statusColor(_assinatura?['status']),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _assinatura?['planoNome'] ?? 'Sem plano',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(_assinatura?['status'])
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color:
                                          _statusColor(_assinatura?['status']),
                                    ),
                                  ),
                                  child: Text(
                                    _statusLabel(_assinatura?['status']),
                                    style: TextStyle(
                                      color:
                                          _statusColor(_assinatura?['status']),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'R\$ ${(_assinatura?['valorMensal'] ?? 0).toStringAsFixed(2)}/mês',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Detalhes
                        if (_assinatura?['dataInicio'] != null) ...[
                          _DetailRow(
                            icon: Icons.calendar_today,
                            label: 'Início',
                            value: _formatDate(_assinatura!['dataInicio']),
                          ),
                        ],
                        if (_assinatura?['proximaCobranca'] != null) ...[
                          _DetailRow(
                            icon: Icons.event,
                            label: 'Próxima cobrança',
                            value:
                                _formatDate(_assinatura!['proximaCobranca']),
                          ),
                        ],
                        if (_assinatura?['dataCancelamento'] != null) ...[
                          _DetailRow(
                            icon: Icons.cancel,
                            label: 'Cancelado em',
                            value:
                                _formatDate(_assinatura!['dataCancelamento']),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Botões de ação
                        if (_assinatura?['status'] == 'ACTIVE' ||
                            _assinatura?['status'] == 'PAST_DUE') ...[
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _cancelarAssinatura,
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              label: const Text(
                                'Cancelar Assinatura',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        ],

                        if (_assinatura?['status'] == 'PAST_DUE' ||
                            _assinatura?['status'] == 'SUSPENDED') ...[
                          const SizedBox(height: 12),
                          Card(
                            color: Colors.orange.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(Icons.warning,
                                      color: Colors.orange.shade700),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _assinatura?['status'] == 'PAST_DUE'
                                          ? 'Seu pagamento está atrasado. Regularize para evitar a suspensão.'
                                          : 'Sua conta está suspensa por inadimplência. Efetue o pagamento para reativar.',
                                      style: TextStyle(
                                          color: Colors.orange.shade900),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final parts = dateStr.split('-');
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (_) {
      return dateStr;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
