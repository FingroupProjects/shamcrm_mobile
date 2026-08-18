import 'dart:io';

import 'package:crm_task_manager/core/theme/app_theme_controller.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/background/project_wallpapers.dart';
import 'package:crm_task_manager/core/theme/background/wallpaper_rotation_mode.dart';
import 'package:crm_task_manager/core/theme/background/wallpaper_source.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class WallpaperCarouselCard extends StatefulWidget {
  final AppThemeController controller;

  const WallpaperCarouselCard({super.key, required this.controller});

  @override
  State<WallpaperCarouselCard> createState() => _WallpaperCarouselCardState();
}

class _WallpaperCarouselCardState extends State<WallpaperCarouselCard> {
  bool _importing = false;

  Future<void> _importFromGallery() async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage(
        imageQuality: 88,
        maxWidth: 1920,
        limit: 100,
        requestFullMetadata: false,
      );
      if (images.isEmpty || !mounted) return;
      final imported = await widget.controller.importGalleryImages(
        images.map((image) => image.path).toList(),
      );
      if (!mounted) return;
      _showMessage(
        imported == 0
            ? 'Не удалось добавить фото в альбом проекта'
            : 'Добавлено в альбом проекта: $imported',
      );
    } catch (_) {
      if (mounted) {
        _showMessage('Не удалось открыть галерею');
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _toggleSource(WallpaperSource source) async {
    final added = await widget.controller.toggleCarouselSource(source);
    if (!added && mounted && !widget.controller.isCarouselSourceSelected(source)) {
      _showMessage('Можно выбрать не больше ${AppThemeController.maxCarouselCount} фото');
    }
  }

  Future<void> _removeImported(String path) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить фото?'),
          content: const Text(
            'Снимок будет удалён из альбома проекта и из карусели.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    await widget.controller.removeImportedSource(path);
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final selectedCount = controller.carouselItems.length;
    final current = controller.currentCarouselSource;
    final imagePath = current != null && current.isFile
        ? current.path
        : controller.backgroundImagePath;
    final assetPath = current != null && current.isAsset
        ? current.path
        : controller.backgroundAssetPath;
    final hasPreview = (imagePath != null && imagePath.isNotEmpty) ||
        (assetPath != null && assetPath.isNotEmpty);
    final carouselPaused = selectedCount > 0 &&
        controller.backgroundPreset != AppBackgroundPreset.custom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CarouselPreview(
          controller: controller,
          imagePath: imagePath,
          assetPath: assetPath,
          hasPreview: hasPreview,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: _importing ? null : _importFromGallery,
              icon: _importing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: Text(_importing ? 'Добавляем…' : 'Добавить из галереи'),
              style: FilledButton.styleFrom(
                backgroundColor: context.appColors.buttonPrimaryBg,
                foregroundColor: context.appColors.buttonPrimaryFg,
              ),
            ),
            if (selectedCount > 0)
              OutlinedButton(
                onPressed: controller.clearCarouselSelection,
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.appColors.textPrimary,
                  side: BorderSide(color: context.appColors.borderSubtle),
                ),
                child: const Text('Сбросить выбор'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Сначала добавьте фото из галереи в альбом проекта, затем отметьте от 1 до ${AppThemeController.maxCarouselCount} снимков для фона.',
          style: context.appTextStyles.bodySm.copyWith(
            color: context.appColors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Выбрано $selectedCount из ${AppThemeController.maxCarouselCount}',
          style: context.appTextStyles.bodyMd.copyWith(
            color: context.appColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (carouselPaused) ...[
          const SizedBox(height: 12),
          _PausedBanner(onEnable: controller.activateCarousel),
        ],
        if (selectedCount > 0) ...[
          const SizedBox(height: 16),
          _CarouselSettings(controller: controller),
        ],
        const SizedBox(height: 18),
        Text(
          'Альбом проекта',
          style: context.appTextStyles.titleMd.copyWith(
            color: context.appColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        _WallpaperGrid(
          sources: [
            ...controller.importedLibraryPaths.map(
              (path) => WallpaperSource(path: path, isAsset: false),
            ),
            ...ProjectWallpapers.assets.map(
              (path) => WallpaperSource(path: path, isAsset: true),
            ),
          ],
          controller: controller,
          onToggle: _toggleSource,
          onDelete: _removeImported,
        ),
      ],
    );
  }
}

class _CarouselPreview extends StatelessWidget {
  final AppThemeController controller;
  final String? imagePath;
  final String? assetPath;
  final bool hasPreview;

  const _CarouselPreview({
    required this.controller,
    required this.imagePath,
    required this.assetPath,
    required this.hasPreview,
  });

  @override
  Widget build(BuildContext context) {
    final count = controller.carouselItems.length;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 176,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: context.appColors.surfacePrimary),
            if (hasPreview && imagePath != null && imagePath!.isNotEmpty)
              Image.file(
                File(imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _PreviewFallback(),
              )
            else if (hasPreview && assetPath != null && assetPath!.isNotEmpty)
              Image.asset(
                assetPath!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _PreviewFallback(),
              )
            else
              const _PreviewFallback(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.38),
                  ],
                ),
              ),
            ),
            if (!hasPreview)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Выберите фото из альбома проекта',
                    textAlign: TextAlign.center,
                    style: context.appTextStyles.bodyMd.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (count >= 2) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: _PreviewArrow(
                  icon: Icons.chevron_left_rounded,
                  onTap: controller.showPreviousWallpaper,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: _PreviewArrow(
                  icon: Icons.chevron_right_rounded,
                  onTap: controller.showNextWallpaper,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(count, (index) {
                    final active = index == controller.carouselIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 16 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: active ? 0.95 : 0.45),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.appColors.backgroundSecondary,
            context.appColors.surfaceAccent.withValues(alpha: 0.55),
          ],
        ),
      ),
    );
  }
}

