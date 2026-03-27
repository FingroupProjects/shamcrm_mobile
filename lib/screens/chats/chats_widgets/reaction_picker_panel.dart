import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:crm_task_manager/data/emoji_data.dart';

/// Панель выбора реакций в iOS стиле
class ReactionPickerPanel extends StatefulWidget {
  final Function(String emoji) onEmojiSelected;
  final Offset position;
  final bool isAbove;
  final VoidCallback? onShowFullPicker; // Callback для открытия полной панели

  const ReactionPickerPanel({
    Key? key,
    required this.onEmojiSelected,
    required this.position,
    this.isAbove = false,
    this.onShowFullPicker,
  }) : super(key: key);

  @override
  State<ReactionPickerPanel> createState() => _ReactionPickerPanelState();
}

class _ReactionPickerPanelState extends State<ReactionPickerPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleEmojiTap(String emoji) {
    widget.onEmojiSelected(emoji);
    _controller.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _handleMoreTap() {
    _controller.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onShowFullPicker?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Получаем ширину экрана для точного центрирования
    final screenWidth = MediaQuery.of(context).size.width;

    // Примерная ширина панели (8 эмодзи * 32px + кнопка + padding)
    const panelWidth = 400.0;

    // Центрируем панель по горизонтали
    final centeredLeft = (screenWidth - panelWidth) / 2;

    return Stack(
      children: [
        // Полупрозрачный фон с размытием
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              _controller.reverse().then((_) {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              });
            },
            child: AnimatedBuilder(
              animation: _opacityAnimation,
              builder: (context, child) {
                return BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 2 * _opacityAnimation.value,
                    sigmaY: 2 * _opacityAnimation.value,
                  ),
                  child: Container(
                    color:
                        Colors.black.withOpacity(0.1 * _opacityAnimation.value),
                  ),
                );
              },
            ),
          ),
        ),
        // Панель с эмодзи - СТРОГО ПО ЦЕНТРУ экрана
        Positioned(
          // Центрируем строго по середине экрана
          left: centeredLeft,
          // Размещаем на 60-70px выше точки нажатия
          top: widget.position.dy - -430,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                alignment: widget.isAbove
                    ? Alignment.bottomCenter
                    : Alignment.topCenter,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: child,
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Популярные реакции из EmojiData
                    ...EmojiData.quickReactions.map((emoji) {
                      return _buildEmojiButton(emoji);
                    }).toList(),
                    // Кнопка "+" для открытия полной панели
                    _buildMoreButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmojiButton(String emoji) {
    return GestureDetector(
      onTap: () => _handleEmojiTap(emoji),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(
          milliseconds: 200 + EmojiData.quickReactions.indexOf(emoji) * 50,
        ),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: HoverEffect(
            child: Text(
              emoji,
              style: const TextStyle(
                fontSize: 24, // Уменьшено с 28
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Кнопка "+" для открытия полной панели
  Widget _buildMoreButton() {
    return GestureDetector(
      onTap: _handleMoreTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: HoverEffect(
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                size: 16,
                color: Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Эффект при наведении/нажатии на эмодзи
class HoverEffect extends StatefulWidget {
  final Widget child;

  const HoverEffect({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<HoverEffect> createState() => _HoverEffectState();
}

class _HoverEffectState extends State<HoverEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _hoverController.forward(),
      onTapUp: (_) => _hoverController.reverse(),
      onTapCancel: () => _hoverController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Показать панель выбора реакций
Future<void> showReactionPicker({
  required BuildContext context,
  required Offset position,
  required Function(String emoji) onEmojiSelected,
  VoidCallback? onShowFullPicker,
  bool isAbove = false,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.transparent,
    barrierDismissible: true,
    builder: (context) {
      return ReactionPickerPanel(
        position: position,
        onEmojiSelected: onEmojiSelected,
        isAbove: isAbove,
        onShowFullPicker: onShowFullPicker,
      );
    },
  );
}
