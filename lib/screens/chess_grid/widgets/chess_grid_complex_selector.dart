import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

/// Horizontal scrollable selector for residential complexes.
class ChessGridComplexSelector extends StatelessWidget {
  final List<ResidentialComplex> complexes;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const ChessGridComplexSelector({
    super.key,
    required this.complexes,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: complexes.length,
        itemBuilder: (context, index) {
          final complex = complexes[index];
          final isSelected = index == selectedIndex;
          return _ComplexCard(
            complex: complex,
            isSelected: isSelected,
            onTap: () => onSelected(index),
          );
        },
      ),
    );
  }
}

class _ComplexCard extends StatelessWidget {
  final ResidentialComplex complex;
  final bool isSelected;
  final VoidCallback onTap;

  const _ComplexCard({
    required this.complex,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final totalApts = ChessGridController.instance
        .getApartmentsForComplex(complex.id)
        .length;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 180,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    colors.buttonPrimaryBg,
                    colors.buttonPrimaryBg.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : colors.surfacePrimary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colors.buttonPrimaryBg
                : colors.borderSubtle.withValues(alpha: 0.6),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.buttonPrimaryBg.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  Icons.apartment_rounded,
                  size: 18,
                  color: isSelected
                      ? colors.buttonPrimaryFg
                      : colors.iconSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    complex.name,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isSelected
                          ? colors.buttonPrimaryFg
                          : colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${complex.buildings.length} ${AppLocalizations.of(context)!.translate('chess_grid_building').toLowerCase()} · $totalApts кв.',
              style: TextStyle(
                fontFamily: 'Golos',
                fontWeight: FontWeight.w500,
                fontSize: 11,
                color: isSelected
                    ? colors.buttonPrimaryFg.withValues(alpha: 0.8)
                    : colors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
