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
    bool realizationLayout = false,
  }) async {
    final bytes = await buildExpenseDocumentPdf(
      document: document,
      title: title,
      settings: settings,
      realizationLayout: realizationLayout,
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
    bool realizationLayout = false,
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
    final margin = receipt
        ? 8.0
        : (realizationLayout ? 20.0 : (compact ? 18.0 : 28.0));
    final spacing = realizationLayout ? 8.0 : (compact ? 10.0 : 18.0);
    final pageFormat = _pageFormat(settings);

    final displayTitle = realizationLayout
        ? _realizationTitle(title, document, settings)
        : (settings.customTitle.trim().isEmpty
            ? title
            : settings.customTitle.trim());
    final theme = pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
    );

    if (realizationLayout) {
      _addRealizationPages(
        pdf: pdf,
        pageFormat: pageFormat,
        margin: margin,
        theme: theme,
        settings: settings,
        copies: () => _documentCopyChildren(
          title: displayTitle,
          document: document,
          goods: goods,
          currency: currency,
          settings: settings,
          spacing: spacing,
          realizationLayout: true,
        ),
        copyColumn: () => _documentCopyColumn(
          title: displayTitle,
          document: document,
          goods: goods,
          currency: currency,
          settings: settings,
          spacing: spacing,
        ),
        twoCopiesFit: _twoRealizationCopiesFit(
          document: document,
          goods: goods,
          settings: settings,
          pageFormat: pageFormat,
          margin: margin,
        ),
      );
    } else {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.all(margin),
          theme: theme,
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
            _header(displayTitle, document, settings, realizationLayout: false),
            pw.SizedBox(height: spacing),
            if (_hasDetails(settings, document)) ...[
              _detailsBlock(document, settings, realizationLayout: false),
              pw.SizedBox(height: spacing),
            ],
            _goodsTable(goods, currency, settings, realizationLayout: false),
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
              _signatures(realizationLayout: false),
            ],
          ],
        ),
      );
    }

    return pdf.save();
  }

  static void _addRealizationPages({
    required pw.Document pdf,
    required PdfPageFormat pageFormat,
    required double margin,
    required pw.ThemeData theme,
    required PrintTemplateSettings settings,
    required List<pw.Widget> Function() copies,
    required pw.Widget Function() copyColumn,
    required bool twoCopiesFit,
  }) {
    if (twoCopiesFit) {
      final contentWidth = pageFormat.width - margin * 2;
      pw.Widget boundedCopy() => pw.SizedBox(
            width: contentWidth,
            child: copyColumn(),
          );
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.all(margin),
          theme: theme,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              boundedCopy(),
              pw.SizedBox(height: 10),
              _cutSeparator(),
              pw.SizedBox(height: 36),
              pw.Expanded(
                child: pw.FittedBox(
                  fit: pw.BoxFit.scaleDown,
                  alignment: pw.Alignment.topCenter,
                  child: boundedCopy(),
                ),
              ),
              if (settings.footerText.trim().isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 6),
                  child: pw.Text(
                    settings.footerText.trim(),
                    style: pw.TextStyle(
                      fontSize: _font(settings, 9),
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
      return;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(margin),
        theme: theme,
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
          ...copies(),
          pw.SizedBox(height: 18),
          _cutSeparator(),
          pw.SizedBox(height: 28),
          ...copies(),
        ],
      ),
    );
  }

  static bool _twoRealizationCopiesFit({
    required exp_doc.ExpenseDocumentDetail document,
    required List<exp_doc.DocumentGood> goods,
    required PrintTemplateSettings settings,
    required PdfPageFormat pageFormat,
    required double margin,
  }) {
    final hasComment = settings.showComment &&
        (document.comment ?? '').trim().isNotEmpty;
    var copyHeight = 86.0;
    if (_hasDetails(settings, document)) copyHeight += 62;
    copyHeight += 24 + goods.length * 20;
    if (settings.showTotalQuantity || settings.showSums) copyHeight += 52;
    if (hasComment) copyHeight += 42;
    if (settings.showSignatures) copyHeight += 40;
    copyHeight += 24;

    final usableHeight = pageFormat.height - margin * 2 - 16;
    return copyHeight <= usableHeight * 0.48;
  }

  static pw.Widget _documentCopyColumn({
    required String title,
    required exp_doc.ExpenseDocumentDetail document,
    required List<exp_doc.DocumentGood> goods,
    required String currency,
    required PrintTemplateSettings settings,
    required double spacing,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: _documentCopyChildren(
        title: title,
        document: document,
        goods: goods,
        currency: currency,
        settings: settings,
        spacing: spacing,
        realizationLayout: true,
      ),
    );
  }

  static List<pw.Widget> _documentCopyChildren({
    required String title,
    required exp_doc.ExpenseDocumentDetail document,
    required List<exp_doc.DocumentGood> goods,
    required String currency,
    required PrintTemplateSettings settings,
    required double spacing,
    required bool realizationLayout,
  }) {
    return [
      _header(title, document, settings, realizationLayout: realizationLayout),
      pw.SizedBox(height: spacing),
      if (_hasDetails(settings, document)) ...[
        _detailsBlock(
          document,
          settings,
          realizationLayout: realizationLayout,
        ),
        pw.SizedBox(height: spacing),
      ],
      _goodsTable(
        goods,
        currency,
        settings,
        realizationLayout: realizationLayout,
      ),
      if (settings.showTotalQuantity || settings.showSums) ...[
        pw.SizedBox(height: 12),
        _totalsBlock(document, currency, settings),
      ],
      if (settings.showComment &&
          (document.comment ?? '').trim().isNotEmpty) ...[
        pw.SizedBox(height: 10),
        _commentBlock(document.comment!.trim()),
      ],
      if (settings.showSignatures) ...[
        pw.SizedBox(height: realizationLayout ? 14 : 20),
        _signatures(realizationLayout: realizationLayout),
      ],
    ];
  }

  static pw.Widget _header(
    String title,
    exp_doc.ExpenseDocumentDetail document,
    PrintTemplateSettings settings, {
    required bool realizationLayout,
  }) {
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
                  fontSize: _font(settings, realizationLayout ? 13 : 18),
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
                title,
                style: pw.TextStyle(
                  fontSize: _font(settings, realizationLayout ? 15 : 22),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        pw.Container(
          padding: pw.EdgeInsets.symmetric(
            horizontal: realizationLayout ? 10 : 12,
            vertical: realizationLayout ? 8 : 10,
          ),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (!realizationLayout) ...[
                _smallMeta(
                  'Документ',
                  '№${document.docNumber ?? document.id ?? ''}',
                ),
                pw.SizedBox(height: 4),
              ],
              _smallMeta('Дата', _formatDate(document.date)),
              if (settings.showStatus) ...[
                pw.SizedBox(height: realizationLayout ? 6 : 4),
                if (realizationLayout)
                  _statusRow(document.statusText)
                else
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
    PrintTemplateSettings settings, {
    required bool realizationLayout,
  }) {
    final rows = <MapEntry<String, String>>[
      if (settings.showClient)
        MapEntry(
          realizationLayout ? 'Клиент РМК' : 'Клиент',
          document.model?.name ?? '',
        ),
      if (realizationLayout && settings.showAuthor)
        MapEntry('Автор', _personName(document.author)),
      if (settings.showStorage) MapEntry('Склад', document.storage?.name ?? ''),
      if (settings.showClientPhone)
        MapEntry('Телефон клиента', document.model?.phone ?? ''),
      if (settings.showClientInn)
        MapEntry('ИНН клиента', document.model?.inn?.toString() ?? ''),
      if (settings.showCurrency)
        MapEntry('Валюта',
            document.currency?.name ?? document.currency?.symbolCode ?? ''),
      if (!realizationLayout && settings.showAuthor)
        MapEntry('Автор', _personName(document.author)),
    ].where((row) => row.value.trim().isNotEmpty).toList();

    pw.Widget rowText(MapEntry<String, String> row) {
      return pw.RichText(
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
      );
    }

    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(
        realizationLayout || settings.layout == 'compact' ? 8 : 12,
      ),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8FAFC'),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB')),
      ),
      child: realizationLayout
          ? pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) pw.SizedBox(height: 4),
                  rowText(rows[i]),
                ],
              ],
            )
          : pw.Wrap(
              runSpacing: 8,
              spacing: 12,
              children: rows
                  .map(
                    (row) => pw.SizedBox(
                      width: 245,
                      child: rowText(row),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  static pw.Widget _goodsTable(
    List<exp_doc.DocumentGood> goods,
    String currency,
    PrintTemplateSettings settings, {
    required bool realizationLayout,
  }) {
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
      realizationLayout ? 'Ед.изм' : 'Ед.',
      _fallback(settings.quantityColumnTitle, 'Кол-во'),
    ];
    final receipt = settings.paperSize == 'receipt58' ||
        settings.paperSize == 'receipt80' ||
        settings.paperSize == 'custom';
    final columnWidths = <int, pw.TableColumnWidth>{
      0: pw.FixedColumnWidth(receipt ? 14 : 24),
      1: const pw.FlexColumnWidth(3),
      2: pw.FixedColumnWidth(
        receipt
            ? (realizationLayout ? 32 : 22)
            : (realizationLayout ? 56 : 48),
      ),
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
        horizontal: realizationLayout || settings.layout == 'compact' ? 4 : 6,
        vertical: realizationLayout || settings.layout == 'compact' ? 4 : 7,
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

  static pw.Widget _signatures({required bool realizationLayout}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _signatureLine(realizationLayout ? 'Сдал' : 'Отпустил'),
        _signatureLine(realizationLayout ? 'Принял' : 'Получил'),
      ],
    );
  }

  static pw.Widget _cutSeparator() {
    return pw.Row(
      children: List.generate(
        47,
        (index) => pw.Expanded(
          child: pw.Container(
            height: 1,
            color: index.isEven ? PdfColors.grey500 : PdfColors.white,
          ),
        ),
      ),
    );
  }

  static String _realizationTitle(
    String title,
    exp_doc.ExpenseDocumentDetail document,
    PrintTemplateSettings settings,
  ) {
    final baseTitle = settings.customTitle.trim().isEmpty
        ? title
        : settings.customTitle.trim();
    final number = (document.docNumber ?? document.id ?? '').toString().trim();
    if (number.isEmpty) return baseTitle;
    final normalized = number.startsWith('№') ? number : '№$number';
    return '$baseTitle: $normalized';
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

  static pw.Widget _statusRow(String status) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'Статус: ',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        _statusChip(status),
      ],
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
