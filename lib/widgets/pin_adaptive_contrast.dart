import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:crm_task_manager/core/theme/app_theme_controller.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinBackgroundLuminance {
  final double header;
  final double keypad;
  final double bottom;

  const PinBackgroundLuminance({
    required this.header,
    required this.keypad,
    required this.bottom,
  });
}

class PinAdaptivePalette {
  final double headerLuminance;
  final double keypadLuminance;
  final double bottomLuminance;

  const PinAdaptivePalette({
    required this.headerLuminance,
    required this.keypadLuminance,
    required this.bottomLuminance,
  });

  factory PinAdaptivePalette.fallback({
    required bool isDark,
    required double backgroundLuminance,
  }) {
    final luminance = backgroundLuminance.isFinite
        ? backgroundLuminance.clamp(0.0, 1.0)
        : (isDark ? 0.08 : 0.94);
    return PinAdaptivePalette(
      headerLuminance: luminance,
      keypadLuminance: luminance,
      bottomLuminance: luminance,
    );
  }

  // Midpoint closer to WCAG perceptual middle so pale snow/sky gets dark ink.
  bool isDarkBackground(double luminance) => luminance < 0.48;

  Color foregroundFor(double luminance) {
    return isDarkBackground(luminance) ? Colors.white : const Color(0xFF0B2F44);
  }

  Color secondaryFor(double luminance) {
    return isDarkBackground(luminance)
        ? Colors.white.withValues(alpha: 0.90)
        : const Color(0xFF123F57);
  }

  Color accentFor(double luminance) {
    return isDarkBackground(luminance)
        ? const Color(0xFFC3F1FF)
        : const Color(0xFF00698F);
  }

  List<Shadow> shadowsFor(double luminance) {
    final onDark = isDarkBackground(luminance);
    if (onDark) {
      return [
        Shadow(
          color: Colors.black.withValues(alpha: 0.62),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];
    }
    return [
      Shadow(
        color: Colors.white.withValues(alpha: 0.96),
        blurRadius: 8,
        offset: const Offset(0, 1),
      ),
      Shadow(
        color: Colors.black.withValues(alpha: 0.18),
        blurRadius: 2,
        offset: const Offset(0, 0.5),
      ),
    ];
  }
}

/// Готовая палитра PIN, посчитанная до первого кадра.
/// Без неё экран сначала брал запасную яркость, и кнопки меняли цвет.
class PinAdaptiveContrastCache {
  static String? _key;
  static PinAdaptivePalette? _palette;

  static String? get savedKey => _key;

  static String buildKey({
    required AppThemeController controller,
    required bool isDark,
    required Size screenSize,
  }) {
    return [
      controller.backgroundPreset.storageKey,
      controller.backgroundImagePath ?? '',
      controller.backgroundAssetPath ?? '',
      controller.backgroundBlurPercent.toStringAsFixed(1),
      controller.backgroundOpacityPercent.toStringAsFixed(1),
      controller.carouselIndex.toString(),
      isDark,
      screenSize.width.round(),
      screenSize.height.round(),
    ].join('|');
  }

  static void save(String key, PinAdaptivePalette palette) {
    _key = key;
    _palette = palette;
  }

  /// Точное совпадение или тот же фон при почти том же размере экрана.
  static PinAdaptivePalette? lookup(String key) {
    final cachedKey = _key;
    final cached = _palette;
    if (cachedKey == null || cached == null) return null;
    if (cachedKey == key || pinContrastKeysMatch(cachedKey, key)) {
      return cached;
    }
    return null;
  }

  /// Тот же фон, даже если экран повернули.
  /// Цвет кнопок не сбрасывается в заглушку, пока новый замер не готов.
  static PinAdaptivePalette? lookupSameWallpaper(String key) {
    final cachedKey = _key;
    final cached = _palette;
    if (cachedKey == null || cached == null) return null;
    if (pinContrastKeysMatch(cachedKey, key, maxSizeDelta: -1)) {
      return cached;
    }
    return null;
  }

