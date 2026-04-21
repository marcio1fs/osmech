import 'dart:convert';
import '../widgets/upper_text.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/mecanico_service.dart';
import '../services/os_service.dart';
import '../services/stock_service.dart';
import '../theme/app_theme.dart';
import '../mixins/auth_error_mixin.dart';
import '../widgets/upper_text.dart';

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

  String _formatPhone(String value) {
    final digits = _digitsOnly(value);
    if (digits.isEmpty) return '';
    final d = digits.length > 11 ? digits.substring(0, 11) : digits;
    if (d.length <= 2) return '($d';
    if (d.length <= 6) return '(${d.substring(0, 2)}) ${d.substring(2)}';
    if (d.length <= 10) {
      return '(${d.substring(0, 2)}) ${d.substring(2, 6)}-${d.substring(6)}';
    }
    return '(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}';
  }

  String _formatCpf(String value) {
    final digits = _digitsOnly(value);
    if (digits.isEmpty) return '';
    final d = digits.length > 11 ? digits.substring(0, 11) : digits;
    if (d.length <= 3) return d;
    if (d.length <= 6) return '${d.substring(0, 3)}.${d.substring(3)}';
    if (d.length <= 9) {
      return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6)}';
    }
    return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
  }

  String _formatCnpj(String value) {
    final digits = _digitsOnly(value);
    if (digits.isEmpty) return '';
    final d = digits.length > 14 ? digits.substring(0, 14) : digits;
    if (d.length <= 2) return d;
    if (d.length <= 5) return '${d.substring(0, 2)}.${d.substring(2)}';
    if (d.length <= 8)
      return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5)}';
    if (d.length <= 12) {
      return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5, 8)}/${d.substring(8)}';
    }
    return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5, 8)}/${d.substring(8, 12)}-${d.substring(12)}';
  }

  void _setMaskedText(TextEditingController controller, String value) {
    _applyingMask = true;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _applyingMask = false;
  }

  void _onTelefoneChanged() {
    if (_applyingMask) return;
    final masked = _formatPhone(_clienteTelefone.text);
    if (_clienteTelefone.text != masked) {
      _setMaskedText(_clienteTelefone, masked);
    }
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
    if (_applyingMask) return;
    final masked = _formatDocumento(_clienteDocumento.text);
    if (_clienteDocumento.text != masked) {
      _setDocumentoMaskedText(masked);
    }
  }

  void _setDocumentoMaskedText(String value) {
    _applyingMask = true;
    _clienteDocumento.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _applyingMask = false;
  }

  String _formatDocumento(String value) {
    final digits = _digitsOnly(value);
    if (digits.isEmpty) return '';
    // If the digits are 11 or less, format as CPF, else as CNPJ (up to 14)
    if (digits.length <= 11) {
      return _formatCpf(digits);
    } else {
      return _formatCnpj(digits);
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
    _clienteTelefone.addListener(_onTelefoneChanged);
    _placa.addListener(_onPlacaChanged);
    _clienteDocumento.addListener(_onDocumentoChanged);
    _onTelefoneChanged();
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

  Future<void> _carregarMontadoras({bool force = false}) async {
    if (_loadingMontadoras) return;
    if (_montadorasCarregadas && !force) return;

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
    _clienteTelefone.removeListener(_onTelefoneChanged);
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
          content: UpperText('Esta OS ja esta concluida'),
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
            'Existem alteracoes nao salvas neste formulario. Deseja encerrar mesmo assim?',
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
      await _mostrarReciboDialog(
        recibo,
        detalhe,
        telefoneWhatsapp: destinoWhatsapp.isNotEmpty
            ? destinoWhatsapp
            : _clienteTelefone.text,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: metodoPagamento,
                  decoration:
                      const InputDecoration(labelText: 'Forma de pagamento'),
                  items: const [
                    DropdownMenuItem(value: 'PIX', child: UpperText('PIX')),
                    DropdownMenuItem(
                        value: 'DINHEIRO', child: UpperText('Dinheiro')),
                    DropdownMenuItem(value: 'CARTAO', child: UpperText('Cartao')),
                    DropdownMenuItem(value: 'BOLETO', child: UpperText('Boleto')),
                    DropdownMenuItem(
                        value: 'TRANSFERENCIA', child: UpperText('Transferencia')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => metodoPagamento = v ?? 'PIX'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: obsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Observacoes do pagamento (opcional)',
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
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const UpperText('Cancelar')),
            FilledButton(
              onPressed: () => Navigator.pop(
                ctx,
                _EncerrarConfig(
                  metodoPagamento: metodoPagamento,
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
          content: UpperText('Informe um telefone valido para WhatsApp'),
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
          content: UpperText('Nao foi possivel abrir o WhatsApp'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _imprimirRecibo(String recibo) async {
    final html = '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Recibo OSMech</title>
  <style>
    body { font-family: Consolas, monospace; padding: 24px; white-space: pre-wrap; }
  </style>
</head>
<body>${recibo.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;')}</body>
<script>window.print();</script>
</html>''';
    final uri = Uri.dataFromString(html,
        mimeType: 'text/html', encoding: Encoding.getByName('utf-8'));
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: UpperText('Nao foi possivel abrir a tela de impressao'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _mostrarReciboDialog(String recibo, String whatsappDetalhe,
      {String? telefoneWhatsapp}) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: UpperText('Recibo / Extrato',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
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
              Container(
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
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                      height: 1.4,
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
            onPressed: () => _imprimirRecibo(recibo),
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const UpperText('Imprimir recibo'),
          ),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: recibo));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: UpperText('Recibo copiado para a area de transferencia'),
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
    if (!_formKey.currentState!.validate()) return;

    // Validar que tem pelo menos um serviço com descrição
    final servicosValidos =
        _servicos.where((s) => s.descricao.text.trim().isNotEmpty).toList();
    if (servicosValidos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: UpperText('Adicione pelo menos um serviço'),
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
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 900;

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

                  final totalChip = Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3)),
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
                        if (context.mounted) Navigator.pop(context);
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
                              : const Icon(Icons.receipt_long_rounded,
                                  size: 18),
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

                  final actions = Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      totalChip,
                      cancelButton,
                      if (closeButton != null) closeButton,
                      saveButton,
                    ],
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            backButton,
                            Expanded(child: titleBlock),
                          ],
                        ),
                        const SizedBox(height: 12),
                        actions,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      backButton,
                      Expanded(child: titleBlock),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: actions,
                        ),
                      ),
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
                                      keyboard: TextInputType.phone,
                                      validator: (v) {
                                        final value = (v ?? '').trim();
                                        if (value.isEmpty)
                                          return 'Campo obrigatório';
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
                                  child: _Field(
                                    label: 'CPF/CNPJ',
                                    controller: _clienteDocumento,
                                    keyboard: TextInputType.number,
                                    validator: _validateDocumento,
                                    hintText: '000.000.000-00 ou 00.000.000/0000-00',
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'\d')),
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

                        // Section: Veiculo
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
                                        required: true,
                                        hintText: 'ABC-1234',
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'[A-Za-z0-9\-]')),
                                        ],
                                        validator: (v) {
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
                                  child: _MontadoraField(
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
                                    child: _Field(
                                        label: 'Modelo',
                                        controller: _modelo,
                                        required: true)),
                                const SizedBox(width: 16),
                                Expanded(
                                    child: _Field(
                                        label: 'Quilometragem',
                                        controller: _km,
                                        keyboard: TextInputType.number)),
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
                                  label: 'Cor do veículo',
                                  controller: _corVeiculo,
                                )),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Section: Servicos
                        Row(
                          children: [
                            const _SectionHeader(
                                icon: Icons.build_outlined, title: 'Serviços'),
                            const Spacer(),
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
                                label: const UpperText('Adicionar Peça'),
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
                          _CardSection(
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
                                      UpperText('Status',
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
                  UpperText('Serviço ${index + 1}',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const Spacer(),
                  UpperText(
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
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int?>(
                      value: _mecanicos.any((m) => (m['id'] as num).toInt() == s.mecanicoId)
                          ? s.mecanicoId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Mecanico do Servico',
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
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
                          ? 'Comissao nao atribuida'
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
                  Column(
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
                  const Spacer(),
                  UpperText(
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
  final bool enviarWhatsapp;
  final String? telefoneWhatsapp;
  final String? observacoes;

  _EncerrarConfig({
    required this.metodoPagamento,
    required this.enviarWhatsapp,
    this.telefoneWhatsapp,
    this.observacoes,
  });
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
        UpperText(title,
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

class _MontadoraField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> opcoes;
  final VoidCallback onCarregar;

  const _MontadoraField({
    required this.controller,
    required this.opcoes,
    required this.onCarregar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UpperText('Montadora',
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Autocomplete<String>(
          initialValue: TextEditingValue(text: controller.text),
          optionsBuilder: (textEditingValue) {
            onCarregar();
            final query = textEditingValue.text.trim().toLowerCase();
            if (query.isEmpty) return opcoes;
            return opcoes.where(
                (m) => m.toLowerCase().contains(query));
          },
          onSelected: (value) => controller.text = value,
          fieldViewBuilder: (ctx, fieldController, focusNode, onSubmit) {
            // Sincroniza o controller externo com o interno do Autocomplete
            fieldController.text = controller.text;
            fieldController.addListener(() {
              controller.text = fieldController.text;
            });
            return TextFormField(
              controller: fieldController,
              focusNode: focusNode,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                suffixIcon: Icon(Icons.arrow_drop_down_rounded),
              ),
              onFieldSubmitted: (_) => onSubmit(),
            );
          },
          optionsViewBuilder: (ctx, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240, maxWidth: 280),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (_, i) {
                      final opt = options.elementAt(i);
                      return InkWell(
                        onTap: () => onSelected(opt),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: UpperText(opt,
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textPrimary)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
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
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final String? hintText;
  const _Field(
      {required this.label,
      required this.controller,
      this.required = false,
      this.maxLines = 1,
      this.keyboard,
      this.onChanged,
      this.onTap,
      this.readOnly = false,
      this.suffixIcon,
      this.validator,
      this.inputFormatters,
      this.hintText});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UpperText(label,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboard,
          inputFormatters: inputFormatters,
          textInputAction:
              maxLines == 1 ? TextInputAction.next : TextInputAction.newline,
          readOnly: readOnly,
          onTap: onTap,
          onFieldSubmitted: (_) {
            if (maxLines == 1) {
              FocusScope.of(context).nextFocus();
            }
          },
          decoration: InputDecoration(suffixIcon: suffixIcon, hintText: hintText),
          onChanged: onChanged != null ? (_) => onChanged!() : null,
          validator: validator ??
              (required
                  ? (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null
                  : null),
        ),
      ],
    );
  }
}
