import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Single apartment cell inside the chess grid matrix with dynamic scale (Chrome-like zoom).
class ChessGridCell extends StatelessWidget {
  final Apartment apartment;
  final bool isSelected;
  final ChessZoomLevel zoomLevel;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ChessGridCell({
    super.key,
    required this.apartment,
    this.isSelected = false,
    this.zoomLevel = ChessZoomLevel.standard100,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final statusColor = apartment.status.color;
    final bgColor = apartment.status.bgColor;

    final roomsLabel = apartment.rooms == 0 ? 'Ст' : '${apartment.rooms}к';
    final priceFormatted = _formatPrice(apartment.totalPrice);

    final width = zoomLevel.cellWidth;
    final height = zoomLevel.cellHeight;
    final marginVal = zoomLevel == ChessZoomLevel.micro50 ? 2.0 : 3.0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      onLongPress: onLongPress != null
          ? () {
              HapticFeedback.mediumImpact();
              onLongPress!();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: width,
        height: height,
        margin: EdgeInsets.all(marginVal),
        decoration: BoxDecoration(
          color: isSelected ? statusColor.withValues(alpha: 0.28) : bgColor,
          borderRadius: BorderRadius.circular(
            zoomLevel == ChessZoomLevel.micro50 ? 8 : 11,
          ),
          border: Border.all(
            color: isSelected
                ? colors.textPrimary
                : statusColor.withValues(alpha: 0.55),
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: zoomLevel == ChessZoomLevel.micro50 ? 2 : 5,
          vertical: zoomLevel == ChessZoomLevel.micro50 ? 2 : 5,
        ),
        child: _buildCellContent(
          colors: colors,
          statusColor: statusColor,
          roomsLabel: roomsLabel,
          priceFormatted: priceFormatted,
        ),
      ),
    );
  }

  Widget _buildCellContent({
    required dynamic colors,
    required Color statusColor,
    required String roomsLabel,
    required String priceFormatted,
  }) {
    switch (zoomLevel) {
      case ChessZoomLevel.micro50:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              apartment.number,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                color: colors.textPrimary,
                height: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
            const SizedBox(height: 3),
            Container(
              width: 5.5,
              height: 5.5,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        );

      case ChessZoomLevel.compact75:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    '№${apartment.number}',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: colors.textPrimary,
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              '$roomsLabel · ${apartment.totalArea.toStringAsFixed(0)}м²',
              style: TextStyle(
                fontFamily: 'Golos',
                fontWeight: FontWeight.w600,
                fontSize: 10,
                color: colors.textSecondary,
                height: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );

      case ChessZoomLevel.standard100:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
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
                      fontSize: 13.5,
                      color: colors.textPrimary,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              '$roomsLabel · ${apartment.totalArea.toStringAsFixed(0)} м²',
              style: TextStyle(
                fontFamily: 'Golos',
                fontWeight: FontWeight.w500,
                fontSize: 11,
                color: colors.textSecondary,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              priceFormatted,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: statusColor,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );

      case ChessZoomLevel.large125:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    '№${apartment.number}',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: colors.textPrimary,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    roomsLabel,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${apartment.totalArea.toStringAsFixed(1)} м²',
              style: TextStyle(
                fontFamily: 'Golos',
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                color: colors.textSecondary,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              priceFormatted,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: statusColor,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
    }
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