  @visibleForTesting
  static void debugReset() {
    _key = null;
    _palette = null;
  }
}

/// Два ключа описывают один и тот же фон.
/// [maxSizeDelta] < 0 игнорирует ширину и высоту.
bool pinContrastKeysMatch(
  String cached,
  String next, {
  int maxSizeDelta = 24,
}) {
  if (cached == next) return true;
  final a = cached.split('|');
  final b = next.split('|');
  if (a.length < 3 || a.length != b.length) return false;
  for (var i = 0; i < a.length - 2; i++) {
    if (a[i] != b[i]) return false;
  }
  if (maxSizeDelta < 0) return true;
  final widthDelta = (int.tryParse(a[a.length - 2]) ?? 0) -
      (int.tryParse(b[b.length - 2]) ?? 0);
  final heightDelta = (int.tryParse(a.last) ?? 0) - (int.tryParse(b.last) ?? 0);
  return widthDelta.abs() <= maxSizeDelta && heightDelta.abs() <= maxSizeDelta;
}

/// Samples wallpaper luminance and exposes ink colors that stay readable
/// on both light and dark backgrounds.
///
/// Used by PIN screens and telephony (dialer, call UI, nav) over custom
/// wallpapers / glass surfaces.
class PinAdaptiveContrastController {
  PinAdaptivePalette? palette;
  String? _paletteKey;

  PinAdaptivePalette resolve(
    BuildContext context, {
    bool isDark = false,
  }) {
    return palette ??
        PinAdaptivePalette.fallback(
          isDark: isDark,
          backgroundLuminance:
              context.appColors.backgroundPrimary.computeLuminance(),
        );
  }

  /// Считает палитру фото до первого кадра PIN.
  /// Экран тогда сразу рисует кнопки своим цветом, без тёмной заглушки.
  static Future<void> warm(AppThemeController controller) async {
    try {
      if (!_hasCustomBackground(controller)) return;
      final key = PinAdaptiveContrastCache.buildKey(
        controller: controller,
        isDark: _startupIsDark(controller),
        screenSize: _startupScreenSize(),
      );
      if (PinAdaptiveContrastCache.lookup(key) != null) return;
      final palette = await _readCustomPalette(
        controller: controller,
        screenSize: _startupScreenSize(),
      );
      if (palette == null) return;
      PinAdaptiveContrastCache.save(key, palette);
    } catch (error) {
      debugPrint('PinAdaptiveContrast warm skipped: $error');
    }
  }

  static bool _startupIsDark(AppThemeController controller) {
    switch (controller.themeMode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    }
  }

  static Size _startupScreenSize() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return const Size(390, 844);
    final view = views.first;
    final ratio = view.devicePixelRatio;
    if (ratio == 0) return const Size(390, 844);
    return view.physicalSize / ratio;
  }

  void syncWithContext(
    BuildContext context, {
    required VoidCallback onChanged,
  }) {
    final controller = AppThemeController.instance;
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasCustomBackground = _hasCustomBackground(controller);
    final paletteKey = PinAdaptiveContrastCache.buildKey(
      controller: controller,
      isDark: isDark,
      screenSize: size,
    );

    // Даже если размер экрана чуть отличается от замера при старте,
    // берём уже посчитанный цвет. Иначе кнопки мигают заглушкой.
    final cached = PinAdaptiveContrastCache.lookupSameWallpaper(paletteKey);
    if (cached != null) {
      final alreadyApplied = _paletteKey == paletteKey && palette != null;
      _paletteKey = paletteKey;
      palette = cached;
      final savedKey = PinAdaptiveContrastCache.savedKey;
      final sizeIsClose = savedKey != null &&
          pinContrastKeysMatch(savedKey, paletteKey, maxSizeDelta: 80);
      if (!sizeIsClose && !alreadyApplied) {
        unawaited(
          _loadAdaptivePalette(
            paletteKey: paletteKey,
            controller: controller,
            screenSize: size,
            onChanged: onChanged,
          ),
        );
      }
      return;
    }

    if (_paletteKey == paletteKey) return;
    _paletteKey = paletteKey;

    if (!hasCustomBackground) {
      palette = PinAdaptivePalette.fallback(
        isDark: isDark,
        backgroundLuminance:
            context.appColors.backgroundPrimary.computeLuminance(),
      );
      PinAdaptiveContrastCache.save(paletteKey, palette!);
      return;
    }

    // Фото ещё не замерено. Не подменяем его тёмной темой:
    // заглушка 0.55 перекрашивала кнопки сразу после входа.
    palette ??= PinAdaptivePalette.fallback(
      isDark: false,
      backgroundLuminance: 0.55,
    );
    unawaited(
      _loadAdaptivePalette(
        paletteKey: paletteKey,
        controller: controller,
        screenSize: size,
        onChanged: onChanged,
      ),
    );
  }

