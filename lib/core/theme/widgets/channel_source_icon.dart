import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/core/theme/widgets/channel_source_style.dart';
import 'package:flutter/material.dart';

export 'package:crm_task_manager/core/theme/widgets/channel_source_style.dart';

/// Круглая иконка источника.
/// На тёмной карточке — светлая. На светлой — тёмная.
/// У брендов (Telegram, WhatsApp) свой цвет, чтобы список не был одинаковым.
class ChannelSourceIcon extends StatelessWidget {
  const ChannelSourceIcon({
    super.key,
    required this.sourceName,
    this.size = 28,
    this.background,
  });

  final String? sourceName;
  final double size;

  /// Фон карточки. От него считаем, светлую или тёмную иконку рисовать.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final surface = background ?? context.appColors.surfacePrimary;
    final onDark = context.useLightForeground(surface);
    final look = lookForChannel(resolveChannelSourceKind(sourceName));
    final iconSize = size * 0.54;

    late final Color fill;
    late final Color glyph;
    Gradient? gradient;
    Color? border;

    switch (look.style) {
      case ChannelBadgeStyle.solid:
        fill = look.brand;
        glyph = Colors.white;
        break;
      case ChannelBadgeStyle.adaptive:
        // Тёмная карточка — светлый кружок и тёмная иконка.
        // Светлая карточка — тёмный кружок и светлая иконка.
        fill = onDark ? const Color(0xFFE8EEF5) : const Color(0xFF1A2332);
        glyph = onDark ? const Color(0xFF1A2332) : const Color(0xFFF8FAFC);
        border = onDark
            ? Colors.white.withValues(alpha: 0.18)
            : Colors.black.withValues(alpha: 0.08);
        break;
      case ChannelBadgeStyle.soft:
        fill = look.brand.withValues(alpha: onDark ? 0.24 : 0.12);
        glyph = look.brand;
        border = look.brand.withValues(alpha: onDark ? 0.42 : 0.22);
        break;
      case ChannelBadgeStyle.gradient:
        fill = look.brand;
        glyph = Colors.white;
        gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: look.gradient ?? [look.brand, look.brand],
        );
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: gradient == null ? fill : null,
        gradient: gradient,
        border: Border.all(
          color: border ?? Colors.white.withValues(alpha: 0.16),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: look.brand.withValues(alpha: onDark ? 0.28 : 0.16),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(look.icon, size: iconSize, color: glyph),
    );
  }
}
