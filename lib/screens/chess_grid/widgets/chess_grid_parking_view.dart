import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/order_create_dialog.dart';
import 'package:flutter/material.dart';

class ChessGridParkingView extends StatelessWidget {
  final ChessGridController controller;
  final VoidCallback onAddParking;

  const ChessGridParkingView({
    super.key,
    required this.controller,
    required this.onAddParking,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final parkingSpots = controller.parkingSpots;

    return Column(
      children: [
        // Top summary & Add button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Парковочные места (${parkingSpots.length})',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: colors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: onAddParking,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Добавить место'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.buttonPrimaryBg,
                  foregroundColor: colors.buttonPrimaryFg,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Grid of parking spots
        Expanded(
          child: parkingSpots.isEmpty
              ? Center(
                  child: Text(
                    'Нет добавленных парковочных мест',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: parkingSpots.length,
                  itemBuilder: (context, index) {
                    final spot = parkingSpots[index];
                    return _buildParkingCard(context, spot);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildParkingCard(BuildContext context, ParkingSpot spot) {
    final colors = context.appColors;
    final statusColor = spot.status.color;
    final isAvailable = spot.status == ApartmentStatus.available;

    Apartment? linkedApt;
    if (spot.linkedApartmentId != null) {
      linkedApt = controller.findApartmentById(spot.linkedApartmentId);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.local_parking_rounded, size: 20, color: colors.buttonPrimaryBg),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Место ${spot.number}',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          '${spot.type} парковка · Корпус ${spot.buildingKey}',
                          style: TextStyle(
                            fontFamily: 'Golos',
                            fontSize: 11.5,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: spot.status.bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        spot.status.labelRu,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Specs & link
            Row(
              children: [
                Text(
                  'Площадь: ${spot.area} м²',
                  style: TextStyle(fontFamily: 'Golos', fontSize: 12, color: colors.textSecondary),
                ),
                const SizedBox(width: 16),
                if (linkedApt != null)
                  Expanded(
                    child: Text(
                      'Привязано: кв. № ${linkedApt.number}',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: colors.buttonPrimaryBg,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  Text(
                    'Без привязки',
                    style: TextStyle(fontFamily: 'Golos', fontSize: 11.5, color: colors.textMuted),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Price & Order Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${spot.price.toStringAsFixed(0)} \$',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: colors.textPrimary,
                  ),
                ),
                ElevatedButton(
                  onPressed: isAvailable
                      ? () => OrderCreateDialog.show(context: context, parking: spot)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.buttonPrimaryBg,
                    foregroundColor: colors.buttonPrimaryFg,
                    disabledBackgroundColor: colors.borderSubtle,
                    disabledForegroundColor: colors.textMuted,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: isAvailable ? 1 : 0,
                  ),
                  child: const Text(
                    'Создать заказ',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
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
}
