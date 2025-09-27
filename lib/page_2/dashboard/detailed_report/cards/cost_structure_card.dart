import 'package:flutter/material.dart';
import 'dashboard_card.dart';

class CostStructureCard extends StatelessWidget {
  final String? amount;
  final VoidCallback? onTap;
  final bool isSelected;

  const CostStructureCard({
    Key? key,
    this.amount,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Структура затрат',
      subtitle: 'Распределение расходов',
      value: amount ?? '0 ₽',
      icon: Icons.analytics,
      iconColor: const Color(0xFFEC4899),
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