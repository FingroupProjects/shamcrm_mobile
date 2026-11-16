import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class DealContractsSection extends StatelessWidget {
  final int orderId;
  final String orderNumber;
  final String buyerName;
  final String buyerPhone;
  final String buyerPassport;
  final String buyerAddress;

  const DealContractsSection({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.buyerName,
    this.buyerPhone = '',
    this.buyerPassport = '',
    this.buyerAddress = '',
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
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
          Text(
            'Договор',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Составление, предпросмотр и новая версия по данным сделки',
            style: TextStyle(fontFamily: 'Golos', fontSize: 12.5, color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => _ContractDialog(
                    orderId: orderId,
                    orderNumber: orderNumber,
                    buyerName: buyerName,
                    buyerPhone: buyerPhone,
                    buyerPassport: buyerPassport,
                    buyerAddress: buyerAddress,
                  ),
                );
              },
              child: const Text('Открыть договор'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueField {
  final String key;
  final String label;
  final bool required;
  final TextEditingController controller;

  _ValueField({
    required this.key,
    required this.label,
    required this.required,
    required this.controller,
  });
}

class _ContractDialog extends StatefulWidget {
  final int orderId;
  final String orderNumber;
  final String buyerName;
  final String buyerPhone;
  final String buyerPassport;
  final String buyerAddress;

  const _ContractDialog({
    required this.orderId,
    required this.orderNumber,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerPassport,
    required this.buyerAddress,
  });

  @override
  State<_ContractDialog> createState() => _ContractDialogState();
}

class _ContractDialogState extends State<_ContractDialog> {
  final ApiService _api = ApiService();
  final _number = TextEditingController();
  final _signer = TextEditingController();
  final List<_ValueField> _fields = [];
  List<Map<String, dynamic>> _contracts = [];
  List<Map<String, dynamic>> _templates = [];
  int? _templateId;
  DateTime _date = DateTime.now();
  String? _html;
  String? _error;
  bool _loading = true;
  bool _busy = false;
  bool _canEditNumber = false;

  static const _knownLabels = {
    'company_director': 'Подписант',
    'buyer_passport': 'Паспорт',
    'buyer_address': 'Адрес',
    'buyer_phone': 'Телефон',
    'buyer_name': 'ФИО покупателя',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _number.dispose();
    _signer.dispose();
    for (final field in _fields) {
      field.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final organizationId = await _api.resolveSelectedOrganizationId();
      final results = await Future.wait([
        _api.getOrderContracts(widget.orderId),
        _api.getContractTemplates(organizationId),
        _api.getContractRequisites(organizationId),
        _api.hasPermission('contract.edit_number').catchError((_) => false),
      ]);
      if (!mounted) return;
      final requisites = results[2] as Map<String, dynamic>;
      setState(() {
        _contracts = results[0] as List<Map<String, dynamic>>;
        _templates = results[1] as List<Map<String, dynamic>>;
        _canEditNumber = results[3] as bool;
        _signer.text = requisites['director_name']?.toString() ?? '';
        _loading = false;
        if (_templates.isNotEmpty) {
          _templateId = int.tryParse(_templates.first['id']?.toString() ?? '');
        }
      });
      if (_templateId != null) await _preview(silent: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _labelOf(Map row) {
    final key = row['key']?.toString() ?? '';
    final label = row['label']?.toString().trim() ?? '';
    if (label.isNotEmpty) return label;
    return _knownLabels[key] ?? key;
  }

  void _ensureField(String key, String label, bool required, String value) {
    for (final field in _fields) {
      if (field.key == key) {
        if (field.controller.text.isEmpty && value.isNotEmpty) {
          field.controller.text = value;
        }
        return;
      }
    }
    var initial = value;
    if (initial.isEmpty) {
      if (key == 'buyer_phone') initial = widget.buyerPhone;
      if (key == 'buyer_passport') initial = widget.buyerPassport;
      if (key == 'buyer_address') initial = widget.buyerAddress;
      if (key == 'buyer_name') initial = widget.buyerName;
      if (key == 'company_director') initial = _signer.text;
    }
    _fields.add(_ValueField(
      key: key,
      label: label,
      required: required,
      controller: TextEditingController(text: initial),
    ));
  }

  Map<String, dynamic> _body() {
    final values = <String, String>{};
    if (_signer.text.trim().isNotEmpty) {
      values['company_director'] = _signer.text.trim();
    }
    for (final field in _fields) {
      final text = field.controller.text.trim();
      if (text.isNotEmpty) values[field.key] = text;
    }
    final number = _number.text.trim();
    return {
      'template_id': _templateId,
      'contract_date': DateFormat('yyyy-MM-dd').format(_date),
      if (number.isNotEmpty && _canEditNumber) 'number': number,
      if (values.isNotEmpty) 'values': values,
      'draft': false,
    };
  }

  Future<void> _preview({bool silent = false}) async {
    if (_templateId == null) return;
    setState(() => _busy = true);
    try {
      final body = _body()..remove('draft');
      final preview = await _api.previewOrderContract(orderId: widget.orderId, body: body);
      final rows = preview['values'];
      if (rows is List) {
        for (final row in rows.whereType<Map>()) {
          final key = row['key']?.toString() ?? '';
          if (key.isEmpty || key == 'contract_number' || key == 'contract_date') continue;
          if (key == 'company_director' && (row['value']?.toString().isNotEmpty ?? false) && _signer.text.isEmpty) {
            _signer.text = row['value'].toString();
          }
          _ensureField(key, _labelOf(row), row['required'] == true, row['value']?.toString() ?? '');
        }
      }
      _ensureField('buyer_passport', 'Паспорт', true, widget.buyerPassport);
      _ensureField('buyer_address', 'Адрес', false, widget.buyerAddress);
      _ensureField('buyer_phone', 'Телефон', true, widget.buyerPhone);
      final numberPreview = preview['number_preview']?.toString() ?? '';
      if (_number.text.isEmpty && numberPreview.isNotEmpty) _number.text = numberPreview;
      if (!mounted) return;
      setState(() {
        if (!silent) _html = preview['html']?.toString();
        _busy = false;
      });
      if (!silent && preview['missing'] is List && (preview['missing'] as List).isNotEmpty) {
        final names = (preview['missing'] as List)
            .whereType<Map>()
            .map((row) => row['label']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .join(', ');
        if (mounted && names.isNotEmpty) {
          showCustomSnackBar(context: context, message: 'Заполните: $names', isSuccess: false);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (!silent) {
        showCustomSnackBar(
          context: context,
          message: e.toString().replaceFirst('Exception: ', ''),
          isSuccess: false,
        );
      } else {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _generate() async {
    for (final field in _fields) {
      if (field.required && field.controller.text.trim().isEmpty) {
        showCustomSnackBar(context: context, message: 'Заполните: ${field.label}', isSuccess: false);
        return;
      }
    }
    setState(() => _busy = true);
    try {
      await _api.createOrderContract(orderId: widget.orderId, body: _body());
      if (!mounted) return;
      showCustomSnackBar(context: context, message: 'Договор сформирован', isSuccess: true);
      setState(() => _loading = true);
      _contracts = await _api.getOrderContracts(widget.orderId);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(
        context: context,
        message: e.toString().replaceFirst('Exception: ', ''),
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openContract(Map<String, dynamic> item) async {
    final id = int.tryParse(item['id']?.toString() ?? '');
    if (id == null) return;
    if (item['has_file'] == true || item['has_file'] == 1) {
      try {
        final bytes = await _api.downloadOrderContractBytes(orderId: widget.orderId, contractId: id);
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/contract-$id.pdf');
        await file.writeAsBytes(bytes);
        await OpenFile.open(file.path);
        return;
      } catch (_) {}
    }
    try {
      final contract = await _api.getOrderContract(orderId: widget.orderId, contractId: id);
      final html = contract['body']?.toString() ?? contract['html']?.toString() ?? '';
      if (!mounted) return;
      setState(() => _html = html.isEmpty ? null : html);
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(context: context, message: e.toString().replaceFirst('Exception: ', ''), isSuccess: false);
    }
  }

  String _dateText(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '—';
    return DateFormat('dd.MM.yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final titleNumber = widget.orderNumber.isEmpty ? widget.orderId.toString() : widget.orderNumber;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      backgroundColor: colors.surfacePrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: _loading
          ? const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Договор по заказу $titleNumber: ${widget.buyerName}',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_error!, style: TextStyle(fontFamily: 'Golos', color: colors.textSecondary)),
                    ),
                  if (_contracts.isEmpty)
                    Text(
                      'Договор ещё не составлен.',
                      style: TextStyle(fontFamily: 'Golos', fontSize: 13, color: colors.textSecondary),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingTextStyle: TextStyle(fontFamily: 'Gilroy', fontSize: 12, color: colors.textSecondary),
                        dataTextStyle: TextStyle(fontFamily: 'Golos', fontSize: 12.5, color: colors.textPrimary),
                        columns: const [
                          DataColumn(label: Text('Версия')),
                          DataColumn(label: Text('Номер')),
                          DataColumn(label: Text('Шаблон')),
                          DataColumn(label: Text('Дата')),
                          DataColumn(label: Text('Статус')),
                          DataColumn(label: Text('')),
                        ],
                        rows: _contracts.map((item) {
                          return DataRow(cells: [
                            DataCell(Text('${item['version'] ?? ''}')),
                            DataCell(Text(item['number']?.toString() ?? '—')),
                            DataCell(Text(item['title']?.toString() ?? item['document_type_label']?.toString() ?? '—')),
                            DataCell(Text(_dateText(item['contract_date'] ?? item['created_at']))),
                            DataCell(Text(item['status_label']?.toString() ?? '—')),
                            DataCell(TextButton(onPressed: () => _openContract(item), child: const Text('Открыть'))),
                          ]);
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 14),
                  Text(
                    _contracts.isEmpty ? 'Составить договор' : 'Пересоздать (новая версия)',
                    style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  if (_templates.isEmpty)
                    Text(
                      'Нет включённого шаблона для этой компании.',
                      style: TextStyle(fontFamily: 'Golos', color: colors.textSecondary),
                    )
                  else ...[
                    DropdownButtonFormField<int>(
                      initialValue: _templateId,
                      decoration: const InputDecoration(labelText: 'Шаблон'),
                      items: _templates.map((item) {
                        final id = int.tryParse(item['id']?.toString() ?? '') ?? 0;
                        return DropdownMenuItem(
                          value: id,
                          child: Text(item['name']?.toString() ?? 'Шаблон'),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        setState(() => _templateId = value);
                        await _preview(silent: true);
                      },
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _number,
                      label: 'Номер',
                      hintText: 'ДП-2026-001',
                      readOnly: !_canEditNumber,
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Дата'),
                      subtitle: Text(DateFormat('dd.MM.yyyy').format(_date)),
                      trailing: const Icon(Icons.calendar_today_outlined, size: 18),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                    ),
                    CustomTextField(controller: _signer, label: 'Подписант', hintText: 'ФИО директора'),
                    ..._fields.where((field) => field.key != 'company_director').map(
                          (field) => Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: CustomTextField(
                              controller: field.controller,
                              label: field.required ? '${field.label} *' : field.label,
                              hintText: '',
                            ),
                          ),
                        ),
                  ],
                  if (_html != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: Html(data: _html!),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _busy || _templateId == null ? null : () => _preview(),
                          child: const Text('Предпросмотр'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _busy || _templateId == null ? null : _generate,
                          child: Text(_busy ? '...' : 'Сформировать'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Закрыть'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
