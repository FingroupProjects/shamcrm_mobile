import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_number_input.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/country_data_list.dart';
import 'package:crm_task_manager/models/page_2/supplier_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditSupplierScreen extends StatefulWidget {
  final Supplier supplier;

  const EditSupplierScreen({Key? key, required this.supplier})
      : super(key: key);

  @override
  _EditSupplierScreenState createState() => _EditSupplierScreenState();
}

class _EditSupplierScreenState extends State<EditSupplierScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController innController;
  late TextEditingController noteController;

  String selectedDialCode = '';
  Country? initialCountry;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.supplier.name);

    // Extract phone number without dial code and find the country
    String? phoneNumber = widget.supplier.phone;
    String dialCode = '';

    if (phoneNumber?.isNotEmpty ?? false) {
      // Find matching dial code from the phone number
      for (var code in countryCodes) {
        if (phoneNumber!.startsWith(code)) {
          dialCode = code;
          phoneNumber = phoneNumber.substring(code.length);
          // Find the country that matches this dial code
          try {
            initialCountry = countries.firstWhere(
                  (country) => country.dialCode == code,
            );
          } catch (e) {
            // If not found, use default
            initialCountry = null;
          }
          break;
        }
      }
    }

    phoneController = TextEditingController(text: phoneNumber);
    innController = TextEditingController(text: widget.supplier.inn?.toString() ?? '');
    noteController = TextEditingController(text: widget.supplier.note);
    selectedDialCode = widget.supplier.phone ?? '';
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.red,
          elevation: 3,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          AppLocalizations.of(context)!.translate('edit_supplier') ??
              'Редактировать поставщика',
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),

      ),
      body: BlocListener<SupplierBloc, SupplierState>(
        listener: (context, state) {
          if (state is SupplierError) {
            _showErrorSnackBar(
                context,
                AppLocalizations.of(context)!.translate(state.message) ??
                    state.message);
          } else if (state is SupplierSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!
                      .translate('supplier_updated_successfully') ??
                      'Поставщик успешно обновлен',
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.green,
                elevation: 3,
                padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: const Duration(seconds: 3),
              ),
            );
            Navigator.pop(context);
          }
        },
        child: Form(
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
                        CustomTextField(
                          controller: nameController,
                          hintText: AppLocalizations.of(context)!
                              .translate('enter_supplier_name') ??
                              'Введите название поставщика',
                          label:
                          AppLocalizations.of(context)!.translate('name') ??
                              'Название',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!
                                  .translate('field_required') ??
                                  'Поле обязательно';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomPhoneNumberInput(
                          controller: phoneController,
                          initialCountry: initialCountry,
                          onInputChanged: (String number) {
                            setState(() {
                              selectedDialCode = number;
                            });
                          },
                          label: AppLocalizations.of(context)!
                              .translate('phone') ??
                              'Телефон',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!
                                  .translate('field_required') ??
                                  'Поле обязательно';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: innController,
                          hintText: AppLocalizations.of(context)!
                              .translate('enter_inn') ??
                              'Введите ИНН',
                          label:
                          AppLocalizations.of(context)!.translate('inn') ??
                              'ИНН',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: noteController,
                          hintText: AppLocalizations.of(context)!
                              .translate('enter_note') ??
                              'Введите примечание',
                          label:
                          AppLocalizations.of(context)!.translate('note') ??
                              'Примечание',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        buttonText:
                        AppLocalizations.of(context)!.translate('close') ??
                            'Отмена',
                        buttonColor: const Color(0xffF4F7FD),
                        textColor: Colors.black,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: BlocBuilder<SupplierBloc, SupplierState>(
                        builder: (context, state) {
                          if (state is SupplierLoading) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xff1E2E52),
                              ),
                            );
                          } else {
                            return CustomButton(
                              buttonText: AppLocalizations.of(context)!
                                  .translate('save') ??
                                  'Сохранить',
                              buttonColor: const Color(0xff4759FF),
                              textColor: Colors.white,
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  final supplier = Supplier(
                                    id: widget.supplier.id,
                                    name: nameController.text,
                                    phone: selectedDialCode.isNotEmpty && phoneController.text.isNotEmpty
                                        ? selectedDialCode
                                        : null,
                                    inn: innController.text.isNotEmpty
                                        ? int.tryParse(innController.text)
                                        : null,
                                    note: noteController.text.isNotEmpty
                                        ? noteController.text
                                        : null,
                                    createdAt: widget.supplier.createdAt,
                                    updatedAt: DateTime.now().toIso8601String(),
                                  );
                                  context.read<SupplierBloc>().add(
                                      UpdateSupplier(supplier, supplier.id));

                                  Navigator.pop(context);
                                }
                              },
                            );
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
}