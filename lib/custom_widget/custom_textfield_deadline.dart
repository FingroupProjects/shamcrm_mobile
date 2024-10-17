
import 'package:flutter/material.dart';

class CustomTextFieldDate extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  CustomTextFieldDate({
    required this.controller,
    required this.label,
  });

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue, // Set the primary color (e.g., for the header)
            hintColor: Colors.blue, // Set the accent color
            colorScheme: ColorScheme.light(primary: Color(0xfff1E2E52)), // Set the color scheme
            dialogBackgroundColor: Colors.white, // Change the background color of the dialog
          ),
          child: child ?? Container(),
        );
      },
    );
    if (picked != null) {
      controller.text = "${picked.day}/${picked.month}/${picked.year}";
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
            color: Color(0xfff1E2E52),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: AbsorbPointer(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: '__/__/____',
                hintStyle: TextStyle(fontSize: 12), // Set the desired hint text size
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
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
