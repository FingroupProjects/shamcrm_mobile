import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Single apartment cell inside the chess grid matrix with comfortable mobile sizing.
class ChessGridCell extends StatelessWidget {
  final Apartment apartment;
  final bool isSelected;
  final VoidCallback onTap;

  const ChessGridCell({
    super.key,
    required this.apartment,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final statusColor = apartment.status.color;
    final bgColor = apartment.status.bgColor;

    final roomsLabel = apartment.rooms == 0 ? 'Ст' : '${apartment.rooms}к';
    final priceFormatted = _formatPrice(apartment.totalPrice);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 88,
        height: 70,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colors.textPrimary
                : statusColor.withValues(alpha: 0.65),
            width: isSelected ? 2.2 : 1.3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top row: Status indicator dot + Apartment number
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '№${apartment.number}',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: colors.textPrimary,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // Middle: Rooms & Total Area
            Text(
              '$roomsLabel · ${apartment.totalArea.toStringAsFixed(0)} м²',
              style: TextStyle(
                fontFamily: 'Golos',
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
                color: colors.textSecondary,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Bottom: Total Price badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                priceFormatted,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                  color: statusColor,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatPrice(double price) {
    if (price >= 1e6) {
      return '${(price / 1e6).toStringAsFixed(1)} млн \$';
    } else if (price >= 1e3) {
      return '${(price / 1e3).toStringAsFixed(0)} тыс \$';
    }
    return '${price.toStringAsFixed(0)} \$';
  }
}
