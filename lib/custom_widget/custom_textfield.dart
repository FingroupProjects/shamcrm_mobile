import 'dart:io' show Platform;
import 'package:crm_task_manager/theme/theme_context_extensions.dart';
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
  final Color? backgroundColor;
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
    this.backgroundColor,
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
    final colors = context.appColors;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: colors.surfaceElevated.withValues(alpha: 0.98),
        border: Border(
          top: BorderSide(
            color: colors.borderPrimary,
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
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final inputTheme = Theme.of(context).inputDecorationTheme;
    final effectiveFillColor = widget.backgroundColor ??
        inputTheme.fillColor ??
        colors.inputBackground;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty ||
        widget.hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: textTheme.titleMedium?.copyWith(
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
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
          style: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle:
                textTheme.bodyMedium?.copyWith(color: colors.textTertiary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: effectiveFillColor,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            prefixIcon: widget.prefixIcon,
            suffixIcon: _buildSuffixIcon(),
            errorText: widget.errorText,
            errorMaxLines: 2,
            errorStyle: textTheme.bodySmall?.copyWith(
              color: colors.error,
              fontWeight: FontWeight.w500,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? colors.inputErrorBorder : colors.inputBorder,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    hasError ? colors.inputErrorBorder : colors.borderSecondary,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colors.inputErrorBorder,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colors.inputErrorBorder,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? colors.inputErrorBorder
                    : colors.inputFocusedBorder,
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
          color: context.appColors.iconBrand,
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
          color: context.appColors.iconSecondary,
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
