import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/localization/localization_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_field_style.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/models/page_2/supplier_model.dart';
import 'package:crm_task_manager/page_2/order/order_details/residential_deal_store.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
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

/// Поля собственника и рассрочки на экране «Новый заказ» вкладки «Сделка».
class ResidentialDealFields extends StatefulWidget {
  final double orderSum;
  final double? apartmentArea;
  final double? pricePerSqm;
  final int fillToken;
  final ValueChanged<double>? onTotalChanged;
  final Set<String> missingFields;
  final String? firstMissingField;
  final int errorPulse;
  final ValueChanged<String>? onEdited;
  final ValueChanged<String>? onDealTypeChanged;
  final ResidentialDealData? initialData;

  const ResidentialDealFields({
    super.key,
    required this.orderSum,
    this.apartmentArea,
    this.pricePerSqm,
    this.fillToken = 0,
    this.onTotalChanged,
    this.missingFields = const {},
    this.firstMissingField,
    this.errorPulse = 0,
    this.onEdited,
    this.onDealTypeChanged,
    this.initialData,
  });

  @override
  ResidentialDealFieldsState createState() => ResidentialDealFieldsState();
}

class ResidentialDealFieldsState extends State<ResidentialDealFields> {
  final _ownerController = TextEditingController();
  final _passportController = TextEditingController();
  final _issuedByController = TextEditingController();
  final _innController = TextEditingController();
  final _addressController = TextEditingController();
  final _issueDateController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _pricePerSqmController = TextEditingController();
  final _areaController = TextEditingController();
  final _sumController = TextEditingController();
  final _downPaymentController = TextEditingController();
  final _monthsController = TextEditingController(text: '12');
  final _installmentSumController = TextEditingController();
  final _monthlyController = TextEditingController();
  final _firstPaymentController = TextEditingController();
  final _barterAmountController = TextEditingController();
  final _barterNoteController = TextEditingController();

  String _gender = 'm';
  String _dealType = 'cash';
  bool _priceEdited = false;
  List<SupplierCurrency> _currencies = [];
  SupplierCurrency? _currency;
  bool _loadingCurrency = true;

  static const _genders = [
    _PickOption('m', 'М'),
    _PickOption('f', 'Ж'),
  ];
  static const _dealTypes = [
    _PickOption('cash', 'Наличными'),
    _PickOption('installment', 'Рассрочка'),
    _PickOption('mixed', 'Смешанные'),
  ];

  @override
  void initState() {
    super.initState();
    _firstPaymentController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _applyApartmentNumbers();
    _loadCurrencies();

    if (widget.initialData != null) {
      final d = widget.initialData!;
      if (d.ownerName.isNotEmpty) _ownerController.text = d.ownerName;
      if (d.gender.isNotEmpty) _gender = d.gender;
      if (d.passport.isNotEmpty) _passportController.text = d.passport;
      if (d.passportIssuedBy != null && d.passportIssuedBy!.isNotEmpty) {
        _issuedByController.text = d.passportIssuedBy!;
      }
      if (d.inn != null && d.inn! > 0) _innController.text = d.inn.toString();
      if (d.residenceAddress != null && d.residenceAddress!.isNotEmpty) {
        _addressController.text = d.residenceAddress!;
      }
      if (d.passportIssuedAt != null && d.passportIssuedAt!.isNotEmpty) {
        _issueDateController.text = _formatRawDateToUi(d.passportIssuedAt!);
      }
      if (d.passportExpiresAt != null && d.passportExpiresAt!.isNotEmpty) {
        _expiryDateController.text = _formatRawDateToUi(d.passportExpiresAt!);
      }
      if (d.ownerBirthDate != null && d.ownerBirthDate!.isNotEmpty) {
        _birthDateController.text = _formatRawDateToUi(d.ownerBirthDate!);
      }
      if (d.dealType.isNotEmpty) _dealType = d.dealType;
      if (d.downPayment != null && d.downPayment! > 0) {
        _downPaymentController.text = d.downPayment!.toStringAsFixed(0);
      }
      if (d.installmentMonths != null && d.installmentMonths! > 0) {
        _monthsController.text = d.installmentMonths.toString();
      }
      if (d.firstPaymentDate != null && d.firstPaymentDate!.isNotEmpty) {
        _firstPaymentController.text = _formatRawDateToUi(d.firstPaymentDate!);
      }
      if (d.barterAmount != null && d.barterAmount! > 0) {
        _barterAmountController.text = d.barterAmount!.toStringAsFixed(0);
      }
      if (d.barterNote != null && d.barterNote!.isNotEmpty) {
        _barterNoteController.text = d.barterNote!;
      }
      if (d.pricePerM2 != null && d.pricePerM2! > 0) {
        _pricePerSqmController.text = d.pricePerM2!.toStringAsFixed(0);
        _priceEdited = true;
      }
      _recalculate();
    }
  }

