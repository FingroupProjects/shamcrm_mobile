import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crm_task_manager/custom_widget/country_data_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomPhoneNumberInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onInputChanged;
  final String? Function(String?)? validator;
  final String label;
  final Country? initialCountry;

  CustomPhoneNumberInput({
    required this.controller,
    required this.label,
    this.onInputChanged,
    this.validator,
    this.initialCountry,
  });

  @override
  _CustomPhoneNumberInputState createState() => _CustomPhoneNumberInputState();
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

  Future<void> _initializeCountry() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedDialCode = prefs.getString('default_dial_code');
    
    print('CustomPhoneNumberInput: Сохранённый default_dial_code = $savedDialCode');
    print('CustomPhoneNumberInput: initialCountry = ${widget.initialCountry?.dialCode}');

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

    print('CustomPhoneNumberInput: Выбрана страна: ${selectedCountry?.name}, код: ${selectedCountry?.dialCode}');

    setState(() {
      _isLoading = false;
    });
  }

  void _onTextChanged() {
    final maxLength = phoneNumberLengths[selectedCountry?.dialCode] ?? 0;
    final value = widget.controller.text;
    if (value.length > maxLength) {
      widget.controller.text = value.substring(0, maxLength);
      widget.controller.selection = TextSelection.fromPosition(TextPosition(offset: maxLength));
    }
    final formattedNumber = (selectedCountry?.dialCode ?? '') + widget.controller.text;
    if (widget.onInputChanged != null) {
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
            int newMaxLength = phoneNumberLengths[matchedDialCode] ?? 0;
            if (phoneNumber.length > newMaxLength) {
              phoneNumber = phoneNumber.substring(0, newMaxLength);
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                selectedCountry = matchedCountry;
                widget.controller.text = phoneNumber;
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
            color: Colors.white,
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
                        hintText: AppLocalizations.of(context)!.translate('search_appbar'),
                        hintStyle: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
                        country.name.toLowerCase().contains(_searchQuery) ||
                            country.fullname!.toLowerCase().contains(_searchQuery) ||
                            country.dialCode.contains(_searchQuery))
                            .map((country) => ListTile(
                          leading: Text(country.flag, style: TextStyle(fontSize: 24)),
                          title: Text(
                            country.dialCode,
                            style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 16,
                                fontWeight: FontWeight.w500),
                          ),
                          onTap: () {
                            setState(() {
                              selectedCountry = country;
                              widget.controller.text = '';
                              if (widget.onInputChanged != null) {
                                widget.onInputChanged!(country.dialCode);
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
              color: Color(0xff1E2E52),
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
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.translate('enter_phone_number'),
            hintStyle: const TextStyle(fontFamily: 'Gilroy', color: Color(0xff99A4BA)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color(0xffF4F7FD),
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            prefixIcon: InkWell(
              onTap: () => _showCountryPicker(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      selectedCountry?.dialCode ?? '+?',
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Text(
                      selectedCountry?.flag ?? '',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
            errorStyle: const TextStyle(
              fontSize: 14,
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
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _phoneNumberPasteFormatter(),
          ],
          validator: widget.validator,
        ),
      ],
    );
  }
}