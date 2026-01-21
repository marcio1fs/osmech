import 'package:flutter/material.dart';

class PricingPage extends StatelessWidget {
  const PricingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planos'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Escolha o plano ideal',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Planos flexíveis para oficinas de todos os tamanhos',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Plano PRO
            _PlanCard(
              name: 'PRO',
              price: 'R\$ 49,90',
              period: '/mês',
              features: const [
                'Até 50 OS/mês',
                '1 usuário',
                'Suporte por email',
                'Relatórios básicos',
              ],
              color: Colors.blue,
              onTap: () {
                _showPlanDialog(context, 'PRO');
              },
            ),
            const SizedBox(height: 16),

            // Plano PRO+
            _PlanCard(
              name: 'PRO+',
              price: 'R\$ 79,90',
              period: '/mês',
              features: const [
                'Até 150 OS/mês',
                'Até 3 usuários',
                'WhatsApp integrado',
                'Suporte prioritário',
                'Relatórios avançados',
              ],
              color: Colors.purple,
              isPopular: true,
              onTap: () {
                _showPlanDialog(context, 'PRO+');
              },
            ),
            const SizedBox(height: 16),

            // Plano PREMIUM
            _PlanCard(
              name: 'PREMIUM',
              price: 'R\$ 149,90',
              period: '/mês',
              features: const [
                'OS ilimitadas',
                'Até 10 usuários',
                'WhatsApp + IA integrados',
                'Suporte 24/7',
                'Relatórios personalizados',
                'API para integrações',
              ],
              color: Colors.amber.shade700,
              onTap: () {
                _showPlanDialog(context, 'PREMIUM');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPlanDialog(BuildContext context, String planName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Plano $planName'),
        content: Text(
          'Funcionalidade de assinatura em desenvolvimento.\n\n'
          'Em breve você poderá assinar o plano $planName diretamente pelo app!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String name;
  final String price;
  final String period;
  final List<String> features;
  final Color color;
  final bool isPopular;
  final VoidCallback onTap;

  const _PlanCard({
    required this.name,
    required this.price,
    required this.period,
    required this.features,
    required this.color,
    this.isPopular = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isPopular ? 8 : 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isPopular
              ? Border.all(color: color, width: 2)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              if (isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'MAIS POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (isPopular) const SizedBox(height: 12),
              Text(
                name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    price,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    period,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: color,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(feature),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Assinar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
