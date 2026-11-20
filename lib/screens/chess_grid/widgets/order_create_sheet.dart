import 'dart:convert';
import 'dart:io';

import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/localization/localization_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_field_style.dart';
import 'package:crm_task_manager/custom_widget/country_data_list.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_number_input.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/custom_widget/file_picker_dialog.dart';
import 'package:crm_task_manager/models/common/file_helper.dart';
import 'package:crm_task_manager/models/field/field_configuration.dart';
import 'package:crm_task_manager/models/field/main_field_model.dart';
import 'package:crm_task_manager/models/lead/lead_list_model.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart' as deal;
import 'package:crm_task_manager/models/page_2/order_status_model.dart' as order_api;
import 'package:crm_task_manager/models/page_2/supplier_model.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid/utils/chess_grid_localizations.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/payment_schedule_sheet.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/lead_with_manager.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_custom_directory_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/custom_field_model.dart' as crm_fields;
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_create_custom.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/main_field_dropdown_widget.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/manager_for_lead.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';
import 'package:crm_task_manager/widgets/required_field_slot.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DealFormSlot {
  final String key;
  final String title;
  final bool active;
  final bool custom;
  final bool directory;
  final int? configId;

  const _DealFormSlot({
    required this.key,
    required this.title,
    required this.active,
    this.custom = false,
    this.directory = false,
    this.configId,
  });

  _DealFormSlot copyWith({bool? active}) {
    return _DealFormSlot(
      key: key,
      title: title,
      active: active ?? this.active,
      custom: custom,
      directory: directory,
      configId: configId,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'title': title,
        'active': active,
        'custom': custom,
        'directory': directory,
        'configId': configId,
      };

  factory _DealFormSlot.fromJson(Map<String, dynamic> json) {
    return _DealFormSlot(
      key: json['key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      active: json['active'] != false,
      custom: json['custom'] == true,
      directory: json['directory'] == true,
      configId: json['configId'] is int ? json['configId'] as int : int.tryParse('${json['configId']}'),
    );
  }
}

class _PickOption {
  final String key;
  final String title;

  const _PickOption(this.key, this.title);

  @override
  bool operator ==(Object other) => other is _PickOption && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => title;
}

class OrderCreateSheet extends StatefulWidget {
  final Apartment? apartment;
  final ParkingSpot? parking;
  final deal.Order? existingOrder;

  const OrderCreateSheet({
    super.key,
    this.apartment,
    this.parking,
    this.existingOrder,
  });

  bool get isEdit => existingOrder != null;

  static Future<dynamic> show({
    required BuildContext context,
    Apartment? apartment,
    ParkingSpot? parking,
    deal.Order? existingOrder,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: OrderCreateSheet(
          apartment: apartment,
          parking: parking,
          existingOrder: existingOrder,
        ),
      ),
    );
  }

  @override
  State<OrderCreateSheet> createState() => _OrderCreateSheetState();
}

class _OrderCreateSheetState extends State<OrderCreateSheet> {
  // CRM Client & Manager
  String? _selectedLeadId;
  String? _selectedManagerId;
  String? _selectedManagerName;

  // Status from the CRM order-status directory.
  List<order_api.OrderStatus> _orderStatuses = [];
  int? _selectedStatusId;
  bool _loadingMeta = true;
  bool _saving = false;
  final List<FileHelper> _attachedFiles = [];

  static const _fieldLayoutKey = 'chess_deal_form_fields_v1';
  static const _fieldTable = 'orders';
  static const _lockedFieldKeys = {'client', 'manager', 'status', 'owner', 'phone', 'passport'};
  static const _builtinFields = <(String, String)>[
    ('client', 'Клиент'),
    ('manager', 'Менеджер'),
    ('status', 'Статус'),
    ('owner', 'ФИО собственника'),
    ('phone', 'Телефон'),
    ('gender', 'Пол'),
    ('passport', 'Паспорт'),
    ('issue_place', 'Место выдачи'),
    ('inn', 'ИНН'),
    ('address', 'Адрес проживания'),
    ('passport_dates', 'Даты паспорта'),
    ('birth', 'Дата рождения'),
    ('price_area', 'Цена и площадь'),
    ('deal_type', 'Тип сделки'),
    ('sum', 'Сумма'),
    ('barter', 'Бартер'),
    ('installment', 'Рассрочка'),
  ];

  final _apiService = ApiService();
  final GlobalKey _addFieldButtonKey = GlobalKey();
  final List<crm_fields.CustomField> _crmFields = [];
  List<FieldConfiguration> _fieldConfigurations = [];
  List<_DealFormSlot> _fieldSlots = [
    for (final field in _builtinFields)
      _DealFormSlot(key: field.$1, title: field.$2, active: true),
  ];
  List<_DealFormSlot>? _fieldSlotsBackup;
  bool _isSettingsMode = false;
  bool _isSavingFieldOrder = false;

  // Owner & Contact
  final _ownerFullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _formattedPhone = '';
  Country? _phoneCountry;
  int _phoneRevision = 0;
  String _selectedGender = 'm';

  // Passport & Identification
  final _passportSeriesNumberController = TextEditingController();
  final _passportIssuePlaceController = TextEditingController();
  final _innController = TextEditingController();
  final _addressController = TextEditingController();
  final _issueDateController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _firstPaymentDateController = TextEditingController();
  final _barterAmountController = TextEditingController();
  final _barterNoteController = TextEditingController();

  // Pricing & Apartment specs
  final _pricePerSqmController = TextEditingController();
  final _totalAreaController = TextEditingController();
  final _totalPriceController = TextEditingController();
  List<SupplierCurrency> _currencies = [];
  SupplierCurrency? _selectedCurrency;

  // Deal & Installment
  DealType _selectedDealType = DealType.cash;
  final _downPaymentController = TextEditingController();
  final _monthsController = TextEditingController(text: '12');
  final _installmentSumController = TextEditingController();
  final _monthlyPaymentController = TextEditingController();

  double _totalArea = 0;
  double _totalPrice = 0;
  double _installmentSum = 0;
  double _monthlyPayment = 0;

  // Validation
  Set<String> _missingFields = {};
  String? _firstMissingField;
  int _fieldErrorPulse = 0;

  String _formatDateForUi(dynamic raw) {
    if (raw == null) return '';
    final str = raw.toString().trim();
    if (str.isEmpty || str == 'null') return '';
    try {
      if (str.contains('/')) {
        final parts = str.split('/');
        if (parts.length == 3 && parts[2].length == 4) return str;
      }
      DateTime dt;
      if (str.contains('T')) {
        final parsed = DateTime.parse(str);
        dt = parsed.isUtc ? parsed.toLocal() : parsed;
      } else if (str.contains('-')) {
        final parsed = DateTime.tryParse(str);
        if (parsed != null) {
          dt = parsed.isUtc ? parsed.toLocal() : parsed;
        } else {
          final datePart = str.split(' ').first;
          dt = DateTime.parse(datePart);
        }
      } else {
        return str;
      }
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return str;
    }
  }

