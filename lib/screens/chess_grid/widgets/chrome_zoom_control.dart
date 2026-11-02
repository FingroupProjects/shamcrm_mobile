import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_zoom_level.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Chrome-style Zoom Pill Control `[ - ]  100%  [ + ]`.
/// - Tap `[-]`: zooms out to the next smaller scale level.
/// - Tap `[+]`: zooms in to the next larger scale level.
/// - Tap center percentage: quickly toggles between the TWO default modes (100% ⇄ 50%).
/// - Long press center: opens [ChromeZoomSheet] with all 4 scale presets.
class ChromeZoomControl extends StatelessWidget {
  final ChessZoomLevel currentLevel;
  final ValueChanged<ChessZoomLevel> onChanged;
  final bool isCompact;

  const ChromeZoomControl({
    super.key,
    required this.currentLevel,
    required this.onChanged,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isCustomNonDefault = !currentLevel.isDefaultPreset;

    return Container(
      height: 38,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 1 : 2, vertical: 2),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCustomNonDefault
              ? colors.buttonPrimaryBg.withValues(alpha: 0.8)
              : colors.borderSubtle.withValues(alpha: 0.5),
          width: isCustomNonDefault ? 1.4 : 1.0,
        ),
        boxShadow: isCustomNonDefault
            ? [
                BoxShadow(
                  color: colors.buttonPrimaryBg.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Zoom Out Button [-]
          _buildStepButton(
            icon: Icons.remove_rounded,
            enabled: currentLevel.canZoomOut,
            colors: colors,
            tooltip: 'Уменьшить',
            onTap: () {
              if (currentLevel.canZoomOut) {
                HapticFeedback.lightImpact();
                onChanged(currentLevel.nextZoomOut);
              }
            },
          ),

          // Center Percentage Pill (Tap: toggle 2 defaults; Long press: open sheet)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(currentLevel.toggleDefault);
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              ChromeZoomSheet.show(
                context: context,
                currentLevel: currentLevel,
                onSelected: onChanged,
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 5 : 8, vertical: 4),
              decoration: BoxDecoration(
                color: currentLevel == ChessZoomLevel.micro50
                    ? colors.buttonPrimaryBg.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    currentLevel == ChessZoomLevel.micro50
                        ? Icons.grid_view_rounded
                        : Icons.zoom_in_rounded,
                    size: isCompact ? 13 : 15,
                    color: currentLevel == ChessZoomLevel.micro50
                        ? colors.buttonPrimaryBg
                        : colors.textSecondary,
                  ),
                  SizedBox(width: isCompact ? 2 : 4),
                  Text(
                    currentLevel.label,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: isCompact ? 11 : 12.5,
                      color: currentLevel == ChessZoomLevel.micro50
                          ? colors.buttonPrimaryBg
                          : colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Zoom In Button [+]
          _buildStepButton(
            icon: Icons.add_rounded,
            enabled: currentLevel.canZoomIn,
            colors: colors,
            tooltip: 'Увеличить',
            onTap: () {
              if (currentLevel.canZoomIn) {
                HapticFeedback.lightImpact();
                onChanged(currentLevel.nextZoomIn);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required bool enabled,
    required dynamic colors,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: isCompact ? 22 : 28,
        height: 32,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: isCompact ? 15 : 17,
          color: enabled
              ? colors.textPrimary
              : colors.textSecondary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

/// Bottom Sheet showing all Chrome-style scale presets with descriptions and quick reset.
class ChromeZoomSheet extends StatelessWidget {
  final ChessZoomLevel currentLevel;
  final ValueChanged<ChessZoomLevel> onSelected;

  const ChromeZoomSheet({
    super.key,
    required this.currentLevel,
    required this.onSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required ChessZoomLevel currentLevel,
    required ValueChanged<ChessZoomLevel> onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChromeZoomSheet(
        currentLevel: currentLevel,
        onSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: colors.borderSubtle,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.buttonPrimaryBg.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.aspect_ratio_rounded,
                  color: colors.buttonPrimaryBg,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Масштаб шахматки',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Выберите размер ячеек или переключайтесь в 1 тап',
                      style: TextStyle(
                        fontFamily: 'Golos',
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // List of Zoom Levels
          for (final level in ChessZoomLevel.values)
            _buildLevelTile(context, level, colors),

          const SizedBox(height: 14),

          // Reset to 100% button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onSelected(ChessZoomLevel.standard100);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Сбросить масштаб (100% Стандарт)',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.buttonPrimaryBg,
                side: BorderSide(
                  color: colors.buttonPrimaryBg.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelTile(
    BuildContext context,
    ChessZoomLevel level,
    dynamic colors,
  ) {
    final isSelected = currentLevel == level;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected
            ? colors.buttonPrimaryBg.withValues(alpha: 0.1)
            : colors.surfaceElevated.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            HapticFeedback.selectionClick();
            onSelected(level);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Radio indicator
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? colors.buttonPrimaryBg
                          : colors.borderSubtle,
                      width: isSelected ? 6 : 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Percentage Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.buttonPrimaryBg
                        : colors.surfacePrimary,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? colors.buttonPrimaryBg
                          : colors.borderSubtle,
                    ),
                  ),
                  child: Text(
                    level.label,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: isSelected ? Colors.white : colors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            level.title,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isSelected
                                  ? colors.buttonPrimaryBg
                                  : colors.textPrimary,
                            ),
                          ),
                          if (level.isDefaultPreset) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: colors.buttonPrimaryBg.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                level == ChessZoomLevel.standard100
                                    ? 'По умолч.'
                                    : 'Быстрый',
                                style: TextStyle(
                                  fontFamily: 'Golos',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: colors.buttonPrimaryBg,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        level.subtitle,
                        style: TextStyle(
                          fontFamily: 'Golos',
                          fontSize: 11.5,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

