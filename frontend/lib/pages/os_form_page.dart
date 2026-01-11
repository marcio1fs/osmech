import 'package:flutter/material.dart';
import '../services/os_service.dart';
import '../services/whatsapp_service.dart';

class OrdemServicoFormPage extends StatefulWidget {
  final OrdemServico? ordemServico;
  final bool isEdit;
  const OrdemServicoFormPage({Key? key, this.ordemServico, this.isEdit = false}) : super(key: key);

  @override
  State<OrdemServicoFormPage> createState() => _OrdemServicoFormPageState();
}

class _OrdemServicoFormPageState extends State<OrdemServicoFormPage> {
  late TextEditingController _descricaoController;
  late TextEditingController _statusController;
  late TextEditingController _telefoneController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _descricaoController = TextEditingController(text: widget.ordemServico?.descricao ?? '');
    _statusController = TextEditingController(text: widget.ordemServico?.status ?? '');
    _telefoneController = TextEditingController(text: widget.ordemServico?.telefone ?? '');
  }

  Future<void> _submit() async {
    setState(() { _isLoading = true; _error = null; });
    final descricao = _descricaoController.text;
    final status = _statusController.text;
    final telefone = _telefoneController.text;
    try {
      if (widget.isEdit && widget.ordemServico != null) {
        await OrdemServicoService.updateOrdem(widget.ordemServico!, descricao, status, telefone);
      } else {
        await OrdemServicoService.createOrdem(descricao, status, telefone);
      }
      // Exemplo: enviar WhatsApp para número fixo (substitua pelo número do cliente)
      try {
        await WhatsAppService.sendMessage(
          telefone,
          'Sua Ordem de Serviço foi atualizada: $descricao - Status: $status',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WhatsApp enviado com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao enviar WhatsApp: ${e.toString()}')),
          );
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEdit ? 'Ordem de Serviço editada com sucesso!' : 'Ordem de Serviço cadastrada com sucesso!')),
        );
        Navigator.pop(context, true); // Retorna para lista de OS
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.toString()}')),
        );
      }
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? 'Editar Ordem de Serviço' : 'Nova Ordem de Serviço')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _descricaoController,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            TextField(
              controller: _statusController,
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            TextField(
              controller: _telefoneController,
              decoration: const InputDecoration(labelText: 'Telefone do Cliente'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Cadastrar'),
            ),
          ],
        ),
      ),
    );
  }
}
