import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/api_config.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';

/// Tela de Planos (Pricing) — rota pública.
class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  List<dynamic> _planos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlanos();
  }

  Future<void> _loadPlanos() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/planos'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode == 200) {
        setState(() {
          _planos = jsonDecode(response.body);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Erro ao carregar planos';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro de conexão';
        _loading = false;
      });
    }
  }

  IconData _planIcon(String codigo) {
    switch (codigo) {
      case 'FREE':
        return Icons.card_giftcard;
      case 'PRO':
        return Icons.star_border;
      case 'PRO_PLUS':
        return Icons.star_half;
      case 'PREMIUM':
        return Icons.star;
      default:
        return Icons.card_membership;
    }
  }

  Color _planColor(String codigo) {
    switch (codigo) {
      case 'FREE':
        return Colors.green;
      case 'PRO':
        return Colors.blue;
      case 'PRO_PLUS':
        return Colors.purple;
      case 'PREMIUM':
        return Colors.amber.shade700;
      default:
        return Colors.grey;
    }
  }

  Future<void> _assinarPlano(String codigo) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para assinar um plano')),
      );
      return;
    }

    // Selecionar método de pagamento
    final metodo = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Método de Pagamento'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'PIX'),
            child: const ListTile(
              leading: Icon(Icons.qr_code),
              title: Text('PIX'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'CARTAO_CREDITO'),
            child: const ListTile(
              leading: Icon(Icons.credit_card),
              title: Text('Cartão de Crédito'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'BOLETO'),
            child: const ListTile(
              leading: Icon(Icons.receipt),
              title: Text('Boleto'),
            ),
          ),
        ],
      ),
    );

    if (metodo == null) return;

    try {
      final service = PaymentService(token: auth.token!);
      await service.assinar(planoCodigo: codigo, metodoPagamento: metodo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plano $codigo assinado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao assinar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planos')),
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
                    onPressed: _loadPlanos,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _planos.length,
              itemBuilder: (context, index) {
                final plano = _planos[index];
                final codigo = plano['codigo'] ?? '';
                final color = _planColor(codigo);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: color.withOpacity(0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(_planIcon(codigo), size: 48, color: color),
                        const SizedBox(height: 8),
                        Text(
                          plano['nome'] ?? '',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'R\$ ${(plano['preco'] ?? 0).toStringAsFixed(2)}/mês',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          plano['descricao'] ?? '',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        // Features
                        _FeatureRow(
                          label: 'OS/mês',
                          value: plano['limiteOs'] == 0
                              ? 'Ilimitado'
                              : '${plano['limiteOs']}',
                        ),
                        _FeatureRow(
                          label: 'WhatsApp',
                          value: plano['whatsappHabilitado'] == true
                              ? 'Sim'
                              : 'Não',
                        ),
                        _FeatureRow(
                          label: 'IA',
                          value: plano['iaHabilitada'] == true ? 'Sim' : 'Não',
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => _assinarPlano(codigo),
                            style: FilledButton.styleFrom(
                              backgroundColor: color,
                            ),
                            child: const Text('Assinar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String label;
  final String value;

  const _FeatureRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
