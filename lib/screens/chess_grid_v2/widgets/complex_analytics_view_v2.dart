import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/controllers/chess_grid_v2_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:flutter/material.dart';

/// Analytics & Stats View for the Complex (MacroCRM & Profitbase style)
class ComplexAnalyticsViewV2 extends StatelessWidget {
  final ChessGridV2Controller controller;

  const ComplexAnalyticsViewV2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final complex = controller.complex;
    final apts = controller.getApartmentsForComplex(complex.id);

    final total = apts.length;
    if (total == 0) {
      return Center(
        child: Text(
          'Нет данных для аналитики',
          style: TextStyle(fontFamily: 'Gilroy', fontSize: 15, color: colors.textSecondary),
        ),
      );
    }

    final free = apts.where((a) => a.status == ApartmentStatus.available).toList();
    final booked = apts.where((a) => a.status == ApartmentStatus.booked).toList();
    final sold = apts.where((a) => a.status == ApartmentStatus.sold).toList();
    final reserved = apts.where((a) => a.status == ApartmentStatus.reserved).toList();

    final soldPercent = (sold.length / total * 100).round();
    final bookedPercent = (booked.length / total * 100).round();
    final freePercent = (free.length / total * 100).round();

    final totalValue = apts.fold<double>(0, (sum, a) => sum + a.totalPrice);
    final soldValue = sold.fold<double>(0, (sum, a) => sum + a.totalPrice);
    final availableValue = free.fold<double>(0, (sum, a) => sum + a.totalPrice);
    final avgPricePerSqm = apts.isEmpty
        ? 0.0
        : apts.fold<double>(0, (sum, a) => sum + a.pricePerSqm) / apts.length;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.paddingOf(context).bottom + 90),
      children: [
        // Overall Sold Progress Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surfacePrimary.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Распроданность комплекса',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    '$soldPercent%',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: ApartmentStatus.sold.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Multi-segment progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      if (sold.isNotEmpty)
                        Flexible(
                          flex: sold.length,
                          child: Container(color: ApartmentStatus.sold.color),
                        ),
                      if (booked.isNotEmpty)
                        Flexible(
                          flex: booked.length,
                          child: Container(color: ApartmentStatus.booked.color),
                        ),
                      if (reserved.isNotEmpty)
                        Flexible(
                          flex: reserved.length,
                          child: Container(color: ApartmentStatus.reserved.color),
                        ),
                      if (free.isNotEmpty)
                        Flexible(
                          flex: free.length,
                          child: Container(color: ApartmentStatus.available.color),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Legend items
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLegendDot('Продано', '${sold.length} ($soldPercent%)', ApartmentStatus.sold.color, colors),
                  _buildLegendDot('Бронь', '${booked.length} ($bookedPercent%)', ApartmentStatus.booked.color, colors),
                  _buildLegendDot('Свободно', '${free.length} ($freePercent%)', ApartmentStatus.available.color, colors),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Financial Metrics Grid (2x2)
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Общий пул продаж',
                value: '\$${_formatCompactPrice(totalValue)}',
                subtitle: '$total квартир',
                icon: Icons.account_balance_wallet_rounded,
                iconColor: colors.buttonPrimaryBg,
                colors: colors,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Свободно в продаже',
                value: '\$${_formatCompactPrice(availableValue)}',
                subtitle: '${free.length} квартир',
                icon: Icons.check_circle_outline_rounded,
                iconColor: ApartmentStatus.available.color,
                colors: colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Реализовано (Сумма)',
                value: '\$${_formatCompactPrice(soldValue)}',
                subtitle: '${sold.length} квартир',
                icon: Icons.monetization_on_outlined,
                iconColor: ApartmentStatus.sold.color,
                colors: colors,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Средняя цена / м²',
                value: '\$${avgPricePerSqm.toStringAsFixed(0)}',
                subtitle: 'по всему комплексу',
                icon: Icons.analytics_outlined,
                iconColor: const Color(0xFF8B5CF6),
                colors: colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Breakdown by Room Type
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surfacePrimary.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Распределение по комнатности',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              _buildRoomBreakdownRow('Студии', apts.where((a) => a.rooms == 0).toList(), total, colors),
              const Divider(height: 16),
              _buildRoomBreakdownRow('1-комнатные', apts.where((a) => a.rooms == 1).toList(), total, colors),
              const Divider(height: 16),
              _buildRoomBreakdownRow('2-комнатные', apts.where((a) => a.rooms == 2).toList(), total, colors),
              const Divider(height: 16),
              _buildRoomBreakdownRow('3-комнатные', apts.where((a) => a.rooms == 3).toList(), total, colors),
              if (apts.any((a) => a.rooms >= 4)) ...[
                const Divider(height: 16),
                _buildRoomBreakdownRow('4+ комнатные', apts.where((a) => a.rooms >= 4).toList(), total, colors),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDot(String title, String count, Color color, dynamic colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontFamily: 'Golos', fontSize: 10.5, color: colors.textSecondary)),
            Text(count, style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 11.5, color: colors.textPrimary)),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required dynamic colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontFamily: 'Golos', fontSize: 11, color: colors.textSecondary)),
              Icon(icon, size: 18, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontFamily: 'Golos', fontSize: 10.5, color: colors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildRoomBreakdownRow(String title, List<Apartment> list, int total, dynamic colors) {
    final count = list.length;
    final free = list.where((a) => a.status == ApartmentStatus.available).length;
    final percent = total > 0 ? (count / total * 100).round() : 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 13, color: colors.textPrimary),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: colors.surfaceElevated, borderRadius: BorderRadius.circular(6)),
              child: Text('$count ($percent%)', style: TextStyle(fontFamily: 'Golos', fontSize: 10.5, color: colors.textSecondary)),
            ),
          ],
        ),
        Text(
          'Свободно: $free',
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
            color: free > 0 ? ApartmentStatus.available.color : colors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatCompactPrice(double val) {
    if (val >= 1e6) {
      return '${(val / 1e6).toStringAsFixed(2)} млн';
    } else if (val >= 1e3) {
      return '${(val / 1e3).toStringAsFixed(0)} тыс';
    }
    return val.toStringAsFixed(0);
  }
}

