import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  CustomTextFieldWithPriority({
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
  _CustomTextFieldWithPriorityState createState() => _CustomTextFieldWithPriorityState();
}


class _CustomTextFieldWithPriorityState extends State<CustomTextFieldWithPriority> 
    with SingleTickerProviderStateMixin {
  bool _isPasswordVisible = false;
  late AnimationController _animationController;
  late Animation<double> _fillAnimation;

 @override
void initState() {
  super.initState();
  _animationController = AnimationController(
    duration: const Duration(milliseconds: 800),
    vsync: this,
  );
  _fillAnimation = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeInOut,
  ));

  // Если данные приходят уже включёнными, то сразу показываем цветную иконку
  if (widget.isPrioritySelected) {
    _animationController.value = 1.0;
  } else {
    _animationController.value = 0.0;
  }
}


  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
@override
void didUpdateWidget(CustomTextFieldWithPriority oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (widget.isPrioritySelected != oldWidget.isPrioritySelected) {
    if (widget.isPrioritySelected) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
}


Widget _buildAnimatedFireIcon() {
  return SizedBox(
    width: 20,
    height: 20,
    child: Stack(
      children: [
        // Базовая иконка для выключенного состояния
        Image.asset(
          'assets/icons/icon-fire-no-color.png',
          width: 20,
          height: 20,
        ),
        // Анимированная цветная иконка
        AnimatedBuilder(
          animation: _fillAnimation,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  // Используем две остановки с одинаковым значением для резкого перехода
                  stops: [_fillAnimation.value, _fillAnimation.value],
                  colors: [
                    Colors.white,
                    Colors.transparent,
                  ],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/icons/icon-fire-color.png',
                width: 20,
                height: 20,
              ),
            );
          },
        ),
      ],
    ),
  );
}


  Widget _buildPrioritySection() {
    if (!widget.showPriority) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: widget.isPrioritySelected,
          onChanged: widget.onPriorityChanged,
          activeColor: const Color(0xff1E2E52),
        ),
        Text(
          widget.priorityText,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(width: 4),
        _buildAnimatedFireIcon(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty || widget.hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xfff1E2E52),
              ),
            ),
            _buildPrioritySection(),
          ],
        ),
        const SizedBox(height: 0),
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
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
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
            errorStyle: const TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.red : Colors.transparent,
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
}