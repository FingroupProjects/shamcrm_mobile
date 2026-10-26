import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ChessCellSize {
  detailed, // 88 x 70 dp - standard mobile view with number, rooms, area, price
  compact,  // 46 x 46 dp - heat map overview mode (entire building on screen)
}

/// Advanced 2.0 Chess Grid Cell supporting Chrome-like zoom levels:
/// 50% (Micro), 75% (Compact), 100% (Standard), 125% (Large).
class ChessCellV2 extends StatelessWidget {
  final Apartment apartment;
  final bool isSelected;
  final ChessZoomLevel zoomLevel;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ChessCellV2({
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
    final status = apartment.status;
    final statusColor = status.color;
    final bgColor = status.bgColor;

    switch (zoomLevel) {
      case ChessZoomLevel.micro50:
        return _buildMicroCell(context, colors, statusColor, bgColor);
      case ChessZoomLevel.compact75:
        return _buildCompact75Cell(context, colors, statusColor, bgColor);
      case ChessZoomLevel.standard100:
        return _buildStandardCell(context, colors, statusColor, bgColor);
      case ChessZoomLevel.large125:
        return _buildLargeCell(context, colors, statusColor, bgColor);
    }
  }

  /// 50% Overview (Heat Map): 46x46 dp
  Widget _buildMicroCell(
    BuildContext context,
    dynamic colors,
    Color statusColor,
    Color bgColor,
  ) {
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
        width: 46,
        height: 46,
        margin: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          color: isSelected
              ? statusColor.withValues(alpha: 0.32)
              : bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? colors.textPrimary
                : statusColor.withValues(alpha: 0.5),
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 75% Compact Mode: 68x56 dp
  Widget _buildCompact75Cell(
    BuildContext context,
    dynamic colors,
    Color statusColor,
    Color bgColor,
  ) {
    final roomsLabel = apartment.rooms == 0 ? 'Ст' : '${apartment.rooms}к';

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
        width: 68,
        height: 56,
        margin: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: isSelected
              ? statusColor.withValues(alpha: 0.28)
              : bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? colors.textPrimary
                : statusColor.withValues(alpha: 0.55),
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
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
        ),
      ),
    );
  }

  /// 100% Standard Detailed Mode: 88x70 dp (Default)
  Widget _buildStandardCell(
    BuildContext context,
    dynamic colors,
    Color statusColor,
    Color bgColor,
  ) {
    final roomsLabel = apartment.rooms == 0 ? 'Студия' : '${apartment.rooms} комн.';
    final priceStr = _formatPrice(apartment.totalPrice);

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
        width: 88,
        height: 70,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isSelected
              ? statusColor.withValues(alpha: 0.28)
              : bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colors.textPrimary
                : statusColor.withValues(alpha: 0.55),
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top: Status indicator + Apt Number
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
                      fontSize: 13,
                      color: colors.textPrimary,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // Middle: Rooms and Area
            Text(
              '$roomsLabel · ${apartment.totalArea.toStringAsFixed(0)}м²',
              style: TextStyle(
                fontFamily: 'Golos',
                fontWeight: FontWeight.w500,
                fontSize: 10.5,
                color: colors.textSecondary,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Bottom: Price
            Text(
              priceStr,
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
        ),
      ),
    );
  }

  /// 125% Large Mode: 112x88 dp
  Widget _buildLargeCell(
    BuildContext context,
    dynamic colors,
    Color statusColor,
    Color bgColor,
  ) {
    final roomsLabel = apartment.rooms == 0 ? 'Студия' : '${apartment.rooms}-комн.';
    final priceStr = _formatPrice(apartment.totalPrice);

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
        width: 112,
        height: 88,
        margin: const EdgeInsets.all(3.5),
        decoration: BoxDecoration(
          color: isSelected
              ? statusColor.withValues(alpha: 0.28)
              : bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? colors.textPrimary
                : statusColor.withValues(alpha: 0.6),
            width: isSelected ? 2.2 : 1.4,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
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
              ],
            ),
            Text(
              '$roomsLabel · ${apartment.totalArea.toStringAsFixed(1)} м²',
              style: TextStyle(
                fontFamily: 'Golos',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: colors.textSecondary,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              priceStr,
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
