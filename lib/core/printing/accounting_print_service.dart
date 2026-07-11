import 'package:crm_task_manager/models/page_2/expense_details_document_model.dart'
    as exp_doc;
import 'package:crm_task_manager/core/printing/print_template_settings.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AccountingPrintService {
  const AccountingPrintService._();

  static Future<void> printExpenseDocument({
    required exp_doc.ExpenseDocumentDetail document,
    required String title,
    PrintTemplateSettings settings = const PrintTemplateSettings(),
  }) async {
    final bytes = await buildExpenseDocumentPdf(
      document: document,
      title: title,
      settings: settings,
    );

    final docNumber =
        _cleanFileName(document.docNumber ?? document.id ?? 'doc');
    await Printing.layoutPdf(
      name: '$docNumber.pdf',
      onLayout: (_) async => bytes,
    );
  }

  static Future<Uint8List> buildExpenseDocumentPdf({
    required exp_doc.ExpenseDocumentDetail document,
    required String title,
    PrintTemplateSettings settings = const PrintTemplateSettings(),
  }) async {
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Gilroy-Regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Gilroy-Bold.ttf'),
    );
    final pdf = pw.Document();
    final goods = document.documentGoods ?? const <exp_doc.DocumentGood>[];
    final currency =
        settings.showCurrency ? document.currency?.symbolCode ?? '' : '';
    final compact = settings.layout == 'compact';
    final receipt = settings.paperSize == 'receipt58' ||
        settings.paperSize == 'receipt80' ||
        settings.paperSize == 'custom';
    final margin = receipt ? 8.0 : (compact ? 18.0 : 28.0);
    final spacing = compact ? 10.0 : 18.0;
    final pageFormat = _pageFormat(settings);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(margin),
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                settings.footerText.trim(),
                style: pw.TextStyle(
                  fontSize: _font(settings, 9),
                  color: PdfColors.grey600,
                ),
              ),
            ),
            pw.Text(
              '${context.pageNumber}/${context.pagesCount}',
              style: pw.TextStyle(
                fontSize: _font(settings, 9),
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
        build: (context) => [
          _header(title, document, settings),
          pw.SizedBox(height: spacing),
          if (_hasDetails(settings, document)) ...[
            _detailsBlock(document, settings),
            pw.SizedBox(height: spacing),
          ],
          _goodsTable(goods, currency, settings),
          if (settings.showTotalQuantity || settings.showSums) ...[
            pw.SizedBox(height: 16),
            _totalsBlock(document, currency, settings),
          ],
          if (settings.showComment &&
              (document.comment ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _commentBlock(document.comment!.trim()),
          ],
          if (settings.showSignatures) ...[
            pw.SizedBox(height: 34),
            _signatures(),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _header(
    String title,
    exp_doc.ExpenseDocumentDetail document,
    PrintTemplateSettings settings,
  ) {
    final effectiveTitle = settings.customTitle.trim().isEmpty
        ? title
        : settings.customTitle.trim();
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'shamCRM',
                style: pw.TextStyle(
                  fontSize: _font(settings, 18),
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1E2E52'),
                ),
              ),
              if (settings.headerText.trim().isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  settings.headerText.trim(),
                  style: pw.TextStyle(
                    fontSize: _font(settings, 10),
                    color: PdfColors.grey700,
                  ),
                ),
              ],
              pw.SizedBox(height: 6),
              pw.Text(
                effectiveTitle,
                style: pw.TextStyle(
                  fontSize: _font(settings, 22),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _smallMeta(
                  'Документ', '№${document.docNumber ?? document.id ?? ''}'),
              pw.SizedBox(height: 4),
              _smallMeta('Дата', _formatDate(document.date)),
              if (settings.showStatus) ...[
                pw.SizedBox(height: 4),
                _statusChip(document.statusText),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _detailsBlock(
    exp_doc.ExpenseDocumentDetail document,
    PrintTemplateSettings settings,
  ) {
    final rows = <MapEntry<String, String>>[
      if (settings.showClient) MapEntry('Клиент', document.model?.name ?? ''),
      if (settings.showClientPhone)
        MapEntry('Телефон клиента', document.model?.phone ?? ''),
      if (settings.showClientInn)
        MapEntry('ИНН клиента', document.model?.inn?.toString() ?? ''),
      if (settings.showStorage) MapEntry('Склад', document.storage?.name ?? ''),
      if (settings.showCurrency)
        MapEntry('Валюта',
            document.currency?.name ?? document.currency?.symbolCode ?? ''),
      if (settings.showAuthor) MapEntry('Автор', _personName(document.author)),
    ].where((row) => row.value.trim().isNotEmpty).toList();

    return pw.Container(
      padding: pw.EdgeInsets.all(settings.layout == 'compact' ? 8 : 12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8FAFC'),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB')),
      ),
      child: pw.Wrap(
        runSpacing: 8,
        spacing: 12,
        children: rows
            .map(
              (row) => pw.SizedBox(
                width: 245,
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: '${row.key}: ',
                        style: pw.TextStyle(
                          fontSize: _font(settings, 10),
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.TextSpan(
                        text: row.value,
                        style: pw.TextStyle(fontSize: _font(settings, 10)),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  static pw.Widget _goodsTable(
    List<exp_doc.DocumentGood> goods,
    String currency,
    PrintTemplateSettings settings,
  ) {
    if (goods.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Text('Товары не указаны'),
      );
    }

    final headers = <String>[
      '№',
      _fallback(settings.goodsColumnTitle, 'Товар'),
      'Ед.',
      _fallback(settings.quantityColumnTitle, 'Кол-во'),
    ];
    final receipt = settings.paperSize == 'receipt58' ||
        settings.paperSize == 'receipt80' ||
        settings.paperSize == 'custom';
    final columnWidths = <int, pw.TableColumnWidth>{
      0: pw.FixedColumnWidth(receipt ? 14 : 24),
      1: const pw.FlexColumnWidth(3),
      2: pw.FixedColumnWidth(receipt ? 22 : 48),
      3: pw.FixedColumnWidth(receipt ? 26 : 48),
    };

    if (settings.showPrices) {
      columnWidths[headers.length] = pw.FixedColumnWidth(receipt ? 34 : 70);
      headers.add(_fallback(settings.priceColumnTitle, 'Цена'));
    }
    if (settings.showSums) {
      columnWidths[headers.length] = pw.FixedColumnWidth(receipt ? 34 : 76);
      headers.add(_fallback(settings.sumColumnTitle, 'Сумма'));
    }

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColor.fromHex('#E5E7EB')),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#1E2E52')),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: _font(settings, 9),
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(fontSize: _font(settings, 9)),
      cellPadding: pw.EdgeInsets.symmetric(
        horizontal: settings.layout == 'compact' ? 4 : 6,
        vertical: settings.layout == 'compact' ? 5 : 7,
      ),
      columnWidths: columnWidths,
      headers: headers,
      data: [
        for (var i = 0; i < goods.length; i++)
          [
            '${i + 1}',
            goods[i].fullName ?? goods[i].good?.name ?? '',
            _unitName(goods[i]),
            _formatNumber(goods[i].quantity ?? 0),
            if (settings.showPrices)
              '${_formatMoney(_priceWithUnit(goods[i]))} $currency',
            if (settings.showSums)
              '${_formatMoney(_lineTotal(goods[i]))} $currency',
          ],
      ],
    );
  }

  static pw.Widget _totalsBlock(
    exp_doc.ExpenseDocumentDetail document,
    String currency,
    PrintTemplateSettings settings,
  ) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 260,
        padding: pw.EdgeInsets.all(settings.layout == 'compact' ? 8 : 12),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#F8FAFC'),
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB')),
        ),
        child: pw.Column(
          children: [
            if (settings.showTotalQuantity)
              _totalRow(
                  'Общее количество', _formatNumber(document.totalQuantity)),
            if (settings.showTotalQuantity && settings.showSums)
              pw.Divider(color: PdfColor.fromHex('#E5E7EB')),
            if (settings.showSums)
              _totalRow(
                'Общая сумма',
                '${_formatMoney(document.totalSum)} $currency',
                bold: true,
              ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _commentBlock(String comment) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB')),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Комментарий',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(comment, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _signatures() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _signatureLine('Отпустил'),
        _signatureLine('Получил'),
      ],
    );
  }

  static pw.Widget _smallMeta(String label, String value) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _statusChip(String status) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#E0F2FE'),
        borderRadius: pw.BorderRadius.circular(20),
      ),
      child: pw.Text(
        status,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#0369A1'),
        ),
      ),
    );
  }

  static pw.Widget _totalRow(String label, String value, {bool bold = false}) {
    final style = pw.TextStyle(
      fontSize: bold ? 13 : 10,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(value, style: style),
      ],
    );
  }

  static pw.Widget _signatureLine(String label) {
    return pw.SizedBox(
      width: 220,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(height: 1, color: PdfColors.grey500),
          pw.SizedBox(height: 6),
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return '';
    return DateFormat('dd.MM.yyyy HH:mm').format(value);
  }

  static bool _hasDetails(
    PrintTemplateSettings settings,
    exp_doc.ExpenseDocumentDetail document,
  ) {
    return (settings.showClient && (document.model?.name ?? '').isNotEmpty) ||
        (settings.showClientPhone &&
            (document.model?.phone ?? '').isNotEmpty) ||
        (settings.showClientInn &&
            (document.model?.inn?.toString() ?? '').isNotEmpty) ||
        (settings.showStorage && (document.storage?.name ?? '').isNotEmpty) ||
        (settings.showCurrency &&
            ((document.currency?.name ?? document.currency?.symbolCode ?? '')
                .isNotEmpty)) ||
        (settings.showAuthor && _personName(document.author).isNotEmpty);
  }

  static String _personName(exp_doc.Author? author) {
    final parts = [author?.name, author?.lastname]
        .where((part) => (part ?? '').trim().isNotEmpty)
        .map((part) => part!.trim())
        .toList();
    return parts.isNotEmpty ? parts.join(' ') : author?.login ?? '';
  }

  static String _unitName(exp_doc.DocumentGood good) {
    final unit = good.selectedUnit;
    return unit.shortName ?? unit.name ?? '';
  }

  static double _priceWithUnit(exp_doc.DocumentGood good) {
    final amount = (good.selectedUnit.amount ?? 1).toDouble();
    final price =
        double.tryParse((good.price ?? '0').replaceAll(',', '.')) ?? 0;
    return amount * price;
  }

  static double _lineTotal(exp_doc.DocumentGood good) {
    return (good.quantity ?? 0).toDouble() * _priceWithUnit(good);
  }

  static String _formatMoney(num value) {
    return NumberFormat('#,##0.00', 'ru_RU').format(value);
  }

  static String _formatNumber(num value) {
    if (value % 1 == 0) return value.toInt().toString();
    return NumberFormat('#,##0.###', 'ru_RU').format(value);
  }

  static String _cleanFileName(Object value) {
    return value.toString().replaceAll(RegExp(r'[^A-Za-z0-9А-Яа-я_-]+'), '_');
  }

  static PdfPageFormat _pageFormat(PrintTemplateSettings settings) {
    switch (settings.paperSize) {
      case 'receipt58':
        return PdfPageFormat(
          58 * PdfPageFormat.mm,
          500 * PdfPageFormat.mm,
        );
      case 'receipt80':
        return PdfPageFormat(
          80 * PdfPageFormat.mm,
          500 * PdfPageFormat.mm,
        );
      case 'custom':
        final width = settings.customWidthMm.clamp(40, 300).toDouble();
        final height = settings.customHeightMm.clamp(80, 1000).toDouble();
        return PdfPageFormat(
          width * PdfPageFormat.mm,
          height * PdfPageFormat.mm,
        );
      case 'a4':
      default:
        return PdfPageFormat.a4;
    }
  }

  static double _font(PrintTemplateSettings settings, double base) {
    return base * settings.fontScale.clamp(0.85, 1.25);
  }

  static String _fallback(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
}
