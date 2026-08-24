import 'package:crm_task_manager/bloc/page_2_BLOC/employee_bloc/employee_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/employee_bloc/employee_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/employee_bloc/employee_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/country_data_list.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/page_2/employee_model.dart';
import 'package:crm_task_manager/page_2/warehouse/employee/employee_form_fields.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditEmployeeScreen extends StatefulWidget {
  final EmployeeModel employee;

  const EditEmployeeScreen({super.key, required this.employee});

  @override
  State<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _positionController;
  late final TextEditingController _addressController;
  late final TextEditingController _salaryController;
  late String _selectedDialCode;
  Country? _initialCountry;

  @override
  void initState() {
    super.initState();
    final parsedPhone = EmployeeFormFields.splitPhone(widget.employee.phone);
    _fullNameController =
        TextEditingController(text: widget.employee.fullName);
    _phoneController = TextEditingController(text: parsedPhone.phone);
    _selectedDialCode = widget.employee.phone ?? '';
    _initialCountry = parsedPhone.country;
    _birthDateController = TextEditingController(
      text: EmployeeFormFields.formatBirthDateForInput(widget.employee.birthDate),
    );
    _positionController =
        TextEditingController(text: widget.employee.position ?? '');
    _addressController =
        TextEditingController(text: widget.employee.address ?? '');
    _salaryController = TextEditingController(
      text: widget.employee.salary?.replaceAll('.00', '') ?? '',
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _positionController.dispose();
    _addressController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.translate('field_required');
    }

    String dialCode = '';
    for (final code in countryCodes) {
      if (_selectedDialCode.startsWith(code)) {
        dialCode = code;
        break;
      }
    }

    final expectedLength = phoneNumberLengths[dialCode];
    if (expectedLength != null && value.length != expectedLength) {
      return (AppLocalizations.of(context)!.translate('invalid_phone_length'))
          .replaceAll('{expectedLength}', expectedLength.toString());
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final employee = EmployeeFormFields.toEmployee(
      id: widget.employee.id,
      fullNameController: _fullNameController,
      phoneController: _phoneController,
      birthDateController: _birthDateController,
      positionController: _positionController,
      addressController: _addressController,
      salaryController: _salaryController,
      fullPhone: _selectedDialCode,
    );
    context
        .read<EmployeeBloc>()
        .add(UpdateEmployee(employee, widget.employee.id));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: colors.surfacePrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.iconPrimary, size: 24),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          l10n.translate('edit_employee'),
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: BlocListener<EmployeeBloc, EmployeeState>(
        listener: (context, state) {
          if (state is EmployeeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.translate(state.message),
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colors.textInverse,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: colors.error,
              ),
            );
          } else if (state is EmployeeSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.translate(state.message),
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colors.textInverse,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: colors.success,
              ),
            );
            Navigator.pop(context, true);
          }
        },
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: EmployeeFormFields(
                      fullNameController: _fullNameController,
                      phoneController: _phoneController,
                      birthDateController: _birthDateController,
                      positionController: _positionController,
                      addressController: _addressController,
                      salaryController: _salaryController,
                      initialCountry: _initialCountry,
                      onPhoneChanged: (number) {
                        setState(() => _selectedDialCode = number);
                      },
                      phoneValidator: _validatePhone,
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
                        buttonText: l10n.translate('close'),
                        buttonColor: colors.backgroundSecondary,
                        textColor: colors.textPrimary,
                        onPressed: () => Navigator.pop(context, false),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: BlocBuilder<EmployeeBloc, EmployeeState>(
                        builder: (context, state) {
                          if (state is EmployeeLoading) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: colors.buttonPrimaryBg,
                              ),
                            );
                          }
                          return CustomButton(
                            buttonText: l10n.translate('save'),
                            buttonColor: colors.buttonPrimaryBg,
                            textColor: colors.textInverse,
                            onPressed: _save,
                          );
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
