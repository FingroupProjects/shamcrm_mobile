import 'dart:io';
import 'dart:ui';

import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';

enum ChatAppearancePreset { classic, system, custom }

enum ChatBubbleStyle { classic, telegram, soft, compact, rounded, glass }

enum ChatWallpaperStyle { none, aurora, ocean, sunset, forest, gallery }

class ChatAppearanceData {
  static const String storageKey = 'chat_appearance_v1';

  final ChatAppearancePreset preset;
  final ChatBubbleStyle bubbleStyle;
  final ChatWallpaperStyle wallpaperStyle;
  final double bubbleOpacity;
  final double backgroundOpacity;
  final double chromeOpacity;
  final double fontScale;
  final int fontWeightLevel;
  final Color? customSenderBubbleColor;
  final Color? customReceiverBubbleColor;
  // Путь к фото из галереи (null если не выбрано)
  final String? customBackgroundImagePath;
  final String? customBackgroundAssetPath;

  const ChatAppearanceData({
    required this.preset,
    required this.bubbleStyle,
    required this.wallpaperStyle,
    required this.bubbleOpacity,
    required this.backgroundOpacity,
    required this.chromeOpacity,
    required this.fontScale,
    required this.fontWeightLevel,
    this.customSenderBubbleColor,
    this.customReceiverBubbleColor,
    this.customBackgroundImagePath,
    this.customBackgroundAssetPath,
  });

  factory ChatAppearanceData.defaults() {
    return const ChatAppearanceData(
      preset: ChatAppearancePreset.classic,
      bubbleStyle: ChatBubbleStyle.classic,
      wallpaperStyle: ChatWallpaperStyle.none,
      bubbleOpacity: 0.96,
      backgroundOpacity: 0.82,
      chromeOpacity: 0.62,
      fontScale: 1.0,
      fontWeightLevel: 1,
      customSenderBubbleColor: null,
      customReceiverBubbleColor: null,
      customBackgroundImagePath: null,
      customBackgroundAssetPath: null,
    );
  }

