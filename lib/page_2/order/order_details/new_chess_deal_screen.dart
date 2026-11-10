import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_field_style.dart';
import 'package:crm_task_manager/custom_widget/country_data_list.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_number_input.dart';
import 'package:crm_task_manager/models/lead/lead_list_model.dart';
import 'package:crm_task_manager/models/lead/manager_model.dart';
import 'package:crm_task_manager/models/page_2/order_status_model.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/page_2/order/order_details/residential_deal_fields.dart';
import 'package:crm_task_manager/page_2/order/order_details/residential_deal_store.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart' hide Order, OrderStatus;
import 'package:crm_task_manager/screens/chess_grid/widgets/chess_deal_goods_sheet.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/payment_schedule_sheet.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/lead_with_manager.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/manager_for_lead.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/required_field_slot.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';

class _StatusOption {
  final int id;
  final String title;

  const _StatusOption(this.id, this.title);

  @override
  bool operator ==(Object other) => other is _StatusOption && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => title;
}

/// Фиксированная форма «Новая сделка» / «Редактирование» для вкладки «Сделка» в шахматке.
/// Поля заданы контрактом сервера и не зависят от настройки полей заказа.
class NewChessDealScreen extends StatefulWidget {
  final Order? existingOrder;
  final ResidentialDealData? existingData;

  const NewChessDealScreen({
    super.key,
    this.existingOrder,
    this.existingData,
  });

  bool get isEdit => existingOrder != null;

  @override
  State<NewChessDealScreen> createState() => _NewChessDealScreenState();
}

class _NewChessDealScreenState extends State<NewChessDealScreen> {
  final _residentialKey = GlobalKey<ResidentialDealFieldsState>();
  final _phoneController = TextEditingController();
  final _api = ApiService();

  String? _leadId;
  String? _managerId;
  int? _statusId;
  String _managerName = '';
  String _dealType = 'cash';
  List<OrderStatus> _statuses = [];
  bool _loadingStatuses = true;
  bool _saving = false;
  Set<String> _missingFields = {};
  String? _firstMissingField;
  int _fieldErrorPulse = 0;

  String _phone = '';
  Country? _phoneCountry;
  int _phoneRevision = 0;

  int? _goodId;
  int? _variantId;
  Apartment? _apartment;
  double _sum = 0;
  double? _area;
  double? _pricePerSqm;
  int _fillToken = 0;

  @override
  void initState() {
    super.initState();
    _initFromExisting();
    _loadStatuses();
  }

