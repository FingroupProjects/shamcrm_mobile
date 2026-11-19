import 'dart:io';

import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_field_style.dart';
import 'package:crm_task_manager/models/lead/lead_list_model.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/page_2/warehouse/order_payments/order_payments_screen.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/lead_with_manager.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/file_picker_dialog.dart';
import 'package:crm_task_manager/models/common/file_helper.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ChessPaymentsView extends StatefulWidget {
  const ChessPaymentsView({super.key});

  @override
  State<ChessPaymentsView> createState() => _ChessPaymentsViewState();
}

class _ChessPaymentsViewState extends State<ChessPaymentsView> {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.getOrderInstallments();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Golos', color: colors.textSecondary)),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Повторить')),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Платежей пока нет\nОни появятся, когда сделка оформлена в рассрочку',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Gilroy', fontSize: 14, height: 1.4, color: colors.textSecondary),
          ),
        ),
      );
    }

    final totalDebt = _items.fold<double>(0, (sum, item) => sum + _num(item['debt']));
    final totalOverdue = _items.fold<double>(0, (sum, item) => sum + _num(item['overdue_amount']));
    final totalReceived = _items.fold<double>(0, (sum, item) => sum + _num(item['received']));
    final overdueBuyers = _items
        .where((item) => _num(item['overdue_amount']) > 0)
        .map((item) => _label(item['buyer'], item['order_id']?.toString() ?? ''))
        .toSet()
        .length;
    final biggest = [..._items]..sort((a, b) => _num(b['debt']).compareTo(_num(a['debt'])));
    final longest = _items.where((item) => _num(item['overdue_amount']) > 0).toList()
      ..sort((a, b) => (_overdueDays(b) ?? 0).compareTo(_overdueDays(a) ?? 0));

    Future<void> openItem(Map<String, dynamic> item) async {
      final changed = await _PaymentDetailSheet.show(context: context, item: item);
      if (changed == true) _load();
    }

    Future<void> createPayment() async {
      final item = await _CreatePaymentPicker.show(context: context);
      if (item == null || !mounted) return;
      final orderId = int.tryParse(item['order_id']?.toString() ?? '') ?? 0;
      if (orderId <= 0) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      Map<String, dynamic>? data;
      Object? error;
      try {
        data = await _api.getOrderInstallment(orderId);
        if (data == null) {
          Order? order;
          try {
            order = await _api.getOrderDetails(orderId);
          } catch (_) {}
          data = _buildFallbackInstallment(orderId: orderId, order: order, item: item);
        }
      } catch (e) {
        error = e;
      }
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (error != null) {
        showCustomSnackBar(context: context, message: error.toString().replaceFirst('Exception: ', ''), isSuccess: false);
        return;
      }
      data ??= _buildFallbackInstallment(orderId: orderId, item: item);
      final saved = await _AddPaymentSheet.open(
        context,
        orderId: orderId,
        installment: data,
        buyer: item['buyer']?.toString(),
        objectName: item['object']?.toString(),
        dealNumber: item['order_number']?.toString(),
      );
      if (saved == true) _load();
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
        itemCount: _items.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _PaymentsOverview(
              totalDebt: totalDebt,
              totalOverdue: totalOverdue,
              overdueBuyers: overdueBuyers,
              totalReceived: totalReceived,
              biggest: biggest.take(3).toList(),
              longest: longest.take(3).toList(),
              onOpen: openItem,
              onCreate: createPayment,
            );
          }
          final item = _items[index - 1];
          return _PaymentCard(item: item, onTap: () => openItem(item));
        },
      ),
    );
  }
}

class _PaymentsOverview extends StatelessWidget {
  final double totalDebt;
  final double totalOverdue;
  final int overdueBuyers;
  final double totalReceived;
  final List<Map<String, dynamic>> biggest;
  final List<Map<String, dynamic>> longest;
  final ValueChanged<Map<String, dynamic>> onOpen;
  final VoidCallback onCreate;