  String _formatRawDateToUi(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    try {
      if (t.contains('-')) {
        final dt = DateTime.parse(t);
        return DateFormat('dd/MM/yyyy').format(dt);
      }
    } catch (_) {}
    return t;
  }

  @override
  void didUpdateWidget(covariant ResidentialDealFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fillToken != widget.fillToken) {
      _priceEdited = false;
    }
    if (oldWidget.orderSum != widget.orderSum ||
        oldWidget.apartmentArea != widget.apartmentArea ||
        oldWidget.pricePerSqm != widget.pricePerSqm ||
        oldWidget.fillToken != widget.fillToken) {
      _applyApartmentNumbers();
    }
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _passportController.dispose();
    _issuedByController.dispose();
    _innController.dispose();
    _addressController.dispose();
    _issueDateController.dispose();
    _expiryDateController.dispose();
    _birthDateController.dispose();
    _pricePerSqmController.dispose();
    _areaController.dispose();
    _sumController.dispose();
    _downPaymentController.dispose();
    _monthsController.dispose();
    _installmentSumController.dispose();
    _monthlyController.dispose();
    _firstPaymentController.dispose();
    _barterAmountController.dispose();
    _barterNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencies() async {
    try {
      final currencies = await ApiService().getCurrencies();
      final savedId = await LocalizationService.getCurrencyId();
      if (!mounted) return;
      SupplierCurrency? selected;
      for (final item in currencies) {
        if (item.id != null && item.id == savedId) {
          selected = item;
          break;
        }
      }
      selected ??= currencies.isNotEmpty ? currencies.first : null;
      setState(() {
        _currencies = currencies.where((item) => item.id != null).toList();
        _currency = selected;
        _loadingCurrency = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCurrency = false);
    }
  }

  double _money(String raw) {
    return double.tryParse(raw.replaceAll(' ', '').replaceAll(',', '.')) ?? 0;
  }

  double get _area => widget.apartmentArea ?? 0;

  double get _barter => _dealType == 'mixed' ? _money(_barterAmountController.text) : 0;

  double get _payable => (widget.orderSum - _barter).clamp(0, double.infinity);

  void _applyApartmentNumbers() {
    final area = _area;
    _areaController.text = area > 0 ? area.toStringAsFixed(1) : '';
    if (!_priceEdited) {
      final fromApartment = widget.pricePerSqm ?? 0;
      if (fromApartment > 0) {
        _pricePerSqmController.text = fromApartment.toStringAsFixed(0);
      } else if (area > 0 && widget.orderSum > 0) {
        _pricePerSqmController.text = (widget.orderSum / area).toStringAsFixed(0);
      }
    }
    _sumController.text = widget.orderSum > 0 ? widget.orderSum.toStringAsFixed(0) : '0';
    _recalculate();
  }

  void _recalculate() {
    final down = _money(_downPaymentController.text);
    final months = int.tryParse(_monthsController.text.trim()) ?? 0;
    final installment = _dealType == 'cash' ? 0.0 : (_payable - down).clamp(0, double.infinity);
    final monthly = months > 0 ? installment / months : 0.0;
    _installmentSumController.text = installment.toStringAsFixed(0);
    _monthlyController.text = monthly > 0 ? monthly.toStringAsFixed(2) : '0';
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

  String? _apiDate(TextEditingController controller) {
    final date = _parseUiDate(controller.text);
    if (date == null) return null;
    return DateFormat('yyyy-MM-dd').format(date);
  }

  bool get _needsSchedule {
    final down = _money(_downPaymentController.text);
    final installment = _dealType == 'cash' ? 0.0 : (_payable - down).clamp(0.0, double.infinity);
    return _dealType != 'cash' && installment > 0;
  }

  List<String> collectMissing() {
    return [
      if (_ownerController.text.trim().isEmpty) 'owner',
      if (_passportController.text.trim().isEmpty) 'passport',
      if (_currency?.id == null) 'currency',
      if (_needsSchedule && (int.tryParse(_monthsController.text.trim()) ?? 0) <= 0) 'months',
      if (_needsSchedule && _parseUiDate(_firstPaymentController.text) == null) 'firstPayment',
    ];
  }

  void _edited(String key) => widget.onEdited?.call(key);

  /// Предпросмотр графика до создания сделки. При нехватке срока или суммы показывает сообщение.
  Order? buildSchedulePreview({
    required String phone,
    String manager = '',
    Apartment? apartment,
  }) {
    final down = _money(_downPaymentController.text);
    final months = int.tryParse(_monthsController.text.trim()) ?? 0;
    final installment = _dealType == 'cash' ? 0.0 : (_payable - down).clamp(0.0, double.infinity);
    if (_dealType == 'mixed' && _barter > widget.orderSum) {
      showCustomSnackBar(
        context: context,
        message: 'Оценка бартера не может быть больше суммы сделки',
        isSuccess: false,
      );
      return null;
    }
    if (down > _payable) {
      showCustomSnackBar(
        context: context,
        message: 'Первоначальный взнос больше остатка сделки',
        isSuccess: false,
      );
      return null;
    }
    if (months <= 0 || installment <= 0) {
      showCustomSnackBar(
        context: context,
        message: 'Укажите срок и сумму рассрочки, чтобы открыть шаблон графика',
        isSuccess: false,
      );
      return null;
    }
    final owner = _ownerController.text.trim();
    final note = _barterNoteController.text.trim();
    return Order(
      id: 'Предпросмотр',
      complexId: apartment?.complexId ?? 1,
      apartmentId: apartment?.id,
      buyerName: owner.isEmpty ? 'Собственник' : owner,
      buyerPhone: phone,
      buyerEmail: '',
      manager: manager.trim().isEmpty ? 'Менеджер' : manager.trim(),
      dealType: _dealType == 'mixed' ? DealType.mixed : DealType.installment,
      price: widget.orderSum,
      status: OrderStatus.inProgress,
      currency: _currency?.symbolCode ?? _currency?.name,
      ownerFullName: owner.isEmpty ? null : owner,
      paymentDetails: PaymentDetails(
        downPayment: down,
        months: months,
        installmentSum: installment,
        monthlyPayment: installment / months,
        barterSubject: note.isEmpty ? null : note,
        barterAmount: _barter,
        schedule: PaymentDetails.generateSchedule(
          totalInstallmentSum: installment,
          months: months,
          firstDueDate: _parseUiDate(_firstPaymentController.text),
        ),
      ),
    );
  }

  Widget _required(String key, Widget child) {
    return RequiredFieldSlot(
      invalid: widget.missingFields.contains(key),
      focus: widget.firstMissingField == key,
      pulse: widget.errorPulse,
      message: AppLocalizations.of(context)?.translate('field_required') ??
          'Поле обязательно для заполнения',
      child: child,
    );
  }

  /// Возвращает поля для POST /order. При ошибке показывает сообщение и возвращает null.
  Map<String, dynamic>? buildPayload() {
    final owner = _ownerController.text.trim();
    final passport = _passportController.text.trim();
    final down = _money(_downPaymentController.text);
    final months = int.tryParse(_monthsController.text.trim()) ?? 0;
    final needsSchedule = _needsSchedule;

    if (_dealType == 'mixed' && _barter > widget.orderSum) {
      showCustomSnackBar(
        context: context,
        message: 'Оценка бартера не может быть больше суммы сделки',
        isSuccess: false,
      );
      return null;
    }
    if (_dealType != 'cash' && down > _payable) {
      showCustomSnackBar(
        context: context,
        message: 'Первоначальный взнос больше остатка сделки',
        isSuccess: false,
      );
      return null;
    }
    if (collectMissing().isNotEmpty || _currency?.id == null) return null;

    final payload = <String, dynamic>{
      'owner_name': owner,
      'gender': _gender,
      'passport': passport,
      'deal_type': _dealType,
      'currency_id': _currency!.id,
      'currency_symbol': _currency?.symbolCode ?? _currency?.name,
      'price_per_m2': _money(_pricePerSqmController.text),
    };

    final issuedBy = _issuedByController.text.trim();
    if (issuedBy.isNotEmpty) payload['passport_issued_by'] = issuedBy;
    final issuedAt = _apiDate(_issueDateController);
    if (issuedAt != null) payload['passport_issued_at'] = issuedAt;
    final expiresAt = _apiDate(_expiryDateController);
    if (expiresAt != null) payload['passport_expires_at'] = expiresAt;
    final birth = _apiDate(_birthDateController);
    if (birth != null) payload['owner_birth_date'] = birth;
    final inn = int.tryParse(_innController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (inn != null) payload['inn'] = inn;
    final address = _addressController.text.trim();
    if (address.isNotEmpty) payload['residence_address'] = address;
    if (_area > 0) payload['total_area'] = _area;

    if (_dealType == 'mixed' && _barter > 0) {
      payload['barter_amount'] = _barter;
      final note = _barterNoteController.text.trim();
      if (note.isNotEmpty) payload['barter_note'] = note;
    }
    if (_dealType != 'cash' && (needsSchedule || down > 0)) {
      payload['down_payment'] = down;
    }
    if (needsSchedule) {
      payload['installment_months'] = months;
      payload['first_payment_date'] = _apiDate(_firstPaymentController);
    }
    return payload;
  }

  @override
  Widget build(BuildContext context) {
    final showInstallment = _dealType != 'cash';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _required(
          'owner',
          CustomTextField(
            controller: _ownerController,
            hintText: 'Введите ФИО собственника',
            label: 'ФИО собственника',
            hasError: widget.missingFields.contains('owner'),
            onChanged: (value) {
              if (value.trim().isNotEmpty) _edited('owner');
            },
          ),
        ),
        const SizedBox(height: 8),
        _dropdown(
          label: 'Пол',
          hint: 'Выберите пол',
          items: _genders,
          selectedKey: _gender,
          onChanged: (key) => setState(() => _gender = key),
        ),
        const SizedBox(height: 8),
        _required(
          'passport',
          CustomTextField(
            controller: _passportController,
            hintText: 'AA 1234567',
            label: 'Паспорт (серия и номер)',
            hasError: widget.missingFields.contains('passport'),
            onChanged: (value) {
              if (value.trim().isNotEmpty) _edited('passport');
            },
          ),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _issuedByController,
          hintText: 'Кем выдан паспорт',
          label: 'Место выдачи',
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _innController,
          hintText: 'Введите ИНН',
          label: 'ИНН',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _addressController,
          hintText: 'Введите адрес проживания',
          label: 'Адрес проживания',
        ),
        const SizedBox(height: 8),
        CustomTextFieldDate(
          controller: _issueDateController,
          label: 'Дата выдачи',
        ),
        const SizedBox(height: 8),
        CustomTextFieldDate(
          controller: _expiryDateController,
          label: 'Срок действия',
        ),
        const SizedBox(height: 8),
        CustomTextFieldDate(
          controller: _birthDateController,
          label: 'Дата рождения собственника',
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _pricePerSqmController,
          hintText: 'Цена за м²',
          label: 'Цена за квадрат',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            setState(() => _priceEdited = true);
            final area = _area;
            if (area <= 0) return;
            widget.onTotalChanged?.call(_money(value) * area);
          },
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _areaController,
          hintText: 'Из выбранной квартиры',
          label: 'Общая площадь',
          readOnly: true,
        ),
        const SizedBox(height: 8),
        _dropdown(
          label: 'Тип сделки',
          hint: 'Выберите тип сделки',
          items: _dealTypes,
          selectedKey: _dealType,
          onChanged: (key) {
            setState(() {
              _dealType = key;
              _recalculate();
            });
            widget.onDealTypeChanged?.call(key);
          },
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _sumController,
          hintText: '0',
          label: 'Сумма',
          readOnly: true,
        ),
        const SizedBox(height: 8),
        _required('currency', _currencyDropdown()),
        if (_dealType == 'mixed') ...[
          const SizedBox(height: 8),
          CustomTextField(
            controller: _barterAmountController,
            hintText: '0',
            label: 'Оценка бартера',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(_recalculate),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _barterNoteController,
            hintText: 'Старая квартира, машина',
            label: 'Что отдают в бартер',
          ),
        ],
        if (showInstallment) ...[
          const SizedBox(height: 8),
          CustomTextField(
            controller: _downPaymentController,
            hintText: '0',
            label: 'Первоначальный взнос',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(_recalculate),
          ),
          const SizedBox(height: 8),
          _required(
            'months',
            CustomTextField(
              controller: _monthsController,
              hintText: '12',
              label: 'Срок рассрочки',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              hasError: widget.missingFields.contains('months'),
              onChanged: (value) {
                if ((int.tryParse(value.trim()) ?? 0) > 0) _edited('months');
                setState(_recalculate);
              },
            ),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _installmentSumController,
            hintText: '0',
            label: 'Сумма рассрочки',
            readOnly: true,
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _monthlyController,
            hintText: '0',
            label: 'Ежемесячная оплата',
            readOnly: true,
          ),
          const SizedBox(height: 8),
          _required(
            'firstPayment',
            CustomTextFieldDate(
              controller: _firstPaymentController,
              label: 'Дата первого платежа',
              hasError: widget.missingFields.contains('firstPayment'),
              onDateSelected: (_) => _edited('firstPayment'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String hint,
    required List<_PickOption> items,
    required String selectedKey,
    required ValueChanged<String> onChanged,
  }) {
    final colors = context.appColors;
    final selected = items.cast<_PickOption?>().firstWhere(
          (item) => item!.key == selectedKey,
          orElse: () => null,
        );
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
          key: ValueKey('$label-$selectedKey'),
          items: items,
          initialItem: selected,
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
            hint,
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

  Widget _currencyDropdown() {
    final colors = context.appColors;
    SupplierCurrency? selected;
    for (final currency in _currencies) {
      if (currency.id != null && currency.id == _currency?.id) {
        selected = currency;
        break;
      }
    }
    String title(SupplierCurrency? currency) {
      final name = currency?.name?.trim() ?? '';
      if (name.isNotEmpty) return name;
      return currency?.symbolCode?.trim() ?? '';
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
        if (_loadingCurrency)
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
            key: ValueKey('deal-currency-${selected?.id}-${_currencies.length}'),
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
            decoration: AppFieldStyle.dropdownDecoration(
              context,
              hasError: widget.missingFields.contains('currency'),
            ),
            listItemBuilder: (context, item, isSelected, onItemSelect) => Text(
              title(item),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
              ),
            ),
            headerBuilder: (context, selectedItem, enabled) => Text(
              title(selectedItem),
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
              if (value == null) return;
              setState(() => _currency = value);
              _edited('currency');
            },
          ),
      ],
    );
  }
}
