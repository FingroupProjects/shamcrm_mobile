import 'package:flutter/material.dart';

/// Тип канала. Нужен, чтобы дать каждому источнику свой вид.
enum ChannelSourceKind {
  telegram,
  whatsapp,
  phone,
  email,
  instagram,
  youtube,
  messenger,
  facebook,
  site,
  unknown,
}

/// Стиль бейджа. Разные каналы выглядят по-разному.
enum ChannelBadgeStyle {
  solid,
  adaptive,
  soft,
  gradient,
}

class ChannelSourceLook {
  const ChannelSourceLook({
    required this.kind,
    required this.icon,
    required this.brand,
    required this.style,
    this.gradient,
  });

  final ChannelSourceKind kind;
  final IconData icon;
  final Color brand;
  final ChannelBadgeStyle style;
  final List<Color>? gradient;
}

/// Ищем канал по имени из API, переводу или пути к картинке.
/// Работает с русским, таджикским и английским.
ChannelSourceKind resolveChannelSourceKind(String? rawName) {
  final name = (rawName ?? '')
      .trim()
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll('-', '_')
      .replaceAll(' ', '');

  if (name.isEmpty) return ChannelSourceKind.unknown;
  if (name.contains('telegram') ||
      name.contains('телеграм') ||
      name.contains('mini_app') ||
      name.contains('miniapp')) {
    return ChannelSourceKind.telegram;
  }
  if (name.contains('whatsapp') ||
      name.contains('ватсап') ||
      name.contains('вацап') ||
      name.contains('green_api') ||
      name.contains('greenapi')) {
    return ChannelSourceKind.whatsapp;
  }
  if (name.contains('instagram') || name.contains('инстаграм')) {
    return ChannelSourceKind.instagram;
  }
  // YouTube-интеграция: канал, комментарий или русское имя.
  if (name.contains('youtube') || name.contains('ютуб')) {
    return ChannelSourceKind.youtube;
  }
  if (name.contains('messenger') || name.contains('мессенджер')) {
    return ChannelSourceKind.messenger;
  }
  if (name.contains('facebook') || name.contains('фейсбук')) {
    return ChannelSourceKind.facebook;
  }
  if (name.contains('email') || name.contains('почт') || name.contains('mail')) {
    return ChannelSourceKind.email;
  }
  if (name.contains('phone') ||
      name.contains('телефон') ||
      name.contains('telefon') ||
      name.contains('telephony')) {
    return ChannelSourceKind.phone;
  }
  // «Интернет магазин» — это канал site. Для него нет PNG.
  if (name.contains('site') ||
      name.contains('сайт') ||
      name.contains('web') ||
      name.contains('internet') ||
      name.contains('интернет')) {
    return ChannelSourceKind.site;
  }
  return ChannelSourceKind.unknown;
}

ChannelSourceLook lookForChannel(ChannelSourceKind kind) {
  switch (kind) {
    case ChannelSourceKind.telegram:
      return const ChannelSourceLook(
        kind: ChannelSourceKind.telegram,
        icon: Icons.telegram,
        brand: Color(0xFF2AABEE),
        style: ChannelBadgeStyle.solid,
      );
    case ChannelSourceKind.whatsapp:
      return const ChannelSourceLook(
        kind: ChannelSourceKind.whatsapp,
        icon: Icons.chat_rounded,
        brand: Color(0xFF25D366),
        style: ChannelBadgeStyle.solid,
      );
    case ChannelSourceKind.phone:
      // Телефон — монохром. На тёмном фоне светлый кружок.
      return const ChannelSourceLook(
        kind: ChannelSourceKind.phone,
        icon: Icons.phone_rounded,
        brand: Color(0xFF0EA5E9),
        style: ChannelBadgeStyle.adaptive,
      );
    case ChannelSourceKind.email:
      return const ChannelSourceLook(
        kind: ChannelSourceKind.email,
        icon: Icons.mail_rounded,
        brand: Color(0xFFF97316),
        style: ChannelBadgeStyle.soft,
      );
    case ChannelSourceKind.instagram:
      return const ChannelSourceLook(
        kind: ChannelSourceKind.instagram,
        icon: Icons.camera_alt_rounded,
        brand: Color(0xFFE1306C),
        style: ChannelBadgeStyle.gradient,
        gradient: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
      );
    case ChannelSourceKind.youtube:
      return const ChannelSourceLook(
        kind: ChannelSourceKind.youtube,
        icon: Icons.smart_display_rounded,
        brand: Color(0xFFFF0000),
        style: ChannelBadgeStyle.solid,
      );
    case ChannelSourceKind.messenger:
      return const ChannelSourceLook(
        kind: ChannelSourceKind.messenger,
        icon: Icons.messenger_rounded,
        brand: Color(0xFF0084FF),
        style: ChannelBadgeStyle.gradient,
        gradient: [Color(0xFF00C6FF), Color(0xFF0078FF), Color(0xFFA033FF)],
      );
    case ChannelSourceKind.facebook:
      return const ChannelSourceLook(
        kind: ChannelSourceKind.facebook,
        icon: Icons.facebook_rounded,
        brand: Color(0xFF1877F2),
        style: ChannelBadgeStyle.solid,
      );
    case ChannelSourceKind.site:
      return const ChannelSourceLook(
        kind: ChannelSourceKind.site,
        icon: Icons.language_rounded,
        brand: Color(0xFF64748B),
        style: ChannelBadgeStyle.soft,
      );
    case ChannelSourceKind.unknown:
      return const ChannelSourceLook(
        kind: ChannelSourceKind.unknown,
        icon: Icons.chat_bubble_outline_rounded,
        brand: Color(0xFF64748B),
        style: ChannelBadgeStyle.adaptive,
      );
  }
}

/// Цвет канала для рамки карточки и акцента.
Color channelBrandColor(String? rawName) {
  return lookForChannel(resolveChannelSourceKind(rawName)).brand;
}
