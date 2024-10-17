import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Не забудьте импортировать для использования inputFormatters

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String label;
  final bool isPassword;
  final Widget? prefixIcon; // Иконка в начале
  final Widget? suffixIcon; // Иконка в конце
  final TextInputType keyboardType; // Новый параметр для типа клавиатуры
  final List<TextInputFormatter>? inputFormatters; // Новый параметр для форматирования ввода

  CustomTextField({
    required this.controller,
    required this.hintText,
    required this.label,
    this.isPassword = false,
    this.prefixIcon, // Иконка в начале
    this.suffixIcon, // Иконка в конце
    this.keyboardType = TextInputType.text, // Значение по умолчанию
    this.inputFormatters, // Можно передать null
  });

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xfff1E2E52),
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          obscureText: widget.isPassword && !_isPasswordVisible,
          keyboardType: widget.keyboardType, // Используем заданный тип клавиатуры
          inputFormatters: widget.inputFormatters, // Используем заданные форматы ввода
          decoration: InputDecoration(
            hintText: widget.hintText,
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
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            prefixIcon: widget.prefixIcon, // Иконка в начале
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Color(0xff99A4BA),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )
                : widget.suffixIcon, // Иконка в конце
          ),
        ),
      ],
    );
  }
}
