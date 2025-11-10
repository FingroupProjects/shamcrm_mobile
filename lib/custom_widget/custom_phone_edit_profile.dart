import 'package:crm_task_manager/custom_widget/country_data_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  @override
  void initState() {
    super.initState();
    // print('Инициализация: Установка начальной страны');
    if (widget.selectedDialCode != null) {
      selectedCountry = countries.firstWhere(
        (country) => country.dialCode == widget.selectedDialCode,
        orElse: () {
          // print('Страна с кодом ${widget.selectedDialCode} не найдена, выбираем первую');
          return countries.first;
        },
      );
    } else {
      selectedCountry = countries.firstWhere(
        (country) => country.name == "TJ",
        orElse: () => countries.first,
      );
      // print('Код страны не указан, выбрана TJ');
    }
    // print('Начальная страна: ${selectedCountry?.name}, код: ${selectedCountry?.dialCode}');

    // Очищаем код страны из начального текста, если он присутствует
    if (widget.controller.text.startsWith(selectedCountry?.dialCode ?? '')) {
      widget.controller.text =
          widget.controller.text.substring(selectedCountry!.dialCode.length);
      // print('Очищен код страны из текста: ${widget.controller.text}');
    }

    // Валидируем начальный текст
    if (widget.controller.text.isNotEmpty) {
      _validatePhoneNumber(widget.controller.text);
    }
  }

  void _validatePhoneNumber(String value) {
    final maxLength = widget.phoneNumberLengths[selectedCountry?.dialCode] ?? 0;
    // print('Валидация: Текст: $value, Максимальная длина: $maxLength');

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
      // print('Валидация: Ошибка: $_errorText, Достигнута макс. длина: $_hasReachedMaxLength');
    });
  }

  // Форматтер для обработки вставки номера
  TextInputFormatter _phoneNumberPasteFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      // print('Formatter: Входной текст: ${newValue.text}, старый текст: ${oldValue.text}');

      // Проверяем, является ли ввод вставкой (длина текста резко увеличилась)
      bool isPaste = (newValue.text.length - oldValue.text.length).abs() > 1;
      bool isDeletion = newValue.text.length < oldValue.text.length;
      // print('Formatter: Это вставка? $isPaste, Это удаление? $isDeletion '
          // '(длина нового: ${newValue.text.length}, старого: ${oldValue.text.length})');

      // Получаем максимальную длину для текущей страны
      int maxLength = widget.phoneNumberLengths[selectedCountry?.dialCode] ?? 0;
      // print('Formatter: Максимальная длина для текущей страны ${selectedCountry?.dialCode}: $maxLength');

      if (isPaste) {
        String newText = newValue.text;
        // print('Formatter: Обработка вставки, текст: $newText');

        // Проверяем, начинается ли текст с кода страны (с "+" или без)
        String? matchedDialCode;
        Country? matchedCountry;
        bool hasPlus = newText.startsWith('+');
        String checkText = hasPlus ? newText : '+' + newText; // Добавляем "+" для проверки

        // print('Formatter: Проверка текста: $checkText');
        for (var code in countryCodes) {
          if (checkText.startsWith(code) && (matchedDialCode == null || code.length > matchedDialCode.length)) {
            matchedDialCode = code;
            matchedCountry = countries.firstWhere(
              (country) => country.dialCode == code,
              orElse: () {
                // print('Formatter: Код $code не найден в списке стран');
                return Country(name: '', flag: '', dialCode: '');
              },
            );
            // print('Formatter: Найден код: $code, страна: ${matchedCountry.name}');
          }
        }

        // Если код страны найден и он валидный
        if (matchedDialCode != null && matchedCountry != null && matchedCountry.name.isNotEmpty) {
          // print('Formatter: Обработка кода страны $matchedDialCode');
          // Вырезаем код страны из текста
          String phoneNumber = hasPlus
              ? newText.substring(matchedDialCode.length)
              : newText.substring(matchedDialCode.length - 1); // Учитываем отсутствие "+"
          // print('Formatter: Извлеченный номер: $phoneNumber');
          // Проверяем, что номер состоит только из цифр
          if (RegExp(r'^\d*$').hasMatch(phoneNumber)) {
            // print('Formatter: Номер валидный (только цифры)');
            // Ограничиваем длину номера
            int newMaxLength = widget.phoneNumberLengths[matchedDialCode] ?? 0;
            // print('Formatter: Максимальная длина номера для $matchedDialCode: $newMaxLength');
            if (phoneNumber.length > newMaxLength) {
              // print('Formatter: Номер слишком длинный, обрезаем до $newMaxLength');
              phoneNumber = phoneNumber.substring(0, newMaxLength);
            }

            // Обновляем состояние и контроллер
            // print('Formatter: Обновляем selectedCountry и controller');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                selectedCountry = matchedCountry;
                widget.controller.text = phoneNumber;
                // print('Formatter: Установлена страна: ${selectedCountry?.name}, код: ${selectedCountry?.dialCode}');
                // print('Formatter: Установлен текст в контроллере: ${widget.controller.text}');
                _validatePhoneNumber(phoneNumber);
              });
              final formattedNumber = (matchedCountry?.dialCode ?? '') + phoneNumber;
              // print('Formatter: Форматированный номер для onInputChanged: $formattedNumber');
              if (widget.onInputChanged != null) {
                widget.onInputChanged!(formattedNumber);
                // print('Formatter: Вызван onInputChanged с номером: $formattedNumber');
              }
            });

            // Возвращаем только номер телефона для текстового поля
            // print('Formatter: Возвращаем текст для поля: $phoneNumber');
            return TextEditingValue(
              text: phoneNumber,
              selection: TextSelection.collapsed(offset: phoneNumber.length),
            );
          } else {
            // print('Formatter: Номер содержит недопустимые символы: $phoneNumber');
            return oldValue; // Отклоняем вставку, если номер содержит не цифры
          }
        } else {
          // print('Formatter: Код страны не найден или невалидный');
          // Обрабатываем как обычный номер, обрезая по максимальной длине текущей страны
          String phoneNumber = newText;
          if (phoneNumber.length > maxLength) {
            // print('Formatter: Номер слишком длинный для текущей страны, обрезаем до $maxLength');
            phoneNumber = phoneNumber.substring(0, maxLength);
          }
          // print('Formatter: Возвращаем обрезанный текст: $phoneNumber');
          _validatePhoneNumber(phoneNumber);
          return TextEditingValue(
            text: phoneNumber,
            selection: TextSelection.collapsed(offset: phoneNumber.length),
          );
        }
      } else {
        // print('Formatter: Ручной ввод или удаление, пропускаем проверку кодов стран');
        // Проверяем длину для текущей страны
        String phoneNumber = newValue.text;
        if (phoneNumber.length > maxLength) {
          // print('Formatter: Номер слишком длинный, обрезаем до $maxLength');
          phoneNumber = phoneNumber.substring(0, maxLength);
        }
        // print('Formatter: Возвращаем текст для ручного ввода/удаления: $phoneNumber');
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
    // print('Build: Отрисовка CustomPhoneNumberInput, текущая страна: ${selectedCountry?.name}');
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
                    ? null // Отключаем выбор страны, если readOnly
                    : (Country? newValue) {
                        // print('Dropdown: Выбрана новая страна: ${newValue?.name}, код: ${newValue?.dialCode}');
                        setState(() {
                          selectedCountry = newValue;
                          widget.controller.text = '';
                          _errorText = null;
                          _hasReachedMaxLength = false;
                          // print('Dropdown: Очищен текст в контроллере');
                          if (newValue != null && widget.onInputChanged != null) {
                            widget.onInputChanged!('');
                            // print('Dropdown: Вызван onInputChanged с пустым номером');
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
              ? null // Отключаем onChanged, если readOnly
              : (value) {
                  // print('onChanged: Введено: $value');
                  final maxLength = widget.phoneNumberLengths[selectedCountry?.dialCode] ?? 0;
                  String phoneNumber = value;

                  if (value.length > maxLength) {
                    phoneNumber = value.substring(0, maxLength);
                    widget.controller.text = phoneNumber;
                    widget.controller.selection =
                        TextSelection.fromPosition(TextPosition(offset: maxLength));
                    // print('onChanged: Обрезан текст до $maxLength: $phoneNumber');
                  }

                  _validatePhoneNumber(phoneNumber);
                  final formattedNumber = (selectedCountry?.dialCode ?? '') + phoneNumber;
                  // print('onChanged: Форматированный номер: $formattedNumber');

                  if (widget.onInputChanged != null) {
                    widget.onInputChanged!(formattedNumber);
                    // print('onChanged: Вызван onInputChanged с номером: $formattedNumber');
                  }
                },
        ),
      ],
    );
  }
}