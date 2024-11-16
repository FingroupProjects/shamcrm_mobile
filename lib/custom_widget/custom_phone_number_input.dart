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
                      widget.onInputChanged!(
                          newValue.dialCode); // Передаем код страны
                    }
                  });
                },
              ),
            ),
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter
                .digitsOnly, // Restrict input to digits only
          ],
          onChanged: (value) {
            final maxLength =
                phoneNumberLengths[selectedCountry?.dialCode] ?? 0;

            if (value.length > maxLength) {
              widget.controller.text = value.substring(0, maxLength);
              widget.controller.selection =
                  TextSelection.fromPosition(TextPosition(offset: maxLength));
            }

            // Форматирование номера телефона с кодом страны
            final formattedNumber =
                (selectedCountry?.dialCode ?? '') + widget.controller.text;
            if (widget.onInputChanged != null) {
              widget.onInputChanged!(
                  formattedNumber); // Передача номера с кодом страны
            }
          },
          validator: widget.validator,
        ),
      ],
    );
  }
}
