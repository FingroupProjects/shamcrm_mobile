import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/chess_grid_cell.dart';
import 'package:flutter/material.dart';

class ChessGridMatrixView extends StatelessWidget {
  final ChessGridController controller;
  final ValueChanged<Apartment> onSelectApartment;
  final Function(String buildingKey, int entrance, int floor, int position) onAddEmptySlot;

  const ChessGridMatrixView({
    super.key,
    required this.controller,
    required this.onSelectApartment,
    required this.onAddEmptySlot,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final building = controller.currentBuilding;

    if (building == null) {
      return Center(
        child: Text(
          'Корпуса не найдены',
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 15,
            color: colors.textSecondary,
          ),
        ),
      );
    }

    final selectedEntrance = controller.filter.entrance;
    final entrances = selectedEntrance == 0
        ? List.generate(building.entranceCount, (i) => i + 1)
        : [selectedEntrance];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Entrance labels
                Row(
                  children: [
                    const SizedBox(width: 48), // Floor label width spacer
                    ...entrances.map((e) {
                      final width = building.apartsPerFloor * 82.0;
                      return Container(
                        width: width,
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colors.borderSubtle.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              'Подъезд $e',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 4),

                // Floor rows from top floor down to 1st floor
                for (int fl = building.floorCount; fl >= 1; fl--) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Floor label badge
                      SizedBox(
                        width: 44,
                        child: Text(
                          '$fl эт.',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Apartments per entrance
                      ...entrances.map((e) {
                        return Row(
                          children: [
                            for (int p = 0; p < building.apartsPerFloor; p++) ...[
                              _buildCellOrEmptySlot(
                                context: context,
                                buildingKey: building.key,
                                entrance: e,
                                floor: fl,
                                position: p,
                              ),
                            ],
                            const SizedBox(width: 6), // Spacer between entrances
                          ],
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 3),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCellOrEmptySlot({
    required BuildContext context,
    required String buildingKey,
    required int entrance,
    required int floor,
    required int position,
  }) {
    final colors = context.appColors;
    final apt = controller.apartments.where((a) =>
        a.buildingKey == buildingKey &&
        a.entrance == entrance &&
        a.floor == floor &&
        a.position == position).firstOrNull;

    if (apt != null) {
      final isMatch = controller.filter.matches(apt);
      final isSelected = controller.selectedApartment?.id == apt.id;

      return Opacity(
        opacity: isMatch ? 1.0 : 0.22,
        child: IgnorePointer(
          ignoring: !isMatch,
          child: ChessGridCell(
            apartment: apt,
            isSelected: isSelected,
            onTap: () => onSelectApartment(apt),
          ),
        ),
      );
    }

    // Empty slot: button to add apartment
    return GestureDetector(
      onTap: () => onAddEmptySlot(buildingKey, entrance, floor, position),
      child: Container(
        width: 78,
        height: 58,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: colors.surfaceElevated.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colors.borderSubtle.withValues(alpha: 0.7),
            style: BorderStyle.solid,
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.add_rounded,
            size: 20,
            color: colors.iconSecondary.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

