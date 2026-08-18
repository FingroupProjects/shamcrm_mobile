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

  void syncWithContext(
    BuildContext context, {
    required VoidCallback onChanged,
  }) {
    final controller = AppThemeController.instance;
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasCustomBackground = _hasCustomBackground(controller);
    final paletteKey = [
      controller.backgroundPreset.storageKey,
      controller.backgroundImagePath ?? '',
      controller.backgroundAssetPath ?? '',
      controller.backgroundBlurPercent.toStringAsFixed(1),
      controller.backgroundOpacityPercent.toStringAsFixed(1),
      controller.carouselIndex.toString(),
      isDark,
      size.width.round(),
      size.height.round(),
    ].join('|');

    if (_paletteKey == paletteKey) return;
    _paletteKey = paletteKey;
    // For photo wallpapers do not inherit the app theme luminance: a dark theme
    // + bright snow image was forcing white text on a light background.
    palette = PinAdaptivePalette.fallback(
      isDark: isDark && !hasCustomBackground,
      backgroundLuminance: hasCustomBackground
          ? 0.55
          : context.appColors.backgroundPrimary.computeLuminance(),
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

  bool _hasCustomBackground(AppThemeController controller) {
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

    final imagePath = controller.backgroundImagePath;
    final assetPath = controller.backgroundAssetPath;
    const photoFallbackLuminance = 0.55;

    try {
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
        return;
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

      if (_paletteKey != paletteKey) return;
      debugPrint(
        'PinAdaptiveContrast -> header=${sample.header.toStringAsFixed(3)}, '
        'keypad=${sample.keypad.toStringAsFixed(3)}, '
        'bottom=${sample.bottom.toStringAsFixed(3)}',
      );
      palette = PinAdaptivePalette(
        headerLuminance: sample.header,
        keypadLuminance: sample.keypad,
        bottomLuminance: sample.bottom,
      );
      onChanged();
    } catch (error) {
      debugPrint('PinAdaptiveContrast: palette skipped: $error');
    }
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
