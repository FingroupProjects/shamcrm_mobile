import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Country {
  final String name;
  final String flag; // Иконка флага
  final String dialCode; // Код страны

  Country({
    required this.name,
    required this.flag,
    required this.dialCode,
  });
}

List<Country> countries = [
  Country(name: "TJ", flag: "🇹🇯", dialCode: "+992"),
  Country(name: "RU", flag: "🇷🇺", dialCode: "+7"),
  Country(name: "UZ", flag: "🇺🇿", dialCode: "+998"),
  Country(name: "KG", flag: "🇰🇬", dialCode: "+996"),
  Country(name: "KZ", flag: "🇰🇿", dialCode: "+7"),
  
];

class CustomPhoneNumberInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onInputChanged; // Принимает строку
  final String? Function(String?)? validator;
  final String label; // Новый параметр для метки

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

  final Map<String, int> phoneNumberLengths = {
    '+992': 9,
    '+7': 10,
    '+998': 9,
    '+996': 9,
  };

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
          style: const TextStyle(
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
            hintText: AppLocalizations.of(context)!.translate('enter_phone_number'), 
            hintStyle: const TextStyle(
              fontFamily: 'Gilroy',
              color: Color(0xff99A4BA),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color(0xffF4F7FD),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            prefixIcon: DropdownButtonHideUnderline(
              child: DropdownButton<Country>(
                value: selectedCountry,
                dropdownColor: Colors.white,
                items: countries.map((Country country) {
                  return DropdownMenuItem<Country>(
                    value: country,
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Text(country.flag), // Флаг страны
                        const SizedBox(width: 8),
                        Text(country.dialCode), // Код страны
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (Country? newValue) {
                  setState(() {
                    selectedCountry = newValue;
                    widget.controller.text = ''; // Очистка поля ввода
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
            final maxLength =
                phoneNumberLengths[selectedCountry?.dialCode] ?? 0;

            if (value.length > maxLength) {
              widget.controller.text = value.substring(0, maxLength);
              widget.controller.selection =
                  TextSelection.fromPosition(TextPosition(offset: maxLength));
            }

            final formattedNumber =
                (selectedCountry?.dialCode ?? '') + widget.controller.text;
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
