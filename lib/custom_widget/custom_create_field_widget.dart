import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomFieldWidget extends StatelessWidget {
  final String fieldName;
  final TextEditingController valueController;
  final VoidCallback onRemove;

  const CustomFieldWidget({
    Key? key,
    required this.fieldName,
    required this.valueController,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fieldName,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  color: Color(0xfff1E2E52),
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: valueController,
                decoration: InputDecoration(
                  hintText: 'Введите значение поля',
                  hintStyle: TextStyle(
                    fontFamily: 'Gilroy',
                    color: Color(0xff99A4BA),
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
              SizedBox(height: 8),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.remove_circle,
            color: Color(0xff99A4BA),
          ),
          onPressed: onRemove,
        ),
      ],
    );
  }
}
