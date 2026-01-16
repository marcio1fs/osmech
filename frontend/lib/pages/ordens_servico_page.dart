import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/os_service.dart';
import '../models/ordem_servico.dart';

class OrdensServicoPage extends StatefulWidget {
  const OrdensServicoPage({Key? key}) : super(key: key);

  @override
  State<OrdensServicoPage> createState() => _OrdensServicoPageState();
}

class _OrdensServicoPageState extends State<OrdensServicoPage> {
  List<OrdemServico> _ordens = [];
  bool _isLoading = true;
  String _filterStatus = 'TODAS';

  @override
  void initState() {
    super.initState();
    _loadOrdens();
  }

  Future<void> _loadOrdens() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ordens = await OrdemServicoService.getOrdens();
      setState(() {
        _ordens = ordens;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar ordens: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<OrdemServico> get _filteredOrdens {
    if (_filterStatus == 'TODAS') {
      return _ordens;
    }
    return _ordens.where((os) => os.status == _filterStatus).toList();
  }

  Future<void> _deleteOrdem(OrdemServico ordem) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir a OS #${ordem.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await OrdemServicoService.deleteOrdem(ordem.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OS excluída com sucesso')),
          );
          _loadOrdens();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordens de Serviço'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'TODAS', child: Text('Todas')),
              const PopupMenuItem(value: 'ABERTA', child: Text('Abertas')),
              const PopupMenuItem(
                  value: 'EM_ANDAMENTO', child: Text('Em Andamento')),
              const PopupMenuItem(value: 'CONCLUIDA', child: Text('Concluídas')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrdens,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filteredOrdens.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma ordem de serviço encontrada',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredOrdens.length,
                    itemBuilder: (context, index) {
                      final ordem = _filteredOrdens[index];
                      return _buildOrdemCard(ordem);
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/form_os');
          _loadOrdens();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOrdemCard(OrdemServico ordem) {
    final numberFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    Color statusColor;
    IconData statusIcon;

    switch (ordem.status) {
      case 'ABERTA':
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
        break;
      case 'EM_ANDAMENTO':
        statusColor = Colors.blue;
        statusIcon = Icons.build;
        break;
      case 'CONCLUIDA':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () async {
          await Navigator.pushNamed(
            context,
            '/form_os',
            arguments: ordem,
          );
          _loadOrdens();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'OS #${ordem.id}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Chip(
                    avatar: Icon(statusIcon, size: 16, color: Colors.white),
                    label: Text(
                      StatusOS.fromValue(ordem.status).label,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: statusColor,
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.person, 'Cliente', ordem.nomeCliente),
              const SizedBox(height: 4),
              _buildInfoRow(Icons.phone, 'Telefone', ordem.telefone),
              const SizedBox(height: 4),
              _buildInfoRow(Icons.directions_car, 'Veículo',
                  '${ordem.modelo} - ${ordem.placa}'),
              const SizedBox(height: 8),
              Text(
                'Problema:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              Text(ordem.descricaoProblema),
              const SizedBox(height: 8),
              Text(
                'Serviços Realizados:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              Text(ordem.servicosRealizados),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    numberFormat.format(ordem.valor),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    ordem.createdAt != null
                        ? dateFormat.format(ordem.createdAt!)
                        : '',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.pushNamed(
                        context,
                        '/form_os',
                        arguments: ordem,
                      );
                      _loadOrdens();
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _deleteOrdem(ordem),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label:
                        const Text('Excluir', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}
