import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Текстовое поле с поддержкой HTML-форматирования (жирный, курсив, зачеркнутый, ссылки)
/// Визуально отображает форматирование прямо в поле ввода
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
  final String htmlContent; // HTML контент для парсинга

  const RichTextField({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.hintText,
    required this.htmlContent,
    this.style,
    this.hintStyle,
    this.fillColor,
    this.borderRadius,
    this.contentPadding,
    this.maxVisibleLines = 6,
    this.lineHeight = 20.0,
  }) : super(key: key);

  @override
  State<RichTextField> createState() => _RichTextFieldState();
}

class _RichTextFieldState extends State<RichTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  double _currentHeight = 50.0;
  final double _minHeight = 50.0;
  late double _maxHeight;
  final ScrollController _scrollController = ScrollController();
  Timer? _updateTimer;
  
  // Для отслеживания позиции курсора
  int _cursorPosition = 0;

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
    
    // Сохраняем позицию курсора
    setState(() {
      _cursorPosition = widget.controller.selection.baseOffset;
    });
  }

  void _updateHeight() {
    if (!mounted) return;

    final textSpan = _buildTextSpan(widget.htmlContent);

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
  TextSpan _buildTextSpan(String html) {
    if (html.isEmpty) {
      return TextSpan(
        text: widget.hintText,
        style: widget.hintStyle,
      );
    }

    List<InlineSpan> spans = [];

    // Регулярные выражения для парсинга HTML тегов
    final boldRegex = RegExp(r'<strong>(.*?)</strong>');
    final italicRegex = RegExp(r'<em>(.*?)</em>');
    final strikeRegex = RegExp(r'<s>(.*?)</s>');
    final linkRegex = RegExp(r'<a href="([^"]*)"[^>]*>(.*?)</a>');

    int lastIndex = 0;

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
        spans.add(TextSpan(
          text: html.substring(lastIndex, match.start),
          style: widget.style?.copyWith(color: Colors.black),
        ));
      }

      // Определяем тип тега и добавляем форматированный текст
      if (match.pattern == boldRegex) {
        spans.add(TextSpan(
          text: match.group(1),
          style: widget.style?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ));
      } else if (match.pattern == italicRegex) {
        spans.add(TextSpan(
          text: match.group(1),
          style: widget.style?.copyWith(
            fontStyle: FontStyle.italic,
            color: Colors.black,
          ),
        ));
      } else if (match.pattern == strikeRegex) {
        spans.add(TextSpan(
          text: match.group(1),
          style: widget.style?.copyWith(
            decoration: TextDecoration.lineThrough,
            decorationColor: Colors.black,
            color: Colors.black,
          ),
        ));
      } else if (match.pattern == linkRegex) {
        spans.add(TextSpan(
          text: match.group(2),
          style: widget.style?.copyWith(
            color: Color(0xff1E2E52),
            decoration: TextDecoration.underline,
            decorationColor: Color(0xff1E2E52),
          ),
        ));
      }

      lastIndex = match.end;
    }

    // Добавляем оставшийся обычный текст
    if (lastIndex < html.length) {
      spans.add(TextSpan(
        text: html.substring(lastIndex),
        style: widget.style?.copyWith(color: Colors.black),
      ));
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _heightAnimation,
      builder: (context, child) {
        return Container(
          height: _heightAnimation.value,
          decoration: BoxDecoration(
            color: widget.fillColor,
            borderRadius: widget.borderRadius,
          ),
          child: Stack(
            children: [
              // Невидимый TextField для ввода и курсора
              Positioned.fill(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  scrollController: _scrollController,
                  onChanged: widget.onChanged,
                  maxLines: null,
                  style: widget.style?.copyWith(color: Colors.transparent),
                  decoration: InputDecoration(
                    hintText: '', // Хинт показываем на RichText
                    border: InputBorder.none,
                    contentPadding: widget.contentPadding,
                    isDense: true,
                  ),
                  cursorColor: Color(0xff1E2E52), // Курсор видимый
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  enableInteractiveSelection: true,
                  contextMenuBuilder: (context, editableTextState) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
              // RichText поверх для отображения форматирования
              Positioned.fill(
                child: IgnorePointer( // Игнорируем клики - они идут в TextField
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: widget.contentPadding,
                    child: RichText(
                      text: _buildTextSpan(widget.htmlContent),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    widget.controller.removeListener(_onTextChanged);
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}