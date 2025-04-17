import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'country_data_list.dart';

class CustomPhoneNumberInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onInputChanged;
  final String? Function(String?)? validator;
  final String label;
  final String? selectedDialCode;

  CustomPhoneNumberInput({
    required this.controller,
    required this.label,
    this.onInputChanged,
    this.validator,
    this.selectedDialCode,
  });

  @override
  _CustomPhoneNumberInputState createState() => _CustomPhoneNumberInputState();
}

class _CustomPhoneNumberInputState extends State<CustomPhoneNumberInput> {
  Country? selectedCountry;
  String? _errorText;
  bool _hasReachedMaxLength = false;

  @override
  void initState() {
    super.initState();
    selectedCountry = countries.firstWhere(
      (country) => country.dialCode == widget.selectedDialCode,
      orElse: () => countries.first,
    );

    if (widget.controller.text.startsWith(selectedCountry?.dialCode ?? '')) {
      widget.controller.text =
          widget.controller.text.substring(selectedCountry!.dialCode.length);
    }
  }

  void _validatePhoneNumber(String value) {
    final maxLength = phoneNumberLengths[selectedCountry?.dialCode] ?? 0;

    setState(() {
      if (value.isEmpty) {
        _errorText = AppLocalizations.of(context)!.translate('field_required');
        _hasReachedMaxLength = false;
      } else if (value.length == maxLength) {
        _errorText = null;
        _hasReachedMaxLength = true;
      } else {
        _errorText =
            AppLocalizations.of(context)!.translate('error_phone_number');
        _hasReachedMaxLength = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          decoration: InputDecoration(
            hintText:
                AppLocalizations.of(context)!.translate('enter_phone_number'),
            hintStyle: TextStyle(
              fontFamily: 'Gilroy',
              color: Color(0xff99A4BA),
            ),
            errorText: _errorText,
            errorStyle: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 15,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.transparent,
                width: 0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.transparent,
                width: 0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Color(0xFFE53935), // Красный цвет для границы ошибки
                width: 1.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Color(
                    0xFFE53935), // Красный цвет для границы ошибки при фокусе
                width: 1.0,
              ),
            ),
            filled: true,
            fillColor: Color(0xffF4F7FD),
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            prefixIcon: DropdownButtonHideUnderline(
              child: DropdownButton<Country>(
                value: selectedCountry,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(6),
                menuMaxHeight: 500,
                itemHeight: 48,
                items: countries.map((Country country) {
                  return DropdownMenuItem<Country>(
                    value: country,
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Text(country.flag,
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 4),
                        Text(country.dialCode,
                            style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w500)),
                        const SizedBox(width: 4),
                        Text(country.name,
                            style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (Country? newValue) {
                  setState(() {
                    selectedCountry = newValue;
                    widget.controller.text = '';
                    _errorText = null;
                    _hasReachedMaxLength = false;
                    if (newValue != null && widget.onInputChanged != null) {
                      widget.onInputChanged!('');
                    }
                  });
                },
              ),
            ),
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (value) {
            final maxLength =
                phoneNumberLengths[selectedCountry?.dialCode] ?? 0;

            if (value.length > maxLength) {
              widget.controller.text = value.substring(0, maxLength);
              widget.controller.selection =
                  TextSelection.fromPosition(TextPosition(offset: maxLength));
              value = widget.controller.text;
            }

            _validatePhoneNumber(value);

            final phoneNumber = widget.controller.text;
            final formattedNumber = phoneNumber;

            if (widget.onInputChanged != null) {
              widget.onInputChanged!(
                  (selectedCountry?.dialCode ?? '') + formattedNumber);
            }
          },
          validator: widget.validator,
        ),
      ],
    );
  }
}
