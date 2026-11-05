import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/localization/localization_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_field_style.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_number_input.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
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
  String _selectedGender = 'm';

  // Passport & Identification
  final _passportSeriesNumberController = TextEditingController();
  final _passportIssuePlaceController = TextEditingController();
  final _innController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _passportIssueDate;
  DateTime? _passportExpiryDate;
  DateTime? _birthDate;

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

    _recalculateInstallment();
    _loadOrderMeta();
  }

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

  String? _apiDate(DateTime? date) {
    if (date == null) return null;
    return DateFormat('yyyy-MM-dd').format(date);
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
    _recalculateInstallment();
  }

  void _onTotalPriceChanged() {
    final tp = double.tryParse(_totalPriceController.text.replaceAll(' ', '')) ?? 0;
    _totalPrice = tp;
    if (_totalArea > 0) {
      final sqPrice = tp / _totalArea;
      _pricePerSqmController.text = sqPrice > 0 ? sqPrice.toStringAsFixed(0) : '';
    }
    _recalculateInstallment();
  }

  void _recalculateInstallment() {
    final down = double.tryParse(_downPaymentController.text.replaceAll(' ', '')) ?? 0;
    final months = int.tryParse(_monthsController.text.replaceAll(' ', '')) ?? 12;

    _installmentSum = (_totalPrice - down).clamp(0.0, double.infinity);
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
                  // 1. Клиент (список лидов из CRM)
                  Text(
                    'Клиент (Лид из CRM)',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  LeadWithManager(
                    selectedLead: _selectedLeadId,
                    onSelectLead: (lead) {
                      setState(() {
                        _selectedLeadId = lead.id.toString();
                        if (_ownerFullNameController.text.trim().isEmpty) {
                          _ownerFullNameController.text = lead.name;
                        }
                        if ((lead.phone ?? '').isNotEmpty) {
                          _phoneController.text = lead.phone!;
                          _formattedPhone = lead.phone!;
                        }
                        if (lead.managerId != null) {
                          _selectedManagerId = lead.managerId.toString();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  // 2. Менеджер (список менеджеров)
                  Text(
                    'Ответственный менеджер',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
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

                  // 3. Статус (выпадающий список)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Статус',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<int>(
                        key: ValueKey(_selectedStatusId),
                        initialValue: _selectedStatusId,
                        isExpanded: true,
                        isDense: true,
                        menuMaxHeight: 240,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                        dropdownColor: colors.surfacePrimary,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.iconSecondary),
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
                        hint: Text(
                          _loadingMeta ? 'Загрузка статусов...' : 'Нет статусов заказа',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 14,
                            color: colors.textSecondary,
                          ),
                        ),
                        items: _orderStatuses.map((st) {
                          return DropdownMenuItem<int>(
                            value: st.id,
                            child: Text(
                              st.name,
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: _orderStatuses.isEmpty
                            ? null
                            : (val) {
                                if (val != null) {
                                  setState(() => _selectedStatusId = val);
                                }
                              },
                      ),
                    ],
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
                    child: CustomPhoneNumberInput(
                      controller: _phoneController,
                      label: 'Номер телефона *',
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

                  // 6. Пол (М или Ж)
                  Text(
                    'Пол',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildGenderChip('m', 'Мужской (М)', Icons.male_rounded),
                      const SizedBox(width: 10),
                      _buildGenderChip('f', 'Женский (Ж)', Icons.female_rounded),
                    ],
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
                  ),
                  const SizedBox(height: 14),

                  // 10. Адрес проживания (текстовое)
                  CustomTextField(
                    controller: _addressController,
                    hintText: 'Введите адрес проживания',
                    label: 'Адрес проживания',
                  ),
                  const SizedBox(height: 14),

                  // 11 & 12. Дата выдачи и Срок действия (дата)
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          context: context,
                          label: 'Дата выдачи',
                          value: _passportIssueDate,
                          onPicked: (d) => setState(() => _passportIssueDate = d),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDateField(
                          context: context,
                          label: 'Срок действия',
                          value: _passportExpiryDate,
                          onPicked: (d) => setState(() => _passportExpiryDate = d),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 13. Дата рождения собственника (дата)
                  _buildDateField(
                    context: context,
                    label: 'Дата рождения собственника',
                    value: _birthDate,
                    onPicked: (d) => setState(() => _birthDate = d),
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

                  // 16. Тип сделки (список: наличными, рассрочка, смешанные)
                  Text(
                    'Тип сделки',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildDealChip(DealType.cash, 'Наличными'),
                      const SizedBox(width: 8),
                      _buildDealChip(DealType.installment, 'Рассрочка'),
                      const SizedBox(width: 8),
                      _buildDealChip(DealType.mixed, 'Смешанные'),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 17 & 18. Сумма (общая стоимость) & Тип валюты (доллар, сомон, сум, евро)
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: CustomTextField(
                          controller: _totalPriceController,
                          hintText: 'Общая сумма',
                          label: 'Сумма (общая стоимость)',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => _onTotalPriceChanged(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: _buildCurrencySelector(colors),
                      ),
                    ],
                  ),

                  // 19. Поля рассрочки (отображаются ТОЛЬКО при рассрочке или смешанных)
                  if (_selectedDealType != DealType.cash) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.buttonPrimaryBg.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.buttonPrimaryBg.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calculate_rounded, size: 18, color: colors.buttonPrimaryBg),
                              const SizedBox(width: 6),
                              Text(
                                'Параметры рассрочки',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Первоначальный взнос & Срок рассрочки (в месяцах)
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: _downPaymentController,
                                  hintText: '0',
                                  label: 'Первоначальный взнос',
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(_recalculateInstallment),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RequiredFieldSlot(
                                  invalid: _missingFields.contains('months'),
                                  focus: _firstMissingField == 'months',
                                  pulse: _fieldErrorPulse,
                                  message: 'Укажите срок',
                                  child: CustomTextField(
                                    controller: _monthsController,
                                    hintText: '12',
                                    label: 'Срок рассрочки (мес.) *',
                                    keyboardType: TextInputType.number,
                                    hasError: _missingFields.contains('months'),
                                    onChanged: (val) {
                                      if (val.trim().isNotEmpty && _missingFields.contains('months')) {
                                        setState(() => _missingFields.remove('months'));
                                      }
                                      setState(_recalculateInstallment);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Сумма рассрочки & Ежемесячная оплата
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: _installmentSumController,
                                  hintText: '0',
                                  label: 'Сумма рассрочки',
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    final sum = double.tryParse(val.replaceAll(' ', '')) ?? 0;
                                    _installmentSum = sum;
                                    final m = int.tryParse(_monthsController.text) ?? 12;
                                    _monthlyPayment = m > 0 ? (_installmentSum / m) : 0;
                                    _monthlyPaymentController.text =
                                        _monthlyPayment > 0 ? _monthlyPayment.toStringAsFixed(2) : '0';
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: CustomTextField(
                                  controller: _monthlyPaymentController,
                                  hintText: '0',
                                  label: 'Ежемесячная оплата',
                                  readOnly: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Summary Banner
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: colors.surfaceElevated.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Платёж в месяц:',
                                  style: TextStyle(
                                    fontFamily: 'Golos',
                                    fontSize: 13,
                                    color: colors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${_monthlyPayment.toStringAsFixed(2)} ${_currencyTitle(_selectedCurrency)} / мес.',
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: colors.buttonPrimaryBg,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // График платежей button
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _openSchedulePreview,
                              icon: Icon(Icons.calendar_month_rounded, size: 16, color: colors.buttonPrimaryBg),
                              label: Text(
                                'Посмотреть график платежей',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: colors.buttonPrimaryBg,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.buttonPrimaryBg,
                        foregroundColor: colors.buttonPrimaryFg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        _saving
                            ? 'Сохранение...'
                            : 'Сохранить${_selectedOrderStatus == null ? '' : ' (${_selectedOrderStatus!.name})'}',
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderChip(String code, String title, IconData icon) {
    final colors = context.appColors;
    final isSelected = _selectedGender == code;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedGender = code);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.buttonPrimaryBg
                : colors.surfaceElevated.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colors.buttonPrimaryBg : colors.borderSubtle,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? colors.buttonPrimaryFg : colors.iconSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 13,
                  color: isSelected ? colors.buttonPrimaryFg : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDealChip(DealType type, String label) {
    final colors = context.appColors;
    final isSelected = _selectedDealType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedDealType = type;
            _recalculateInstallment();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.buttonPrimaryBg
                : colors.surfaceElevated.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colors.buttonPrimaryBg : colors.borderSubtle,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 12.5,
                color: isSelected ? colors.buttonPrimaryFg : colors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencySelector(dynamic colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Валюта',
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: colors.surfaceElevated.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedCurrency?.id,
              isExpanded: true,
              hint: Text(
                _loadingMeta ? '...' : 'Валюта',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 12.5,
                  color: colors.textSecondary,
                ),
              ),
              icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: colors.iconSecondary),
              items: _currencies.map((cur) {
                return DropdownMenuItem<int>(
                  value: cur.id,
                  child: Text(
                    _currencyTitle(cur),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: colors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val == null) return;
                SupplierCurrency? picked;
                for (final item in _currencies) {
                  if (item.id == val) {
                    picked = item;
                    break;
                  }
                }
                if (picked != null) setState(() => _selectedCurrency = picked);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required BuildContext context,
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onPicked,
  }) {
    final colors = context.appColors;
    final formatted = value != null ? DateFormat('dd.MM.yyyy').format(value) : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(1930),
              lastDate: DateTime(2050),
              builder: (ctx, child) {
                return Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: colors.buttonPrimaryBg,
                      onPrimary: colors.buttonPrimaryFg,
                      surface: colors.surfacePrimary,
                      onSurface: colors.textPrimary,
                    ),
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
            );
            if (picked != null) {
              onPicked(picked);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: colors.surfaceElevated.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatted.isNotEmpty ? formatted : 'Выберите дату',
                  style: TextStyle(
                    fontFamily: 'Golos',
                    fontSize: 13,
                    color: formatted.isNotEmpty
                        ? colors.textPrimary
                        : colors.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: colors.iconSecondary,
                ),
              ],
            ),
          ),
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
          months: int.tryParse(_monthsController.text) ?? 12,
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

    final missing = <String>[];
    if (ownerName.isEmpty) missing.add('ownerFullName');
    if (phone.isEmpty) missing.add('phone');
    if (passport.isEmpty) missing.add('passport');
    if (isInstallment) {
      final m = int.tryParse(_monthsController.text) ?? 0;
      if (m <= 0) missing.add('months');
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
    final down = double.tryParse(_downPaymentController.text.replaceAll(' ', '')) ?? 0;
    final months = int.tryParse(_monthsController.text.replaceAll(' ', '')) ?? 0;
    final sqPrice = double.tryParse(_pricePerSqmController.text.replaceAll(' ', '')) ?? 0;
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
        passportIssuedAt: _apiDate(_passportIssueDate),
        passportExpiresAt: _apiDate(_passportExpiryDate),
        ownerBirthDate: _apiDate(_birthDate),
        inn: inn,
        residenceAddress: _addressController.text.trim(),
        goodId: apartment.id,
        variantId: variantId,
        pricePerM2: sqPrice,
        dealType: dealType,
        downPayment: isInstallment ? down : null,
        installmentMonths: isInstallment ? months : null,
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
        passportIssueDate: _passportIssueDate,
        passportExpiryDate: _passportExpiryDate,
        birthDate: _birthDate,
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
