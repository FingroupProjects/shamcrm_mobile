import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';

String colorToHex(Color color, {bool leadingHashSign = true}) {
  final hex = color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
  return leadingHashSign ? '#$hex' : hex;
}

Color hexToColor(String? hexString, {Color defaultColor = const Color(0xFF3B82F6)}) {
  if (hexString == null) return defaultColor;
  var hex = hexString.trim().replaceAll('#', '');
  if (hex.isEmpty) return defaultColor;
  if (hex.length == 3) {
    hex = hex.split('').map((c) => '$c$c').join();
  }
  if (hex.length == 4) {
    hex = '${hex}00';
  }
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  if (hex.length == 8) {
    final val = int.tryParse(hex, radix: 16);
    if (val != null) return Color(val);
  }
  return defaultColor;
}

class StatusColorField extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;
  final String label;

  const StatusColorField({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
    this.label = 'Цвет статуса',
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hexString = colorToHex(selectedColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            final picked = await StatusColorPickerDialog.show(
              context,
              initialColor: selectedColor,
            );
            if (picked != null) {
              onColorChanged(picked);
            }
          },
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: colors.fieldBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colors.borderSubtle.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: colors.textPrimary.withValues(alpha: 0.15),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: selectedColor.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  hexString,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.palette_outlined,
                  size: 20,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class StatusColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const StatusColorPickerDialog({
    super.key,
    required this.initialColor,
  });

  static Future<Color?> show(BuildContext context, {required Color initialColor}) {
    return showDialog<Color>(
      context: context,
      builder: (context) => StatusColorPickerDialog(initialColor: initialColor),
    );
  }

  @override
  State<StatusColorPickerDialog> createState() => _StatusColorPickerDialogState();
}

class _StatusColorPickerDialogState extends State<StatusColorPickerDialog> {
  late double _hue;
  late double _saturation;
  late double _value;
  late Color _currentColor;

  static const List<String> _presetHexColors = [
    '#EE9191',
    '#EF4444',
    '#F97316',
    '#F59E0B',
    '#10B981',
    '#06B6D4',
    '#3B82F6',
    '#8B5CF6',
    '#EC4899',
    '#64748B',
  ];

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initialColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
    _currentColor = widget.initialColor;
  }

  void _updateSatVal(Offset localPosition, Size size) {
    final s = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final v = (1.0 - (localPosition.dy / size.height)).clamp(0.0, 1.0);
    setState(() {
      _saturation = s;
      _value = v;
      _currentColor = HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
    });
  }

  void _updateHue(Offset localPosition, double width) {
    final h = ((localPosition.dx / width).clamp(0.0, 1.0)) * 360.0;
    setState(() {
      _hue = h.clamp(0.0, 360.0);
      _currentColor = HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
    });
  }

  void _applyPreset(String hex) {
    final c = hexToColor(hex);
    final hsv = HSVColor.fromColor(c);
    setState(() {
      _hue = hsv.hue;
      _saturation = hsv.saturation;
      _value = hsv.value;
      _currentColor = c;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.borderSubtle.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Выбор цвета',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 22, color: colors.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 2D Saturation / Value Gradient Box
            LayoutBuilder(
              builder: (context, constraints) {
                final boxWidth = constraints.maxWidth;
                const boxHeight = 150.0;
                final pureHueColor = HSVColor.fromAHSV(1.0, _hue, 1.0, 1.0).toColor();
                final thumbX = (_saturation * boxWidth).clamp(0.0, boxWidth);
                final thumbY = ((1.0 - _value) * boxHeight).clamp(0.0, boxHeight);

                return GestureDetector(
                  onPanDown: (details) =>
                      _updateSatVal(details.localPosition, Size(boxWidth, boxHeight)),
                  onPanUpdate: (details) =>
                      _updateSatVal(details.localPosition, Size(boxWidth, boxHeight)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: boxWidth,
                      height: boxHeight,
                      child: Stack(
                        children: [
                          Container(color: pureHueColor),
                          // White horizontal gradient
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Colors.white, Colors.transparent],
                              ),
                            ),
                          ),
                          // Black vertical gradient
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black],
                              ),
                            ),
                          ),
                          // Draggable thumb indicator
                          Positioned(
                            left: thumbX - 10,
                            top: thumbY - 10,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentColor,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black45,
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // Color preview + Rainbow Hue slider
            LayoutBuilder(
              builder: (context, constraints) {
                final previewSize = 34.0;
                final sliderWidth = constraints.maxWidth - previewSize - 12;
                final hueThumbX =
                    ((_hue / 360.0) * sliderWidth).clamp(0.0, sliderWidth);

                return Row(
                  children: [
                    Container(
                      width: previewSize,
                      height: previewSize,
                      decoration: BoxDecoration(
                        color: _currentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _currentColor.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onPanDown: (details) =>
                            _updateHue(details.localPosition, sliderWidth),
                        onPanUpdate: (details) =>
                            _updateHue(details.localPosition, sliderWidth),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 20,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFFF0000),
                                  Color(0xFFFFFF00),
                                  Color(0xFF00FF00),
                                  Color(0xFF00FFFF),
                                  Color(0xFF0000FF),
                                  Color(0xFFFF00FF),
                                  Color(0xFFFF0000),
                                ],
                              ),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  left: (hueThumbX - 8).clamp(0.0, sliderWidth - 16),
                                  top: 2,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(
                                        color: Colors.black26,
                                        width: 1,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black38,
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),

            // RGB and Hex values display
            Row(
              children: [
                _buildChannelBox('R', (((_currentColor.toARGB32() >> 16) & 0xFF)).toString(), colors),
                const SizedBox(width: 8),
                _buildChannelBox('G', (((_currentColor.toARGB32() >> 8) & 0xFF)).toString(), colors),
                const SizedBox(width: 8),
                _buildChannelBox('B', ((_currentColor.toARGB32() & 0xFF)).toString(), colors),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.fieldBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors.borderSubtle.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      colorToHex(_currentColor),
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Presets palette
            Text(
              'Популярные цвета:',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetHexColors.map((hex) {
                final c = hexToColor(hex);
                final isSelected = colorToHex(_currentColor) == hex;
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _applyPreset(hex),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.black12,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: c.withValues(alpha: 0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Buttons: Cancel & Select
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: colors.borderSubtle.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: Text(
                      'Отмена',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_currentColor),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.buttonPrimaryBg,
                      foregroundColor: colors.buttonPrimaryFg,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Выбрать',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _buildChannelBox(String label, String value, dynamic colors) {
    return Expanded(
      flex: 2,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: colors.fieldBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colors.borderSubtle.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
