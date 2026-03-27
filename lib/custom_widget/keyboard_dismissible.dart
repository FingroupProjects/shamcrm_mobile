import 'package:flutter/material.dart';

/// Обёртка для автоматического закрытия клавиатуры при тапе вне полей ввода
class KeyboardDismissible extends StatelessWidget {
  final Widget child;

  const KeyboardDismissible({
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Убираем фокус с текущего поля, что закрывает клавиатуру
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          currentFocus.unfocus();
        }
      },
      // Не перехватывать событие, если тап был на интерактивном элементе
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}