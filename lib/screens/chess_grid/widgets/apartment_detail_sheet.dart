import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:flutter/material.dart';

class ApartmentDetailSheet extends StatelessWidget {
  final Apartment apartment;
  final VoidCallback onCreateOrder;
  final VoidCallback onToggleReserve;
  final VoidCallback? onEdit;

  const ApartmentDetailSheet({
    super.key,
    required this.apartment,
    required this.onCreateOrder,
    required this.onToggleReserve,
    this.onEdit,
  });

  static Future<void> show({
    required BuildContext context,
    required Apartment apartment,
    required VoidCallback onCreateOrder,
    required VoidCallback onToggleReserve,
    VoidCallback? onEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ApartmentDetailSheet(
        apartment: apartment,
        onCreateOrder: onCreateOrder,
        onToggleReserve: onToggleReserve,
        onEdit: onEdit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isAvailable = apartment.status == ApartmentStatus.available;
    final statusColor = apartment.status.color;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Scrollable body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Title & Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Квартира № ${apartment.number}',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${apartment.buildingName} · ${apartment.floor} этаж · Подъезд ${apartment.entrance}',
                            style: TextStyle(
                              fontFamily: 'Golos',
                              fontSize: 13,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: apartment.status.bgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              apartment.status.labelRu,
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Price card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.borderSubtle.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Общая стоимость',
                              style: TextStyle(
                                fontFamily: 'Golos',
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${apartment.totalPrice.toStringAsFixed(0)} \$',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                color: colors.buttonPrimaryBg,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Цена за м²',
                              style: TextStyle(
                                fontFamily: 'Golos',
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${apartment.pricePerSqm.toStringAsFixed(0)} \$/м²',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Specifications Section (Lead details style)
                  Text(
                    'Параметры квартиры',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: colors.surfacePrimary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.6)),
                    ),
                    child: Column(
                      children: [
                        _buildParamRow(context, 'Комнат', apartment.rooms == 0 ? 'Студия' : '${apartment.rooms}-комнатная'),
                        _buildDivider(colors),
                        _buildParamRow(context, 'Тип отделки', apartment.type),
                        _buildDivider(colors),
                        _buildParamRow(context, 'Общая площадь', '${apartment.totalArea} м²'),
                        _buildDivider(colors),
                        _buildParamRow(context, 'Жилая площадь', '${apartment.livingArea} м²'),
                        _buildDivider(colors),
                        _buildParamRow(context, 'Площадь кухни', '${apartment.kitchenArea} м²'),
                        _buildDivider(colors),
                        _buildParamRow(
                          context,
                          'Броней в этом месяце',
                          '${apartment.bookingCountMonth} из ${ChessGridController.instance.monthlyBookingLimit}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Create Order Button (Strictly available only for "Свободно")
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isAvailable
                          ? () {
                              Navigator.pop(context);
                              onCreateOrder();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.buttonPrimaryBg,
                        foregroundColor: colors.buttonPrimaryFg,
                        disabledBackgroundColor: colors.borderSubtle,
                        disabledForegroundColor: colors.textMuted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: isAvailable ? 2 : 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_shopping_cart_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isAvailable ? 'Оформить бронь / заказ' : 'Заказ недоступен (не свободно)',
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Reserve toggle
                  if (apartment.status == ApartmentStatus.available ||
                      apartment.status == ApartmentStatus.reserved) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onToggleReserve();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.textPrimary,
                          side: BorderSide(color: colors.borderSubtle),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          apartment.status == ApartmentStatus.reserved
                              ? 'Снять с резерва'
                              : 'Поставить в резерв',
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamRow(BuildContext context, String label, String value) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Golos',
              fontSize: 13.5,
              color: colors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(dynamic colors) {
    return Divider(height: 1, color: colors.borderSubtle.withValues(alpha: 0.5));
  }
}
