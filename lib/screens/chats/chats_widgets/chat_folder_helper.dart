class ChatFolderHelper {
  static const List<Map<String, String>> presetIcons = [
    {'id': 'fire', 'emoji': '🔥', 'label': 'Огонь'},
    {'id': 'star', 'emoji': '⭐', 'label': 'Звезда'},
    {'id': 'work', 'emoji': '💼', 'label': 'Работа'},
    {'id': 'flash', 'emoji': '⚡', 'label': 'Срочно'},
    {'id': 'target', 'emoji': '🎯', 'label': 'Цель'},
    {'id': 'rocket', 'emoji': '🚀', 'label': 'Ракета'},
    {'id': 'chat', 'emoji': '💬', 'label': 'Чат'},
    {'id': 'users', 'emoji': '👥', 'label': 'Клиенты'},
    {'id': 'pin', 'emoji': '📌', 'label': 'Важно'},
    {'id': 'heart', 'emoji': '❤️', 'label': 'Любимые'},
    {'id': 'bell', 'emoji': '🔔', 'label': 'Звонки'},
    {'id': 'money', 'emoji': '💰', 'label': 'Сделки'},
    {'id': 'package', 'emoji': '📦', 'label': 'Заказы'},
    {'id': 'check', 'emoji': '✅', 'label': 'Готово'},
  ];

  static String resolveIcon(String? iconId) {
    if (iconId == null || iconId.trim().isEmpty) return '';
    final trimmed = iconId.trim();

    // If it's already an emoji (contains non-ascii or emoji characters), return it
    for (final preset in presetIcons) {
      if (preset['id'] == trimmed.toLowerCase()) {
        return preset['emoji']!;
      }
      if (preset['emoji'] == trimmed) {
        return preset['emoji']!;
      }
    }

    // If string itself is 1-2 chars and contains unicode symbols
    if (trimmed.runes.length <= 2 && trimmed.codeUnits.any((c) => c > 127)) {
      return trimmed;
    }

    return '';
  }
}
