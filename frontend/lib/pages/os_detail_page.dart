import 'package:flutter/material.dart';
import '../services/os_service.dart';

class OrdemServicoDetailPage extends StatelessWidget {
  final OrdemServico ordemServico;
  const OrdemServicoDetailPage({Key? key, required this.ordemServico}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da OS')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Descrição:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(ordemServico.descricao),
            const SizedBox(height: 16),
            Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(ordemServico.status),
            const SizedBox(height: 16),
            Text('Usuário:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(ordemServico.usuario),
            const SizedBox(height: 32),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrdemServicoFormPage(
                          ordemServico: ordemServico,
                          isEdit: true,
                        ),
                      ),
                    ).then((result) {
                      if (result == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ordem de Serviço editada com sucesso!')),
                        );
                      }
                    });
                  },
                  child: const Text('Editar'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmar exclusão'),
                        content: const Text('Deseja realmente excluir esta Ordem de Serviço?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Excluir'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await OrdemServicoService.deleteOrdem(ordemServico.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ordem de Serviço excluída com sucesso!')),
                          );
                          Navigator.pop(context, true); // Retorna para lista
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro ao excluir: ${e.toString()}')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Excluir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
