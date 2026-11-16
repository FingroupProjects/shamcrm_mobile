import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_field_style.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
      final item = await _CreatePaymentPicker.show(context: context, items: _items);
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
      } catch (e) {
        error = e;
      }
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (error != null) {
        showCustomSnackBar(context: context, message: error.toString().replaceFirst('Exception: ', ''), isSuccess: false);
        return;
      }
      if (data == null) {
        showCustomSnackBar(context: context, message: 'У сделки нет графика платежей', isSuccess: false);
        return;
      }
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AddPaymentSheet(orderId: orderId, installment: data!),
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
  final List<Map<String, dynamic>> biggest;
  final List<Map<String, dynamic>> longest;
  final ValueChanged<Map<String, dynamic>> onOpen;
  final VoidCallback onCreate;

  const _PaymentsOverview({
    required this.totalDebt,
    required this.totalOverdue,
    required this.overdueBuyers,
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
                _metric(colors, 'Общий долг', _money(totalDebt), colors.textPrimary),
                const SizedBox(height: 10),
                _metric(colors, 'Просрочено', _money(totalOverdue), totalOverdue > 0 ? colors.error : colors.textPrimary),
                const SizedBox(height: 10),
                _metric(colors, 'С просрочкой', '$overdueBuyers', colors.textPrimary),
              ],
            ),
          ),
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _sectionTitle(colors, 'Сделки')),
              const SizedBox(width: 8),
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

  Widget _metric(dynamic colors, String label, String value, Color valueColor) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(fontFamily: 'Gilroy', fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary)),
        ),
        Text(value, style: TextStyle(fontFamily: 'Gilroy', fontSize: 16, fontWeight: FontWeight.w700, color: valueColor)),
      ],
    );
  }

  Widget _sectionTitle(dynamic colors, String text) {
    return Text(text, style: TextStyle(fontFamily: 'Gilroy', fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary));
  }

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
  bool _changed = false;
  bool _history = false;
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
      final data = await _api.getOrderInstallment(_orderId);
      if (!mounted) return;
      setState(() {
        _data = data;
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

  Future<void> _add({bool early = false}) async {
    final data = _data;
    if (data == null) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPaymentSheet(orderId: _orderId, installment: data, early: early),
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
                              _notices(colors, lines),
                              const SizedBox(height: 12),
                              _actions(colors, data, down, lines),
                              if (payments.where((payment) => payment['status']?.toString() == 'draft').isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Ждут подтверждения: ${payments.where((payment) => payment['status']?.toString() == 'draft').length}. До подтверждения они не входят в оплаченное.',
                                  style: TextStyle(fontFamily: 'Gilroy', fontSize: 12, height: 1.3, color: colors.textSecondary),
                                ),
                              ],
                              const SizedBox(height: 14),
                              _tabs(colors),
                              const SizedBox(height: 10),
                              if (!_history)
                                _schedule(colors, data, down, lines, payments)
                              else
                                _historyList(colors, payments),
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
    final cards = [
      _metric(colors, 'Стоимость сделки', _money(total), 'Сумма сделки'),
      _metric(colors, 'Первоначальный взнос', _money(down['planned']), 'получено ${_money(down['paid'])}, ${_lineStatus(down['status']?.toString()).toLowerCase()}'),
      _metric(colors, 'Бартер', barter > 0 ? _money(barter) : '—', barter > 0 ? _label(data['barter_note'], 'учтён в сумме') : 'не применяется'),
      _metric(colors, 'К оплате деньгами', _money(cash), 'в графике рассрочки: ${_money(data['schedule_amount'] ?? widget.item['schedule_amount'])}'),
      _metric(colors, 'Оплачено', _money(data['received'] ?? widget.item['received']), 'возвраты: ${_money(refunds)}'),
      _metric(colors, 'Остаток долга', _money(data['debt'] ?? widget.item['debt']), _dealStatus(data['settlement_status']?.toString() ?? widget.item['settlement_status']?.toString())),
      _metric(colors, 'Просрочено', _money(data['overdue_amount'] ?? widget.item['overdue_amount']), _num(data['overdue_amount'] ?? widget.item['overdue_amount']) > 0 ? 'есть просрочка' : 'просрочек нет', danger: _num(data['overdue_amount'] ?? widget.item['overdue_amount']) > 0),
      _metric(colors, 'Ближайший платёж', next == null ? '—' : _money(next['amount']), next == null ? 'нет' : 'на ${_date(next['date'])}'),
      _metric(colors, 'Пени к оплате', _money(penalty), penalty > 0 ? 'начислено' : 'начислений нет'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.55,
      children: cards,
    );
  }

  Widget _metric(dynamic colors, String label, String value, String caption, {bool danger = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceElevated.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Gilroy', fontSize: 11, fontWeight: FontWeight.w600, color: colors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Gilroy', fontSize: 16, fontWeight: FontWeight.w800, color: danger ? colors.error : colors.textPrimary)),
          const Spacer(),
          Text(caption, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Gilroy', fontSize: 10.5, height: 1.2, color: colors.textSecondary)),
        ],
      ),
    );
  }

  Widget _notices(dynamic colors, List<Map<String, dynamic>> lines) {
    final notes = <String>[];
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    for (final line in lines) {
      if (_num(line['remainder']) <= 0) continue;
      final due = DateTime.tryParse(line['due_date']?.toString() ?? '');
      final overdueDays = int.tryParse(line['overdue_days']?.toString() ?? '') ?? 0;
      final late = line['status']?.toString() == 'overdue' || overdueDays > 0;
      if (late) {
        notes.add('Просрочен платёж №${line['position'] ?? ''} от ${_date(line['due_date'])}: ${_money(line['remainder'])}, дней: ${overdueDays > 0 ? overdueDays : (due == null ? 0 : start.difference(DateTime(due.year, due.month, due.day)).inDays)}');
      } else if (due != null) {
        final left = DateTime(due.year, due.month, due.day).difference(start).inDays;
        if (left >= 0 && left <= 3) {
          notes.add('Скоро платёж №${line['position'] ?? ''} на ${_date(line['due_date'])}: ${_money(line['remainder'])}');
        }
      }
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
          const SizedBox(height: 6),
          if (notes.isEmpty)
            Text('Уведомлений пока нет', style: TextStyle(fontFamily: 'Gilroy', fontSize: 12.5, color: colors.textSecondary))
          else
            ...notes.map((note) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(note, style: TextStyle(fontFamily: 'Gilroy', fontSize: 12.5, height: 1.3, color: colors.textPrimary)),
                )),
        ],
      ),
    );
  }

  Widget _actions(dynamic colors, Map<String, dynamic> data, Map<String, dynamic> down, List<Map<String, dynamic>> lines) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _actionButton(colors, 'Добавить платёж', filled: true, onTap: () => _add()),
        _actionButton(colors, 'Досрочное погашение', onTap: () => _add(early: true)),
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

  Widget _tabs(dynamic colors) {
    return Row(
      children: [
        _tabChip(colors, 'График', !_history, () => setState(() => _history = false)),
        const SizedBox(width: 8),
        _tabChip(colors, 'История операций', _history, () => setState(() => _history = true)),
      ],
    );
  }

  Widget _tabChip(dynamic colors, String label, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? colors.buttonPrimaryBg : colors.surfaceElevated.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(label, style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 13, color: selected ? colors.buttonPrimaryFg : colors.textPrimary)),
        ),
      ),
    );
  }

  Widget _schedule(dynamic colors, Map<String, dynamic> data, Map<String, dynamic> down, List<Map<String, dynamic>> lines, List<Map<String, dynamic>> payments) {
    final version = data['version']?.toString();
    final rows = <List<String>>[
      ['Взнос', '—', _money(down['planned']), _money(down['paid']), _money(down['remainder']), '—', _lineStatus(down['status']?.toString()), _money(_firstNum(down, const ['penalty', 'penalty_amount']))],
      ...lines.map((line) => [
            '${line['position'] ?? ''}',
            _date(line['due_date']),
            _money(line['planned']),
            _money(line['paid']),
            _money(line['remainder']),
            _lastPayment(payments, line['id']),
            _lineStatus(line['status']?.toString()),
            _money(_firstNum(line, const ['penalty', 'penalty_amount'])),
          ]),
    ];
    const headers = ['№', 'Дата', 'По графику', 'Оплачено', 'Остаток', 'Последняя оплата', 'Статус', 'Пени'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (version != null && version.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('График версии $version', style: TextStyle(fontFamily: 'Gilroy', fontSize: 12, color: colors.textSecondary)),
          ),
        SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 36,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 48,
        headingTextStyle: TextStyle(fontFamily: 'Gilroy', fontSize: 11, fontWeight: FontWeight.w700, color: colors.textSecondary),
        dataTextStyle: TextStyle(fontFamily: 'Gilroy', fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimary),
        columns: headers.map((title) => DataColumn(label: Text(title))).toList(),
        rows: rows.map((row) => DataRow(cells: row.map((cell) => DataCell(Text(cell))).toList())).toList(),
      ),
        ),
      ],
    );
  }

  Widget _historyList(dynamic colors, List<Map<String, dynamic>> payments) {
    if (payments.isEmpty) {
      return Text('Операций пока нет', style: TextStyle(fontFamily: 'Gilroy', fontSize: 13, color: colors.textSecondary));
    }
    final sorted = [...payments]..sort((a, b) => (b['paid_at']?.toString() ?? '').compareTo(a['paid_at']?.toString() ?? ''));
    return Column(
      children: sorted.map((payment) {
        final refund = payment['source_payment_id'] != null;
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
                  Expanded(child: Text(refund ? 'Возврат' : 'Платёж', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 14, color: colors.textPrimary))),
                  Text('${refund ? '−' : ''}${_money(payment['amount'])}', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w800, fontSize: 15, color: colors.textPrimary)),
                ],
              ),
              const SizedBox(height: 4),
              Text('${_date(payment['paid_at'])} · ${_method(payment['method']?.toString())} · ${_payStatus(payment['status']?.toString())}', style: TextStyle(fontFamily: 'Gilroy', fontSize: 12, color: colors.textSecondary)),
              Text('Документ: ${_label(payment['document_number'], '—')}', style: TextStyle(fontFamily: 'Gilroy', fontSize: 12, color: colors.textSecondary)),
              Text(_allocationText(payment), style: TextStyle(fontFamily: 'Gilroy', fontSize: 12, color: colors.textSecondary)),
              if (_label(payment['reversal_reason'], '').isNotEmpty)
                Text('Причина отмены: ${payment['reversal_reason']}', style: TextStyle(fontFamily: 'Gilroy', fontSize: 12, color: colors.textSecondary)),
              if (payment['status']?.toString() != 'reversed') ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (payment['status']?.toString() == 'draft')
                      _historyAction(colors, 'Подтвердить', () => _confirm(payment)),
                    if (payment['status']?.toString() == 'confirmed' && !refund)
                      _historyAction(colors, 'Вернуть', () => _refund(payment)),
                    _historyAction(colors, 'Отменить', () => _reverse(payment)),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
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
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPaymentSheet(orderId: _orderId, installment: data, existing: payment),
    );
    if (saved == true) {
      _changed = true;
      _load();
    }
  }

  Future<void> _reverse(Map<String, dynamic> payment) async {
    final id = int.tryParse(payment['id']?.toString() ?? '');
    if (id == null) return;
    final reason = await _askText(title: 'Отмена операции', label: 'Причина', action: 'Отменить');
    if (reason == null || reason.isEmpty) return;
    try {
      await _api.reverseInstallmentPayment(orderId: _orderId, paymentId: id, reason: reason);
      _changed = true;
      _load();
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(context: context, message: e.toString().replaceFirst('Exception: ', ''), isSuccess: false);
    }
  }

  Future<void> _refund(Map<String, dynamic> payment) async {
    final id = int.tryParse(payment['id']?.toString() ?? '');
    if (id == null) return;
    final values = await _askRefund(maxAmount: _num(payment['amount']));
    if (values == null) return;
    try {
      await _api.refundInstallmentPayment(orderId: _orderId, paymentId: id, amount: values.$1, reason: values.$2);
      _changed = true;
      _load();
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(context: context, message: e.toString().replaceFirst('Exception: ', ''), isSuccess: false);
    }
  }

  Future<String?> _askText({required String title, required String label, required String action}) {
    final controller = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colors = context.appColors;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            decoration: BoxDecoration(color: colors.surfacePrimary, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: 'Gilroy', fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                const SizedBox(height: 12),
                CustomTextField(controller: controller, label: label, hintText: 'Укажите причину'),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, controller.text.trim()),
                    style: ElevatedButton.styleFrom(backgroundColor: colors.buttonPrimaryBg, foregroundColor: colors.buttonPrimaryFg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: Text(action, style: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<(double, String)?> _askRefund({required double maxAmount}) {
    final amount = TextEditingController(text: _plain(maxAmount));
    final reason = TextEditingController();
    return showModalBottomSheet<(double, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colors = context.appColors;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            decoration: BoxDecoration(color: colors.surfacePrimary, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Возврат средств', style: TextStyle(fontFamily: 'Gilroy', fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                const SizedBox(height: 6),
                Text('Не больше ${_money(maxAmount)}', style: TextStyle(fontFamily: 'Gilroy', fontSize: 12, color: colors.textSecondary)),
                const SizedBox(height: 12),
                CustomTextField(controller: amount, label: 'Сумма', hintText: '0', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 10),
                CustomTextField(controller: reason, label: 'Основание', hintText: 'Почему возвращаем'),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final value = double.tryParse(amount.text.replaceAll(' ', '').replaceAll(',', '.')) ?? 0;
                      if (value <= 0 || value > maxAmount + 0.001 || reason.text.trim().isEmpty) return;
                      Navigator.pop(context, (value, reason.text.trim()));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: colors.buttonPrimaryBg, foregroundColor: colors.buttonPrimaryFg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('Оформить возврат', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  String _lastPayment(List<Map<String, dynamic>> payments, dynamic lineId) {
    DateTime? best;
    var amount = 0.0;
    for (final payment in payments) {
      if (payment['status']?.toString() == 'reversed') continue;
      final allocs = payment['allocations'];
      if (allocs is! List) continue;
      for (final raw in allocs) {
        if (raw is! Map) continue;
        if (raw['schedule_line_id']?.toString() != lineId?.toString()) continue;
        final date = DateTime.tryParse(payment['paid_at']?.toString() ?? '');
        if (date != null && (best == null || date.isAfter(best))) {
          best = date;
          amount = _num(raw['amount']);
        }
      }
    }
    if (best == null) return '—';
    return '${_date(best)} · ${_money(amount)}';
  }

  String _allocationText(Map payment) {
    if (payment['source_payment_id'] != null) {
      return 'Возврат по платежу №${payment['source_payment_id']}';
    }
    final allocs = payment['allocations'];
    if (allocs is! List || allocs.isEmpty) return 'Распределение: ещё не подтверждён';
    final parts = <String>[];
    for (final raw in allocs) {
      if (raw is! Map) continue;
      final type = raw['type']?.toString();
      final amount = _money(raw['amount']);
      if (type == 'down_payment') {
        parts.add('Взнос $amount');
      } else if (type == 'early_repayment') {
        parts.add('Досрочно $amount');
      } else if (raw['schedule_line_id'] != null) {
        parts.add('Строка ${raw['schedule_line_id']} $amount');
      } else {
        parts.add(amount);
      }
    }
    return parts.isEmpty ? 'Распределение: —' : parts.join(', ');
  }
}

class _CreatePaymentPicker extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const _CreatePaymentPicker({required this.items});

  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    required List<Map<String, dynamic>> items,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePaymentPicker(items: items),
    );
  }

  @override
  State<_CreatePaymentPicker> createState() => _CreatePaymentPickerState();
}

class _PaymentClient {
  final int key;
  final String name;
  final List<Map<String, dynamic>> deals;

  const _PaymentClient({required this.key, required this.name, required this.deals});
}

class _CreatePaymentPickerState extends State<_CreatePaymentPicker> {
  late final List<_PaymentClient> _clients;
  _PaymentClient? _client;
  Map<String, dynamic>? _deal;
  bool _clientsOpen = false;
  bool _dealsOpen = false;

  @override
  void initState() {
    super.initState();
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final item in widget.items) {
      final leadId = int.tryParse(item['lead_id']?.toString() ?? '');
      final orderId = int.tryParse(item['order_id']?.toString() ?? '') ?? 0;
      final key = leadId != null && leadId > 0 ? leadId : -orderId;
      grouped.putIfAbsent(key, () => []).add(item);
    }
    _clients = grouped.entries.map((entry) {
      final named = entry.value
          .map((item) => _label(item['buyer'], ''))
          .firstWhere((name) => name.isNotEmpty, orElse: () => '');
      return _PaymentClient(key: entry.key, name: named.isEmpty ? '—' : named, deals: entry.value);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

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
                _fieldLabel(colors, 'Клиент'),
                const SizedBox(height: 6),
                _selector(
                  colors,
                  text: _client?.name ?? 'Выберите клиента',
                  placeholder: _client == null,
                  open: _clientsOpen,
                  onTap: () => setState(() {
                    _clientsOpen = !_clientsOpen;
                    _dealsOpen = false;
                  }),
                ),
                if (_clientsOpen) ...[
                  const SizedBox(height: 8),
                  ..._clients.map((client) => _option(
                        colors,
                        title: client.name,
                        subtitle: _dealsCount(client.deals.length),
                        selected: _client?.key == client.key,
                        onTap: () => setState(() {
                          _client = client;
                          _deal = client.deals.length == 1 ? client.deals.first : null;
                          _clientsOpen = false;
                          _dealsOpen = client.deals.length != 1;
                        }),
                      )),
                ],
                const SizedBox(height: 14),
                _fieldLabel(colors, 'Сделка'),
                const SizedBox(height: 6),
                _selector(
                  colors,
                  text: _deal == null ? (_client == null ? 'Сначала выберите клиента' : 'Выберите сделку') : _dealCaption(_deal!),
                  placeholder: _deal == null,
                  enabled: _client != null,
                  open: _dealsOpen,
                  onTap: _client == null
                      ? null
                      : () => setState(() {
                            _dealsOpen = !_dealsOpen;
                            _clientsOpen = false;
                          }),
                ),
                if (_dealsOpen && _client != null) ...[
                  const SizedBox(height: 8),
                  ..._client!.deals.map((deal) => _option(
                        colors,
                        title: _dealCaption(deal),
                        subtitle: 'Долг ${_money(deal['debt'])}',
                        selected: _deal?['order_id'] == deal['order_id'],
                        onTap: () => setState(() {
                          _deal = deal;
                          _dealsOpen = false;
                        }),
                      )),
                ],
                const SizedBox(height: 8),
                Text(
                  'Показаны сделки выбранного клиента.',
                  style: TextStyle(fontFamily: 'Gilroy', fontSize: 12, fontWeight: FontWeight.w500, color: colors.textSecondary),
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
                    onPressed: _deal == null ? null : () => Navigator.pop(context, _deal),
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

  String _dealsCount(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) return '$count сделка';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return '$count сделки';
    return '$count сделок';
  }

  Widget _fieldLabel(dynamic colors, String text) {
    return Text(text, style: TextStyle(fontFamily: 'Gilroy', fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary));
  }

  Widget _selector(
    dynamic colors, {
    required String text,
    required bool placeholder,
    required bool open,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    return Material(
      color: colors.surfaceElevated.withValues(alpha: enabled ? 0.55 : 0.28),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.8)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: placeholder ? colors.textSecondary : colors.textPrimary,
                  ),
                ),
              ),
              Icon(open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: colors.iconSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option(
    dynamic colors, {
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? colors.buttonPrimaryBg.withValues(alpha: 0.12) : colors.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? colors.buttonPrimaryBg : colors.borderSubtle.withValues(alpha: 0.7)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, fontSize: 13.5, color: colors.textPrimary)),
                      Text(subtitle, style: TextStyle(fontFamily: 'Gilroy', fontSize: 11.5, color: colors.textSecondary)),
                    ],
                  ),
                ),
                if (selected) Icon(Icons.check_rounded, size: 18, color: colors.buttonPrimaryBg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddPaymentSheet extends StatefulWidget {
  final int orderId;
  final Map<String, dynamic> installment;
  final bool early;
  final Map<String, dynamic>? existing;

  const _AddPaymentSheet({
    required this.orderId,
    required this.installment,
    this.early = false,
    this.existing,
  });

  @override
  State<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<_AddPaymentSheet> {
  final ApiService _api = ApiService();
  final _amount = TextEditingController();
  final _document = TextEditingController();
  final _comment = TextEditingController();
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
    final lines = (widget.installment['lines'] as List?)?.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() ?? const <Map<String, dynamic>>[];
    Map<String, dynamic>? openLine;
    for (final line in lines) {
      if (_num(line['remainder']) > 0 && line['status']?.toString() != 'paid') {
        openLine = line;
        break;
      }
    }
    final existing = widget.existing;
    if (existing != null) {
      _amount.text = _plain(_num(existing['amount']));
      _document.text = existing['document_number']?.toString() ?? '';
      _comment.text = existing['comment']?.toString() ?? '';
      final method = existing['method']?.toString();
      if (method == 'cash' || method == 'transfer' || method == 'terminal') _method = method!;
      _paidAt = DateTime.tryParse(existing['paid_at']?.toString() ?? '') ?? DateTime.now();
      if (downLeft > 0) {
        _type = 'down_payment';
      } else if (openLine != null) {
        _type = 'schedule_line';
        _lineId = int.tryParse(openLine['id']?.toString() ?? '');
      }
    } else if (widget.early) {
      _type = 'early_repayment';
      _amount.text = _plain(_num(widget.installment['debt']));
      _paidAt = DateTime.now();
    } else if (downLeft > 0) {
      _type = 'down_payment';
      _amount.text = _plain(downLeft);
    } else if (openLine != null) {
      _type = 'schedule_line';
      _lineId = int.tryParse(openLine['id']?.toString() ?? '');
      _amount.text = _plain(_num(openLine['remainder']));
      final due = DateTime.tryParse(openLine['due_date']?.toString() ?? '');
      if (due != null) _paidAt = due;
    } else if (lines.isNotEmpty) {
      _lineId = int.tryParse(lines.first['id']?.toString() ?? '');
    }
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
      showCustomSnackBar(context: context, message: 'Не найден взнос для зачисления', isSuccess: false);
      return;
    }
    if (_type == 'schedule_line' && _lineId == null) {
      showCustomSnackBar(context: context, message: 'Выберите месяц графика', isSuccess: false);
      return;
    }
    setState(() => _busy = true);
    try {
      var paymentId = int.tryParse(widget.existing?['id']?.toString() ?? '');
      var status = widget.existing?['status']?.toString();
      if (paymentId == null) {
        final created = await _api.createInstallmentPayment(
          orderId: widget.orderId,
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
        if (_type == 'down_payment') {
          allocation['obligation_id'] = _obligationId;
          allocation['schedule_line_id'] = null;
        } else if (_type == 'schedule_line') {
          allocation['schedule_line_id'] = _lineId;
        }
        await _api.confirmInstallmentPayment(
          orderId: widget.orderId,
          paymentId: paymentId,
          allocations: [allocation],
        );
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
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final lines = (widget.installment['lines'] as List?)?.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() ?? const <Map<String, dynamic>>[];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: colors.borderSubtle, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(
                widget.existing != null ? 'Подтвердить платёж' : widget.early ? 'Досрочное погашение' : 'Добавить платёж',
                style: TextStyle(fontFamily: 'Gilroy', fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary),
              ),
              const SizedBox(height: 12),
              CustomTextField(controller: _amount, label: 'Сумма', hintText: '0', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 10),
              Text('Дата оплаты', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
              const SizedBox(height: 6),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Text(DateFormat('dd.MM.yyyy').format(_paidAt), style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, color: colors.textPrimary)),
                ),
              ),
              const SizedBox(height: 10),
              _choice<String>(
                label: 'Способ оплаты',
                value: _method,
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Наличные')),
                  DropdownMenuItem(value: 'transfer', child: Text('Перевод')),
                  DropdownMenuItem(value: 'terminal', child: Text('Терминал')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _method = value);
                },
              ),
              const SizedBox(height: 10),
              CustomTextField(controller: _document, label: 'Номер документа', hintText: 'КВ-1'),
              const SizedBox(height: 10),
              _choice<String>(
                label: 'Это платёж за',
                value: _type,
                items: const [
                  DropdownMenuItem(value: 'down_payment', child: Text('Первый взнос')),
                  DropdownMenuItem(value: 'schedule_line', child: Text('Месяц из графика')),
                  DropdownMenuItem(value: 'early_repayment', child: Text('Досрочное погашение')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
              if (_type == 'schedule_line' && lines.isNotEmpty) ...[
                const SizedBox(height: 10),
                _choice<int>(
                  label: 'Какой месяц',
                  value: _lineId ?? (int.tryParse(lines.first['id']?.toString() ?? '') ?? 0),
                  items: lines.map((line) {
                    final id = int.tryParse(line['id']?.toString() ?? '') ?? 0;
                    return DropdownMenuItem(
                      value: id,
                      child: Text(
                        'Месяц ${line['position']} · ${_date(line['due_date'])} · осталось ${_money(line['remainder'])}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _lineId = value),
                ),
              ],
              const SizedBox(height: 10),
              CustomTextField(controller: _comment, label: 'Комментарий', hintText: 'Необязательно'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
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
                      : const Text('Сохранить', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700)),
                ),
              ),
            ],
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
    default:
      return 'Рассрочка';
  }
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
      return 'Черновик';
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
      return 'Перевод';
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
