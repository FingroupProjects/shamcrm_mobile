import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CountryProfile {
  final String name;
  final String flag;
  final String dialCode;

  CountryProfile({
    required this.name,
    required this.flag,
    required this.dialCode,
  });
}

List<CountryProfile> countries = [
  CountryProfile(name: "TJ", flag: "🇹🇯", dialCode: "+992"),
  CountryProfile(name: "RU", flag: "🇷🇺", dialCode: "+7"),
  CountryProfile(name: "UZ", flag: "🇺🇿", dialCode: "+998"),
  CountryProfile(name: "KG", flag: "🇰🇬", dialCode: "+996"),
  CountryProfile(name: "KZ", flag: "🇰🇿", dialCode: "+7"),
  CountryProfile(name: "US", flag: "🇺🇸", dialCode: "+1"), // Added USA
];

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
  CountryProfile? selectedCountry;

  final Map<String, int> phoneNumberLengths = {
    '+992': 9,
    '+7': 10,
    '+998': 9,
    '+996': 9,
    '+1': 10, 
  };

  @override
  void initState() {
    super.initState();
    
  // Проверяем номер телефона на наличие кода страны
  String phoneNumber = widget.controller.text;
  
  // Ищем подходящий код страны в номере телефона
  selectedCountry = countries.firstWhere(
    (country) => phoneNumber.startsWith(country.dialCode),
    orElse: () => countries.firstWhere(
      (country) => country.dialCode == widget.selectedDialCode,
      orElse: () => countries.first,
    ),
  );

  // Убираем код страны из номера телефона
  if (phoneNumber.startsWith(selectedCountry?.dialCode ?? '')) {
    widget.controller.text = phoneNumber.substring(selectedCountry!.dialCode.length);
  }

  
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
            hintText: 'Введите номер телефона',
            hintStyle: TextStyle(
              fontFamily: 'Gilroy',
              color: Color(0xff99A4BA),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Color(0xffF4F7FD),
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            prefixIcon: DropdownButtonHideUnderline(
              child: DropdownButton<CountryProfile>(
                value: selectedCountry,
                dropdownColor: Colors.white,
                items: countries.map((CountryProfile country) {
                  return DropdownMenuItem<CountryProfile>(
                    value: country,
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Text(country.flag),
                        const SizedBox(width: 8),
                        Text(country.dialCode),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (CountryProfile? newValue) {
                  setState(() {
                    selectedCountry = newValue;
                    widget.controller.text = '';
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
            final maxLength = phoneNumberLengths[selectedCountry?.dialCode] ?? 0;

            if (value.length > maxLength) {
              widget.controller.text = value.substring(0, maxLength);
              widget.controller.selection =
                  TextSelection.fromPosition(TextPosition(offset: maxLength));
            }

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
