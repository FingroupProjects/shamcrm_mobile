import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/apartment_form_sheet.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/chess_grid_cell.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/order_create_dialog.dart';
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

                // Divider before Parking level (TZ Section 5 / Image 3)
                const SizedBox(height: 6),
                Container(
                  margin: const EdgeInsets.only(left: 52),
                  height: 1.5,
                  width: entrances.length * building.apartsPerFloor * 82.0,
                  color: colors.borderSubtle.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 6),

                // Floor -1: Parking spots row
                _buildParkingRow(context, building, entrances),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParkingRow(
    BuildContext context,
    Building building,
    List<int> entrances,
  ) {
    final colors = context.appColors;
    final spots = controller.parkingSpots.where((p) => p.buildingKey == building.key).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Parking level label
        SizedBox(
          width: 44,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-1 эт.',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  color: colors.textSecondary,
                ),
              ),
              Text(
                'Паркинг',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Golos',
                  fontWeight: FontWeight.w600,
                  fontSize: 8.5,
                  color: colors.buttonPrimaryBg,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Spots list horizontally aligned with the building width
        Row(
          children: [
            ...spots.map((spot) => _buildParkingCell(context, spot)),
            // Add parking button
            GestureDetector(
              onTap: () {
                ApartmentFormSheet.show(
                  context: context,
                  initialBuildingKey: building.key,
                  isParkingMode: true,
                );
              },
              child: Container(
                width: 78,
                height: 54,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colors.borderSubtle.withValues(alpha: 0.7),
                    style: BorderStyle.solid,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_parking_rounded, size: 14, color: colors.buttonPrimaryBg),
                      const SizedBox(width: 2),
                      Icon(Icons.add_rounded, size: 14, color: colors.iconSecondary),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParkingCell(BuildContext context, ParkingSpot spot) {
    final colors = context.appColors;
    final isAvailable = spot.status == ApartmentStatus.available;

    return GestureDetector(
      onTap: () {
        if (isAvailable) {
          OrderCreateDialog.show(context: context, parking: spot);
        } else {
          // Open edit or show status
          ApartmentFormSheet.show(
            context: context,
            existingParking: spot,
            isParkingMode: true,
          );
        }
      },
      child: Container(
        width: 78,
        height: 54,
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        decoration: BoxDecoration(
          color: spot.status.bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: spot.status.color.withValues(alpha: 0.6),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: spot.status.color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'P',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '№${spot.number}',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: spot.status.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${spot.area.toStringAsFixed(0)} м²',
                  style: TextStyle(
                    fontFamily: 'Golos',
                    fontSize: 9,
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  '${spot.price.toStringAsFixed(0)} \$',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
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

