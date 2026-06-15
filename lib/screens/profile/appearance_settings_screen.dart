import 'dart:io';
import 'dart:math' as math;

import 'package:crm_task_manager/core/theme/app_theme_controller.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/core/theme/palette/app_palette_presets.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('AppearanceSettingsScreen: initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('AppearanceSettingsScreen: first frame rendered');
    });
  }

  @override
  void dispose() {
    debugPrint('AppearanceSettingsScreen: dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppThemeController>();
    debugPrint(
      'AppearanceSettingsScreen: build mode=${controller.themeMode.name} palette=${controller.palettePreset.storageKey} background=${controller.backgroundPreset.storageKey}',
    );
    return Scaffold(
      backgroundColor: context.appColors.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'Оформление',
          style: context.appTextStyles.titleLg.copyWith(
            color: context.appColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        forceMaterialTransparency: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppBackgroundOverlay(preset: AppBackgroundPreset.aurora),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _SectionCard(
                title: 'Режим темы',
                subtitle:
                    'Выберите, как приложение будет выглядеть днем и вечером.',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ModeChip(
                      label: 'Светлая',
                      selected: controller.themeMode == ThemeMode.light,
                      onTap: () => controller.setThemeMode(ThemeMode.light),
                    ),
                    _ModeChip(
                      label: 'Темная',
                      selected: controller.themeMode == ThemeMode.dark,
                      onTap: () => controller.setThemeMode(ThemeMode.dark),
                    ),
                    _ModeChip(
                      label: 'Системная',
                      selected: controller.themeMode == ThemeMode.system,
                      onTap: () => controller.setThemeMode(ThemeMode.system),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Цветовой круг',
                subtitle:
                    'Выберите любой оттенок. Приложение соберет палитру автоматически.',
                child: _ColorWheelPalette(
                  controller: controller,
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Фоновый арт',
                subtitle:
                    'Легкий художественный слой поверх интерфейса. Видно мягко и без перегруза.',
                child: Column(
                  children: AppBackgroundPreset.values
                      .where((preset) => preset != AppBackgroundPreset.custom)
                      .map(
                        (preset) => _BackgroundTile(
                          preset: preset,
                          selected: controller.backgroundPreset == preset,
                          onTap: () => controller.setBackgroundPreset(preset),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Своя картинка',
                subtitle:
                    'Можно поставить свой фон для всего приложения. Он будет мягко наложен поверх интерфейса.',
                child: _CustomBackgroundCard(controller: controller),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Размытие фона',
                subtitle:
                    'Настройте, насколько сильно будет размываться активный фон.',
                child: _BackgroundBlurControl(controller: controller),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: controller.resetAppearance,
                style: FilledButton.styleFrom(
                  backgroundColor: context.appColors.buttonSecondaryBg,
                  foregroundColor: context.appColors.buttonSecondaryFg,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                ),
                child: Text(
                  'Сбросить оформление',
                  style: context.appTextStyles.bodyMd.copyWith(
                    color: context.appColors.buttonSecondaryFg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.surfacePrimary.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.appColors.borderSubtle.withValues(alpha: 0.42),
        ),
        boxShadow: context.appShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.appTextStyles.titleMd.copyWith(
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: context.appTextStyles.bodySm.copyWith(
              color: context.appColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: Duration.zero,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? context.appColors.buttonPrimaryBg
              : context.appColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? context.appColors.buttonPrimaryBg
                : context.appColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: context.appTextStyles.bodyMd.copyWith(
            color: selected
                ? context.appColors.buttonPrimaryFg
                : context.appColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _BackgroundTile extends StatelessWidget {
  final AppBackgroundPreset preset;
  final bool selected;
  final VoidCallback onTap;

  const _BackgroundTile({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: Duration.zero,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? context.appColors.surfaceAccent.withValues(alpha: 0.3)
                : context.appColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? context.appColors.buttonPrimaryBg
                  : context.appColors.borderSubtle,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 78,
                  height: 54,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: context.appColors.surfacePrimary),
                      _BackgroundPreview(preset: preset),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  preset.title,
                  style: context.appTextStyles.bodyLg.copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle,
                  color: context.appColors.buttonPrimaryBg,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackgroundPreview extends StatelessWidget {
  final AppBackgroundPreset preset;

  const _BackgroundPreview({required this.preset});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: _gradient(context),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _previewBlob(
            alignment: const Alignment(-0.85, -0.95),
            color: context.appColors.buttonPrimaryBg.withValues(alpha: 0.28),
            size: 34,
          ),
          _previewBlob(
            alignment: const Alignment(0.95, -0.35),
            color: context.appColors.surfaceAccent.withValues(alpha: 0.26),
            size: 30,
          ),
          _previewBlob(
            alignment: const Alignment(0.25, 0.95),
            color: context.appColors.info.withValues(alpha: 0.22),
            size: 38,
          ),
          if (preset == AppBackgroundPreset.paper)
            CustomPaint(
              painter: _PreviewLinesPainter(
                color: context.appColors.borderSubtle.withValues(alpha: 0.3),
              ),
            ),
        ],
      ),
    );
  }

  Gradient _gradient(BuildContext context) {
    switch (preset) {
      case AppBackgroundPreset.none:
        return const LinearGradient(
          colors: [Colors.transparent, Colors.transparent],
        );
      case AppBackgroundPreset.aurora:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.appColors.backgroundPrimary,
            context.appColors.backgroundSecondary,
            context.appColors.surfacePrimary,
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
            context.appColors.surfaceAccent.withValues(alpha: 0.45),
            context.appColors.backgroundSecondary,
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
            context.appColors.backgroundSecondary,
            context.appColors.surfaceAccent.withValues(alpha: 0.35),
          ],
        );
    }
  }

  Widget _previewBlob({
    required Alignment alignment,
    required Color color,
    required double size,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _PreviewLinesPainter extends CustomPainter {
  final Color color;

  const _PreviewLinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8;

    const gap = 10.0;
    for (double x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewLinesPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _CustomBackgroundCard extends StatelessWidget {
  final AppThemeController controller;

  static const List<String> _projectBackgrounds = <String>[
    'assets/fon/IMG_1614.JPG',
    'assets/fon/IMG_1615.JPG',
    'assets/fon/IMG_1617.JPG',
    'assets/fon/IMG_1616.JPG',
    'assets/fon/IMG_1606.JPG',
    'assets/fon/IMG_1612.JPG',
    'assets/fon/IMG_1613.JPG',
    'assets/fon/IMG_1607.JPG',
    'assets/fon/IMG_1611.JPG',
    'assets/fon/IMG_1610.JPG',
    'assets/fon/IMG_1609.JPG',
    'assets/fon/IMG_1580.JPG',
    'assets/fon/IMG_1581.JPG',
    'assets/fon/IMG_1608.JPG',
    'assets/fon/IMG_1620.JPG',
    'assets/fon/IMG_1583.JPG',
    'assets/fon/IMG_1582.JPG',
    'assets/fon/IMG_1579.JPG',
    'assets/fon/IMG_1578.JPG',
    'assets/fon/IMG_1618.JPG',
    'assets/fon/IMG_1584.JPG',
    'assets/fon/IMG_1619.JPG',
  ];

  const _CustomBackgroundCard({required this.controller});

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    if (!context.mounted) return;
    await controller.setCustomBackgroundImagePath(image.path);
  }

  Future<void> _setProjectBackground(String assetPath) async {
    await controller.setAssetBackgroundImagePath(assetPath);
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = controller.backgroundImagePath;
    final assetPath = controller.backgroundAssetPath;
    final hasImage = imagePath != null && imagePath.isNotEmpty;
    final hasAsset = assetPath != null && assetPath.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 164,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: context.appColors.surfacePrimary),
                if (hasImage)
                  Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      debugPrint(
                        'AppearanceSettingsScreen: failed to load custom background image',
                      );
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              context.appColors.backgroundSecondary,
                              context.appColors.surfaceAccent.withValues(
                                alpha: 0.55,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                else if (hasAsset)
                  Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              context.appColors.backgroundSecondary,
                              context.appColors.surfaceAccent.withValues(
                                alpha: 0.55,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          context.appColors.backgroundSecondary,
                          context.appColors.surfaceAccent
                              .withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        context.appColors.backgroundPrimary
                            .withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                ),
                if (!hasImage)
                  Center(
                    child: Text(
                      'Выберите изображение из альбома проекта или галереи',
                      style: context.appTextStyles.bodyMd.copyWith(
                        color: context.appColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton(
              onPressed: () => _pickImage(context),
              style: FilledButton.styleFrom(
                backgroundColor: context.appColors.buttonPrimaryBg,
                foregroundColor: context.appColors.buttonPrimaryFg,
              ),
              child: Text(hasImage ? 'Сменить картинку' : 'Выбрать картинку'),
            ),
            if (hasImage)
              OutlinedButton(
                onPressed: controller.clearCustomBackgroundImage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.appColors.textPrimary,
                  side: BorderSide(color: context.appColors.borderSubtle),
                ),
                child: const Text('Убрать'),
              ),
            if (hasImage)
              OutlinedButton(
                onPressed: () => controller.setBackgroundPreset(
                  AppBackgroundPreset.custom,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.appColors.textPrimary,
                  side: BorderSide(
                    color: controller.backgroundPreset ==
                            AppBackgroundPreset.custom
                        ? context.appColors.buttonPrimaryBg
                        : context.appColors.borderSubtle,
                  ),
                ),
                child: const Text('Использовать как фон'),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Альбом проекта',
          style: context.appTextStyles.titleMd.copyWith(
            color: context.appColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _projectBackgrounds.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (context, index) {
            final asset = _projectBackgrounds[index];
            final selected = hasAsset && assetPath == asset;
            return InkWell(
              onTap: () => _setProjectBackground(asset),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? context.appColors.buttonPrimaryBg
                        : context.appColors.borderSubtle,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        asset,
                        fit: BoxFit.cover,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      if (selected)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Icon(
                            Icons.check_circle,
                            color: context.appColors.buttonPrimaryBg,
                            size: 22,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ColorWheelPalette extends StatelessWidget {
  final AppThemeController controller;

  const _ColorWheelPalette({required this.controller});

  @override
  Widget build(BuildContext context) {
    final seedColor = controller.paletteSeedColor;
    final currentPreset = controller.palettePreset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: _ColorWheelPicker(
            color: seedColor,
            onChanged: controller.setPaletteSeedColor,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: seedColor,
                shape: BoxShape.circle,
                border: Border.all(color: context.appColors.borderPrimary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '#${seedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                style: context.appTextStyles.bodyMd.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              currentPreset.title,
              style: context.appTextStyles.bodySm.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Быстрые схемы',
          style: context.appTextStyles.bodySm.copyWith(
            color: context.appColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppPalettePreset.values
              .where((preset) => preset != AppPalettePreset.custom)
              .map(
                (preset) => ChoiceChip(
                  label: Text(preset.title),
                  selected: controller.palettePreset == preset,
                  onSelected: (_) => controller.setPalettePreset(preset),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _ColorWheelPicker extends StatefulWidget {
  final Color color;
  final ValueChanged<Color> onChanged;

  const _ColorWheelPicker({
    required this.color,
    required this.onChanged,
  });

  @override
  State<_ColorWheelPicker> createState() => _ColorWheelPickerState();
}

class _ColorWheelPickerState extends State<_ColorWheelPicker> {
  late Offset _pointer;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    final hsl = HSLColor.fromColor(widget.color);
    _pointer = _offsetFromHsl(hsl);
  }

  @override
  void didUpdateWidget(covariant _ColorWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && oldWidget.color != widget.color) {
      final hsl = HSLColor.fromColor(widget.color);
      _pointer = _offsetFromHsl(hsl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        _dragging = true;
        _updateFromLocalPosition(details.localPosition);
      },
      onPanUpdate: (details) => _updateFromLocalPosition(details.localPosition),
      onPanEnd: (_) => _dragging = false,
      onTapDown: (details) => _updateFromLocalPosition(details.localPosition),
      child: CustomPaint(
        size: const Size(280, 280),
        painter: _ColorWheelPainter(
          color: widget.color,
          pointer: _pointer,
        ),
      ),
    );
  }

  void _updateFromLocalPosition(Offset position) {
    const size = 280.0;
    final center = const Offset(size / 2, size / 2);
    final radius = size / 2;
    final delta = position - center;
    final distance = delta.distance.clamp(0.0, radius);
    final normalized = distance / radius;
    final angle = (math.atan2(delta.dy, delta.dx) + math.pi) / (2 * math.pi);
    final hue = (angle * 360) % 360;
    final saturation = normalized.clamp(0.0, 1.0);
    final color = HSLColor.fromAHSL(
      1,
      hue,
      saturation,
      0.55,
    ).toColor();
    setState(() {
      _pointer = center +
          Offset.fromDirection(math.atan2(delta.dy, delta.dx), distance);
    });
    widget.onChanged(color);
  }

  Offset _offsetFromHsl(HSLColor hsl) {
    const size = 280.0;
    final radius = size / 2;
    final angle = (hsl.hue / 360) * 2 * math.pi;
    final distance = hsl.saturation * radius;
    return Offset(
      radius + math.cos(angle - math.pi) * distance,
      radius + math.sin(angle - math.pi) * distance,
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  final Color color;
  final Offset pointer;

  _ColorWheelPainter({
    required this.color,
    required this.pointer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const steps = 360;
    for (int i = 0; i < steps; i++) {
      final sweep = 2 * math.pi / steps;
      final start = (i * sweep) - math.pi;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius
        ..shader = SweepGradient(
          colors: [
            HSLColor.fromAHSL(1, (i * 360 / steps), 1, 0.5).toColor(),
            HSLColor.fromAHSL(1, ((i + 1) * 360 / steps), 1, 0.5).toColor(),
          ],
          stops: const [0, 1],
        ).createShader(rect);
      canvas.drawArc(rect, start, sweep, false, paint);
    }
    final inner = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius, inner);

    final pointerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pointer, 10, pointerPaint);
    canvas.drawCircle(
      pointer,
      12,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.pointer != pointer;
  }
}

class _BackgroundBlurControl extends StatelessWidget {
  final AppThemeController controller;

  const _BackgroundBlurControl({required this.controller});

  @override
  Widget build(BuildContext context) {
    final blurPercent = controller.backgroundBlurPercent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Slider(
                value: blurPercent.clamp(0, 100),
                min: 0,
                max: 100,
                divisions: 100,
                label: '${blurPercent.round()}%',
                onChanged: controller.setBackgroundBlurPercent,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 56,
              child: Text(
                '${blurPercent.round()}%',
                textAlign: TextAlign.right,
                style: context.appTextStyles.bodyMd.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '0% - без размытия, 100% - максимальное размытие.',
          style: context.appTextStyles.bodySm.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
