import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomTextFieldDate extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool withTime;
  final String? Function(String?)? validator;

  CustomTextFieldDate({
    required this.controller,
    required this.label,
    this.withTime = false,
    this.validator,
  });

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: AbsorbPointer(
            child: TextFormField(
              controller: controller,
              validator: validator, // Use the validator here
              decoration: InputDecoration(
                hintText: withTime ? '__/__/____ __:__' : '__/__/____',
                hintStyle: TextStyle(fontSize: 12),
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
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Color(0xffF4F7FD),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
