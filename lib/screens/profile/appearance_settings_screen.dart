import 'dart:io';

import 'package:crm_task_manager/core/theme/app_theme_controller.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/core/theme/palette/app_palette_presets.dart';
import 'package:crm_task_manager/custom_widget/full_color_wheel_dialog.dart';
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
  Widget build(BuildContext context) {
    final controller = context.watch<AppThemeController>();
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
                title: 'Палитра',
                subtitle:
                    'Выберите основной цвет темы. Приложение соберет палитру автоматически.',
                child: _ColorWheelPalette(controller: controller),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Фоновый арт',
                subtitle:
                    'Легкий художественный слой поверх интерфейса. Видно мягко и без перегруза.',
                child: Column(
                  children: AppBackgroundPreset.values
                      .where((p) => p != AppBackgroundPreset.custom)
                      .map((preset) => _BackgroundTile(
                            preset: preset,
                            selected: controller.backgroundPreset == preset,
                            onTap: () => controller.setBackgroundPreset(preset),
                          ))
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
              _SectionCard(
                title: 'Анимация входа',
                subtitle:
                    'Короткий переход с логотипом перед открытием PIN-кода.',
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: controller.loginIntroAnimationEnabled,
                  onChanged: controller.setLoginIntroAnimationEnabled,
                  title: Text(
                    controller.loginIntroAnimationEnabled
                        ? 'Включена'
                        : 'Выключена',
                    style: context.appTextStyles.bodyLg.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Показывать короткую анимацию shamCRM при переходе к PIN.',
                    style: context.appTextStyles.bodySm.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ),
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
            color: context.appColors.borderSubtle.withValues(alpha: 0.42)),
        boxShadow: context.appShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: context.appTextStyles.titleMd
                  .copyWith(color: context.appColors.textPrimary)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: context.appTextStyles.bodySm.copyWith(
                  color: context.appColors.textSecondary, height: 1.45)),
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

  const _ModeChip(
      {required this.label, required this.selected, required this.onTap});

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
                  : context.appColors.borderSubtle),
        ),
        child: Text(label,
            style: context.appTextStyles.bodyMd.copyWith(
              color: selected
                  ? context.appColors.buttonPrimaryFg
                  : context.appColors.textPrimary,
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }
}

class _BackgroundTile extends StatelessWidget {
  final AppBackgroundPreset preset;
  final bool selected;
  final VoidCallback onTap;

