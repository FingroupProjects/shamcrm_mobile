import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:flutter/material.dart';

/// Interactive statistics summary bar with clickable chips to filter by status.
class ChessGridStatsBar extends StatelessWidget {
  final List<Apartment> apartments;
  final Set<ApartmentStatus> selectedStatuses;
  final ValueChanged<ApartmentStatus>? onToggleStatus;

  const ChessGridStatsBar({
    super.key,
    required this.apartments,
    this.selectedStatuses = const {
      ApartmentStatus.available,
      ApartmentStatus.booked,
      ApartmentStatus.sold,
      ApartmentStatus.reserved,
    },
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final available =
        apartments.where((a) => a.status == ApartmentStatus.available).length;
    final booked =
        apartments.where((a) => a.status == ApartmentStatus.booked).length;
    final sold =
        apartments.where((a) => a.status == ApartmentStatus.sold).length;
    final reserved =
        apartments.where((a) => a.status == ApartmentStatus.reserved).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _StatusChip(
            status: ApartmentStatus.available,
            label: 'Свободно',
            count: available,
            isSelected: selectedStatuses.contains(ApartmentStatus.available),
            onTap: () => onToggleStatus?.call(ApartmentStatus.available),
          ),
          const SizedBox(width: 8),
          _StatusChip(
            status: ApartmentStatus.booked,
            label: 'Бронь',
            count: booked,
            isSelected: selectedStatuses.contains(ApartmentStatus.booked),
            onTap: () => onToggleStatus?.call(ApartmentStatus.booked),
          ),
          const SizedBox(width: 8),
          _StatusChip(
            status: ApartmentStatus.sold,
            label: 'Продано',
            count: sold,
            isSelected: selectedStatuses.contains(ApartmentStatus.sold),
            onTap: () => onToggleStatus?.call(ApartmentStatus.sold),
          ),
          const SizedBox(width: 8),
          _StatusChip(
            status: ApartmentStatus.reserved,
            label: 'Резерв',
            count: reserved,
            isSelected: selectedStatuses.contains(ApartmentStatus.reserved),
            onTap: () => onToggleStatus?.call(ApartmentStatus.reserved),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ApartmentStatus status;
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.status,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = status.color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : colors.surfacePrimary.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : colors.borderSubtle.withValues(alpha: 0.5),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Golos',
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
                color: isSelected ? colors.textPrimary : colors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.25) : colors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: isSelected ? color : colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
