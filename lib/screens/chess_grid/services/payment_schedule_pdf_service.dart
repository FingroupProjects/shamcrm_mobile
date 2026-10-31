import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PaymentSchedulePdfService {
  const PaymentSchedulePdfService._();

  static Future<pw.Font> _loadRegularFont() async {
    final data = await rootBundle.load('assets/fonts/Gilroy-Regular.ttf');
    return pw.Font.ttf(data);
  }

  static Future<pw.Font> _loadBoldFont() async {
    final data = await rootBundle.load('assets/fonts/Gilroy-Bold.ttf');
    return pw.Font.ttf(data);
  }

  static Future<pw.MemoryImage?> _loadLogoImage() async {
    try {
      final data = await rootBundle.load('assets/icons/shamCRM.jpg');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  /// Builds the official 5-section Installment Schedule PDF matching the exact CRM specification.
  static Future<Uint8List> buildSchedulePdf({
    required Order order,
    required Apartment? apartment,
    required ParkingSpot? parking,
    required ResidentialComplex complex,
    required CompanyRequisites requisites,
    required PaymentDetails details,
  }) async {
    final doc = pw.Document();
    final fontRegular = await _loadRegularFont();
    final fontBold = await _loadBoldFont();
    final logoImage = await _loadLogoImage();

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
    );

    final dateFormat = DateFormat('dd.MM.yyyy');
    final numberFormat = NumberFormat('#,##0.00', 'ru_RU');
    final currency = apartment?.currency ?? '\$';

    final orderId = order.id.isNotEmpty ? order.id : 'ГП-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final createdDateStr = dateFormat.format(DateTime.now());

    final scheduleRows = details.schedule.isNotEmpty
        ? details.schedule
        : PaymentDetails.generateSchedule(
            totalInstallmentSum: details.installmentSum,
            months: details.months,
          );

    final firstPayDate = scheduleRows.isNotEmpty
        ? dateFormat.format(scheduleRows.first.date)
        : createdDateStr;
    final lastPayDate = scheduleRows.isNotEmpty
        ? dateFormat.format(scheduleRows.last.date)
        : createdDateStr;

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // ── Header: Company requisites & Logo ─────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      requisites.name.isNotEmpty
                          ? requisites.name.toUpperCase()
                          : 'ООО «СТРОИТЕЛЬНАЯ КОМПАНИЯ»',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 13,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Юридический адрес: ${requisites.address.isNotEmpty ? requisites.address : complex.address}',
                      style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      'Телефон: ${requisites.phone.isNotEmpty ? requisites.phone : complex.salesOffice.phone}   |   Email: ${requisites.email.isNotEmpty ? requisites.email : complex.salesOffice.email}',
                      style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                    ),
                    if (requisites.inn.isNotEmpty)
                      pw.Text(
                        'ИНН / реквизиты: ${requisites.inn}',
                        style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                      ),
                  ],
                ),
              ),
              if (logoImage != null)
                pw.Container(
                  width: 55,
                  height: 55,
                  margin: const pw.EdgeInsets.only(left: 12),
                  child: pw.ClipRRect(
                    horizontalRadius: 6,
                    verticalRadius: 6,
                    child: pw.Image(logoImage, fit: pw.BoxFit.cover),
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(thickness: 1.2, color: PdfColors.blueGrey400),
          pw.SizedBox(height: 8),

          // ── Title & Contract metadata ─────────────────────────────────────
          pw.Center(
            child: pw.Text(
              'ГРАФИК ПЛАТЕЖЕЙ ПО РАССРОЧКЕ',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 15,
                color: PdfColors.blueGrey900,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'Номер графика: $orderId    Дата формирования: $createdDateStr    Основание: договор № $orderId от $createdDateStr',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
            ),
          ),
          pw.SizedBox(height: 14),

          // ── Section 1: Customer and Apartment info ────────────────────────
          _buildSectionHeader('1. Сведения о покупателе и объекте', fontBold),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.2),
              1: const pw.FlexColumnWidth(3.8),
            },
            children: [
              _buildTableRow('Покупатель', order.buyerName.isNotEmpty ? order.buyerName : 'Не указан', fontBold),
              _buildTableRow('Телефон покупателя', order.buyerPhone.isNotEmpty ? order.buyerPhone : '—', fontBold),
              _buildTableRow('Жилой комплекс', complex.name, fontBold),
              _buildTableRow('Корпус', apartment?.buildingName ?? parking?.buildingKey ?? 'Корпус А', fontBold),
              if (apartment != null) ...[
                _buildTableRow('Подъезд', '${apartment.entrance}', fontBold),
                _buildTableRow('Этаж', '${apartment.floor}', fontBold),
                _buildTableRow('Квартира', '№ ${apartment.number}', fontBold),
                _buildTableRow('Общая площадь', '${apartment.totalArea.toStringAsFixed(1)} м²', fontBold),
                if (apartment.layoutType != null && apartment.layoutType!.isNotEmpty)
                  _buildTableRow('Тип планировки', apartment.layoutType!, fontBold),
              ] else if (parking != null) ...[
                _buildTableRow('Парковочное место', '№ ${parking.number}', fontBold),
                _buildTableRow('Тип парковки', parking.type, fontBold),
                _buildTableRow('Площадь парковки', '${parking.area.toStringAsFixed(1)} м²', fontBold),
              ],
            ],
          ),
          pw.SizedBox(height: 14),

          // ── Section 2: Payment conditions ─────────────────────────────────
          _buildSectionHeader('2. Условия оплаты', fontBold),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.2),
              1: const pw.FlexColumnWidth(3.8),
            },
            children: [
              _buildTableRow('Общая стоимость объекта', '${numberFormat.format(order.price)} $currency', fontBold),
              _buildTableRow('Первоначальный взнос', '${numberFormat.format(details.downPayment)} $currency', fontBold),
              if (details.barterAmount > 0)
                _buildTableRow(
                  'Зачет по бартеру (${details.barterSubject ?? "Бартер"})',
                  '${numberFormat.format(details.barterAmount)} $currency',
                  fontBold,
                ),
              _buildTableRow('Остаток к оплате в рассрочку', '${numberFormat.format(details.installmentSum)} $currency', fontBold),
              _buildTableRow('Срок рассрочки', '${details.months} месяцев', fontBold),
              _buildTableRow('Дата первого платежа', firstPayDate, fontBold),
              _buildTableRow('Дата последнего платежа', lastPayDate, fontBold),
              _buildTableRow('Плановый ежемесячный платёж', '${numberFormat.format(details.monthlyPayment)} $currency', fontBold),
              _buildTableRow('Валюта платежей', currency, fontBold),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Все суммы, даты и валюты в настоящем графике сформированы на основе согласованных условий сделки.',
            style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
          ),
          pw.SizedBox(height: 14),

          // ── Section 3: Schedule table ─────────────────────────────────────
          _buildSectionHeader('3. График платежей', fontBold),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(32),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2.5),
              3: const pw.FlexColumnWidth(3),
            },
            children: [
              // Header
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableCell('№', fontBold, align: pw.TextAlign.center),
                  _buildTableCell('Дата платежа', fontBold, align: pw.TextAlign.center),
                  _buildTableCell('Сумма платежа ($currency)', fontBold, align: pw.TextAlign.right),
                  _buildTableCell('Остаток задолженности ($currency)', fontBold, align: pw.TextAlign.right),
                ],
              ),
              // Schedule items
              ...scheduleRows.map((row) {
                return pw.TableRow(
                  children: [
                    _buildTableCell('${row.number}', fontRegular, align: pw.TextAlign.center),
                    _buildTableCell(dateFormat.format(row.date), fontRegular, align: pw.TextAlign.center),
                    _buildTableCell(numberFormat.format(row.paymentAmount), fontRegular, align: pw.TextAlign.right),
                    _buildTableCell(numberFormat.format(row.remainingDebt), fontRegular, align: pw.TextAlign.right),
                  ],
                );
              }),
              // Total Row
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('', fontBold),
                  _buildTableCell('Итого:', fontBold, align: pw.TextAlign.right),
                  _buildTableCell(numberFormat.format(details.installmentSum), fontBold, align: pw.TextAlign.right),
                  _buildTableCell('0.00', fontBold, align: pw.TextAlign.right),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // ── Section 4: Rules / Terms ──────────────────────────────────────
          _buildSectionHeader('4. Порядок оплаты', fontBold),
          pw.SizedBox(height: 6),
          _buildBullet('Покупатель осуществляет платежи в размерах и сроки, указанные в настоящем графике, с учётом условий договора.'),
          _buildBullet('Первоначальный взнос учитывается отдельно и не включается повторно в сумму платежей по рассрочке.'),
          _buildBullet('Последний платёж может отличаться от остальных в связи с округлением сумм до двух знаков после запятой.'),
          _buildBullet('При изменении стоимости объекта, условий рассрочки или сроков оплаты новый график оформляется в порядке, предусмотренном договором.'),
          _buildBullet('Фактическое исполнение обязательств определяется по поступившим платежам и условиям договора. Наличие графика само по себе не подтверждает факт оплаты.'),
          pw.SizedBox(height: 16),

          // ── Section 5: Signatures ─────────────────────────────────────────
          _buildSectionHeader('5. Подтверждение и подписи сторон', fontBold),
          pw.SizedBox(height: 6),
          pw.Text(
            'Настоящий график является приложением к договору № $orderId от $createdDateStr только в случае, если это предусмотрено договором и график надлежащим образом согласован сторонами.',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 14),

          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Продавец:', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      requisites.name.isNotEmpty ? requisites.name : 'Строительная компания',
                      style: pw.TextStyle(fontSize: 8.5),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('Представитель: ${order.manager.isNotEmpty ? order.manager : "Менеджер"}', style: pw.TextStyle(fontSize: 8.5)),
                    pw.SizedBox(height: 18),
                    pw.Text('Подпись: ______________________', style: pw.TextStyle(fontSize: 8.5)),
                    pw.SizedBox(height: 6),
                    pw.Text('Дата: _________________________', style: pw.TextStyle(fontSize: 8.5)),
                  ],
                ),
              ),
              pw.SizedBox(width: 24),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Покупатель:', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      order.buyerName.isNotEmpty ? order.buyerName : 'Покупатель',
                      style: pw.TextStyle(fontSize: 8.5),
                    ),
                    pw.SizedBox(height: 30),
                    pw.Text('Подпись: ______________________', style: pw.TextStyle(fontSize: 8.5)),
                    pw.SizedBox(height: 6),
                    pw.Text('Дата: _________________________', style: pw.TextStyle(fontSize: 8.5)),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 20),
          pw.Divider(thickness: 0.5, color: PdfColors.grey400),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'Документ сформирован в системе shamCRM',
              style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  /// Builds the official 1-page "Паспорт квартиры" / Commercial Proposal PDF matching the ТЗ card mockup.
  static Future<Uint8List> buildApartmentPassportPdf({
    required Apartment apartment,
    required ResidentialComplex complex,
    required CompanyRequisites requisites,
  }) async {
    final doc = pw.Document();
    final fontRegular = await _loadRegularFont();
    final fontBold = await _loadBoldFont();
    final logoImage = await _loadLogoImage();

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
    );

    final numberFormat = NumberFormat('#,##0.00', 'ru_RU');
    final currency = apartment.currency;

    doc.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      complex.name.toUpperCase(),
                      style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blueGrey900),
                    ),
                    pw.Text(
                      '${apartment.buildingName} · Этаж ${apartment.floor} · Подъезд ${apartment.entrance}',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                if (logoImage != null)
                  pw.Container(
                    width: 50,
                    height: 50,
                    child: pw.ClipRRect(
                      horizontalRadius: 6,
                      verticalRadius: 6,
                      child: pw.Image(logoImage, fit: pw.BoxFit.cover),
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(thickness: 1, color: PdfColors.blueGrey300),
            pw.SizedBox(height: 12),

            // Apartment Number Title & Price Badge
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'КВАРТИРА № ${apartment.number}',
                  style: pw.TextStyle(font: fontBold, fontSize: 20, color: PdfColors.blueGrey900),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber100,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.TableBorder.all(color: PdfColors.amber600, width: 1),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        '${numberFormat.format(apartment.totalPrice)} $currency',
                        style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blueGrey900),
                      ),
                      pw.Text(
                        '${numberFormat.format(apartment.pricePerSqm)} $currency / м²',
                        style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Specifications Table
            _buildSectionHeader('Характеристики квартиры', fontBold),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
              },
              children: [
                _buildTableRow('Площадь общая', '${apartment.totalArea.toStringAsFixed(1)} м²', fontBold),
                _buildTableRow('Жилая площадь', '${apartment.livingArea.toStringAsFixed(1)} м²', fontBold),
                _buildTableRow('Площадь кухни', '${apartment.kitchenArea.toStringAsFixed(1)} м²', fontBold),
                _buildTableRow('Количество комнат', '${apartment.rooms == 0 ? "Студия" : apartment.rooms}', fontBold),
                _buildTableRow('Тип планировки', apartment.layoutType ?? 'A', fontBold),
                _buildTableRow('Количество балконов / лоджий', '${apartment.balconiesCount}', fontBold),
                _buildTableRow('Количество совмещенных санузлов', '${apartment.combinedBathroomsCount}', fontBold),
                _buildTableRow('Этаж', '${apartment.floor}', fontBold),
                _buildTableRow('Тип отделки', apartment.type, fontBold),
                _buildTableRow('Статус', apartment.status.labelRu, fontBold),
              ],
            ),
            pw.SizedBox(height: 16),

            // Sales Office Info Box
            _buildSectionHeader('Контакты отдела продаж', fontBold),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Адрес офиса: ${complex.salesOffice.address.isNotEmpty ? complex.salesOffice.address : complex.address}', style: pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 3),
                  pw.Text('Телефон: ${complex.salesOffice.phone}', style: pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 3),
                  pw.Text('Email: ${complex.salesOffice.email}', style: pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 3),
                  pw.Text('Режим работы: ${complex.salesOffice.workingHours}', style: pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),

            pw.Spacer(),
            pw.Divider(thickness: 0.5, color: PdfColors.grey400),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Паспорт квартиры сформирован в системе shamCRM',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  // ── Helper builders ────────────────────────────────────────────────────────

  static pw.Widget _buildSectionHeader(String title, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: const pw.BoxDecoration(
        color: PdfColors.blueGrey50,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blueGrey800),
      ),
    );
  }

  static pw.TableRow _buildTableRow(String label, String value, pw.Font fontBold) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
          child: pw.Text(label, style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
          child: pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.blueGrey900)),
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.blueGrey900),
      ),
    );
  }

  static pw.Widget _buildBullet(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('• ', style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
          pw.Expanded(
            child: pw.Text(text, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
          ),
        ],
      ),
    );
  }

  /// Print or preview the schedule directly to system printer
  static Future<void> printSchedule({
    required Order order,
    required Apartment? apartment,
    required ParkingSpot? parking,
    required ResidentialComplex complex,
    required CompanyRequisites requisites,
    required PaymentDetails details,
  }) async {
    final bytes = await buildSchedulePdf(
      order: order,
      apartment: apartment,
      parking: parking,
      complex: complex,
      requisites: requisites,
      details: details,
    );
    await Printing.layoutPdf(
      name: 'График_рассрочки_${order.id}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  /// Share schedule PDF file via system dialog (WhatsApp, Telegram, Mail, AirDrop)
  static Future<void> shareSchedule({
    required Order order,
    required Apartment? apartment,
    required ParkingSpot? parking,
    required ResidentialComplex complex,
    required CompanyRequisites requisites,
    required PaymentDetails details,
  }) async {
    final bytes = await buildSchedulePdf(
      order: order,
      apartment: apartment,
      parking: parking,
      complex: complex,
      requisites: requisites,
      details: details,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'График_рассрочки_${order.id}.pdf',
    );
  }

  /// Print or preview apartment passport
  static Future<void> printApartmentPassport({
    required Apartment apartment,
    required ResidentialComplex complex,
    required CompanyRequisites requisites,
  }) async {
    final bytes = await buildApartmentPassportPdf(
      apartment: apartment,
      complex: complex,
      requisites: requisites,
    );
    await Printing.layoutPdf(
      name: 'Паспорт_квартиры_${apartment.number}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  /// Share apartment passport PDF
  static Future<void> shareApartmentPassport({
    required Apartment apartment,
    required ResidentialComplex complex,
    required CompanyRequisites requisites,
  }) async {
    final bytes = await buildApartmentPassportPdf(
      apartment: apartment,
      complex: complex,
      requisites: requisites,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Паспорт_квартиры_${apartment.number}.pdf',
    );
  }
}
