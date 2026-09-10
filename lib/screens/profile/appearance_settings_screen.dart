import 'package:crm_task_manager/core/theme/app_theme_controller.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/core/theme/palette/app_palette_presets.dart';
import 'package:crm_task_manager/custom_widget/full_color_wheel_dialog.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/widgets/wallpaper_carousel_card.dart';
import 'package:crm_task_manager/widgets/pin_adaptive_contrast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Переводы названий фоновых пресетов.
String appearanceBackgroundTitle(
    AppBackgroundPreset preset, AppLocalizations t) {
  return t.translate('appearance_bg_${preset.name}');
}

// Переводы названий цветовых схем.
String appearancePaletteTitle(AppPalettePreset preset, AppLocalizations t) {
  return t.translate('appearance_palette_${preset.name}');
}

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  final PinAdaptiveContrastController _adaptiveContrast =
      PinAdaptiveContrastController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adaptiveContrast.syncWithContext(
      context,
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppThemeController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adaptivePalette = _adaptiveContrast.resolve(
      context,
      isDark: isDark,
    );
    final headerInk =
        adaptivePalette.foregroundFor(adaptivePalette.headerLuminance);
    final headerShadows =
        adaptivePalette.shadowsFor(adaptivePalette.headerLuminance);
    final t = AppLocalizations.of(context)!;

    return WallpaperAdaptiveScope(
      palette: adaptivePalette,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            t.translate('appearance'),
            style: context.appTextStyles.titleLg.copyWith(
              color: headerInk,
              shadows: headerShadows,
            ),
          ),
          iconTheme: IconThemeData(color: headerInk),
          backgroundColor: Colors.transparent,
          elevation: 0,
          forceMaterialTransparency: true,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const AppBackgroundOverlay(
              preset: AppBackgroundPreset.aurora,
              forceRender: true,
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
              _SectionCard(
                title: t.translate('appearance_theme_mode'),
                subtitle: t.translate('appearance_theme_mode_subtitle'),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ModeChip(
                      label: t.translate('appearance_theme_light'),
                      selected: controller.themeMode == ThemeMode.light,
                      onTap: () => controller.setThemeMode(ThemeMode.light),
                    ),
                    _ModeChip(
                      label: t.translate('appearance_theme_dark'),
                      selected: controller.themeMode == ThemeMode.dark,
                      onTap: () => controller.setThemeMode(ThemeMode.dark),
                    ),
                    _ModeChip(
                      label: t.translate('appearance_theme_system'),
                      selected: controller.themeMode == ThemeMode.system,
                      onTap: () => controller.setThemeMode(ThemeMode.system),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: t.translate('appearance_palette'),
                subtitle: t.translate('appearance_palette_subtitle'),
                child: _ColorWheelPalette(controller: controller),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: t.translate('appearance_bg_art'),
                subtitle: t.translate('appearance_bg_art_subtitle'),
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
                title: t.translate('appearance_carousel'),
                subtitle: t.translate('appearance_carousel_subtitle'),
                child: WallpaperCarouselCard(controller: controller),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: t.translate('appearance_blur'),
                subtitle: t.translate('appearance_blur_subtitle'),
                child: _BackgroundBlurControl(controller: controller),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: t.translate('appearance_login_anim'),
                subtitle: t.translate('appearance_login_anim_subtitle'),
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: controller.loginIntroAnimationEnabled,
                  onChanged: controller.setLoginIntroAnimationEnabled,
                  title: Text(
                    controller.loginIntroAnimationEnabled
                        ? t.translate('appearance_login_anim_on')
                        : t.translate('appearance_login_anim_off'),
                    style: context.appTextStyles.bodyLg.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    t.translate('appearance_login_anim_switch'),
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
                  t.translate('appearance_reset'),
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
                  child: Text(
                      appearanceBackgroundTitle(
                          preset, AppLocalizations.of(context)!),
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
                  Text(
                      appearancePaletteTitle(
                          currentPreset, AppLocalizations.of(context)!),
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
            Text(AppLocalizations.of(context)!.translate('appearance_quick_schemes'),
                style: context.appTextStyles.bodySm.copyWith(
                    color: context.appColors.textSecondary,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _openFullColorWheel(context),
              icon: const Icon(Icons.palette, size: 16),
              label: Text(AppLocalizations.of(context)!
                  .translate('appearance_open_palette')),
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
                    label: Text(appearancePaletteTitle(
                        preset, AppLocalizations.of(context)!)),
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
        Text(
            AppLocalizations.of(context)!.translate('appearance_blur_hint'),
            style: context.appTextStyles.bodySm
                .copyWith(color: context.appColors.textSecondary)),
      ],
    );
  }
}
