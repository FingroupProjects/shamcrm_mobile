import 'package:flutter/material.dart';
import 'dart:async';

class InfoPanel extends StatefulWidget {
  final String message;
  final VoidCallback? onActionTap;
  final String? actionText;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final Color actionButtonColor;
  final IconData icon;
  final Color iconColor;
  final bool show;
  final Duration? duration;
  final VoidCallback? onDismiss;

  const InfoPanel({
    Key? key,
    required this.message,
    this.onActionTap,
    this.actionText,
    this.backgroundColor = const Color(0xff4CAF50),
    this.textColor = const Color(0xff2E7D32),
    this.borderColor = const Color(0xff4CAF50),
    this.actionButtonColor = const Color(0xff4CAF50),
    this.icon = Icons.check_circle_outline,
    this.iconColor = const Color(0xff4CAF50),
    this.show = true,
    this.duration,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<InfoPanel> createState() => _InfoPanelState();
}

class _InfoPanelState extends State<InfoPanel> {
  Timer? _timer;

  @override
  void didUpdateWidget(InfoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ⭐ Если show изменился с false на true - запускаем таймер
    if (!oldWidget.show && widget.show) {
      _startTimer();
    }

    // ⭐ Если show изменился с true на false - отменяем таймер
    if (oldWidget.show && !widget.show) {
      _timer?.cancel();
    }
  }

  void _startTimer() {
    if (widget.duration != null) {
      _timer?.cancel();
      _timer = Timer(widget.duration!, () {
        if (mounted) {
          widget.onDismiss?.call();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleActionTap() {
    // ⭐ Отменяем таймер
    _timer?.cancel();

    // ⭐ Сначала вызываем действие пользователя
    widget.onActionTap?.call();

    // ⭐ Затем скрываем панель через onDismiss
    if (mounted) {
      widget.onDismiss?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: widget.show
          ? Container(
        key: const ValueKey('info_panel_visible'),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: widget.backgroundColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.borderColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              widget.icon,
              color: widget.iconColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.message,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: widget.textColor,
                ),
              ),
            ),
            if (widget.onActionTap != null && widget.actionText != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _handleActionTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.actionButtonColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.actionText!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      )
          : const SizedBox.shrink(key: ValueKey('info_panel_hidden')),
    );
  }
}