import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Компактное поле ввода БЕЗ label (для использования в карточках)
class CompactTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String)? onChanged;
  final TextAlign textAlign;
  final TextStyle? style;
  final InputDecoration? decoration;
  final bool hasError;
  final FocusNode? focusNode; // ✅ НОВОЕ: Поддержка внешнего FocusNode
  final VoidCallback? onDone; // ✅ НОВОЕ: Callback при нажатии "Готово"

  const CompactTextField({
    required this.controller,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.onChanged,
    this.textAlign = TextAlign.start,
    this.style,
    this.decoration,
    this.hasError = false,
    this.focusNode, // ✅ НОВОЕ
    this.onDone, // ✅ НОВОЕ
    Key? key,
  }) : super(key: key);

  @override
  State<CompactTextField> createState() => _CompactTextFieldState();
}

class _CompactTextFieldState extends State<CompactTextField> {
  late FocusNode _internalFocusNode; // ✅ ИЗМЕНЕНО: Внутренний FocusNode
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode; // ✅ НОВОЕ
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    // ✅ НОВОЕ: Создаём внутренний FocusNode только если не передан извне
    _internalFocusNode = FocusNode();
    
    if (Platform.isIOS) {
      _effectiveFocusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void didUpdateWidget(CompactTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ НОВОЕ: Если FocusNode изменился, переподписываемся
    if (Platform.isIOS && oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _effectiveFocusNode.addListener(_handleFocusChange);
    }
  }

  void _handleFocusChange() {
    if (_effectiveFocusNode.hasFocus) {
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
              // ✅ НОВОЕ: Вызываем callback onDone если он передан
              if (widget.onDone != null) {
                widget.onDone!();
              } else {
                // Иначе просто закрываем клавиатуру
                _effectiveFocusNode.unfocus();
              }
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
    _removeKeyboardToolbar();
    if (Platform.isIOS) {
      _effectiveFocusNode.removeListener(_handleFocusChange);
    }
    // ✅ НОВОЕ: Удаляем внутренний FocusNode только если не используется внешний
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _effectiveFocusNode, // ✅ ИЗМЕНЕНО: Используем эффективный FocusNode
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      textAlign: widget.textAlign,
      style: widget.style,
      decoration: widget.decoration ??
          InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(
              fontSize: 12,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w400,
              color: Color(0xff99A4BA),
            ),
            filled: true,
            fillColor: const Color(0xFFF4F7FD),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: widget.hasError ? Colors.red : const Color(0xFFE5E7EB),
                width: widget.hasError ? 2 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: widget.hasError ? Colors.red : const Color(0xFFE5E7EB),
                width: widget.hasError ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: widget.hasError ? Colors.red : const Color(0xff4759FF),
                width: widget.hasError ? 2 : 1.5,
              ),
            ),
          ),
    );
  }
}