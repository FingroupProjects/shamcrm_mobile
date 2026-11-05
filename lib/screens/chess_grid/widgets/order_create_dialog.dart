import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_number_input.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/order_create_sheet.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/payment_schedule_sheet.dart';
import 'package:crm_task_manager/screens/lead/tabBar/source_lead_list.dart';
import 'package:crm_task_manager/widgets/required_field_slot.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderCreateDialog extends StatefulWidget {
  final Apartment? apartment;
  final ParkingSpot? parking;

  const OrderCreateDialog({
    super.key,
    this.apartment,
    this.parking,
  });

  static Future<void> show({
    required BuildContext context,
    Apartment? apartment,
    ParkingSpot? parking,
  }) {
    return OrderCreateSheet.show(
      context: context,
      apartment: apartment,
      parking: parking,
    );
  }

  @override
  State<OrderCreateDialog> createState() => _OrderCreateDialogState();
}

class _OrderCreateDialogState extends State<OrderCreateDialog> {
  final _buyerNameController = TextEditingController();
  final _buyerPhoneController = TextEditingController();
  String _formattedBuyerPhone = '';
  final _buyerEmailController = TextEditingController();
  final _commentController = TextEditingController();
  final _downPaymentController = TextEditingController();
  final _monthsController = TextEditingController();
  final _barterSubjectController = TextEditingController();
  final _barterAmountController = TextEditingController();
  String? _selectedSourceId;

  final Map<int, TextEditingController> _customFieldControllers = {};

  DealType _selectedDealType = DealType.cash;
  int _selectedRoleIndex = 0;

  // Required fields validation like LeadAddScreen
  Set<String> _missingFields = {};
  String? _firstMissingField;
  int _fieldErrorPulse = 0;

