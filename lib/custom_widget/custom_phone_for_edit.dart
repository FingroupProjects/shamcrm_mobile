import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crm_task_manager/custom_widget/country_data_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

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
    // Инициализация начальной страны
    selectedCountry = countries.firstWhere(
      (country) => country.dialCode == widget.selectedDialCode,
      orElse: () => countries.firstWhere((country) => country.name == "TJ"),
    );

    // Очищаем код страны из начального текста, если он присутствует
    if (widget.controller.text.startsWith(selectedCountry?.dialCode ?? '')) {
      widget.controller.text =
          widget.controller.text.substring(selectedCountry!.dialCode.length);
    }

    // Валидируем начальный текст
    if (widget.controller.text.isNotEmpty) {
      _validatePhoneNumber(widget.controller.text);
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
        _errorText = AppLocalizations.of(context)!.translate('error_phone_number');
        _hasReachedMaxLength = false;
      }
    });
  }

  TextInputFormatter _phoneNumberPasteFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      int maxLength = phoneNumberLengths[selectedCountry?.dialCode] ?? 0;
      String newText = newValue.text;

      // Проверяем, является ли ввод вставкой
      bool isPaste = (newValue.text.length - oldValue.text.length).abs() > 1;

      if (isPaste) {
        String? matchedDialCode;
        Country? matchedCountry;
        bool hasPlus = newText.startsWith('+');
        String checkText = hasPlus ? newText : '+' + newText;

        // Проверяем, начинается ли текст с кода страны
        for (var code in countryCodes) {
          if (checkText.startsWith(code) && (matchedDialCode == null || code.length > matchedDialCode.length)) {
            matchedDialCode = code;
            matchedCountry = countries.firstWhere(
              (country) => country.dialCode == code,
              orElse: () => Country(name: '', flag: '', dialCode: ''),
            );
          }
        }

        if (matchedDialCode != null && matchedCountry != null && matchedCountry.name.isNotEmpty) {
          // Извлекаем номер без кода страны
          String phoneNumber = hasPlus
              ? newText.substring(matchedDialCode.length)
              : newText.substring(matchedDialCode.length - 1);
          
          // Проверяем, что номер состоит только из цифр
          if (RegExp(r'^\d*$').hasMatch(phoneNumber)) {
            int newMaxLength = phoneNumberLengths[matchedDialCode] ?? 0;
            if (phoneNumber.length > newMaxLength) {
              phoneNumber = phoneNumber.substring(0, newMaxLength);
            }

            // Обновляем состояние
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                selectedCountry = matchedCountry;
                widget.controller.text = phoneNumber;
                _validatePhoneNumber(phoneNumber);
              });
              // Передаём только код страны в onInputChanged
              if (widget.onInputChanged != null) {
                widget.onInputChanged!(matchedCountry!.dialCode);
              }
            });

            return TextEditingValue(
              text: phoneNumber,
              selection: TextSelection.collapsed(offset: phoneNumber.length),
            );
          } else {
            return oldValue; // Отклоняем вставку, если номер содержит не цифры
          }
        } else {
          // Если код страны не найден, обрабатываем как обычный номер
          String phoneNumber = newText;
          if (phoneNumber.length > maxLength) {
            phoneNumber = phoneNumber.substring(0, maxLength);
          }
          _validatePhoneNumber(phoneNumber);
          return TextEditingValue(
            text: phoneNumber,
            selection: TextSelection.collapsed(offset: phoneNumber.length),
          );
        }
      } else {
        // Ручной ввод или удаление
        String phoneNumber = newValue.text;
        if (phoneNumber.length > maxLength) {
          phoneNumber = phoneNumber.substring(0, maxLength);
        }
        _validatePhoneNumber(phoneNumber);
        return TextEditingValue(
          text: phoneNumber,
          selection: TextSelection.collapsed(offset: phoneNumber.length),
        );
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
            errorText: _errorText,
            errorStyle: const TextStyle(
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
              borderSide: const BorderSide(
                color: Colors.transparent,
                width: 0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.transparent,
                width: 0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE53935),
                width: 1.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE53935),
                width: 1.0,
              ),
            ),
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
                        Text(
                          country.dialCode,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          country.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                      widget.onInputChanged!(newValue.dialCode);
                    }
                  });
                },
              ),
            ),
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _phoneNumberPasteFormatter(),
          ],
          onChanged: (value) {
            final maxLength = phoneNumberLengths[selectedCountry?.dialCode] ?? 0;
            String phoneNumber = value;

            if (value.length > maxLength) {
              phoneNumber = value.substring(0, maxLength);
              widget.controller.text = phoneNumber;
              widget.controller.selection =
                  TextSelection.fromPosition(TextPosition(offset: maxLength));
            }

            _validatePhoneNumber(phoneNumber);
            // Передаём только код страны в onInputChanged
            if (widget.onInputChanged != null) {
              widget.onInputChanged!(selectedCountry?.dialCode ?? '');
            }
          },
          validator: widget.validator,
        ),
      ],
    );
  }
}