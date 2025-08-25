import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String label;
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
  final Color backgroundColor; 
  final bool? enabled;
  final bool showEditButton; // Новое свойство для показа кнопки редактирования
  final VoidCallback? onEditPressed; // Колбэк для кнопки редактирования

  CustomTextField({
    required this.controller,
    required this.hintText,
    required this.label,
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
    this.enabled,
    this.hasError = false,
    this.backgroundColor = const Color(0xffF4F7FD),
    this.showEditButton = false, // По умолчанию скрыта
    this.onEditPressed,
  });

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty ||
        widget.hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: const Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && !_isPasswordVisible,
          enabled: widget.showEditButton ? true : widget.enabled, // Всегда включено если есть кнопка редактирования
          readOnly: widget.showEditButton ? true : widget.readOnly, // Только для чтения если есть кнопка редактирования
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
            fillColor: widget.backgroundColor, 
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            prefixIcon: widget.prefixIcon,
            suffixIcon: _buildSuffixIcon(),
            errorText: widget.errorText,
            errorStyle: const TextStyle(
              fontSize: 14,
              color: Colors.red,
              fontWeight: FontWeight.w400,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.red : Colors.transparent,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.red : Colors.grey.shade300,
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
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    // Приоритет: кнопка редактирования > кнопка пароля > обычная suffixIcon
    if (widget.showEditButton && widget.onEditPressed != null) {
      return IconButton(
        icon: Icon(
          Icons.edit,
          color: Color(0xff4F40EC),
          size: 20,
        ),
        onPressed: widget.onEditPressed,
        tooltip: 'Редактировать',
      );
    } else if (widget.isPassword) {
      return IconButton(
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
      );
    } else {
      return widget.suffixIcon;
    }
  }
}