import 'package:crm_task_manager/screens/chess_grid/utils/chess_grid_localizations.dart';
import 'package:flutter/material.dart';

/// Floating Building / Complex Badge (Media 1)
class FloatingBuildingBadge extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isSelected;

  const FloatingBuildingBadge({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2C3942).withValues(alpha: 0.94), // Dark architectural badge as in Media 1
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF2979FF) : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 1.8 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2ECC71), // Green indicator dot
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Golos',
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.82),
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating Entrance Badge (Media 2)
class FloatingEntranceBadge extends StatelessWidget {
  final int entranceNumber;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const FloatingEntranceBadge({
    super.key,
    required this.entranceNumber,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF2C3942).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected ? const Color(0xFF2979FF) : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 1.8 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2ECC71),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${context.tr('chess_grid_entrance', fallback: 'Подъезд')} $entranceNumber',
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Golos',
                fontSize: 9.5,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating Floor Number Badge (Media 3)
class FloatingFloorBadge extends StatelessWidget {
  final int floorNumber;
  final bool isSelected;
  final VoidCallback onTap;

  const FloatingFloorBadge({
    super.key,
    required this.floorNumber,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 26,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2979FF) : const Color(0xFF2C3942).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 1.4 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '$floorNumber',
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
            color: Colors.white,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

/// Floating Apartment Unit Number Badge (Media 4)
class FloatingApartmentUnitBadge extends StatelessWidget {
  final String number;
  final bool isSelected;
  final VoidCallback onTap;

  const FloatingApartmentUnitBadge({
    super.key,
    required this.number,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF2C3942).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C4DFF) : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '№ $number',
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w800,
            fontSize: 11,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

