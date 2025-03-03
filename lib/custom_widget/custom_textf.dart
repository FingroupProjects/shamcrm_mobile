import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextFieldNoLabel extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isPassword;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final String? errorText;
  final bool hasError;

  CustomTextFieldNoLabel({
    required this.controller,
    required this.hintText,
    this.isPassword = false,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    this.errorText,
    this.hasError = false,
  });

  @override
  _CustomTextFieldNoLabelState createState() => _CustomTextFieldNoLabelState();
}

class _CustomTextFieldNoLabelState extends State<CustomTextFieldNoLabel> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    // Determine if the field has an error
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty ||
        widget.hasError;

    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword && !_isPasswordVisible,
      readOnly: widget.readOnly,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      maxLines: widget.maxLines,
      validator: widget.validator,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
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
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Image.asset(
                  _isPasswordVisible
                      ? 'assets/icons/Profile/eye.png'
                      : 'assets/icons/Profile/eye_close.png',
                  width: 24,
                  height: 24,
                  color: const Color(0xff99A4BA),
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : widget.suffixIcon,
        errorText: widget.errorText,
        // Уменьшенный размер шрифта для ошибки и выравнивание по левому краю
        errorStyle: const TextStyle(
          fontSize: 12, // Уменьшенный размер шрифта
          color: Colors.red,
          fontWeight: FontWeight.w400,
        ),
        // Смещение текста ошибки влево
        errorMaxLines: 2,
        alignLabelWithHint: false,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError ? Colors.red : Colors.transparent,
          ),
        ),
        // Не менять цвет при фокусе, сохранять прозрачную или красную границу
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError ? Colors.red : Colors.transparent, // Не меняем цвет границы при фокусе
            width: hasError ? 1.5 : 0,
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
            color: Colors.red,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}