  factory ChatAppearanceData.fromJson(Map<String, dynamic> json) {
    final d = ChatAppearanceData.defaults();
    return ChatAppearanceData(
      preset: _readPreset(json['preset'] as String?) ?? d.preset,
      bubbleStyle:
          _readBubbleStyle(json['bubbleStyle'] as String?) ?? d.bubbleStyle,
      wallpaperStyle: _readWallpaperStyle(json['wallpaperStyle'] as String?) ??
          d.wallpaperStyle,
      bubbleOpacity:
          (json['bubbleOpacity'] as num?)?.toDouble() ?? d.bubbleOpacity,
      backgroundOpacity: (json['backgroundOpacity'] as num?)?.toDouble() ??
          d.backgroundOpacity,
      chromeOpacity:
          (json['chromeOpacity'] as num?)?.toDouble() ?? d.chromeOpacity,
      fontScale: (json['fontScale'] as num?)?.toDouble() ?? d.fontScale,
      fontWeightLevel:
          (json['fontWeightLevel'] as num?)?.toInt() ?? d.fontWeightLevel,
      customSenderBubbleColor: json['customSenderBubbleColor'] != null
          ? Color(json['customSenderBubbleColor'] as int)
          : null,
      customReceiverBubbleColor: json['customReceiverBubbleColor'] != null
          ? Color(json['customReceiverBubbleColor'] as int)
          : null,
      customBackgroundImagePath: (json['customBackgroundImagePath'] ??
          json['customWallpaperPath']) as String?,
      customBackgroundAssetPath: json['customBackgroundAssetPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    String enumName(Object value) => value.toString().split('.').last;
    return {
      'preset': enumName(preset),
      'bubbleStyle': enumName(bubbleStyle),
      'wallpaperStyle': enumName(wallpaperStyle),
      'bubbleOpacity': bubbleOpacity,
      'backgroundOpacity': backgroundOpacity,
      'chromeOpacity': chromeOpacity,
      'fontScale': fontScale,
      'fontWeightLevel': fontWeightLevel,
      if (customSenderBubbleColor != null)
        'customSenderBubbleColor': customSenderBubbleColor!.toARGB32(),
      if (customReceiverBubbleColor != null)
        'customReceiverBubbleColor': customReceiverBubbleColor!.toARGB32(),
      if (customBackgroundImagePath != null)
        'customBackgroundImagePath': customBackgroundImagePath,
      if (customBackgroundAssetPath != null)
        'customBackgroundAssetPath': customBackgroundAssetPath,
    };
  }

  ChatAppearanceData copyWith({
    ChatAppearancePreset? preset,
    ChatBubbleStyle? bubbleStyle,
    ChatWallpaperStyle? wallpaperStyle,
    double? bubbleOpacity,
    double? backgroundOpacity,
    double? chromeOpacity,
    double? fontScale,
    int? fontWeightLevel,
    Color? customSenderBubbleColor,
    Color? customReceiverBubbleColor,
    String? customBackgroundImagePath,
    String? customBackgroundAssetPath,
    bool clearCustomSenderBubbleColor = false,
    bool clearCustomReceiverBubbleColor = false,
    bool clearCustomBackgroundImagePath = false,
  }) {
    return ChatAppearanceData(
      preset: preset ?? this.preset,
      bubbleStyle: bubbleStyle ?? this.bubbleStyle,
      wallpaperStyle: wallpaperStyle ?? this.wallpaperStyle,
      bubbleOpacity: bubbleOpacity ?? this.bubbleOpacity,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      chromeOpacity: chromeOpacity ?? this.chromeOpacity,
      fontScale: fontScale ?? this.fontScale,
      fontWeightLevel: fontWeightLevel ?? this.fontWeightLevel,
      customSenderBubbleColor: clearCustomSenderBubbleColor
          ? null
          : (customSenderBubbleColor ?? this.customSenderBubbleColor),
      customReceiverBubbleColor: clearCustomReceiverBubbleColor
          ? null
          : (customReceiverBubbleColor ?? this.customReceiverBubbleColor),
      customBackgroundImagePath: clearCustomBackgroundImagePath
          ? null
          : (customBackgroundImagePath ?? this.customBackgroundImagePath),
      customBackgroundAssetPath: clearCustomBackgroundImagePath
          ? null
          : (customBackgroundAssetPath ?? this.customBackgroundAssetPath),
    );
  }

  FontWeight get messageFontWeight {
    switch (fontWeightLevel.clamp(0, 2)) {
      case 0:
        return FontWeight.w400;
      case 2:
        return FontWeight.w600;
      default:
        return FontWeight.w500;
    }
  }

  double scaledFont(double size) => size * fontScale;

  bool get usesWallpaper =>
      preset == ChatAppearancePreset.system ||
      (preset == ChatAppearancePreset.custom &&
          (wallpaperStyle != ChatWallpaperStyle.none));

  bool get hasGalleryWallpaper =>
      preset == ChatAppearancePreset.custom &&
      wallpaperStyle == ChatWallpaperStyle.gallery &&
      ((customBackgroundImagePath != null &&
              customBackgroundImagePath!.isNotEmpty) ||
          (customBackgroundAssetPath != null &&
              customBackgroundAssetPath!.isNotEmpty));

  ImageProvider? chromeImageProvider() {
    if (!hasGalleryWallpaper) {
      return null;
    }
    if (customBackgroundAssetPath != null &&
        customBackgroundAssetPath!.isNotEmpty) {
      return AssetImage(customBackgroundAssetPath!);
    }
    if (customBackgroundImagePath != null &&
        customBackgroundImagePath!.isNotEmpty) {
      return FileImage(File(customBackgroundImagePath!));
    }
    return null;
  }

  BorderRadius bubbleRadius(bool isSender) {
    switch (bubbleStyle) {
      case ChatBubbleStyle.telegram:
        return BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isSender ? 20 : 5),
          bottomRight: Radius.circular(isSender ? 5 : 20),
        );
      case ChatBubbleStyle.soft:
        return BorderRadius.circular(24);
      case ChatBubbleStyle.compact:
        return BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(isSender ? 14 : 6),
          bottomRight: Radius.circular(isSender ? 6 : 14),
        );
      case ChatBubbleStyle.rounded:
        return BorderRadius.circular(28);
      case ChatBubbleStyle.glass:
        return BorderRadius.circular(18);
      case ChatBubbleStyle.classic:
        return BorderRadius.circular(14);
    }
  }

  Color senderBubbleColor(BuildContext context) {
    final base =
        customSenderBubbleColor != null && preset == ChatAppearancePreset.custom
            ? customSenderBubbleColor!
            : switch (preset) {
                ChatAppearancePreset.classic =>
                  context.appColors.buttonPrimaryBg,
                ChatAppearancePreset.system => Color.alphaBlend(
                    context.appColors.buttonPrimaryBg.withValues(alpha: 0.32),
                    context.appColors.surfacePrimary.withValues(alpha: 0.68),
                  ),
                ChatAppearancePreset.custom => Color.alphaBlend(
                    context.appColors.buttonPrimaryBg.withValues(alpha: 0.38),
                    _wallpaperAccentColor(context),
                  ),
              };
    return base.withValues(alpha: bubbleOpacity.clamp(0.55, 1.0));
  }

  Color receiverBubbleColor(BuildContext context) {
    final base = customReceiverBubbleColor != null &&
            preset == ChatAppearancePreset.custom
        ? customReceiverBubbleColor!
        : switch (preset) {
            ChatAppearancePreset.classic => context.appColors.surfacePrimary,
            ChatAppearancePreset.system =>
              context.appColors.surfacePrimary.withValues(alpha: 0.78),
            ChatAppearancePreset.custom => Color.alphaBlend(
                context.appColors.surfacePrimary.withValues(alpha: 0.80),
                context.appColors.backgroundPrimary.withValues(alpha: 0.20),
              ),
          };
    return base.withValues(alpha: bubbleOpacity.clamp(0.58, 1.0));
  }

  Color inputSurfaceColor(BuildContext context) {
    return switch (preset) {
      ChatAppearancePreset.classic => context.appColors.backgroundPrimary,
      ChatAppearancePreset.system =>
        context.appColors.surfacePrimary.withValues(alpha: 0.72),
      ChatAppearancePreset.custom => Color.alphaBlend(
          context.appColors.surfacePrimary.withValues(alpha: 0.74),
          _wallpaperAccentColor(context).withValues(alpha: 0.18),
        ),
    };
  }

  Color chromeSurfaceColor(BuildContext context) {
    final baseSurface = inputSurfaceColor(context);
    final overlay = Theme.of(context).brightness == Brightness.dark
        ? context.appColors.textInverse.withValues(alpha: 0.06)
        : context.appColors.textInverse.withValues(alpha: 0.02);

    return Color.alphaBlend(
      overlay,
      baseSurface.withValues(alpha: 0.94),
    );
  }

  double chromeBlurSigma() {
    final normalized = (chromeOpacity / 0.95).clamp(0.0, 1.0);
    return normalized * 24;
  }

  Color accentColor(BuildContext context) {
    return switch (preset) {
      ChatAppearancePreset.classic => context.appColors.buttonPrimaryBg,
      ChatAppearancePreset.system => Color.alphaBlend(
          context.appColors.buttonPrimaryBg.withValues(alpha: 0.78),
          context.appColors.surfacePrimary,
        ),
      ChatAppearancePreset.custom => _wallpaperAccentColor(context),
    };
  }

  Color outgoingForeground(BuildContext context) =>
      _bubbleForegroundColor(senderBubbleColor(context));

  Color incomingForeground(BuildContext context) =>
      _bubbleForegroundColor(receiverBubbleColor(context));

  Color secondaryForeground(BuildContext context, bool isSender) {
    final bubble =
        isSender ? senderBubbleColor(context) : receiverBubbleColor(context);
    return _bubbleSecondaryForegroundColor(bubble);
  }

  Color senderNameColor(BuildContext context) {
    final base = context.appColors.textPrimary;
    return base.withValues(alpha: 0.92);
  }

  Color borderColor(BuildContext context, bool isSender) {
    final bubble =
        isSender ? senderBubbleColor(context) : receiverBubbleColor(context);
    return context.adaptiveBorderOn(bubble, lightAlpha: 0.18, darkAlpha: 0.52);
  }

  BoxDecoration buildScreenDecoration(BuildContext context) {
    if (preset == ChatAppearancePreset.classic) {
      return BoxDecoration(color: context.appColors.backgroundSecondary);
    }

    if (preset == ChatAppearancePreset.system) {
      return BoxDecoration(color: context.appColors.backgroundSecondary);
    }

    final gradient = _wallpaperGradient(context);
    return BoxDecoration(
      color: context.appColors.backgroundSecondary,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradient
            .map((c) => c.withValues(alpha: backgroundOpacity.clamp(0.45, 1.0)))
            .toList(),
      ),
    );
  }

  DecorationImage? buildGalleryWallpaperDecoration() {
    if (!hasGalleryWallpaper) return null;
    if (customBackgroundAssetPath != null &&
        customBackgroundAssetPath!.isNotEmpty) {
      return DecorationImage(
        image: AssetImage(customBackgroundAssetPath!),
        fit: BoxFit.cover,
        opacity: backgroundOpacity.clamp(0.45, 1.0),
      );
    }
    return DecorationImage(
      image: FileImage(File(customBackgroundImagePath!)),
      fit: BoxFit.cover,
      opacity: backgroundOpacity.clamp(0.45, 1.0),
    );
  }

  BoxDecoration buildFullScreenDecoration(BuildContext context) {
    return buildScreenDecoration(context);
  }

  Widget buildBackgroundLayer(BuildContext context) {
    if (!hasGalleryWallpaper) {
      return const SizedBox.shrink();
    }

    final image = chromeImageProvider();
    if (image == null) {
      return const SizedBox.shrink();
    }

    final blurSigma = chromeBlurSigma();
    final imageWidget = Image(
      image: image,
      fit: BoxFit.cover,
    );

    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: backgroundOpacity.clamp(0.45, 1.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (blurSigma > 0)
                ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: blurSigma,
                    sigmaY: blurSigma,
                  ),
                  child: imageWidget,
                )
              else
                imageWidget,
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.appColors.backgroundPrimary
                          .withValues(alpha: 0.18),
                      context.appColors.surfacePrimary.withValues(alpha: 0.10),
                      context.appColors.backgroundSecondary
                          .withValues(alpha: 0.24),
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

  List<Widget> buildBackgroundOrbs(BuildContext context) {
    if (!usesWallpaper ||
        hasGalleryWallpaper ||
        preset == ChatAppearancePreset.system) {
      return const [];
    }

    final accent = _wallpaperAccentColor(context);
    final primary = context.appColors.buttonPrimaryBg;

    // Для системного пресета используем цвета темы
    final orbColor = preset == ChatAppearancePreset.system ? primary : accent;

    return [
      Positioned(
        top: -60,
        left: -30,
        child: _BackgroundOrb(
          size: 240,
          color: orbColor.withValues(alpha: 0.22 * backgroundOpacity),
        ),
      ),
      Positioned(
        top: 160,
        right: -50,
        child: _BackgroundOrb(
          size: 200,
          color: (preset == ChatAppearancePreset.system
                  ? context.appColors.info
                  : context.appColors.info)
              .withValues(alpha: 0.14 * backgroundOpacity),
        ),
      ),
      Positioned(
        bottom: 100,
        left: 20,
        child: _BackgroundOrb(
          size: 180,
          color: (preset == ChatAppearancePreset.system
                  ? context.appColors.success
                  : context.appColors.success)
              .withValues(alpha: 0.12 * backgroundOpacity),
        ),
      ),
    ];
  }

  List<Color> _wallpaperGradient(BuildContext context) {
    switch (wallpaperStyle) {
      case ChatWallpaperStyle.none:
        return [
          context.appColors.backgroundSecondary,
          context.appColors.surfacePrimary.withValues(alpha: 0.96),
          context.appColors.backgroundPrimary,
        ];
      case ChatWallpaperStyle.aurora:
        return const [Color(0xFF0B1F3A), Color(0xFF18497A), Color(0xFF1F8A8A)];
      case ChatWallpaperStyle.ocean:
        return const [Color(0xFF091C33), Color(0xFF134E7A), Color(0xFF2A7FBF)];
      case ChatWallpaperStyle.sunset:
        return const [Color(0xFF26163A), Color(0xFF5A2E67), Color(0xFFD97852)];
      case ChatWallpaperStyle.forest:
        return const [Color(0xFF0D2222), Color(0xFF1A4B43), Color(0xFF5E8B4A)];
      case ChatWallpaperStyle.gallery:
        return [
          context.appColors.backgroundSecondary,
          context.appColors.backgroundPrimary,
        ];
    }
  }

  Color _wallpaperAccentColor(BuildContext context) {
    switch (wallpaperStyle) {
      case ChatWallpaperStyle.none:
        return context.appColors.buttonPrimaryBg;
      case ChatWallpaperStyle.aurora:
        return const Color(0xFF2DA7FF);
      case ChatWallpaperStyle.ocean:
        return const Color(0xFF35B9FF);
      case ChatWallpaperStyle.sunset:
        return const Color(0xFFFF9F68);
      case ChatWallpaperStyle.forest:
        return const Color(0xFF4FD39B);
      case ChatWallpaperStyle.gallery:
        return context.appColors.buttonPrimaryBg;
    }
  }

  Color _bubbleForegroundColor(Color bubbleColor) {
    final opaqueColor = bubbleColor.withValues(alpha: 1);
    final useLightText = opaqueColor.computeLuminance() < 0.45;
    return useLightText ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  }

  Color _bubbleSecondaryForegroundColor(Color bubbleColor) {
    final opaqueColor = bubbleColor.withValues(alpha: 1);
    final useLightText = opaqueColor.computeLuminance() < 0.45;
    return useLightText
        ? const Color(0xFFF8FAFC).withValues(alpha: 0.74)
        : const Color(0xFF0F172A).withValues(alpha: 0.62);
  }
}

