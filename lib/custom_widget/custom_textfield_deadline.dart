import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
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
  final bool hasError;
  final Function(String)? onDateSelected;
  final Function(String)? onChanged;

  CustomTextFieldDate({
    required this.controller,
    required this.label,
    this.withTime = false,
    this.validator,
    this.useCurrentDateAsDefault = false,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.hasError = false,
    this.onDateSelected,
    this.onChanged,
  }) {
    if (useCurrentDateAsDefault) {
      controller.text = withTime
          ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())
          : DateFormat('dd/MM/yyyy').format(DateTime.now());
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    TimeOfDay initialTime = TimeOfDay.now();
    
    if (controller.text.isNotEmpty) {
      try {
        if (withTime) {
          final parsedDateTime = DateFormat('dd/MM/yyyy HH:mm').parse(controller.text);
          initialDate = parsedDateTime;
          initialTime = TimeOfDay(hour: parsedDateTime.hour, minute: parsedDateTime.minute);
        } else {
          initialDate = DateFormat('dd/MM/yyyy').parse(controller.text);
        }
      } catch (e) {
        debugPrint('Ошибка парсинга даты: $e');
      }
    }
    
    String formattedDate = DateFormat('dd/MM/yyyy').format(initialDate);
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      fieldHintText: AppLocalizations.of(context)!.translate('ddmmyyyy'),
      cancelText: AppLocalizations.of(context)!.translate('back'),
      confirmText: AppLocalizations.of(context)!.translate('ok'),
      helpText: AppLocalizations.of(context)!.translate('select_date'),
      errorFormatText: "${AppLocalizations.of(context)!.translate('error_example')}$formattedDate",
      errorInvalidText: AppLocalizations.of(context)!.translate('invalid_format_date'),
      fieldLabelText: AppLocalizations.of(context)!.translate('enter_date'),
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
          initialTime: initialTime,
          cancelText: AppLocalizations.of(context)!.translate('back'),
          confirmText: AppLocalizations.of(context)!.translate('ok'),
          helpText: AppLocalizations.of(context)!.translate('select_time'),
          minuteLabelText: AppLocalizations.of(context)!.translate('minute'),
          hourLabelText: AppLocalizations.of(context)!.translate('hour'),
          builder: (BuildContext context, Widget? child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
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
          
          if (onDateSelected != null) {
            onDateSelected!(controller.text);
          }
          if (onChanged != null) {
            onChanged!(controller.text);
          }
        }
      } else {
        controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
        
        if (onDateSelected != null) {
          onDateSelected!(controller.text);
        }
        if (onChanged != null) {
          onChanged!(controller.text);
        }
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
                  borderSide: hasError
                      ? const BorderSide(color: Colors.red, width: 1.5)
                      : const BorderSide(color: Colors.transparent),
                ),
                errorStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.w400,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: hasError
                      ? const BorderSide(color: Colors.red, width: 1.5)
                      : const BorderSide(color: Colors.transparent),
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
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: hasError
                      ? const BorderSide(color: Colors.red, width: 1.5)
                      : const BorderSide(color: Color(0xff4759FF), width: 1.5),
                ),
                filled: true,
                fillColor: const Color(0xffF4F7FD),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}