  @override
  void initState() {
    super.initState();
    final apt = widget.apartment;
    final park = widget.parking;

    if (apt != null) {
      _totalArea = apt.totalArea;
      _totalPrice = apt.totalPrice;
      final sqPrice = apt.pricePerSqm > 0
          ? apt.pricePerSqm
          : (_totalArea > 0 ? (_totalPrice / _totalArea) : 0);
      _pricePerSqmController.text = sqPrice > 0 ? sqPrice.toStringAsFixed(0) : '';
      _totalAreaController.text = '${_totalArea.toStringAsFixed(1)} м²';
      _totalPriceController.text = _totalPrice > 0 ? _totalPrice.toStringAsFixed(0) : '';
    } else if (park != null) {
      _totalArea = 0;
      _totalPrice = park.price;
      _pricePerSqmController.text = '0';
      _totalAreaController.text = '—';
      _totalPriceController.text = _totalPrice.toStringAsFixed(0);
    }

    final today = DateTime.now();
    _firstPaymentDateController.text = DateFormat('dd/MM/yyyy').format(today);

    final existing = widget.existingOrder;
    if (existing != null) {
      final raw = existing.rawJson ?? {};

      _selectedLeadId = existing.lead.id.toString();
      if (existing.manager != null) {
        _selectedManagerId = existing.manager!.id.toString();
        _selectedManagerName = existing.manager!.name;
      } else if (raw['manager_id'] != null) {
        _selectedManagerId = raw['manager_id'].toString();
      }

      _selectedStatusId = existing.orderStatus.id;

      final ownerName = (raw['owner_name'] ?? raw['ownerName'] ?? raw['buyer_name'] ?? existing.lead.name)?.toString().trim() ?? '';
      _ownerFullNameController.text = ownerName;

      final phone = existing.phone.isNotEmpty ? existing.phone : (raw['phone']?.toString() ?? '');
      if (phone.isNotEmpty) {
        final parsed = parsePhoneCountryAndNumber(phone);
        _phoneCountry = parsed.country;
        final dial = parsed.country?.dialCode ?? '';
        final local = parsed.localNumber;
        _formattedPhone = dial.isNotEmpty ? '$dial$local' : phone;
        _phoneController.text = local.isNotEmpty ? local : phone;
        _phoneRevision++;
      }

      final genderRaw = (raw['gender'] ?? '').toString().toLowerCase().trim();
      if (genderRaw == 'f' || genderRaw == 'female' || genderRaw == 'ж' || genderRaw == 'женский') {
        _selectedGender = 'f';
      } else {
        _selectedGender = 'm';
      }

      _passportSeriesNumberController.text = (raw['passport'] ?? '').toString();
      _passportIssuePlaceController.text = (raw['passport_issued_by'] ?? raw['passportIssuedBy'] ?? '').toString();
      _issueDateController.text = _formatDateForUi(raw['passport_issued_at'] ?? raw['passportIssuedAt']);
      _expiryDateController.text = _formatDateForUi(raw['passport_expires_at'] ?? raw['passportExpiresAt']);
      _birthDateController.text = _formatDateForUi(raw['owner_birth_date'] ?? raw['ownerBirthDate']);

      final innVal = raw['inn'];
      if (innVal != null && innVal.toString().isNotEmpty && innVal.toString() != 'null') {
        _innController.text = innVal.toString();
      }
      _addressController.text = (raw['residence_address'] ?? raw['residenceAddress'] ?? '').toString();

      final dPricePerM2 = SafeConverters.toDoubleOrNull(raw['price_per_m2'] ?? raw['price_per_sqm']);
      if (dPricePerM2 != null && dPricePerM2 > 0) {
        _pricePerSqmController.text = dPricePerM2.toStringAsFixed(0);
      }
      final dArea = SafeConverters.toDoubleOrNull(raw['total_area']);
      if (dArea != null && dArea > 0) {
        _totalArea = dArea;
        _totalAreaController.text = '${dArea.toStringAsFixed(1)} м²';
      }
      final dSum = SafeConverters.toDoubleOrNull(raw['sum'] ?? raw['price'] ?? existing.sum);
      if (dSum != null && dSum > 0) {
        _totalPrice = dSum;
        _totalPriceController.text = dSum.toStringAsFixed(0);
      }

      final dealTypeRaw = (raw['deal_type'] ?? raw['dealType'] ?? raw['payment_type'] ?? '').toString().toLowerCase().trim();
      if (dealTypeRaw == 'installment' || dealTypeRaw == 'рассрочка') {
        _selectedDealType = DealType.installment;
      } else if (dealTypeRaw == 'mixed' || dealTypeRaw == 'смешанные' || dealTypeRaw == 'бартер') {
        _selectedDealType = DealType.mixed;
      } else {
        _selectedDealType = DealType.cash;
      }

      final down = SafeConverters.toDoubleOrNull(raw['down_payment']);
      if (down != null && down > 0) {
        _downPaymentController.text = down.toStringAsFixed(0);
      }

      final months = SafeConverters.toIntOrNull(raw['installment_months']);
      if (months != null && months > 0) {
        _monthsController.text = months.toString();
      }

      final firstDate = raw['first_payment_date'];
      if (firstDate != null && firstDate.toString().isNotEmpty && firstDate.toString() != 'null') {
        _firstPaymentDateController.text = _formatDateForUi(firstDate);
      }

      final barterAmt = SafeConverters.toDoubleOrNull(raw['barter_amount']);
      if (barterAmt != null && barterAmt > 0) {
        _barterAmountController.text = barterAmt.toStringAsFixed(0);
      }
      _barterNoteController.text = (raw['barter_note'] ?? '').toString();
    }

    _recalculateInstallment();
    _loadOrderMeta();
    _loadDealFieldLayout();
  }

