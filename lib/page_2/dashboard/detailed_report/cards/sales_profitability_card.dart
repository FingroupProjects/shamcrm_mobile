import 'package:flutter/material.dart';
import 'dashboard_card.dart';

class SalesProfitabilityCard extends StatelessWidget {
  final String? percentage;
  final VoidCallback? onTap;
  final bool isSelected;

  const SalesProfitabilityCard({
    Key? key,
    this.percentage,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Рентабельность продаж',
      subtitle: 'Эффективность продаж',
      value: percentage ?? '0%',
      icon: Icons.pie_chart,
      iconColor: const Color(0xFFF59E0B),
      isSelected: isSelected,
      onTap: onTap,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Color(0xff99A4BA),
      ),
    );
  }
}
