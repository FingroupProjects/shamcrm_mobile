import 'dart:io' show Platform;
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
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
  final int? maxLines;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final String? errorText;
  final bool hasError;
  final Color? backgroundColor;
  final Color? labelColor;
  final Color? hintColor;
  final Color? textColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final bool? enabled;
  final bool showEditButton;
  final VoidCallback? onEditPressed;
  final TextAlign textAlign;

  const CustomTextField({
    super.key,
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
    this.labelColor,
    this.hintColor,
    this.textColor,
    this.borderColor,
    this.focusedBorderColor,
    this.showEditButton = false,
    this.onEditPressed,
    this.textAlign = TextAlign.start,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isPasswordVisible = false;
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      _focusNode.addListener(_handleFocusChange);
    }
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _showKeyboardToolbar();
    } else {
      _removeKeyboardToolbar();
    }
  }

  void _showKeyboardToolbar() {
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

  void _removeKeyboardToolbar() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildKeyboardToolbar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: context.appColors.surfacePrimary.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: context.appColors.borderSubtle,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => _focusNode.unfocus(),
            child: Text(
              'Готово',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: context.appColors.buttonPrimaryBg,
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
    _removeKeyboardToolbar();
    if (Platform.isIOS) {
      _focusNode.removeListener(_handleFocusChange);
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
            color: widget.labelColor ?? colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.isPassword && !_isPasswordVisible,
          enabled: widget.showEditButton ? true : widget.enabled,
          readOnly: widget.showEditButton ? true : widget.readOnly,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.maxLines,
          validator: widget.validator,
          onChanged: widget.onChanged,
          textAlign: widget.textAlign,
          style: TextStyle(
            fontFamily: 'Gilroy',
            color: widget.textColor ?? colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              fontFamily: 'Gilroy',
              color: widget.hintColor ?? colors.fieldHint,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? colors.error : colors.borderSubtle,
                width: 1,
              ),
            ),
            filled: true,
            fillColor: widget.backgroundColor ?? colors.fieldBg,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            prefixIcon: widget.prefixIcon,
            suffixIcon: _buildSuffixIcon(),
            errorText: widget.errorText,
            errorMaxLines: 2,
            errorStyle: TextStyle(
              fontSize: 14,
              color: colors.error,
              fontWeight: FontWeight.w400,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? colors.error
                    : (widget.borderColor ?? colors.borderSubtle),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? colors.error
                    : (widget.focusedBorderColor ??
                        widget.borderColor ??
                        colors.buttonPrimaryBg.withValues(alpha: 0.6)),
                width: 1.2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? colors.error
                    : (widget.borderColor ?? colors.borderSubtle),
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colors.error,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colors.error,
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
          color: context.appColors.buttonPrimaryBg,
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
          color: context.appColors.textSecondary,
        ),
        onPressed: () =>
            setState(() => _isPasswordVisible = !_isPasswordVisible),
      );
    } else {
      return widget.suffixIcon;
    }
  }
}