  Future<void> _onLeadSelected(LeadData lead) async {
    var phone = (lead.phone ?? '').trim();
    String? birthday;
    if (phone.isEmpty) {
      try {
        final card = await ApiService().getLeadById(lead.id);
        if (!mounted) return;
        final cardPhone = (card.phone ?? '').trim();
        final whatsApp = (card.whatsApp ?? '').trim();
        phone = cardPhone.isNotEmpty ? cardPhone : whatsApp;
        birthday = card.birthday;
      } catch (_) {}
    }
    if (!mounted) return;

    final parsed = parsePhoneCountryAndNumber(phone);
    final localPhone = parsed.localNumber;
    setState(() {
      _selectedLeadId = lead.id.toString();
      if (_ownerFullNameController.text.trim().isEmpty && lead.name.trim().isNotEmpty) {
        _ownerFullNameController.text = lead.name;
        _missingFields.remove('ownerFullName');
      }
      if (localPhone.isNotEmpty) {
        _phoneCountry = parsed.country ?? _phoneCountry;
        final dial = parsed.country?.dialCode ?? '';
        _formattedPhone = dial.isNotEmpty ? '$dial$localPhone' : localPhone;
        _phoneRevision++;
        _missingFields.remove('phone');
      }
      if (_birthDateController.text.trim().isEmpty) {
        final birthText = _formatBirthDate(birthday);
        if (birthText != null) _birthDateController.text = birthText;
      }
      if (lead.managerId != null) {
        _selectedManagerId = lead.managerId.toString();
      }
    });
    if (localPhone.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _phoneController.text = localPhone;
      });
    }
  }

  String? _formatBirthDate(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty || value.toLowerCase() == 'null') return null;
    final iso = DateTime.tryParse(value);
    if (iso != null) {
      final dt = iso.isUtc ? iso.toLocal() : iso;
      return DateFormat('dd/MM/yyyy').format(dt);
    }
    for (final pattern in ['dd.MM.yyyy', 'dd/MM/yyyy', 'yyyy-MM-dd']) {
      try {
        return DateFormat('dd/MM/yyyy').format(DateFormat(pattern).parseStrict(value));
      } catch (_) {}
    }
    return null;
  }

  DateTime? _parseUiDate(String text) {
    final value = text.trim();
    if (value.isEmpty) return null;
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(value);
    } catch (_) {
      return null;
    }
  }

  String? _apiDateFrom(TextEditingController controller) {
    final date = _parseUiDate(controller.text);
    if (date == null) return null;
    return DateFormat('yyyy-MM-dd').format(date);
  }

  double _money(TextEditingController controller) {
    return double.tryParse(controller.text.replaceAll(' ', '').replaceAll(',', '.')) ?? 0;
  }

  double get _barterAmount =>
      _selectedDealType == DealType.mixed ? _money(_barterAmountController) : 0;

  double get _payableAmount => (_totalPrice - _barterAmount).clamp(0.0, double.infinity);

  Future<void> _loadOrderMeta() async {
    try {
      final api = ApiService();
      final statuses = await api.getOrderStatuses();
      final currencies = await api.getCurrencies();
      final savedCurrencyId = await LocalizationService.getCurrencyId();
      if (!mounted) return;

      SupplierCurrency? currency;
      final targetCurrencyId = widget.existingOrder != null
          ? (SafeConverters.toIntOrNull(widget.existingOrder!.rawJson?['currency_id']) ?? savedCurrencyId)
          : savedCurrencyId;
      if (targetCurrencyId != null) {
        for (final item in currencies) {
          if (item.id == targetCurrencyId) {
            currency = item;
            break;
          }
        }
      }
      currency ??= currencies.isNotEmpty ? currencies.first : null;

      setState(() {
        _orderStatuses = statuses;
        if (widget.existingOrder != null) {
          _selectedStatusId = widget.existingOrder!.orderStatus.id;
        } else {
          _selectedStatusId = statuses.isNotEmpty ? statuses.first.id : null;
        }
        _currencies = currencies.where((item) => item.id != null).toList();
        _selectedCurrency = currency;
        _loadingMeta = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMeta = false);
    }
  }

  String _currencyTitle(SupplierCurrency? currency) {
    final name = currency?.name?.trim() ?? '';
    if (name.isNotEmpty) return name;
    return currency?.symbolCode?.trim() ?? '';
  }

  order_api.OrderStatus? get _selectedOrderStatus {
    for (final status in _orderStatuses) {
      if (status.id == _selectedStatusId) return status;
    }
    return null;
  }

  @override
  void dispose() {
    _ownerFullNameController.dispose();
    _phoneController.dispose();
    _passportSeriesNumberController.dispose();
    _passportIssuePlaceController.dispose();
    _innController.dispose();
    _addressController.dispose();
    _issueDateController.dispose();
    _expiryDateController.dispose();
    _birthDateController.dispose();
    _firstPaymentDateController.dispose();
    _barterAmountController.dispose();
    _barterNoteController.dispose();
    _pricePerSqmController.dispose();
    _totalAreaController.dispose();
    _totalPriceController.dispose();
    _downPaymentController.dispose();
    _monthsController.dispose();
    _installmentSumController.dispose();
    _monthlyPaymentController.dispose();
    for (final field in _crmFields) {
      field.dispose();
    }
    super.dispose();
  }

  bool _fieldActive(String key) {
    for (final slot in _fieldSlots) {
      if (slot.key == key) return slot.active;
    }
    return true;
  }

  Future<void> _loadDealFieldLayout() async {
    List<_DealFormSlot> saved = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_fieldLayoutKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          saved = decoded
              .whereType<Map>()
              .map((item) => _DealFormSlot.fromJson(Map<String, dynamic>.from(item)))
              .where((slot) => slot.key.isNotEmpty)
              .toList();
        }
      }
    } catch (_) {}

    List<FieldConfiguration> configs = [];
    try {
      final response = await _apiService.getFieldPositions(tableName: _fieldTable);
      configs = response.result.where((field) => field.isCustomField || field.isDirectory).toList()
        ..sort((a, b) => a.position.compareTo(b.position));
    } catch (error) {
      debugPrint('OrderCreateSheet fields: $error');
    }
    if (!mounted) return;

    final builtinTitles = {for (final field in _builtinFields) field.$1: field.$2};
    final customByKey = <String, FieldConfiguration>{
      for (final config in configs) 'crm_${config.id}': config,
    };
    final merged = <_DealFormSlot>[];
    final seen = <String>{};

    for (final slot in saved) {
      if (builtinTitles.containsKey(slot.key)) {
        merged.add(_DealFormSlot(key: slot.key, title: builtinTitles[slot.key]!, active: slot.active));
        seen.add(slot.key);
      } else if (customByKey.containsKey(slot.key)) {
        final config = customByKey[slot.key]!;
        merged.add(_DealFormSlot(
          key: slot.key,
          title: config.fieldName,
          active: slot.active,
          custom: true,
          directory: config.isDirectory,
          configId: config.id,
        ));
        seen.add(slot.key);
      }
    }

    for (final field in _builtinFields) {
      if (seen.contains(field.$1)) continue;
      merged.add(_DealFormSlot(key: field.$1, title: field.$2, active: true));
    }
    for (final config in configs) {
      final key = 'crm_${config.id}';
      if (seen.contains(key)) continue;
      merged.add(_DealFormSlot(
        key: key,
        title: config.fieldName,
        active: config.isActive,
        custom: true,
        directory: config.isDirectory,
        configId: config.id,
      ));
    }

    setState(() {
      _fieldConfigurations = configs;
      _fieldSlots = merged;
      if (widget.existingOrder != null) {
        for (final cf in widget.existingOrder!.customFieldValues) {
          final keyName = cf.customField?.name;
          final field = _crmFields.cast<crm_fields.CustomField?>().firstWhere(
                (f) => f?.fieldName == keyName,
                orElse: () => null,
              );
          if (field != null && field.controller.text.isEmpty) {
            field.controller.text = cf.value;
          }
        }
        for (final dv in widget.existingOrder!.directoryValues) {
          final dirId = dv.entry.directory.id;
          final field = _crmFields.cast<crm_fields.CustomField?>().firstWhere(
                (f) => f?.directoryId == dirId,
                orElse: () => null,
              );
          if (field != null && field.controller.text.isEmpty) {
            field.controller.text = dv.entry.id.toString();
          }
        }
      }
    });
  }

  Future<void> _persistFieldSlots() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fieldLayoutKey, jsonEncode(_fieldSlots.map((slot) => slot.toJson()).toList()));
  }

  Future<void> _toggleFieldSettings() async {
    if (_isSettingsMode) {
      final backup = _fieldSlotsBackup;
      setState(() {
        if (backup != null) _fieldSlots = backup;
        _fieldSlotsBackup = null;
        _isSettingsMode = false;
      });
      return;
    }
    setState(() {
      _fieldSlotsBackup = _fieldSlots.map((slot) => slot.copyWith()).toList();
      _isSettingsMode = true;
    });
  }

  Future<void> _saveFieldOrder() async {
    setState(() => _isSavingFieldOrder = true);
    try {
      await _persistFieldSlots();
      if (!mounted) return;
      setState(() {
        _fieldSlotsBackup = null;
        _isSettingsMode = false;
      });
      showCustomSnackBar(
        context: context,
        message: context.tr('field_settings_saved', fallback: 'Настройки полей сохранены'),
        isSuccess: true,
      );
    } finally {
      if (mounted) setState(() => _isSavingFieldOrder = false);
    }
  }

  crm_fields.CustomField _crmFieldFor(_DealFormSlot slot) {
    final config = _fieldConfigurations.cast<FieldConfiguration?>().firstWhere(
          (field) => field?.id == slot.configId,
          orElse: () => null,
        );
    if (slot.directory && slot.configId != null) {
      final existing = _crmFields.cast<crm_fields.CustomField?>().firstWhere(
            (field) => field?.directoryId == config?.directoryId,
            orElse: () => null,
          );
      if (existing != null) return existing;
      final created = crm_fields.CustomField(
        fieldName: slot.title,
        isDirectoryField: true,
        directoryId: config?.directoryId,
        controller: TextEditingController(),
      );
      _crmFields.add(created);
      return created;
    }

    final existing = _crmFields.cast<crm_fields.CustomField?>().firstWhere(
          (field) => field?.isCustomField == true && field?.fieldName == slot.title,
          orElse: () => null,
        );
    if (existing != null) return existing;
    final created = crm_fields.CustomField(
      fieldName: slot.title,
      controller: TextEditingController(),
      type: config?.type,
      isCustomField: true,
    );
    _crmFields.add(created);
    return created;
  }

  Future<void> _addDealField(
    String fieldName, {
    bool isDirectory = false,
    int? directoryId,
    String? type,
  }) async {
    if (isDirectory && directoryId != null) {
      final alreadyAdded = _fieldConfigurations.any((field) => field.isDirectory && field.directoryId == directoryId);
      if (alreadyAdded) {
        showCustomSnackBar(
          context: context,
          message: context.tr('directory_already_added', fallback: 'Справочник уже добавлен'),
          isSuccess: false,
        );
        return;
      }
      try {
        final organizationId = await _apiService.getSelectedOrganization();
        await _apiService.linkDirectory(
          directoryId: directoryId,
          modelType: 'order',
          organizationId: organizationId?.toString() ?? '',
        );
        if (!mounted) return;
        showCustomSnackBar(
          context: context,
          message: context.tr('directory_added', fallback: 'Справочник успешно добавлен'),
          isSuccess: true,
        );
        await _reloadFieldsKeepingOrder();
      } catch (error) {
        if (!mounted) return;
        showCustomSnackBar(context: context, message: error.toString(), isSuccess: false);
      }
      return;
    }

    try {
      await _apiService.addNewField(
        tableName: _fieldTable,
        fieldName: fieldName,
        fieldType: type ?? 'string',
      );
      if (!mounted) return;
      await _reloadFieldsKeepingOrder();
    } catch (error) {
      if (!mounted) return;
      showCustomSnackBar(
        context: context,
        message: '${context.tr('add_field_error', fallback: 'Ошибка при добавлении поля')}: $error',
        isSuccess: false,
      );
    }
  }

  Future<void> _reloadFieldsKeepingOrder() async {
    final previous = _fieldSlots.map((slot) => slot.copyWith()).toList();
    await _loadDealFieldLayout();
    if (!mounted) return;
    final fresh = {for (final slot in _fieldSlots) slot.key: slot};
    final merged = <_DealFormSlot>[];
    final seen = <String>{};
    for (final slot in previous) {
      final next = fresh[slot.key];
      if (next == null) continue;
      merged.add(next.copyWith(active: slot.active));
      seen.add(slot.key);
    }
    for (final slot in _fieldSlots) {
      if (seen.add(slot.key)) merged.add(slot);
    }
    setState(() => _fieldSlots = merged);
  }

  Future<void> _showAddFieldMenu() async {
    final box = _addFieldButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    var position = const RelativeRect.fromLTRB(24, 120, 24, 0);
    if (box != null && overlay != null) {
      final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
      position = RelativeRect.fromLTRB(
        topLeft.dx,
        topLeft.dy + box.size.height + 8,
        overlay.size.width - topLeft.dx - box.size.width,
        overlay.size.height - topLeft.dy - box.size.height,
      );
    }

    final choice = await showMenu<String>(
      context: context,
      position: position,
      color: context.appColors.fieldBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          value: 'manual',
          child: Text(
            context.tr('manual_input', fallback: 'Ручной ввод'),
            style: TextStyle(fontFamily: 'Gilroy', fontSize: 16, fontWeight: FontWeight.w500, color: context.appColors.textPrimary),
          ),
        ),
        PopupMenuItem(
          value: 'directory',
          child: Text(
            context.tr('directory', fallback: 'Справочник'),
            style: TextStyle(fontFamily: 'Gilroy', fontSize: 16, fontWeight: FontWeight.w500, color: context.appColors.textPrimary),
          ),
        ),
      ],
    );
    if (!mounted || choice == null) return;

    if (choice == 'manual') {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AddCustomFieldDialog(
          onAddField: (name, {String? type}) {
            if (type != null) _addDealField(name, type: type);
          },
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AddCustomDirectoryDialog(
        onAddDirectory: (directory) {
          _addDealField(directory.name, isDirectory: true, directoryId: directory.id);
        },
      ),
    );
  }

  void _onPricePerSqmChanged() {
    final sqPrice = double.tryParse(_pricePerSqmController.text.replaceAll(' ', '')) ?? 0;
    if (_totalArea > 0) {
      _totalPrice = sqPrice * _totalArea;
      _totalPriceController.text = _totalPrice > 0 ? _totalPrice.toStringAsFixed(0) : '';
    }
    setState(_recalculateInstallment);
  }

  void _onTotalPriceChanged() {
    final tp = double.tryParse(_totalPriceController.text.replaceAll(' ', '')) ?? 0;
    _totalPrice = tp;
    if (_totalArea > 0) {
      final sqPrice = tp / _totalArea;
      _pricePerSqmController.text = sqPrice > 0 ? sqPrice.toStringAsFixed(0) : '';
    }
    setState(_recalculateInstallment);
  }

  void _recalculateInstallment() {
    final down = _money(_downPaymentController);
    final months = int.tryParse(_monthsController.text.replaceAll(' ', '')) ?? 0;
    final base = _selectedDealType == DealType.cash ? _totalPrice : _payableAmount;

    _installmentSum = (base - down).clamp(0.0, double.infinity);
    _monthlyPayment = months > 0 ? (_installmentSum / months) : 0;

    _installmentSumController.text =
        _installmentSum > 0 ? _installmentSum.toStringAsFixed(0) : '0';
    _monthlyPaymentController.text =
        _monthlyPayment > 0 ? _monthlyPayment.toStringAsFixed(2) : '0';
  }

  List<Widget> _visibleDealFields(dynamic colors) {
    final widgets = <Widget>[];
    for (final slot in _fieldSlots.where((item) => item.active)) {
      final field = slot.custom ? _customDealField(slot) : _builtinDealField(slot.key, colors);
      if (field == null) continue;
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 14));
      widgets.add(field);
    }
    return widgets;
  }

  Widget? _customDealField(_DealFormSlot slot) {
    final field = _crmFieldFor(slot);
    if (slot.directory && field.directoryId != null) {
      return MainFieldDropdownWidget(
        directoryId: field.directoryId!,
        directoryName: slot.title,
        selectedField: null,
        controller: field.controller,
        initialEntryIds: field.selectedEntryIds,
        onSelectField: (List<MainField> selected) {
          final index = _crmFields.indexWhere((item) => item.directoryId == field.directoryId);
          if (index == -1) return;
          setState(() => _crmFields[index] = _crmFields[index].withDirectorySelection(selected));
        },
        onSelectEntryId: (List<int> entryIds) {
          final index = _crmFields.indexWhere((item) => item.directoryId == field.directoryId);
          if (index == -1) return;
          setState(() => _crmFields[index] = _crmFields[index].copyWith(entryIds: entryIds));
        },
      );
    }
    return CustomFieldWidget(
      fieldName: slot.title,
      valueController: field.controller,
      type: field.type,
      isCustomField: true,
    );
  }

  Widget? _builtinDealField(String key, dynamic colors) {
    switch (key) {
      case 'client':
        return LeadWithManager(
          selectedLead: _selectedLeadId,
          alwaysRefreshFromServer: true,
          hasError: _missingFields.contains('lead') || _missingFields.contains('client'),
          onSelectLead: _onLeadSelected,
        );
      case 'manager':
        return ManagerForLead(
          selectedManager: _selectedManagerId,
          onSelectManager: (manager) {
            setState(() {
              _selectedManagerId = manager.id.toString();
              _selectedManagerName = manager.name;
            });
          },
        );
      case 'status':
        return _buildOptionDropdown(
          label: 'Статус',
          hint: _loadingMeta ? 'Загрузка статусов...' : 'Выберите статус',
          items: _orderStatuses.map((status) => _PickOption(status.id.toString(), status.name)).toList(),
          selectedKey: _selectedStatusId?.toString(),
          onChanged: (value) => setState(() => _selectedStatusId = int.tryParse(value)),
        );
      case 'owner':
        return RequiredFieldSlot(
          invalid: _missingFields.contains('ownerFullName'),
          focus: _firstMissingField == 'ownerFullName',
          pulse: _fieldErrorPulse,
          message: 'Укажите ФИО собственника',
          child: CustomTextField(
            controller: _ownerFullNameController,
            hintText: 'Введите ФИО собственника',
            label: 'ФИО собственника *',
            hasError: _missingFields.contains('ownerFullName'),
            onChanged: (val) {
              if (val.trim().isNotEmpty && _missingFields.contains('ownerFullName')) {
                setState(() {
                  _missingFields.remove('ownerFullName');
                  if (_firstMissingField == 'ownerFullName') _firstMissingField = null;
                });
              }
            },
          ),
        );
      case 'phone':
        return RequiredFieldSlot(
          invalid: _missingFields.contains('phone'),
          focus: _firstMissingField == 'phone',
          pulse: _fieldErrorPulse,
          message: 'Укажите номер телефона',
          child: CustomPhoneNumberInput(
            key: ValueKey('phone-$_phoneRevision-${_phoneCountry?.dialCode ?? ''}'),
            controller: _phoneController,
            label: 'Телефон *',
            initialCountry: _phoneCountry,
            onInputChanged: (val) {
              _formattedPhone = val;
              if (val.trim().isNotEmpty && _missingFields.contains('phone')) {
                setState(() {
                  _missingFields.remove('phone');
                  if (_firstMissingField == 'phone') _firstMissingField = null;
                });
              }
            },
          ),
        );
      case 'gender':
        return _buildOptionDropdown(
          label: 'Пол',
          hint: 'Выберите пол',
          items: const [
            _PickOption('m', 'М'),
            _PickOption('f', 'Ж'),
          ],
          selectedKey: _selectedGender,
          onChanged: (value) => setState(() => _selectedGender = value),
        );
      case 'passport':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Паспортные данные и идентификация',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            RequiredFieldSlot(
              invalid: _missingFields.contains('passport'),
              focus: _firstMissingField == 'passport',
              pulse: _fieldErrorPulse,
              message: 'Укажите серию и номер паспорта',
              child: CustomTextField(
                controller: _passportSeriesNumberController,
                hintText: 'например: AA 1234567',
                label: 'Паспорт (серия и номер) *',
                hasError: _missingFields.contains('passport'),
                onChanged: (val) {
                  if (val.trim().isNotEmpty && _missingFields.contains('passport')) {
                    setState(() {
                      _missingFields.remove('passport');
                      if (_firstMissingField == 'passport') _firstMissingField = null;
                    });
                  }
                },
              ),
            ),
          ],
        );
      case 'issue_place':
        return CustomTextField(
          controller: _passportIssuePlaceController,
          hintText: 'Кем выдан паспорт',
          label: 'Место выдачи',
        );
      case 'inn':
        return CustomTextField(
          controller: _innController,
          hintText: 'Введите ИНН / ПИНФЛ',
          label: 'ИНН',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        );
      case 'address':
        return CustomTextField(
          controller: _addressController,
          hintText: 'Введите адрес проживания',
          label: 'Адрес проживания',
        );
      case 'passport_dates':
        return Row(
          children: [
            Expanded(
              child: CustomTextFieldDate(
                controller: _issueDateController,
                label: 'Дата выдачи',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomTextFieldDate(
                controller: _expiryDateController,
                label: 'Срок действия',
              ),
            ),
          ],
        );
      case 'birth':
        return CustomTextFieldDate(
          controller: _birthDateController,
          label: 'Дата рождения собственника',
        );
      case 'price_area':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Параметры объекта и оплаты',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _pricePerSqmController,
                    hintText: 'Цена за м²',
                    label: 'Цена за квадрат',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _onPricePerSqmChanged(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomTextField(
                    controller: _totalAreaController,
                    hintText: 'Общая площадь',
                    label: 'Общая площадь',
                    readOnly: true,
                  ),
                ),
              ],
            ),
          ],
        );
      case 'deal_type':
        return _buildOptionDropdown(
          label: 'Тип сделки',
          hint: 'Выберите тип сделки',
          items: const [
            _PickOption('cash', 'Наличными'),
            _PickOption('installment', 'Рассрочка'),
            _PickOption('mixed', 'Смешанные'),
          ],
          selectedKey: switch (_selectedDealType) {
            DealType.cash => 'cash',
            DealType.installment => 'installment',
            DealType.mixed => 'mixed',
          },
          onChanged: (value) {
            setState(() {
              _selectedDealType = switch (value) {
                'installment' => DealType.installment,
                'mixed' => DealType.mixed,
                _ => DealType.cash,
              };
              _recalculateInstallment();
            });
          },
        );
      case 'sum':
        return CustomTextField(
          controller: _totalPriceController,
          hintText: 'Общая сумма',
          label: 'Сумма',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => _onTotalPriceChanged(),
        );
      case 'barter':
        if (_selectedDealType != DealType.mixed) return null;
        return Column(
          children: [
            CustomTextField(
              controller: _barterAmountController,
              hintText: '0',
              label: 'Оценка бартера',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(_recalculateInstallment),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _barterNoteController,
              hintText: 'Старая квартира, машина',
              label: 'Что отдают в бартер',
            ),
          ],
        );
      case 'installment':
        if (_selectedDealType == DealType.cash) return null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              controller: _downPaymentController,
              hintText: '0',
              label: 'Первоначальный взнос',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(_recalculateInstallment),
            ),
            const SizedBox(height: 14),
            RequiredFieldSlot(
              invalid: _missingFields.contains('months'),
              focus: _firstMissingField == 'months',
              pulse: _fieldErrorPulse,
              message: 'Укажите срок в месяцах',
              child: CustomTextField(
                controller: _monthsController,
                hintText: '12',
                label: _installmentSum > 0 ? 'Срок рассрочки (мес.) *' : 'Срок рассрочки (мес.)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                hasError: _missingFields.contains('months'),
                onChanged: (val) {
                  if (val.trim().isNotEmpty && _missingFields.contains('months')) {
                    setState(() => _missingFields.remove('months'));
                  }
                  setState(_recalculateInstallment);
                },
              ),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _installmentSumController,
              hintText: '0',
              label: 'Сумма рассрочки',
              readOnly: true,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _monthlyPaymentController,
              hintText: '0',
              label: 'Ежемесячная оплата',
              readOnly: true,
            ),
            const SizedBox(height: 14),
            RequiredFieldSlot(
              invalid: _missingFields.contains('firstPayment'),
              focus: _firstMissingField == 'firstPayment',
              pulse: _fieldErrorPulse,
              message: 'Укажите дату первого платежа',
              child: CustomTextFieldDate(
                controller: _firstPaymentDateController,
                label: _installmentSum > 0 ? 'Дата первого платежа *' : 'Дата первого платежа',
                hasError: _missingFields.contains('firstPayment'),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _openSchedulePreview,
                child: Text(
                  'График платежей',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: colors.buttonPrimaryBg,
                  ),
                ),
              ),
            ),
          ],
        );
      default:
        return null;
    }
  }

  Widget _buildDealFieldSettings() {
    final colors = context.appColors;
    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: _fieldSlots.length + 1,
            onReorder: (oldIndex, newIndex) {
              if (oldIndex >= _fieldSlots.length) return;
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                if (newIndex >= _fieldSlots.length) newIndex = _fieldSlots.length - 1;
                final item = _fieldSlots.removeAt(oldIndex);
                _fieldSlots.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              if (index == _fieldSlots.length) {
                return Container(
                  key: _addFieldButtonKey,
                  margin: const EdgeInsets.only(top: 4, bottom: 8),
                  child: CustomButton(
                    buttonText: context.tr('add_field', fallback: 'Добавить поле'),
                    buttonColor: colors.fieldBg,
                    textColor: colors.buttonPrimaryBg,
                    borderColor: colors.buttonPrimaryBg,
                    borderWidth: 1.4,
                    onPressed: _showAddFieldMenu,
                  ),
                );
              }

              final slot = _fieldSlots[index];
              final locked = _lockedFieldKeys.contains(slot.key);
              final typeLabel = slot.directory
                  ? context.tr('directory', fallback: 'Справочник')
                  : slot.custom
                      ? context.tr('custom_field', fallback: 'Пользовательское поле')
                      : context.tr('system_field', fallback: 'Системное поле');
              return Container(
                key: ValueKey('chess_deal_field_${slot.key}'),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: colors.fieldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(Icons.drag_handle, color: colors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slot.title,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            typeLabel,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                          if (!locked) ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _fieldSlots[index] = slot.copyWith(active: !slot.active);
                                });
                              },
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: slot.active ? colors.buttonPrimaryBg : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: slot.active ? colors.buttonPrimaryBg : colors.borderSubtle,
                                        width: 2,
                                      ),
                                    ),
                                    child: slot.active
                                        ? Icon(Icons.check_rounded, size: 16, color: colors.textInverse)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    context.tr('show_field', fallback: 'Показать поле'),
                                    style: TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: CustomButton(
            buttonText: _isSavingFieldOrder
                ? context.tr('saving', fallback: 'Сохранение...')
                : context.tr('save', fallback: 'Сохранить'),
            buttonColor: colors.buttonPrimaryBg,
            textColor: colors.buttonPrimaryFg,
            onPressed: _isSavingFieldOrder ? () {} : _saveFieldOrder,
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final apt = widget.apartment;
    final park = widget.parking;

    final unitTitle = apt != null
        ? 'Кв. № ${apt.displayNumber}'
        : (park != null ? 'Паркинг № ${park.number}' : 'Объект');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSettingsMode
                            ? context.tr('field_settings', fallback: 'Настройка полей')
                            : 'Сделка',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (!_isSettingsMode) ...[
                        const SizedBox(height: 2),
                        Text(
                          '$unitTitle · ${_totalPrice.toStringAsFixed(0)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: colors.buttonPrimaryBg,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: _isSettingsMode
                      ? context.tr('close', fallback: 'Закрыть')
                      : context.tr('settings', fallback: 'Настройки'),
                  onPressed: _toggleFieldSettings,
                  icon: Icon(
                    _isSettingsMode ? Icons.close_rounded : Icons.settings_rounded,
                    color: colors.iconSecondary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: colors.iconSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _isSettingsMode
                ? _buildDealFieldSettings()
                : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._visibleDealFields(colors),
                  const SizedBox(height: 8),
                  _buildFileAttachment(colors),
                  const SizedBox(height: 16),
                  CustomButton(
                    buttonText: _saving ? 'Сохранение...' : 'Сохранить',
                    buttonColor: colors.buttonPrimaryBg,
                    textColor: colors.buttonPrimaryFg,
                    isLoading: _saving,
                    onPressed: _saving ? null : _handleSubmit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionDropdown({
    required String label,
    required String hint,
    required List<_PickOption> items,
    required String? selectedKey,
    required ValueChanged<String> onChanged,
  }) {
    final colors = context.appColors;
    _PickOption? selected;
    for (final item in items) {
      if (item.key == selectedKey) {
        selected = item;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.appTextStyles.bodyMd.copyWith(
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<_PickOption>.search(
          key: ValueKey('$label-${selected?.key}-${items.length}'),
          items: items,
          initialItem: selected,
          enabled: items.isNotEmpty,
          excludeSelected: false,
          canClear: false,
          overlayHeight: 280,
          searchHintText: 'Поиск',
          noResultFoundText: 'Ничего не найдено',
          listItemPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          closedHeaderPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: AppFieldStyle.dropdownDecoration(context),
          listItemBuilder: (context, item, isSelected, onItemSelect) => Text(
            item.title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
            ),
          ),
          headerBuilder: (context, selectedItem, enabled) => Text(
            selectedItem.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: colors.textPrimary,
            ),
          ),
          hintBuilder: (context, hintText, enabled) => Text(
            items.isEmpty ? hint : hint,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: colors.textSecondary,
            ),
          ),
          onChanged: (value) {
            if (value != null) onChanged(value.key);
          },
        ),
      ],
    );
  }

  // Поле валюты в шахматке пока скрыто.
  // ignore: unused_element
  Widget _buildCurrencyDropdown() {
    final colors = context.appColors;
    SupplierCurrency? selected;
    for (final currency in _currencies) {
      if (currency.id != null && currency.id == _selectedCurrency?.id) {
        selected = currency;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Тип валюты',
          style: context.appTextStyles.bodyMd.copyWith(
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        if (_loadingMeta)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: colors.fieldBg,
              borderRadius: AppFieldStyle.radius,
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Text(
              'Загрузка...',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
          )
        else
          CustomDropdown<SupplierCurrency>.search(
            key: ValueKey('currency-${selected?.id}-${_currencies.length}'),
            items: _currencies,
            initialItem: selected,
            enabled: _currencies.isNotEmpty,
            excludeSelected: false,
            canClear: false,
            overlayHeight: 280,
            searchHintText: 'Поиск',
            noResultFoundText: 'Ничего не найдено',
            listItemPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            closedHeaderPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: AppFieldStyle.dropdownDecoration(context),
            listItemBuilder: (context, item, isSelected, onItemSelect) => Text(
              _currencyTitle(item),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
              ),
            ),
            headerBuilder: (context, selectedItem, enabled) => Text(
              _currencyTitle(selectedItem),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textPrimary,
              ),
            ),
            hintBuilder: (context, hint, enabled) => Text(
              'Выберите валюту',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textSecondary,
              ),
            ),
            onChanged: (value) {
              if (value != null) setState(() => _selectedCurrency = value);
            },
          ),
      ],
    );
  }

  void _openSchedulePreview() {
    final previewOrder = Order(
      id: 'Предпросмотр',
      complexId: widget.apartment?.complexId ?? widget.parking?.complexId ?? 1,
      apartmentId: widget.apartment?.id,
      parkingId: widget.parking?.id,
      buyerName: _ownerFullNameController.text.trim().isNotEmpty
          ? _ownerFullNameController.text.trim()
          : 'Собственник',
      buyerPhone: _formattedPhone.isNotEmpty ? _formattedPhone : _phoneController.text.trim(),
      buyerEmail: '',
      manager: _selectedManagerName ?? 'Менеджер',
      dealType: _selectedDealType,
      price: _totalPrice,
      status: OrderStatus.inProgress,
      paymentDetails: PaymentDetails(
        downPayment: double.tryParse(_downPaymentController.text) ?? 0,
        months: int.tryParse(_monthsController.text) ?? 12,
        installmentSum: _installmentSum,
        monthlyPayment: _monthlyPayment,
        schedule: PaymentDetails.generateSchedule(
          totalInstallmentSum: _installmentSum,
          months: int.tryParse(_monthsController.text) ?? 0,
          firstDueDate: _parseUiDate(_firstPaymentDateController.text),
        ),
      ),
    );
    PaymentScheduleSheet.show(context: context, order: previewOrder);
  }

  Future<void> _pickDealFile() async {
    final totalSize = _attachedFiles.fold<double>(0, (sum, file) {
      if (file.path.startsWith('http://') || file.path.startsWith('https://')) {
        return sum;
      }
      final local = File(file.path);
      if (!local.existsSync()) return sum;
      return sum + local.lengthSync() / (1024 * 1024);
    });

    final pickedFiles = await FilePickerDialog.show(
      context: context,
      allowMultiple: true,
      maxSizeMB: 50,
      currentTotalSizeMB: totalSize,
      fileLabel: context.tr('file', fallback: 'Файл'),
      galleryLabel: context.tr('gallery', fallback: 'Галерея'),
      cameraLabel: context.tr('camera', fallback: 'Камера'),
      cancelLabel: context.tr('cancel', fallback: 'Отмена'),
      fileSizeTooLargeMessage: context.tr('file_size_too_large', fallback: 'Файл слишком большой'),
      errorPickingFileMessage: context.tr('error_picking_file', fallback: 'Не удалось выбрать файл'),
    );

    if (pickedFiles == null || pickedFiles.isEmpty || !mounted) return;
    setState(() {
      for (final file in pickedFiles) {
        _attachedFiles.add(FileHelper(
          id: 0,
          name: file.name,
          path: file.path,
          size: file.sizeKB,
        ));
      }
    });
  }

  Widget _buildFileAttachment(dynamic colors) {
    final fileCardColor = colors.fieldBg;
    final fileTextColor = colors.textPrimary;
    final fileBorderColor = colors.borderSubtle;
    final addFileIconAsset = ThemeData.estimateBrightnessForColor(fileCardColor) == Brightness.dark
        ? 'assets/icons/files/add_for_dark.png'
        : 'assets/icons/files/add.png';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('file', fallback: 'Файл'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: fileTextColor,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _attachedFiles.isEmpty ? 1 : _attachedFiles.length + 1,
            itemBuilder: (context, index) {
              if (_attachedFiles.isEmpty || index == _attachedFiles.length) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: _saving ? null : _pickDealFile,
                    child: Container(
                      width: 100,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: fileCardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: fileBorderColor),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ColorFiltered(
                            colorFilter: ColorFilter.mode(fileTextColor, BlendMode.srcIn),
                            child: Image.asset(addFileIconAsset, width: 54, height: 54),
                          ),
                          const SizedBox(height: 6),
                          Flexible(
                            child: Text(
                              context.tr('add_file', fallback: 'Загрузить файл'),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Gilroy',
                                color: fileTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final fileName = _attachedFiles[index].name;
              final fileExtension = fileName.split('.').last.toLowerCase();
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: fileCardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: fileBorderColor),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Center(
                              child: buildFileIcon(_attachedFiles, fileName, fileExtension),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: Text(
                              fileName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Gilroy',
                                color: fileTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: -2,
                      top: -6,
                      child: GestureDetector(
                        onTap: _saving ? null : () => setState(() => _attachedFiles.removeAt(index)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colors.surfacePrimary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colors.shadow.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(Icons.close, size: 16, color: fileTextColor),
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

  Future<void> _handleSubmit() async {
    if (_saving) return;

    final ownerName = _ownerFullNameController.text.trim();
    final phone = _formattedPhone.isNotEmpty ? _formattedPhone : _phoneController.text.trim();
    final passport = _passportSeriesNumberController.text.trim();
    final leadId = int.tryParse(_selectedLeadId ?? '');
    final managerId = int.tryParse(_selectedManagerId ?? '');
    final currencyId = _selectedCurrency?.id;
    final isInstallment = _selectedDealType != DealType.cash;
    final down = _money(_downPaymentController);
    final months = int.tryParse(_monthsController.text.replaceAll(' ', '')) ?? 0;
    final needsSchedule = isInstallment && _installmentSum > 0;

    if (_selectedDealType == DealType.mixed && _barterAmount > _totalPrice) {
      showCustomSnackBar(
        context: context,
        message: 'Оценка бартера не может быть больше суммы сделки',
        isSuccess: false,
      );
      return;
    }
    if (isInstallment && down > _payableAmount) {
      showCustomSnackBar(
        context: context,
        message: 'Первоначальный взнос больше остатка сделки',
        isSuccess: false,
      );
      return;
    }

    final missing = <String>[];
    if (_fieldActive('owner') && ownerName.isEmpty) missing.add('ownerFullName');
    if (_fieldActive('phone') && phone.isEmpty) missing.add('phone');
    if (_fieldActive('passport') && passport.isEmpty) missing.add('passport');
    if (needsSchedule && months <= 0) missing.add('months');
    if (needsSchedule && _parseUiDate(_firstPaymentDateController.text) == null) {
      missing.add('firstPayment');
    }

    if (leadId == null || managerId == null || _selectedStatusId == null || currencyId == null || missing.isNotEmpty) {
      setState(() {
        _missingFields = missing.toSet();
        _firstMissingField = missing.isEmpty ? null : missing.first;
        _fieldErrorPulse++;
      });
      final parts = <String>[
        if (leadId == null) 'клиент',
        if (managerId == null) 'менеджер',
        if (_selectedStatusId == null) 'статус',
        if (currencyId == null) 'валюта',
        if (missing.contains('ownerFullName')) 'ФИО',
        if (missing.contains('phone')) 'телефон',
        if (missing.contains('passport')) 'паспорт',
        if (missing.contains('months')) 'срок рассрочки',
        if (missing.contains('firstPayment')) 'дата первого платежа',
      ];
      showCustomSnackBar(
        context: context,
        message: 'Заполните: ${parts.join(', ')}',
        isSuccess: false,
      );
      return;
    }

    final apartment = widget.apartment;
    if (apartment == null) {
      showCustomSnackBar(
        context: context,
        message: 'Сделку можно оформить только по квартире. Для паркинга такого метода нет.',
        isSuccess: false,
      );
      return;
    }

    if (_missingFields.isNotEmpty) {
      setState(() {
        _missingFields = {};
        _firstMissingField = null;
      });
    }

    setState(() => _saving = true);
    final sqPrice = _money(_pricePerSqmController);
    final sendSchedule = needsSchedule && months > 0;
    final issueDate = _parseUiDate(_issueDateController.text);
    final expiryDate = _parseUiDate(_expiryDateController.text);
    final birthDate = _parseUiDate(_birthDateController.text);
    final inn = int.tryParse(_innController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    final dealType = switch (_selectedDealType) {
      DealType.cash => 'cash',
      DealType.installment => 'installment',
      DealType.mixed => 'mixed',
    };

    try {
      final api = ApiService();
      var variantId = apartment.variantId;
      if (variantId == null || variantId <= 0) {
        try {
          final goods = await api.getGoodsById(apartment.id);
          final variants = goods.isNotEmpty ? goods.first.variants : null;
          if (variants != null && variants.isNotEmpty && variants.first.id > 0) {
            variantId = variants.first.id;
          }
        } catch (_) {}
      }
      if (!mounted) return;
      if (variantId != null && variantId <= 0) variantId = null;

      final integrationId = await api.resolveOrderMiniAppIntegrationId();
      if (!mounted) return;
      if (integrationId == null) {
        showCustomSnackBar(
          context: context,
          message: 'Не найдена интеграция. Без неё сервер сделку не примет.',
          isSuccess: false,
        );
        return;
      }

      final customFieldMap = <Map<String, dynamic>>[];
      final directoryValues = <Map<String, int>>[];
      for (final slot in _fieldSlots.where((item) => item.active && item.custom)) {
        final field = _crmFieldFor(slot);
        if (field.isDirectoryField && field.directoryId != null) {
          directoryValues.addAll(field.toDirectoryPayloads());
          continue;
        }
        final value = field.controller.text.trim();
        if (value.isEmpty) continue;
        var fieldType = field.type;
        if (fieldType == null || fieldType.isEmpty || fieldType == 'text') fieldType = 'string';
        customFieldMap.add({
          'key': field.fieldName,
          'value': value,
          'type': fieldType,
        });
      }

      final result = widget.isEdit
          ? await api.updateResidentialOrder(
              orderId: widget.existingOrder!.id,
              leadId: leadId,
              managerId: managerId,
              orderStatusId: _selectedStatusId!,
              integrationId: widget.existingOrder?.integrationId ?? integrationId,
              phone: phone,
              sum: _totalPrice,
              currencyId: currencyId,
              ownerName: ownerName,
              gender: _selectedGender,
              passport: passport,
              passportIssuedBy: _passportIssuePlaceController.text.trim(),
              passportIssuedAt: _apiDateFrom(_issueDateController),
              passportExpiresAt: _apiDateFrom(_expiryDateController),
              ownerBirthDate: _apiDateFrom(_birthDateController),
              inn: inn,
              residenceAddress: _addressController.text.trim(),
              goodId: apartment.id,
              variantId: variantId,
              pricePerM2: sqPrice,
              totalArea: _totalArea > 0 ? _totalArea : null,
              dealType: dealType,
              downPayment: !isInstallment
                  ? null
                  : (sendSchedule || down > 0 ? down : null),
              installmentMonths: sendSchedule ? months : null,
              firstPaymentDate: sendSchedule ? _apiDateFrom(_firstPaymentDateController) : null,
              barterAmount: _selectedDealType == DealType.mixed && _barterAmount > 0 ? _barterAmount : null,
              barterNote: _selectedDealType == DealType.mixed ? _barterNoteController.text.trim() : null,
              orderCustomFields: customFieldMap,
              directoryValues: directoryValues,
              filePaths: _attachedFiles.map((file) => file.path).toList(),
            )
          : await api.createResidentialOrder(
              leadId: leadId,
              managerId: managerId,
              orderStatusId: _selectedStatusId!,
              integrationId: integrationId,
              phone: phone,
              sum: _totalPrice,
              currencyId: currencyId,
              ownerName: ownerName,
              gender: _selectedGender,
              passport: passport,
              passportIssuedBy: _passportIssuePlaceController.text.trim(),
              passportIssuedAt: _apiDateFrom(_issueDateController),
              passportExpiresAt: _apiDateFrom(_expiryDateController),
              ownerBirthDate: _apiDateFrom(_birthDateController),
              inn: inn,
              residenceAddress: _addressController.text.trim(),
              goodId: apartment.id,
              variantId: variantId,
              pricePerM2: sqPrice,
              totalArea: _totalArea > 0 ? _totalArea : null,
              dealType: dealType,
              downPayment: !isInstallment
                  ? null
                  : (sendSchedule || down > 0 ? down : null),
              installmentMonths: sendSchedule ? months : null,
              firstPaymentDate: sendSchedule ? _apiDateFrom(_firstPaymentDateController) : null,
              barterAmount: _selectedDealType == DealType.mixed && _barterAmount > 0 ? _barterAmount : null,
              barterNote: _selectedDealType == DealType.mixed ? _barterNoteController.text.trim() : null,
              orderCustomFields: customFieldMap,
              directoryValues: directoryValues,
              filePaths: _attachedFiles.map((file) => file.path).toList(),
            );
      if (!mounted) return;
      if (result['success'] != true) {
        showCustomSnackBar(
          context: context,
          message: result['error']?.toString() ??
              (widget.isEdit ? 'Не удалось обновить сделку' : 'Не удалось создать сделку'),
          isSuccess: false,
        );
        return;
      }

      if (widget.isEdit) {
        await ChessGridController.instance.loadApartmentById(apartment);
        if (!mounted) return;
        final navigator = Navigator.of(context);
        navigator.pop({'success': true, 'statusId': _selectedStatusId});
        showCustomSnackBar(
          context: navigator.context,
          message: 'Квартира № ${apartment.displayNumber}: сделка успешно обновлена',
          isSuccess: true,
        );
        return;
      }

      final status = _selectedOrderStatus;
      final ApartmentStatus apartmentStatus;
      final OrderStatus localStatus;
      if (status?.isSuccess == true) {
        apartmentStatus = ApartmentStatus.sold;
        localStatus = OrderStatus.success;
      } else if (status?.isFailed == true || status?.canceled == true) {
        apartmentStatus = ApartmentStatus.available;
        localStatus = OrderStatus.rejected;
      } else {
        apartmentStatus = ApartmentStatus.booked;
        localStatus = OrderStatus.inProgress;
      }

      final err = ChessGridController.instance.createOrder(
        apartment: apartment,
        parking: widget.parking,
        serverOrderId: result['orderId']?.toString(),
        orderStatus: localStatus,
        fromServer: true,
        buyerName: ownerName,
        buyerPhone: phone,
        buyerEmail: '',
        roleName: _selectedManagerName ?? 'Менеджер',
        dealType: _selectedDealType,
        downPayment: isInstallment ? down : 0,
        months: isInstallment ? months : 0,
        leadId: leadId,
        managerId: _selectedManagerId,
        targetStatus: apartmentStatus,
        ownerFullName: ownerName,
        gender: _selectedGender,
        passportSeriesNumber: passport,
        passportIssuePlace: _passportIssuePlaceController.text.trim(),
        inn: inn?.toString(),
        address: _addressController.text.trim(),
        passportIssueDate: issueDate,
        passportExpiryDate: expiryDate,
        birthDate: birthDate,
        pricePerSqm: sqPrice,
        totalArea: _totalArea,
        customPrice: _totalPrice,
        currency: _currencyTitle(_selectedCurrency),
        installmentSumOverride: isInstallment ? _installmentSum : null,
        monthlyPaymentOverride: isInstallment ? _monthlyPayment : null,
      );

      if (err != null) {
        showCustomSnackBar(
          context: context,
          message: err,
          isSuccess: false,
        );
        return;
      }

      final navigator = Navigator.of(context);
      navigator.pop({'success': true, 'statusId': _selectedStatusId});
      showCustomSnackBar(
        context: navigator.context,
        message: 'Квартира № ${apartment.displayNumber}: сделка создана',
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(
        context: context,
        message: e.toString().replaceFirst('Exception: ', ''),
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
