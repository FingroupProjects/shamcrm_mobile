import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/utils/chess_grid_localizations.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/controllers/chess_grid_v2_controller.dart';
import 'package:flutter/material.dart';

/// Quick selector bottom sheet for Building & Entrance.
/// Allows fast switching without cluttering the main screen header.
class SectionBuildingSheetV2 extends StatelessWidget {
  final ChessGridV2Controller controller;

  const SectionBuildingSheetV2({super.key, required this.controller});

  static Future<void> show({
    required BuildContext context,
    required ChessGridV2Controller controller,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SectionBuildingSheetV2(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final complex = controller.complex;
    final currentBuildingKey = controller.selectedBuildingKey;
    final currentEntrance = controller.filter.entrance;

    final building = controller.currentBuilding ?? (complex.buildings.isNotEmpty ? complex.buildings.first : null);

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
          const SizedBox(height: 14),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('chess_grid_section_and_entrance', fallback: 'Секция и подъезд'),
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    complex.name,
                    style: TextStyle(
                      fontFamily: 'Golos',
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 22),
                color: colors.iconSecondary,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Buildings Section
          Text(
            context.tr('chess_grid_building_block', fallback: 'Корпус / Блок'),
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: complex.buildings.map((b) {
              final isSelected = b.key == currentBuildingKey;
              final bApts = controller.apartments.where((a) => a.buildingKey == b.key).length;

              return GestureDetector(
                onTap: () {
                  controller.selectBuilding(b.key);
                  // If entrance exceeds new building's count, reset to 0
                  if (controller.filter.entrance > b.entranceCount) {
                    controller.setFilter(controller.filter.copyWith(
                      buildingKey: b.key,
                      entrance: 0,
                    ));
                  }
                  Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.buttonPrimaryBg
                        : colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? colors.buttonPrimaryBg
                          : colors.borderSubtle.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colors.buttonPrimaryBg.withValues(alpha: 0.28),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.domain_rounded,
                        size: 16,
                        color: isSelected ? colors.buttonPrimaryFg : colors.iconSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        b.name,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 13.5,
                          color: isSelected ? colors.buttonPrimaryFg : colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '($bApts)',
                        style: TextStyle(
                          fontFamily: 'Golos',
                          fontSize: 11,
                          color: isSelected
                              ? colors.buttonPrimaryFg.withValues(alpha: 0.8)
                              : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Entrances Section
          Text(
            context.tr('chess_grid_entrance', fallback: 'Подъезд'),
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildEntrancePill(
                context: context,
                title: context.tr('chess_grid_all_entrances', fallback: 'Все подъезды'),
                isSelected: currentEntrance == 0,
                onTap: () {
                  controller.setFilter(controller.filter.copyWith(entrance: 0));
                  Navigator.pop(context);
                },
              ),
              if (building != null)
                for (int e = 1; e <= building.entranceCount; e++)
                  _buildEntrancePill(
                  context: context,
                  title: '${context.tr('chess_grid_entrance', fallback: 'Подъезд')} $e',
                  isSelected: currentEntrance == e,
                  onTap: () {
                    controller.setFilter(controller.filter.copyWith(entrance: e));
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEntrancePill({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.buttonPrimaryBg : colors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? colors.buttonPrimaryBg
                : colors.borderSubtle.withValues(alpha: 0.6),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.buttonPrimaryBg.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
            color: isSelected ? colors.buttonPrimaryFg : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

