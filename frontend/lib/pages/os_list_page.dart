import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/os_service.dart';
import 'os_form_page.dart';

/// Tela de listagem de Ordens de Serviço.
class OsListPage extends StatefulWidget {
  const OsListPage({super.key});

  @override
  State<OsListPage> createState() => _OsListPageState();
}

class _OsListPageState extends State<OsListPage> {
  List<Map<String, dynamic>> _ordens = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrdens();
  }

  Future<void> _loadOrdens() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final osService = OsService(token: auth.token!);
      final ordens = await osService.listar();
      setState(() {
        _ordens = ordens;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar ordens de serviço';
        _loading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ABERTA':
        return Colors.orange;
      case 'EM_ANDAMENTO':
        return Colors.blue;
      case 'AGUARDANDO_PECA':
        return Colors.purple;
      case 'AGUARDANDO_APROVACAO':
        return Colors.amber;
      case 'CONCLUIDA':
        return Colors.green;
      case 'CANCELADA':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ABERTA':
        return 'Aberta';
      case 'EM_ANDAMENTO':
        return 'Em Andamento';
      case 'AGUARDANDO_PECA':
        return 'Aguardando Peça';
      case 'AGUARDANDO_APROVACAO':
        return 'Aguardando Aprovação';
      case 'CONCLUIDA':
        return 'Concluída';
      case 'CANCELADA':
        return 'Cancelada';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordens de Serviço'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrdens),
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
                    onPressed: _loadOrdens,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : _ordens.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma OS encontrada',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadOrdens,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _ordens.length,
                itemBuilder: (context, index) {
                  final os = _ordens[index];
                  final status = os['status'] ?? 'ABERTA';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _statusColor(status).withOpacity(0.2),
                        child: Icon(Icons.build, color: _statusColor(status)),
                      ),
                      title: Text(
                        '${os['placa']} - ${os['modelo']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(os['clienteNome'] ?? ''),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: TextStyle(
                                fontSize: 12,
                                color: _statusColor(status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        'R\$ ${(os['valor'] ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OsFormPage(osData: os),
                          ),
                        );
                        _loadOrdens();
                      },
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OsFormPage()),
          );
          _loadOrdens();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
