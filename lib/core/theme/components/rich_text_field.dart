import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Theme-aware текстовое поле с поддержкой HTML-форматирования:
/// жирный, курсив, зачеркнутый, ссылки.
/// Плавно расширяется до [maxVisibleLines] строк, затем скроллится.
///
/// ВАЖНО: глобальная тема (AppInputTheme) задаёт для InputDecorationTheme
/// filled: true, fillColor, enabledBorder и focusedBorder с видимой рамкой.
/// Если явно не погасить именно enabledBorder/focusedBorder/disabledBorder,
/// Flutter возьмёт их из темы, даже если тут указан border: InputBorder.none —
/// потому что border используется только как fallback, когда конкретное
/// состояние (enabled/focused/...) не задано. Отсюда и "лишняя рамка + залитый
/// фон" внутри уже оформленного контейнера. Ниже все состояния погашены явно.
class RichTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;
  final String hintText;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final Color? fillColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? contentPadding;
  final int maxVisibleLines;
  final double lineHeight;
  final String? htmlContent;
  final VoidCallback? onLongPress;

  const RichTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.hintText,
    this.style,
    this.hintStyle,
    this.fillColor,
    this.borderRadius,
    this.contentPadding,
    this.maxVisibleLines = 6,
    this.lineHeight = 20.0,
    this.htmlContent,
    this.onLongPress,
  });

  @override
  State<RichTextField> createState() => _RichTextFieldState();
}

class _RichTextFieldState extends State<RichTextField> {
  final double _minHeight = 50.0;
  final ScrollController _scrollController = ScrollController();
  Timer? _updateTimer;
  Timer? _longPressTimer;

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateHeight();
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _longPressTimer?.cancel();
    widget.controller.removeListener(_onTextChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _updateTimer?.cancel();
    _updateTimer = Timer(const Duration(milliseconds: 50), _updateHeight);
  }

  void _updateHeight() {
    if (!mounted) return;

    final textSpan = TextSpan(
      text: widget.controller.text.isEmpty
          ? widget.hintText
          : widget.controller.text,
      style: widget.style,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    final renderBox = context.findRenderObject() as RenderBox?;
    final textFieldWidth = renderBox?.size.width ?? 300;
    final availableWidth =
        textFieldWidth - (widget.contentPadding?.horizontal ?? 20);

    textPainter.layout(maxWidth: availableWidth);

    final lineCount = textPainter.computeLineMetrics().length;

    if (lineCount > widget.maxVisibleLines) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.onLongPress != null) {
      _longPressTimer?.cancel();
      _longPressTimer = Timer(const Duration(milliseconds: 500), () {
        widget.onLongPress?.call();
      });
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _longPressTimer?.cancel();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _longPressTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    Widget textField = TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      scrollController: _scrollController,
      onChanged: widget.onChanged,
      minLines: 1,
      maxLines: widget.maxVisibleLines,
      style: widget.style,
      textAlignVertical: TextAlignVertical.center,
      cursorColor: widget.style?.color,
      inputFormatters: [
        TextInputFormatter.withFunction((oldValue, newValue) => newValue),
      ],
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: widget.hintStyle,
        // isCollapsed: true полностью отключает встроенную логику
        // InputDecorator по расчёту вертикальных отступов (она считается по
        // метрикам шрифта, а не по contentPadding, из-за чего текст "плавает"
        // и обычно оказывается чуть выше центра). При isCollapsed: true
        // позиция текста зависит только от заданного contentPadding —
        // именно так делают кастомные "пилюльные" поля ввода в мессенджерах.
        isCollapsed: true,
        contentPadding: widget.contentPadding,
        // --- ключевой фикс ---
        // Гасим заливку и рамку темы, чтобы поле было "прозрачным" и
        // визуально сливалось с внешним Container, у которого уже есть
        // свой фон/скругление/тень (как в Telegram: один "пилюльный" бар,
        // а не рамка внутри рамки).
        filled: false,
        fillColor: Colors.transparent,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
      ),
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      enableInteractiveSelection: true,
      contextMenuBuilder: (context, editableTextState) =>
          const SizedBox.shrink(),
    );

    // Wrap in listener for long-press
    textField = Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: textField,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: _minHeight),
      child: textField,
    );
  }
}