  static bool _hasCustomBackground(AppThemeController controller) {
    if (controller.backgroundPreset != AppBackgroundPreset.custom) {
      return false;
    }
    final imagePath = controller.backgroundImagePath;
    final assetPath = controller.backgroundAssetPath;
    return (imagePath != null && imagePath.isNotEmpty) ||
        (assetPath != null && assetPath.isNotEmpty);
  }

  Future<void> _loadAdaptivePalette({
    required String paletteKey,
    required AppThemeController controller,
    required Size screenSize,
    required VoidCallback onChanged,
  }) async {
    if (!_hasCustomBackground(controller)) return;

    try {
      final next = await _readCustomPalette(
        controller: controller,
        screenSize: screenSize,
      );
      if (next == null || _paletteKey != paletteKey) return;
      final previous = palette;
      palette = next;
      PinAdaptiveContrastCache.save(paletteKey, next);
      // Тот же светлый/тёмный стиль не требует перерисовки:
      // иначе кнопки мигают без видимой причины.
      if (previous != null && _sameInk(previous, next)) return;
      onChanged();
    } catch (error) {
      debugPrint('PinAdaptiveContrast: palette skipped: $error');
    }
  }

  static bool _sameInk(PinAdaptivePalette previous, PinAdaptivePalette next) {
    return previous.isDarkBackground(previous.headerLuminance) ==
            next.isDarkBackground(next.headerLuminance) &&
        previous.isDarkBackground(previous.keypadLuminance) ==
            next.isDarkBackground(next.keypadLuminance) &&
        previous.isDarkBackground(previous.bottomLuminance) ==
            next.isDarkBackground(next.bottomLuminance);
  }

  static Future<PinAdaptivePalette?> _readCustomPalette({
    required AppThemeController controller,
    required Size screenSize,
  }) async {
    if (!_hasCustomBackground(controller)) return null;

    final imagePath = controller.backgroundImagePath;
    final assetPath = controller.backgroundAssetPath;
    const photoFallbackLuminance = 0.55;

    final bytes = imagePath != null && imagePath.isNotEmpty
        ? await File(imagePath).readAsBytes()
        : (await rootBundle.load(assetPath!)).buffer.asUint8List();
    final codec = await instantiateImageCodec(bytes, targetWidth: 180);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final byteData = await image.toByteData(format: ImageByteFormat.rawRgba);
    if (byteData == null) {
      image.dispose();
      codec.dispose();
      return null;
    }

    final sample = sampleBackgroundLuminance(
      bytes: byteData,
      imageWidth: image.width,
      imageHeight: image.height,
      screenSize: screenSize,
      fallbackLuminance: photoFallbackLuminance,
    );
    image.dispose();
    codec.dispose();

    debugPrint(
      'PinAdaptiveContrast -> header=${sample.header.toStringAsFixed(3)}, '
      'keypad=${sample.keypad.toStringAsFixed(3)}, '
      'bottom=${sample.bottom.toStringAsFixed(3)}',
    );
    return PinAdaptivePalette(
      headerLuminance: sample.header,
      keypadLuminance: sample.keypad,
      bottomLuminance: sample.bottom,
    );
  }

