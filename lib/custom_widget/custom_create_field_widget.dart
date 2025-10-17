import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:intl/intl.dart';

class CustomFieldWidget extends StatelessWidget {
  final String fieldName;
  final TextEditingController valueController;
  final VoidCallback onRemove;
  final bool isDirectory;
  final String? type;

  const CustomFieldWidget({
    Key? key,
    required this.fieldName,
    required this.valueController,
    required this.onRemove,
    this.isDirectory = false,
    this.type,
  }) : super(key: key);

  Future<void> _selectDate(BuildContext context, {bool withTime = false}) async {
    // Пытаемся получить дату из контроллера, если она уже выбрана
    DateTime initialDate = DateTime.now();
    TimeOfDay initialTime = TimeOfDay.now();
    
    if (valueController.text.isNotEmpty) {
      try {
        if (withTime) {
          // Парсим дату и время в формате dd/MM/yyyy HH:mm
          final parsedDateTime = DateFormat('dd/MM/yyyy HH:mm').parse(valueController.text);
          initialDate = parsedDateTime;
          initialTime = TimeOfDay(hour: parsedDateTime.hour, minute: parsedDateTime.minute);
        } else {
          // Парсим только дату в формате dd/MM/yyyy
          initialDate = DateFormat('dd/MM/yyyy').parse(valueController.text);
        }
      } catch (e) {
        // Если не удалось распарсить, используем текущую дату
        debugPrint('Ошибка парсинга даты: $e');
      }
    }
    
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xff1E2E52),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xff1E2E52),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (withTime) {
        TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: initialTime,
          builder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                colorScheme: ColorScheme.light(
                  primary: Color(0xff1E2E52),
                  onPrimary: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (pickedTime != null) {
          final formattedDateTime = DateFormat('dd/MM/yyyy HH:mm').format(
            DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            ),
          );
          valueController.text = formattedDateTime;
        }
      } else {
        final formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
        valueController.text = formattedDate;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    TextInputType keyboardType;
    List<TextInputFormatter>? inputFormatters;
    bool readOnly = false;
    String hintText;

    // Определяем подсказку и настройки в зависимости от type
    switch (type) {
      case 'number':
        keyboardType = TextInputType.number;
        inputFormatters = [FilteringTextInputFormatter.digitsOnly];
        hintText = AppLocalizations.of(context)!.translate('enter_number');
        break;
      case 'date':
        keyboardType = TextInputType.none;
        readOnly = true;
        hintText = AppLocalizations.of(context)!.translate('enter_date');
        break;
      case 'datetime':
        keyboardType = TextInputType.none;
        readOnly = true;
        hintText = AppLocalizations.of(context)!.translate('enter_datetime');
        break;
      default: // string
        keyboardType = TextInputType.text;
        inputFormatters = null;
        hintText = AppLocalizations.of(context)!.translate('enter_textfield_text');
        break;
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fieldName,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              const SizedBox(height: 8),
              if (!isDirectory)
                TextField(
                  controller: valueController,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  readOnly: readOnly,
                  onTap: readOnly
                      ? () => _selectDate(context, withTime: type == 'datetime')
                      : null,
                  decoration: InputDecoration(
                    hintText: hintText, // Используем динамическую подсказку
                    hintStyle: const TextStyle(
                      fontFamily: 'Gilroy',
                      color: Color(0xff99A4BA),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xffF4F7FD),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xffF4F7FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    fieldName,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.remove_circle,
            color: Color.fromARGB(255, 236, 64, 16),
          ),
          onPressed: onRemove,
        ),
      ],
    );
  }
}