import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/order_create_dialog.dart';
import 'package:flutter/material.dart';

class ChessGridCatalogView extends StatelessWidget {
  final ChessGridController controller;
  final ValueChanged<Apartment> onSelectApartment;

  const ChessGridCatalogView({
    super.key,
    required this.controller,
    required this.onSelectApartment,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final apartments = controller.filteredApartments;

    if (apartments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: colors.iconSecondary),
              const SizedBox(height: 12),
              Text(
                'Нет квартир по выбранным фильтрам',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Попробуйте сбросить фильтры или расширить диапазон цен и площади',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Golos',
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => controller.resetFilter(),
                child: const Text('Сбросить фильтры'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: apartments.length,
      itemBuilder: (context, index) {
        final apt = apartments[index];
        final isAvailable = apt.status == ApartmentStatus.available;
        final statusColor = apt.status.color;

        return GestureDetector(
          onTap: () => onSelectApartment(apt),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: colors.surfacePrimary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card header
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: apt.status.bgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  apt.status.labelRu,
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
                          const SizedBox(width: 8),
                          Text(
                            '№ ${apt.number}',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${apt.totalPrice.toStringAsFixed(0)} \$',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: colors.buttonPrimaryBg,
                        ),
                      ),
                    ],
                  ),
                ),

                // Location info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    '${apt.buildingName}, подъезд ${apt.entrance}, ${apt.floor} этаж · ${apt.rooms == 0 ? "Студия" : "${apt.rooms}-комнатная"} (${apt.type})',
                    style: TextStyle(
                      fontFamily: 'Golos',
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Specs chips row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      _buildChip(context, Icons.straighten_rounded, '${apt.totalArea} м²'),
                      const SizedBox(width: 8),
                      _buildChip(context, Icons.meeting_room_outlined, '${apt.livingArea} м² жил.'),
                      const SizedBox(width: 8),
                      _buildChip(context, Icons.kitchen_outlined, '${apt.kitchenArea} м² кух.'),
                      const Spacer(),
                      Text(
                        '${apt.pricePerSqm.toStringAsFixed(0)} \$/м²',
                        style: TextStyle(
                          fontFamily: 'Golos',
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),

                // Action bottom row
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAvailable
                            ? 'Свободно для сделки'
                            : 'Бронь/Продано: заказ недоступен',
                        style: TextStyle(
                          fontFamily: 'Golos',
                          fontSize: 11,
                          color: isAvailable ? colors.success : colors.textMuted,
                          fontStyle: isAvailable ? FontStyle.normal : FontStyle.italic,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: isAvailable
                            ? () => OrderCreateDialog.show(context: context, apartment: apt)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.buttonPrimaryBg,
                          foregroundColor: colors.buttonPrimaryFg,
                          disabledBackgroundColor: colors.borderSubtle,
                          disabledForegroundColor: colors.textMuted,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(BuildContext context, IconData icon, String text) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colors.iconSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Golos',
              fontWeight: FontWeight.w500,
              fontSize: 10.5,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

