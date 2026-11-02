import 'dart:ui';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/scene_3d_state.dart';
import 'package:flutter/material.dart';

class Scene3DHudControls extends StatelessWidget {
  final Scene3DState state;
  final VoidCallback onResetCamera;
  final VoidCallback onToggleAutoRotate;
  final VoidCallback onToggleNightMode;
  final VoidCallback? onResetBuildingPositions;
  final VoidCallback? onOpenGoogleMap;

  const Scene3DHudControls({
    super.key,
    required this.state,
    required this.onResetCamera,
    required this.onToggleAutoRotate,
    required this.onToggleNightMode,
    this.onResetBuildingPositions,
    this.onOpenGoogleMap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF202B33).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Day / Night Mode Switcher
              IconButton(
                onPressed: onToggleNightMode,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) =>
                      RotationTransition(turns: anim, child: child),
                  child: Icon(
                    state.isNightMode
                        ? Icons.nightlight_round
                        : Icons.wb_sunny_rounded,
                    key: ValueKey(state.isNightMode),
                    size: 20,
                  ),
                ),
                color: state.isNightMode
                    ? const Color(0xFFFFD166)
                    : const Color(0xFFFFA000),
                tooltip: state.isNightMode
                    ? 'Переключить на день'
                    : 'Ночной режим с огнями',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 2),

              // Reset Camera
              IconButton(
                onPressed: onResetCamera,
                icon: const Icon(Icons.center_focus_strong_rounded, size: 20),
                color: Colors.white,
                tooltip: 'Сброс камеры',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 2),

              // Auto-Rotate 360
              IconButton(
                onPressed: onToggleAutoRotate,
                icon: Icon(
                  state.isAutoRotating
                      ? Icons.pause_circle_filled_rounded
                      : Icons.rotate_right_rounded,
                  size: 20,
                ),
                color: state.isAutoRotating
                    ? const Color(0xFF2979FF)
                    : Colors.white,
                tooltip: 'Авто-облет 360°',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),

              // Google Satellite Map (Real Satellite & Complex Footprint)
              if (onOpenGoogleMap != null) ...[
                const SizedBox(height: 2),
                IconButton(
                  onPressed: onOpenGoogleMap,
                  icon: const Icon(Icons.satellite_alt_rounded, size: 20),
                  color: const Color(0xFF64B5F6),
                  tooltip: 'Спутниковая карта Google',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ],

              // Reset Custom Building positions button (if buildings were moved)
              if (state.level == Scene3DLevel.complex &&
                  state.customBuildingOffsets.isNotEmpty &&
                  onResetBuildingPositions != null) ...[
                const SizedBox(height: 2),
                IconButton(
                  onPressed: onResetBuildingPositions,
                  icon: const Icon(Icons.restore_rounded, size: 20),
                  color: const Color(0xFF2ECC71),
                  tooltip: 'Сбросить расстановку корпусов',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Action button to drill down to next level (e.g. "Смотреть этажи", "3D план этажа")
class Scene3DNextLevelButton extends StatelessWidget {
  final Scene3DState state;
  final VoidCallback onNextLevel;

  const Scene3DNextLevelButton({
    super.key,
    required this.state,
    required this.onNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    if (state.level == Scene3DLevel.floor) return const SizedBox.shrink();

    final label = _nextLevelLabel(state.level);
    if (label.isEmpty) return const SizedBox.shrink();

    return ElevatedButton.icon(
      onPressed: onNextLevel,
      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2979FF),
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black45,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  String _nextLevelLabel(Scene3DLevel level) {
    switch (level) {
      case Scene3DLevel.complex:
        return 'Выбрать корпус';
      case Scene3DLevel.building:
        return 'Смотреть этажи';
      case Scene3DLevel.section:
        return '3D план этажа';
      case Scene3DLevel.floor:
        return '';
    }
  }
}

/// Status Legend Widget (compact glass panel)
class Scene3DStatusLegend extends StatelessWidget {
  final bool isNightMode;

  const Scene3DStatusLegend({
    super.key,
    this.isNightMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF202B33).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _legendDot(const Color(0xFF2ECC71), 'Свободно'),
              const SizedBox(width: 6),
              _legendDot(const Color(0xFFF39C12), 'Бронь'),
              const SizedBox(width: 6),
              _legendDot(
                isNightMode ? const Color(0xFFFFD166) : const Color(0xFF95A5A6),
                'Продано',
              ),
              const SizedBox(width: 6),
              _legendDot(const Color(0xFF1ABC9C), 'Резерв'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7.5,
          height: 7.5,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            fontFamily: 'Gilroy',
          ),
        ),
      ],
    );
  }
}