  const _PaymentsOverview({
    required this.totalDebt,
    required this.totalOverdue,
    required this.overdueBuyers,
    this.totalReceived = 0,
    required this.biggest,
    required this.longest,
    required this.onOpen,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfacePrimary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.7)),
            ),
            child: Column(
              children: [
                _metric(colors, 'Общая задолженность', _money(totalDebt), colors.textPrimary),
                const SizedBox(height: 10),
                _metric(colors, 'Просроченная задолженность', _money(totalOverdue), totalOverdue > 0 ? colors.error : colors.textPrimary),
                const SizedBox(height: 10),
                _metric(colors, 'Ожидается за период (план)', '—', colors.textSecondary),
                const SizedBox(height: 10),
                _metric(colors, 'Получено за период (факт)', totalReceived > 0 ? _money(totalReceived) : '—', totalReceived > 0 ? colors.textPrimary : colors.textSecondary),
                const SizedBox(height: 10),
                _metric(colors, 'Покупателей с просрочкой', '$overdueBuyers', colors.textPrimary),
                const SizedBox(height: 10),
                _metric(colors, 'Платежи за период', '—', colors.textSecondary, subtitle: 'оплачено / частично / не в срок'),
              ],
            ),
          ),
          /*
          if (biggest.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionTitle(colors, 'Крупные долги'),
            const SizedBox(height: 8),
            ...biggest.map((item) => _rankRow(
                  colors,
                  title: _buyerName(item),
                  subtitle: _dealCaption(item),
                  trailing: _money(item['debt']),
                  trailingColor: colors.textPrimary,
                  onTap: () => onOpen(item),
                )),
          ],
          if (longest.isNotEmpty) ...[
            const SizedBox(height: 8),
            _sectionTitle(colors, 'Долгие просрочки'),
            const SizedBox(height: 8),
            ...longest.map((item) {
              final days = _overdueDays(item);
              return _rankRow(
                colors,
                title: _buyerName(item),
                subtitle: _dealCaption(item),
                trailing: days == null ? _money(item['overdue_amount']) : '$days дн.',
                trailingColor: colors.error,
                onTap: () => onOpen(item),
              );
            }),
          ],
          */
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _sectionTitle(colors, 'Сделки')),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OrderPaymentsScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.receipt_long_rounded, size: 16, color: colors.buttonPrimaryBg),
                label: Text(
                  'Отчет платежей',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: colors.buttonPrimaryBg,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.buttonPrimaryBg),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: colors.buttonPrimaryBg,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onCreate,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 16, color: colors.buttonPrimaryFg),
                        const SizedBox(width: 4),
                        Text(
                          'Создать платёж',
                          style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 12.5, color: colors.buttonPrimaryFg),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _metric(dynamic colors, String label, String value, Color valueColor, {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(fontFamily: 'Gilroy', fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontFamily: 'Gilroy', fontSize: 11, color: colors.textSecondary.withValues(alpha: 0.75)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(value, style: TextStyle(fontFamily: 'Gilroy', fontSize: 15, fontWeight: FontWeight.w700, color: valueColor)),
      ],
    );
  }

  Widget _sectionTitle(dynamic colors, String text) {
    return Text(text, style: TextStyle(fontFamily: 'Gilroy', fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary));
  }

  // ignore: unused_element
  Widget _rankRow(
    dynamic colors, {
    required String title,
    required String subtitle,
    required String trailing,
    required Color trailingColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.7)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, fontSize: 13.5, color: colors.textPrimary)),
                      Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Gilroy', fontSize: 11.5, color: colors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(trailing, style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 14, color: trailingColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const _PaymentCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final status = item['settlement_status']?.toString();
    final overdue = _num(item['overdue_amount']);
    final next = item['next_payment'] is Map ? item['next_payment'] as Map : null;
    final statusColor = _statusColor(status, colors);

    final buyer = _buyerName(item);
    final object = _label(item['object'], '');
    final nextLine = overdue > 0
        ? 'Просрочено ${_money(overdue)}'
        : next == null
            ? 'Следующего платежа нет'
            : 'Следующий платёж ${_date(next['date'])} · ${_money(next['amount'])}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: colors.surfacePrimary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.7), width: 1),
              boxShadow: [
                BoxShadow(color: colors.shadow.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              'Сделка №${item['order_number'] ?? item['order_id'] ?? '—'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 15.5, color: colors.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(label: _dealStatus(status), color: statusColor),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _iconLine(colors, Icons.person_outline_rounded, buyer, strong: true, link: true),
                      if (object.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _iconLine(colors, Icons.apartment_outlined, object),
                      ],
                      const SizedBox(height: 4),
                      _iconLine(colors, Icons.payments_outlined, 'Получено ${_money(item['received'])}'),
                      const SizedBox(height: 4),
                      _iconLine(colors, overdue > 0 ? Icons.error_outline : Icons.event_outlined, nextLine, danger: overdue > 0),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated.withValues(alpha: 0.65),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                    border: Border(top: BorderSide(color: colors.borderSubtle.withValues(alpha: 0.7))),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Долг',
                        style: TextStyle(fontFamily: 'Gilroy', fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary),
                      ),
                      const Spacer(),
                      Text(
                        _money(item['debt']),
                        style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 16.5, color: colors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconLine(dynamic colors, IconData icon, String text, {bool strong = false, bool danger = false, bool link = false}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: danger ? colors.error : (link ? colors.buttonPrimaryBg : colors.textSecondary)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: strong ? 13 : 12,
              fontWeight: strong ? FontWeight.w600 : FontWeight.w500,
              color: danger ? colors.error : (link ? colors.buttonPrimaryBg : (strong ? colors.textPrimary : colors.textSecondary)),
              decoration: link ? TextDecoration.underline : null,
              decorationColor: link ? colors.buttonPrimaryBg : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentDetailSheet extends StatefulWidget {
  final Map<String, dynamic> item;

  const _PaymentDetailSheet({required this.item});

  static Future<bool?> show({required BuildContext context, required Map<String, dynamic> item}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentDetailSheet(item: item),
    );
  }

  @override
  State<_PaymentDetailSheet> createState() => _PaymentDetailSheetState();
}

class _PaymentDetailSheetState extends State<_PaymentDetailSheet> {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;
  List<Map<String, dynamic>> _contracts = const [];
  String? _contractsError;
  Map<int, String> _staff = const {};
  bool _changed = false;
  bool _downloading = false;

  int get _orderId => int.tryParse(widget.item['order_id']?.toString() ?? '') ?? 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var data = await _api.getOrderInstallment(_orderId);
      if (data == null) {
        Order? order;
        try {
          order = await _api.getOrderDetails(_orderId);
        } catch (_) {}
        data = _buildFallbackInstallment(orderId: _orderId, order: order, item: widget.item);
      }
      List<Map<String, dynamic>> contracts = const [];
      String? contractsError;
      try {
        contracts = await _api.getOrderContracts(_orderId);
      } catch (e) {
        contractsError = e.toString().replaceFirst('Exception: ', '');
      }
      final staff = await _loadStaff();
      if (!mounted) return;
      setState(() {
        _data = data;
        _contracts = contracts;
        _contractsError = contractsError;
        _staff = staff;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _add() async {
    final data = _data ?? _buildFallbackInstallment(orderId: _orderId, item: widget.item);
    final saved = await _AddPaymentSheet.open(
      context,
      orderId: _orderId,
      installment: data,
      buyer: _buyerName(widget.item),
      objectName: widget.item['object']?.toString(),
      dealNumber: widget.item['order_number']?.toString(),
    );
    if (saved == true) {
      _changed = true;
      _load();
    }
  }

  Future<void> _download(Map<String, dynamic> data, Map<String, dynamic> down, List<Map<String, dynamic>> lines) async {
    setState(() => _downloading = true);
    try {
      final regular = await rootBundle.load('assets/fonts/Gilroy-Regular.ttf');
      final bold = await rootBundle.load('assets/fonts/Gilroy-Bold.ttf');
      final font = pw.Font.ttf(regular);
      final fontBold = pw.Font.ttf(bold);
      final doc = pw.Document();
      final title = 'Сделка №${widget.item['order_number'] ?? _orderId}';
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          build: (context) => [
            pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 16)),
            pw.SizedBox(height: 4),
            pw.Text('${_buyerName(widget.item)} · ${_label(widget.item['object'], '—')}', style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(font: fontBold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headers: const ['№', 'Дата', 'По графику', 'Оплачено', 'Остаток', 'Статус'],
              data: [
                ['Взнос', '—', _money(down['planned']), _money(down['paid']), _money(down['remainder']), _lineStatus(down['status']?.toString())],
                ...lines.map((line) => [
                      '${line['position'] ?? ''}',
                      _date(line['due_date']),
                      _money(line['planned']),
                      _money(line['paid']),
                      _money(line['remainder']),
                      _lineStatus(line['status']?.toString()),
                    ]),
              ],
            ),
          ],
        ),
      );
      await Printing.sharePdf(bytes: await doc.save(), filename: 'grafik-$_orderId.pdf');
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(context: context, message: 'Не удалось скачать график', isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final data = _data;
    final down = data?['down_payment'] is Map ? Map<String, dynamic>.from(data!['down_payment'] as Map) : <String, dynamic>{};
    final lines = (data?['lines'] as List?)?.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() ?? const <Map<String, dynamic>>[];
    final payments = (data?['payments'] as List?)?.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() ?? const <Map<String, dynamic>>[];
    final buyer = _buyerName(widget.item);
    final number = widget.item['order_number'] ?? _orderId;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.94),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: colors.borderSubtle, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Сделка №$number${buyer == '—' ? '' : ': $buyer'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w800, fontSize: 16.5, color: colors.textPrimary),
                      ),
                      Text(
                        _label(widget.item['object'], 'Объект не указан'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: 'Gilroy', fontSize: 12, fontWeight: FontWeight.w500, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, _changed),
                  icon: Icon(Icons.close_rounded, color: colors.iconSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: TextStyle(fontFamily: 'Golos', color: colors.textSecondary)))
                    : data == null
                        ? Center(child: Text('Графика нет', style: TextStyle(fontFamily: 'Golos', color: colors.textSecondary)))
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                            children: [
                              _metrics(colors, data, down),
                              const SizedBox(height: 12),
                              _contractsBlock(colors),
                              const SizedBox(height: 12),
                              _notices(colors, lines, data: data, down: down),
                              const SizedBox(height: 12),
                              _actions(colors, data, down, lines),
                              if (payments.where((payment) => payment['status']?.toString() == 'draft').isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Ждут подтверждения: ${payments.where((payment) => payment['status']?.toString() == 'draft').length}. До подтверждения они не входят в оплаченное.',
                                  style: TextStyle(fontFamily: 'Gilroy', fontSize: 12, height: 1.3, color: colors.textSecondary),
                                ),
                              ],
                              const SizedBox(height: 16),
                              Text(
                                'История операций',
                                style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 14, color: colors.textPrimary),
                              ),
                              const SizedBox(height: 10),
                              _historyList(colors, payments, lines),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _metrics(dynamic colors, Map<String, dynamic> data, Map<String, dynamic> down) {
    final total = _num(data['total_amount'] ?? widget.item['total_amount']);
    final barter = _num(data['barter_amount'] ?? widget.item['barter_amount']);
    final cash = (total - barter).clamp(0, double.infinity);
    final next = data['next_payment'] is Map ? data['next_payment'] as Map : widget.item['next_payment'] is Map ? widget.item['next_payment'] as Map : null;
    final refunds = _refunds(data['payments']);
    final penalty = _firstNum(data, const ['penalty_due', 'penalty_amount', 'penalties', 'penalty']);
    final lines = (data['lines'] as List?)?.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() ?? const <Map<String, dynamic>>[];
    final isInstallment = _isInstallment(data, lines);
    final cards = isInstallment
        ? [
            _metric(colors, 'Стоимость сделки', _money(total), 'Сумма сделки'),
            _metric(colors, 'Первоначальный взнос', _money(down['planned']), 'получено ${_money(down['paid'])}, ${_lineStatus(down['status']?.toString()).toLowerCase()}'),
            _metric(colors, 'Бартер', barter > 0 ? _money(barter) : '—', barter > 0 ? _label(data['barter_note'], 'учтён в сумме') : 'не применяется'),
            _metric(colors, 'К оплате деньгами', _money(cash), 'в графике рассрочки: ${_money(data['schedule_amount'] ?? widget.item['schedule_amount'])}'),
            _metric(colors, 'Оплачено', _money(data['received'] ?? widget.item['received']), 'возвраты: ${_money(refunds)}'),
            _metric(colors, 'Остаток долга', _money(data['debt'] ?? widget.item['debt']), _dealStatus(data['settlement_status']?.toString() ?? widget.item['settlement_status']?.toString())),
            _metric(colors, 'Просрочено', _money(data['overdue_amount'] ?? widget.item['overdue_amount']), _num(data['overdue_amount'] ?? widget.item['overdue_amount']) > 0 ? 'есть просрочка' : 'просрочек нет', danger: _num(data['overdue_amount'] ?? widget.item['overdue_amount']) > 0),
            _metric(colors, 'Ближайший платёж', next == null ? '—' : _money(next['amount']), next == null ? 'нет' : 'на ${_date(next['date'])}'),
            _metric(colors, 'Пени к оплате', _money(penalty), penalty > 0 ? 'начислено' : 'начислений нет'),
          ]
        : [
            _metric(colors, 'Стоимость сделки', _money(total), 'Сумма сделки'),
            _metric(colors, 'Оплачено', _money(data['received'] ?? widget.item['received']), 'возвраты: ${_money(refunds)}'),
            _metric(colors, 'Остаток долга', _money(data['debt'] ?? widget.item['debt']), _dealStatus(data['settlement_status']?.toString() ?? widget.item['settlement_status']?.toString())),
            if (barter > 0)
              _metric(colors, 'Бартер', _money(barter), _label(data['barter_note'], 'учтён в сумме')),
            _metric(colors, 'Просрочено', _money(data['overdue_amount'] ?? widget.item['overdue_amount']), _num(data['overdue_amount'] ?? widget.item['overdue_amount']) > 0 ? 'есть просрочка' : 'просрочек нет', danger: _num(data['overdue_amount'] ?? widget.item['overdue_amount']) > 0),
            if (penalty > 0)
              _metric(colors, 'Пени к оплате', _money(penalty), 'начислено'),
          ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }

  Widget _metric(dynamic colors, String label, String value, String caption, {bool danger = false}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: danger ? colors.error.withValues(alpha: 0.06) : colors.surfaceElevated.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (danger ? colors.error : colors.borderSubtle).withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Gilroy', fontSize: 11, fontWeight: FontWeight.w600, color: colors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Gilroy', fontSize: 15, fontWeight: FontWeight.w800, height: 1.15, color: danger ? colors.error : colors.textPrimary)),
          const SizedBox(height: 2),
          Text(caption, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Gilroy', fontSize: 10.5, height: 1.2, color: colors.textSecondary)),
        ],
      ),
    );
  }

  Widget _contractsBlock(dynamic colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Договор', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 14, color: colors.textPrimary)),
          const SizedBox(height: 8),
          if (_contractsError != null)
            Text(_contractsError!, style: TextStyle(fontFamily: 'Gilroy', fontSize: 12.5, color: colors.textSecondary))
          else if (_contracts.isEmpty)
            Text('Договор не составлен.', style: TextStyle(fontFamily: 'Gilroy', fontSize: 12.5, color: colors.textSecondary))
          else
            ..._contracts.map((item) => _contractRow(colors, item)),
        ],
      ),
    );
  }

  Widget _contractRow(dynamic colors, Map<String, dynamic> item) {
    final number = _label(item['number'], 'без номера');
    final type = _label(item['document_type_label'], 'Документ');
    final status = _label(item['status_label'], '');
    final date = _date(item['contract_date']);
    final hasFile = item['has_file'] == true || item['has_file'] == 1;
    final hasScan = item['has_scan'] == true || item['has_scan'] == 1;
    final current = item['is_current'] == true || item['is_current'] == 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _label(item['title'], type),
            style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 13.5, color: colors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            [type, '№ $number', date == '—' ? '' : date, status, current ? '' : 'старая версия'].where((part) => part.isNotEmpty).join(' · '),
            style: TextStyle(fontFamily: 'Gilroy', fontSize: 12, color: colors.textSecondary),
          ),
          if (hasFile || hasScan) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                if (hasFile) _historyAction(colors, 'Файл', () => _openContract(item, scan: false)),
                if (hasScan) _historyAction(colors, 'Скан', () => _openContract(item, scan: true)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openContract(Map<String, dynamic> item, {required bool scan}) async {
    final id = int.tryParse(item['id']?.toString() ?? '');
    if (id == null) return;
    try {
      final bytes = await _api.downloadOrderContractBytes(orderId: _orderId, contractId: id, scan: scan);
      final directory = await getTemporaryDirectory();
      final ext = _fileExt(scan ? item['scan_url'] : item['file_url'], fallback: scan ? 'jpg' : 'pdf');
      final file = File('${directory.path}/contract-$id${scan ? '-scan' : ''}.$ext');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFile.open(file.path);
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(context: context, message: e.toString().replaceFirst('Exception: ', ''), isSuccess: false);
    }
  }

  String _fileExt(dynamic url, {required String fallback}) {
    final match = RegExp(r'\.([a-zA-Z0-9]{2,5})(?:\?|$)').firstMatch(url?.toString() ?? '');
    return match?.group(1)?.toLowerCase() ?? fallback;
  }

  Widget _notices(
    dynamic colors,
    List<Map<String, dynamic>> lines, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? down,
  }) {
    final notices = <_PaymentNotice>[];

    // 1. Просроченные платежи
    for (final line in lines) {
      if (_num(line['remainder']) <= 0) continue;
      final overdueDays = int.tryParse(line['overdue_days']?.toString() ?? '') ?? 0;
      final isOverdue = line['status']?.toString() == 'overdue' || overdueDays > 0;
      if (isOverdue) {
        final pos = line['position'] ?? '';
        final dStr = _date(line['due_date']);
        final sumStr = _money(line['remainder']);
        notices.add(_PaymentNotice(
          date: dStr,
          channel: 'CRM',
          text: 'Просрочен платёж №$pos от $dStr: $sumStr',
          isOverdue: true,
        ));
      }
    }

    // 2. Ближайший ожидаемый платёж (первая непросроченная открытая строка)
    for (final line in lines) {
      if (_num(line['remainder']) <= 0) continue;
      final overdueDays = int.tryParse(line['overdue_days']?.toString() ?? '') ?? 0;
      final isOverdue = line['status']?.toString() == 'overdue' || overdueDays > 0;
      if (!isOverdue) {
        final pos = line['position'] ?? '';
        final dStr = _date(line['due_date']);
        final sumStr = _money(line['remainder']);
        notices.add(_PaymentNotice(
          date: dStr,
          channel: 'CRM',
          text: 'Ожидается платёж №$pos от $dStr: $sumStr',
          isOverdue: false,
        ));
        break;
      }
    }

    // 3. Если в lines ничего не добавилось, проверяем next_payment
    if (notices.isEmpty && data?['next_payment'] is Map) {
      final next = data!['next_payment'] as Map;
      final amount = _num(next['amount']);
      if (amount > 0) {
        final dStr = _date(next['date']);
        notices.add(_PaymentNotice(
          date: dStr,
          channel: 'CRM',
          text: 'Ожидается платёж от $dStr: ${_money(amount)}',
          isOverdue: false,
        ));
      }
    }

    // 4. Если всё ещё пусто, но взнос не оплачен
    if (notices.isEmpty && down != null && _num(down['remainder']) > 0) {
      final dStr = _date(data?['first_payment_date'] ?? data?['created_at']);
      final sumStr = _money(down['remainder']);
      notices.add(_PaymentNotice(
        date: dStr == '—' ? _date(DateTime.now().toIso8601String()) : dStr,
        channel: 'CRM',
        text: 'Ожидается первоначальный взнос: $sumStr',
        isOverdue: false,
      ));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Уведомления', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 14, color: colors.textPrimary)),
          const SizedBox(height: 10),
          if (notices.isEmpty)
            Text('Уведомлений пока нет', style: TextStyle(fontFamily: 'Gilroy', fontSize: 12.5, color: colors.textSecondary))
          else ...[
            Row(
              children: [
                SizedBox(
                  width: 85,
                  child: Text('Дата', style: TextStyle(fontFamily: 'Gilroy', fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary)),
                ),
                SizedBox(
                  width: 50,
                  child: Text('Канал', style: TextStyle(fontFamily: 'Gilroy', fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Текст', style: TextStyle(fontFamily: 'Gilroy', fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...notices.map((n) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 85,
                        child: Text(n.date, style: TextStyle(fontFamily: 'Gilroy', fontSize: 12.5, color: colors.textPrimary)),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(n.channel, style: TextStyle(fontFamily: 'Gilroy', fontSize: 12.5, color: colors.textPrimary)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          n.text,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 12.5,
                            height: 1.3,
                            color: n.isOverdue ? colors.error : colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  bool _isInstallment(Map<String, dynamic> data, List<Map<String, dynamic>> lines) {
    final type = '${data['deal_type'] ?? widget.item['deal_type'] ?? ''}'.toLowerCase();
    if (type.contains('cash') || type.contains('налич')) return false;
    if (type.contains('install') || type.contains('рассроч') || type.contains('mixed') || type.contains('смеш')) return true;
    if (lines.isNotEmpty) return true;
    return _num(data['schedule_amount'] ?? widget.item['schedule_amount']) > 0;
  }

  Widget _actions(dynamic colors, Map<String, dynamic> data, Map<String, dynamic> down, List<Map<String, dynamic>> lines) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _actionButton(colors, 'Добавить платёж', filled: true, onTap: _add),
        if (_isInstallment(data, lines))
          _actionButton(colors, _downloading ? 'Готовим файл…' : 'Скачать график', onTap: _downloading ? null : () => _download(data, down, lines)),
      ],
    );
  }

  Widget _actionButton(dynamic colors, String label, {required VoidCallback? onTap, bool filled = false}) {
    return Material(
      color: filled ? colors.buttonPrimaryBg : colors.surfacePrimary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: filled ? colors.buttonPrimaryBg : colors.borderSubtle),
          ),
          child: Text(
            label,
            style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 13, color: filled ? colors.buttonPrimaryFg : colors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _historyList(dynamic colors, List<Map<String, dynamic>> payments, List<Map<String, dynamic>> lines) {
    if (payments.isEmpty) {
      return Text('Операций пока нет', style: TextStyle(fontFamily: 'Gilroy', fontSize: 13, color: colors.textSecondary));
    }
    final sorted = [...payments]..sort((a, b) => (b['paid_at']?.toString() ?? '').compareTo(a['paid_at']?.toString() ?? ''));
    return Column(
      children: sorted.map((payment) {
        final refund = payment['source_payment_id'] != null;
        final status = payment['status']?.toString();
        final entered = _person(payment['author'] ?? payment['author_name'] ?? payment['author_id']);
        final confirmed = _person(payment['confirmed_by_user'] ?? payment['confirmer'] ?? payment['confirmed_by']);
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(_date(payment['paid_at']), style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 13, color: colors.textPrimary)),
                  ),
                  _statusChip(colors, status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text(refund ? 'Возврат' : 'Платёж', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 14, color: colors.textPrimary))),
                  Text('${refund ? '−' : ''}${_money(payment['amount'])}', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w800, fontSize: 15, color: colors.textPrimary)),
                ],
              ),
              const SizedBox(height: 8),
              _historyField(colors, 'Способ', _method(payment['method']?.toString())),
              _historyField(colors, 'Документ', _label(payment['document_number'], '—')),
              _historyField(colors, 'Распределение', _allocationText(payment, lines)),
              _historyField(colors, 'Сотрудники', 'Внёс: $entered${confirmed == '—' ? '' : '\nПодтвердил: $confirmed'}'),
              if (status == 'draft') ...[
                const SizedBox(height: 8),
                _historyAction(colors, 'Подтвердить', () => _confirm(payment)),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _historyField(dynamic colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(label, style: TextStyle(fontFamily: 'Gilroy', fontSize: 12, color: colors.textSecondary)),
          ),
          Expanded(child: Text(value, style: TextStyle(fontFamily: 'Gilroy', fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3, color: colors.textPrimary))),
        ],
      ),
    );
  }

  Widget _statusChip(dynamic colors, String? status) {
    final confirmed = status == 'confirmed';
    final reversed = status == 'reversed';
    final color = confirmed ? colors.success : reversed ? colors.error : colors.buttonPrimaryBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(_payStatus(status), style: TextStyle(fontFamily: 'Gilroy', fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _historyAction(dynamic colors, String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Text(label, style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 12, color: colors.buttonPrimaryBg)),
      ),
    );
  }

  Future<void> _confirm(Map<String, dynamic> payment) async {
    final data = _data;
    if (data == null) return;
    final saved = await _AddPaymentSheet.open(
      context,
      orderId: _orderId,
      installment: data,
      existing: payment,
      buyer: _buyerName(widget.item),
      objectName: widget.item['object']?.toString(),
      dealNumber: widget.item['order_number']?.toString(),
    );
    if (saved == true) {
      _changed = true;
      _load();
    }
  }

  double _refunds(dynamic payments) {
    if (payments is! List) return 0;
    var sum = 0.0;
    for (final raw in payments) {
      if (raw is! Map) continue;
      if (raw['source_payment_id'] == null) continue;
      if (raw['status']?.toString() == 'reversed') continue;
      sum += _num(raw['amount']);
    }
    return sum;
  }

  double _firstNum(Map data, List<String> keys) {
    for (final key in keys) {
      if (data[key] != null) return _num(data[key]);
    }
    return 0;
  }

  Future<Map<int, String>> _loadStaff() async {
    try {
      final response = await _api.getAllManager(perPage: 200);
      final names = <int, String>{};
      for (final manager in response.result ?? const []) {
        final last = manager.lastname?.trim() ?? '';
        final name = manager.name.trim();
        if (name.isEmpty) continue;
        names[manager.id] = last.isEmpty ? name : '$name ${last[0]}.';
      }
      return names;
    } catch (_) {
      return const {};
    }
  }

  String _person(dynamic value) {
    if (value is Map) {
      final name = '${value['name'] ?? value['full_name'] ?? ''}'.trim();
      final last = '${value['lastname'] ?? value['last_name'] ?? ''}'.trim();
      if (name.isNotEmpty && last.isNotEmpty) return '$name ${last[0]}.';
      if (name.isNotEmpty) return name;
      return '—';
    }
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') return '—';
    final id = int.tryParse(text);
    if (id != null) return _staff[id] ?? '—';
    return text;
  }

  String _allocationText(Map payment, List<Map<String, dynamic>> lines) {
    if (payment['source_payment_id'] != null) {
      final reason = _label(payment['reversal_reason'] ?? payment['comment'], '');
      return 'К платежу №${payment['source_payment_id']}${reason.isEmpty ? '' : ': $reason'}';
    }
    final allocs = payment['allocations'];
    if (allocs is! List || allocs.isEmpty) return 'Ещё не подтверждён';
    final parts = <String>[];
    for (final raw in allocs) {
      if (raw is! Map) continue;
      final type = raw['type']?.toString();
      final amount = _money(raw['amount']);
      if (type == 'down_payment') {
        parts.add('Взнос $amount');
      } else if (type == 'early_repayment') {
        parts.add('Досрочное погашение $amount');
      } else if (type == 'unallocated') {
        parts.add('Другой $amount');
      } else if (raw['schedule_line_id'] != null) {
        Map<String, dynamic>? line;
        for (final item in lines) {
          if (item['id']?.toString() == raw['schedule_line_id']?.toString()) {
            line = item;
            break;
          }
        }
        final position = line?['position'];
        parts.add(position == null ? 'Платёж $amount' : 'Платёж №$position $amount');
      } else {
        parts.add(amount);
      }
    }
    return parts.isEmpty ? '—' : parts.join(', ');
  }
}

class _CreatePaymentPicker extends StatefulWidget {
  const _CreatePaymentPicker();

  static Future<Map<String, dynamic>?> show({required BuildContext context}) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreatePaymentPicker(),
    );
  }

  @override
  State<_CreatePaymentPicker> createState() => _CreatePaymentPickerState();
}