  void _initFromExisting() {
    final order = widget.existingOrder;
    final data = widget.existingData;
    if (order == null && data == null) return;

    if (order != null) {
      _leadId = order.lead.id.toString();
      _statusId = order.orderStatus.id;
      if (order.manager != null) {
        _managerId = order.manager!.id.toString();
        _managerName = order.manager!.name;
      }
      final phone = order.phone.trim();
      if (phone.isNotEmpty) {
        _phone = phone;
        final parsed = parsePhoneCountryAndNumber(phone);
        _phoneCountry = parsed.country;
        _phoneController.text = parsed.localNumber;
        _phoneRevision++;
      }
      if (order.sum != null && order.sum! > 0) {
        _sum = order.sum!;
      }
      if (order.goods.isNotEmpty) {
        final g = order.goods.first;
        _goodId = g.good.id > 0 ? g.good.id : (g.goodId > 0 ? g.goodId : null);
        _variantId = g.goodId > 0 ? g.goodId : null;
      }
    }

    if (data != null) {
      if (data.goodId != null && _goodId == null) {
        _goodId = data.goodId;
      }
      if (data.variantId != null && _variantId == null) {
        _variantId = data.variantId;
      }
      if (data.sum != null && data.sum! > 0) {
        _sum = data.sum!;
      }
      if (data.totalArea != null && data.totalArea! > 0) {
        _area = data.totalArea;
      }
      if (data.pricePerM2 != null && data.pricePerM2! > 0) {
        _pricePerSqm = data.pricePerM2;
      }
      if (data.dealType.isNotEmpty) {
        _dealType = data.dealType;
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadStatuses() async {
    try {
      final statuses = await _api.getOrderStatuses();
      if (!mounted) return;
      setState(() {
        _statuses = statuses;
        if (_statusId == null && statuses.isNotEmpty) {
          _statusId = statuses.first.id;
        }
        _loadingStatuses = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingStatuses = false);
    }
  }

  Future<void> _onLeadSelected(LeadData lead) async {
    var phone = (lead.phone ?? '').trim();
    if (phone.isEmpty) {
      try {
        final card = await _api.getLeadById(lead.id);
        if (!mounted) return;
        final cardPhone = (card.phone ?? '').trim();
        final whatsApp = (card.whatsApp ?? '').trim();
        phone = cardPhone.isNotEmpty ? cardPhone : whatsApp;
      } catch (_) {}
    }
    if (!mounted) return;
    final parsed = parsePhoneCountryAndNumber(phone);
    setState(() {
      _leadId = lead.id.toString();
      if (lead.managerId != null) _managerId = lead.managerId.toString();
      _missingFields.remove('lead');
      if (_managerId != null) _missingFields.remove('manager');
      if (_firstMissingField == 'lead') _firstMissingField = null;
      if (parsed.localNumber.isNotEmpty) {
        _phoneCountry = parsed.country ?? _phoneCountry;
        final dial = parsed.country?.dialCode ?? '';
        _phone = dial.isNotEmpty ? '$dial${parsed.localNumber}' : parsed.localNumber;
        _phoneRevision++;
        _missingFields.remove('phone');
        if (_firstMissingField == 'phone') _firstMissingField = null;
      }
    });
    if (parsed.localNumber.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _phoneController.text = parsed.localNumber;
      });
    }
  }

  Future<void> _pickApartment() async {
    final apartment = await ChessDealGoodsSheet.show(context);
    if (apartment == null || !mounted) return;
    var variantId = apartment.variantId;
    if (variantId == null || variantId <= 0) {
      try {
        final goods = await _api.getGoodsById(apartment.id);
        final variants = goods.isNotEmpty ? goods.first.variants : null;
        if (variants != null && variants.isNotEmpty && variants.first.id > 0) {
          variantId = variants.first.id;
        }
      } catch (_) {}
    }
    if (!mounted) return;
    final price = apartment.totalPrice > 0
        ? apartment.totalPrice
        : apartment.pricePerSqm * apartment.totalArea;
    setState(() {
      _goodId = apartment.id;
      _variantId = variantId;
      _apartment = apartment;
      _sum = price;
      _area = apartment.totalArea > 0 ? apartment.totalArea : null;
      _pricePerSqm = apartment.pricePerSqm > 0 ? apartment.pricePerSqm : null;
      _fillToken++;
      _missingFields.remove('apartment');
      if (_firstMissingField == 'apartment') _firstMissingField = null;
    });
  }

  void _openScheduleTemplate() {
    final phone = _phone.isNotEmpty ? _phone : _phoneController.text.trim();
    final order = _residentialKey.currentState?.buildSchedulePreview(
      phone: phone,
      manager: _managerName,
      apartment: _apartment,
    );
    if (order == null || !mounted) return;
    PaymentScheduleSheet.show(context: context, order: order, apartment: _apartment);
  }

  Future<void> _submit() async {
    if (_saving) return;
    final leadId = int.tryParse(_leadId ?? '');
    final managerId = int.tryParse(_managerId ?? '');
    final phone = _phone.isNotEmpty ? _phone : _phoneController.text.trim();
    final missing = <String>[
      if (_apartment == null && _goodId == null) 'apartment',
      if (leadId == null) 'lead',
      if (managerId == null) 'manager',
      if (_statusId == null) 'status',
      if (phone.isEmpty) 'phone',
      ...?_residentialKey.currentState?.collectMissing(),
    ];
    if (missing.isNotEmpty) {
      setState(() {
        _missingFields = missing.toSet();
        _firstMissingField = missing.first;
        _fieldErrorPulse++;
      });
      return;
    }
    if (_missingFields.isNotEmpty) {
      setState(() {
        _missingFields = {};
        _firstMissingField = null;
      });
    }

    final int effectiveVariantId = (_variantId != null && _variantId! > 0)
        ? _variantId!
        : (_goodId != null && _goodId! > 0 ? _goodId! : 0);
    if (effectiveVariantId <= 0) {
      showCustomSnackBar(
        context: context,
        message: 'У квартиры нет варианта товара. Сервер без него сделку не примет.',
        isSuccess: false,
      );
      return;
    }

    final payload = _residentialKey.currentState?.buildPayload();
    if (payload == null) return;

    setState(() => _saving = true);
    try {
      final integrationId = widget.existingOrder?.integrationId ??
          await _api.resolveOrderMiniAppIntegrationId();
      if (!mounted) return;
      if (integrationId == null) {
        showCustomSnackBar(
          context: context,
          message: 'Не найдена интеграция. Без неё сервер сделку не примет.',
          isSuccess: false,
        );
        return;
      }

      final currencyId = payload['currency_id'] as int;
      final currencySymbol = payload['currency_symbol'] as String?;
      final ownerName = payload['owner_name'] as String;
      final gender = payload['gender'] as String;
      final passport = payload['passport'] as String;
      final passportIssuedBy = payload['passport_issued_by'] as String?;
      final passportIssuedAt = payload['passport_issued_at'] as String?;
      final passportExpiresAt = payload['passport_expires_at'] as String?;
      final ownerBirthDate = payload['owner_birth_date'] as String?;
      final inn = payload['inn'] as int?;
      final residenceAddress = payload['residence_address'] as String?;
      final pricePerM2 = (payload['price_per_m2'] as num?)?.toDouble() ?? 0;
      final totalArea = (payload['total_area'] as num?)?.toDouble();
      final dealType = payload['deal_type'] as String;
      final downPayment = (payload['down_payment'] as num?)?.toDouble();
      final installmentMonths = payload['installment_months'] as int?;
      final firstPaymentDate = payload['first_payment_date'] as String?;
      final barterAmount = (payload['barter_amount'] as num?)?.toDouble();
      final barterNote = payload['barter_note'] as String?;

      if (widget.isEdit) {
        final orderId = widget.existingOrder!.id;
        final result = await _api.updateResidentialOrder(
          orderId: orderId,
          leadId: leadId!,
          managerId: managerId!,
          orderStatusId: _statusId!,
          integrationId: integrationId,
          phone: phone,
          sum: _sum,
          currencyId: currencyId,
          ownerName: ownerName,
          gender: gender,
          passport: passport,
          passportIssuedBy: passportIssuedBy,
          passportIssuedAt: passportIssuedAt,
          passportExpiresAt: passportExpiresAt,
          ownerBirthDate: ownerBirthDate,
          inn: inn,
          residenceAddress: residenceAddress,
          goodId: _goodId!,
          variantId: effectiveVariantId,
          pricePerM2: pricePerM2,
          totalArea: totalArea,
          dealType: dealType,
          downPayment: downPayment,
          installmentMonths: installmentMonths,
          firstPaymentDate: firstPaymentDate,
          barterAmount: barterAmount,
          barterNote: barterNote,
        );
        if (!mounted) return;
        if (result['success'] != true) {
          showCustomSnackBar(
            context: context,
            message: result['error']?.toString() ?? 'Не удалось сохранить сделку',
            isSuccess: false,
          );
          return;
        }

        await ResidentialDealStore.save(ResidentialDealData(
          orderId: orderId,
          ownerName: ownerName,
          gender: gender,
          passport: passport,
          passportIssuedBy: passportIssuedBy,
          passportIssuedAt: passportIssuedAt,
          passportExpiresAt: passportExpiresAt,
          ownerBirthDate: ownerBirthDate,
          inn: inn,
          residenceAddress: residenceAddress,
          dealType: dealType,
          pricePerM2: pricePerM2,
          totalArea: totalArea,
          sum: _sum,
          currencyId: currencyId,
          currencySymbol: currencySymbol,
          downPayment: downPayment,
          installmentMonths: installmentMonths,
          firstPaymentDate: firstPaymentDate,
          barterAmount: barterAmount,
          barterNote: barterNote,
          goodId: _goodId,
          variantId: effectiveVariantId,
          goodName: _apartment?.number != null
              ? 'Квартира № ${_apartment!.number}'
              : widget.existingData?.goodName,
          buildingName: _apartment?.buildingName.isNotEmpty == true
              ? _apartment!.buildingName
              : widget.existingData?.buildingName,
          phone: phone,
        ));

        Navigator.pop(context, {
          'success': true,
          'updated': true,
          'statusId': _statusId,
        });
      } else {
        final result = await _api.createResidentialOrder(
          leadId: leadId!,
          managerId: managerId!,
          orderStatusId: _statusId!,
          integrationId: integrationId,
          phone: phone,
          sum: _sum,
          currencyId: currencyId,
          ownerName: ownerName,
          gender: gender,
          passport: passport,
          passportIssuedBy: passportIssuedBy,
          passportIssuedAt: passportIssuedAt,
          passportExpiresAt: passportExpiresAt,
          ownerBirthDate: ownerBirthDate,
          inn: inn,
          residenceAddress: residenceAddress,
          goodId: _goodId!,
          variantId: effectiveVariantId,
          pricePerM2: pricePerM2,
          totalArea: totalArea,
          dealType: dealType,
          downPayment: downPayment,
          installmentMonths: installmentMonths,
          firstPaymentDate: firstPaymentDate,
          barterAmount: barterAmount,
          barterNote: barterNote,
        );
        if (!mounted) return;
        if (result['success'] != true) {
          showCustomSnackBar(
            context: context,
            message: result['error']?.toString() ?? 'Не удалось создать сделку',
            isSuccess: false,
          );
          return;
        }

        final createdId = (result['order'] is Map ? result['order']['id'] : null) as int? ?? 0;
        if (createdId > 0) {
          await ResidentialDealStore.save(ResidentialDealData(
            orderId: createdId,
            ownerName: ownerName,
            gender: gender,
            passport: passport,
            passportIssuedBy: passportIssuedBy,
            passportIssuedAt: passportIssuedAt,
            passportExpiresAt: passportExpiresAt,
            ownerBirthDate: ownerBirthDate,
            inn: inn,
            residenceAddress: residenceAddress,
            dealType: dealType,
            pricePerM2: pricePerM2,
            totalArea: totalArea,
            sum: _sum,
            currencyId: currencyId,
            currencySymbol: currencySymbol,
            downPayment: downPayment,
            installmentMonths: installmentMonths,
            firstPaymentDate: firstPaymentDate,
            barterAmount: barterAmount,
            barterNote: barterNote,
            goodId: _goodId,
            variantId: effectiveVariantId,
            goodName: _apartment != null ? 'Квартира № ${_apartment!.number}' : null,
            buildingName: _apartment?.buildingName,
            phone: phone,
          ));
        }

        Navigator.pop(context, {
          'success': true,
          'statusId': _statusId,
        });
      }
    } catch (error) {
      if (!mounted) return;
      showCustomSnackBar(
        context: context,
        message: error.toString().replaceFirst('Exception: ', ''),
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _markFilled(String key) {
    if (!_missingFields.contains(key)) return;
    setState(() {
      _missingFields.remove(key);
      if (_firstMissingField == key) _firstMissingField = null;
    });
  }

  Widget _slot(String key, Widget child, {bool showCaption = true}) {
    return RequiredFieldSlot(
      invalid: _missingFields.contains(key),
      focus: _firstMissingField == key,
      pulse: _fieldErrorPulse,
      showCaption: showCaption,
      message: AppLocalizations.of(context)?.translate('field_required') ??
          'Поле обязательно для заполнения',
      child: child,
    );
  }

  Widget _buildApartmentPicker(dynamic colors) {
    final apartment = _apartment;
    final price = apartment == null
        ? 0.0
        : (apartment.totalPrice > 0
            ? apartment.totalPrice
            : apartment.pricePerSqm * apartment.totalArea);
    final place = apartment == null
        ? ''
        : [
            if (apartment.buildingName.trim().isNotEmpty) apartment.buildingName,
            'подъезд ${apartment.entrance}',
            if (apartment.floor > 0) 'этаж ${apartment.floor}',
          ].join(' · ');

    final existingGoodName = widget.existingData?.goodName ??
        (widget.existingOrder?.goods.isNotEmpty == true
            ? widget.existingOrder!.goods.first.getCorrectGoodName()
            : null);
    final hasExistingGood = existingGoodName != null && existingGoodName.trim().isNotEmpty;
    final hasSelected = apartment != null || hasExistingGood;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickApartment,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _missingFields.contains('apartment')
                  ? colors.error
                  : hasSelected
                      ? colors.buttonPrimaryBg
                      : colors.buttonPrimaryBg.withValues(alpha: 0.35),
              width: _missingFields.contains('apartment') || hasSelected ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.buttonPrimaryBg.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.apartment_rounded,
                    color: colors.buttonPrimaryBg,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: apartment != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Квартира № ${apartment.number}',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              place,
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _apartmentChip(colors, '${apartment.rooms} комн.'),
                                if (apartment.totalArea > 0)
                                  _apartmentChip(
                                    colors,
                                    '${apartment.totalArea.toStringAsFixed(1)} м²',
                                  ),
                                _apartmentChip(colors, apartment.status.labelRu),
                                if (price > 0)
                                  _apartmentChip(colors, price.toStringAsFixed(0), accent: true),
                              ],
                            ),
                          ],
                        )
                      : hasExistingGood
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  existingGoodName,
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                if (widget.existingData?.buildingName != null &&
                                    widget.existingData!.buildingName!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.existingData!.buildingName!,
                                    style: TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    if (_area != null && _area! > 0)
                                      _apartmentChip(
                                        colors,
                                        '${_area!.toStringAsFixed(1)} м²',
                                      ),
                                    if (_sum > 0)
                                      _apartmentChip(colors, _sum.toStringAsFixed(0), accent: true),
                                  ],
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Квартира',
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ЖК, корпус, подъезд и квартира',
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    Icon(Icons.chevron_right_rounded, color: colors.buttonPrimaryBg, size: 28),
                    Text(
                      hasSelected ? 'Изменить' : 'Выбрать',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.buttonPrimaryBg,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _apartmentChip(dynamic colors, String text, {bool accent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent
            ? colors.buttonPrimaryBg.withValues(alpha: 0.12)
            : colors.fieldBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: accent ? colors.buttonPrimaryBg : colors.textPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final statuses = _statuses
        .map((status) => _StatusOption(status.id, status.name))
        .toList();
    _StatusOption? selectedStatus;
    for (final status in statuses) {
      if (status.id == _statusId) {
        selectedStatus = status;
        break;
      }
    }

    return Scaffold(
      backgroundColor: colors.surfacePrimary,
      appBar: AppBar(
        backgroundColor: colors.surfacePrimary,
        forceMaterialTransparency: true,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEdit
              ? 'Сделка №${widget.existingOrder!.orderNumber}'
              : 'Новая сделка',
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _slot('apartment', _buildApartmentPicker(colors)),
                  const SizedBox(height: 16),
                  _slot(
                    'lead',
                    LeadWithManager(
                      selectedLead: _leadId,
                      alwaysRefreshFromServer: true,
                      hasError: _missingFields.contains('lead'),
                      onSelectLead: _onLeadSelected,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _slot(
                    'manager',
                    ManagerForLead(
                      selectedManager: _managerId,
                      hasError: _missingFields.contains('manager'),
                      onSelectManager: (ManagerData manager) {
                        final last = (manager.lastname ?? '').trim();
                        setState(() {
                          _managerId = manager.id.toString();
                          _managerName = last.isEmpty ? manager.name : '${manager.name} $last';
                        });
                        _markFilled('manager');
                      },
                    ),
                    showCaption: false,
                  ),
                  const SizedBox(height: 8),
                  _slot(
                    'status',
                    Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    'Статус',
                    style: context.appTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_loadingStatuses)
                    _closedHint(colors, 'Загрузка...')
                  else
                    CustomDropdown<_StatusOption>.search(
                      key: ValueKey('deal-status-$_statusId-${statuses.length}'),
                      items: statuses,
                      initialItem: selectedStatus,
                      enabled: statuses.isNotEmpty,
                      excludeSelected: false,
                      canClear: false,
                      overlayHeight: 280,
                      searchHintText: 'Поиск',
                      noResultFoundText: 'Ничего не найдено',
                      listItemPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      closedHeaderPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: AppFieldStyle.dropdownDecoration(
                        context,
                        hasError: _missingFields.contains('status'),
                      ),
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
                      hintBuilder: (context, hint, enabled) => Text(
                        'Выберите статус',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: colors.textSecondary,
                        ),
                      ),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _statusId = value.id);
                        _markFilled('status');
                      },
                    ),
                    ],
                  ),
                  ),
                  const SizedBox(height: 8),
                  _slot(
                    'phone',
                    CustomPhoneNumberInput(
                      key: ValueKey('deal-phone-$_phoneRevision-${_phoneCountry?.dialCode ?? ''}'),
                      controller: _phoneController,
                      label: 'Телефон',
                      initialCountry: _phoneCountry,
                      hasError: _missingFields.contains('phone'),
                      onInputChanged: (value) {
                        _phone = value;
                        if (value.trim().isNotEmpty) _markFilled('phone');
                      },
                    ),
                  ),
                  ResidentialDealFields(
                    key: _residentialKey,
                    orderSum: _sum,
                    apartmentArea: _area,
                    pricePerSqm: _pricePerSqm,
                    fillToken: _fillToken,
                    initialData: widget.existingData,
                    missingFields: _missingFields,
                    firstMissingField: _firstMissingField,
                    errorPulse: _fieldErrorPulse,
                    onEdited: _markFilled,
                    onDealTypeChanged: (type) => setState(() => _dealType = type),
                    onTotalChanged: (sum) => setState(() => _sum = sum),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            decoration: BoxDecoration(
              color: colors.backgroundPrimary,
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.08),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_dealType != 'cash') ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _openScheduleTemplate,
                      icon: Icon(Icons.description_outlined, color: colors.buttonPrimaryBg, size: 18),
                      label: Text(
                        'Шаблон графика',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          color: colors.buttonPrimaryBg,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.buttonPrimaryBg,
                        side: BorderSide(color: colors.buttonPrimaryBg, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: colors.textPrimary,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Отмена',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.buttonPrimaryBg,
                      foregroundColor: colors.buttonPrimaryFg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      widget.isEdit
                          ? (_saving ? 'Сохранение...' : 'Сохранить')
                          : (_saving ? 'Создание...' : 'Создать'),
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: colors.buttonPrimaryFg,
                      ),
                    ),
                  ),
                ),
              ],
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _closedHint(dynamic colors, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: colors.fieldBg,
        borderRadius: AppFieldStyle.radius,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}
