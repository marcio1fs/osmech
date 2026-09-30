import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/mecanico_service.dart';
import '../services/os_service.dart';
import '../services/stock_service.dart';
import '../services/api_client.dart';
import '../services/api_config.dart';
import '../theme/app_theme.dart';
import '../utils/receipt_print.dart';
import '../mixins/auth_error_mixin.dart';
import '../widgets/upper_text.dart';
import 'os_form_components.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

/// Formulario de criação/edição de OS — com suporte a multiplos serviços e itens de estoque.
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
  late final TextEditingController _clienteDocumento;
  late final TextEditingController _clienteTelefone;
  late final TextEditingController _placa;
  late final TextEditingController _modelo;
  late final TextEditingController _montadora;
  late final TextEditingController _corVeiculo;
  late final TextEditingController _ano;
  late final TextEditingController _km;
  late final TextEditingController _diagnostico;
  bool _applyingMask = false;
  String _status = 'ABERTA';
  bool _notificarWhatsApp = false;
  bool _loading = false;
  bool _closingOs = false;
  bool _saved = false;
  bool _formSubmitted = false;
  bool _vendaRapida = false;

  final _telefoneFormatter = MaskTextInputFormatter(
      mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});
  
  final _documentoFormatter = MaskTextInputFormatter(
      mask: '###.###.###-##', 
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy);

  // Serviços dinamicos
  final List<_ServicoEntry> _servicos = [];

  // Itens de estoque dinamicos
  final List<_ItemEstoqueEntry> _itensEstoque = [];

  // Itens de estoque disponíveis (carregados da API)
  List<Map<String, dynamic>> _stockItems = [];
  bool _loadingStock = false;
  List<Map<String, dynamic>> _mecanicos = [];
  List<String> _montadorasDisponiveis = [];
  bool _loadingMontadoras = false;
  bool _montadorasCarregadas = false;
  static const List<String> _montadorasBaseBrasil = [
    'Abarth',
    'Audi',
    'BMW',
    'BYD',
    'Caoa Chery',
    'Chevrolet',
    'Citroën',
    'Fiat',
    'Ford',
    'GWM',
    'Honda',
    'Hyundai',
    'JAC Motors',
    'Jeep',
    'Kia',
    'Land Rover',
    'Lexus',
    'Mercedes-Benz',
    'MINI',
    'Mitsubishi',
    'Nissan',
    'Peugeot',
    'Porsche',
    'RAM',
    'Renault',
    'Subaru',
    'Suzuki',
    'Toyota',
    'Volkswagen',
    'Volvo',
  ];

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
        title: UpperText('Descartar alterações?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: UpperText(
          'Você tem alterações não salvas. Deseja sair sem salvar?',
          style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const UpperText('Continuar editando')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const UpperText('Descartar'),
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
    'AGUARDANDO_PECA': 'Aguardando Peca',
    'AGUARDANDO_APROVACAO': 'Ag. Aprovacao',
    'CONCLUIDA': 'Concluida',
    'CANCELADA': 'Cancelada',
  };

  List<String> get _statusPermitidos {
    if (!_isEditing) return ['ABERTA'];
    return _transicoesValidas[_status] ?? ['ABERTA'];
  }

  String _nomeUsuarioLogado() {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      return (auth.nome ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  int? _parseIntOrNull(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return null;
    return int.tryParse(digitsOnly);
  }

  double _parseDoubleOrZero(String raw) {
    return double.tryParse(raw.replaceAll(',', '.').trim()) ?? 0;
  }

  String _digitsOnly(String raw) => raw.replaceAll(RegExp(r'[^0-9]'), '');

  String _nomeMecanicoPorId(int? mecanicoId) {
    if (mecanicoId == null) return '';
    for (final mecanico in _mecanicos) {
      if (mecanico['id'] == mecanicoId) {
        return (mecanico['nome'] ?? '').toString();
      }
    }
    return '';
  }

  String _normalizePlaca(String raw) {
    final placa = raw.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    return placa.length > 7 ? placa.substring(0, 7) : placa;
  }

  /// Formata a placa conforme o usuário digita:
  /// - Mercosul (LKJ5G35): 3 letras + 1 número + 1 letra + 2 números → sem hífen
  /// - Antiga   (ABC1234): 3 letras + 4 números → com hífen: ABC-1234
  /// Enquanto digita, aplica o hífen automaticamente no formato antigo.
  String _formatPlaca(String value) {
    final norm = _normalizePlaca(value);
    if (norm.length < 4) return norm;
    // Detecta formato antigo: posição 3 é número E posição 4 (se existir) é número
    final pos3IsDigit = RegExp(r'[0-9]').hasMatch(norm[3]);
    final pos4IsDigit = norm.length > 4 ? RegExp(r'[0-9]').hasMatch(norm[4]) : true;
    if (pos3IsDigit && pos4IsDigit) {
      // Formato antigo: ABC-1234
      return norm.length <= 3 ? norm : '${norm.substring(0, 3)}-${norm.substring(3)}';
    }
    // Mercosul: sem hífen
    return norm;
  }



  void _setMaskedText(TextEditingController controller, String value) {
    _applyingMask = true;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _applyingMask = false;
  }

  void _onPlacaChanged() {
    if (_applyingMask) return;
    final masked = _formatPlaca(_placa.text);
    if (_placa.text != masked) {
      _setMaskedText(_placa, masked);
    }
  }

  bool _isValidTelefone(String telefone) {
    final digits = _digitsOnly(telefone);
    return digits.length == 10 || digits.length == 11;
  }

  bool _isValidPlaca(String placa) {
    final norm = _normalizePlaca(placa);
    // Mercosul: AAA0A00
    if (RegExp(r'^[A-Z]{3}[0-9][A-Z][0-9]{2}$').hasMatch(norm)) return true;
    // Antiga:   AAA0000
    if (RegExp(r'^[A-Z]{3}[0-9]{4}$').hasMatch(norm)) return true;
    return false;
  }

  bool _isValidCpf(String cpf) {
    final digits = _digitsOnly(cpf);
    if (digits.length != 11) return false;
    if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return false;

    int calcDigit(String base, List<int> weights) {
      int sum = 0;
      for (int i = 0; i < weights.length; i++) {
        sum += int.parse(base[i]) * weights[i];
      }
      final mod = sum % 11;
      return mod < 2 ? 0 : 11 - mod;
    }

    final d1 = calcDigit(digits.substring(0, 9), [10, 9, 8, 7, 6, 5, 4, 3, 2]);
    final d2 = calcDigit(
      digits.substring(0, 10),
      [11, 10, 9, 8, 7, 6, 5, 4, 3, 2],
    );
    return digits[9] == d1.toString() && digits[10] == d2.toString();
  }

  bool _isValidCnpj(String cnpj) {
    final digits = _digitsOnly(cnpj);
    if (digits.length != 14) return false;
    if (RegExp(r'^(\d)\1{13}$').hasMatch(digits)) return false;

    int calcDigit(String base, List<int> weights) {
      int sum = 0;
      for (int i = 0; i < weights.length; i++) {
        sum += int.parse(base[i]) * weights[i];
      }
      final mod = sum % 11;
      return mod < 2 ? 0 : 11 - mod;
    }

    final d1 = calcDigit(
        digits.substring(0, 12), [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]);
    final d2 = calcDigit(
        digits.substring(0, 13), [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]);
    return digits[12] == d1.toString() && digits[13] == d2.toString();
  }

  void _onDocumentoChanged() {
    final digits = _digitsOnly(_clienteDocumento.text);
    if (digits.length <= 11 && _documentoFormatter.getMask() != '###.###.###-##') {
       _documentoFormatter.updateMask(mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});
    } else if (digits.length > 11 && _documentoFormatter.getMask() != '##.###.###/####-##') {
       _documentoFormatter.updateMask(mask: '##.###.###/####-##', filter: {"#": RegExp(r'[0-9]')});
    }
  }

  String? _validateDocumento(String? value) {
    final input = value ?? '';
    final digits = _digitsOnly(input);
    if (digits.isEmpty) return null; // optional
    if (digits.length == 11) {
      return _isValidCpf(digits) ? null : 'CPF inválido';
    } else if (digits.length == 14) {
      return _isValidCnpj(digits) ? null : 'CNPJ inválido';
    } else {
      return 'Documento inválido';
    }
  }

  void _toggleVendaRapida(bool value) {
    setState(() {
      _vendaRapida = value;
      if (_vendaRapida) {
        _clienteNome.text = 'Consumidor Final';
        _clienteTelefone.text = '';
        _placa.text = 'BALCAO';
        _modelo.text = 'BALCAO';
        _montadora.text = '';
        _corVeiculo.text = '';
        _ano.text = '';
        _km.text = '';
      } else {
        if (_clienteNome.text == 'Consumidor Final') _clienteNome.text = '';
        if (_placa.text == 'BALCAO') _placa.text = '';
        if (_modelo.text == 'BALCAO') _modelo.text = '';
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final d = widget.osData;
    _clienteNome = TextEditingController(text: d?['clienteNome'] ?? '');
    _clienteDocumento = TextEditingController(
        text: d?['clienteCpf'] ?? d?['clienteCnpj'] ?? '');
    _clienteTelefone = TextEditingController(text: d?['clienteTelefone'] ?? '');
    _placa = TextEditingController(text: d?['placa'] ?? '');
    _modelo = TextEditingController(text: d?['modelo'] ?? '');
    _montadora = TextEditingController(text: d?['montadora'] ?? '');
    _corVeiculo = TextEditingController(text: d?['corVeiculo'] ?? '');
    _ano = TextEditingController(text: d?['ano']?.toString() ?? '');
    final kmExistente = d?['quilometragem'] ?? d?['km'];
    _km = TextEditingController(text: kmExistente?.toString() ?? '');
    _diagnostico = TextEditingController(text: d?['diagnostico'] ?? '');
    _status = d?['status'] ?? 'ABERTA';
    _notificarWhatsApp = d?['whatsappConsentimento'] ?? false;
    final placaVal = d?['placa'] ?? '';
    _vendaRapida = placaVal == 'BALCAO';
    _placa.addListener(_onPlacaChanged);
    _clienteDocumento.addListener(_onDocumentoChanged);
    _onDocumentoChanged();
    _onPlacaChanged();

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
          percentualComissao: TextEditingController(
              text: (s['percentualComissao'] ?? 0).toString()),
          mecanicoId: s['mecanicoId'] != null ? (s['mecanicoId'] as num).toInt() : null,
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

    // Se novo formulario, adicionar um serviço vazio
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

    // Carregar itens de estoque disponiveis
    _carregarStockItems();
    _carregarMecanicos();
    _carregarDadosCompletosOs();
  }

  Future<void> _carregarDadosCompletosOs() async {
    if (!_isEditing) return;
    final id = widget.osData?['id'];
    if (id == null) return;

    try {
      final osService = OsService(token: safeToken);
      final os = await osService.buscarPorId(id);
      if (!mounted) return;

      final km = os['quilometragem'] ?? os['km'];
      final statusAtualizado = (os['status'] ?? '').toString().trim();
      setState(() {
        _clienteDocumento.text =
            (os['clienteCpf'] ?? os['clienteCnpj'] ?? '').toString();
        _placa.text = (os['placa'] ?? '').toString();
        _montadora.text = (os['montadora'] ?? '').toString();
        _corVeiculo.text = (os['corVeiculo'] ?? '').toString();
        _onDocumentoChanged();
        _onPlacaChanged();
        _km.text = km?.toString() ?? '';
        if (statusAtualizado.isNotEmpty) {
          _status = statusAtualizado;
        }
      });
    } catch (e) {
      handleAuthError(e);
    }
  }

  Future<void> _carregarMecanicos() async {
    try {
      final service = MecanicoService(token: safeToken);
      final data = await service.listar(ativosOnly: true);
      if (!mounted) return;
      setState(() {
        _mecanicos = data;
      });
    } catch (e) {
      handleAuthError(e);
    }
  }

  Future<void> _carregarStockItems() async {
    if (!mounted) return;
    setState(() => _loadingStock = true);
    try {
      final stockService = StockService(token: safeToken);
      final items = await stockService.listarItens();
      if (!mounted) return;
      setState(() {
        _stockItems = items.where((i) => (i['ativo'] ?? true) == true).toList();
        _loadingStock = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (!handleAuthError(e)) {
        setState(() => _loadingStock = false);
      }
    }
  }

  Future<void> _carregarMontadoras({bool force = false}) async {
    if (_loadingMontadoras) return;
    if (_montadorasCarregadas && !force) return;

    if (!mounted) return;
    setState(() => _loadingMontadoras = true);
    final montadorasMap = <String, String>{};

    for (final montadoraBase in _montadorasBaseBrasil) {
      final chave = _normalizarChaveMontadora(montadoraBase);
      montadorasMap[chave] = montadoraBase;
    }

    final montadoraAtual = _montadora.text.trim();
    if (montadoraAtual.isNotEmpty) {
      final chave = _normalizarChaveMontadora(montadoraAtual);
      montadorasMap.putIfAbsent(chave, () => montadoraAtual);
    }

    try {
      final osService = OsService(token: safeToken);
      final ordens = await osService.listar();

      for (final os in ordens) {
        final montadora = (os['montadora'] ?? '').toString().trim();
        if (montadora.isNotEmpty) {
          final chave = _normalizarChaveMontadora(montadora);
          montadorasMap.putIfAbsent(chave, () => montadora);
        }
      }

      final lista = montadorasMap.values.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      if (!mounted) return;
      setState(() {
        _montadorasDisponiveis = lista;
        _montadorasCarregadas = true;
        _loadingMontadoras = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (handleAuthError(e)) {
        return;
      }

      final lista = montadorasMap.values.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      setState(() {
        _montadorasDisponiveis = lista;
        _montadorasCarregadas = true;
        _loadingMontadoras = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: UpperText('Montadoras carregadas da lista local'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  String _normalizarChaveMontadora(String valor) {
    var v = valor.toLowerCase().trim();
    const substituicoes = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };
    substituicoes.forEach((origem, destino) {
      v = v.replaceAll(origem, destino);
    });
    v = v.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return v;
  }

  @override
  void dispose() {
    _placa.removeListener(_onPlacaChanged);
    _clienteDocumento.removeListener(_onDocumentoChanged);
    _clienteNome.dispose();
    _clienteDocumento.dispose();
    _clienteTelefone.dispose();
    _placa.dispose();
    _modelo.dispose();
    _montadora.dispose();
    _corVeiculo.dispose();
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
    // Filtrar itens que ja¡ foram adicionados
    final idsJaAdicionados = _itensEstoque.map((i) => i.stockItemId).toSet();
    final disponiveis = _stockItems
        .where((item) => !idsJaAdicionados.contains(item['id']))
        .where((item) => (item['quantidade'] ?? 0) > 0)
        .toList();

    if (disponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: UpperText('Nenhum item de estoque disponível'),
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
            title: UpperText('Selecionar Item do Estoque',
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
                            child: UpperText('Nenhum item encontrado',
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
                                title: UpperText(item['nome'] ?? '',
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600)),
                                subtitle: UpperText(
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
                  child: const UpperText('Cancelar')),
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

  Future<void> _encerrarOsPeloFormulario() async {
    if (!_isEditing) return;
    final id = widget.osData?['id'];
    if (id == null) return;
    if (_status == 'CONCLUIDA') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: UpperText('Esta OS já está concluída'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_isDirty) {
      final continuar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: UpperText('Encerrar OS',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: UpperText(
            'Existem alterações não salvas neste formulário. Deseja encerrar mesmo assim?',
            style:
                GoogleFonts.inter(color: AppColors.textSecondary, height: 1.45),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const UpperText('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const UpperText('Continuar')),
          ],
        ),
      );
      if (continuar != true) return;
    }

    final config = await _abrirDialogoEncerramento();
    if (config == null) return;

    setState(() => _closingOs = true);
    try {
      final osService = OsService(token: safeToken);
      final response = await osService.encerrar(id, {
        'metodoPagamento': config.metodoPagamento,
        'descontoPercentual': config.descontoPercentual,
        'enviarReciboWhatsapp': config.enviarWhatsapp,
        'telefoneWhatsapp': config.telefoneWhatsapp?.trim().isEmpty == true
            ? null
            : config.telefoneWhatsapp?.trim(),
        'observacoesPagamento': config.observacoes?.trim().isEmpty == true
            ? null
            : config.observacoes?.trim(),
      });

      if (!mounted) return;
      setState(() => _status = 'CONCLUIDA');

      final recibo = (response['recibo'] ?? '').toString();
      final detalhe = (response['whatsappDetalhe'] ?? '').toString();
      final destinoWhatsapp = (response['whatsappDestino'] ?? '').toString();
      final logoUrl = await _buscarLogoUrl();
      
      await _mostrarReciboDialog(
        recibo,
        detalhe,
        telefoneWhatsapp: destinoWhatsapp.isNotEmpty
            ? destinoWhatsapp
            : _clienteTelefone.text,
        logoUrl: logoUrl,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: UpperText('OS encerrada com sucesso'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!handleAuthError(e) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: UpperText('Erro ao encerrar OS: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    if (mounted) setState(() => _closingOs = false);
  }

  Future<_EncerrarConfig?> _abrirDialogoEncerramento() async {
    final telefoneController =
        TextEditingController(text: _clienteTelefone.text);
    final obsController = TextEditingController();
    final descontoController = TextEditingController(text: '0');
    double descontoPerc = 0;
    String metodoPagamento = 'PIX';
    bool enviarWhatsapp = _notificarWhatsApp;

    final result = await showDialog<_EncerrarConfig>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: UpperText('Encerrar OS',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: metodoPagamento,
                    decoration:
                        const InputDecoration(labelText: 'Forma de pagamento'),
                    items: const [
                      DropdownMenuItem(value: 'PIX', child: UpperText('PIX')),
                      DropdownMenuItem(
                          value: 'DINHEIRO', child: UpperText('Dinheiro')),
                      DropdownMenuItem(value: 'CARTAO', child: UpperText('Cartão')),
                      DropdownMenuItem(value: 'BOLETO', child: UpperText('Boleto')),
                      DropdownMenuItem(
                          value: 'TRANSFERENCIA', child: UpperText('Transferência')),
                      DropdownMenuItem(
                          value: 'PRAZO_30_DIAS', child: UpperText('A Prazo (30 dias)')),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => metodoPagamento = v ?? 'PIX'),
                  ),
                  const SizedBox(height: 16),
                  UpperText(
                    'Desconto (0% a 10%)',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: descontoController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            suffixText: '%',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                          ),
                          onChanged: (v) {
                            final val = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                            setDialogState(() {
                              descontoPerc = val.clamp(0.0, 10.0);
                              if (val > 10) descontoController.text = '10';
                              if (val < 0) descontoController.text = '0';
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: descontoPerc.clamp(0.0, 10.0),
                          min: 0,
                          max: 10,
                          divisions: 10,
                          label: '${descontoPerc.toStringAsFixed(0)}%',
                          activeColor: AppColors.primary,
                          onChanged: (v) {
                            setDialogState(() {
                              descontoPerc = v;
                              descontoController.text = v.toStringAsFixed(0);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UpperText(
                          'Resumo dos Valores',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            UpperText('Valor total:', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                            UpperText(
                              'R\$ ${_formatNum(_valorTotal)}',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        if (descontoPerc > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: UpperText(
                                  'Desconto (${descontoPerc.toStringAsFixed(0)}%):',
                                  style: GoogleFonts.inter(color: AppColors.error, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              UpperText(
                                '- R\$ ${_formatNum(_valorTotal * descontoPerc / 100)}',
                                style: GoogleFonts.inter(color: AppColors.error, fontSize: 13),
                              ),
                            ],
                          ),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              UpperText(
                                'Valor final:',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: UpperText(
                                  'R\$ ${_formatNum(_valorTotal * (1 - descontoPerc / 100))}',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.success, fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: obsController,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [UpperCaseTextFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Observações do pagamento (opcional)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: enviarWhatsapp,
                    onChanged: (v) => setDialogState(() => enviarWhatsapp = v),
                    contentPadding: EdgeInsets.zero,
                    title: const UpperText('Enviar recibo por WhatsApp'),
                  ),
                  if (enviarWhatsapp)
                    TextField(
                      controller: telefoneController,
                      keyboardType: TextInputType.phone,
                      decoration:
                          const InputDecoration(labelText: 'Telefone WhatsApp'),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const UpperText('Cancelar')),
            FilledButton(
              onPressed: () => Navigator.pop(
                ctx,
                _EncerrarConfig(
                  metodoPagamento: metodoPagamento,
                  descontoPercentual: descontoPerc,
                  enviarWhatsapp: enviarWhatsapp,
                  telefoneWhatsapp: telefoneController.text,
                  observacoes: obsController.text,
                ),
              ),
              child: const UpperText('Encerrar'),
            ),
          ],
        ),
      ),
    );

    telefoneController.dispose();
    obsController.dispose();
    descontoController.dispose();
    return result;
  }

  String _normalizarTelefoneWhatsapp(String telefone) {
    final digits = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    if (digits.startsWith('55')) return digits;
    if (digits.length == 10 || digits.length == 11) return '55$digits';
    return digits;
  }

  Future<void> _enviarReciboWhatsapp(String recibo, String telefone) async {
    final destino = _normalizarTelefoneWhatsapp(telefone);
    if (destino.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: UpperText('Informe um telefone válido para WhatsApp'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    final url = Uri.parse(
      'https://wa.me/$destino?text=${Uri.encodeComponent(recibo)}',
    );
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: UpperText('Não foi possível abrir o WhatsApp'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<String?> _buscarLogoUrl() async {
    try {
      final api = ApiClient(token: safeToken);
      final response = await api.get('/api/usuario/perfil');
      if (response.statusCode == 200) {
        final profile = jsonDecode(response.body) as Map<String, dynamic>;
        final logo = profile['logoUrl']?.toString();
        if (logo != null && logo.isNotEmpty) {
          return ApiConfig.absoluteUrl(logo);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _imprimirRecibo(String recibo, {String? logoUrl}) async {
    try {
      final id = widget.osData?['id'] ?? 'nova';
      await printReceiptText(recibo, 'Recibo_OS_$id', logoUrl: logoUrl);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: UpperText('Não foi possível abrir a tela de impressão: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _mostrarReciboDialog(String recibo, String whatsappDetalhe,
      {String? telefoneWhatsapp, String? logoUrl}) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            if (logoUrl != null && logoUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  logoUrl,
                  height: 36,
                  width: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: 10),
            ],
            UpperText('Recibo / Extrato',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 640,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (whatsappDetalhe.isNotEmpty) ...[
                UpperText('WhatsApp: $whatsappDetalhe',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
              ],
              Flexible(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 420),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                    recibo,
                    style: GoogleFonts.robotoMono(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _enviarReciboWhatsapp(
                recibo, telefoneWhatsapp ?? _clienteTelefone.text),
            icon: const Icon(Icons.chat_rounded, size: 16),
            label: const UpperText('Enviar WhatsApp'),
          ),
          TextButton.icon(
            onPressed: () => _imprimirRecibo(recibo, logoUrl: logoUrl),
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const UpperText('Imprimir recibo'),
          ),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: recibo));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: UpperText('Recibo copiado para a área de transferência'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const UpperText('Copiar recibo'),
          ),
          FilledButton(
              onPressed: () => Navigator.pop(ctx), child: const UpperText('Fechar')),
        ],
      ),
    );
  }

  Future<void> _salvar() async {
    setState(() => _formSubmitted = true);
    if (!_formKey.currentState!.validate()) return;

    // Validar que tem pelo menos um serviço ou pelo menos um item de estoque
    final servicosValidos =
        _servicos.where((s) => s.descricao.text.trim().isNotEmpty).toList();
    final itensValidos =
        _itensEstoque.where((i) => i.stockItemId != null).toList();

    if (servicosValidos.isEmpty && itensValidos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: UpperText('Adicione pelo menos um serviço ou item/peça'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final osService = OsService(token: safeToken);

      // Montar lista de serviços
      final servicos = servicosValidos.map((s) {
        return {
          'descricao': s.descricao.text.trim(),
          'quantidade': int.tryParse(s.quantidade.text) ?? 1,
          'valorUnitario': _parseDoubleOrZero(s.valorUnitario.text),
          'mecanicoId': s.mecanicoId,
          'percentualComissao': _parseDoubleOrZero(s.percentualComissao.text),
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

      // Deriva mecanicoResponsavel do primeiro serviço com mecânico atribuído
      final mecanicoDoServico = _servicos
          .where((s) => s.mecanicoId != null)
          .map((s) => _nomeMecanicoPorId(s.mecanicoId))
          .where((nome) => nome.isNotEmpty)
          .firstOrNull;
      final mecanicoPayload = mecanicoDoServico ?? _nomeUsuarioLogado();
      final documentoDigits = _digitsOnly(_clienteDocumento.text);
      final clienteCpf = documentoDigits.length == 11 ? documentoDigits : '';
      final clienteCnpj = documentoDigits.length == 14 ? documentoDigits : '';
      final placaNormalizada = _normalizePlaca(_placa.text);

      final data = {
        'clienteNome': _clienteNome.text.trim(),
        'clienteCpf': clienteCpf,
        'clienteCnpj': clienteCnpj,
        'clienteTelefone': _clienteTelefone.text.trim(),
        'placa': placaNormalizada,
        'modelo': _modelo.text.trim(),
        'montadora': _montadora.text.trim(),
        'corVeiculo': _corVeiculo.text.trim(),
        'ano': int.tryParse(_ano.text.trim()),
        'quilometragem': _parseIntOrNull(_km.text),
        'diagnostico': _diagnostico.text.trim(),
        'mecanicoResponsavel': mecanicoPayload,
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
                content: UpperText('Erro ao salvar: $e'),
                backgroundColor: AppColors.error),
          );
        }
      }
    }
    if (mounted) setState(() => _loading = false);
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
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final backButton = Navigator.canPop(context)
                      ? Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: IconButton(
                            icon:
                                const Icon(Icons.arrow_back_rounded, size: 20),
                            onPressed: () async {
                              if (await _confirmarSaida()) {
                                if (context.mounted) Navigator.pop(context);
                              }
                            },
                          ),
                        )
                      : const SizedBox.shrink();

                  final titleBlock = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      UpperText(
                        _isEditing ? 'Editar OS' : 'Nova Ordem de Serviço',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                      UpperText(
                        _isEditing
                            ? 'Placa: ${widget.osData?['placa'] ?? ''}'
                            : 'Preencha os dados da OS',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  );

                  return Row(
                    children: [
                      backButton,
                      Expanded(child: titleBlock),
                    ],
                  );
                },
              ),
            ),

            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _formSubmitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Toggle Venda Rápida / Balcão
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: _vendaRapida 
                                ? AppColors.accent.withValues(alpha: 0.08) 
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _vendaRapida 
                                  ? AppColors.accent 
                                  : AppColors.border,
                              width: _vendaRapida ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _vendaRapida 
                                      ? AppColors.accent 
                                      : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.point_of_sale_rounded,
                                  color: _vendaRapida ? Colors.white : AppColors.textSecondary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    UpperText(
                                      'Venda Rápida (Balcão / PDV)',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    UpperText(
                                      'Ative para vender peças/itens diretamente sem necessidade de veículo ou serviços',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _vendaRapida,
                                activeTrackColor: AppColors.accent.withValues(alpha: 0.5),
                                activeColor: AppColors.accent,
                                onChanged: (val) => _toggleVendaRapida(val),
                              ),
                            ],
                          ),
                        ),
                        // Section: Cliente
                        const OsSectionHeader(
                            icon: Icons.person_outline_rounded,
                            title: 'Dados do Cliente'),
                        const SizedBox(height: 16),
                        OsCardSection(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: OsField(
                                      label: 'Nome do Cliente',
                                      controller: _clienteNome,
                                      required: true),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: OsField(
                                      label: 'Telefone (WhatsApp)',
                                      controller: _clienteTelefone,
                                      required: !_vendaRapida,
                                      keyboard: TextInputType.phone,
                                      inputFormatters: [_telefoneFormatter],
                                      validator: (v) {
                                        final value = (v ?? '').trim();
                                        if (value.isEmpty) {
                                          if (_vendaRapida) return null;
                                          return 'Campo obrigatório';
                                        }
                                        if (!_isValidTelefone(value)) {
                                          return 'Telefone inválido (use DDD + número)';
                                        }
                                        return null;
                                      }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: OsField(
                                    label: 'CPF/CNPJ',
                                    controller: _clienteDocumento,
                                    keyboard: TextInputType.number,
                                    validator: _validateDocumento,
                                    hintText: '000.000.000-00 ou 00.000.000/0000-00',
                                    inputFormatters: [
                                      _documentoFormatter,
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Keeping the space for layout consistency, but we can remove it if needed
                                // For now, let's keep an empty expanded to maintain UI balance
                                Expanded(
                                  child: Container(),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        if (!_vendaRapida) ...[
                          // Section: Veiculo
                          const OsSectionHeader(
                              icon: Icons.directions_car_outlined,
                              title: 'Dados do Veículo'),
                          const SizedBox(height: 16),
                          OsCardSection(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: OsField(
                                          label: 'Placa',
                                          controller: _placa,
                                          required: true,
                                          hintText: 'ABC-1234',
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                                RegExp(r'[A-Za-z0-9\-]')),
                                          ],
                                          validator: (v) {
                                            if (_vendaRapida) return null;
                                            final value = (v ?? '').trim();
                                            if (value.isEmpty) {
                                              return 'Campo obrigatório';
                                            }
                                            if (!_isValidPlaca(value)) {
                                              return 'Placa inválida';
                                            }
                                            return null;
                                          })),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: OsMontadoraField(
                                      controller: _montadora,
                                      opcoes: _montadorasDisponiveis,
                                      onCarregar: () => _carregarMontadoras(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                      child: OsField(
                                          label: 'Modelo',
                                          controller: _modelo,
                                          required: true)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                      child: OsField(
                                          label: 'Quilometragem',
                                          controller: _km,
                                          keyboard: TextInputType.number)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                      child: OsField(
                                          label: 'Ano',
                                          controller: _ano,
                                          keyboard: TextInputType.number)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                      child: OsField(
                                    label: 'Cor do veículo',
                                    controller: _corVeiculo,
                                  )),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                        ],

                        // Section: Servicos
                        Row(
                          children: [
                            const Expanded(
                              child: OsSectionHeader(
                                  icon: Icons.build_outlined, title: 'Serviços'),
                            ),
                            FilledButton.icon(
                              onPressed: _adicionarServico,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const UpperText('Adicionar Serviço'),
                              style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          alignment: Alignment.topCenter,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _buildServicosCards(),
                          ),
                        ),
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
                              child: UpperText(
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
                            const Expanded(
                              child: OsSectionHeader(
                                  icon: Icons.inventory_2_outlined,
                                  title: 'Itens do Estoque'),
                            ),
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
                                label: const UpperText('Adicionar Peça'),
                                style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF8B5CF6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          alignment: Alignment.topCenter,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _buildItensEstoqueCards(),
                          ),
                        ),
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
                              child: UpperText(
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
                          OsCardSection(
                            children: [
                              Center(
                                child: UpperText(
                                  'Nenhuma peça adicionada. Clique em "Adicionar Peça" para selecionar do estoque.',
                                  style: GoogleFonts.inter(
                                      fontSize: 13, color: AppColors.textMuted),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 28),

                        // Section: Diagnostico e Status
                        const OsSectionHeader(
                            icon: Icons.assignment_outlined,
                            title: 'Diagnóstico e Status'),
                        const SizedBox(height: 16),
                        OsCardSection(
                          children: [
                            OsField(
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
                                      UpperText('Status',
                                          style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary)),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        value: _status,
                                        decoration: const InputDecoration(),
                                        items: _statusPermitidos
                                            .map((s) => DropdownMenuItem(
                                                value: s,
                                                child: UpperText(
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
                                        UpperText('Valor Total da OS',
                                            style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color:
                                                    AppColors.textSecondary)),
                                        const SizedBox(height: 4),
                                        UpperText(
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
                                title: UpperText('Notificar cliente via WhatsApp',
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500)),
                                subtitle: UpperText(
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
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildBottomBar() {
    final totalChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: UpperText(
        'Total: R\$ ${_valorTotal.toStringAsFixed(2).replaceAll('.', ',')}',
        style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.accent),
      ),
    );

    final cancelButton = OutlinedButton(
      onPressed: () async {
        if (await _confirmarSaida()) {
          if (mounted) Navigator.pop(context);
        }
      },
      child: const UpperText('Cancelar'),
    );

    final closeButton = _isEditing && _status != 'CONCLUIDA'
        ? FilledButton.icon(
            onPressed: (_loading || _closingOs)
                ? null
                : _encerrarOsPeloFormulario,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
            ),
            icon: _closingOs
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.receipt_long_rounded, size: 18),
            label: const UpperText('Encerrar OS'),
          )
        : null;

    final saveButton = FilledButton.icon(
      onPressed: _loading ? null : _salvar,
      icon: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.save_rounded, size: 18),
      label: UpperText(_isEditing ? 'Salvar Alterações' : 'Criar OS'),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          totalChip,
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              cancelButton,
              if (closeButton != null) closeButton,
              saveButton,
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildServicosCards() {
    return List.generate(_servicos.length, (index) {
      final s = _servicos[index];
      final qty = int.tryParse(s.quantidade.text) ?? 0;
      final val = _parseDoubleOrZero(s.valorUnitario.text);
      final total = qty * val;
      final percentualComissao = _parseDoubleOrZero(s.percentualComissao.text);
      final valorComissao = total * (percentualComissao / 100);

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
                      child: UpperText('${index + 1}',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: UpperText('Serviço ${index + 1}',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                  ),
                  Flexible(
                    child: UpperText(
                      'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.accent),
                    ),
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
                    child: OsField(
                        label: 'Descrição do Serviço',
                        controller: s.descricao,
                        required: !_vendaRapida && _itensEstoque.where((i) => i.stockItemId != null).isEmpty),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OsField(
                        label: 'Qtd',
                        controller: s.quantidade,
                        required: s.descricao.text.trim().isNotEmpty,
                        keyboard: TextInputType.number,
                        onChanged: () => setState(() {})),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OsField(
                        label: 'Valor Unit. (R\$)',
                        controller: s.valorUnitario,
                        required: s.descricao.text.trim().isNotEmpty,
                        keyboard: TextInputType.number,
                        onChanged: () => setState(() {})),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UpperText('Mecânico do Serviço',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int?>(
                          isExpanded: true,
                          value: _mecanicos.any((m) => (m['id'] as num).toInt() == s.mecanicoId)
                              ? s.mecanicoId
                              : null,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: UpperText('Sem mecanico'),
                        ),
                        ..._mecanicos.map(
                          (mecanico) => DropdownMenuItem<int?>(
                            value: (mecanico['id'] as num).toInt(),
                            child: UpperText((mecanico['nome'] ?? '-').toString()),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          s.mecanicoId = value;
                          if (value == null) {
                            s.percentualComissao.text = '0';
                            return;
                          }
                          final mecanico = _mecanicos.firstWhere(
                            (item) => (item['id'] as num).toInt() == value,
                            orElse: () => <String, dynamic>{},
                          );
                          s.percentualComissao.text =
                              (mecanico['percentualComissao'] ?? 0).toString();
                        });
                      },
                    ),
                  ],
                ),
              ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OsField(
                      label: 'Comissao (%)',
                      controller: s.percentualComissao,
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: () => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: UpperText(
                      s.mecanicoId == null
                          ? 'Comissão não atribuída'
                          : 'Mecanico: ${_nomeMecanicoPorId(s.mecanicoId)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  UpperText(
                    'Comissao: R\$ ${valorComissao.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UpperText(i.nomeItem,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        UpperText('Código: ${i.codigoItem}',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Flexible(
                    child: UpperText(
                      'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: const Color(0xFF8B5CF6)),
                    ),
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
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (i.estoqueDisponivel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: UpperText(
                        'Estoque: ${i.estoqueDisponivel}',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OsField(
                        label: 'Quantidade',
                        controller: i.quantidade,
                        required: true,
                        keyboard: TextInputType.number,
                        onChanged: () => setState(() {})),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OsField(
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
  final TextEditingController percentualComissao;
  int? mecanicoId;

  _ServicoEntry({
    TextEditingController? descricao,
    TextEditingController? quantidade,
    TextEditingController? valorUnitario,
    TextEditingController? percentualComissao,
    this.mecanicoId,
  })  : descricao = descricao ?? TextEditingController(),
        quantidade = quantidade ?? TextEditingController(text: '1'),
        valorUnitario = valorUnitario ?? TextEditingController(text: '0'),
        percentualComissao =
            percentualComissao ?? TextEditingController(text: '0');

  void dispose() {
    descricao.dispose();
    quantidade.dispose();
    valorUnitario.dispose();
    percentualComissao.dispose();
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

class _EncerrarConfig {
  final String metodoPagamento;
  final double descontoPercentual;
  final bool enviarWhatsapp;
  final String? telefoneWhatsapp;
  final String? observacoes;

  _EncerrarConfig({
    required this.metodoPagamento,
    required this.descontoPercentual,
    required this.enviarWhatsapp,
    this.telefoneWhatsapp,
    this.observacoes,
  });
}

// ============ Widgets ============


