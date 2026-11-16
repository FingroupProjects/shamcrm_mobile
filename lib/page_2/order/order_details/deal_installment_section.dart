import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart' as cm;
import 'package:crm_task_manager/screens/chess_grid/widgets/payment_schedule_sheet.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DealInstallmentSection extends StatefulWidget {
  final int orderId;
  final String buyerName;
  final String buyerPhone;
  final String currency;

  const DealInstallmentSection({
    super.key,
    required this.orderId,
    required this.buyerName,
    required this.buyerPhone,
    required this.currency,
  });

  @override
  State<DealInstallmentSection> createState() => _DealInstallmentSectionState();
}

class _DealInstallmentSectionState extends State<DealInstallmentSection> {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

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
      final data = await _api.getOrderInstallment(widget.orderId);
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

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _money(dynamic value) {
    final amount = _num(value).toStringAsFixed(2);
    final currency = widget.currency.trim();
    if (currency.isEmpty) return amount;
    return '$amount $currency';
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
        return 'Есть просрочка';
      case 'paid':
        return 'Оплачено';
      default:
        return value ?? '—';
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
        return value ?? '—';
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
        return value ?? '—';
    }
  }

  void _openTemplate() {
    final data = _data;
    if (data == null) return;
    final lines = (data['lines'] as List?) ?? const [];
    final rows = <cm.InstallmentScheduleRow>[];
    var remaining = _num(data['schedule_amount']);
    for (final raw in lines.whereType<Map>()) {
      final planned = _num(raw['planned']);
      remaining = (remaining - planned).clamp(0, double.infinity);
      rows.add(cm.InstallmentScheduleRow(
        number: int.tryParse(raw['position']?.toString() ?? '') ?? rows.length + 1,
        date: DateTime.tryParse(raw['due_date']?.toString() ?? '') ?? DateTime.now(),
        paymentAmount: planned,
        remainingDebt: remaining,
      ));
    }
    final down = data['down_payment'] is Map ? data['down_payment'] as Map : const {};
    PaymentScheduleSheet.show(
      context: context,
      order: cm.Order(
        id: widget.orderId.toString(),
        complexId: 1,
        buyerName: widget.buyerName,
        buyerPhone: widget.buyerPhone,
        buyerEmail: '',
        manager: '',
        dealType: _num(data['barter_amount']) > 0 ? cm.DealType.mixed : cm.DealType.installment,
        price: _num(data['total_amount']),
        status: cm.OrderStatus.inProgress,
        currency: widget.currency,
        paymentDetails: cm.PaymentDetails(
          downPayment: _num(down['planned']),
          months: rows.length,
          installmentSum: _num(data['schedule_amount']),
          monthlyPayment: rows.isEmpty ? 0 : rows.first.paymentAmount,
          barterAmount: _num(data['barter_amount']),
          barterSubject: data['barter_note']?.toString(),
          schedule: rows,
        ),
      ),
    );
  }

  Future<void> _addPayment() async {
    final data = _data;
    if (data == null) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentSheet(orderId: widget.orderId, installment: data),
    );
    if (saved == true) _load();
  }

  Future<void> _reverse(Map payment) async {
    final id = int.tryParse(payment['id']?.toString() ?? '');
    if (id == null) return;
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить платёж'),
        content: TextField(controller: reason, decoration: const InputDecoration(labelText: 'Причина')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Закрыть')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Отменить платёж')),
        ],
      ),
    );
    if (ok != true || reason.text.trim().isEmpty) return;
    try {
      await _api.reverseInstallmentPayment(orderId: widget.orderId, paymentId: id, reason: reason.text.trim());
      _load();
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(context: context, message: e.toString().replaceFirst('Exception: ', ''), isSuccess: false);
    }
  }

  Future<void> _refund(Map payment) async {
    final id = int.tryParse(payment['id']?.toString() ?? '');
    if (id == null) return;
    final amount = TextEditingController();
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Вернуть деньги'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Сумма')),
            TextField(controller: reason, decoration: const InputDecoration(labelText: 'Причина')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Закрыть')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Вернуть')),
        ],
      ),
    );
    final value = double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
    if (ok != true || value <= 0 || reason.text.trim().isEmpty) return;
    try {
      await _api.refundInstallmentPayment(
        orderId: widget.orderId,
        paymentId: id,
        amount: value,
        reason: reason.text.trim(),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(context: context, message: e.toString().replaceFirst('Exception: ', ''), isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Text(_error!, style: const TextStyle(fontFamily: 'Golos'));
    }
    final data = _data;
    if (data == null) return const SizedBox.shrink();

    final colors = context.appColors;
    final down = data['down_payment'] is Map ? Map<String, dynamic>.from(data['down_payment'] as Map) : <String, dynamic>{};
    final lines = (data['lines'] as List?)?.whereType<Map>().toList() ?? const [];
    final payments = (data['payments'] as List?)?.whereType<Map>().toList() ?? const [];
    final next = data['next_payment'] is Map ? data['next_payment'] as Map : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.5)),
        boxShadow: context.appShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Рассрочка', style: TextStyle(fontFamily: 'Gilroy', fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary)),
          const SizedBox(height: 10),
          _row(colors, 'Статус', _dealStatus(data['settlement_status']?.toString())),
          _row(colors, 'Получено', _money(data['received'])),
          _row(colors, 'Долг', _money(data['debt']), highlight: true),
          _row(colors, 'Просрочено', _money(data['overdue_amount'])),
          _row(colors, 'Взнос', '${_money(down['paid'])} из ${_money(down['planned'])} · ${_lineStatus(down['status']?.toString())}'),
          if (_num(data['barter_amount']) > 0)
            _row(colors, 'Бартер', '${_money(data['barter_amount'])}${data['barter_note'] == null ? '' : ' · ${data['barter_note']}'}'),
          if (next != null) _row(colors, 'Ближайший платёж', '${_money(next['amount'])} до ${_date(next['date'])}'),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: TextStyle(fontFamily: 'Gilroy', fontSize: 12, color: colors.textSecondary),
              dataTextStyle: TextStyle(fontFamily: 'Golos', fontSize: 12, color: colors.textPrimary),
              columns: const [
                DataColumn(label: Text('№')),
                DataColumn(label: Text('Дата')),
                DataColumn(label: Text('План')),
                DataColumn(label: Text('Оплачено')),
                DataColumn(label: Text('Остаток')),
                DataColumn(label: Text('Статус')),
              ],
              rows: [
                DataRow(cells: [
                  const DataCell(Text('Взнос')),
                  const DataCell(Text('—')),
                  DataCell(Text(_money(down['planned']))),
                  DataCell(Text(_money(down['paid']))),
                  DataCell(Text(_money(down['remainder']))),
                  DataCell(Text(_lineStatus(down['status']?.toString()))),
                ]),
                ...lines.map((line) => DataRow(cells: [
                      DataCell(Text('${line['position'] ?? ''}')),
                      DataCell(Text(_date(line['due_date']))),
                      DataCell(Text(_money(line['planned']))),
                      DataCell(Text(_money(line['paid']))),
                      DataCell(Text(_money(line['remainder']))),
                      DataCell(Text(_lineStatus(line['status']?.toString()))),
                    ])),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(onPressed: _addPayment, child: const Text('Добавить платёж')),
              OutlinedButton(onPressed: lines.isEmpty ? null : _openTemplate, child: const Text('Шаблон графика')),
            ],
          ),
          if (payments.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Платежи', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, color: colors.textPrimary)),
            ...payments.map((payment) {
              final status = payment['status']?.toString();
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${_money(payment['amount'])} · ${_payStatus(status)}'),
                subtitle: Text('${_date(payment['paid_at'])} · ${payment['document_number'] ?? payment['method'] ?? ''}'),
                trailing: status == 'confirmed'
                    ? PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'reverse') _reverse(payment);
                          if (value == 'refund') _refund(payment);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'reverse', child: Text('Отменить')),
                          PopupMenuItem(value: 'refund', child: Text('Вернуть')),
                        ],
                      )
                    : status == 'draft'
                        ? TextButton(
                            onPressed: () async {
                              final saved = await showModalBottomSheet<bool>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => _PaymentSheet(
                                  orderId: widget.orderId,
                                  installment: data,
                                  draft: Map<String, dynamic>.from(payment),
                                ),
                              );
                              if (saved == true) _load();
                            },
                            child: const Text('Подтвердить'),
                          )
                        : null,
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _row(dynamic colors, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontFamily: 'Golos', fontSize: 13, color: colors.textSecondary))),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? colors.buttonPrimaryBg : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSheet extends StatefulWidget {
  final int orderId;
  final Map<String, dynamic> installment;
  final Map<String, dynamic>? draft;

  const _PaymentSheet({
    required this.orderId,
    required this.installment,
    this.draft,
  });

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final ApiService _api = ApiService();
  final _amount = TextEditingController();
  final _document = TextEditingController();
  final _comment = TextEditingController();
  DateTime _date = DateTime.now();
  String _method = 'cash';
  String _type = 'down_payment';
  int? _lineId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    if (draft != null) {
      _amount.text = draft['amount']?.toString() ?? '';
      _document.text = draft['document_number']?.toString() ?? '';
      _comment.text = draft['comment']?.toString() ?? '';
      _method = draft['method']?.toString().isNotEmpty == true ? draft['method'].toString() : 'cash';
      _date = DateTime.tryParse(draft['paid_at']?.toString() ?? '') ?? DateTime.now();
    }
    final lines = (widget.installment['lines'] as List?)?.whereType<Map>().toList() ?? const [];
    if (lines.isNotEmpty) _lineId = int.tryParse(lines.first['id']?.toString() ?? '');
  }

  @override
  void dispose() {
    _amount.dispose();
    _document.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) {
      showCustomSnackBar(context: context, message: 'Укажите сумму', isSuccess: false);
      return;
    }
    setState(() => _busy = true);
    try {
      var paymentId = int.tryParse(widget.draft?['id']?.toString() ?? '');
      if (paymentId == null) {
        final created = await _api.createInstallmentPayment(
          orderId: widget.orderId,
          body: {
            'paid_at': DateFormat('yyyy-MM-dd').format(_date),
            'amount': amount,
            'method': _method,
            if (_document.text.trim().isNotEmpty) 'document_number': _document.text.trim(),
            if (_comment.text.trim().isNotEmpty) 'comment': _comment.text.trim(),
          },
        );
        paymentId = int.tryParse(created['id']?.toString() ?? '');
        if (created['status']?.toString() == 'confirmed' || paymentId == null) {
          if (!mounted) return;
          Navigator.pop(context, true);
          return;
        }
      }

      final down = widget.installment['down_payment'];
      final obligationId = down is Map ? int.tryParse(down['obligation_id']?.toString() ?? '') : null;
      final allocation = <String, dynamic>{
        'amount': amount,
        'type': _type,
      };
      if (_type == 'down_payment') {
        allocation['obligation_id'] = obligationId;
        allocation['schedule_line_id'] = null;
      } else if (_type == 'schedule_line') {
        allocation['schedule_line_id'] = _lineId;
      }
      await _api.confirmInstallmentPayment(
        orderId: widget.orderId,
        paymentId: paymentId,
        allocations: [allocation],
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(context: context, message: e.toString().replaceFirst('Exception: ', ''), isSuccess: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final lines = (widget.installment['lines'] as List?)?.whereType<Map>().toList() ?? const [];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.draft == null ? 'Поступление' : 'Подтвердить платёж',
                style: TextStyle(fontFamily: 'Gilroy', fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary),
              ),
              const SizedBox(height: 10),
              CustomTextField(controller: _amount, label: 'Сумма', hintText: '0', keyboardType: TextInputType.number, readOnly: widget.draft != null),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: const InputDecoration(labelText: 'Способ'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Наличные')),
                  DropdownMenuItem(value: 'transfer', child: Text('Перевод')),
                  DropdownMenuItem(value: 'terminal', child: Text('Терминал')),
                ],
                onChanged: widget.draft == null
                    ? (value) {
                        if (value != null) setState(() => _method = value);
                      }
                    : null,
              ),
              const SizedBox(height: 8),
              CustomTextField(controller: _document, label: 'Номер квитанции', hintText: 'КВ-1'),
              const SizedBox(height: 8),
              CustomTextField(controller: _comment, label: 'Комментарий', hintText: 'Необязательно'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Куда зачислить'),
                items: const [
                  DropdownMenuItem(value: 'down_payment', child: Text('Первоначальный взнос')),
                  DropdownMenuItem(value: 'schedule_line', child: Text('Месяц графика')),
                  DropdownMenuItem(value: 'early_repayment', child: Text('Досрочно')),
                  DropdownMenuItem(value: 'unallocated', child: Text('Без выбора месяца')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
              if (_type == 'schedule_line' && lines.isNotEmpty)
                DropdownButtonFormField<int>(
                  initialValue: _lineId,
                  decoration: const InputDecoration(labelText: 'Строка графика'),
                  items: lines.map((line) {
                    final id = int.tryParse(line['id']?.toString() ?? '') ?? 0;
                    return DropdownMenuItem(value: id, child: Text('№ ${line['position']} · ${line['due_date']}'));
                  }).toList(),
                  onChanged: (value) => setState(() => _lineId = value),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _busy ? null : _save, child: Text(_busy ? 'Сохранение...' : 'Сохранить')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
