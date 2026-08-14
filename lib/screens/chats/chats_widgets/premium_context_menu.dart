import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/data/emoji_data.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chats/chat_appearance.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PremiumContextMenu {
  static void show({
    required BuildContext context,
    required Offset messagePosition,
    required Size messageSize,
    required Widget messageWidget,
    required List<ContextMenuItem> items,
    Function(String emoji)? onReactionSelected,
    VoidCallback? onShowFullPicker,
    String? channelKey,
    bool showReactions = true,
    required VoidCallback onDismiss,
  }) {
    final overlay = Overlay.of(context);
    final appearance = ChatAppearanceScope.of(context);
    late OverlayEntry entry;
    var removed = false;

    void dismissAndRemove() {
      if (removed) return;
      removed = true;
      onDismiss();
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (context) => ChatAppearanceScope(
        appearance: appearance,
        child: _PremiumMenuOverlay(
          messagePosition: messagePosition,
          messageSize: messageSize,
          messageWidget: messageWidget,
          items: items,
          onReactionSelected: showReactions && onReactionSelected != null
              ? (emoji) {
                  onReactionSelected(emoji);
                  dismissAndRemove();
                }
              : null,
          onShowFullPicker: showReactions
              ? () {
                  onShowFullPicker?.call();
                  dismissAndRemove();
                }
              : null,
          channelKey: channelKey,
          showReactions: showReactions,
          onDismiss: dismissAndRemove,
        ),
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
  final Function(String emoji)? onReactionSelected;
  final VoidCallback? onShowFullPicker;
  final String? channelKey;
  final bool showReactions;
  final VoidCallback onDismiss;

  const _PremiumMenuOverlay({
    Key? key,
    required this.messagePosition,
    required this.messageSize,
    required this.messageWidget,
    required this.items,
    this.onReactionSelected,
    this.onShowFullPicker,
    this.channelKey,
    this.showReactions = true,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<_PremiumMenuOverlay> createState() => _PremiumMenuOverlayState();
}

class _PremiumMenuOverlayState extends State<_PremiumMenuOverlay>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  late Animation<double> _animation;
  late final double _initialKeyboardInset;

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
    _initialKeyboardInset = _currentKeyboardInset();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  double _currentKeyboardInset() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return 0;
    return views.first.viewInsets.bottom;
  }

  @override
  void didChangeMetrics() {
    final inset = _currentKeyboardInset();
    if (inset > _initialKeyboardInset + 80) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onDismiss();
        }
      });
    }
  }

  void _close() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final safeTop = mediaQuery.padding.top + 8.0;
    final safeBottom = screenHeight -
        mediaQuery.padding.bottom -
        mediaQuery.viewInsets.bottom -
        8.0;

    // Константы для расчёта
    const double horizontalPadding = 16.0;
    const double gap = 10.0;
    final double maxMenuWidth =
        (screenWidth - (horizontalPadding * 2)).clamp(220.0, 280.0);
    final double reactionPanelHeight = widget.showReactions ? 54.0 + gap : 0.0;

    // Приблизительная высота всего блока меню (реакции + само меню)
    final double desiredMenuHeight =
        (widget.items.length * 50.0) + reactionPanelHeight + 8.0;

    final messageTop = widget.messagePosition.dy;
    final messageBottom = messageTop + widget.messageSize.height;
    final spaceBelow = safeBottom - messageBottom - gap;
    final spaceAbove = messageTop - safeTop - gap;
    final maxSafeHeight = (safeBottom - safeTop).clamp(120.0, screenHeight);

    // Ставим меню туда, где оно целиком влезает; иначе — в сторону с большим местом.
    // Если сообщение огромное (видео) и места нет ни сверху, ни снизу — рисуем
    // поверх сообщения в безопасной зоне, чтобы пункты не обрезались.
    final bool fitsBelow = spaceBelow >= desiredMenuHeight;
    final bool fitsAbove = spaceAbove >= desiredMenuHeight;
    final bool hasSideSpace = spaceBelow > 80 || spaceAbove > 80;

    final bool isMenuBelow;
    final bool overlayOnMessage;
    if (fitsBelow) {
      isMenuBelow = true;
      overlayOnMessage = false;
    } else if (fitsAbove) {
      isMenuBelow = false;
      overlayOnMessage = false;
    } else if (hasSideSpace) {
      isMenuBelow = spaceBelow >= spaceAbove;
      overlayOnMessage = false;
    } else {
      isMenuBelow = true;
      overlayOnMessage = true;
    }

    final double availableHeight = overlayOnMessage
        ? maxSafeHeight
        : (isMenuBelow ? spaceBelow : spaceAbove).clamp(0.0, maxSafeHeight);
    // Если места почти нет — всё равно показываем меню поверх сообщения.
    final double menuBlockHeight = desiredMenuHeight
        .clamp(
          0.0,
          availableHeight >= 80 ? availableHeight : maxSafeHeight,
        )
        .toDouble();
    final bool useOverlayFallback =
        overlayOnMessage || availableHeight < 80;

    double top;
    if (useOverlayFallback) {
      top = (safeBottom - menuBlockHeight).clamp(safeTop, safeBottom);
    } else if (isMenuBelow) {
      top = messageBottom + gap;
      if (top + menuBlockHeight > safeBottom) {
        top = (safeBottom - menuBlockHeight).clamp(safeTop, safeBottom);
      }
    } else {
      top = messageTop - menuBlockHeight - gap;
      if (top < safeTop) {
        top = safeTop;
      }
    }

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

    final needsScroll = desiredMenuHeight > menuBlockHeight + 0.5;

    return GestureDetector(
      onTap: _close,
      child: Material(
        color: context.appColors.overlay.withValues(alpha: 0.0),
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
                      Container(
                        color: context.appColors.overlay.withValues(
                              alpha: 0.3 * value,
                            ),
                      ),
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

            // Меню и реакции — всегда внутри безопасной зоны экрана
            Positioned(
              left: left,
              top: top,
              width: maxMenuWidth,
              child: ScaleTransition(
                scale: _animation,
                alignment:
                    isMenuBelow ? Alignment.topCenter : Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: menuBlockHeight),
                  child: needsScroll
                      ? SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: _buildMenuColumn(),
                        )
                      : _buildMenuColumn(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showReactions) ...[
          _buildReactionPanel(),
          const SizedBox(height: 10),
        ],
        _buildMenuCard(),
      ],
    );
  }

  Widget _buildReactionPanel() {
    final contextReactions = EmojiData.reactionsForSource(
      'context_menu',
      channelKey: widget.channelKey,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: context.appColors.surfacePrimary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow.withValues(alpha: 0.12),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 6),
            ...contextReactions.map((emoji) {
              return GestureDetector(
                onTap: () => widget.onReactionSelected?.call(emoji),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appColors.surfacePrimary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow.withValues(alpha: 0.12),
            blurRadius: 10,
            spreadRadius: 2,
          )
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
                color: context.appColors.borderSubtle,
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
        final action = item.onTap;
        // Снимаем оверлей сразу, иначе клавиатура (Ответить/Изменить)
        // оставляет панель реакций поверх поля ввода.
        widget.onDismiss();
        WidgetsBinding.instance.addPostFrameCallback((_) => action());
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.icon.contains('.svg'))
              SvgPicture.asset(
                item.icon,
                width: 22,
                height: 22,
                color: item.isDestructive
                    ? context.appColors.error
                    : context.appColors.textPrimary,
              )
            else
              Icon(
                Icons.copy, // Fallback
                size: 22,
                color: item.isDestructive
                    ? context.appColors.error
                    : context.appColors.textPrimary,
              ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                item.text,
                softWrap: true,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: item.isDestructive
                      ? context.appColors.error
                      : context.appColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
