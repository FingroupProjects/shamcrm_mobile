import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

class CustomTextFieldWithPriority extends StatefulWidget {
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
  final bool showPriority;
  final bool isPrioritySelected;
  final Function(bool?)? onPriorityChanged;
  final String priorityText;

  const CustomTextFieldWithPriority({
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
    this.hasError = false,
    this.showPriority = false,
    this.isPrioritySelected = false,
    this.onPriorityChanged,
    this.priorityText = '',
  });

  @override
  State<CustomTextFieldWithPriority> createState() =>
      _CustomTextFieldWithPriorityState();
}

class _CustomTextFieldWithPriorityState
    extends State<CustomTextFieldWithPriority>
    with SingleTickerProviderStateMixin {
  bool _isPasswordVisible = false;
  late final AnimationController _animationController;
  late final Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fillAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.value = widget.isPrioritySelected ? 1 : 0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CustomTextFieldWithPriority oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPrioritySelected != oldWidget.isPrioritySelected) {
      widget.isPrioritySelected
          ? _animationController.forward()
          : _animationController.reverse();
    }
  }

  Widget _buildAnimatedFireIcon() {
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        children: [
          Image.asset('assets/icons/icon-fire-no-color.png', width: 20, height: 20),
          AnimatedBuilder(
            animation: _fillAnimation,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: [_fillAnimation.value, _fillAnimation.value],
                  colors: const [Colors.white, Colors.transparent],
                ).createShader(bounds),
                blendMode: BlendMode.dstIn,
                child: Image.asset('assets/icons/icon-fire-color.png', width: 20, height: 20),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasError = (widget.errorText != null && widget.errorText!.isNotEmpty) || widget.hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textPrimary,
              ),
            ),
            if (widget.showPriority)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: widget.isPrioritySelected,
                    onChanged: widget.onPriorityChanged,
                    activeColor: colors.buttonPrimaryBg,
                  ),
                  Text(
                    widget.priorityText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildAnimatedFireIcon(),
                ],
              ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
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
            hintStyle: TextStyle(fontFamily: 'Gilroy', color: colors.fieldHint),
            filled: true,
            fillColor: colors.fieldBg,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: colors.iconSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _isPasswordVisible = !_isPasswordVisible),
                  )
                : widget.suffixIcon,
            errorText: widget.errorText,
            errorStyle: TextStyle(
              fontSize: 14,
              color: colors.error,
              fontWeight: FontWeight.w400,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? colors.error : colors.borderSubtle,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? colors.error : colors.borderSubtle,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? colors.error
                    : colors.buttonPrimaryBg.withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