class _DealOption {
  final Order order;
  final String title;

  const _DealOption(this.order, this.title);

  @override
  String toString() => title;

  @override
  bool operator ==(Object other) => other is _DealOption && other.order.id == order.id;

  @override
  int get hashCode => order.id.hashCode;
}

class _CreatePaymentPickerState extends State<_CreatePaymentPicker> {
  final ApiService _api = ApiService();
  LeadData? _lead;
  _DealOption? _deal;
  List<_DealOption> _deals = const [];
  bool _dealsLoading = false;
  String? _dealsError;
  int _dealListVersion = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
      margin: EdgeInsets.only(bottom: bottom),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: colors.borderSubtle, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Создание платежа', style: TextStyle(fontFamily: 'Gilroy', fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(
                        'Выберите клиента и сделку',
                        style: TextStyle(fontFamily: 'Gilroy', fontSize: 12.5, fontWeight: FontWeight.w500, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: colors.iconSecondary)),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              children: [
                LeadWithManager(
                  selectedLead: _lead?.id.toString(),
                  onSelectLead: _onLeadSelected,
                ),
                const SizedBox(height: 8),
                _fieldLabel(colors, 'Сделка'),
                const SizedBox(height: 6),
                if (_lead == null)
                  _closedHint(colors, 'Сначала выберите клиента')
                else if (_dealsLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
                  )
                else if (_dealsError != null)
                  Text(_dealsError!, style: TextStyle(fontFamily: 'Gilroy', fontSize: 12.5, color: colors.textSecondary))
                else if (_deals.isEmpty)
                  _closedHint(colors, 'У клиента нет сделок')
                else
                  CustomDropdown<_DealOption>.search(
                    key: ValueKey('payment_deal_${_lead!.id}_$_dealListVersion'),
                    items: _deals,
                    initialItem: _deal,
                    hintText: 'Выберите сделку',
                    searchHintText: 'Поиск',
                    overlayHeight: 280,
                    excludeSelected: false,
                    decoration: AppFieldStyle.dropdownDecoration(context),
                    listItemBuilder: (context, item, isSelected, onItemSelect) {
                      return Text(item.title, style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w500, fontSize: 14, color: colors.textPrimary));
                    },
                    headerBuilder: (context, item, enabled) {
                      return Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w500, fontSize: 14, color: colors.textPrimary));
                    },
                    onChanged: (value) => setState(() => _deal = value),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + MediaQuery.paddingOf(context).bottom),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Отмена', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, color: colors.textSecondary)),
                ),
                const Spacer(),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _deal == null
                        ? null
                        : () => Navigator.pop(context, {
                              'order_id': _deal!.order.id,
                              'order_number': _deal!.order.orderNumber,
                              'buyer': _lead?.name,
                              'lead_id': _lead?.id,
                              'object': _deal!.order.goods.isEmpty ? null : _deal!.order.goods.first.goodName,
                            }),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Продолжить', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.buttonPrimaryBg,
                      foregroundColor: colors.buttonPrimaryFg,
                      disabledBackgroundColor: colors.buttonPrimaryBg.withValues(alpha: 0.35),
                      disabledForegroundColor: colors.buttonPrimaryFg.withValues(alpha: 0.7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onLeadSelected(LeadData lead) async {
    if (_lead?.id == lead.id && _deals.isNotEmpty) return;
    setState(() {
      _lead = lead;
      _deal = null;
      _deals = const [];
      _dealsError = null;
      _dealsLoading = true;
      _dealListVersion++;
    });
    try {
      final response = await _api.getOrdersByLead(leadId: lead.id, perPage: 50);
      if (!mounted || _lead?.id != lead.id) return;
      final deals = response.data.map((order) => _DealOption(order, _orderTitle(order))).toList();
      setState(() {
        _deals = deals;
        _dealsLoading = false;
        if (deals.length == 1) _deal = deals.first;
      });
    } catch (e) {
      if (!mounted || _lead?.id != lead.id) return;
      setState(() {
        _dealsError = e.toString().replaceFirst('Exception: ', '');
        _dealsLoading = false;
      });
    }
  }

  String _orderTitle(Order order) {
    final number = order.orderNumber.trim().isEmpty ? order.id.toString() : order.orderNumber;
    final sum = order.sum;
    return sum == null ? 'Сделка №$number' : 'Сделка №$number · ${_money(sum)}';
  }

  Widget _closedHint(dynamic colors, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: colors.fieldBackground,
        borderRadius: AppFieldStyle.radius,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Text(text, style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w500, fontSize: 14, color: colors.textSecondary)),
    );
  }

  Widget _fieldLabel(dynamic colors, String text) {
    return Text(text, style: TextStyle(fontFamily: 'Gilroy', fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary));
  }
}