class ChatAppearanceScope extends InheritedWidget {
  final ChatAppearanceData appearance;

  const ChatAppearanceScope({
    super.key,
    required this.appearance,
    required super.child,
  });

  static ChatAppearanceData of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ChatAppearanceScope>();
    return scope?.appearance ?? ChatAppearanceData.defaults();
  }

  @override
  bool updateShouldNotify(ChatAppearanceScope oldWidget) =>
      oldWidget.appearance != appearance;
}

class _BackgroundOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _BackgroundOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0.0)],
          ),
        ),
      ),
    );
  }
}

ChatAppearancePreset? _readPreset(String? raw) {
  switch (raw) {
    case 'classic':
      return ChatAppearancePreset.classic;
    case 'system':
      return ChatAppearancePreset.system;
    case 'custom':
      return ChatAppearancePreset.custom;
    default:
      return null;
  }
}

ChatBubbleStyle? _readBubbleStyle(String? raw) {
  switch (raw) {
    case 'classic':
      return ChatBubbleStyle.classic;
    case 'telegram':
    case 'modern':
      return ChatBubbleStyle.telegram;
    case 'soft':
      return ChatBubbleStyle.soft;
    case 'compact':
      return ChatBubbleStyle.compact;
    case 'rounded':
    case 'pill':
      return ChatBubbleStyle.rounded;
    case 'glass':
    case 'sharp':
      return ChatBubbleStyle.glass;
    default:
      return null;
  }
}

ChatWallpaperStyle? _readWallpaperStyle(String? raw) {
  switch (raw) {
    case 'none':
      return ChatWallpaperStyle.none;
    case 'aurora':
      return ChatWallpaperStyle.aurora;
    case 'ocean':
      return ChatWallpaperStyle.ocean;
    case 'sunset':
      return ChatWallpaperStyle.sunset;
    case 'forest':
      return ChatWallpaperStyle.forest;
    case 'gallery':
      return ChatWallpaperStyle.gallery;
    default:
      return null;
  }
}
