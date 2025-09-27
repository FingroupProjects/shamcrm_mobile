import 'package:flutter/material.dart';
import 'dashboard_card.dart';

class OurDebtsCard extends StatelessWidget {
  final String? amount;
  final VoidCallback? onTap;
  final bool isSelected;

  const OurDebtsCard({
    Key? key,
    this.amount,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Наши долги',
      subtitle: 'Сумма наших обязательств',
      value: amount ?? '0 ₽',
      icon: Icons.credit_card_off,
      iconColor: const Color(0xFFEF4444),
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