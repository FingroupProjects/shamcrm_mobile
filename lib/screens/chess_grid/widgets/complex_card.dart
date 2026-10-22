import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:flutter/material.dart';

class ComplexCard extends StatelessWidget {
  final ResidentialComplex complex;
  final VoidCallback onTap;

  const ComplexCard({
    super.key,
    required this.complex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final controller = ChessGridController.instance;

    final apts = controller.getApartmentsForComplex(complex.id);
    final freeCount = controller.getAvailableCount(complex.id);
    final bookedCount = controller.getBookedCount(complex.id);
    final soldCount = controller.getSoldCount(complex.id);
    final totalCount = apts.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.borderSubtle.withValues(alpha: 0.5),
        ),
        boxShadow: context.appShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Avatar/Icon + Name + Building Count
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors.buttonPrimaryBg,
                            colors.buttonPrimaryBg.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: colors.buttonPrimaryBg.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.apartment_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            complex.name,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: colors.textPrimary,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: colors.iconSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  complex.address,
                                  style: TextStyle(
                                    fontFamily: 'Golos',
                                    fontSize: 12.5,
                                    color: colors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colors.borderSubtle.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        '${complex.buildings.length} ${complex.buildings.length == 1 ? "корпус" : "корпуса"}',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Stats Chips Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        context: context,
                        color: ApartmentStatus.available.color,
                        label: 'Свободно',
                        count: freeCount,
                      ),
                      _buildDivider(context),
                      _buildStatItem(
                        context: context,
                        color: ApartmentStatus.booked.color,
                        label: 'Бронь',
                        count: bookedCount,
                      ),
                      _buildDivider(context),
                      _buildStatItem(
                        context: context,
                        color: ApartmentStatus.sold.color,
                        label: 'Продано',
                        count: soldCount,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Bottom row: Total count & "Открыть шахматку"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Всего помещений: $totalCount',
                      style: TextStyle(
                        fontFamily: 'Golos',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Шахматка',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: colors.buttonPrimaryBg,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: colors.buttonPrimaryBg,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: context.appColors.borderSubtle.withValues(alpha: 0.6),
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required Color color,
    required String label,
    required int count,
  }) {
    final colors = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Golos',
            fontSize: 11,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

