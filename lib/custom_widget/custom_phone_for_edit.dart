import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Country {
  final String name;
  final String flag;
  final String dialCode;

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
  Country(name: "US", flag: "🇺🇸", dialCode: "+1"), // Added USA
  
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
  Country? selectedCountry;

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
    
    // Если есть начальное значение в контроллере
    if (widget.controller.text.isNotEmpty) {
      // Находим подходящую страну по началу номера телефона
      selectedCountry = countries.firstWhere(
        (country) => widget.controller.text.startsWith(country.dialCode),
        orElse: () => countries.first,
      );

      // Убираем код страны из номера
      if (widget.controller.text.startsWith(selectedCountry?.dialCode ?? '')) {
        widget.controller.text = widget.controller.text.substring(selectedCountry!.dialCode.length);
      }
    } else {
      // Если нет начального значения, используем выбранный код страны из параметров
      selectedCountry = countries.firstWhere(
        (country) => country.dialCode == widget.selectedDialCode,
        orElse: () => countries.first,
      );
    }
  }

  @override
  void didUpdateWidget(CustomPhoneNumberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Обновляем состояние при изменении входных данных
    if (widget.controller.text.isNotEmpty && 
        widget.controller.text != oldWidget.controller.text) {
      selectedCountry = countries.firstWhere(
        (country) => widget.controller.text.startsWith(country.dialCode),
        orElse: () => selectedCountry ?? countries.first,
      );

      if (widget.controller.text.startsWith(selectedCountry?.dialCode ?? '')) {
        widget.controller.text = widget.controller.text.substring(selectedCountry!.dialCode.length);
      }
    }
  }

  // Остальной код остается без изменений
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
                        Text(country.flag),
                        const SizedBox(width: 8),
                        Text(country.dialCode),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (Country? newValue) {
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