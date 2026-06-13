import 'dart:async';

import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Theme-aware текстовое поле с поддержкой HTML-форматирования:
/// жирный, курсив, зачеркнутый, ссылки.
/// Плавно расширяется до [maxVisibleLines] строк, затем скроллится.
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

class _RichTextFieldState extends State<RichTextField>
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

  @override
  void dispose() {
    _updateTimer?.cancel();
    _longPressTimer?.cancel();
    widget.controller.removeListener(_onTextChanged);
    _animationController.dispose();
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

  // _buildFormattedTextSpan удалён — не используется.
  // Форматирование текста реализовано на уровне _htmlContent в input_field.dart.
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
    final isTransparent = widget.fillColor == null ||
        widget.fillColor == context.appColors.overlay.withValues(alpha: 0.0);

    Widget textField = TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      scrollController: _scrollController,
      onChanged: widget.onChanged,
      maxLines: null,
      style: widget.style,
      textAlignVertical: TextAlignVertical.center,
      inputFormatters: [
        TextInputFormatter.withFunction((oldValue, newValue) => newValue),
      ],
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: widget.hintStyle,
        border: InputBorder.none,
        contentPadding: widget.contentPadding,
        isDense: true,
        isCollapsed: false,
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

    // Wrap in animated height container
    return AnimatedBuilder(
      animation: _heightAnimation,
      builder: (context, child) => Container(
        height: _heightAnimation.value,
        decoration: !isTransparent
            ? BoxDecoration(
                color: widget.fillColor,
                borderRadius: widget.borderRadius,
              )
            : null,
        child: child,
      ),
      child: textField,
    );
  }
}
