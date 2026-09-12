import 'dart:io';
import 'dart:ui';

import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chats/chat_appearance.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<ChatAppearanceData?> showChatAppearanceSheet({
  required BuildContext context,
  required ChatAppearanceData initialValue,
}) {
  return showModalBottomSheet<ChatAppearanceData>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (context) => _ChatAppearanceSheet(initialValue: initialValue),
  );
}

class _ChatAppearanceSheet extends StatefulWidget {
  final ChatAppearanceData initialValue;
  const _ChatAppearanceSheet({required this.initialValue});

  @override
  State<_ChatAppearanceSheet> createState() => _ChatAppearanceSheetState();
}

class _ChatAppearanceSheetState extends State<_ChatAppearanceSheet> {
  static const List<String> _projectWallpapers = [
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

  late ChatAppearanceData _draft;
  bool _isPickingGallery = false;

  static const List<Color> _lightMessageColors = [
    Color(0xFFFFFFFF),
    Color(0xFFF4F7FB),
    Color(0xFFEAF7FF),
    Color(0xFFF3F1FF),
    Color(0xFFFFF4E8),
    Color(0xFFEAF8EF),
    Color(0xFF1D9BF0),
    Color(0xFF5ABF7D),
    Color(0xFF8C56FF),
    Color(0xFFFB7D6E),
    Color(0xFFF6C35C),
    Color(0xFF00BFA5),
  ];

  static const List<Color> _darkMessageColors = [
    Color(0xFF0F172A),
    Color(0xFF111827),
    Color(0xFF1E293B),
    Color(0xFF23324D),
    Color(0xFF2C1F45),
    Color(0xFF16352A),
    Color(0xFF607D8B),
    Color(0xFF7C4DFF),
  ];

  @override
  void initState() {
    super.initState();
    _draft = widget.initialValue;
  }

  // ─── Галерея ───────────────────────────────────────────────────────────────

  Future<void> _pickGalleryWallpaper() async {
    if (_isPickingGallery) return;
    setState(() => _isPickingGallery = true);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null || !mounted) return;

      // Копируем в постоянную директорию приложения
      final dir = await getApplicationDocumentsDirectory();
      final wallpaperDir = Directory('${dir.path}/chat_wallpapers');
      if (!wallpaperDir.existsSync()) wallpaperDir.createSync(recursive: true);

      final ext = file.path.split('.').last;
      final dest =
          '${wallpaperDir.path}/wallpaper_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final saved = await File(file.path).copy(dest);

      setState(() {
        _draft = _draft.copyWith(
          preset: ChatAppearancePreset.custom,
          wallpaperStyle: ChatWallpaperStyle.gallery,
          customBackgroundImagePath: saved.path,
          customBackgroundAssetPath: '',
        );
      });
    } catch (e) {
      debugPrint('Gallery wallpaper error: $e');
    } finally {
      if (mounted) setState(() => _isPickingGallery = false);
    }
  }

  // ─── Пресеты ───────────────────────────────────────────────────────────────

  ChatAppearanceData _presetValueFor(ChatAppearancePreset preset) {
    switch (preset) {
      case ChatAppearancePreset.classic:
        return const ChatAppearanceData(
          preset: ChatAppearancePreset.classic,
          bubbleStyle: ChatBubbleStyle.classic,
          wallpaperStyle: ChatWallpaperStyle.none,
          bubbleOpacity: 0.96,
          backgroundOpacity: 0.82,
          chromeOpacity: 0.62,
          fontScale: 1.0,
          fontWeightLevel: 1,
        );
      case ChatAppearancePreset.system:
        return _draft.copyWith(
          preset: ChatAppearancePreset.system,
          bubbleStyle: ChatBubbleStyle.telegram,
          wallpaperStyle: ChatWallpaperStyle.none,
          bubbleOpacity: _draft.bubbleOpacity,
          backgroundOpacity: _draft.backgroundOpacity,
          chromeOpacity: _draft.chromeOpacity,
          fontScale: _draft.fontScale,
          fontWeightLevel: _draft.fontWeightLevel,
        );
      case ChatAppearancePreset.custom:
        return _draft.copyWith(
          preset: ChatAppearancePreset.custom,
          bubbleStyle: _draft.bubbleStyle,
          wallpaperStyle: _draft.wallpaperStyle,
        );
    }
  }

  void _selectProjectWallpaper(String assetPath) {
    setState(() {
      _draft = _draft.copyWith(
        preset: ChatAppearancePreset.custom,
        wallpaperStyle: ChatWallpaperStyle.gallery,
        customBackgroundImagePath: '',
        customBackgroundAssetPath: assetPath,
      );
    });
  }

  // ─── Labels ────────────────────────────────────────────────────────────────

  String _presetLabel(ChatAppearancePreset preset, AppLocalizations t) =>
      switch (preset) {
        ChatAppearancePreset.system =>
          t.translate('chat_appearance_preset_system'),
        ChatAppearancePreset.custom =>
          t.translate('chat_appearance_preset_custom'),
        ChatAppearancePreset.classic =>
          t.translate('chat_appearance_preset_classic'),
      };

  IconData _presetIcon(ChatAppearancePreset preset) => switch (preset) {
        ChatAppearancePreset.classic => Icons.format_paint_outlined,
        ChatAppearancePreset.system => Icons.phone_android_outlined,
        ChatAppearancePreset.custom => Icons.tune_rounded,
      };

  String _bubbleLabel(ChatBubbleStyle style, AppLocalizations t) =>
      switch (style) {
        ChatBubbleStyle.classic =>
          t.translate('chat_appearance_bubble_classic'),
        ChatBubbleStyle.telegram =>
          t.translate('chat_appearance_bubble_telegram'),
        ChatBubbleStyle.soft => t.translate('chat_appearance_bubble_soft'),
        ChatBubbleStyle.compact =>
          t.translate('chat_appearance_bubble_compact'),
        ChatBubbleStyle.rounded =>
          t.translate('chat_appearance_bubble_rounded'),
        ChatBubbleStyle.glass => t.translate('chat_appearance_bubble_glass'),
      };

  String _wallpaperLabel(ChatWallpaperStyle w, AppLocalizations t) =>
      switch (w) {
        ChatWallpaperStyle.none =>
          t.translate('chat_appearance_wallpaper_default'),
        ChatWallpaperStyle.aurora => 'Aurora',
        ChatWallpaperStyle.ocean => 'Ocean',
        ChatWallpaperStyle.sunset => 'Sunset',
        ChatWallpaperStyle.forest => 'Forest',
        ChatWallpaperStyle.gallery =>
          t.translate('chat_appearance_wallpaper_gallery'),
      };

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final t = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: bottomInset + 12,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              // Ограничиваем высоту, чтобы не выходить за экран
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.88,
              ),
              decoration: BoxDecoration(
                color: colors.surfacePrimary.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: colors.borderSubtle.withValues(alpha: 0.32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.16),
                    blurRadius: 32,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Шапка (не скроллится) ──
                  _buildHeader(context),
                  // ── Контент (скроллится) ──
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(label: t.translate('chat_appearance_mode')),
                          _buildPresetRow(context, t),
                          const SizedBox(height: 20),

                          // Форма пузырьков
                          _SectionLabel(
                              label: t.translate('chat_appearance_message_shape')),
                          _buildBubbleGrid(context, t),

                          // Кастомные настройки (только в режиме «Свой стиль»)
                          if (_draft.preset == ChatAppearancePreset.custom) ...[
                            const SizedBox(height: 20),
                            _SectionLabel(
                                label: t.translate('chat_appearance_background')),
                            _buildWallpaperRow(context, t),
                            const SizedBox(height: 14),
                            _buildProjectWallpaperRow(context),
                            const SizedBox(height: 20),
                            _buildBubbleColorSection(context, t),
                            const SizedBox(height: 20),
                            _buildSliders(context, t),
                            const SizedBox(height: 4),
                            _SectionLabel(
                                label: t.translate('chat_appearance_font_weight')),
                            _buildFontWeightSegment(context, t),
                          ],
                          const SizedBox(height: 20),
                          _SectionLabel(
                              label: t.translate('chat_appearance_preview')),
                          _ChatPreviewCard(appearance: _draft),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                    decoration: BoxDecoration(
                      color: colors.surfacePrimary.withValues(alpha: 0.94),
                      border: Border(
                        top: BorderSide(
                          color: colors.borderSubtle.withValues(alpha: 0.16),
                        ),
                      ),
                    ),
                    child: _buildButtons(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Шапка ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final colors = context.appColors;
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ручка
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderSubtle.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.buttonPrimaryBg.withValues(alpha: 0.18),
                      colors.buttonPrimaryBg.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.palette_outlined,
                  color: colors.buttonPrimaryBg,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.translate('chat_appearance'),
                  style: context.appTextStyles.titleMd.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Ряд пресетов ───────────────────────────────────────────────────────────

  Widget _buildPresetRow(BuildContext context, AppLocalizations t) {
    return Row(
      children: ChatAppearancePreset.values
          .where((preset) => preset != ChatAppearancePreset.classic)
          .map((preset) {
        final isSelected = _draft.preset == preset;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: preset != ChatAppearancePreset.custom ? 8 : 0,
            ),
            child: _PresetCard(
              label: _presetLabel(preset, t),
              icon: _presetIcon(preset),
              isSelected: isSelected,
              onTap: () => setState(() => _draft = _presetValueFor(preset)),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Сетка форм пузырьков ───────────────────────────────────────────────────

  Widget _buildBubbleGrid(BuildContext context, AppLocalizations t) {
    final styles = ChatBubbleStyle.values;
    // 3 колонки по 2 строки
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: styles.map((style) {
        final isSelected = _draft.bubbleStyle == style;
        final itemWidth =
            (MediaQuery.of(context).size.width - 24 - 18 * 2 - 8 * 2) / 3;
        return _BubbleStyleCard(
          label: _bubbleLabel(style, t),
          style: style,
          isSelected: isSelected,
          width: itemWidth,
          appearance: _draft,
          onTap: () => setState(() => _draft = _draft.copyWith(
                bubbleStyle: style,
                preset: _draft.preset,
              )),
        );
      }).toList(),
    );
  }

  // ── Ряд обоев ──────────────────────────────────────────────────────────────

  Widget _buildWallpaperRow(BuildContext context, AppLocalizations t) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Обои из enum
          ...ChatWallpaperStyle.values
              .where((w) => w != ChatWallpaperStyle.gallery)
              .map((wallpaper) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _WallpaperChip(
                      wallpaper: wallpaper,
                      label: _wallpaperLabel(wallpaper, t),
                      isSelected: _draft.wallpaperStyle == wallpaper,
                      customPath: null,
                      onTap: () => setState(() => _draft = _draft.copyWith(
                            wallpaperStyle: wallpaper,
                            clearCustomBackgroundImagePath: true,
                          )),
                    ),
                  )),
          // Галерея
          _WallpaperChip(
            wallpaper: ChatWallpaperStyle.gallery,
            label: t.translate('chat_appearance_gallery'),
            isSelected: _draft.wallpaperStyle == ChatWallpaperStyle.gallery &&
                (_draft.customBackgroundImagePath ?? '').isNotEmpty,
            customPath: _draft.customBackgroundImagePath,
            customAssetPath: null,
            isLoading: _isPickingGallery,
            onTap: _pickGalleryWallpaper,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectWallpaperRow(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _projectWallpapers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final assetPath = _projectWallpapers[index];
          return _WallpaperChip(
            wallpaper: ChatWallpaperStyle.gallery,
            label: '',
            isSelected: _draft.wallpaperStyle == ChatWallpaperStyle.gallery &&
                _draft.customBackgroundAssetPath == assetPath,
            customPath: null,
            customAssetPath: assetPath,
            onTap: () => _selectProjectWallpaper(assetPath),
          );
        },
      ),
    );
  }

  Widget _buildBubbleColorSection(BuildContext context, AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: t.translate('chat_appearance_message_color')),
        const SizedBox(height: 8),
        Text(
          t.translate('chat_appearance_outgoing'),
          style: context.appTextStyles.bodySm.copyWith(
            color: context.appColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildColorPalette(context, true),
        const SizedBox(height: 16),
        Text(
          t.translate('chat_appearance_incoming'),
          style: context.appTextStyles.bodySm.copyWith(
            color: context.appColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildColorPalette(context, false),
      ],
    );
  }

  Widget _buildColorPalette(BuildContext context, bool isSender) {
    final t = AppLocalizations.of(context)!;
    final selectedColor = isSender
        ? _draft.customSenderBubbleColor
        : _draft.customReceiverBubbleColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPaletteRow(
          context: context,
          title: t.translate('chat_appearance_colors_light'),
          colors: _lightMessageColors,
          selectedColor: selectedColor,
          onSelected: (color) => _updateBubbleColor(isSender, color),
        ),
        const SizedBox(height: 12),
        _buildPaletteRow(
          context: context,
          title: t.translate('chat_appearance_colors_dark'),
          colors: _darkMessageColors,
          selectedColor: selectedColor,
          onSelected: (color) => _updateBubbleColor(isSender, color),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _updateBubbleColor(isSender, null),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color:
                  context.appColors.backgroundSecondary.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedColor == null
                    ? context.appColors.buttonPrimaryBg
                    : context.appColors.borderSubtle.withValues(alpha: 0.28),
                width: selectedColor == null ? 1.6 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.restart_alt_rounded,
                  size: 18,
                  color: selectedColor == null
                      ? context.appColors.buttonPrimaryBg
                      : context.appColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  t.translate('chat_appearance_default'),
                  style: context.appTextStyles.bodySm.copyWith(
                    color: selectedColor == null
                        ? context.appColors.buttonPrimaryBg
                        : context.appColors.textPrimary,
                    fontWeight: selectedColor == null
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _updateBubbleColor(bool isSender, Color? color) {
    setState(() {
      _draft = _draft.copyWith(
        clearCustomSenderBubbleColor: isSender && color == null,
        clearCustomReceiverBubbleColor: !isSender && color == null,
        customSenderBubbleColor:
            isSender ? color : _draft.customSenderBubbleColor,
        customReceiverBubbleColor:
            isSender ? _draft.customReceiverBubbleColor : color,
      );
    });
  }

  Widget _buildPaletteRow({
    required BuildContext context,
    required String title,
    required List<Color> colors,
    required Color? selectedColor,
    required ValueChanged<Color> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.appTextStyles.caption.copyWith(
            color: context.appColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: colors.map((color) {
            final isSelected = selectedColor != null &&
                selectedColor.toARGB32() == color.toARGB32();
            return GestureDetector(
              onTap: () => onSelected(color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? context.appColors.buttonPrimaryBg
                        : context.appColors.borderSubtle
                            .withValues(alpha: 0.18),
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.appColors.shadow.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: context.adaptiveForegroundOn(color),
                        size: 18,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Слайдеры ───────────────────────────────────────────────────────────────

  Widget _buildSliders(BuildContext context, AppLocalizations t) {
    return Column(
      children: [
        _SliderTile(
          label: t.translate('chat_appearance_bubble_opacity'),
          value: _draft.bubbleOpacity,
          min: 0.55,
          max: 1.0,
          onChanged: (v) =>
              setState(() => _draft = _draft.copyWith(bubbleOpacity: v)),
        ),
        _SliderTile(
          label: t.translate('chat_appearance_background_saturation'),
          value: _draft.backgroundOpacity,
          min: 0.45,
          max: 1.0,
          onChanged: (v) =>
              setState(() => _draft = _draft.copyWith(backgroundOpacity: v)),
        ),
        _SliderTile(
          label: t.translate('chat_appearance_background_blur'),
          value: _draft.chromeOpacity,
          min: 0.0,
          max: 0.95,
          onChanged: (v) =>
              setState(() => _draft = _draft.copyWith(chromeOpacity: v)),
        ),
        _SliderTile(
          label: t.translate('chat_appearance_font_size'),
          value: _draft.fontScale,
          min: 0.9,
          max: 1.18,
          onChanged: (v) =>
              setState(() => _draft = _draft.copyWith(fontScale: v)),
        ),
      ],
    );
  }

  // ── Толщина шрифта ─────────────────────────────────────────────────────────

  Widget _buildFontWeightSegment(BuildContext context, AppLocalizations t) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SegmentedButton<int>(
        segments: [
          ButtonSegment<int>(
              value: 0,
              label: Text(t.translate('chat_appearance_weight_light'))),
          ButtonSegment<int>(
              value: 1,
              label: Text(t.translate('chat_appearance_weight_regular'))),
          ButtonSegment<int>(
              value: 2,
              label: Text(t.translate('chat_appearance_weight_bold'))),
        ],
        selected: {_draft.fontWeightLevel},
        onSelectionChanged: (s) =>
            setState(() => _draft = _draft.copyWith(fontWeightLevel: s.first)),
        showSelectedIcon: false,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? colors.buttonPrimaryBg.withValues(alpha: 0.14)
                : colors.backgroundSecondary.withValues(alpha: 0.45),
          ),
          foregroundColor: WidgetStateProperty.all(colors.textPrimary),
        ),
      ),
    );
  }

  // ── Кнопки ─────────────────────────────────────────────────────────────────

  Widget _buildButtons(BuildContext context) {
    final colors = context.appColors;
    final t = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () =>
                setState(() => _draft = ChatAppearanceData.defaults()),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: BorderSide(color: colors.borderSubtle),
              foregroundColor: colors.textSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(t.translate('chat_appearance_default')),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_draft),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: _draft.accentColor(context),
              foregroundColor: context.adaptiveForegroundOn(
                _draft.accentColor(context),
              ),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              t.translate('apply'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── _SectionLabel ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: context.appTextStyles.bodyMd.copyWith(
          color: context.appColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

// ─── _PresetCard ──────────────────────────────────────────────────────────────

class _PresetCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.buttonPrimaryBg.withValues(alpha: 0.12)
              : colors.backgroundSecondary.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colors.buttonPrimaryBg.withValues(alpha: 0.5)
                : colors.borderSubtle.withValues(alpha: 0.22),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? colors.buttonPrimaryBg : colors.textSecondary,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.appTextStyles.caption.copyWith(
                color: isSelected ? colors.buttonPrimaryBg : colors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _BubbleStyleCard ─────────────────────────────────────────────────────────

class _BubbleStyleCard extends StatelessWidget {
  final String label;
  final ChatBubbleStyle style;
  final bool isSelected;
  final double width;
  final ChatAppearanceData appearance;
  final VoidCallback onTap;

  const _BubbleStyleCard({
    required this.label,
    required this.style,
    required this.isSelected,
    required this.width,
    required this.appearance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Создаём временный appearance с нужным стилем для превью
    final previewAppearance = appearance.copyWith(bubbleStyle: style);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: width,
        decoration: BoxDecoration(
          color: isSelected
              ? colors.buttonPrimaryBg.withValues(alpha: 0.10)
              : colors.backgroundSecondary.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colors.buttonPrimaryBg.withValues(alpha: 0.50)
                : colors.borderSubtle.withValues(alpha: 0.22),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Мини-превью двух пузырьков
              _BubbleMiniPreview(appearance: previewAppearance),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.appTextStyles.caption.copyWith(
                  color:
                      isSelected ? colors.buttonPrimaryBg : colors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BubbleMiniPreview extends StatelessWidget {
  final ChatAppearanceData appearance;
  const _BubbleMiniPreview({required this.appearance});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Входящий — слева
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            height: 14,
            width: 44,
            decoration: BoxDecoration(
              color: appearance.receiverBubbleColor(context),
              borderRadius: appearance.bubbleRadius(false),
              border: Border.all(
                color: appearance.borderColor(context, false),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        // Исходящий — справа
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            height: 14,
            width: 38,
            decoration: BoxDecoration(
              color: appearance.senderBubbleColor(context),
              borderRadius: appearance.bubbleRadius(true),
              border: Border.all(
                color: appearance.borderColor(context, true),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── _WallpaperChip ───────────────────────────────────────────────────────────

class _WallpaperChip extends StatelessWidget {
  final ChatWallpaperStyle wallpaper;
  final String label;
  final bool isSelected;
  final String? customPath;
  final String? customAssetPath;
  final bool isLoading;
  final VoidCallback onTap;

  const _WallpaperChip({
    required this.wallpaper,
    required this.label,
    required this.isSelected,
    required this.customPath,
    this.customAssetPath,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const previewHeight = 60.0;
    const previewWidth = 68.0;

    // Превью для чипа
    Widget preview;
    if (wallpaper == ChatWallpaperStyle.gallery) {
      if (isLoading) {
        preview = Container(
          height: previewHeight,
          width: previewWidth,
          decoration: BoxDecoration(
            color: colors.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.buttonPrimaryBg,
              ),
            ),
          ),
        );
      } else if (customPath != null && customPath!.isNotEmpty) {
        preview = Container(
          height: previewHeight,
          width: previewWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: FileImage(File(customPath!)),
              fit: BoxFit.cover,
            ),
          ),
        );
      } else if (customAssetPath != null && customAssetPath!.isNotEmpty) {
        preview = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            customAssetPath!,
            height: previewHeight,
            width: previewWidth,
            fit: BoxFit.cover,
          ),
        );
      } else {
        preview = Container(
          height: previewHeight,
          width: previewWidth,
          decoration: BoxDecoration(
            color: colors.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.borderSubtle.withValues(alpha: 0.4),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined,
                  color: colors.textSecondary, size: 22),
            ],
          ),
        );
      }
    } else {
      // Gradient preview
      final appearance = ChatAppearanceData.defaults().copyWith(
        preset: ChatAppearancePreset.custom,
        wallpaperStyle: wallpaper,
        bubbleStyle: ChatBubbleStyle.telegram,
      );
      preview = Container(
        height: previewHeight,
        width: previewWidth,
        decoration: appearance.buildScreenDecoration(context).copyWith(
              borderRadius: BorderRadius.circular(12),
            ),
        child: Stack(
          children: [
            ...appearance.buildBackgroundOrbs(context),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                width: 34,
                height: 12,
                margin: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: appearance.receiverBubbleColor(context),
                  borderRadius: appearance.bubbleRadius(false),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 28,
                height: 12,
                margin: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: appearance.senderBubbleColor(context),
                  borderRadius: appearance.bubbleRadius(true),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colors.buttonPrimaryBg
                : colors.borderSubtle.withValues(alpha: 0.22),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: preview,
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.appTextStyles.caption.copyWith(
                  color:
                      isSelected ? colors.buttonPrimaryBg : colors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 9.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── _SliderTile ──────────────────────────────────────────────────────────────

class _SliderTile extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.appTextStyles.bodySm.copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.appColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value.toStringAsFixed(2),
                  style: context.appTextStyles.caption.copyWith(
                    color: context.appColors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: context.appColors.buttonPrimaryBg,
              inactiveTrackColor:
                  context.appColors.borderSubtle.withValues(alpha: 0.4),
              thumbColor: context.appColors.buttonPrimaryBg,
              overlayColor:
                  context.appColors.buttonPrimaryBg.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _ChatPreviewCard ─────────────────────────────────────────────────────────

class _ChatPreviewCard extends StatelessWidget {
  final ChatAppearanceData appearance;
  const _ChatPreviewCard({required this.appearance});

  Color _opaqueOn(Color color, Color canvas) {
    return Color.alphaBlend(color, canvas);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final t = AppLocalizations.of(context)!;
    final canvas = colors.backgroundPrimary;
    final inputSurface = _opaqueOn(appearance.inputSurfaceColor(context), canvas);
    final inputText = context.adaptiveForegroundOn(inputSurface);
    final chrome = _opaqueOn(appearance.chromeSurfaceColor(context), canvas);

    return SizedBox(
      height: 228,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: appearance.buildFullScreenDecoration(context),
              ),
              ColoredBox(color: canvas.withValues(alpha: 0.28)),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: _PreviewBubble(
                        text: t.translate('chat_appearance_preview_hello'),
                        isSender: true,
                        appearance: appearance,
                        canvas: canvas,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: chrome,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: colors.borderSubtle),
                        ),
                        child: Text(
                          t.translate('today'),
                          style: context.appTextStyles.caption.copyWith(
                            color: context.adaptiveForegroundOn(chrome),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _PreviewBubble(
                        text: t.translate('chat_appearance_preview_reply'),
                        isSender: false,
                        appearance: appearance,
                        canvas: canvas,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: inputSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: context.adaptiveBorderOn(inputSurface),
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          t.translate('chat_appearance_preview_input'),
                          style: context.appTextStyles.bodySm.copyWith(
                            color: inputText.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewBubble extends StatelessWidget {
  final String text;
  final bool isSender;
  final ChatAppearanceData appearance;
  final Color canvas;

  const _PreviewBubble({
    required this.text,
    required this.isSender,
    required this.appearance,
    required this.canvas,
  });

  @override
  Widget build(BuildContext context) {
    final rawBg = isSender
        ? appearance.senderBubbleColor(context)
        : appearance.receiverBubbleColor(context);
    final bg = Color.alphaBlend(rawBg, canvas);
    final useLightText = bg.computeLuminance() < 0.45;
    final fg = useLightText ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: appearance.bubbleRadius(isSender),
        border: Border.all(
          color: appearance.borderColor(context, isSender),
        ),
      ),
      child: Text(
        text,
        style: context.appTextStyles.bodyMd.copyWith(
          color: fg,
          fontSize: appearance.scaledFont(13),
          fontWeight: appearance.messageFontWeight,
        ),
      ),
    );
  }
}
