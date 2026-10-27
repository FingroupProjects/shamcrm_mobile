import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/apartment_room_layout_view.dart';
import 'package:flutter/material.dart';

/// Floating docked bottom card shown when an apartment is selected in Chessboard 2.0.
/// Provides instant access to unit stats, architectural room layout plan,
/// and fast actions without covering the entire screen.
class ApartmentQuickDockV2 extends StatefulWidget {
  final Apartment apartment;
  final VoidCallback onClose;
  final VoidCallback onOpenDetail;
  final VoidCallback onToggleReserve;
  final VoidCallback onCreateOrder;

  const ApartmentQuickDockV2({
    super.key,
    required this.apartment,
    required this.onClose,
    required this.onOpenDetail,
    required this.onToggleReserve,
    required this.onCreateOrder,
  });

  @override
  State<ApartmentQuickDockV2> createState() => _ApartmentQuickDockV2State();
}

class _ApartmentQuickDockV2State extends State<ApartmentQuickDockV2> {
  bool _showLayout = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final apartment = widget.apartment;
    final status = apartment.status;
    final priceStr = _formatPriceFull(apartment.totalPrice);
    final roomsLabel = apartment.rooms == 0 ? 'Студия' : '${apartment.rooms}-комн.';

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status.color.withValues(alpha: 0.45),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: status.color.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Unit info, price & close button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Status colored icon badge
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: status.bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: status.color.withValues(alpha: 0.5)),
                ),
                child: Center(
                  child: Icon(
                    status.icon,
                    size: 20,
                    color: status.color,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Title and specs
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '№ ${apartment.number}',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w800,
                            fontSize: 16.5,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: status.color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status.labelRu,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                              color: status.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${apartment.floor} этаж · $roomsLabel · ${apartment.totalArea.toStringAsFixed(1)} м²',
                      style: TextStyle(
                        fontFamily: 'Golos',
                        fontSize: 11.5,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$priceStr \$',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    '\$${apartment.pricePerSqm.toStringAsFixed(0)} / м²',
                    style: TextStyle(
                      fontFamily: 'Golos',
                      fontSize: 10.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),

              // Close button
              GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: colors.iconSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Collapsible Plan & Layout Scheme Section
          GestureDetector(
            onTap: () => setState(() => _showLayout = !_showLayout),
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.architecture_rounded,
                      size: 15,
                      color: colors.buttonPrimaryBg,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Планировка комнат',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Icon(
                  _showLayout
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: colors.iconSecondary,
                ),
              ],
            ),
          ),

          if (_showLayout) ...[
            const SizedBox(height: 6),
            ApartmentRoomLayoutView(
              apartment: apartment,
              compact: true,
              onTap: widget.onOpenDetail,
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Action Buttons Row
          Row(
            children: [
              // Reserve / Unreserve button
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onToggleReserve,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(
                      color: apartment.status == ApartmentStatus.reserved
                          ? colors.error
                          : colors.buttonPrimaryBg,
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    apartment.status == ApartmentStatus.reserved
                        ? 'Снять резерв'
                        : 'В резерв',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: apartment.status == ApartmentStatus.reserved
                          ? colors.error
                          : colors.buttonPrimaryBg,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Create Order
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onCreateOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.buttonPrimaryBg,
                    foregroundColor: colors.buttonPrimaryFg,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_shopping_cart_rounded, size: 14),
                      SizedBox(width: 5),
                      Text(
                        'Заказ',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Open Full Detail Sheet
              OutlinedButton(
                onPressed: widget.onOpenDetail,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  side: BorderSide(
                    color: colors.borderSubtle.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Паспорт',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: colors.iconSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatPriceFull(double price) {
    final intPrice = price.round();
    final s = intPrice.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}
