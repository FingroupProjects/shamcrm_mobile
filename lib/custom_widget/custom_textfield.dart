import 'dart:io' show Platform;
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
  final bool showEditButton;
  final VoidCallback? onEditPressed;
  final TextAlign textAlign; // ← Добавим для гибкости

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
    this.showEditButton = false,
    this.onEditPressed,
    this.textAlign = TextAlign.start, // ← Добавили
  });

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isPasswordVisible = false;
  final FocusNode _focusNode = FocusNode(); // ← Добавили
  OverlayEntry? _overlayEntry; // ← Для тулбара iOS

  @override
  void initState() {
    super.initState();
    
    // ← Добавили: отслеживаем фокус для показа тулбара на iOS
    if (Platform.isIOS) {
      _focusNode.addListener(_handleFocusChange);
    }
  }

  // ← Новый метод: обработка изменения фокуса
  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _showKeyboardToolbar();
    } else {
      _removeKeyboardToolbar();
    }
  }

  // ← Новый метод: показать тулбар над клавиатурой
  void _showKeyboardToolbar() {
    // Небольшая задержка, чтобы клавиатура успела появиться
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted || _overlayEntry != null) return;

      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 0,
          right: 0,
          child: _buildKeyboardToolbar(),
        ),
      );

      Overlay.of(context).insert(_overlayEntry!);
    });
  }

  // ← Новый метод: удалить тулбар
  void _removeKeyboardToolbar() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // ← Новый метод: виджет тулбара
  Widget _buildKeyboardToolbar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFD1D5DB).withOpacity(0.95),
        border: const Border(
          top: BorderSide(
            color: Color(0xFF9CA3AF),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
              _focusNode.unfocus(); // Закрываем клавиатуру
            },
            child: const Text(
              'Готово',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xff4759FF),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _removeKeyboardToolbar(); // ← Очищаем overlay
    if (Platform.isIOS) {
      _focusNode.removeListener(_handleFocusChange);
    }
    _focusNode.dispose();
    super.dispose();
  }

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
          focusNode: _focusNode, // ← Добавили наш FocusNode
          obscureText: widget.isPassword && !_isPasswordVisible,
          enabled: widget.showEditButton ? true : widget.enabled,
          readOnly: widget.showEditButton ? true : widget.readOnly,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.maxLines,
          validator: widget.validator,
          onChanged: widget.onChanged,
          textAlign: widget.textAlign, // ← Используем новый параметр
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