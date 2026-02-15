import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/os_service.dart';

/// Tela de criação/edição de Ordem de Serviço.
class OsFormPage extends StatefulWidget {
  final Map<String, dynamic>? osData;

  const OsFormPage({super.key, this.osData});

  @override
  State<OsFormPage> createState() => _OsFormPageState();
}

class _OsFormPageState extends State<OsFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _clienteNomeCtrl;
  late final TextEditingController _clienteTelefoneCtrl;
  late final TextEditingController _placaCtrl;
  late final TextEditingController _modeloCtrl;
  late final TextEditingController _anoCtrl;
  late final TextEditingController _kmCtrl;
  late final TextEditingController _descricaoCtrl;
  late final TextEditingController _diagnosticoCtrl;
  late final TextEditingController _pecasCtrl;
  late final TextEditingController _valorCtrl;
  String _status = 'ABERTA';
  bool _whatsappConsentimento = false;
  bool _loading = false;

  bool get _isEditing => widget.osData != null;

  @override
  void initState() {
    super.initState();
    final os = widget.osData;
    _clienteNomeCtrl = TextEditingController(text: os?['clienteNome'] ?? '');
    _clienteTelefoneCtrl = TextEditingController(
      text: os?['clienteTelefone'] ?? '',
    );
    _placaCtrl = TextEditingController(text: os?['placa'] ?? '');
    _modeloCtrl = TextEditingController(text: os?['modelo'] ?? '');
    _anoCtrl = TextEditingController(text: os?['ano']?.toString() ?? '');
    _kmCtrl = TextEditingController(
      text: os?['quilometragem']?.toString() ?? '',
    );
    _descricaoCtrl = TextEditingController(text: os?['descricao'] ?? '');
    _diagnosticoCtrl = TextEditingController(text: os?['diagnostico'] ?? '');
    _pecasCtrl = TextEditingController(text: os?['pecas'] ?? '');
    _valorCtrl = TextEditingController(
      text: os?['valor']?.toStringAsFixed(2) ?? '',
    );
    _status = os?['status'] ?? 'ABERTA';
    _whatsappConsentimento = os?['whatsappConsentimento'] ?? false;
  }

  @override
  void dispose() {
    _clienteNomeCtrl.dispose();
    _clienteTelefoneCtrl.dispose();
    _placaCtrl.dispose();
    _modeloCtrl.dispose();
    _anoCtrl.dispose();
    _kmCtrl.dispose();
    _descricaoCtrl.dispose();
    _diagnosticoCtrl.dispose();
    _pecasCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final osService = OsService(token: auth.token!);

      final dados = {
        'clienteNome': _clienteNomeCtrl.text.trim(),
        'clienteTelefone': _clienteTelefoneCtrl.text.trim(),
        'placa': _placaCtrl.text.trim().toUpperCase(),
        'modelo': _modeloCtrl.text.trim(),
        'ano': _anoCtrl.text.isNotEmpty ? int.tryParse(_anoCtrl.text) : null,
        'quilometragem': _kmCtrl.text.isNotEmpty
            ? int.tryParse(_kmCtrl.text)
            : null,
        'descricao': _descricaoCtrl.text.trim(),
        'diagnostico': _diagnosticoCtrl.text.trim(),
        'pecas': _pecasCtrl.text.trim(),
        'valor': _valorCtrl.text.isNotEmpty
            ? double.tryParse(_valorCtrl.text.replaceAll(',', '.'))
            : null,
        'status': _status,
        'whatsappConsentimento': _whatsappConsentimento,
      };

      if (_isEditing) {
        await osService.atualizar(widget.osData!['id'], dados);
      } else {
        await osService.criar(dados);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'OS atualizada com sucesso!'
                  : 'OS criada com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar OS' : 'Nova OS')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seção: Cliente
              Text(
                'Cliente',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _clienteNomeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome do cliente',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clienteTelefoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone (WhatsApp)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Cliente autoriza WhatsApp?'),
                value: _whatsappConsentimento,
                onChanged: (v) => setState(() => _whatsappConsentimento = v),
                contentPadding: EdgeInsets.zero,
              ),

              const Divider(height: 32),

              // Seção: Veículo
              Text(
                'Veículo',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _placaCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Placa',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe a placa' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _modeloCtrl,
                decoration: const InputDecoration(
                  labelText: 'Modelo',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o modelo' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _anoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Ano',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _kmCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'KM',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(height: 32),

              // Seção: Serviço
              Text(
                'Serviço',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descricaoCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrição do problema / serviço',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe a descrição' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _diagnosticoCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Diagnóstico',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pecasCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Peças utilizadas',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valorCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  border: OutlineInputBorder(),
                  prefixText: 'R\$ ',
                ),
              ),
              const SizedBox(height: 12),

              // Status dropdown
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'ABERTA', child: Text('Aberta')),
                  DropdownMenuItem(
                    value: 'EM_ANDAMENTO',
                    child: Text('Em Andamento'),
                  ),
                  DropdownMenuItem(
                    value: 'AGUARDANDO_PECA',
                    child: Text('Aguardando Peça'),
                  ),
                  DropdownMenuItem(
                    value: 'AGUARDANDO_APROVACAO',
                    child: Text('Aguardando Aprovação'),
                  ),
                  DropdownMenuItem(
                    value: 'CONCLUIDA',
                    child: Text('Concluída'),
                  ),
                  DropdownMenuItem(
                    value: 'CANCELADA',
                    child: Text('Cancelada'),
                  ),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'ABERTA'),
              ),
              const SizedBox(height: 24),

              // Botão Salvar
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _loading ? null : _salvar,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isEditing ? 'Atualizar' : 'Criar OS'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
