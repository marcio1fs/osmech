import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/os_service.dart';
import '../services/stock_service.dart';
import '../theme/app_theme.dart';
import '../mixins/auth_error_mixin.dart';

/// Formulário de criação/edição de OS — com suporte a múltiplos serviços e itens de estoque.
class OsFormPage extends StatefulWidget {
  final Map<String, dynamic>? osData;
  final VoidCallback? onSaved;
  const OsFormPage({super.key, this.osData, this.onSaved});

  @override
  State<OsFormPage> createState() => _OsFormPageState();
}

class _OsFormPageState extends State<OsFormPage> with AuthErrorMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _clienteNome;
  late final TextEditingController _clienteTelefone;
  late final TextEditingController _placa;
  late final TextEditingController _modelo;
  late final TextEditingController _ano;
  late final TextEditingController _km;
  late final TextEditingController _diagnostico;
  String _status = 'ABERTA';
  bool _notificarWhatsApp = false;
  bool _loading = false;
  bool _saved = false;

  // Serviços dinâmicos
  final List<_ServicoEntry> _servicos = [];

  // Itens de estoque dinâmicos
  final List<_ItemEstoqueEntry> _itensEstoque = [];

  // Itens de estoque disponíveis (carregados da API)
  List<Map<String, dynamic>> _stockItems = [];
  bool _loadingStock = false;

  bool get _isEditing => widget.osData != null;

  double get _totalServicos {
    double total = 0;
    for (var s in _servicos) {
      final qty = int.tryParse(s.quantidade.text) ?? 0;
      final val = double.tryParse(s.valorUnitario.text) ?? 0;
      total += qty * val;
    }
    return total;
  }

  double get _totalItens {
    double total = 0;
    for (var i in _itensEstoque) {
      final qty = int.tryParse(i.quantidade.text) ?? 0;
      final val = double.tryParse(i.valorUnitario.text) ?? 0;
      total += qty * val;
    }
    return total;
  }

  double get _valorTotal => _totalServicos + _totalItens;

  bool get _isDirty {
    if (_saved) return false;
    return _servicos.isNotEmpty ||
        _itensEstoque.isNotEmpty ||
        _clienteNome.text.trim().isNotEmpty ||
        _placa.text.trim().isNotEmpty;
  }

  Future<bool> _confirmarSaida() async {
    if (!_isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Descartar alterações?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Você tem alterações não salvas. Deseja sair sem salvar?',
          style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Continuar editando')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Mapa de transições de status válidas (espelho do backend StatusOS).
  static const Map<String, List<String>> _transicoesValidas = {
    'ABERTA': [
      'ABERTA',
      'EM_ANDAMENTO',
      'AGUARDANDO_PECA',
      'AGUARDANDO_APROVACAO',
      'CANCELADA'
    ],
    'EM_ANDAMENTO': [
      'EM_ANDAMENTO',
      'AGUARDANDO_PECA',
      'AGUARDANDO_APROVACAO',
      'CONCLUIDA',
      'CANCELADA'
    ],
    'AGUARDANDO_PECA': ['AGUARDANDO_PECA', 'EM_ANDAMENTO', 'CANCELADA'],
    'AGUARDANDO_APROVACAO': [
      'AGUARDANDO_APROVACAO',
      'EM_ANDAMENTO',
      'CANCELADA'
    ],
    'CONCLUIDA': ['CONCLUIDA'],
    'CANCELADA': ['CANCELADA', 'ABERTA'],
  };

  static const Map<String, String> _statusLabels = {
    'ABERTA': 'Aberta',
    'EM_ANDAMENTO': 'Em Andamento',
    'AGUARDANDO_PECA': 'Aguardando Peça',
    'AGUARDANDO_APROVACAO': 'Ag. Aprovação',
    'CONCLUIDA': 'Concluída',
    'CANCELADA': 'Cancelada',
  };

  List<String> get _statusPermitidos {
    if (!_isEditing) return ['ABERTA'];
    return _transicoesValidas[_status] ?? ['ABERTA'];
  }

  @override
  void initState() {
    super.initState();
    final d = widget.osData;
    _clienteNome = TextEditingController(text: d?['clienteNome'] ?? '');
    _clienteTelefone = TextEditingController(text: d?['clienteTelefone'] ?? '');
    _placa = TextEditingController(text: d?['placa'] ?? '');
    _modelo = TextEditingController(text: d?['modelo'] ?? '');
    _ano = TextEditingController(text: d?['ano']?.toString() ?? '');
    _km = TextEditingController(text: d?['quilometragem']?.toString() ?? '');
    _diagnostico = TextEditingController(text: d?['diagnostico'] ?? '');
    _status = d?['status'] ?? 'ABERTA';
    _notificarWhatsApp = d?['whatsappConsentimento'] ?? false;

    // Carregar serviços existentes
    if (d != null &&
        d['servicos'] != null &&
        (d['servicos'] as List).isNotEmpty) {
      for (var s in d['servicos']) {
        _servicos.add(_ServicoEntry(
          descricao: TextEditingController(text: s['descricao'] ?? ''),
          quantidade:
              TextEditingController(text: (s['quantidade'] ?? 1).toString()),
          valorUnitario:
              TextEditingController(text: (s['valorUnitario'] ?? 0).toString()),
        ));
      }
    }

    // Se editando sem serviços, criar um a partir do campo descricao/valor
    if (_servicos.isEmpty &&
        d != null &&
        d['descricao'] != null &&
        d['descricao'].toString().isNotEmpty) {
      _servicos.add(_ServicoEntry(
        descricao: TextEditingController(text: d['descricao'] ?? ''),
        quantidade: TextEditingController(text: '1'),
        valorUnitario:
            TextEditingController(text: (d['valor'] ?? 0).toString()),
      ));
    }

    // Se novo formulário, adicionar um serviço vazio
    if (_servicos.isEmpty) {
      _servicos.add(_ServicoEntry());
    }

    // Carregar itens de estoque existentes
    if (d != null && d['itens'] != null) {
      for (var i in d['itens']) {
        _itensEstoque.add(_ItemEstoqueEntry(
          stockItemId: i['stockItemId'],
          nomeItem: i['nomeItem'] ?? '',
          codigoItem: i['codigoItem'] ?? '',
          quantidade:
              TextEditingController(text: (i['quantidade'] ?? 1).toString()),
          valorUnitario:
              TextEditingController(text: (i['valorUnitario'] ?? 0).toString()),
        ));
      }
    }

    // Carregar itens de estoque disponíveis
    _carregarStockItems();
  }

  Future<void> _carregarStockItems() async {
    setState(() => _loadingStock = true);
    try {
      final stockService = StockService(token: safeToken);
      final items = await stockService.listarItens();
      setState(() {
        _stockItems = items.where((i) => (i['ativo'] ?? true) == true).toList();
        _loadingStock = false;
      });
    } catch (e) {
      if (!handleAuthError(e)) {
        setState(() => _loadingStock = false);
      }
    }
  }

  @override
  void dispose() {
    _clienteNome.dispose();
    _clienteTelefone.dispose();
    _placa.dispose();
    _modelo.dispose();
    _ano.dispose();
    _km.dispose();
    _diagnostico.dispose();
    for (var s in _servicos) {
      s.dispose();
    }
    for (var i in _itensEstoque) {
      i.dispose();
    }
    super.dispose();
  }

  void _adicionarServico() {
    setState(() {
      _servicos.add(_ServicoEntry());
    });
  }

  void _removerServico(int index) {
    setState(() {
      _servicos[index].dispose();
      _servicos.removeAt(index);
    });
  }

  void _removerItemEstoque(int index) {
    setState(() {
      _itensEstoque[index].dispose();
      _itensEstoque.removeAt(index);
    });
  }

  void _mostrarSeletorEstoque() {
    // Filtrar itens que já foram adicionados
    final idsJaAdicionados = _itensEstoque.map((i) => i.stockItemId).toSet();
    final disponiveis = _stockItems
        .where((item) => !idsJaAdicionados.contains(item['id']))
        .where((item) => (item['quantidade'] ?? 0) > 0)
        .toList();

    if (disponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum item de estoque disponível'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          final query = searchController.text.toLowerCase();
          final filtrados = disponiveis.where((item) {
            final nome = (item['nome'] ?? '').toString().toLowerCase();
            final codigo = (item['codigo'] ?? '').toString().toLowerCase();
            return query.isEmpty ||
                nome.contains(query) ||
                codigo.contains(query);
          }).toList();

          return AlertDialog(
            title: Text('Selecionar Item do Estoque',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            content: SizedBox(
              width: 500,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome ou código...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtrados.isEmpty
                        ? Center(
                            child: Text('Nenhum item encontrado',
                                style: GoogleFonts.inter(
                                    color: AppColors.textMuted)))
                        : ListView.builder(
                            itemCount: filtrados.length,
                            itemBuilder: (ctx, i) {
                              final item = filtrados[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppColors.accent.withValues(alpha: 0.1),
                                  child: const Icon(Icons.inventory_2_outlined,
                                      color: AppColors.accent, size: 20),
                                ),
                                title: Text(item['nome'] ?? '',
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  '${item['codigo'] ?? ''} • Estoque: ${item['quantidade'] ?? 0} • R\$ ${_formatNum(item['precoVenda'] ?? 0)}',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  setState(() {
                                    _itensEstoque.add(_ItemEstoqueEntry(
                                      stockItemId: item['id'],
                                      nomeItem: item['nome'] ?? '',
                                      codigoItem: item['codigo'] ?? '',
                                      quantidade:
                                          TextEditingController(text: '1'),
                                      valorUnitario: TextEditingController(
                                          text: (item['precoVenda'] ?? 0)
                                              .toString()),
                                      estoqueDisponivel:
                                          item['quantidade'] ?? 0,
                                    ));
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar')),
            ],
          );
        });
      },
    );
  }

  String _formatNum(dynamic value) {
    if (value == null) return '0,00';
    final num = double.tryParse(value.toString()) ?? 0;
    return num.toStringAsFixed(2).replaceAll('.', ',');
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar que tem pelo menos um serviço com descrição
    final servicosValidos =
        _servicos.where((s) => s.descricao.text.trim().isNotEmpty).toList();
    if (servicosValidos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Adicione pelo menos um serviço'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final osService = OsService(token: safeToken);

      // Montar lista de serviços
      final servicos = servicosValidos.map((s) {
        return {
          'descricao': s.descricao.text.trim(),
          'quantidade': int.tryParse(s.quantidade.text) ?? 1,
          'valorUnitario': double.tryParse(s.valorUnitario.text) ?? 0,
        };
      }).toList();

      // Montar lista de itens de estoque
      final itens = _itensEstoque.where((i) => i.stockItemId != null).map((i) {
        return {
          'stockItemId': i.stockItemId,
          'quantidade': int.tryParse(i.quantidade.text) ?? 1,
          'valorUnitario': double.tryParse(i.valorUnitario.text) ?? 0,
        };
      }).toList();

      final data = {
        'clienteNome': _clienteNome.text.trim(),
        'clienteTelefone': _clienteTelefone.text.trim(),
        'placa': _placa.text.trim().toUpperCase(),
        'modelo': _modelo.text.trim(),
        'ano': int.tryParse(_ano.text.trim()),
        'quilometragem': int.tryParse(_km.text.trim()),
        'diagnostico': _diagnostico.text.trim(),
        'whatsappConsentimento': _notificarWhatsApp,
        'servicos': servicos,
        'itens': itens,
      };

      // Enviar status apenas na edição
      if (_isEditing) {
        data['status'] = _status;
      }

      if (_isEditing) {
        await osService.atualizar(widget.osData!['id'], data);
      } else {
        await osService.criar(data);
      }
      if (mounted) {
        _saved = true;
        if (widget.onSaved != null) {
          widget.onSaved!();
        } else {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (!handleAuthError(e)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erro ao salvar: $e'),
                backgroundColor: AppColors.error),
          );
        }
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmarSaida()) {
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // Header
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  if (Navigator.canPop(context))
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, size: 20),
                        onPressed: () async {
                          if (await _confirmarSaida()) {
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isEditing ? 'Editar OS' : 'Nova Ordem de Serviço',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                      Text(
                        _isEditing
                            ? 'Placa: ${widget.osData?['placa'] ?? ''}'
                            : 'Preencha os dados da OS',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Valor total chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Total: R\$ ${_valorTotal.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () async {
                      if (await _confirmarSaida()) {
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _loading ? null : _salvar,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(_isEditing ? 'Salvar Alterações' : 'Criar OS'),
                  ),
                ],
              ),
            ),

            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section: Cliente
                        const _SectionHeader(
                            icon: Icons.person_outline_rounded,
                            title: 'Dados do Cliente'),
                        const SizedBox(height: 16),
                        _CardSection(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _Field(
                                      label: 'Nome do Cliente',
                                      controller: _clienteNome,
                                      required: true),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _Field(
                                      label: 'Telefone (WhatsApp)',
                                      controller: _clienteTelefone,
                                      required: true,
                                      keyboard: TextInputType.phone),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Section: Veículo
                        const _SectionHeader(
                            icon: Icons.directions_car_outlined,
                            title: 'Dados do Veículo'),
                        const SizedBox(height: 16),
                        _CardSection(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: _Field(
                                        label: 'Placa',
                                        controller: _placa,
                                        required: true)),
                                const SizedBox(width: 16),
                                Expanded(
                                    flex: 2,
                                    child: _Field(
                                        label: 'Modelo',
                                        controller: _modelo,
                                        required: true)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                    child: _Field(
                                        label: 'Ano',
                                        controller: _ano,
                                        keyboard: TextInputType.number)),
                                const SizedBox(width: 16),
                                Expanded(
                                    child: _Field(
                                        label: 'Quilometragem',
                                        controller: _km,
                                        keyboard: TextInputType.number)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Section: Serviços
                        Row(
                          children: [
                            const _SectionHeader(
                                icon: Icons.build_outlined, title: 'Serviços'),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: _adicionarServico,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Adicionar Serviço'),
                              style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ..._buildServicosCards(),
                        if (_servicos.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Subtotal Serviços: R\$ ${_totalServicos.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),

                        // Section: Itens de Estoque
                        Row(
                          children: [
                            const _SectionHeader(
                                icon: Icons.inventory_2_outlined,
                                title: 'Itens do Estoque'),
                            const Spacer(),
                            if (_loadingStock)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.accent),
                              )
                            else
                              FilledButton.icon(
                                onPressed: _mostrarSeletorEstoque,
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Adicionar Peça'),
                                style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF8B5CF6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ..._buildItensEstoqueCards(),
                        if (_itensEstoque.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Subtotal Peças: R\$ ${_totalItens.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary),
                              ),
                            ),
                          ),
                        ],
                        if (_itensEstoque.isEmpty)
                          _CardSection(
                            children: [
                              Center(
                                child: Text(
                                  'Nenhuma peça adicionada. Clique em "Adicionar Peça" para selecionar do estoque.',
                                  style: GoogleFonts.inter(
                                      fontSize: 13, color: AppColors.textMuted),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 28),

                        // Section: Diagnóstico e Status
                        const _SectionHeader(
                            icon: Icons.assignment_outlined,
                            title: 'Diagnóstico e Status'),
                        const SizedBox(height: 16),
                        _CardSection(
                          children: [
                            _Field(
                                label: 'Diagnóstico',
                                controller: _diagnostico,
                                maxLines: 3),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Status',
                                          style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary)),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        value: _status,
                                        decoration: const InputDecoration(),
                                        items: _statusPermitidos
                                            .map((s) => DropdownMenuItem(
                                                value: s,
                                                child: Text(
                                                    _statusLabels[s] ?? s)))
                                            .toList(),
                                        onChanged: _isEditing
                                            ? (v) => setState(
                                                () => _status = v ?? _status)
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: AppColors.accent
                                              .withValues(alpha: 0.2)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text('Valor Total da OS',
                                            style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color:
                                                    AppColors.textSecondary)),
                                        const SizedBox(height: 4),
                                        Text(
                                          'R\$ ${_valorTotal.toStringAsFixed(2).replaceAll('.', ',')}',
                                          style: GoogleFonts.inter(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.accent),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SwitchListTile(
                                value: _notificarWhatsApp,
                                onChanged: (v) =>
                                    setState(() => _notificarWhatsApp = v),
                                title: Text('Notificar cliente via WhatsApp',
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500)),
                                subtitle: Text(
                                    'Envia atualização de status ao cliente',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textMuted)),
                                contentPadding: EdgeInsets.zero,
                                activeColor: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildServicosCards() {
    return List.generate(_servicos.length, (index) {
      final s = _servicos[index];
      final qty = int.tryParse(s.quantidade.text) ?? 0;
      final val = double.tryParse(s.valorUnitario.text) ?? 0;
      final total = qty * val;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text('${index + 1}',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Serviço ${index + 1}',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const Spacer(),
                  Text(
                    'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.accent),
                  ),
                  const SizedBox(width: 8),
                  if (_servicos.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: AppColors.error),
                      onPressed: () => _removerServico(index),
                      tooltip: 'Remover serviço',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _Field(
                        label: 'Descrição do Serviço',
                        controller: s.descricao,
                        required: true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                        label: 'Qtd',
                        controller: s.quantidade,
                        required: true,
                        keyboard: TextInputType.number,
                        onChanged: () => setState(() {})),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                        label: 'Valor Unit. (R\$)',
                        controller: s.valorUnitario,
                        required: true,
                        keyboard: TextInputType.number,
                        onChanged: () => setState(() {})),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  List<Widget> _buildItensEstoqueCards() {
    return List.generate(_itensEstoque.length, (index) {
      final i = _itensEstoque[index];
      final qty = int.tryParse(i.quantidade.text) ?? 0;
      final val = double.tryParse(i.valorUnitario.text) ?? 0;
      final total = qty * val;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.inventory_2_outlined,
                          size: 16, color: Color(0xFF8B5CF6)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(i.nomeItem,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text('Código: ${i.codigoItem}',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: const Color(0xFF8B5CF6)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 20, color: AppColors.error),
                    onPressed: () => _removerItemEstoque(index),
                    tooltip: 'Remover item',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (i.estoqueDisponivel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Estoque: ${i.estoqueDisponivel}',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                        label: 'Quantidade',
                        controller: i.quantidade,
                        required: true,
                        keyboard: TextInputType.number,
                        onChanged: () => setState(() {})),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                        label: 'Valor Unit. (R\$)',
                        controller: i.valorUnitario,
                        required: true,
                        keyboard: TextInputType.number,
                        onChanged: () => setState(() {})),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ============ Data Models ============

class _ServicoEntry {
  final TextEditingController descricao;
  final TextEditingController quantidade;
  final TextEditingController valorUnitario;

  _ServicoEntry({
    TextEditingController? descricao,
    TextEditingController? quantidade,
    TextEditingController? valorUnitario,
  })  : descricao = descricao ?? TextEditingController(),
        quantidade = quantidade ?? TextEditingController(text: '1'),
        valorUnitario = valorUnitario ?? TextEditingController(text: '0');

  void dispose() {
    descricao.dispose();
    quantidade.dispose();
    valorUnitario.dispose();
  }
}

class _ItemEstoqueEntry {
  final int? stockItemId;
  final String nomeItem;
  final String codigoItem;
  final TextEditingController quantidade;
  final TextEditingController valorUnitario;
  final int? estoqueDisponivel;

  _ItemEstoqueEntry({
    this.stockItemId,
    this.nomeItem = '',
    this.codigoItem = '',
    TextEditingController? quantidade,
    TextEditingController? valorUnitario,
    this.estoqueDisponivel,
  })  : quantidade = quantidade ?? TextEditingController(text: '1'),
        valorUnitario = valorUnitario ?? TextEditingController(text: '0');

  void dispose() {
    quantidade.dispose();
    valorUnitario.dispose();
  }
}

// ============ Widgets ============

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.accent),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ],
    );
  }
}

class _CardSection extends StatelessWidget {
  final List<Widget> children;
  const _CardSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool required;
  final int maxLines;
  final TextInputType? keyboard;
  final VoidCallback? onChanged;
  const _Field(
      {required this.label,
      required this.controller,
      this.required = false,
      this.maxLines = 1,
      this.keyboard,
      this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboard,
          onChanged: onChanged != null ? (_) => onChanged!() : null,
          validator: required
              ? (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null
              : null,
        ),
      ],
    );
  }
}
