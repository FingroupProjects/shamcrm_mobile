import 'dart:ui';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/scene_3d_state.dart';
import 'package:flutter/material.dart';

class Scene3DBreadcrumbs extends StatelessWidget {
  final Scene3DState state;
  final ResidentialComplex complex;
  final VoidCallback onBack;
  final ValueChanged<Scene3DLevel> onSelectLevel;

  const Scene3DBreadcrumbs({
    super.key,
    required this.state,
    required this.complex,
    required this.onBack,
    required this.onSelectLevel,
  });

  @override
  Widget build(BuildContext context) {
    final building = state.selectedBuilding ??
        (complex.buildings.isNotEmpty ? complex.buildings.first : null);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF202B33).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Back Button (if not on root level)
                if (state.level != Scene3DLevel.complex) ...[
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Level 1: Complex
                _buildCrumb(
                  title: complex.name,
                  isActive: state.level == Scene3DLevel.complex,
                  onTap: () => onSelectLevel(Scene3DLevel.complex),
                ),

                // Level 2: Building
                if (state.level.index >= Scene3DLevel.building.index && building != null) ...[
                  _buildSeparator(),
                  _buildCrumb(
                    title: building.name,
                    isActive: state.level == Scene3DLevel.building,
                    onTap: () => onSelectLevel(Scene3DLevel.building),
                  ),
                ],

                // Level 3: Entrance
                if (state.level.index >= Scene3DLevel.section.index) ...[
                  _buildSeparator(),
                  _buildCrumb(
                    title: 'Подъезд ${state.selectedEntrance}',
                    isActive: state.level == Scene3DLevel.section,
                    onTap: () => onSelectLevel(Scene3DLevel.section),
                  ),
                ],

                // Level 4: Floor
                if (state.level.index >= Scene3DLevel.floor.index) ...[
                  _buildSeparator(),
                  _buildCrumb(
                    title: 'Этаж ${state.selectedFloor}',
                    isActive: state.level == Scene3DLevel.floor,
                    onTap: () => onSelectLevel(Scene3DLevel.floor),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        Icons.chevron_right_rounded,
        size: 16,
        color: Colors.white.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildCrumb({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2979FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}

