import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Constrói os bytes do PDF do recibo otimizado para impressora Bematec MP-20
/// (papel 76 mm de largura, modo bobina contínua).
///
/// O formato A4 causava texto minúsculo pois a impressora redimensionava
/// a página inteira para caber no papel de 76 mm. Agora o PDF já é gerado
/// na largura exata do papel (76 mm) com fontes legíveis.
Future<Uint8List> buildReceiptPdfBytes(String receipt, {String? logoUrl}) async {
  final receiptText = receipt.trimRight();

  // Remove quebras de linha excessivas
  final cleanReceiptText = receiptText
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();

  // Tenta baixar a imagem do logo com validação robusta
  pw.MemoryImage? logoImage;
  if (logoUrl != null && logoUrl.isNotEmpty) {
    try {
      final response = await http.get(Uri.parse(logoUrl));
      if (response.statusCode == 200 && response.bodyBytes.length > 200) {
        final bytes = response.bodyBytes;
        final isPng = bytes.length > 8 &&
            bytes[0] == 0x89 && bytes[1] == 0x50 &&
            bytes[2] == 0x4E && bytes[3] == 0x47;
        final isJpeg = bytes.length > 3 &&
            bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
        if (isPng || isJpeg) {
          logoImage = pw.MemoryImage(bytes);
        }
      }
    } catch (_) {
      logoImage = null;
    }
  }

  // ─── Formato para impressora Bematec MP-20 ──────────────────────────────────
  // Papel: 76 mm de largura (padrão do MP-20 matricial)
  // Margens laterais: 3 mm de cada lado (deixa ~70 mm de área útil de impressão)
  // Altura: contínua (bobina) — o PDF se adapta ao conteúdo
  const double paperWidthMm = 76.0;
  const double marginSideMm = 3.0;
  const double marginTopBottomMm = 4.0;

  final double paperWidthPt = paperWidthMm * PdfPageFormat.mm;
  final double marginSidePt = marginSideMm * PdfPageFormat.mm;
  final double marginTopBottomPt = marginTopBottomMm * PdfPageFormat.mm;

  // Fontes calibradas para 76 mm:
  // Courier 9pt: ~32 caracteres/linha na área útil de ~70 mm
  // Aumentar para 10pt se quiser menos caracteres mas texto ainda maior
  const double bodyFontSize = 9.0;
  const double separatorFontSize = 8.5;
  const double footerFontSize = 8.5;

  final bodyStyle = pw.TextStyle(
    font: pw.Font.courier(),
    fontSize: bodyFontSize,
    lineSpacing: 1.3,
    color: PdfColors.black,
  );

  final boldStyle = pw.TextStyle(
    font: pw.Font.courierBold(),
    fontSize: bodyFontSize,
    lineSpacing: 1.3,
    color: PdfColors.black,
  );

  final sepStyle = pw.TextStyle(
    font: pw.Font.courier(),
    fontSize: separatorFontSize,
    lineSpacing: 1.0,
    color: PdfColors.grey800,
  );

  List<pw.Widget> buildContent({bool withLogo = true}) {
    final lines = cleanReceiptText.isEmpty
        ? ['Recibo sem conteúdo.']
        : cleanReceiptText.split('\n');

    return [
      // Logo centralizado (limitado à largura útil do papel)
      if (withLogo && logoImage != null)
        pw.Container(
          width: double.infinity,
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Image(
            logoImage,
            width: paperWidthPt - (marginSidePt * 2),
            height: 32,
            fit: pw.BoxFit.contain,
          ),
        ),

      // Linhas do recibo renderizadas individualmente.
      // Linhas com "===" ou "---" recebem estilo de separador.
      // Linhas de totais/resumo ficam em negrito.
      ...lines.map((line) {
        if (line.startsWith('=') || line.startsWith('-')) {
          return pw.Text(line.isEmpty ? ' ' : line, style: sepStyle);
        }
        final isBold = line.startsWith('TOTAL') ||
            line.startsWith('VALOR') ||
            line.startsWith('MÉTODO') ||
            line.startsWith('OS:') ||
            line.startsWith('STATUS');
        return pw.Text(
          line.isEmpty ? ' ' : line,
          style: isBold ? boldStyle : bodyStyle,
        );
      }),

      pw.SizedBox(height: 6),
      pw.Text(
        'Agradecemos pela preferencia!',
        style: pw.TextStyle(
          font: pw.Font.courierBold(),
          fontSize: footerFontSize,
          color: PdfColors.black,
        ),
        textAlign: pw.TextAlign.center,
      ),
      pw.Text(
        'Volte sempre!',
        style: pw.TextStyle(
          font: pw.Font.courier(),
          fontSize: footerFontSize,
          color: PdfColors.grey700,
        ),
        textAlign: pw.TextAlign.center,
      ),
      pw.SizedBox(height: 10),
    ];
  }

  // Formato 76 mm × altura contínua (bobina)
  final pageFormat = PdfPageFormat(
    paperWidthPt,
    double.infinity,
    marginLeft: marginSidePt,
    marginRight: marginSidePt,
    marginTop: marginTopBottomPt,
    marginBottom: marginTopBottomPt,
  );

  try {
    final pdfDocument = pw.Document();
    pdfDocument.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisSize: pw.MainAxisSize.min,
          children: buildContent(withLogo: true),
        ),
      ),
    );
    return pdfDocument.save();
  } catch (_) {
    // Fallback sem logo caso ocorra erro de renderização
    final fallbackDoc = pw.Document();
    fallbackDoc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisSize: pw.MainAxisSize.min,
          children: buildContent(withLogo: false),
        ),
      ),
    );
    return fallbackDoc.save();
  }
}
