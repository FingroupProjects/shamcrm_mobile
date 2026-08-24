import 'package:crm_task_manager/custom_widget/country_data_list.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_number_input.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/models/page_2/employee_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class EmployeeFormFields extends StatelessWidget {
  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final TextEditingController birthDateController;
  final TextEditingController positionController;
  final TextEditingController addressController;
  final TextEditingController salaryController;
  final Country? initialCountry;
  final ValueChanged<String>? onPhoneChanged;
  final String? Function(String?)? phoneValidator;

  const EmployeeFormFields({
    super.key,
    required this.fullNameController,
    required this.phoneController,
    required this.birthDateController,
    required this.positionController,
    required this.addressController,
    required this.salaryController,
    this.initialCountry,
    this.onPhoneChanged,
    this.phoneValidator,
  });

  static String formatBirthDateForInput(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('dd/MM/yyyy').format(parsed);
  }

  static String? birthDateToIso(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    try {
      final parsed = DateFormat('dd/MM/yyyy').parseStrict(trimmed);
      return DateTime.utc(parsed.year, parsed.month, parsed.day)
          .toIso8601String();
    } catch (_) {
      return DateTime.tryParse(trimmed)?.toUtc().toIso8601String();
    }
  }

  static EmployeeModel toEmployee({
    int id = 0,
    required TextEditingController fullNameController,
    required TextEditingController phoneController,
    required TextEditingController birthDateController,
    required TextEditingController positionController,
    required TextEditingController addressController,
    required TextEditingController salaryController,
    String? fullPhone,
  }) {
    return EmployeeModel(
      id: id,
      fullName: fullNameController.text.trim(),
      phone: _nullable(
        phoneController.text.isNotEmpty ? (fullPhone ?? phoneController.text) : '',
      ),
      birthDate: birthDateToIso(birthDateController.text),
      position: _nullable(positionController.text),
      address: _nullable(addressController.text),
      salary: _nullable(salaryController.text.replaceAll(' ', '')),
    );
  }

  static ({String phone, Country? country}) splitPhone(String? raw) {
    var phoneNumber = raw ?? '';
    Country? country;
    if (phoneNumber.isNotEmpty) {
      for (final code in countryCodes) {
        if (phoneNumber.startsWith(code)) {
          phoneNumber = phoneNumber.substring(code.length);
          try {
            country = countries.firstWhere((item) => item.dialCode == code);
          } catch (_) {
            country = null;
          }
          break;
        }
      }
    }
    return (phone: phoneNumber, country: country);
  }

  static String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _required(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.translate('field_required') ??
          'Поле обязательно';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: fullNameController,
          label: l10n.translate('full_name'),
          hintText: l10n.translate('enter_full_name'),
          validator: (value) => _required(context, value),
        ),
        const SizedBox(height: 16),
        CustomPhoneNumberInput(
          controller: phoneController,
          label: l10n.translate('phone'),
          initialCountry: initialCountry,
          onInputChanged: onPhoneChanged,
          validator: phoneValidator,
        ),
        const SizedBox(height: 16),
        CustomTextFieldDate(
          controller: birthDateController,
          label: l10n.translate('birth_date'),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: positionController,
          label: l10n.translate('position'),
          hintText: l10n.translate('enter_position'),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: addressController,
          label: l10n.translate('employee_address'),
          hintText: l10n.translate('enter_address'),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: salaryController,
          label: l10n.translate('salary'),
          hintText: l10n.translate('enter_salary'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9., ]')),
          ],
        ),
      ],
    );
  }
}