  const _BackgroundTile(
      {required this.preset, required this.selected, required this.onTap});

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
                  child: Stack(fit: StackFit.expand, children: [
                    ColoredBox(color: context.appColors.surfacePrimary),
                    _BackgroundPreview(preset: preset),
                  ]),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Text(preset.title,
                      style: context.appTextStyles.bodyLg.copyWith(
                        color: context.appColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ))),
              if (selected)
                Icon(Icons.check_circle,
                    color: context.appColors.buttonPrimaryBg),
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
      decoration: BoxDecoration(gradient: _gradient(context)),
      child: Stack(fit: StackFit.expand, children: [
        _blob(const Alignment(-0.85, -0.95),
            context.appColors.buttonPrimaryBg.withValues(alpha: 0.28), 34),
        _blob(const Alignment(0.95, -0.35),
            context.appColors.surfaceAccent.withValues(alpha: 0.26), 30),
        _blob(const Alignment(0.25, 0.95),
            context.appColors.info.withValues(alpha: 0.22), 38),
        if (preset == AppBackgroundPreset.paper)
          CustomPaint(
              painter: _PreviewLinesPainter(
                  color:
                      context.appColors.borderSubtle.withValues(alpha: 0.3))),
      ]),
    );
  }

  Gradient _gradient(BuildContext context) {
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
              context.appColors.backgroundSecondary,
              context.appColors.surfacePrimary,
            ]);
      case AppBackgroundPreset.mesh:
        return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.appColors.backgroundSecondary,
              context.appColors.backgroundPrimary,
            ]);
      case AppBackgroundPreset.sunrise:
        return LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              context.appColors.backgroundPrimary,
              context.appColors.surfaceAccent.withValues(alpha: 0.45),
              context.appColors.backgroundSecondary,
            ]);
      case AppBackgroundPreset.paper:
        return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.appColors.backgroundPrimary,
              context.appColors.surfacePrimary,
            ]);
      case AppBackgroundPreset.custom:
        return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.appColors.backgroundSecondary,
              context.appColors.surfaceAccent.withValues(alpha: 0.35),
            ]);
    }
  }

  Widget _blob(Alignment alignment, Color color, double size) {
    return Align(
        alignment: alignment,
        child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)));
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
          Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewLinesPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _CustomBackgroundCard extends StatelessWidget {
  final AppThemeController controller;

  static const List<String> _projectBackgrounds = [
    'assets/fon/IMG_1548.JPG',
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
        'assets/fon/IMG_1500.png',
    'assets/fon/IMG_1501.png',
    'assets/fon/IMG_1502.png',
    'assets/fon/IMG_1503.png',
    'assets/fon/IMG_1504.png',
    'assets/fon/IMG_1505.png',
    'assets/fon/IMG_1506.png',
    'assets/fon/IMG_1507.png',
    'assets/fon/IMG_1508.png',
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
            child: Stack(fit: StackFit.expand, children: [
              ColoredBox(color: context.appColors.surfacePrimary),
              if (hasImage)
                Image.file(File(imagePath), fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                  return DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.appColors.backgroundSecondary,
                      context.appColors.surfaceAccent.withValues(alpha: 0.55),
                    ],
                  )));
                })
              else if (hasAsset)
                Image.asset(assetPath, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                  return DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.appColors.backgroundSecondary,
                      context.appColors.surfaceAccent.withValues(alpha: 0.55),
                    ],
                  )));
                })
              else
                DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.appColors.backgroundSecondary,
                    context.appColors.surfaceAccent.withValues(alpha: 0.55),
                  ],
                ))),
              DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  context.appColors.backgroundPrimary.withValues(alpha: 0.18),
                ],
              ))),
              if (!hasImage)
                Center(
                    child: Text(
                        'Выберите изображение из альбома проекта или галереи',
                        style: context.appTextStyles.bodyMd.copyWith(
                            color: context.appColors.textPrimary,
                            fontWeight: FontWeight.w600))),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 10, children: [
          FilledButton(
            onPressed: () => _pickImage(context),
            style: FilledButton.styleFrom(
                backgroundColor: context.appColors.buttonPrimaryBg,
                foregroundColor: context.appColors.buttonPrimaryFg),
            child: Text(hasImage ? 'Сменить картинку' : 'Выбрать картинку'),
          ),
          if (hasImage)
            OutlinedButton(
              onPressed: controller.clearCustomBackgroundImage,
              style: OutlinedButton.styleFrom(
                  foregroundColor: context.appColors.textPrimary,
                  side: BorderSide(color: context.appColors.borderSubtle)),
              child: const Text('Убрать'),
            ),
          if (hasImage)
            OutlinedButton(
              onPressed: () =>
                  controller.setBackgroundPreset(AppBackgroundPreset.custom),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.appColors.textPrimary,
                side: BorderSide(
                    color: controller.backgroundPreset ==
                            AppBackgroundPreset.custom
                        ? context.appColors.buttonPrimaryBg
                        : context.appColors.borderSubtle),
              ),
              child: const Text('Использовать как фон'),
            ),
        ]),
        const SizedBox(height: 18),
        Text('Альбом проекта',
            style: context.appTextStyles.titleMd.copyWith(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _projectBackgrounds.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.92),
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
                      width: selected ? 1.5 : 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(fit: StackFit.expand, children: [
                    Image.asset(asset, fit: BoxFit.cover),
                    DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        Colors.transparent
                      ],
                    ))),
                    if (selected)
                      Positioned(
                          right: 8,
                          top: 8,
                          child: Icon(Icons.check_circle,
                              color: context.appColors.buttonPrimaryBg,
                              size: 22)),
                  ]),
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

  Future<void> _openFullColorWheel(BuildContext context) async {
    final seedColor = controller.paletteSeedColor;
    final selected =
        await FullColorWheelDialog.show(context, initialColor: seedColor);
    if (selected != null && context.mounted) {
      await controller.setPaletteSeedColor(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seedColor = controller.paletteSeedColor;
    final currentPreset = controller.palettePreset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => _openFullColorWheel(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: seedColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.appColors.borderPrimary)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '#${seedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                      style: context.appTextStyles.bodyMd.copyWith(
                          color: context.appColors.textPrimary,
                          fontWeight: FontWeight.w700)),
                  Text(currentPreset.title,
                      style: context.appTextStyles.bodySm
                          .copyWith(color: context.appColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 10),
        Row(
          children: [
            Text('Быстрые схемы',
                style: context.appTextStyles.bodySm.copyWith(
                    color: context.appColors.textSecondary,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _openFullColorWheel(context),
              icon: const Icon(Icons.palette, size: 16),
              label: const Text('Открыть палитру'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppPalettePreset.values
              .where((p) => p != AppPalettePreset.custom)
              .map((preset) => ChoiceChip(
                    label: Text(preset.title),
                    selected: controller.palettePreset == preset,
                    onSelected: (_) => controller.setPalettePreset(preset),
                  ))
              .toList(),
        ),
      ],
    );
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
                child: Text('${blurPercent.round()}%',
                    textAlign: TextAlign.right,
                    style: context.appTextStyles.bodyMd.copyWith(
                        color: context.appColors.textPrimary,
                        fontWeight: FontWeight.w700))),
          ],
        ),
        const SizedBox(height: 8),
        Text('0% - без размытия, 100% - максимальное размытие.',
            style: context.appTextStyles.bodySm
                .copyWith(color: context.appColors.textSecondary)),
      ],
    );
  }
}
