import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/stock_service.dart';
import '../theme/app_theme.dart';

/// Formulário de cadastro e edição de peça/item de estoque.
class StockFormPage extends StatefulWidget {
  final VoidCallback? onSaved;
  final VoidCallback? onCancel;
  final int? editItemId;

  const StockFormPage(
      {super.key, this.onSaved, this.onCancel, this.editItemId});

  @override
  State<StockFormPage> createState() => _StockFormPageState();
}

class _StockFormPageState extends State<StockFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();
  final _quantidadeCtrl = TextEditingController(text: '0');
  final _quantidadeMinimaCtrl = TextEditingController(text: '1');
  final _precoCustoCtrl = TextEditingController(text: '0.00');
  final _precoVendaCtrl = TextEditingController(text: '0.00');
  final _localizacaoCtrl = TextEditingController();

  String _categoria = 'OUTROS';
  bool _saving = false;
  bool _loadingItem = false;

  static const Map<String, String> _categoriaLabels = {
    'MOTOR': 'Motor',
    'SUSPENSAO': 'Suspensão',
    'FREIOS': 'Freios',
    'ELETRICA': 'Elétrica',
    'TRANSMISSAO': 'Transmissão',
    'ARREFECIMENTO': 'Arrefecimento',
    'FILTROS': 'Filtros',
    'OLEOS': 'Óleos',
    'FUNILARIA': 'Funilaria',
    'ACESSORIOS': 'Acessórios',
    'OUTROS': 'Outros',
  };

  bool get isEditing => widget.editItemId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadItem();
    } else {
      _codigoCtrl.text = 'Auto';
    }
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nomeCtrl.dispose();
    _quantidadeCtrl.dispose();
    _quantidadeMinimaCtrl.dispose();
    _precoCustoCtrl.dispose();
    _precoVendaCtrl.dispose();
    _localizacaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadItem() async {
    setState(() => _loadingItem = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = StockService(token: auth.token!);
      final item = await service.buscarItem(widget.editItemId!);
      setState(() {
        _codigoCtrl.text = item['codigo'] ?? '';
        _nomeCtrl.text = item['nome'] ?? '';
        _categoria = item['categoria'] ?? 'OUTROS';
        _quantidadeCtrl.text = '${item['quantidade'] ?? 0}';
        _quantidadeMinimaCtrl.text = '${item['quantidadeMinima'] ?? 1}';
        _precoCustoCtrl.text =
            (item['precoCusto'] as num?)?.toStringAsFixed(2) ?? '0.00';
        _precoVendaCtrl.text =
            (item['precoVenda'] as num?)?.toStringAsFixed(2) ?? '0.00';
        _localizacaoCtrl.text = item['localizacao'] ?? '';
        _loadingItem = false;
      });
    } catch (e) {
      setState(() => _loadingItem = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Erro ao carregar item', style: GoogleFonts.inter()),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final service = StockService(token: auth.token!);

      // Tratar vírgula como separador decimal (padrão brasileiro)
      double parsePreco(String text) {
        final normalized = text.replaceAll(',', '.');
        return double.tryParse(normalized) ?? 0.0;
      }

      final dados = {
        'nome': _nomeCtrl.text.trim(),
        'categoria': _categoria,
        'quantidade': int.tryParse(_quantidadeCtrl.text) ?? 0,
        'quantidadeMinima': int.tryParse(_quantidadeMinimaCtrl.text) ?? 1,
        'precoCusto': parsePreco(_precoCustoCtrl.text),
        'precoVenda': parsePreco(_precoVendaCtrl.text),
        'localizacao': _localizacaoCtrl.text.trim().isNotEmpty
            ? _localizacaoCtrl.text.trim()
            : null,
      };

      if (isEditing) {
        await service.atualizarItem(widget.editItemId!, dados);
      } else {
        await service.criarItem(dados);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isEditing ? 'Item atualizado!' : 'Item cadastrado!',
                  style: GoogleFonts.inter()),
              backgroundColor: AppColors.success),
        );
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', ''),
                  style: GoogleFonts.inter()),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
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
                Text(isEditing ? 'Editar Peça' : 'Nova Peça',
                    style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const Spacer(),
                OutlinedButton(
                  onPressed: widget.onCancel ?? widget.onSaved,
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _saving ? null : _salvar,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(_saving ? 'Salvando...' : 'Salvar'),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: _loadingItem
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 700),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Informações da Peça',
                                  style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 24),

                              // Código (auto) + Categoria
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _codigoCtrl,
                                      readOnly: true,
                                      enabled: false,
                                      decoration: InputDecoration(
                                        labelText: 'Código',
                                        hintText: isEditing
                                            ? ''
                                            : 'Gerado automaticamente',
                                        prefixIcon:
                                            const Icon(Icons.qr_code_rounded),
                                        filled: true,
                                        fillColor: AppColors.background,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      value: _categoria,
                                      decoration: const InputDecoration(
                                        labelText: 'Categoria',
                                        prefixIcon:
                                            Icon(Icons.category_rounded),
                                      ),
                                      items: _categoriaLabels.entries
                                          .map((e) => DropdownMenuItem(
                                              value: e.key,
                                              child: Text(e.value)))
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _categoria = v!),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Nome
                              TextFormField(
                                controller: _nomeCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Nome da peça *',
                                  hintText: 'Ex: Pastilha de freio dianteira',
                                  prefixIcon: Icon(Icons.build_rounded),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Informe o nome'
                                    : null,
                              ),
                              const SizedBox(height: 24),

                              Text('Quantidades',
                                  style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 16),

                              // Quantidade + Mínimo
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _quantidadeCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Quantidade atual',
                                        prefixIcon:
                                            Icon(Icons.inventory_rounded),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Informe a quantidade';
                                        }
                                        final n = int.tryParse(v);
                                        if (n == null || n < 0) {
                                          return 'Valor inválido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _quantidadeMinimaCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Quantidade mínima',
                                        prefixIcon: Icon(Icons
                                            .notification_important_rounded),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Informe o mínimo';
                                        }
                                        final n = int.tryParse(v);
                                        if (n == null || n < 0) {
                                          return 'Valor inválido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              Text('Preços',
                                  style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 16),

                              // Preço custo + Preço venda
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _precoCustoCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Preço de custo (R\$)',
                                        prefixIcon:
                                            Icon(Icons.shopping_cart_rounded),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _precoVendaCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Preço de venda (R\$)',
                                        prefixIcon: Icon(Icons.sell_rounded),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              Text('Localização',
                                  style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _localizacaoCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Localização no estoque',
                                  hintText: 'Ex: Prateleira A3, Gaveta 2',
                                  prefixIcon: Icon(Icons.location_on_rounded),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
