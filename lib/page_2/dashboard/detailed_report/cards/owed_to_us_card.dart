import 'package:flutter/material.dart';
import 'dashboard_card.dart';

class OwedToUsCard extends StatelessWidget {
  final String? amount;
  final VoidCallback? onTap;
  final bool isSelected;

  const OwedToUsCard({
    Key? key,
    this.amount,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Нам должны',
      subtitle: 'Сумма дебиторской задолженности',
      value: amount ?? '0 ₽',
      icon: Icons.account_balance,
      iconColor: const Color(0xFF3B82F6),
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