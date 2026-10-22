import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';

class ComplexAddSheet extends StatefulWidget {
  const ComplexAddSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const ComplexAddSheet(),
      ),
    );
  }

  @override
  State<ComplexAddSheet> createState() => _ComplexAddSheetState();
}

class _ComplexAddSheetState extends State<ComplexAddSheet> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _buildingCountController = TextEditingController(text: '2');
  final _salesAddressController = TextEditingController();
  final _salesPhoneController = TextEditingController();
  final _salesEmailController = TextEditingController();
  final _salesHoursController = TextEditingController(text: '09:00 – 18:00');

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _buildingCountController.dispose();
    _salesAddressController.dispose();
    _salesPhoneController.dispose();
    _salesEmailController.dispose();
    _salesHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Добавление объекта (ЖК)',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: colors.textPrimary,
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

          // Form fields in Lead style
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: _nameController,
                    hintText: 'Например: ЖК «Панорама»',
                    label: 'Название объекта (ЖК) *',
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: _addressController,
                    hintText: 'Город, улица, дом',
                    label: 'Адрес ЖК *',
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: _buildingCountController,
                    hintText: '2',
                    label: 'Количество корпусов ЖК',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),

                  // Sales Office Block (TZ Section 1)
                  Text(
                    'Данные отдела продаж',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  CustomTextField(
                    controller: _salesAddressController,
                    hintText: 'Адрес офиса продаж',
                    label: 'Адрес отдела продаж',
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: _salesPhoneController,
                    hintText: '+992 ...',
                    label: 'Телефон',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: _salesEmailController,
                    hintText: 'sales@example.com',
                    label: 'Электронная почта',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: _salesHoursController,
                    hintText: 'Пн-Сб, 9:00 - 18:00',
                    label: 'Режим работы',
                  ),
                  const SizedBox(height: 24),

                  // Submit button in Lead style
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
                        'Создать жилой комплекс',
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

  void _handleSubmit() {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty) {
      showCustomSnackBar(
        context: context,
        message: 'Пожалуйста, укажите название ЖК',
        isSuccess: false,
      );
      return;
    }

    if (address.isEmpty) {
      showCustomSnackBar(
        context: context,
        message: 'Пожалуйста, укажите адрес ЖК',
        isSuccess: false,
      );
      return;
    }

    final buildingCount = int.tryParse(_buildingCountController.text) ?? 1;

    ChessGridController.instance.addComplex(
      name: name,
      address: address,
      buildingCount: buildingCount,
      salesAddress: _salesAddressController.text.trim(),
      phone: _salesPhoneController.text.trim(),
      email: _salesEmailController.text.trim(),
      workingHours: _salesHoursController.text.trim(),
    );

    Navigator.pop(context);
    showCustomSnackBar(
      context: context,
      message: 'Жилой комплекс «$name» успешно создан!',
      isSuccess: true,
    );
  }
}

