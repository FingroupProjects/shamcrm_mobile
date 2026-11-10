import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/localization/localization_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_field_style.dart';
import 'package:crm_task_manager/custom_widget/country_data_list.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_number_input.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/models/lead/lead_list_model.dart';
import 'package:crm_task_manager/models/page_2/order_status_model.dart' as order_api;
import 'package:crm_task_manager/models/page_2/supplier_model.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/payment_schedule_sheet.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/lead_with_manager.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/manager_for_lead.dart';
import 'package:crm_task_manager/widgets/required_field_slot.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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

  const OrderCreateSheet({
    super.key,
    this.apartment,
    this.parking,
  });

  static Future<void> show({
    required BuildContext context,
    Apartment? apartment,
    ParkingSpot? parking,
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
    _recalculateInstallment();
    _loadOrderMeta();
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
    if (iso != null) return DateFormat('dd/MM/yyyy').format(iso);
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
      if (savedCurrencyId != null) {
        for (final item in currencies) {
          if (item.id == savedCurrencyId) {
            currency = item;
            break;
          }
        }
      }
      currency ??= currencies.isNotEmpty ? currencies.first : null;

      setState(() {
        _orderStatuses = statuses;
        _selectedStatusId = statuses.isNotEmpty ? statuses.first.id : null;
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
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final apt = widget.apartment;
    final park = widget.parking;

    final unitTitle = apt != null
        ? 'Кв. № ${apt.number}'
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Оформление / Сделка',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$unitTitle · ${_totalPrice.toStringAsFixed(0)} ${_currencyTitle(_selectedCurrency)}',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: colors.buttonPrimaryBg,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: colors.iconSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Form fields
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LeadWithManager(
                    selectedLead: _selectedLeadId,
                    onSelectLead: _onLeadSelected,
                  ),
                  const SizedBox(height: 14),

                  ManagerForLead(
                    selectedManager: _selectedManagerId,
                    onSelectManager: (manager) {
                      setState(() {
                        _selectedManagerId = manager.id.toString();
                        _selectedManagerName = manager.name;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildOptionDropdown(
                    label: 'Статус',
                    hint: _loadingMeta ? 'Загрузка статусов...' : 'Выберите статус',
                    items: _orderStatuses
                        .map((status) => _PickOption(status.id.toString(), status.name))
                        .toList(),
                    selectedKey: _selectedStatusId?.toString(),
                    onChanged: (key) => setState(() => _selectedStatusId = int.tryParse(key)),
                  ),
                  const SizedBox(height: 14),

                  // 4. ФИО собственника (текстовое поле ручной ввод)
                  RequiredFieldSlot(
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
                  ),
                  const SizedBox(height: 14),

                  // 5. Телефон (подставляется из лида с возможностью изменить)
                  RequiredFieldSlot(
                    invalid: _missingFields.contains('phone'),
                    focus: _firstMissingField == 'phone',
                    pulse: _fieldErrorPulse,
                    message: 'Укажите номер телефона',
                    child:                   CustomPhoneNumberInput(
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
                  ),
                  const SizedBox(height: 14),

                  _buildOptionDropdown(
                    label: 'Пол',
                    hint: 'Выберите пол',
                    items: const [
                      _PickOption('m', 'М'),
                      _PickOption('f', 'Ж'),
                    ],
                    selectedKey: _selectedGender,
                    onChanged: (key) => setState(() => _selectedGender = key),
                  ),
                  const SizedBox(height: 18),

                  // Паспортный блок
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

                  // 7. Паспорт (серии и номер) - Обязательное поле текстовое
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
                  const SizedBox(height: 14),

                  // 8. Место выдачи (текстовое)
                  CustomTextField(
                    controller: _passportIssuePlaceController,
                    hintText: 'Кем выдан паспорт',
                    label: 'Место выдачи',
                  ),
                  const SizedBox(height: 14),

                  // 9. ИНН (числовое)
                  CustomTextField(
                    controller: _innController,
                    hintText: 'Введите ИНН / ПИНФЛ',
                    label: 'ИНН',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 14),

                  // 10. Адрес проживания (текстовое)
                  CustomTextField(
                    controller: _addressController,
                    hintText: 'Введите адрес проживания',
                    label: 'Адрес проживания',
                  ),
                  const SizedBox(height: 14),

                  Row(
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
                  ),
                  const SizedBox(height: 14),

                  CustomTextFieldDate(
                    controller: _birthDateController,
                    label: 'Дата рождения собственника',
                  ),
                  const SizedBox(height: 20),

                  // Финансовый блок
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

                  // 14 & 15. Цена за квадрат (изменяемая) & Общая площадь (неизменяемая)
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
                  const SizedBox(height: 14),

                  _buildOptionDropdown(
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
                    onChanged: (key) {
                      setState(() {
                        _selectedDealType = switch (key) {
                          'installment' => DealType.installment,
                          'mixed' => DealType.mixed,
                          _ => DealType.cash,
                        };
                        _recalculateInstallment();
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: _totalPriceController,
                    hintText: 'Общая сумма',
                    label: 'Сумма',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _onTotalPriceChanged(),
                  ),
                  const SizedBox(height: 14),

                  _buildCurrencyDropdown(),

                  if (_selectedDealType == DealType.mixed) ...[
                    const SizedBox(height: 14),
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

                  if (_selectedDealType != DealType.cash) ...[
                    const SizedBox(height: 14),
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

                  const SizedBox(height: 8),
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
    if (ownerName.isEmpty) missing.add('ownerFullName');
    if (phone.isEmpty) missing.add('phone');
    if (passport.isEmpty) missing.add('passport');
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
        message: 'Бэкенд принимает заказ только по квартире: нужны good_id и variant_id. Для паркинга такого метода нет.',
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
        final goods = await api.getGoodsById(apartment.id);
        final variants = goods.isNotEmpty ? goods.first.variants : null;
        if (variants != null && variants.isNotEmpty && variants.first.id > 0) {
          variantId = variants.first.id;
        }
      }
      if (!mounted) return;
      if (variantId == null || variantId <= 0) {
        showCustomSnackBar(
          context: context,
          message: 'У квартиры нет variant_id. Бэкенд без варианта товара заказ не примет.',
          isSuccess: false,
        );
        return;
      }

      final integrationId = await api.resolveOrderMiniAppIntegrationId();
      if (!mounted) return;
      if (integrationId == null) {
        showCustomSnackBar(
          context: context,
          message: 'Не найдена интеграция заказа (integration_id). Без неё сервер заказ не примет.',
          isSuccess: false,
        );
        return;
      }

      final result = await api.createResidentialOrder(
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
      );
      if (!mounted) return;
      if (result['success'] != true) {
        showCustomSnackBar(
          context: context,
          message: result['error']?.toString() ?? 'Не удалось создать заказ',
          isSuccess: false,
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

      Navigator.pop(context);
      showCustomSnackBar(
        context: context,
        message: err ?? 'Квартира № ${apartment.number}: заказ создан',
        isSuccess: err == null,
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