class _AddPaymentSheet extends StatefulWidget {
  final int orderId;
  final Map<String, dynamic> installment;
  final Map<String, dynamic>? existing;
  final String? buyer;
  final String? objectName;
  final String? dealNumber;

  const _AddPaymentSheet({
    required this.orderId,
    required this.installment,
    this.existing,
    this.buyer,
    this.objectName,
    this.dealNumber,
  });

  static Future<bool?> open(
    BuildContext context, {
    required int orderId,
    required Map<String, dynamic> installment,
    Map<String, dynamic>? existing,
    String? buyer,
    String? objectName,
    String? dealNumber,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _AddPaymentSheet(
          orderId: orderId,
          installment: installment,
          existing: existing,
          buyer: buyer,
          objectName: objectName,
          dealNumber: dealNumber,
        ),
      ),
    );
  }

  @override
  State<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<_AddPaymentSheet> {
  final ApiService _api = ApiService();
  final _amount = TextEditingController();
  final _document = TextEditingController();
  final _comment = TextEditingController();
  final List<FileHelper> _files = [];
  DateTime _paidAt = DateTime.now();
  String _method = 'cash';
  String _type = 'schedule_line';
  int? _lineId;
  int? _obligationId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final down = widget.installment['down_payment'] is Map
        ? Map<String, dynamic>.from(widget.installment['down_payment'] as Map)
        : <String, dynamic>{};
    _obligationId = int.tryParse(down['obligation_id']?.toString() ?? '');
    final downLeft = _num(down['remainder']);
    final lines = _scheduleLines(widget.installment);
    final openLine = _nextOpenLine(lines);
    if (openLine != null) {
      _lineId = int.tryParse(openLine['id']?.toString() ?? '');
    }
    final existing = widget.existing;
    if (existing != null) {
      _amount.text = _plain(_num(existing['amount']));
      _document.text = existing['document_number']?.toString() ?? '';
      _comment.text = existing['comment']?.toString() ?? '';
      final method = existing['method']?.toString();
      if (method == 'cash' || method == 'transfer' || method == 'terminal') _method = method!;
      _paidAt = DateTime.tryParse(existing['paid_at']?.toString() ?? '') ?? DateTime.now();
      if (downLeft > 0 && _obligationId != null) {
        _type = 'down_payment';
      } else if (openLine != null) {
        _type = 'schedule_line';
      } else {
        _type = 'unallocated';
      }
    } else if (downLeft > 0 && _obligationId != null) {
      _type = 'down_payment';
    } else if (openLine != null) {
      _type = 'schedule_line';
    } else {
      _type = 'unallocated';
    }
  }

  List<Map<String, dynamic>> _scheduleLines(Map<String, dynamic> installment) {
    return (installment['lines'] as List?)?.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() ?? const <Map<String, dynamic>>[];
  }

  double _lineRemainder(Map<String, dynamic> line) {
    for (final key in const ['remainder', 'rest', 'left', 'balance']) {
      if (line[key] != null) return _num(line[key]);
    }
    final planned = _num(line['planned']);
    final paid = _num(line['paid']);
    if (planned <= 0) return 0;
    final left = planned - paid;
    return left < 0 ? 0 : left;
  }

  List<Map<String, dynamic>> _openLines(List<Map<String, dynamic>> lines) {
    final open = lines.where((line) => _lineRemainder(line) > 0 && line['status']?.toString() != 'paid').toList();
    open.sort((a, b) {
      final byDate = (a['due_date']?.toString() ?? '').compareTo(b['due_date']?.toString() ?? '');
      if (byDate != 0) return byDate;
      return _num(a['position']).compareTo(_num(b['position']));
    });
    return open;
  }

  Map<String, dynamic>? _nextOpenLine(List<Map<String, dynamic>> lines) {
    final open = _openLines(lines);
    return open.isEmpty ? null : open.first;
  }

  @override
  void dispose() {
    _amount.dispose();
    _document.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _paidAt = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.replaceAll(' ', '').replaceAll(',', '.')) ?? 0;
    if (amount <= 0) {
      showCustomSnackBar(context: context, message: 'Укажите сумму', isSuccess: false);
      return;
    }
    if (_type == 'down_payment' && _obligationId == null) {
      _type = 'unallocated';
    }
    if (_type == 'schedule_line') {
      final open = _openLines(_scheduleLines(widget.installment));
      final selected = open.where((line) => int.tryParse(line['id']?.toString() ?? '') == _lineId);
      if (selected.isEmpty) {
        _lineId = open.isEmpty ? null : int.tryParse(open.first['id']?.toString() ?? '');
      }
      if (_lineId == null) {
        showCustomSnackBar(context: context, message: 'Нет месяца с остатком', isSuccess: false);
        return;
      }
    }
    setState(() => _busy = true);
    try {
      var paymentId = int.tryParse(widget.existing?['id']?.toString() ?? '');
      var status = widget.existing?['status']?.toString();
      if (paymentId == null) {
        final created = await _api.createInstallmentPayment(
          orderId: widget.orderId,
          filePaths: _files.map((file) => file.path).toList(),
          body: {
            'paid_at': DateFormat('yyyy-MM-dd').format(_paidAt),
            'amount': amount,
            'method': _method,
            if (_document.text.trim().isNotEmpty) 'document_number': _document.text.trim(),
            if (_comment.text.trim().isNotEmpty) 'comment': _comment.text.trim(),
          },
        );
        paymentId = int.tryParse(created['id']?.toString() ?? '');
        status = created['status']?.toString();
      }
      if (status != 'confirmed' && paymentId != null) {
        final posted = widget.existing == null ? amount : _num(widget.existing!['amount']);
        final allocation = <String, dynamic>{'amount': posted, 'type': _type};
        if (_type == 'down_payment' && _obligationId != null) {
          allocation['obligation_id'] = _obligationId;
          allocation['schedule_line_id'] = null;
        } else if (_type == 'schedule_line' && _lineId != null) {
          allocation['schedule_line_id'] = _lineId;
        } else {
          allocation['obligation_id'] = null;
          allocation['schedule_line_id'] = null;
        }
        try {
          await _api.confirmInstallmentPayment(
            orderId: widget.orderId,
            paymentId: paymentId,
            allocations: [allocation],
          );
        } catch (e) {
          debugPrint('Confirm installment payment error: $e');
        }
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(context: context, message: e.toString().replaceFirst('Exception: ', ''), isSuccess: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _choice<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? hint,
  }) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          hint: hint == null ? null : Text(hint, style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w500, color: colors.textSecondary)),
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: colors.fieldBg,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            border: AppFieldStyle.outline(context),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppFieldStyle.radius,
              borderSide: AppFieldStyle.side(context),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppFieldStyle.radius,
              borderSide: AppFieldStyle.side(context, focused: true),
            ),
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.iconSecondary),
          dropdownColor: colors.surfacePrimary,
          style: TextStyle(fontSize: 14, fontFamily: 'Gilroy', fontWeight: FontWeight.w500, color: colors.textPrimary),
        ),
      ],
    );
  }

  Widget _section(dynamic colors, String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 15, color: colors.textPrimary)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Future<void> _pickPaymentFile() async {
    final totalSize = _files.fold<double>(0, (sum, file) {
      final local = File(file.path);
      if (!local.existsSync()) return sum;
      return sum + local.lengthSync() / (1024 * 1024);
    });
    final picked = await FilePickerDialog.show(
      context: context,
      allowMultiple: true,
      maxSizeMB: 50,
      currentTotalSizeMB: totalSize,
      fileLabel: 'Файл',
      galleryLabel: 'Галерея',
      cameraLabel: 'Камера',
      cancelLabel: 'Отмена',
      fileSizeTooLargeMessage: 'Файл слишком большой',
      errorPickingFileMessage: 'Не удалось выбрать файл',
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    setState(() {
      for (final file in picked) {
        _files.add(FileHelper(id: 0, name: file.name, path: file.path, size: file.sizeKB));
      }
    });
  }

  Widget _paymentFiles(dynamic colors) {
    final addIcon = ThemeData.estimateBrightnessForColor(colors.fieldBg) == Brightness.dark
        ? 'assets/icons/files/add_for_dark.png'
        : 'assets/icons/files/add.png';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Подтверждающий документ', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
        const SizedBox(height: 8),
        SizedBox(
          height: 112,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _files.length + 1,
            itemBuilder: (context, index) {
              if (index == _files.length) {
                return GestureDetector(
                  onTap: _busy ? null : _pickPaymentFile,
                  child: Container(
                    width: 96,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.fieldBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(addIcon, width: 42, height: 42),
                        const SizedBox(height: 6),
                        Text('Добавить файл', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Gilroy', fontSize: 11, color: colors.textPrimary)),
                      ],
                    ),
                  ),
                );
              }
              final file = _files[index];
              final extension = file.name.split('.').last.toLowerCase();
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Stack(
                  children: [
                    Container(
                      width: 96,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.fieldBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(child: buildFileIcon(_files, file.name, extension)),
                          const SizedBox(height: 4),
                          Text(file.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Gilroy', fontSize: 11, color: colors.textPrimary)),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: _busy ? null : () => setState(() => _files.removeAt(index)),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(color: colors.surfacePrimary, shape: BoxShape.circle),
                          child: Icon(Icons.close, size: 14, color: colors.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _dealNumberLabel() {
    final raw = widget.dealNumber?.trim() ?? '';
    if (raw.isEmpty || raw == 'null') {
      return widget.orderId > 0 ? '№${widget.orderId}' : '—';
    }
    return raw.startsWith('№') ? raw : '№$raw';
  }

  Widget _readonly(dynamic colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: colors.fieldBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Text(value, style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, fontSize: 14, color: colors.textPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final openLines = _openLines(_scheduleLines(widget.installment));
    return Scaffold(
      backgroundColor: colors.surfacePrimary,
      appBar: AppBar(
        backgroundColor: colors.surfacePrimary,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Информация о платеже', style: TextStyle(fontFamily: 'Gilroy', fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            Text('Заполните информацию о новом платеже', style: TextStyle(fontFamily: 'Gilroy', fontSize: 12, fontWeight: FontWeight.w500, color: colors.textSecondary)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
              _section(
                colors,
                'Сделка',
                [
                  _readonly(colors, 'Покупатель', _label(widget.buyer, '—')),
                  _readonly(colors, 'Объект', _label(widget.objectName, '—')),
                  _readonly(colors, 'Договор', _dealNumberLabel()),
                  _readonly(colors, 'Остаток долга', _money(widget.installment['debt'])),
                ],
              ),
              const SizedBox(height: 10),
              _section(
                colors,
                'Поступление',
                [
                  Text('Дата поступления *', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: colors.fieldBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: Text(DateFormat('dd.MM.yyyy').format(_paidAt), style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, color: colors.textPrimary)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(controller: _amount, label: 'Сумма *', hintText: 'Введите сумму', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 10),
                  _choice<String>(
                    label: 'Способ оплаты *',
                    value: _method,
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Наличные')),
                      DropdownMenuItem(value: 'transfer', child: Text('Банковский перевод')),
                      DropdownMenuItem(value: 'terminal', child: Text('Терминал')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _method = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(controller: _document, label: 'Номер квитанции или поручения', hintText: 'Введите номер документа'),
                  const SizedBox(height: 10),
                  _paymentFiles(colors),
                  const SizedBox(height: 10),
                  CustomTextField(controller: _comment, label: 'Комментарий', hintText: 'Комментарий'),
                ],
              ),
              const SizedBox(height: 10),
              _section(
                colors,
                'Распределение платежа',
                [
                  _choice<String>(
                    label: 'К чему относится *',
                    value: _type,
                    items: () {
                      final hasDown = _obligationId != null;
                      final hasSchedule = openLines.isNotEmpty;
                      return [
                        if (hasDown)
                          const DropdownMenuItem(value: 'down_payment', child: Text('Первоначальный взнос')),
                        if (hasSchedule)
                          const DropdownMenuItem(value: 'schedule_line', child: Text('Платёж по графику')),
                        if (hasSchedule)
                          const DropdownMenuItem(value: 'early_repayment', child: Text('Досрочное погашение')),
                        const DropdownMenuItem(value: 'unallocated', child: Text('Платёж по сделке')),
                      ];
                    }(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _type = value;
                        if (value == 'schedule_line' && openLines.isNotEmpty) {
                          final ids = openLines.map((line) => int.tryParse(line['id']?.toString() ?? '')).toSet();
                          if (!ids.contains(_lineId)) {
                            _lineId = int.tryParse(openLines.first['id']?.toString() ?? '');
                          }
                        }
                      });
                    },
                  ),
                  if (_type == 'schedule_line') ...[
                    const SizedBox(height: 10),
                    if (openLines.isEmpty)
                      _readonly(colors, 'Месяц', 'Нет месяцев с остатком')
                    else
                      _choice<int>(
                        label: 'Месяц',
                        value: () {
                          final ids = openLines.map((line) => int.tryParse(line['id']?.toString() ?? '')).whereType<int>().toList();
                          if (_lineId != null && ids.contains(_lineId)) return _lineId;
                          return ids.isEmpty ? null : ids.first;
                        }(),
                        items: openLines.map((line) {
                          final id = int.tryParse(line['id']?.toString() ?? '') ?? 0;
                          return DropdownMenuItem(
                            value: id,
                            child: Text(
                              '№${line['position']} · ${_date(line['due_date'])} · остаток ${_money(_lineRemainder(line))}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _lineId = value),
                      ),
                  ],
                ],
              ),
            ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _busy ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.buttonPrimaryBg,
                foregroundColor: colors.buttonPrimaryFg,
                disabledBackgroundColor: colors.buttonPrimaryBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _busy
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colors.buttonPrimaryFg))
                  : const Text('Сохранить платёж', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(label, style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 11, color: color)),
    );
  }
}

String _buyerName(Map item) => _label(item['buyer'], '—');

// ignore: unused_element
String _dealCaption(Map item) {
  final number = '№${item['order_number'] ?? item['order_id'] ?? '—'}';
  final object = _label(item['object'], '');
  if (object.isEmpty) return 'Сделка $number';
  return '$number · $object';
}

String _label(dynamic value, String fallback) {
  if (value is Map) {
    for (final key in ['name', 'title', 'label', 'number', 'address']) {
      final text = value[key]?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    final parts = value.values.where((item) => item is String || item is num).map((item) => item.toString().trim()).where((item) => item.isNotEmpty);
    final joined = parts.join(', ');
    return joined.isEmpty ? fallback : joined;
  }
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty || text == 'null') return fallback;
  return text;
}

int? _overdueDays(Map item) {
  if (_num(item['overdue_amount']) <= 0) return null;
  final explicit = int.tryParse(
    item['oldest_overdue_days']?.toString() ?? item['overdue_days']?.toString() ?? '',
  );
  if (explicit != null && explicit > 0) return explicit;
  final next = item['next_payment'];
  final raw = next is Map ? next['date']?.toString() : item['overdue_since']?.toString();
  final due = DateTime.tryParse(raw ?? '');
  if (due == null) return null;
  final start = DateTime(due.year, due.month, due.day);
  final today = DateTime.now();
  final days = DateTime(today.year, today.month, today.day).difference(start).inDays;
  return days < 0 ? 0 : days;
}

double _num(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().replaceAll(' ', '').replaceAll(',', '.') ?? '') ?? 0;
}

String _plain(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}

String _money(dynamic value) {
  final text = _plain(_num(value));
  return text.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ' ');
}

String _date(dynamic value) {
  final raw = value?.toString() ?? '';
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw.isEmpty ? '—' : raw;
  return DateFormat('dd.MM.yyyy').format(parsed);
}

String _dealStatus(String? value) {
  switch (value) {
    case 'not_started':
      return 'Не начато';
    case 'on_schedule':
      return 'По графику';
    case 'partial':
      return 'Частично';
    case 'overdue':
      return 'Просрочка';
    case 'paid':
      return 'Оплачено';
    case 'cash':
      return 'Наличные';
    default:
      return value?.isNotEmpty == true ? value! : 'Оплачено';
  }
}

Map<String, dynamic> _buildFallbackInstallment({
  required int orderId,
  Order? order,
  Map<String, dynamic>? item,
}) {
  final raw = order?.rawJson ?? const <String, dynamic>{};
  final total = order?.sum != null
      ? _num(order!.sum)
      : _num(item?['total_amount'] ?? item?['received'] ?? item?['price'] ?? item?['sum']);
  final received = _num(raw['received'] ?? raw['paid'] ?? item?['received']);
  final debt = _num(raw['debt'] ?? raw['remainder'] ?? item?['debt'] ?? (total > received ? total - received : 0));
  final dealType = raw['deal_type'] ?? item?['deal_type'] ?? 'cash';
  return <String, dynamic>{
    'order_id': orderId,
    'total_amount': total,
    'schedule_amount': 0,
    'barter_amount': _num(raw['barter_amount'] ?? item?['barter_amount']),
    'received': received,
    'debt': debt,
    'overdue_amount': _num(raw['overdue_amount'] ?? item?['overdue_amount']),
    'settlement_status': raw['settlement_status'] ?? item?['settlement_status'] ?? (debt <= 0 && (received > 0 || total > 0) ? 'paid' : 'cash'),
    'deal_type': dealType,
    'lines': <Map<String, dynamic>>[],
    'payments': (raw['payments'] as List?)?.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() ?? <Map<String, dynamic>>[],
    'down_payment': <String, dynamic>{
      'planned': total,
      'paid': received,
      'remainder': debt,
      'status': debt <= 0 ? 'paid' : 'open',
    },
  };
}

String _lineStatus(String? value) {
  switch (value) {
    case 'waiting':
      return 'Ожидает';
    case 'partial':
      return 'Частично';
    case 'paid':
      return 'Оплачен';
    case 'overdue':
      return 'Просрочен';
    case 'overpaid':
      return 'Переплата';
    default:
      return '—';
  }
}

String _payStatus(String? value) {
  switch (value) {
    case 'draft':
      return 'Ждёт подтверждения';
    case 'confirmed':
      return 'Подтверждён';
    case 'reversed':
      return 'Отменён';
    default:
      return '—';
  }
}

String _method(String? value) {
  switch (value) {
    case 'cash':
      return 'Наличные';
    case 'transfer':
      return 'Банковский перевод';
    case 'terminal':
      return 'Терминал';
    default:
      return value?.isNotEmpty == true ? value! : '—';
  }
}

Color _statusColor(String? status, dynamic colors) {
  switch (status) {
    case 'overdue':
      return colors.error;
    case 'paid':
      return colors.success;
    case 'partial':
    case 'on_schedule':
      return colors.buttonPrimaryBg;
    default:
      return colors.textSecondary;
  }
}

class _PaymentNotice {
  final String date;
  final String channel;
  final String text;
  final bool isOverdue;

  const _PaymentNotice({
    required this.date,
    required this.channel,
    required this.text,
    this.isOverdue = false,
  });
}
