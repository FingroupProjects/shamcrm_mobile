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
  final Country? initialCountry;

  const CustomPhoneNumberInput({
    super.key,
    required this.controller,
    required this.label,
    this.onInputChanged,
    this.validator,
    this.initialCountry,
  });

  @override
  State<CustomPhoneNumberInput> createState() => _CustomPhoneNumberInputState();
}

class _CustomPhoneNumberInputState extends State<CustomPhoneNumberInput> {
  Country? selectedCountry;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeCountry();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant CustomPhoneNumberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCountry != oldWidget.initialCountry &&
        widget.initialCountry != null) {
      setState(() {
        selectedCountry = widget.initialCountry;
      });
    }
  }

  Future<void> _initializeCountry() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedDialCode = prefs.getString('default_dial_code');

    debugPrint(
        'CustomPhoneNumberInput: Сохранённый default_dial_code = $savedDialCode');
    debugPrint(
        'CustomPhoneNumberInput: initialCountry = ${widget.initialCountry?.dialCode}');

    if (widget.initialCountry != null) {
      selectedCountry = widget.initialCountry;
    } else if (savedDialCode != null && savedDialCode.isNotEmpty) {
      selectedCountry = countries.firstWhere(
        (country) => country.dialCode == savedDialCode,
        orElse: () => countries.firstWhere(
          (country) => country.name == "TJ",
          orElse: () => countries.first,
        ),
      );
    } else {
      selectedCountry = countries.firstWhere(
        (country) => country.name == "TJ",
        orElse: () => countries.first,
      );
    }

    debugPrint(
        'CustomPhoneNumberInput: Выбрана страна: ${selectedCountry?.name}, код: ${selectedCountry?.dialCode}');

    setState(() {
      _isLoading = false;
    });
  }

  void _onTextChanged() {
    final maxLength = phoneNumberLengths[selectedCountry?.dialCode] ?? 0;
    final value = widget.controller.text;

    if (value.length > maxLength) {
      widget.controller.text = value.substring(0, maxLength);
      widget.controller.selection =
          TextSelection.fromPosition(TextPosition(offset: maxLength));
    }

    // ✅ ИСПРАВЛЕНО: отправляем код региона ТОЛЬКО если есть цифры
    if (widget.onInputChanged != null) {
      String formattedNumber;
      if (widget.controller.text.isEmpty) {
        formattedNumber = ''; // Пустая строка, если нет номера
      } else {
        formattedNumber =
            (selectedCountry?.dialCode ?? '') + widget.controller.text;
      }

      debugPrint(
          'CustomPhoneNumberInput: phoneNumber = "${widget.controller.text}", formattedNumber = "$formattedNumber"');
      widget.onInputChanged!(formattedNumber);
    }
  }

  TextInputFormatter _phoneNumberPasteFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      bool isPaste = (newValue.text.length - oldValue.text.length).abs() > 1;
      int maxLength = phoneNumberLengths[selectedCountry?.dialCode] ?? 0;

      if (isPaste) {
        String newText = newValue.text;
        String? matchedDialCode;
        Country? matchedCountry;
        bool hasPlus = newText.startsWith('+');
        bool hasInternationalPrefix = hasPlus || newText.startsWith('00');
        String checkText = hasPlus
            ? newText
            : (newText.startsWith('00') ? '+${newText.substring(2)}' : newText);

        // Без явного международного префикса не пытаемся угадывать чужую страну
        // по первым цифрам. В этом режиме номер считается локальным для выбранной
        // страны, чтобы 927724041 не превращался в +92....
        if (hasInternationalPrefix) {
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
        }

        if (matchedDialCode != null &&
            matchedCountry != null &&
            matchedCountry.name.isNotEmpty) {
          String phoneNumber = checkText.substring(matchedDialCode.length);

          if (RegExp(r'^\d*$').hasMatch(phoneNumber)) {
            int newMaxLength = phoneNumberLengths[matchedDialCode] ?? 0;
            if (phoneNumber.length > newMaxLength) {
              phoneNumber = phoneNumber.substring(0, newMaxLength);
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                selectedCountry = matchedCountry;
                widget.controller.text = phoneNumber;
              });

              // ✅ ИСПРАВЛЕНО: отправляем код региона ТОЛЬКО если есть цифры
              if (widget.onInputChanged != null) {
                String formattedNumber;
                if (phoneNumber.isEmpty) {
                  formattedNumber = '';
                } else {
                  formattedNumber =
                      (matchedCountry?.dialCode ?? '') + phoneNumber;
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

          // ✅ ИСПРАВЛЕНО: _onTextChanged вызовется автоматически через listener
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

        // ✅ ИСПРАВЛЕНО: _onTextChanged вызовется автоматически через listener
        return TextEditingValue(
          text: phoneNumber,
          selection: TextSelection.collapsed(offset: phoneNumber.length),
        );
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _showCountryPicker(BuildContext context) async {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: context.appColors.surfacePrimary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: StatefulBuilder(
            builder: (context, setStateModal) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!
                            .translate('search_appbar'),
                        hintStyle: context.appTextStyles.bodyLg.copyWith(
                          color: context.appColors.fieldHint,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: context.appColors.iconSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: context.appRadius.input,
                        ),
                      ),
                      onChanged: (value) {
                        setStateModal(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                    Expanded(
                      child: ListView(
                        children: countries
                            .where((country) =>
                                country.name
                                    .toLowerCase()
                                    .contains(_searchQuery) ||
                                country.fullname!
                                    .toLowerCase()
                                    .contains(_searchQuery) ||
                                country.dialCode.contains(_searchQuery))
                            .map((country) => ListTile(
                                  leading: Text(country.flag,
                                      style: TextStyle(fontSize: 24)),
                                  title: Text(
                                    country.dialCode,
                                    style:
                                        context.appTextStyles.bodyLg.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      selectedCountry = country;
                                      widget.controller.text = '';

                                      // ✅ ИСПРАВЛЕНО: отправляем пустую строку при смене региона
                                      if (widget.onInputChanged != null) {
                                        widget.onInputChanged!('');
                                      }
                                    });
                                    Navigator.pop(context);
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fieldFill = colors.fieldBg;
    final primaryText = context.adaptiveForegroundOn(fieldFill);
    final hintTextColor = context.adaptiveHintOn(fieldFill);
    final fieldBorder = context.adaptiveBorderOn(fieldFill);

    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: context.appTextStyles.labelLg.copyWith(
              fontWeight: FontWeight.w500,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: fieldFill,
              borderRadius: context.appRadius.input,
              border: Border.all(
                color: fieldBorder,
              ),
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
            color: primaryText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          decoration: InputDecoration(
            hintText:
                AppLocalizations.of(context)!.translate('enter_phone_number'),
            hintStyle: context.appTextStyles.bodyMd.copyWith(
              color: hintTextColor,
            ),
            border: OutlineInputBorder(
              borderRadius: context.appRadius.input,
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: fieldFill,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            prefixIcon: InkWell(
              onTap: () => _showCountryPicker(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      selectedCountry?.dialCode ?? '+?',
                      style: context.appTextStyles.bodyLg.copyWith(
                        fontWeight: FontWeight.w500,
                        color: primaryText,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      selectedCountry?.flag ?? '',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down,
                      color: primaryText.withValues(alpha: 0.9)),
                ],
              ),
            ),
            errorStyle: context.appTextStyles.bodyMd.copyWith(
              color: context.appColors.error,
              fontWeight: FontWeight.w400,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: context.appRadius.input,
              borderSide: BorderSide(color: fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: context.appRadius.input,
              borderSide: BorderSide(
                color: context.adaptiveFocusBorderOn(fieldFill),
                width: 1.2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: context.appRadius.input,
              borderSide: BorderSide(
                color: context.appColors.error,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: context.appRadius.input,
              borderSide: BorderSide(
                color: context.appColors.error,
                width: 1.5,
              ),
            ),
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _phoneNumberPasteFormatter(),
          ],
          validator: widget.validator,
          style: context.appTextStyles.bodyLg.copyWith(
            color: primaryText,
          ),
        ),
      ],
    );
  }
}
