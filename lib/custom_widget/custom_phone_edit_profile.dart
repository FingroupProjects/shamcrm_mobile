import 'package:crm_task_manager/custom_widget/country_data_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomPhoneNumberInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onInputChanged;
  final String label;
  final String? selectedDialCode;
  final bool readOnly;
  final Map<String, int> phoneNumberLengths;

  CustomPhoneNumberInput({
    required this.controller,
    required this.label,
    this.onInputChanged,
    this.selectedDialCode,
    required this.phoneNumberLengths,
    this.readOnly = false,
  });

  @override
  _CustomPhoneNumberInputState createState() => _CustomPhoneNumberInputState();
}

class _CustomPhoneNumberInputState extends State<CustomPhoneNumberInput> {
  Country? selectedCountry;
  String? _errorText;
  bool _hasReachedMaxLength = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeCountry();
  }

  Future<void> _initializeCountry() async {
    // Читаем сохранённый код региона из SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    String? savedDialCode = prefs.getString('default_dial_code');
    
    debugPrint('CustomPhoneNumberInput: Сохранённый default_dial_code = $savedDialCode');
    debugPrint('CustomPhoneNumberInput: selectedDialCode из параметров = ${widget.selectedDialCode}');

    // Определяем, какой код использовать
    String? dialCodeToUse;
    
    if (widget.selectedDialCode != null && widget.selectedDialCode!.isNotEmpty) {
      // Если передан код явно - используем его
      dialCodeToUse = widget.selectedDialCode;
    } else if (savedDialCode != null && savedDialCode.isNotEmpty) {
      // Иначе используем сохранённый из настроек
      dialCodeToUse = savedDialCode;
    } else {
      // Иначе по умолчанию +992
      dialCodeToUse = '+992';
    }

    debugPrint('CustomPhoneNumberInput: Используем dialCode = $dialCodeToUse');

    // Ищем страну по коду
    selectedCountry = countries.firstWhere(
      (country) => country.dialCode == dialCodeToUse,
      orElse: () {
        debugPrint('CustomPhoneNumberInput: Страна с кодом $dialCodeToUse не найдена, используем TJ (+992)');
        return countries.firstWhere(
          (country) => country.name == "TJ",
          orElse: () => countries.first,
        );
      },
    );

    debugPrint('CustomPhoneNumberInput: Выбрана страна: ${selectedCountry?.name}, код: ${selectedCountry?.dialCode}');

    // Очищаем код страны из начального текста, если он присутствует
    if (widget.controller.text.startsWith(selectedCountry?.dialCode ?? '')) {
      widget.controller.text =
          widget.controller.text.substring(selectedCountry!.dialCode.length);
      debugPrint('CustomPhoneNumberInput: Очищен код страны из текста: ${widget.controller.text}');
    }

    // Валидируем начальный текст
    if (widget.controller.text.isNotEmpty) {
      _validatePhoneNumber(widget.controller.text);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _validatePhoneNumber(String value) {
    final maxLength = widget.phoneNumberLengths[selectedCountry?.dialCode] ?? 0;

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
      bool isPaste = (newValue.text.length - oldValue.text.length).abs() > 1;
      int maxLength = widget.phoneNumberLengths[selectedCountry?.dialCode] ?? 0;

      if (isPaste) {
        String newText = newValue.text;
        String? matchedDialCode;
        Country? matchedCountry;
        bool hasPlus = newText.startsWith('+');
        String checkText = hasPlus ? newText : '+' + newText;

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
          String phoneNumber = hasPlus
              ? newText.substring(matchedDialCode.length)
              : newText.substring(matchedDialCode.length - 1);

          if (RegExp(r'^\d*$').hasMatch(phoneNumber)) {
            int newMaxLength = widget.phoneNumberLengths[matchedDialCode] ?? 0;
            if (phoneNumber.length > newMaxLength) {
              phoneNumber = phoneNumber.substring(0, newMaxLength);
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                selectedCountry = matchedCountry;
                widget.controller.text = phoneNumber;
                _validatePhoneNumber(phoneNumber);
              });
              final formattedNumber = (matchedCountry?.dialCode ?? '') + phoneNumber;
              if (widget.onInputChanged != null) {
                widget.onInputChanged!(formattedNumber);
              }
            });

            return TextEditingValue(
              text: phoneNumber,
              selection: TextSelection.collapsed(offset: phoneNumber.length),
            );
          } else {
            return oldValue;
          }
        } else {
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
    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xffF4F7FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          readOnly: widget.readOnly,
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
                color: Colors.red,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color.fromARGB(255, 245, 90, 79),
                width: 1.5,
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
                      ],
                    ),
                  );
                }).toList(),
                onChanged: widget.readOnly
                    ? null
                    : (Country? newValue) {
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
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _phoneNumberPasteFormatter(),
          ],
          onChanged: widget.readOnly
              ? null
              : (value) {
                  final maxLength = widget.phoneNumberLengths[selectedCountry?.dialCode] ?? 0;
                  String phoneNumber = value;

                  if (value.length > maxLength) {
                    phoneNumber = value.substring(0, maxLength);
                    widget.controller.text = phoneNumber;
                    widget.controller.selection =
                        TextSelection.fromPosition(TextPosition(offset: maxLength));
                  }

                  _validatePhoneNumber(phoneNumber);
                   // ✅ ИСПРАВЛЕНО: отправляем код региона ТОЛЬКО если есть цифры
                String formattedNumber;
                if (phoneNumber.isEmpty) {
                  formattedNumber = ''; // Пустая строка, если нет номера
                } else {
                  formattedNumber = (selectedCountry?.dialCode ?? '') + phoneNumber;
                }

                  if (widget.onInputChanged != null) {
                    widget.onInputChanged!(formattedNumber);
                  }
                },
        ),
      ],
    );
  }
}