import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomTextFieldDate extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool withTime;
  final String? Function(String?)? validator;
  final bool useCurrentDateAsDefault;
  final bool readOnly;
  final TextInputType keyboardType;

  CustomTextFieldDate({
    required this.controller,
    required this.label,
    this.withTime = false,
    this.validator,
    this.useCurrentDateAsDefault = false,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
  }) {
    if (useCurrentDateAsDefault) {
      controller.text = withTime
          ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())
          : DateFormat('dd/MM/yyyy').format(DateTime.now());
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    String formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      fieldHintText: "дд/ММ/гггг",
      cancelText: "Назад",
      confirmText: "Ок",
      helpText: "Выберите дату",
      errorFormatText: "Ошибка! Пример: $formattedDate",
      errorInvalidText: "Неправильный формат даты! дд/ММ/гггг",
      fieldLabelText: "Введите дату",
      firstDate: DateTime(1940),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            hintColor: Colors.blue,
            colorScheme: ColorScheme.light(primary: Color(0xff1E2E52)),
            dialogBackgroundColor: Colors.white,
          ),
          child: child ?? Container(),
        );
      },
    );

    if (pickedDate != null) {
      if (withTime) {
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
          cancelText: "Назад",
          confirmText: "Ок",
          helpText: "Выберите время",
          minuteLabelText: "Минута",
          hourLabelText: "Час",
          builder: (BuildContext context, Widget? child) {
            return MediaQuery(
              data:
                  MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
              child: Theme(
                data: ThemeData.light().copyWith(
                  primaryColor: Colors.blue,
                  hintColor: Colors.blue,
                  colorScheme: ColorScheme.light(primary: Color(0xff1E2E52)),
                  dialogBackgroundColor: Colors.white,
                ),
                child: child ?? Container(),
              ),
            );
          },
          initialEntryMode: TimePickerEntryMode.dial,
        );

        if (pickedTime != null) {
          final DateTime dateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          controller.text = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
        }
      } else {
        controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: readOnly ? null : () => _selectDate(context),
          child: AbsorbPointer(
            child: TextFormField(
              controller: controller,
              validator: validator,
              readOnly: readOnly,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: withTime ? '__/__/____ __:__' : '__/__/____',
                hintStyle: const TextStyle(fontSize: 12),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: Image.asset(
                      'assets/icons/tabBar/date.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.transparent),
                ),
              errorStyle: const TextStyle(
              fontSize: 14, 
              fontFamily: 'Gilroy',
              color: Colors.red,
              fontWeight: FontWeight.w500, 
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
                filled: true,
                fillColor: const Color(0xffF4F7FD),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
