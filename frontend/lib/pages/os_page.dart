import 'package:flutter/material.dart';
import '../services/os_service.dart';

class OrdemServicoPage extends StatefulWidget {
  const OrdemServicoPage({Key? key}) : super(key: key);

  @override
  State<OrdemServicoPage> createState() => _OrdemServicoPageState();
}

class _OrdemServicoPageState extends State<OrdemServicoPage> {
  late Future<List<OrdemServico>> _osFuture;

  @override
  void initState() {
    super.initState();
    _osFuture = OrdemServicoService.getOrdens();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ordens de Serviço')),
      body: FutureBuilder<List<OrdemServico>>(
        future: _osFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma OS encontrada'));
          }
          final osList = snapshot.data!;
          return ListView.builder(
            itemCount: osList.length,
            itemBuilder: (context, index) {
              final os = osList[index];
              return Card(
                child: ListTile(
                  title: Text(os.descricao),
                  subtitle: Text('Status: ${os.status}'),
                  trailing: const Icon(Icons.build),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrdemServicoDetailPage(ordemServico: os),
                      ),
                    );
                    if (result == true) {
                      setState(() {
                        _osFuture = OrdemServicoService.getOrdens();
                      });
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/os_form');
          if (result == true) {
            setState(() {
              _osFuture = OrdemServicoService.getOrdens();
            });
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Nova OS',
      ),
    );
  }
}
