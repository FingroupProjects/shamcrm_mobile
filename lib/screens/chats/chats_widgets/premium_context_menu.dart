import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/data/emoji_data.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PremiumContextMenu {
  static void show({
    required BuildContext context,
    required Offset messagePosition,
    required Size messageSize,
    required Widget messageWidget,
    required List<ContextMenuItem> items,
    required Function(String emoji) onReactionSelected,
    VoidCallback? onShowFullPicker,
    required VoidCallback onDismiss,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _PremiumMenuOverlay(
        messagePosition: messagePosition,
        messageSize: messageSize,
        messageWidget: messageWidget,
        items: items,
        onReactionSelected: (emoji) {
          onReactionSelected(emoji);
          onDismiss();
          entry.remove();
        },
        onShowFullPicker: () {
          onShowFullPicker?.call();
          onDismiss();
          entry.remove();
        },
        onDismiss: () {
          onDismiss();
          entry.remove();
        },
      ),
    );

    overlay.insert(entry);
  }
}

class ContextMenuItem {
  final String icon;
  final String text;
  final VoidCallback onTap;
  final bool isDestructive;

  ContextMenuItem({
    required this.icon,
    required this.text,
    required this.onTap,
    this.isDestructive = false,
  });
}

class _PremiumMenuOverlay extends StatefulWidget {
  final Offset messagePosition;
  final Size messageSize;
  final Widget messageWidget;
  final List<ContextMenuItem> items;
  final Function(String emoji) onReactionSelected;
  final VoidCallback? onShowFullPicker;
  final VoidCallback onDismiss;

  const _PremiumMenuOverlay({
    Key? key,
    required this.messagePosition,
    required this.messageSize,
    required this.messageWidget,
    required this.items,
    required this.onReactionSelected,
    this.onShowFullPicker,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<_PremiumMenuOverlay> createState() => _PremiumMenuOverlayState();
}

class _PremiumMenuOverlayState extends State<_PremiumMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack, // Пружинный эффект
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Константы для расчёта
    const double maxMenuWidth = 260.0;
    const double horizontalPadding = 16.0;
    const double reactionPanelHeight = 54.0;

    // Рассчитываем вертикальное положение
    final isMenuBelow = widget.messagePosition.dy < screenHeight / 2;

    // Рассчитываем горизонтальное положение, чтобы меню не вылезало за экран
    double left = widget.messagePosition.dx;
    // Если сообщение справа, прижимаем меню к правому краю с отступом
    if (left + maxMenuWidth > screenWidth - horizontalPadding) {
      left = screenWidth - maxMenuWidth - horizontalPadding;
    }
    // Если слишком сильно сместилось влево
    if (left < horizontalPadding) {
      left = horizontalPadding;
    }

    // Приблизительная высота всего блока меню (реакции + само меню)
    final totalMenuHeight =
        (widget.items.length * 50.0) + reactionPanelHeight + 20;

    return GestureDetector(
      onTap: _close,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Размытый фон
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 200),
              builder: (context, value, child) {
                return BackdropFilter(
                  filter:
                      ImageFilter.blur(sigmaX: 10 * value, sigmaY: 10 * value),
                  child:
                      Container(color: Colors.black.withOpacity(0.3 * value)),
                );
              },
            ),

            // Оригинальное сообщение в оверлее (подсветка)
            Positioned(
              left: widget.messagePosition.dx,
              top: widget.messagePosition.dy,
              width: widget.messageSize.width,
              height: widget.messageSize.height,
              child: widget.messageWidget,
            ),

            // Меню и реакции
            Positioned(
              left: left,
              top: isMenuBelow
                  ? widget.messagePosition.dy + widget.messageSize.height + 10
                  : widget.messagePosition.dy - totalMenuHeight - 10,
              width: maxMenuWidth,
              child: ScaleTransition(
                scale: _animation,
                alignment:
                    isMenuBelow ? Alignment.topCenter : Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Панель реакций
                    _buildReactionPanel(),
                    const SizedBox(height: 10),
                    // Контекстное меню
                    _buildMenuCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 6),
            ...EmojiData.quickReactions.map((emoji) {
              return GestureDetector(
                onTap: () => widget.onReactionSelected(emoji),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              );
            }).toList(),
            GestureDetector(
              onTap: widget.onShowFullPicker,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 20, color: Colors.black54),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.items.map((item) {
          final isLast = item == widget.items.last;
          return Column(
            children: [
              _buildMenuItemWidget(item),
              if (!isLast)
                Divider(
                    height: 1,
                    color: Colors.black12,
                    indent: 15,
                    endIndent: 15),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItemWidget(ContextMenuItem item) {
    return InkWell(
      onTap: () {
        item.onTap();
        _close();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: Row(
          children: [
            if (item.icon.contains('.svg'))
              SvgPicture.asset(
                item.icon,
                width: 22,
                height: 22,
                color: item.isDestructive ? Colors.red : Colors.black87,
              )
            else
              Icon(
                Icons.copy, // Fallback
                size: 22,
                color: item.isDestructive ? Colors.red : Colors.black87,
              ),
            const SizedBox(width: 15),
            Text(
              item.text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: item.isDestructive ? Colors.red : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
