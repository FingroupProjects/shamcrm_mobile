import 'package:flutter/material.dart';

import 'dashboard_card.dart';

class SalesDynamicsCard extends StatelessWidget {
  final String? percentage;
  final VoidCallback? onTap;
  final bool isSelected;

  const SalesDynamicsCard({
    Key? key,
    this.percentage,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Динамика продаж',
      subtitle: 'Изменение продаж за период',
      value: percentage ?? '+0%',
      icon: Icons.show_chart,
      iconColor: const Color(0xFF06B6D4),
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