import 'package:flutter/material.dart';
import 'dashboard_card.dart';

class NetProfitCard extends StatelessWidget {
  final String? amount;
  final VoidCallback? onTap;
  final bool isSelected;

  const NetProfitCard({
    Key? key,
    this.amount,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Чистая прибыль',
      subtitle: 'Прибыль после всех расходов',
      value: amount ?? '0 ₽',
      icon: Icons.attach_money,
      iconColor: const Color(0xFF10B981),
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