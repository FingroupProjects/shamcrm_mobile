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

    // Initialize controllers with empty values
    ourDutyController = TextEditingController();
    debtToUsController = TextEditingController();
  }

  @override
  void dispose() {
    ourDutyController.dispose();
    debtToUsController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, bool isSuccess) {
    debugPrint("SHOW _showSnackBar: $message");
    if (!mounted || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SupplierOpeningsBloc, SupplierOpeningsState>(
      listener: (context, state) {
        if (!mounted || !context.mounted) return;

        if (state is SupplierOpeningCreateSuccess) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && context.mounted) {
              // Just pop - the parent screen will show the success message
              Navigator.pop(context, true); // ✅ Return true to indicate success
            }
          });
        }

        if (state is SupplierOpeningCreateError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && context.mounted) {
              _showSnackBar(state.message, false);
            }
          });
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
            AppLocalizations.of(context)?.translate('add_supplier_opening') ?? 'Добавить остаток поставщика',
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
                          label: AppLocalizations.of(context)?.translate('our_duty') ?? 'Наш долг',
                          hintText: AppLocalizations.of(context)?.translate('enter_amount') ?? 'Введите сумму',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            PriceInputFormatter(),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)?.translate('field_required') ?? 'Обязательное поле';
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
                          label: AppLocalizations.of(context)?.translate('debt_to_us') ?? 'Долг поставщика',
                          hintText: AppLocalizations.of(context)?.translate('enter_amount') ?? 'Введите сумму',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            PriceInputFormatter(),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)?.translate('field_required') ?? 'Обязательное поле';
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
              BlocBuilder<SupplierOpeningsBloc, SupplierOpeningsState>(
                builder: (context, state) {
                  final isCreating = state is SupplierOpeningCreating;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            buttonText: AppLocalizations.of(context)?.translate('close') ?? 'Закрыть',
                            buttonColor: const Color(0xffF4F7FD),
                            textColor: Colors.black,
                            onPressed: isCreating
                                ? null
                                : () {
                                    Navigator.pop(context);
                                  },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            buttonText: AppLocalizations.of(context)?.translate('save') ?? 'Сохранить',
                            buttonColor: const Color(0xff4759FF),
                            textColor: Colors.white,
                            isLoading: isCreating,
                            onPressed: isCreating
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      // Create event for adding supplier opening
                                      context.read<SupplierOpeningsBloc>().add(
                                            CreateSupplierOpening(
                                              supplierId: widget.supplierId,
                                              ourDuty: double.parse(ourDutyController.text),
                                              debtToUs: double.parse(debtToUsController.text),
                                            ),
                                          );
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
