import 'package:crm_task_manager/custom_widget/country_data_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class CustomPhoneNumberInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onInputChanged; 
  final String? Function(String?)? validator;
  final String label; 

  CustomPhoneNumberInput({
    required this.controller,
    required this.label,
    this.onInputChanged,
    this.validator,
  });

  @override
  _CustomPhoneNumberInputState createState() => _CustomPhoneNumberInputState();
}

class _CustomPhoneNumberInputState extends State<CustomPhoneNumberInput> {
  Country? selectedCountry;

  @override
  void initState() {
    super.initState();
    selectedCountry = countries.firstWhere((country) => country.name == "TJ");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 16,fontWeight: FontWeight.w500,fontFamily: 'Gilroy',color: Color(0xff1E2E52))),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.translate('enter_phone_number'), 
            hintStyle: const TextStyle(fontFamily: 'Gilroy', color: Color(0xff99A4BA)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),borderSide: BorderSide.none),
            filled: true,
            fillColor: const Color(0xffF4F7FD),
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
                    if (newValue != null && widget.onInputChanged != null) {
                      widget.onInputChanged!(newValue.dialCode);
                    }
                  });
                },
              ),
            ),
              errorStyle: const TextStyle(
              fontSize: 14, 
              // fontFamily: 'Gilroy',
              color: Colors.red,
              fontWeight: FontWeight.w400, 
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.transparent),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (value) {
            final maxLength = phoneNumberLengths[selectedCountry?.dialCode] ?? 0;
            if (value.length > maxLength) {
              widget.controller.text = value.substring(0, maxLength);
              widget.controller.selection =
                  TextSelection.fromPosition(TextPosition(offset: maxLength));
            }
            final formattedNumber = (selectedCountry?.dialCode ?? '') + widget.controller.text;
            if (widget.onInputChanged != null) {
              widget.onInputChanged!(formattedNumber);
            }
          },
          validator: widget.validator,
        ),
      ],
    );
  }
}
