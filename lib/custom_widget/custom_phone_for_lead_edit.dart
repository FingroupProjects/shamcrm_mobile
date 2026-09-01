import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crm_task_manager/custom_widget/country_data_list.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomPhoneNumberInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onInputChanged;
  final String? Function(String?)? validator;
  final String label;
  final String? selectedDialCode;

  const CustomPhoneNumberInput({
    super.key,
    required this.controller,
    required this.label,
    this.onInputChanged,
    this.validator,
    this.selectedDialCode,
  });

  @override
  State<CustomPhoneNumberInput> createState() => _CustomPhoneNumberInputState();
}

class _CustomPhoneNumberInputState extends State<CustomPhoneNumberInput> {
  Country? selectedCountry;
  String? _errorText;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeCountry();
  }

  Future<void> _initializeCountry() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedDialCode = prefs.getString('default_dial_code');

    debugPrint(
        'CustomPhoneNumberInput: Сохранённый default_dial_code = $savedDialCode');
    debugPrint(
        'CustomPhoneNumberInput: selectedDialCode из параметров = ${widget.selectedDialCode}');

    String? dialCodeToUse;

    if (widget.selectedDialCode != null &&
        widget.selectedDialCode!.isNotEmpty) {
      dialCodeToUse = widget.selectedDialCode;
    } else if (savedDialCode != null && savedDialCode.isNotEmpty) {
      dialCodeToUse = savedDialCode;
    } else {
      dialCodeToUse = '+992';
    }

    debugPrint('CustomPhoneNumberInput: Используем dialCode = $dialCodeToUse');

    selectedCountry = countries.firstWhere(
      (country) => country.dialCode == dialCodeToUse,
      orElse: () {
        debugPrint(
            'CustomPhoneNumberInput: Страна с кодом $dialCodeToUse не найдена, используем TJ (+992)');
        return countries.firstWhere(
          (country) => country.name == "TJ",
          orElse: () => countries.first,
        );
      },
    );

    // ✅ ИСПРАВЛЕНО: Очищаем код страны из текста контроллера
    if (widget.controller.text.startsWith(selectedCountry!.dialCode)) {
      widget.controller.text =
          widget.controller.text.substring(selectedCountry!.dialCode.length);
    }

    // ✅ ИСПРАВЛЕНО: отправляем ТОЛЬКО если есть номер
    if (widget.controller.text.isNotEmpty) {
      _validatePhoneNumber(widget.controller.text);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.onInputChanged != null) {
          String formattedNumber =
              selectedCountry!.dialCode + widget.controller.text;
          debugPrint(
              'CustomPhoneNumberInput: Инициализация - отправка "$formattedNumber"');
          widget.onInputChanged!(formattedNumber);
        }
      });
    } else {
      // ✅ НОВОЕ: Если поле пустое, ничего не отправляем
      debugPrint(
          'CustomPhoneNumberInput: Инициализация - поле пустое, ничего не отправляем');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _validatePhoneNumber(String value) {
    final maxLength = phoneNumberLengths[selectedCountry?.dialCode] ?? 0;
    setState(() {
      if (value.isEmpty) {
        _errorText = AppLocalizations.of(context)!.translate('field_required');
      } else if (!RegExp(r'^\d+$').hasMatch(value)) {
        _errorText =
            AppLocalizations.of(context)!.translate('invalid_phone_format');
      } else if (value.length == maxLength) {
        _errorText = null;
      } else {
        _errorText =
            AppLocalizations.of(context)!.translate('error_phone_number');
      }
    });
  }

  TextInputFormatter _phoneNumberPasteFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      int maxLength = phoneNumberLengths[selectedCountry?.dialCode] ?? 0;
      String newText = newValue.text;
      newText = newText.replaceAll(RegExp(r'[^\d]'), '');

      bool isPaste = (newValue.text.length - oldValue.text.length).abs() > 1;

      if (isPaste) {
        String? matchedDialCode;
        Country? matchedCountry;
        bool hasPlus = newText.startsWith('+');
        String checkText = hasPlus ? newText : '+$newText';

        for (var code in countryCodes) {
          if (checkText.startsWith(code) &&
              (matchedDialCode == null ||
                  code.length > matchedDialCode.length)) {
            matchedDialCode = code;
            matchedCountry = countries.firstWhere(
              (country) => country.dialCode == code,
              orElse: () => Country(name: '', flag: '', dialCode: ''),
            );
          }
        }

        if (matchedDialCode != null &&
            matchedCountry != null &&
            matchedCountry.name.isNotEmpty) {
          String phoneNumber = hasPlus
              ? newText.substring(matchedDialCode.length)
              : newText.substring(matchedDialCode.length - 1);

          if (RegExp(r'^\d*$').hasMatch(phoneNumber)) {
            int newMaxLength = phoneNumberLengths[matchedDialCode] ?? 0;
            if (phoneNumber.length > newMaxLength) {
              phoneNumber = phoneNumber.substring(0, newMaxLength);
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                selectedCountry = matchedCountry;
                widget.controller.text = phoneNumber;
                _validatePhoneNumber(phoneNumber);
              });

              // ✅ ИСПРАВЛЕНО: отправляем код региона ТОЛЬКО если есть цифры
              if (widget.onInputChanged != null) {
                String formattedNumber;
                if (phoneNumber.isEmpty) {
                  formattedNumber = '';
                } else {
                  formattedNumber = matchedCountry!.dialCode + phoneNumber;
                }
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _validatePhoneNumber(phoneNumber);

            // ✅ ИСПРАВЛЕНО: отправляем код региона ТОЛЬКО если есть цифры
            if (widget.onInputChanged != null) {
              String formattedNumber;
              if (phoneNumber.isEmpty) {
                formattedNumber = '';
              } else {
                formattedNumber = selectedCountry!.dialCode + phoneNumber;
              }
              widget.onInputChanged!(formattedNumber);
            }
          });
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _validatePhoneNumber(phoneNumber);

          // ✅ ИСПРАВЛЕНО: отправляем код региона ТОЛЬКО если есть цифры
          if (widget.onInputChanged != null) {
            String formattedNumber;
            if (phoneNumber.isEmpty) {
              formattedNumber = '';
            } else {
              formattedNumber = selectedCountry!.dialCode + phoneNumber;
            }
            widget.onInputChanged!(formattedNumber);
          }
        });
        return TextEditingValue(
          text: phoneNumber,
          selection: TextSelection.collapsed(offset: phoneNumber.length),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fieldFill = colors.fieldBg;
    final fieldBorder = colors.borderSubtle;
    final focusedBorder = colors.buttonPrimaryBg.withValues(alpha: 0.6);

    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: context.appTextStyles.labelLg.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: fieldFill,
              borderRadius: context.appRadius.input,
              border: Border.all(color: fieldBorder),
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
          style: context.appTextStyles.labelLg.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          decoration: InputDecoration(
            hintText:
                AppLocalizations.of(context)!.translate('enter_phone_number'),
            hintStyle: context.appTextStyles.bodyMd.copyWith(
              color: context.appColors.fieldHint,
            ),
            errorText: _errorText,
            errorStyle: context.appTextStyles.bodyMd.copyWith(
              color: context.appColors.error,
              fontWeight: FontWeight.w500,
            ),
            border: OutlineInputBorder(
              borderRadius: context.appRadius.input,
              borderSide: BorderSide(color: fieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: context.appRadius.input,
              borderSide: BorderSide(color: fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: context.appRadius.input,
              borderSide: BorderSide(color: focusedBorder, width: 1.2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: context.appRadius.input,
              borderSide: BorderSide(
                color: context.appColors.error,
                width: 1.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: context.appRadius.input,
              borderSide: BorderSide(
                color: context.appColors.error,
                width: 1.0,
              ),
            ),
            filled: true,
            fillColor: context.appColors.fieldBg,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            prefixIcon: DropdownButtonHideUnderline(
              child: DropdownButton<Country>(
                value: selectedCountry,
                dropdownColor: context.appColors.surfacePrimary,
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
                        Text(
                          country.dialCode,
                          style: context.appTextStyles.bodyLg.copyWith(
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
                  });

                  // ✅ ИСПРАВЛЕНО: отправляем пустую строку при смене региона
                  if (newValue != null && widget.onInputChanged != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      widget.onInputChanged!('');
                    });
                  }
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
            final maxLength =
                phoneNumberLengths[selectedCountry?.dialCode] ?? 0;
            String phoneNumber = value;

            if (value.length > maxLength) {
              phoneNumber = value.substring(0, maxLength);
              widget.controller.text = phoneNumber;
              widget.controller.selection =
                  TextSelection.fromPosition(TextPosition(offset: maxLength));
            }

            _validatePhoneNumber(phoneNumber);

            // ✅ ИСПРАВЛЕНО: отправляем код региона ТОЛЬКО если есть цифры
            if (widget.onInputChanged != null) {
              String formattedNumber;
              if (phoneNumber.isEmpty) {
                formattedNumber = ''; // Пустая строка, если нет номера
              } else {
                formattedNumber = selectedCountry!.dialCode + phoneNumber;
              }

              debugPrint(
                  'CustomPhoneNumberInput: phoneNumber = "$phoneNumber", formattedNumber = "$formattedNumber"');
              widget.onInputChanged!(formattedNumber);
            }
          },
          validator: widget.validator,
        ),
      ],
    );
  }
}
