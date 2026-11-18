import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_field_style.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/file_picker_dialog.dart';
import 'package:crm_task_manager/models/common/file_helper.dart';
import 'package:crm_task_manager/models/lead/lead_list_model.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/models/page_2/order_payment_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/lead_with_manager.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateOrderPaymentScreen extends StatefulWidget {
  final OrderPayment? existingPayment;
  final int? initialOrderId;

  const CreateOrderPaymentScreen({
    super.key,
    this.existingPayment,
    this.initialOrderId,
  });

  @override
  State<CreateOrderPaymentScreen> createState() => _CreateOrderPaymentScreenState();
}

class _CreateOrderPaymentScreenState extends State<CreateOrderPaymentScreen> {
  final ApiService _api = ApiService();
  final _amountController = TextEditingController();
  final _documentController = TextEditingController();
  final _commentController = TextEditingController();
  final List<FileHelper> _files = [];

  DateTime _paidAt = DateTime.now();
  String _method = 'cash';
  String _type = 'unallocated';
  int? _lineId;
  int? _obligationId;

  LeadData? _selectedLead;
  Order? _selectedOrder;
  List<Order> _leadOrders = const [];
  bool _loadingOrders = false;
  Map<String, dynamic>? _installmentData;
  bool _loadingInstallment = false;
  bool _busy = false;

