import 'dart:ui';
import 'dart:io';

import 'package:crm_task_manager/core/theme/app_theme_controller.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppBackgroundOverlay extends StatelessWidget {
  final AppBackgroundPreset preset;
  final String? imagePath;
  final String? assetPath;
  final double blurSigma;
  final bool followActiveTheme;
  final bool forceRender;

  const AppBackgroundOverlay({
    super.key,
    required this.preset,
    this.imagePath,
    this.assetPath,
    this.blurSigma = 54,
    this.followActiveTheme = true,
    this.forceRender = false,
  });

  @override
  Widget build(BuildContext context) {
    // AppBackgroundOverlay используется и глобально, и внутри отдельных
    // экранов. Не рисуем второй экземпляр поверх первого: именно он создавал
    // эффект тени/двойного изображения.
    if (!forceRender &&
        context.dependOnInheritedWidgetOfExactType<_AppBackgroundScope>() !=
            null) {
      return const SizedBox.shrink();
    }

    final themeController =
        followActiveTheme ? context.watch<AppThemeController>() : null;
    final resolvedPreset = themeController?.backgroundPreset ?? preset;
    final resolvedImagePath = themeController?.backgroundImagePath ?? imagePath;
    final resolvedAssetPath = themeController?.backgroundAssetPath ?? assetPath;
    final resolvedBlurSigma = themeController?.backgroundBlurSigma ?? blurSigma;
    final resolvedOpacity = themeController?.backgroundOpacity ?? 1.0;

    if (resolvedPreset == AppBackgroundPreset.none) {
      return const SizedBox.shrink();
    }

    if (resolvedPreset == AppBackgroundPreset.custom &&
        resolvedImagePath != null &&
        resolvedImagePath.isNotEmpty) {
      final file = File(resolvedImagePath);
      if (file.existsSync()) {
        return _AppBackgroundScope(
          child: IgnorePointer(
            child: _CustomWallpaperLayer(
              wallpaperKey: 'file:$resolvedImagePath',
              opacity: resolvedOpacity,
              blurSigma: resolvedBlurSigma,
              image: Image.file(
                file,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        );
      }
    }

    if (resolvedPreset == AppBackgroundPreset.custom &&
        resolvedAssetPath != null &&
        resolvedAssetPath.isNotEmpty) {
      return _AppBackgroundScope(
        child: IgnorePointer(
          child: _CustomWallpaperLayer(
            wallpaperKey: 'asset:$resolvedAssetPath',
            opacity: resolvedOpacity,
            blurSigma: resolvedBlurSigma,
            image: Image.asset(
              resolvedAssetPath,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      );
    }

    return _AppBackgroundScope(
      child: IgnorePointer(
        child: Opacity(
          opacity: resolvedPreset.opacity,
          child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: _baseGradient(context, resolvedPreset),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _glow(
                alignment: const Alignment(-0.85, -0.9),
                color: context.appColors.buttonPrimaryBg,
                size: 280,
              ),
              _glow(
                alignment: const Alignment(0.95, -0.55),
                color: context.appColors.surfaceAccent,
                size: 260,
              ),
              _glow(
                alignment: const Alignment(0.15, 0.95),
                color: context.appColors.info,
                size: 320,
              ),
              if (resolvedPreset == AppBackgroundPreset.mesh ||
                  resolvedPreset == AppBackgroundPreset.sunrise)
                _glow(
                  alignment: const Alignment(-0.2, 0.25),
                  color: context.appColors.warning,
                  size: 220,
                ),
              if (resolvedPreset == AppBackgroundPreset.paper)
                const _PaperPattern(),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Gradient _baseGradient(BuildContext context, AppBackgroundPreset preset) {
    switch (preset) {
      case AppBackgroundPreset.none:
        return const LinearGradient(
            colors: [Colors.transparent, Colors.transparent]);
      case AppBackgroundPreset.aurora:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.appColors.backgroundPrimary,
            context.appColors.backgroundSecondary.withValues(alpha: 0.9),
            context.appColors.surfacePrimary.withValues(alpha: 0.7),
          ],
        );
      case AppBackgroundPreset.mesh:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            context.appColors.backgroundSecondary,
            context.appColors.backgroundPrimary,
          ],
        );
      case AppBackgroundPreset.sunrise:
        return LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            context.appColors.backgroundPrimary,
            context.appColors.surfacePrimary.withValues(alpha: 0.85),
            context.appColors.backgroundSecondary.withValues(alpha: 0.95),
          ],
        );
      case AppBackgroundPreset.paper:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.appColors.backgroundPrimary,
            context.appColors.surfacePrimary,
          ],
        );
      case AppBackgroundPreset.custom:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.appColors.backgroundPrimary,
            context.appColors.backgroundSecondary,
          ],
        );
    }
  }

  Widget _glow({
    required Alignment alignment,
    required Color color,
    required double size,
  }) {
    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 54, sigmaY: 54),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.9),
                color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomWallpaperLayer extends StatelessWidget {
  final String wallpaperKey;
  final double opacity;
  final double blurSigma;
  final Image image;

  const _CustomWallpaperLayer({
    required this.wallpaperKey,
    required this.opacity,
    required this.blurSigma,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.1, 1.0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 700),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey(wallpaperKey),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (blurSigma > 0)
                ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: blurSigma,
                    sigmaY: blurSigma,
                  ),
                  child: SizedBox.expand(child: image),
                )
              else
                SizedBox.expand(child: image),
              if (blurSigma > 0)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.appColors.backgroundPrimary
                            .withValues(alpha: 0.16),
                        context.appColors.surfacePrimary
                            .withValues(alpha: 0.08),
                        context.appColors.backgroundSecondary
                            .withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBackgroundScope extends InheritedWidget {
  const _AppBackgroundScope({required super.child});

  @override
  bool updateShouldNotify(covariant _AppBackgroundScope oldWidget) => false;
}

class _PaperPattern extends StatelessWidget {
  const _PaperPattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PaperPatternPainter(
        lineColor: context.appColors.borderSubtle.withValues(alpha: 0.45),
      ),
    );
  }
}

class _PaperPatternPainter extends CustomPainter {
  final Color lineColor;

  const _PaperPatternPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    const gap = 28.0;
    for (double x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PaperPatternPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}