class _PreviewArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _PreviewArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.black.withValues(alpha: 0.28),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}

class _PausedBanner extends StatelessWidget {
  final VoidCallback onEnable;

  const _PausedBanner({required this.onEnable});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appColors.surfaceAccent.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appColors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Сейчас включён художественный фон. Карусель на паузе.',
              style: context.appTextStyles.bodySm.copyWith(
                color: context.appColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onEnable,
            child: const Text('Включить'),
          ),
        ],
      ),
    );
  }
}

class _CarouselSettings extends StatelessWidget {
  final AppThemeController controller;

  const _CarouselSettings({required this.controller});

  String _intervalLabel(int minutes) {
    if (minutes < 60) return '$minutes мин';
    if (minutes == 60) return '1 ч';
    if (minutes % 60 == 0) return '${minutes ~/ 60} ч';
    return '$minutes мин';
  }

  @override
  Widget build(BuildContext context) {
    final opacity = controller.backgroundOpacityPercent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appColors.backgroundSecondary.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Настройки фона',
            style: context.appTextStyles.bodyLg.copyWith(
              color: context.appColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Видимость',
            style: context.appTextStyles.bodySm.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: opacity.clamp(10, 100),
                  min: 10,
                  max: 100,
                  divisions: 90,
                  label: '${opacity.round()}%',
                  onChanged: controller.setBackgroundOpacityPercent,
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '${opacity.round()}%',
                  textAlign: TextAlign.right,
                  style: context.appTextStyles.bodyMd.copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Насколько ярко картинка видна под интерфейсом.',
            style: context.appTextStyles.bodySm.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          if (controller.canAutoRotate) ...[
            const SizedBox(height: 16),
            Text(
              'Смена фото',
              style: context.appTextStyles.bodySm.copyWith(
                color: context.appColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: WallpaperRotationMode.values.map((mode) {
                final selected = controller.rotationMode == mode;
                return ChoiceChip(
                  label: Text(mode.title),
                  selected: selected,
                  onSelected: (_) => controller.setRotationMode(mode),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              controller.rotationMode.subtitle,
              style: context.appTextStyles.bodySm.copyWith(
                color: context.appColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (controller.rotationMode == WallpaperRotationMode.interval) ...[
              const SizedBox(height: 12),
              Text(
                'Интервал: ${_intervalLabel(controller.intervalMinutes)}',
                style: context.appTextStyles.bodyMd.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppThemeController.intervalPresets.map((minutes) {
                  final selected = controller.intervalMinutes == minutes;
                  return ChoiceChip(
                    label: Text(_intervalLabel(minutes)),
                    selected: selected,
                    onSelected: (_) => controller.setIntervalMinutes(minutes),
                  );
                }).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _WallpaperGrid extends StatelessWidget {
  final List<WallpaperSource> sources;
  final AppThemeController controller;
  final Future<void> Function(WallpaperSource source) onToggle;
  final Future<void> Function(String path)? onDelete;

  const _WallpaperGrid({
    required this.sources,
    required this.controller,
    required this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sources.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, index) {
        final source = sources[index];
        final order = controller.carouselOrderOf(source);
        final selected = order >= 0;
        return _WallpaperTile(
          source: source,
          selected: selected,
          order: order,
          onTap: () => onToggle(source),
          onDelete: onDelete == null || source.isAsset
              ? null
              : () => onDelete!(source.path),
        );
      },
    );
  }
}

class _WallpaperTile extends StatelessWidget {
  final WallpaperSource source;
  final bool selected;
  final int order;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _WallpaperTile({
    required this.source,
    required this.selected,
    required this.order,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? context.appColors.buttonPrimaryBg
                : context.appColors.borderSubtle,
            width: selected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              source.isAsset
                  ? Image.asset(
                      source.path,
                      fit: BoxFit.cover,
                      cacheWidth: 360,
                    )
                  : Image.file(
                      File(source.path),
                      fit: BoxFit.cover,
                      cacheWidth: 360,
                      errorBuilder: (_, __, ___) => ColoredBox(
                        color: context.appColors.backgroundSecondary,
                      ),
                    ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: selected ? 0.28 : 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.appColors.buttonPrimaryBg,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${order + 1}',
                      style: context.appTextStyles.bodySm.copyWith(
                        color: context.appColors.buttonPrimaryFg,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              if (onDelete != null)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.42),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onDelete,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
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