  @visibleForTesting
  static PinBackgroundLuminance sampleBackgroundLuminance({
    required ByteData bytes,
    required int imageWidth,
    required int imageHeight,
    required Size screenSize,
    required double fallbackLuminance,
  }) {
    final imageAspect = imageWidth / imageHeight;
    final screenAspect = screenSize.width / screenSize.height;

    var cropLeft = 0.0;
    var cropTop = 0.0;
    var visibleWidth = imageWidth.toDouble();
    var visibleHeight = imageHeight.toDouble();

    if (imageAspect > screenAspect) {
      visibleWidth = imageHeight * screenAspect;
      cropLeft = (imageWidth - visibleWidth) / 2;
    } else {
      visibleHeight = imageWidth / screenAspect;
      cropTop = (imageHeight - visibleHeight) / 2;
    }

    double sampleRegion(double top, double bottom) {
      final samples = <double>[];

      for (var yIndex = 0; yIndex < 12; yIndex++) {
        final screenY = top + (bottom - top) * ((yIndex + 0.5) / 12);
        final imageY = (cropTop + visibleHeight * screenY)
            .round()
            .clamp(0, imageHeight - 1);

        for (var xIndex = 0; xIndex < 12; xIndex++) {
          final screenX = 0.10 + 0.80 * ((xIndex + 0.5) / 12);
          final imageX = (cropLeft + visibleWidth * screenX)
              .round()
              .clamp(0, imageWidth - 1);
          final offset = (imageY * imageWidth + imageX) * 4;
          final red = bytes.getUint8(offset);
          final green = bytes.getUint8(offset + 1);
          final blue = bytes.getUint8(offset + 2);
          final alpha = bytes.getUint8(offset + 3) / 255;
          final pixelLuminance = relativeLuminance(red, green, blue);
          samples.add(pixelLuminance * alpha + fallbackLuminance * (1 - alpha));
        }
      }

      samples.sort();
      final average =
          samples.reduce((sum, value) => sum + value) / samples.length;
      final brightPercentile = samples[(samples.length * 0.72).floor()];
      final darkPercentile = samples[(samples.length * 0.28).floor()];
      final biased = (brightPercentile * 0.55) +
          (average * 0.30) +
          (darkPercentile * 0.15);
      return biased.clamp(0.0, 1.0);
    }

    return PinBackgroundLuminance(
      header: sampleRegion(0.10, 0.36),
      keypad: sampleRegion(0.38, 0.82),
      bottom: sampleRegion(0.80, 0.96),
    );
  }

  @visibleForTesting
  static double relativeLuminance(int red, int green, int blue) {
    double linearize(int channel) {
      final value = channel / 255;
      return value <= 0.04045
          ? value / 12.92
          : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * linearize(red) +
        0.7152 * linearize(green) +
        0.0722 * linearize(blue);
  }
}

/// Provides a sampled wallpaper palette to descendants (settings labels, etc.).
class WallpaperAdaptiveScope extends InheritedWidget {
  final PinAdaptivePalette palette;

  const WallpaperAdaptiveScope({
    super.key,
    required this.palette,
    required super.child,
  });

  static PinAdaptivePalette? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<WallpaperAdaptiveScope>()
        ?.palette;
  }

  static PinAdaptivePalette of(BuildContext context) {
    final scoped = maybeOf(context);
    if (scoped != null) return scoped;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PinAdaptivePalette.fallback(
      isDark: isDark,
      backgroundLuminance:
          context.appColors.backgroundPrimary.computeLuminance(),
    );
  }

  @override
  bool updateShouldNotify(WallpaperAdaptiveScope oldWidget) {
    return oldWidget.palette.headerLuminance != palette.headerLuminance ||
        oldWidget.palette.keypadLuminance != palette.keypadLuminance ||
        oldWidget.palette.bottomLuminance != palette.bottomLuminance;
  }
}

extension WallpaperAdaptiveInk on BuildContext {
  /// Ink for free-floating text/icons sitting on the wallpaper (not on cards).
  Color wallpaperForeground({double? luminance}) {
    final palette = WallpaperAdaptiveScope.of(this);
    return palette.foregroundFor(luminance ?? palette.keypadLuminance);
  }

  Color wallpaperSecondary({double? luminance}) {
    final palette = WallpaperAdaptiveScope.of(this);
    return palette.secondaryFor(luminance ?? palette.keypadLuminance);
  }

  Color wallpaperAccent({double? luminance}) {
    final palette = WallpaperAdaptiveScope.of(this);
    return palette.accentFor(luminance ?? palette.bottomLuminance);
  }

  List<Shadow> wallpaperShadows({double? luminance}) {
    final palette = WallpaperAdaptiveScope.of(this);
    return palette.shadowsFor(luminance ?? palette.keypadLuminance);
  }
}
