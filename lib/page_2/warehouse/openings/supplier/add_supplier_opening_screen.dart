import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/supplier/supplier_openings_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/supplier/supplier_openings_event.dart';
import '../../../../bloc/page_2_BLOC/openings/supplier/supplier_openings_state.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../../../../custom_widget/custom_button.dart';
import '../../../../custom_widget/custom_textfield.dart';
import '../../../../custom_widget/price_input_formatter.dart';

class AddSupplierOpeningScreen extends StatefulWidget {
  final String supplierName;
  final int supplierId;

  const AddSupplierOpeningScreen({
    Key? key,
    required this.supplierName,
    required this.supplierId,
  }) : super(key: key);

  @override
  _AddSupplierOpeningScreenState createState() => _AddSupplierOpeningScreenState();
}

class _AddSupplierOpeningScreenState extends State<AddSupplierOpeningScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for numeric fields
  late TextEditingController ourDutyController;
  late TextEditingController debtToUsController;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with default values
    ourDutyController = TextEditingController(text: '0');
    debtToUsController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    ourDutyController.dispose();
    debtToUsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SupplierOpeningsBloc, SupplierOpeningsState>(
      listener: (context, state) {
        if (state is SupplierOpeningsLoaded) {
          // Успешно создан остаток, закрываем экран
          Navigator.pop(context);

          // Показываем сообщение об успехе
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.translate('supplier_opening_created') ??
                    'Остаток поставщика создан',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is SupplierOpeningsError) {
          // Показываем ошибку
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          forceMaterialTransparency: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Image.asset(
              'assets/icons/arrow-left.png',
              width: 24,
              height: 24,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            AppLocalizations.of(context)?.translate('add_supplier_opening') ?? 
                'Добавить остаток поставщика',
            style: const TextStyle(
              fontSize: 18,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSupplierNameField(),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: ourDutyController,
                          label: AppLocalizations.of(context)?.translate('our_duty') ?? 
                              'Наш долг',
                          hintText: AppLocalizations.of(context)?.translate('enter_amount') ?? 
                              'Введите сумму',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            PriceInputFormatter(),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)?.translate('field_required') ?? 
                                  'Обязательное поле';
                            }
                            if (double.tryParse(value) == null) {
                              return AppLocalizations.of(context)?.translate('enter_correct_number') ?? 
                                  'Введите корректное число';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: debtToUsController,
                          label: AppLocalizations.of(context)?.translate('debt_to_us') ?? 
                              'Долг поставщика',
                          hintText: AppLocalizations.of(context)?.translate('enter_amount') ?? 
                              'Введите сумму',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            PriceInputFormatter(),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)?.translate('field_required') ?? 
                                  'Обязательное поле';
                            }
                            if (double.tryParse(value) == null) {
                              return AppLocalizations.of(context)?.translate('enter_correct_number') ?? 
                                  'Введите корректное число';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        buttonText:
                        AppLocalizations.of(context)?.translate('close') ?? 'Закрыть',
                        buttonColor: const Color(0xffF4F7FD),
                        textColor: Colors.black,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        buttonText:
                        AppLocalizations.of(context)?.translate('save') ?? 'Сохранить',
                        buttonColor: const Color(0xff4759FF),
                        textColor: Colors.white,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // Создаем событие для добавления остатка поставщика
                            context.read<SupplierOpeningsBloc>().add(
                              CreateSupplierOpening(
                                supplierId: widget.supplierId,
                                ourDuty: double.parse(ourDutyController.text),
                                debtToUs: double.parse(debtToUsController.text),
                              ),
                            );

                            // BlocListener автоматически обработает успешное создание
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.translate('supplier') ?? 'Поставщик',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xffF4F7FD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xffF4F7FD),
              width: 1,
            ),
          ),
          child: Text(
            widget.supplierName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
            ),
          ),
        ),
      ],
    );
  }

}

