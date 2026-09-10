import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';

class FullColorWheelDialog extends StatefulWidget {
  final Color initialColor;
  final String title;

  const FullColorWheelDialog({
    super.key,
    this.initialColor = const Color(0xFF0EA5E9),
    this.title = '',
  });

  static Future<Color?> show(BuildContext context, {Color? initialColor}) {
    return showModalBottomSheet<Color>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FullColorWheelDialog(
        initialColor: initialColor ?? const Color(0xFF0EA5E9),
      ),
    );
  }

  @override
  State<FullColorWheelDialog> createState() => _FullColorWheelDialogState();
}

class _FullColorWheelDialogState extends State<FullColorWheelDialog> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  String get _hexCode =>
      '#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final titleText = widget.title.isNotEmpty
        ? widget.title
        : t.translate('appearance_palette');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final wheelDiameter = (size.width - 64).clamp(220.0, 320.0);
    final foreground =
        ThemeData.estimateBrightnessForColor(_selectedColor) == Brightness.dark
            ? Colors.white
            : Colors.black;

    return SafeArea(
      top: false,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.12),
                blurRadius: 28,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        titleText,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _hexCode,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  t.translate('appearance_color_wheel_hint'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Theme(
                  data: theme.copyWith(
                    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  child: ColorPicker(
                    color: _selectedColor,
                    onColorChanged: (Color color) {
                      setState(() => _selectedColor = color);
                    },
                    pickersEnabled: const <ColorPickerType, bool>{
                      ColorPickerType.wheel: true,
                    },
                    pickerTypeLabels: <ColorPickerType, String>{
                      ColorPickerType.primary:
                          t.translate('appearance_color_primary'),
                      ColorPickerType.accent:
                          t.translate('appearance_color_accent'),
                      ColorPickerType.wheel:
                          t.translate('appearance_color_wheel'),
                    },
                    enableShadesSelection: false,
                    enableTonalPalette: true,
                    showColorCode: true,
                    colorCodeHasColor: true,
                    colorCodeReadOnly: false,
                    showMaterialName: false,
                    showColorName: false,
                    width: 40,
                    height: 40,
                    borderRadius: 12,
                    hasBorder: true,
                    borderColor: theme.dividerColor,
                    wheelDiameter: wheelDiameter,
                    wheelWidth: 24,
                    wheelSquarePadding: 6,
                    wheelSquareBorderRadius: 16,
                    wheelHasBorder: true,
                    enableTooltips: false,
                    columnSpacing: 16,
                    spacing: 8,
                    runSpacing: 8,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(t.translate('cancel')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pop(_selectedColor),
                        style: FilledButton.styleFrom(
                          backgroundColor: _selectedColor,
                          foregroundColor: foreground,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          t.translate('apply'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
