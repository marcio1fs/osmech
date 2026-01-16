import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/os_service.dart';
import '../models/ordem_servico.dart';

class FormOsPage extends StatefulWidget {
  const FormOsPage({Key? key}) : super(key: key);

  @override
  State<FormOsPage> createState() => _FormOsPageState();
}

class _FormOsPageState extends State<FormOsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeClienteController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _placaController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _descricaoProblemaController =
      TextEditingController();
  final TextEditingController _servicosRealizadosController =
      TextEditingController();
  final TextEditingController _valorController = TextEditingController();

  StatusOS _selectedStatus = StatusOS.aberta;
  bool _isLoading = false;
  OrdemServico? _ordemToEdit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is OrdemServico && _ordemToEdit == null) {
      _ordemToEdit = args;
      _populateForm();
    }
  }

  void _populateForm() {
    if (_ordemToEdit != null) {
      _nomeClienteController.text = _ordemToEdit!.nomeCliente;
      _telefoneController.text = _ordemToEdit!.telefone;
      _placaController.text = _ordemToEdit!.placa;
      _modeloController.text = _ordemToEdit!.modelo;
      _descricaoProblemaController.text = _ordemToEdit!.descricaoProblema;
      _servicosRealizadosController.text = _ordemToEdit!.servicosRealizados;
      _valorController.text = _ordemToEdit!.valor.toStringAsFixed(2);
      _selectedStatus = StatusOS.fromValue(_ordemToEdit!.status);
    }
  }

  @override
  void dispose() {
    _nomeClienteController.dispose();
    _telefoneController.dispose();
    _placaController.dispose();
    _modeloController.dispose();
    _descricaoProblemaController.dispose();
    _servicosRealizadosController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _saveOrdem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final valor = double.parse(_valorController.text.replaceAll(',', '.'));

      final ordem = OrdemServico(
        id: _ordemToEdit?.id,
        nomeCliente: _nomeClienteController.text.trim(),
        telefone: _telefoneController.text.trim(),
        placa: _placaController.text.trim().toUpperCase(),
        modelo: _modeloController.text.trim(),
        descricaoProblema: _descricaoProblemaController.text.trim(),
        servicosRealizados: _servicosRealizadosController.text.trim(),
        valor: valor,
        status: _selectedStatus.value,
      );

      if (_ordemToEdit != null) {
        await OrdemServicoService.updateOrdem(_ordemToEdit!.id!, ordem);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OS atualizada com sucesso')),
          );
        }
      } else {
        await OrdemServicoService.createOrdem(ordem);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OS criada com sucesso')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_ordemToEdit == null ? 'Nova OS' : 'Editar OS'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Dados do Cliente',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeClienteController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Cliente *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome do cliente';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  hintText: '(11) 98765-4321',
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o telefone';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Dados do Veículo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _placaController,
                decoration: const InputDecoration(
                  labelText: 'Placa *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_shipping),
                  hintText: 'ABC-1234',
                ),
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a placa';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modeloController,
                decoration: const InputDecoration(
                  labelText: 'Modelo *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car),
                  hintText: 'Ex: Gol 1.0',
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o modelo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Detalhes do Serviço',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoProblemaController,
                decoration: const InputDecoration(
                  labelText: 'Descrição do Problema *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, descreva o problema';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _servicosRealizadosController,
                decoration: const InputDecoration(
                  labelText: 'Serviços Realizados *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.build),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, descreva os serviços realizados';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorController,
                decoration: const InputDecoration(
                  labelText: 'Valor *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o valor';
                  }
                  final valor = double.tryParse(value.replaceAll(',', '.'));
                  if (valor == null || valor <= 0) {
                    return 'Por favor, insira um valor válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<StatusOS>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                items: StatusOS.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveOrdem,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _ordemToEdit == null ? 'Criar OS' : 'Salvar Alterações',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
