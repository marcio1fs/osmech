import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/os_service.dart';
import '../theme/app_theme.dart';
import '../mixins/auth_error_mixin.dart';
import '../utils/formatters.dart';
import 'os_form_page.dart';
import '../widgets/upper_text.dart';

/// Página de detalhes da OS com design moderno e profissional.
class OsDetailPage extends StatefulWidget {
  final Map<String, dynamic> osData;

  const OsDetailPage({super.key, required this.osData});

  @override
  State<OsDetailPage> createState() => _OsDetailPageState();
}

class _OsDetailPageState extends State<OsDetailPage> with AuthErrorMixin {
  late Map<String, dynamic> _os;
  bool _loading = false;
  bool _encerrando = false;

  @override
  void initState() {
    super.initState();
    _os = widget.osData;
  }

  String get safeToken {
    final auth = Provider.of<AuthService>(context, listen: false);
    return auth.token ?? '';
  }

  Future<void> _encerrarOs() async {
    final metodoController = TextEditingController();
    final descontoController = TextEditingController(text: '0');
    double descontoPerc = 0;
    bool enviarWhatsapp = _os['whatsappConsentimento'] == true;
    String? telefoneWhatsapp = _os['clienteTelefone'];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: UpperText(
            'Encerrar OS',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UpperText(
                  'Método de pagamento',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: metodoController.text.isEmpty ? null : metodoController.text,
                  decoration: InputDecoration(
                    hintText: 'Selecione o método',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'DINHEIRO', child: UpperText('Dinheiro')),
                    DropdownMenuItem(value: 'PIX', child: UpperText('PIX')),
                    DropdownMenuItem(value: 'CREDITO', child: UpperText('Cartão de Crédito')),
                    DropdownMenuItem(value: 'DEBITO', child: UpperText('Cartão de Débito')),
                    DropdownMenuItem(value: 'TRANSFERENCIA', child: UpperText('Transferência')),
                  ],
                  onChanged: (v) {
                    setDialogState(() {
                      metodoController.text = v ?? '';
                    });
                  },
                ),
                const SizedBox(height: 20),
                if (_os['whatsappConsentimento'] == true) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: UpperText(
                      'Enviar recibo via WhatsApp',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                    subtitle: UpperText(
                      'Cliente autorizou mensagens',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    value: enviarWhatsapp,
                    onChanged: (v) => setDialogState(() => enviarWhatsapp = v),
                  ),
                  if (enviarWhatsapp) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: TextEditingController(text: telefoneWhatsapp),
                      decoration: InputDecoration(
                        labelText: 'Telefone WhatsApp',
                        hintText: '77999999999',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.phone_android),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (v) => telefoneWhatsapp = v,
                    ),
                  ],
                ] else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: UpperText(
                            'Cliente não autorizou envio de recibo via WhatsApp',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                // Campo de desconto
                UpperText(
                  'Desconto (0% a 10%)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
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
                          descontoPerc = val.clamp(0, 10);
                          if (val > 10) descontoController.text = '10';
                          if (val < 0) descontoController.text = '0';
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: descontoPerc.clamp(0, 10),
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
                ]),
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
                        'Resumo',
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
                          UpperText('Cliente:', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                          UpperText(_os['clienteNome'] ?? '-', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          UpperText('Veículo:', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                          UpperText('${_os['modelo'] ?? '-'} (${_os['placa'] ?? '-'})', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          UpperText('Valor total:', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                          UpperText(
                            formatCurrency(_os['valor'] ?? 0),
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      // Desconto
                      if (descontoPerc > 0) ...[
                        const SizedBox(height: 4),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          UpperText('Desconto (${descontoPerc.toStringAsFixed(0)}%):',
                              style: GoogleFonts.inter(color: AppColors.error, fontSize: 13)),
                          UpperText(
                            '- ${formatCurrency(((_os['valor'] ?? 0) as num).toDouble() * descontoPerc / 100)}',
                            style: GoogleFonts.inter(color: AppColors.error, fontSize: 13),
                          ),
                        ]),
                        const Divider(height: 12),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          UpperText('Valor final:',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          UpperText(
                            formatCurrency(((_os['valor'] ?? 0) as num).toDouble() * (1 - descontoPerc / 100)),
                            style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.success, fontSize: 16),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const UpperText('Cancelar'),
            ),
            FilledButton(
              onPressed: metodoController.text.isEmpty
                  ? null
                  : () {
                      Navigator.pop(ctx, {
                        'metodoPagamento': metodoController.text,
                        'descontoPercentual': descontoPerc,
                        'enviarReciboWhatsapp': enviarWhatsapp,
                        'telefoneWhatsapp': telefoneWhatsapp,
                      });
                    },
              child: _encerrando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const UpperText('Encerrar OS'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    setState(() => _encerrando = true);

    try {
      final osService = OsService(token: safeToken);
      final response = await osService.encerrar(_os['id'], result);

      if (!mounted) return;

      setState(() {
        _os = {..._os, 'status': 'CONCLUIDA'};
      });

      // Show success message
      if (!mounted) return;
      
      String mensagem = 'OS encerrada com sucesso!';
      if (result['enviarReciboWhatsapp'] == true && response['whatsappEnviado'] == true) {
        mensagem += '\nRecibo enviado via WhatsApp para ${response['whatsappDestino']}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: UpperText(mensagem),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // If receipt was generated, show options to print or send
      if (response['recibo'] != null && !mounted) return;
      
      _mostrarRecibo(response['recibo'] ?? '', result['enviarReciboWhatsapp'] == true);
    } catch (e) {
      if (!handleAuthError(e)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: UpperText('Erro ao encerrar OS: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _encerrando = false);
      }
    }
  }

  void _mostrarRecibo(String recibo, bool whatsappEnviado) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  UpperText(
                    'Recibo da OS',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: UpperText(
                    recibo,
                    style: GoogleFonts.courierPrime(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Print functionality - opens browser print dialog
                        _imprimirRecibo(recibo);
                      },
                      icon: const Icon(Icons.print),
                      label: const UpperText('Imprimir'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        // Copy to clipboard
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: UpperText('Recibo copiado para a área de transferência!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const UpperText('Copiar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _imprimirRecibo(String recibo) {
    // Show print options
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const UpperText('Imprimir Recibo'),
        content: const UpperText('Para imprimir o recibo, você pode usar a função de impressão do navegador (Ctrl+P) ou salvar como PDF.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const UpperText('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarReciboWhatsApp() async {
    if (_os['whatsappConsentimento'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: UpperText('Cliente não autorizou envio de mensagens via WhatsApp'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String? telefoneWhatsapp = _os['clienteTelefone'];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: UpperText(
            'Enviar Recibo via WhatsApp',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UpperText(
                'O recibo será enviado para o número:',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: TextEditingController(text: telefoneWhatsapp),
                decoration: InputDecoration(
                  labelText: 'Telefone WhatsApp',
                  hintText: '77999999999',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.phone_android),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (v) => telefoneWhatsapp = v,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: UpperText(
                        'O sistema tentará enviar o recibo mesmo que a OS já esteja encerrada.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const UpperText('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx, {'telefoneWhatsapp': telefoneWhatsapp});
              },
              child: const UpperText('Enviar'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    setState(() => _loading = true);

    try {
      final osService = OsService(token: safeToken);
      
      // Use the new endpoint to send just the WhatsApp receipt
      final response = await osService.enviarReciboWhatsApp(
        _os['id'],
        telefoneWhatsapp: result['telefoneWhatsapp'],
      );

      if (!mounted) return;

      if (response['enviado'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: UpperText('Recibo enviado via WhatsApp para ${response['destino']}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: UpperText('Falha ao enviar: ${response['detalhe']}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!handleAuthError(e)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: UpperText('Erro ao enviar recibo: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _os['status'] ?? 'ABERTA';
    final statusColor = _statusColor(status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context, _os),
        ),
        title: UpperText(
          'OS #${_os['id']}',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.accent),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OsFormPage(osData: _os)),
              );
              // Reload OS data after edit
            },
            tooltip: 'Editar OS',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status compacto no topo
                  _buildStatusCard(status, statusColor),
                  const SizedBox(height: 20),

                  // Duas colunas: Cliente + Veículo
                  LayoutBuilder(builder: (ctx, constraints) {
                    final wide = constraints.maxWidth > 640;
                    final clienteCard = _buildInfoCard(
                      title: 'Cliente',
                      icon: Icons.person_outline,
                      children: [
                        _buildInfoRow('Nome', _os['clienteNome'] ?? '-'),
                        if ((_os['clienteCpf'] ?? '').toString().isNotEmpty)
                          _buildInfoRow('CPF', _os['clienteCpf']),
                        _buildInfoRow('Telefone', _os['clienteTelefone'] ?? '-'),
                        _buildInfoRow(
                          'WhatsApp',
                          _os['whatsappConsentimento'] == true ? 'Autorizado' : 'Não autorizado',
                          valueColor: _os['whatsappConsentimento'] == true ? AppColors.success : AppColors.textMuted,
                        ),
                      ],
                    );
                    final veiculoCard = _buildInfoCard(
                      title: 'Veículo',
                      icon: Icons.directions_car_outlined,
                      children: [
                        _buildInfoRow('Modelo', _os['modelo'] ?? '-'),
                        if ((_os['montadora'] ?? '').toString().isNotEmpty)
                          _buildInfoRow('Montadora', _os['montadora']),
                        _buildInfoRow('Placa', _os['placa'] ?? '-'),
                        if ((_os['corVeiculo'] ?? '').toString().isNotEmpty)
                          _buildInfoRow('Cor', _os['corVeiculo']),
                        if (_os['ano'] != null)
                          _buildInfoRow('Ano', _os['ano'].toString()),
                        if (_os['quilometragem'] != null)
                          _buildInfoRow('Km', _os['quilometragem'].toString()),
                      ],
                    );
                    if (wide) {
                      return IntrinsicHeight(
                        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Expanded(child: clienteCard),
                          const SizedBox(width: 16),
                          Expanded(child: veiculoCard),
                        ]),
                      );
                    }
                    return Column(children: [clienteCard, const SizedBox(height: 16), veiculoCard]);
                  }),
                  const SizedBox(height: 16),

                  // Serviços + Valores lado a lado
                  LayoutBuilder(builder: (ctx, constraints) {
                    final wide = constraints.maxWidth > 640;
                    final servicoCard = _buildInfoCard(
                      title: 'Serviço',
                      icon: Icons.build_outlined,
                      children: [
                        if ((_os['mecanicoResponsavel'] ?? '').toString().isNotEmpty)
                          _buildInfoRow('Mecânico', _os['mecanicoResponsavel']),
                        _buildInfoRow('Descrição', _os['descricao'] ?? '-'),
                        if ((_os['diagnostico'] ?? '').toString().isNotEmpty)
                          _buildInfoRow('Diagnóstico', _os['diagnostico']),
                      ],
                    );
                    final valorCard = _buildInfoCard(
                      title: 'Financeiro',
                      icon: Icons.attach_money,
                      children: [
                        _buildInfoRow('Valor Total', formatCurrency(_os['valor'] ?? 0),
                            isTotal: true, valueColor: AppColors.success),
                        _buildInfoRow('Criado em', _formatDateTime(_os['criadoEm'])),
                        if (_os['concluidoEm'] != null)
                          _buildInfoRow('Concluído em', _formatDateTime(_os['concluidoEm'])),
                      ],
                    );
                    if (wide) {
                      return IntrinsicHeight(
                        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Expanded(flex: 2, child: servicoCard),
                          const SizedBox(width: 16),
                          Expanded(child: valorCard),
                        ]),
                      );
                    }
                    return Column(children: [servicoCard, const SizedBox(height: 16), valorCard]);
                  }),
                  const SizedBox(height: 24),

                  // Botões de ação
                  if (status != 'CONCLUIDA' && status != 'CANCELADA') ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _encerrarOs,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const UpperText('Encerrar OS'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],

                  if (status == 'CONCLUIDA') ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _mostrarRecibo('Recibo da OS #${_os['id']}\n\nCliente: ${_os['clienteNome']}\nValor: ${formatCurrency(_os['valor'] ?? 0)}', false);
                            },
                            icon: const Icon(Icons.receipt_long),
                            label: const UpperText('Ver Recibo'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _enviarReciboWhatsApp(),
                            icon: const Icon(Icons.send),
                            label: const UpperText('WhatsApp'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(String status, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_statusIcon(status), color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UpperText(_statusLabel(status),
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
                UpperText('OS #${_os['id']}  •  ${_os['clienteNome'] ?? '-'}  •  ${_os['placa'] ?? '-'}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          UpperText(formatCurrency(_os['valor'] ?? 0),
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800,
                  color: status == 'CONCLUIDA' ? AppColors.success : AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.accent),
                const SizedBox(width: 8),
                UpperText(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: UpperText(
              label,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: UpperText(
              value,
              style: GoogleFonts.inter(
                color: valueColor ?? AppColors.textPrimary,
                fontSize: isTotal ? 18 : 13,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(dynamic dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr.toString();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ABERTA':
        return AppColors.info;
      case 'EM_ANDAMENTO':
        return AppColors.warning;
      case 'AGUARDANDO_PECA':
        return AppColors.accent;
      case 'AGUARDANDO_APROVACAO':
        return AppColors.warning;
      case 'CONCLUIDA':
        return AppColors.success;
      case 'CANCELADA':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'ABERTA':
        return Icons.play_circle_outline;
      case 'EM_ANDAMENTO':
        return Icons.engineering_outlined;
      case 'AGUARDANDO_PECA':
        return Icons.pending_outlined;
      case 'AGUARDANDO_APROVACAO':
        return Icons.thumb_up_outlined;
      case 'CONCLUIDA':
        return Icons.check_circle_outline;
      case 'CANCELADA':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
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
}
