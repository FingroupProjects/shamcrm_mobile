import 'package:crm_task_manager/custom_widget/country_data_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomPhoneNumberInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onInputChanged;
  final String label;
  final String? selectedDialCode;
  final bool readOnly; // Добавьте это поле

  CustomPhoneNumberInput({
    required this.controller,
    required this.label,
    this.onInputChanged,
    this.selectedDialCode,
    required Map<String, int> phoneNumberLengths,
    this.readOnly = false, // Добавьте это в конструктор с дефолтным значением
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
    if (widget.selectedDialCode != null) {
      selectedCountry = countries.firstWhere(
        (country) => country.dialCode == widget.selectedDialCode,
        orElse: () => countries.first,
      );
    } else {
      selectedCountry = countries.first;
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
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
                color: Colors.red,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color.fromARGB(255, 245, 90, 79),
                width: 1.5,
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
                        Text(country.flag, style: const TextStyle(fontSize: 24)), 
                        const SizedBox(width: 4),
                        Text(country.dialCode, style: const TextStyle(fontSize: 16, fontFamily: 'Gilroy',fontWeight: FontWeight.w500)), 
                        const SizedBox(width: 4),
                        Text(country.name, style: const TextStyle(fontSize: 16, fontFamily: 'Gilroy',fontWeight: FontWeight.w500)), 
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (Country? newValue) {
                  setState(() {
                    selectedCountry = newValue;
                    widget.controller.text = '';
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
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            final maxLength =
                phoneNumberLengths[selectedCountry?.dialCode] ?? 0;
            if (value.length > maxLength) {
              widget.controller.text = value.substring(0, maxLength);
              widget.controller.selection = TextSelection.fromPosition(
                TextPosition(offset: maxLength),
              );
              value = widget.controller.text;
            }

            _validatePhoneNumber(value);

            if (widget.onInputChanged != null) {
              widget.onInputChanged!(
                (selectedCountry?.dialCode ?? '') + widget.controller.text,
              );
            }
          },
        ),
      ],
    );
  }
}
