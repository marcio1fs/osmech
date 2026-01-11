import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bem-vindo ao OSMECH!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                title: const Text('Ordens de Serviço'),
                subtitle: const Text('Resumo das OS cadastradas'),
                trailing: const Icon(Icons.build),
                onTap: () {
                  Navigator.pushNamed(context, '/os');
                },
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Planos'),
                subtitle: const Text('Veja os planos disponíveis'),
                trailing: const Icon(Icons.payment),
                onTap: () {
                  Navigator.pushNamed(context, '/plans');
                },
              ),
            ),
            // Adicione mais cards conforme necessidade
          ],
        ),
      ),
    );
  }
}
