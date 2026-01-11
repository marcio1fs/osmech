import 'package:flutter/material.dart';

class PricingPage extends StatelessWidget {
  const PricingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planos'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildPlanCard('PRO', 'R\$ 49,90/mês', 'Plano básico para pequenas oficinas.'),
          _buildPlanCard('PRO+', 'R\$ 79,90/mês', 'Plano intermediário com mais recursos.'),
          _buildPlanCard('PREMIUM', 'R\$ 149,90/mês', 'Plano completo para oficinas avançadas.'),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String title, String price, String description) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              price,
              style: const TextStyle(
                fontSize: 18.0,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(description),
          ],
        ),
      ),
    );
  }
}