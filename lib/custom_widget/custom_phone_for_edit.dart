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

  const CustomPhoneNumberInput({
    required this.controller,
    required this.label,
    this.onInputChanged,
    this.validator,
    this.selectedDialCode,
    super.key,
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
    if (widget.selectedDialCode != null && widget.selectedDialCode!.isNotEmpty) {
      selectedCountry = countries.firstWhere(
        (country) => widget.selectedDialCode!.startsWith(country.dialCode),
        orElse: () => countries.firstWhere((country) => country.name == "TJ"),
      );
      if (widget.controller.text.startsWith(selectedCountry!.dialCode)) {
        widget.controller.text =
            widget.controller.text.substring(selectedCountry!.dialCode.length);
      }
    } else {
      selectedCountry = countries.firstWhere((country) => country.name == "TJ");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.text.isNotEmpty) {
        _validatePhoneNumber(widget.controller.text);
        if (widget.onInputChanged != null) {
          widget.onInputChanged!(selectedCountry!.dialCode + widget.controller.text);
        }
      }
    });
  }

  void _validatePhoneNumber(String value) {
    final maxLength = phoneNumberLengths[selectedCountry?.dialCode] ?? 15;
    final minLength = 5;
    setState(() {
      if (value.isEmpty) {
        _errorText = AppLocalizations.of(context)!.translate('field_required');
        _hasReachedMaxLength = false;
      } else if (!RegExp(r'^\d+$').hasMatch(value)) {
        _errorText = AppLocalizations.of(context)!.translate('invalid_phone_number');
        _hasReachedMaxLength = false;
      } else if (value.length < minLength) {
        _errorText = AppLocalizations.of(context)!.translate('phone_number_too_short');
        _hasReachedMaxLength = false;
      } else if (value.length > maxLength) {
        _errorText = AppLocalizations.of(context)!.translate('phone_number_too_long');
        _hasReachedMaxLength = true;
      } else {
        _errorText = null;
        _hasReachedMaxLength = value.length == maxLength;
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
        String checkText = hasPlus ? newText : '+' + newText;

        for (var code in countryCodes) {
          if (checkText.startsWith(code) &&
              (matchedDialCode == null || code.length > matchedDialCode.length)) {
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
              if (widget.onInputChanged != null) {
                widget.onInputChanged!(matchedCountry!.dialCode + phoneNumber);
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
              widget.onInputChanged!(selectedCountry!.dialCode + phoneNumber);
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
          if (widget.onInputChanged != null) {
            widget.onInputChanged!(selectedCountry!.dialCode + phoneNumber);
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
            hintText:
                AppLocalizations.of(context)!.translate('enter_phone_number'),
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
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
                  });
                  if (newValue != null && widget.onInputChanged != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      widget.onInputChanged!(newValue.dialCode);
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
            final maxLength = phoneNumberLengths[selectedCountry?.dialCode] ?? 15;
            String phoneNumber = value;

            if (value.length > maxLength) {
              phoneNumber = value.substring(0, maxLength);
              widget.controller.text = phoneNumber;
              widget.controller.selection =
                  TextSelection.fromPosition(TextPosition(offset: maxLength));
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _validatePhoneNumber(phoneNumber);
              if (widget.onInputChanged != null) {
                widget.onInputChanged!(selectedCountry!.dialCode + phoneNumber);
              }
            });
          },
          validator: widget.validator,
        ),
      ],
    );
  }
}