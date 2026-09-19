import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';

/// Матрица инверсии цвета.
/// Чёрный кружок становится белым. Белый глиф становится тёмным.
const ColorFilter kInvertIconFilter = ColorFilter.matrix(<double>[
  -1, 0, 0, 0, 255,
  0, -1, 0, 0, 255,
  0, 0, -1, 0, 255,
  0, 0, 0, 1, 0,
]);

/// PNG-иконка под светлый и тёмный фон.
/// Светлая карточка — тёмная иконка. Тёмная карточка — светлая иконка.
class ThemedAssetIcon extends StatelessWidget {
  const ThemedAssetIcon({
    super.key,
    required this.assetPath,
    this.darkAssetPath,
    this.size = 18,
    this.color,
    this.background,
    this.invertOnDark = false,
  });

  final String assetPath;

  /// Отдельный файл для тёмного фона. Пример: email_dark.png.
  final String? darkAssetPath;
  final double size;
  final Color? color;

  /// Фон, от которого считаем контраст. Обычно цвет карточки.
  final Color? background;

  /// Для чёрных кружков (телефон, почта).
  /// На тёмном фоне картинку инвертируем.
  final bool invertOnDark;

  @override
  Widget build(BuildContext context) {
    final surface = background ?? context.appColors.surfacePrimary;
    final needsLightIcon = context.useLightForeground(surface);
    final tint = color ?? context.adaptiveForegroundOn(surface);

    // Если есть пара файлов — просто меняем asset.
    if (darkAssetPath != null) {
      return Image.asset(
        needsLightIcon ? darkAssetPath! : assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.circle_outlined,
          size: size,
          color: tint,
        ),
      );
    }

    final image = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.circle_outlined,
        size: size,
        color: tint,
      ),
    );

    // Чёрный кружок на тёмной карточке почти не видно.
    // Инверсия делает его светлым и читаемым.
    if (invertOnDark && needsLightIcon) {
      return ColorFiltered(
        colorFilter: kInvertIconFilter,
        child: image,
      );
    }

    // Одноцветный глиф красим в цвет темы.
    return ColorFiltered(
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      child: image,
    );
  }
}

/// Календарь на карточках и в полях даты.
/// Цвет сам становится светлым или тёмным, как текст рядом.
class ThemedDateIcon extends StatelessWidget {
  const ThemedDateIcon({
    super.key,
    this.size = 18,
    this.color,
    this.background,
  });

  final double size;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final surface = background ?? context.appColors.surfacePrimary;
    // Если цвет не задали — берём адаптивный, как у остального текста.
    final iconColor = color ?? context.adaptiveForegroundOn(surface);
    return Icon(
      Icons.calendar_month_rounded,
      size: size,
      color: iconColor,
    );
  }
}
