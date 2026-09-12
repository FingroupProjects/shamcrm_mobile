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
    required this.controller,
    required this.label,
    this.onInputChanged,
    this.validator,
    this.selectedDialCode,
    super.key,
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

  @override
  void didUpdateWidget(covariant CustomPhoneNumberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDialCode != oldWidget.selectedDialCode &&
        widget.selectedDialCode != null) {
      final newCountry = countries.firstWhere(
        (country) => country.dialCode == widget.selectedDialCode,
        orElse: () => selectedCountry!,
      );
      if (newCountry != selectedCountry) {
        setState(() {
          selectedCountry = newCountry;
        });
      }
    }
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

    if (widget.controller.text.startsWith(selectedCountry!.dialCode)) {
      widget.controller.text =
          widget.controller.text.substring(selectedCountry!.dialCode.length);
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.controller.text.isNotEmpty) {
          _validatePhoneNumber(widget.controller.text);
          if (widget.onInputChanged != null) {
            widget.onInputChanged!(
                selectedCountry!.dialCode + widget.controller.text);
          }
        }
      });
    }
  }

  void _validatePhoneNumber(String value) {
    final maxLength = phoneNumberLengths[selectedCountry?.dialCode] ?? 15;
    final minLength = 5;
    setState(() {
      if (value.isEmpty) {
        _errorText = AppLocalizations.of(context)!.translate('field_required');
      } else if (!RegExp(r'^\d+$').hasMatch(value)) {
        _errorText =
            AppLocalizations.of(context)!.translate('invalid_phone_number');
      } else if (value.length < minLength) {
        _errorText =
            AppLocalizations.of(context)!.translate('phone_number_too_short');
      } else if (value.length > maxLength) {
        _errorText =
            AppLocalizations.of(context)!.translate('phone_number_too_long');
      } else {
        _errorText = null;
      }
    });
  }

  TextInputFormatter _phoneNumberPasteFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      int maxLength = phoneNumberLengths[selectedCountry?.dialCode] ?? 15;
      String newText = newValue.text;

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
            int newMaxLength = phoneNumberLengths[matchedDialCode] ?? 15;
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
              color: context.appColors.fieldBg,
              borderRadius: context.appRadius.input,
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
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.appColors.borderSubtle, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.appColors.borderSubtle, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.appColors.buttonPrimaryBg.withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.appColors.error,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.appColors.error,
                width: 1.5,
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
                phoneNumberLengths[selectedCountry?.dialCode] ?? 15;
            String phoneNumber = value;

            if (value.length > maxLength) {
              phoneNumber = value.substring(0, maxLength);
              widget.controller.text = phoneNumber;
              widget.controller.selection =
                  TextSelection.fromPosition(TextPosition(offset: maxLength));
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
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
            });
          },
          validator: widget.validator,
        ),
      ],
    );
  }
}
