import 'package:flutter/material.dart';
import '../services/oficina_service.dart';

class OficinaFormPage extends StatefulWidget {
  final Oficina? oficina;
  final bool isEdit;
  const OficinaFormPage({Key? key, this.oficina, this.isEdit = false}) : super(key: key);

  @override
  State<OficinaFormPage> createState() => _OficinaFormPageState();
}

class _OficinaFormPageState extends State<OficinaFormPage> {
  late TextEditingController _nomeController;
  late TextEditingController _enderecoController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.oficina?.nome ?? '');
    _enderecoController = TextEditingController(text: widget.oficina?.endereco ?? '');
  }

  Future<void> _submit() async {
    setState(() { _isLoading = true; _error = null; });
    final nome = _nomeController.text;
    final endereco = _enderecoController.text;
    try {
      if (widget.isEdit && widget.oficina != null) {
        await OficinaService.updateOficina(widget.oficina!, nome, endereco);
      } else {
        await OficinaService.createOficina(nome, endereco);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEdit ? 'Oficina editada com sucesso!' : 'Oficina cadastrada com sucesso!')),
        );
        Navigator.pop(context, true);
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
      appBar: AppBar(title: Text(widget.isEdit ? 'Editar Oficina' : 'Nova Oficina')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome da Oficina'),
            ),
            TextField(
              controller: _enderecoController,
              decoration: const InputDecoration(labelText: 'Endereço'),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading ? const CircularProgressIndicator() : Text(widget.isEdit ? 'Salvar' : 'Cadastrar'),
            ),
          ],
        ),
      ),
    );
  }
}