  bool get _isEdit => widget.existingPayment != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = widget.existingPayment!;
      _amountController.text = p.amount == p.amount.roundToDouble()
          ? p.amount.toStringAsFixed(0)
          : p.amount.toStringAsFixed(2);
      _documentController.text = p.documentNumber ?? '';
      _commentController.text = p.comment ?? '';
      _method = p.method.isNotEmpty ? p.method : 'cash';
      if (p.paidAt != null) {
        _paidAt = DateTime.tryParse(p.paidAt!) ?? DateTime.now();
      }
      if (p.allocations.isNotEmpty) {
        _type = p.allocations.first.type;
        _lineId = p.allocations.first.scheduleLineId;
        _obligationId = p.allocations.first.obligationId;
      }
      _loadInitialOrder(p.orderId);
    } else if (widget.initialOrderId != null) {
      _loadInitialOrder(widget.initialOrderId!);
    }
  }

  Future<void> _loadInitialOrder(int orderId) async {
    setState(() => _loadingOrders = true);
    try {
      final order = await _api.getOrderDetails(orderId);
      if (!mounted) return;
      setState(() {
        _selectedOrder = order;
        _loadingOrders = false;
      });
      _loadInstallmentForOrder(orderId);
    } catch (_) {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  Future<void> _loadInstallmentForOrder(int orderId) async {
    setState(() => _loadingInstallment = true);
    try {
      final data = await _api.getOrderInstallment(orderId);
      if (!mounted) return;
      setState(() {
        _installmentData = data;
        _loadingInstallment = false;
        final down = data?['down_payment'] is Map ? data!['down_payment'] as Map : null;
        _obligationId = int.tryParse(down?['obligation_id']?.toString() ?? '');
        final lines = (data?['lines'] as List?)?.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
        final openLines = lines.where((l) => _num(l['remainder']) > 0 && l['status']?.toString() != 'paid').toList();
        if (_type == 'unallocated') {
          if (_obligationId != null && _num(down?['remainder']) > 0) {
            _type = 'down_payment';
          } else if (openLines.isNotEmpty) {
            _type = 'schedule_line';
            _lineId = int.tryParse(openLines.first['id']?.toString() ?? '');
          }
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingInstallment = false);
    }
  }

  Future<void> _onLeadSelected(LeadData lead) async {
    if (_selectedLead?.id == lead.id && _leadOrders.isNotEmpty) return;
    setState(() {
      _selectedLead = lead;
      _selectedOrder = null;
      _leadOrders = const [];
      _loadingOrders = true;
      _installmentData = null;
    });
    try {
      final response = await _api.getOrdersByLead(leadId: lead.id, perPage: 50);
      if (!mounted || _selectedLead?.id != lead.id) return;
      setState(() {
        _leadOrders = response.data;
        _loadingOrders = false;
        if (response.data.length == 1) {
          _onOrderSelected(response.data.first);
        }
      });
    } catch (e) {
      if (!mounted || _selectedLead?.id != lead.id) return;
      setState(() => _loadingOrders = false);
      showCustomSnackBar(context: context, message: e.toString().replaceFirst('Exception: ', ''), isSuccess: false);
    }
  }

  void _onOrderSelected(Order order) {
    setState(() {
      _selectedOrder = order;
      _lineId = null;
    });
    _loadInstallmentForOrder(order.id);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _documentController.dispose();
    _commentController.dispose();
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

  Future<void> _save({bool confirmAfterSave = false}) async {
    final orderId = _selectedOrder?.id ?? widget.existingPayment?.orderId;
    if (orderId == null || orderId <= 0) {
      showCustomSnackBar(context: context, message: 'Выберите сделку', isSuccess: false);
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll(' ', '').replaceAll(',', '.')) ?? 0;
    if (amount <= 0) {
      showCustomSnackBar(context: context, message: 'Укажите сумму платежа', isSuccess: false);
      return;
    }

    if (_type == 'down_payment' && _obligationId == null) {
      _type = 'unallocated';
    }

    final openLines = _openLines();
    if (_type == 'schedule_line') {
      final selected = openLines.where((l) => int.tryParse(l['id']?.toString() ?? '') == _lineId);
      if (selected.isEmpty && openLines.isNotEmpty) {
        _lineId = int.tryParse(openLines.first['id']?.toString() ?? '');
      }
      if (_lineId == null && openLines.isEmpty) {
        _type = 'unallocated';
      }
    }

    setState(() => _busy = true);
    try {
      final body = <String, dynamic>{
        'paid_at': DateFormat('yyyy-MM-dd').format(_paidAt),
        'amount': amount,
        'method': _method,
        if (_documentController.text.trim().isNotEmpty) 'document_number': _documentController.text.trim(),
        if (_commentController.text.trim().isNotEmpty) 'comment': _commentController.text.trim(),
      };

      int? paymentId;
      String? status;

      if (_isEdit) {
        paymentId = widget.existingPayment!.id;
        final updated = await _api.updateOrderPayment(
          orderId: orderId,
          paymentId: paymentId,
          body: body,
          filePaths: _files.map((f) => f.path).toList(),
        );
        status = updated['status']?.toString();
      } else {
        final created = await _api.createInstallmentPayment(
          orderId: orderId,
          filePaths: _files.map((f) => f.path).toList(),
          body: body,
        );
        paymentId = int.tryParse(created['id']?.toString() ?? '');
        status = created['status']?.toString();
      }

      if (confirmAfterSave && paymentId != null && status != 'confirmed') {
        final allocation = <String, dynamic>{
          'amount': amount,
          'type': _type,
          'obligation_id': _type == 'down_payment' ? _obligationId : null,
          'schedule_line_id': _type == 'schedule_line' ? _lineId : null,
        };
        try {
          await _api.confirmInstallmentPayment(
            orderId: orderId,
            paymentId: paymentId,
            allocations: [allocation],
          );
        } catch (e) {
          debugPrint('Confirm error: $e');
        }
      }

      if (!mounted) return;
      showCustomSnackBar(
        context: context,
        message: confirmAfterSave ? 'Платёж успешно проведён' : 'Платёж сохранён',
        isSuccess: true,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(context: context, message: e.toString().replaceFirst('Exception: ', ''), isSuccess: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<Map<String, dynamic>> _openLines() {
    final lines = (_installmentData?['lines'] as List?)?.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    final open = lines.where((l) => _num(l['remainder']) > 0 && l['status']?.toString() != 'paid').toList();
    open.sort((a, b) => (a['due_date']?.toString() ?? '').compareTo(b['due_date']?.toString() ?? ''));
    return open;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final openLines = _openLines();

    return Scaffold(
      backgroundColor: colors.surfacePrimary,
      appBar: AppBar(
        backgroundColor: colors.surfacePrimary,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEdit ? 'Редактирование платежа' : 'Создание платежа',
              style: TextStyle(fontFamily: 'Gilroy', fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary),
            ),
            Text(
              'Заполните реквизиты платежа',
              style: TextStyle(fontFamily: 'Gilroy', fontSize: 12, fontWeight: FontWeight.w500, color: colors.textSecondary),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _section(
            colors,
            'Сделка',
            [
              if (!_isEdit && widget.initialOrderId == null) ...[
                Text('Клиент *', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
                const SizedBox(height: 6),
                LeadWithManager(
                  selectedLead: _selectedLead?.name,
                  onSelectLead: _onLeadSelected,
                  alwaysRefreshFromServer: true,
                ),
                const SizedBox(height: 12),
                if (_loadingOrders)
                  const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                else if (_leadOrders.isNotEmpty) ...[
                  Text('Сделка *', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
                  const SizedBox(height: 6),
                  _dropdown<int>(
                    colors: colors,
                    value: _selectedOrder?.id,
                    hint: 'Выберите сделку',
                    items: _leadOrders.map((order) {
                      final numStr = order.orderNumber.isEmpty ? order.id.toString() : order.orderNumber;
                      final sumStr = order.sum != null ? ' · ${_money(order.sum!)}' : '';
                      return DropdownMenuItem(value: order.id, child: Text('Сделка №$numStr$sumStr'));
                    }).toList(),
                    onChanged: (id) {
                      final found = _leadOrders.where((o) => o.id == id);
                      if (found.isNotEmpty) _onOrderSelected(found.first);
                    },
                  ),
                ] else if (_selectedLead != null)
                  Text('У клиента нет активных сделок', style: TextStyle(fontFamily: 'Gilroy', fontSize: 13, color: colors.textSecondary)),
                const SizedBox(height: 8),
              ],
              if (_selectedOrder != null || _isEdit) ...[
                _readonlyField(colors, 'Покупатель', _selectedLead?.name ?? widget.existingPayment?.buyer ?? '—'),
                _readonlyField(
                  colors,
                  'Сделка',
                  '№${_selectedOrder?.orderNumber ?? widget.existingPayment?.orderNumber ?? widget.existingPayment?.orderId ?? '—'}',
                ),
                if (_selectedOrder?.goods.isNotEmpty == true || widget.existingPayment?.object != null)
                  _readonlyField(
                    colors,
                    'Объект',
                    _selectedOrder?.goods.isNotEmpty == true
                        ? _selectedOrder!.goods.first.goodName
                        : widget.existingPayment?.object ?? '—',
                  ),
                if (_loadingInstallment)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                  )
                else if (_installmentData != null)
                  _readonlyField(colors, 'Остаток долга', _money(_num(_installmentData!['debt']))),
              ],
            ],
          ),
          const SizedBox(height: 14),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd.MM.yyyy').format(_paidAt), style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, color: colors.textPrimary)),
                      Icon(Icons.calendar_today_rounded, size: 18, color: colors.iconSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _amountController,
                label: 'Сумма *',
                hintText: 'Введите сумму платежа',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              Text('Способ оплаты *', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
              const SizedBox(height: 6),
              _dropdown<String>(
                colors: colors,
                value: _method,
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Наличные')),
                  DropdownMenuItem(value: 'transfer', child: Text('Банковский перевод')),
                  DropdownMenuItem(value: 'terminal', child: Text('Терминал')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _method = val);
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _documentController,
                label: 'Номер квитанции или поручения',
                hintText: 'Введите номер документа',
              ),
              const SizedBox(height: 12),
              _paymentFilesWidget(colors),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _commentController,
                label: 'Комментарий',
                hintText: 'Примечание к платежу',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _section(
            colors,
            'Распределение платежа',
            [
              Text('К чему относится *', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
              const SizedBox(height: 6),
              _dropdown<String>(
                colors: colors,
                value: _type,
                items: () {
                  final hasDown = _obligationId != null;
                  final hasSchedule = openLines.isNotEmpty;
                  return [
                    if (hasDown) const DropdownMenuItem(value: 'down_payment', child: Text('Первоначальный взнос')),
                    if (hasSchedule) const DropdownMenuItem(value: 'schedule_line', child: Text('Платёж по графику')),
                    if (hasSchedule) const DropdownMenuItem(value: 'early_repayment', child: Text('Досрочное погашение')),
                    const DropdownMenuItem(value: 'unallocated', child: Text('Платёж по сделке')),
                  ];
                }(),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() {
                    _type = val;
                    if (val == 'schedule_line' && openLines.isNotEmpty) {
                      _lineId = int.tryParse(openLines.first['id']?.toString() ?? '');
                    }
                  });
                },
              ),
              if (_type == 'schedule_line') ...[
                const SizedBox(height: 10),
                if (openLines.isEmpty)
                  _readonlyField(colors, 'Месяц', 'Нет месяцев с остатком')
                else
                  _dropdown<int>(
                    colors: colors,
                    value: () {
                      final ids = openLines.map((l) => int.tryParse(l['id']?.toString() ?? '')).whereType<int>().toList();
                      if (_lineId != null && ids.contains(_lineId)) return _lineId;
                      return ids.isEmpty ? null : ids.first;
                    }(),
                    items: openLines.map((line) {
                      final id = int.tryParse(line['id']?.toString() ?? '') ?? 0;
                      return DropdownMenuItem(
                        value: id,
                        child: Text(
                          '№${line['position']} · ${_date(line['due_date'])} · ост. ${_money(_num(line['remainder']))}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _lineId = val),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => _save(confirmAfterSave: false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.buttonPrimaryBg),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _busy
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colors.buttonPrimaryBg))
                        : Text('Сохранить', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, color: colors.buttonPrimaryBg)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _busy ? null : () => _save(confirmAfterSave: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _busy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Провести', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required dynamic colors,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? hint,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      hint: hint != null ? Text(hint, style: TextStyle(fontFamily: 'Gilroy', color: colors.textSecondary)) : null,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: colors.fieldBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: AppFieldStyle.outline(context),
        enabledBorder: OutlineInputBorder(borderRadius: AppFieldStyle.radius, borderSide: AppFieldStyle.side(context)),
        focusedBorder: OutlineInputBorder(borderRadius: AppFieldStyle.radius, borderSide: AppFieldStyle.side(context, focused: true)),
      ),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.iconSecondary),
      dropdownColor: colors.surfacePrimary,
      style: TextStyle(fontSize: 14, fontFamily: 'Gilroy', fontWeight: FontWeight.w500, color: colors.textPrimary),
    );
  }

  Widget _section(dynamic colors, String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceElevated.withValues(alpha: 0.35),
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

  Widget _readonlyField(dynamic colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontFamily: 'Gilroy', fontSize: 13, color: colors.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, fontSize: 13.5, color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentFilesWidget(dynamic colors) {
    final addIcon = ThemeData.estimateBrightnessForColor(colors.fieldBg) == Brightness.dark
        ? 'assets/icons/files/add_for_dark.png'
        : 'assets/icons/files/add.png';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Подтверждающий документ', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _files.length + 1,
            itemBuilder: (context, index) {
              if (index == _files.length) {
                return GestureDetector(
                  onTap: _busy ? null : _pickPaymentFile,
                  child: Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.fieldBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(addIcon, width: 36, height: 36),
                        const SizedBox(height: 6),
                        Text('Добавить', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Gilroy', fontSize: 11, color: colors.textPrimary)),
                      ],
                    ),
                  ),
                );
              }
              final file = _files[index];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      decoration: BoxDecoration(
                        color: colors.fieldBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.insert_drive_file_outlined, size: 34, color: colors.buttonPrimaryBg),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Gilroy', fontSize: 10, color: colors.textPrimary)),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _files.removeAt(index)),
                        child: Container(
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
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

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(' ', '').replaceAll(',', '.') ?? '') ?? 0.0;
  }

  String _money(double value) {
    final text = value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
    return text.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ' ');
  }

  String _date(dynamic value) {
    final raw = value?.toString() ?? '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw.isEmpty ? '—' : raw;
    return DateFormat('dd.MM.yyyy').format(parsed);
  }
}
