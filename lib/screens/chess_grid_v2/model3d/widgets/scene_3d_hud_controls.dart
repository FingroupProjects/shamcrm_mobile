import 'dart:ui';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/scene_3d_state.dart';
import 'package:flutter/material.dart';

class Scene3DHudControls extends StatelessWidget {
  final Scene3DState state;
  final VoidCallback onResetCamera;
  final VoidCallback onToggleAutoRotate;
  final VoidCallback onNextLevel;

  const Scene3DHudControls({
    super.key,
    required this.state,
    required this.onResetCamera,
    required this.onToggleAutoRotate,
    required this.onNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Camera Action Buttons
        ClipRRect(
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
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  // Auto-Rotate
                  IconButton(
                    onPressed: onToggleAutoRotate,
                    icon: Icon(
                      state.isAutoRotating ? Icons.pause_circle_filled_rounded : Icons.rotate_right_rounded,
                      size: 20,
                    ),
                    color: state.isAutoRotating ? const Color(0xFF2979FF) : Colors.white,
                    tooltip: 'Авто-облет 360°',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Action button to drill down to next level if available
        if (state.level != Scene3DLevel.floor)
          ElevatedButton.icon(
            onPressed: onNextLevel,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: Text(
              _nextLevelLabel(state.level),
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
              shadowColor: Colors.black38,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
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
  const Scene3DStatusLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF202B33).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _legendDot(const Color(0xFF2ECC71), 'Свободно'),
              const SizedBox(width: 8),
              _legendDot(const Color(0xFFF39C12), 'Бронь'),
              const SizedBox(width: 8),
              _legendDot(const Color(0xFF95A5A6), 'Продано'),
              const SizedBox(width: 8),
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
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Golos',
            fontSize: 10,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