  @override
  void initState() {
    super.initState();
    for (final cf in ChessGridController.instance.customFields.where((f) => f.scope == 'order')) {
      _customFieldControllers[cf.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _buyerNameController.dispose();
    _buyerPhoneController.dispose();
    _buyerEmailController.dispose();
    _commentController.dispose();
    _downPaymentController.dispose();
    _monthsController.dispose();
    _barterSubjectController.dispose();
    _barterAmountController.dispose();
    for (final c in _customFieldControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _totalPrice => widget.apartment?.totalPrice ?? widget.parking?.price ?? 0;
  double get _downPayment => double.tryParse(_downPaymentController.text) ?? 0;
  int get _months => int.tryParse(_monthsController.text) ?? 12;
  double get _barterAmount => _selectedDealType == DealType.mixed
      ? (double.tryParse(_barterAmountController.text) ?? 0)
      : 0;

  double get _installmentSum =>
      (_totalPrice - _downPayment - _barterAmount).clamp(0.0, double.infinity);

  double get _monthlyPayment =>
      _months > 0 ? (_installmentSum / _months) : 0;

  List<InstallmentScheduleRow> get _currentSchedule {
    return PaymentDetails.generateSchedule(
      totalInstallmentSum: _installmentSum,
      months: _months,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final controller = ChessGridController.instance;
    final safeRoleIndex = controller.roleSettings.isNotEmpty
        ? _selectedRoleIndex.clamp(0, controller.roleSettings.length - 1)
        : 0;
    final role = controller.roleSettings.isNotEmpty
        ? controller.roleSettings[safeRoleIndex]
        : const RoleBookingSetting(roleName: 'Менеджер', durationDays: 3);
    final reservedUntil = DateTime.now().add(Duration(days: role.durationDays));
    final dateFormat = DateFormat('dd.MM.yyyy');

    final isApartment = widget.apartment != null;
    final itemName = isApartment
        ? 'квартира № ${widget.apartment!.number}'
        : 'парковочное место ${widget.parking!.number}';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
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
              width: 38,
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Новый заказ',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        itemName,
                        style: TextStyle(
                          fontFamily: 'Golos',
                          fontSize: 12.5,
                          color: colors.buttonPrimaryBg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

          // Form fields
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Info Card
                  _buildSectionCard(
                    title: isApartment ? 'Данные квартиры' : 'Данные парковки',
                    child: Column(
                      children: [
                        _buildInfoRow('Комплекс', controller.complex.name),
                        if (isApartment) ...[
                          _buildInfoRow('Корпус', widget.apartment!.buildingName),
                          _buildInfoRow('Подъезд, этаж', 'Подъезд ${widget.apartment!.entrance}, ${widget.apartment!.floor} этаж'),
                          _buildInfoRow('Комнат', '${widget.apartment!.rooms} (${widget.apartment!.type})'),
                          _buildInfoRow('Площадь', '${widget.apartment!.totalArea} м²'),
                          _buildInfoRow('Цена за м²', '${widget.apartment!.pricePerSqm.toStringAsFixed(0)} \$'),
                        ] else ...[
                          _buildInfoRow('Тип парковки', widget.parking!.type),
                          _buildInfoRow('Площадь', '${widget.parking!.area} м²'),
                        ],
                        const Divider(height: 16),
                        _buildInfoRow(
                          'Общая стоимость',
                          '${_totalPrice.toStringAsFixed(0)} \$',
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Buyer & Booking Info
                  _buildSectionCard(
                    title: 'Покупатель и бронь',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RequiredFieldSlot(
                          invalid: _missingFields.contains('buyerName'),
                          focus: _firstMissingField == 'buyerName',
                          pulse: _fieldErrorPulse,
                          message: 'Укажите ФИО покупателя',
                          child: CustomTextField(
                            controller: _buyerNameController,
                            label: 'ФИО покупателя *',
                            hintText: 'Введите ФИО покупателя',
                            hasError: _missingFields.contains('buyerName'),
                            onChanged: (val) {
                              if (val.trim().isNotEmpty && _missingFields.contains('buyerName')) {
                                setState(() {
                                  _missingFields.remove('buyerName');
                                  if (_firstMissingField == 'buyerName') _firstMissingField = null;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        RequiredFieldSlot(
                          invalid: _missingFields.contains('buyerPhone'),
                          focus: _firstMissingField == 'buyerPhone',
                          pulse: _fieldErrorPulse,
                          message: 'Укажите номер телефона',
                          child: CustomPhoneNumberInput(
                            controller: _buyerPhoneController,
                            label: 'Телефон *',
                            onInputChanged: (val) {
                              _formattedBuyerPhone = val;
                              if (val.trim().isNotEmpty && _missingFields.contains('buyerPhone')) {
                                setState(() {
                                  _missingFields.remove('buyerPhone');
                                  if (_firstMissingField == 'buyerPhone') _firstMissingField = null;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _buyerEmailController,
                          label: 'Почта',
                          hintText: 'Введите email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _commentController,
                          label: 'Комментарий',
                          hintText: 'Введите комментарий',
                        ),
                        const SizedBox(height: 12),
                        SourceLeadWidget(
                          selectedSourceLead: _selectedSourceId,
                          onChanged: (val) {
                            setState(() => _selectedSourceId = val);
                          },
                        ),

                        // Custom fields for orders
                        for (final cf in controller.customFields.where((f) => f.scope == 'order')) ...[
                          const SizedBox(height: 12),
                          if (cf.isRequired)
                            RequiredFieldSlot(
                              invalid: _missingFields.contains('custom_${cf.id}'),
                              focus: _firstMissingField == 'custom_${cf.id}',
                              pulse: _fieldErrorPulse,
                              message: 'Поле «${cf.name}» обязательно',
                              child: CustomTextField(
                                controller: _customFieldControllers[cf.id]!,
                                label: '${cf.name} *',
                                hintText: 'Введите ${cf.name.toLowerCase()}',
                                keyboardType: cf.type == 'number' ? TextInputType.number : TextInputType.text,
                                hasError: _missingFields.contains('custom_${cf.id}'),
                                onChanged: (val) {
                                  if (val.trim().isNotEmpty && _missingFields.contains('custom_${cf.id}')) {
                                    setState(() {
                                      _missingFields.remove('custom_${cf.id}');
                                      if (_firstMissingField == 'custom_${cf.id}') _firstMissingField = null;
                                    });
                                  }
                                },
                              ),
                            )
                          else
                            CustomTextField(
                              controller: _customFieldControllers[cf.id]!,
                              label: cf.name,
                              hintText: 'Введите ${cf.name.toLowerCase()}',
                              keyboardType: cf.type == 'number' ? TextInputType.number : TextInputType.text,
                            ),
                        ],
                        const SizedBox(height: 14),

                        // Role & Reservation Duration Selector
                        Text(
                          'Роль и срок бронирования',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colors.borderSubtle),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: controller.roleSettings.isNotEmpty ? safeRoleIndex : null,
                              isExpanded: true,
                              items: List.generate(
                                controller.roleSettings.length,
                                (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text(
                                    '${controller.roleSettings[i].roleName}: бронь ${controller.roleSettings[i].durationDays} дн.',
                                    style: TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontSize: 13,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedRoleIndex = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colors.surfaceElevated.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Бронь будет действовать до:',
                                style: TextStyle(
                                  fontFamily: 'Golos',
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                ),
                              ),
                              Text(
                                dateFormat.format(reservedUntil),
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: colors.buttonPrimaryBg,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Payment & Deal Type
                  _buildSectionCard(
                    title: 'Оплата и условия сделки',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Тип сделки',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colors.borderSubtle),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<DealType>(
                              value: _selectedDealType,
                              isExpanded: true,
                              items: DealType.values.map((d) {
                                return DropdownMenuItem(
                                  value: d,
                                  child: Text(
                                    d.labelRu,
                                    style: TextStyle(
                                      fontFamily: 'Golos',
                                      fontSize: 13,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedDealType = val);
                              },
                            ),
                          ),
                        ),

                        // Mixed payment barter fields
                        if (_selectedDealType == DealType.mixed) ...[
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _barterSubjectController,
                            label: 'Предмет бартера',
                            hintText: 'Введите предмет бартера',
                          ),
                          const SizedBox(height: 10),
                          CustomTextField(
                            controller: _barterAmountController,
                            label: 'Сумма бартера',
                            hintText: 'Введите сумму',
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ],

                        // Installment fields
                        if (_selectedDealType != DealType.cash) ...[
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: _downPaymentController,
                                  label: 'Первый взнос',
                                  hintText: 'Введите сумму',
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
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
                                    label: 'Срок рассрочки, мес. *',
                                    hintText: 'Введите кол-во',
                                    keyboardType: TextInputType.number,
                                    hasError: _missingFields.contains('months'),
                                    onChanged: (val) {
                                      if (val.trim().isNotEmpty && _missingFields.contains('months')) {
                                        setState(() {
                                          _missingFields.remove('months');
                                          if (_firstMissingField == 'months') _firstMissingField = null;
                                        });
                                      }
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: colors.borderSubtle),
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow('Сумма в рассрочку', '${_installmentSum.toStringAsFixed(0)} \$'),
                                const SizedBox(height: 4),
                                _buildInfoRow(
                                  'Ежемесячный платёж',
                                  '${_monthlyPayment.toStringAsFixed(2)} \$',
                                  isBold: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Live Schedule Preview Button
                          OutlinedButton.icon(
                            onPressed: () {
                              final previewOrder = Order(
                                id: 'Предпросмотр',
                                apartmentId: widget.apartment?.id,
                                parkingId: widget.parking?.id,
                                buyerName: _buyerNameController.text.trim().isNotEmpty
                                    ? _buyerNameController.text.trim()
                                    : 'Покупатель (ФИО)',
                                buyerPhone: _buyerPhoneController.text,
                                buyerEmail: _buyerEmailController.text,
                                manager: role.roleName,
                                dealType: _selectedDealType,
                                price: _totalPrice,
                                status: OrderStatus.inProgress,
                                paymentDetails: PaymentDetails(
                                  downPayment: _downPayment,
                                  months: _months,
                                  installmentSum: _installmentSum,
                                  monthlyPayment: _monthlyPayment,
                                  barterSubject: _barterSubjectController.text,
                                  barterAmount: _barterAmount,
                                  schedule: _currentSchedule,
                                ),
                              );
                              PaymentScheduleSheet.show(context: context, order: previewOrder);
                            },
                            icon: const Icon(Icons.table_chart_outlined, size: 16),
                            label: const Text(
                              'Открыть график платежей',
                              style: TextStyle(fontFamily: 'Gilroy', fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.buttonPrimaryBg,
                              side: BorderSide(color: colors.buttonPrimaryBg),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.buttonPrimaryBg,
                        foregroundColor: colors.buttonPrimaryFg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Подтвердить и создать заказ',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
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

  void _handleSubmit() {
    final buyerName = _buyerNameController.text.trim();
    final buyerPhone = _formattedBuyerPhone.isNotEmpty
        ? _formattedBuyerPhone
        : _buyerPhoneController.text.trim();

    final missing = <String>[];
    if (buyerName.isEmpty) missing.add('buyerName');
    if (buyerPhone.isEmpty) missing.add('buyerPhone');
    if (_selectedDealType != DealType.cash) {
      if (_months <= 0) missing.add('months');
    }

    final controller = ChessGridController.instance;

    // Validate required custom fields for orders
    for (final cf in controller.customFields.where((f) => f.scope == 'order' && f.isRequired)) {
      final ctrl = _customFieldControllers[cf.id];
      if (ctrl == null || ctrl.text.trim().isEmpty) {
        missing.add('custom_${cf.id}');
      }
    }

    if (missing.isNotEmpty) {
      setState(() {
        _missingFields = missing.toSet();
        _firstMissingField = missing.first;
        _fieldErrorPulse++;
      });
      showCustomSnackBar(
        context: context,
        message: 'Заполните обязательные поля',
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

    // Collect custom fields
    final Map<int, String> customFieldsMap = {};
    for (final entry in _customFieldControllers.entries) {
      customFieldsMap[entry.key] = entry.value.text.trim();
    }

    final safeRoleIndex = controller.roleSettings.isNotEmpty
        ? _selectedRoleIndex.clamp(0, controller.roleSettings.length - 1)
        : 0;
    final roleName = controller.roleSettings.isNotEmpty
        ? controller.roleSettings[safeRoleIndex].roleName
        : 'Менеджер';

    final err = controller.createOrder(
      apartment: widget.apartment,
      parking: widget.parking,
      buyerName: buyerName,
      buyerPhone: _formattedBuyerPhone.isNotEmpty
          ? _formattedBuyerPhone
          : _buyerPhoneController.text.trim(),
      buyerEmail: _buyerEmailController.text.trim(),
      comment: _commentController.text.trim(),
      roleName: roleName,
      dealType: _selectedDealType,
      downPayment: _downPayment,
      months: _months,
      barterSubject: _barterSubjectController.text.trim(),
      barterAmount: _barterAmount,
      customFields: customFieldsMap,
      sourceId: _selectedSourceId,
    );

    if (err != null) {
      showCustomSnackBar(
        context: context,
        message: err,
        isSuccess: false,
      );
      return;
    }

    Navigator.pop(context); // close order dialog
    if (widget.apartment != null) {
      Navigator.pop(context); // close apartment sheet if open
    }

    showCustomSnackBar(
      context: context,
      message: 'Заказ успешно создан! Статус обновлён на «Бронь».',
      isSuccess: true,
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceElevated.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Golos',
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              fontSize: isBold ? 14 : 12,
              color: isBold ? colors.buttonPrimaryBg : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

