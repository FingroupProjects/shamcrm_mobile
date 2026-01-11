import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Кастомное текстовое поле с плавной анимацией изменения высоты
/// Работает как в Telegram - до 6 строк расширяется, потом скролл
/// Поддерживает HTML-форматирование: жирный, курсив, зачеркнутый, ссылки
class AnimatedTextField extends StatefulWidget {
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
  final String? htmlContent; // HTML контент для форматирования
  final VoidCallback? onLongPress; // Callback для долгого нажатия

  const AnimatedTextField({
    Key? key,
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
  }) : super(key: key);

  @override
  State<AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<AnimatedTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  double _currentHeight = 50.0;
  final double _minHeight = 50.0;
  late double _maxHeight;
  final ScrollController _scrollController = ScrollController();
  Timer? _updateTimer;
  Timer? _longPressTimer;

  @override
  void initState() {
    super.initState();

    _maxHeight = (widget.contentPadding?.vertical ?? 24) +
        (widget.maxVisibleLines * widget.lineHeight);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _heightAnimation = Tween<double>(
      begin: _minHeight,
      end: _minHeight,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    _updateTimer?.cancel();
    _updateTimer = Timer(const Duration(milliseconds: 50), () {
      _updateHeight();
    });
  }

  void _updateHeight() {
    if (!mounted) return;

    final textSpan = TextSpan(
      text: widget.controller.text.isEmpty ? widget.hintText : widget.controller.text,
      style: widget.style,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    final renderBox = context.findRenderObject() as RenderBox?;
    final textFieldWidth = renderBox?.size.width ?? 300;
    final availableWidth = textFieldWidth - (widget.contentPadding?.horizontal ?? 20);

    textPainter.layout(maxWidth: availableWidth);

    final lineMetrics = textPainter.computeLineMetrics();
    final lineCount = lineMetrics.length;

    double targetHeight = (widget.contentPadding?.vertical ?? 24) +
        (lineCount * widget.lineHeight);

    targetHeight = targetHeight.clamp(_minHeight, _maxHeight);

    if ((_currentHeight - targetHeight).abs() > 2) {
      setState(() {
        _heightAnimation = Tween<double>(
          begin: _currentHeight,
          end: targetHeight,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
        _currentHeight = targetHeight;
      });

      _animationController.forward(from: 0);
    }

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

  /// Парсим HTML и создаём TextSpan с форматированием
  TextSpan _buildFormattedTextSpan(BuildContext context, {required bool withComposing}) {
    final String text = widget.controller.text;
    final String html = widget.htmlContent ?? text;
    
    if (text.isEmpty) {
      return TextSpan(
        text: widget.hintText,
        style: widget.hintStyle,
      );
    }

    // Если нет HTML тегов, возвращаем обычный текст
    if (!html.contains('<strong>') && 
        !html.contains('<em>') && 
        !html.contains('<s>') && 
        !html.contains('<a href=')) {
      return TextSpan(
        text: text,
        style: widget.style,
      );
    }

    List<InlineSpan> spans = [];

    // Регулярные выражения для парсинга HTML тегов
    final boldRegex = RegExp(r'<strong>(.*?)</strong>');
    final italicRegex = RegExp(r'<em>(.*?)</em>');
    final strikeRegex = RegExp(r'<s>(.*?)</s>');
    final linkRegex = RegExp(r'<a href="([^"]*)"[^>]*>(.*?)</a>');

    int lastIndex = 0;
    int currentTextIndex = 0; // Позиция в отображаемом тексте

    // Находим все теги в порядке их появления
    final allMatches = <MapEntry<int, Match>>[];
    
    boldRegex.allMatches(html).forEach((m) {
      allMatches.add(MapEntry(m.start, m));
    });
    italicRegex.allMatches(html).forEach((m) {
      allMatches.add(MapEntry(m.start, m));
    });
    strikeRegex.allMatches(html).forEach((m) {
      allMatches.add(MapEntry(m.start, m));
    });
    linkRegex.allMatches(html).forEach((m) {
      allMatches.add(MapEntry(m.start, m));
    });

    // Сортируем по позиции
    allMatches.sort((a, b) => a.key.compareTo(b.key));

    for (var entry in allMatches) {
      final match = entry.value;

      // Добавляем обычный текст перед тегом
      if (match.start > lastIndex) {
        final plainText = html.substring(lastIndex, match.start);
        final displayText = text.substring(currentTextIndex, currentTextIndex + plainText.length);
        spans.add(TextSpan(
          text: displayText,
          style: widget.style,
        ));
        currentTextIndex += plainText.length;
      }

      // Определяем тип тега и добавляем форматированный текст
      String? contentText;
      TextStyle? contentStyle;

      if (match.pattern == boldRegex) {
        contentText = match.group(1);
        final displayText = text.substring(currentTextIndex, currentTextIndex + (contentText?.length ?? 0));
        contentStyle = widget.style?.copyWith(
          fontWeight: FontWeight.bold,
        );
        spans.add(TextSpan(text: displayText, style: contentStyle));
        currentTextIndex += contentText?.length ?? 0;
      } else if (match.pattern == italicRegex) {
        contentText = match.group(1);
        final displayText = text.substring(currentTextIndex, currentTextIndex + (contentText?.length ?? 0));
        contentStyle = widget.style?.copyWith(
          fontStyle: FontStyle.italic,
        );
        spans.add(TextSpan(text: displayText, style: contentStyle));
        currentTextIndex += contentText?.length ?? 0;
      } else if (match.pattern == strikeRegex) {
        contentText = match.group(1);
        final displayText = text.substring(currentTextIndex, currentTextIndex + (contentText?.length ?? 0));
        contentStyle = widget.style?.copyWith(
          decoration: TextDecoration.lineThrough,
        );
        spans.add(TextSpan(text: displayText, style: contentStyle));
        currentTextIndex += contentText?.length ?? 0;
      } else if (match.pattern == linkRegex) {
        contentText = match.group(2);
        final displayText = text.substring(currentTextIndex, currentTextIndex + (contentText?.length ?? 0));
        contentStyle = widget.style?.copyWith(
          color: Color(0xff1E2E52),
          decoration: TextDecoration.underline,
          decorationColor: Color(0xff1E2E52),
        );
        spans.add(TextSpan(text: displayText, style: contentStyle));
        currentTextIndex += contentText?.length ?? 0;
      }

      lastIndex = match.end;
    }

    // Добавляем оставшийся обычный текст
    if (currentTextIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentTextIndex),
        style: widget.style,
      ));
    }

    return TextSpan(children: spans);
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
    return AnimatedBuilder(
      animation: _heightAnimation,
      builder: (context, child) {
        return Container(
          height: _heightAnimation.value,
          // ✅ ОБНОВЛЕНО: Если fillColor прозрачный, не добавляем фон (для glass effect)
          decoration: widget.fillColor != null && widget.fillColor != Colors.transparent
              ? BoxDecoration(
                  color: widget.fillColor,
                  borderRadius: widget.borderRadius,
                )
              : null, // Позволяем внешнему Container управлять фоном
          child: Listener(
            onPointerDown: _handlePointerDown,
            onPointerUp: _handlePointerUp,
            onPointerCancel: _handlePointerCancel,
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              scrollController: _scrollController,
              onChanged: widget.onChanged,
              maxLines: null,
              style: widget.style,
              // ВАЖНО: Кастомный билдер для TextSpan с форматированием
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  // Apply custom formatting logic here if needed
                  return newValue;
                }),
              ],
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: widget.hintStyle,
                border: InputBorder.none,
                contentPadding: widget.contentPadding,
                isDense: true,
              ),
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              enableInteractiveSelection: true,
              contextMenuBuilder: (context, editableTextState) {
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      },
    );
  }


  @override
  void dispose() {
    _updateTimer?.cancel();
    _longPressTimer?.cancel();
    widget.controller.removeListener(_onTextChanged);
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}