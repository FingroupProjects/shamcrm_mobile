import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/core/theme/widgets/channel_source_style.dart';
import 'package:flutter/material.dart';

export 'package:crm_task_manager/core/theme/widgets/channel_source_style.dart';

/// Иконка источника лида или чата.
/// Берём PNG из assets/icons/leads, как раньше.
/// Сайт рисуем иконкой Icons.language — отдельного файла нет.
class ChannelSourceIcon extends StatelessWidget {
  const ChannelSourceIcon({
    super.key,
    required this.sourceName,
    this.size = 28,
    this.background,
  });

  /// Имя канала, перевод или путь к картинке.
  final String? sourceName;
  final double size;

  /// Фон карточки. Оставлен, чтобы старые вызовы не ломались.
  /// Сам файл выбираем по теме приложения, не по цвету карточки.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final kind = resolveChannelSourceKind(sourceName);
    final isDark = context.isDarkTheme;

    // Сайт без своей картинки. Раньше здесь была иконка языка.
    if (kind == ChannelSourceKind.site) {
      return Icon(
        Icons.language,
        size: size,
        color: context.appColors.textPrimary,
      );
    }

    final path = leadSourceAsset(kind, isDark: isDark);
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Если тёмный файл не подхватился, показываем обычную заглушку.
        return Icon(
          Icons.person,
          size: size * 0.7,
          color: context.appColors.iconSecondary,
        );
      },
    );
  }
}

/// Путь к PNG канала.
/// Тёмные копии есть только у телефона, почты и заглушки.
/// Бренды (Telegram, WhatsApp и остальные) одни и те же в обеих темах.
String leadSourceAsset(ChannelSourceKind kind, {required bool isDark}) {
  switch (kind) {
    case ChannelSourceKind.telegram:
      return 'assets/icons/leads/telegram.png';
    case ChannelSourceKind.whatsapp:
      return 'assets/icons/leads/whatsapp.png';
    case ChannelSourceKind.instagram:
      return 'assets/icons/leads/instagram.png';
    case ChannelSourceKind.youtube:
      return 'assets/icons/leads/youtube.png';
    case ChannelSourceKind.messenger:
    case ChannelSourceKind.facebook:
      // Facebook-канал раньше тоже показывал messenger.png.
      return 'assets/icons/leads/messenger.png';
    case ChannelSourceKind.phone:
      return isDark
          ? 'assets/icons/leads/telefon_dark.png'
          : 'assets/icons/leads/telefon.png';
    case ChannelSourceKind.email:
      return isDark
          ? 'assets/icons/leads/email_dark.png'
          : 'assets/icons/leads/email.png';
    case ChannelSourceKind.site:
      return '';
    case ChannelSourceKind.unknown:
      return isDark
          ? 'assets/icons/leads/default_dark.png'
          : 'assets/icons/leads/default.png';
  }
}
