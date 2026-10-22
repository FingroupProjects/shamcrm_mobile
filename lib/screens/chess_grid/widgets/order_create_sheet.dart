import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/payment_schedule_sheet.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';

class OrderCreateSheet extends StatefulWidget {
  final Apartment apartment;

  const OrderCreateSheet({super.key, required this.apartment});

  static Future<void> show({
    required BuildContext context,
    required Apartment apartment,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: OrderCreateSheet(apartment: apartment),
      ),
    );
  }

  @override
  State<OrderCreateSheet> createState() => _OrderCreateSheetState();
}

class _OrderCreateSheetState extends State<OrderCreateSheet> {
  final _buyerNameController = TextEditingController();
  final _buyerPhoneController = TextEditingController();
  final _buyerEmailController = TextEditingController();
  final _commentController = TextEditingController();
  final _downPaymentController = TextEditingController();
  final _monthsController = TextEditingController(text: '12');
  final _barterSubjectController = TextEditingController();
  final _barterAmountController = TextEditingController(text: '0');

  DealType _selectedDealType = DealType.cash;
  int _selectedRoleIndex = 0;

  @override
  void initState() {
    super.initState();
    final totalPrice = widget.apartment.totalPrice;
    _downPaymentController.text = (totalPrice * 0.20).round().toString();
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
    super.dispose();
  }

  double get _totalPrice => widget.apartment.totalPrice;
  double get _downPayment => double.tryParse(_downPaymentController.text) ?? 0;
  int get _months => int.tryParse(_monthsController.text) ?? 12;
  double get _barterAmount => _selectedDealType == DealType.mixed
      ? (double.tryParse(_barterAmountController.text) ?? 0)
      : 0;

  double get _installmentSum =>
      (_totalPrice - _downPayment - _barterAmount).clamp(0.0, double.infinity);

  double get _monthlyPayment =>
      _months > 0 ? (_installmentSum / _months) : 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final controller = ChessGridController.instance;
    final role = controller.roleSettings[_selectedRoleIndex];

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
                      'Бронирование квартиры',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Кв. № ${widget.apartment.number} · ${_totalPrice.toStringAsFixed(0)} \$',
                      style: TextStyle(
                        fontFamily: 'Golos',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
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

          // Form fields in Lead style
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: _buyerNameController,
                    hintText: 'Фамилия Имя Отчество',
                    label: 'ФИО покупателя *',
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: _buyerPhoneController,
                    hintText: '+992 ...',
                    label: 'Номер телефона *',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: _buyerEmailController,
                    hintText: 'email@domain.com',
                    label: 'Электронная почта',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: _commentController,
                    hintText: 'Примечание к сделке',
                    label: 'Комментарий',
                  ),
                  const SizedBox(height: 18),

                  // Role & Reservation Duration Selector
                  Text(
                    'Роль менеджера и срок брони',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedRoleIndex,
                        isExpanded: true,
                        items: List.generate(
                          controller.roleSettings.length,
                          (i) => DropdownMenuItem(
                            value: i,
                            child: Text(
                              '${controller.roleSettings[i].roleName}: бронь на ${controller.roleSettings[i].durationDays} дн.',
                              style: TextStyle(
                                fontFamily: 'Golos',
                                fontSize: 13.5,
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
                  const SizedBox(height: 20),

                  // Deal Type Selector
                  Text(
                    'Условия сделки и тип оплаты',
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
                      _buildDealChip(DealType.cash, 'Наличными'),
                      const SizedBox(width: 8),
                      _buildDealChip(DealType.installment, 'Рассрочка'),
                      const SizedBox(width: 8),
                      _buildDealChip(DealType.mixed, 'Бартер'),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Mixed payment fields
                  if (_selectedDealType == DealType.mixed) ...[
                    CustomTextField(
                      controller: _barterSubjectController,
                      hintText: 'Автомобиль, земельный участок и др.',
                      label: 'Предмет бартера',
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _barterAmountController,
                      hintText: '0',
                      label: 'Сумма бартера, \$',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Installment calculation block
                  if (_selectedDealType != DealType.cash) ...[
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _downPaymentController,
                            hintText: '0',
                            label: 'Первый взнос, \$',
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _monthsController,
                            hintText: '12',
                            label: 'Срок, мес.',
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.buttonPrimaryBg.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colors.buttonPrimaryBg.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Сумма в рассрочку:',
                                style: TextStyle(
                                  fontFamily: 'Golos',
                                  fontSize: 13,
                                  color: colors.textSecondary,
                                ),
                              ),
                              Text(
                                '${_installmentSum.toStringAsFixed(0)} \$',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ежемесячный платёж:',
                                style: TextStyle(
                                  fontFamily: 'Golos',
                                  fontSize: 13,
                                  color: colors.textSecondary,
                                ),
                              ),
                              Text(
                                '${_monthlyPayment.toStringAsFixed(2)} \$ / мес.',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: colors.buttonPrimaryBg,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Button to open schedule
                    OutlinedButton.icon(
                      onPressed: () {
                        final previewOrder = Order(
                          id: 'Предпросмотр',
                          complexId: widget.apartment.complexId,
                          apartmentId: widget.apartment.id,
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
                            schedule: PaymentDetails.generateSchedule(
                              totalInstallmentSum: _installmentSum,
                              months: _months,
                            ),
                          ),
                        );
                        PaymentScheduleSheet.show(context: context, order: previewOrder);
                      },
                      icon: const Icon(Icons.table_view_rounded, size: 18),
                      label: const Text('График платежей'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.buttonPrimaryBg,
                        side: BorderSide(color: colors.buttonPrimaryBg),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.buttonPrimaryBg,
                        foregroundColor: colors.buttonPrimaryFg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Забронировать квартиру',
                        style: TextStyle(
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

  Widget _buildDealChip(DealType type, String label) {
    final colors = context.appColors;
    final isSelected = _selectedDealType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDealType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.buttonPrimaryBg
                : colors.surfaceElevated.withValues(alpha: 0.6),
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

  void _handleSubmit() {
    final buyerName = _buyerNameController.text.trim();
    if (buyerName.isEmpty) {
      showCustomSnackBar(
        context: context,
        message: 'Пожалуйста, укажите ФИО покупателя',
        isSuccess: false,
      );
      return;
    }

    final controller = ChessGridController.instance;

    final err = controller.createOrder(
      apartment: widget.apartment,
      buyerName: buyerName,
      buyerPhone: _buyerPhoneController.text.trim(),
      buyerEmail: _buyerEmailController.text.trim(),
      comment: _commentController.text.trim(),
      roleName: controller.roleSettings[_selectedRoleIndex].roleName,
      dealType: _selectedDealType,
      downPayment: _downPayment,
      months: _months,
      barterSubject: _barterSubjectController.text.trim(),
      barterAmount: _barterAmount,
    );

    if (err != null) {
      showCustomSnackBar(
        context: context,
        message: err,
        isSuccess: false,
      );
      return;
    }

    Navigator.pop(context); // close order sheet

    showCustomSnackBar(
      context: context,
      message: 'Квартира № ${widget.apartment.number} успешно забронирована!',
      isSuccess: true,
    );
  }
}
