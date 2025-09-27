import 'package:flutter/material.dart';
import 'dashboard_card.dart';

class CashBalanceCard extends StatelessWidget {
  final String? balance;
  final VoidCallback? onTap;
  final bool isSelected;

  const CashBalanceCard({
    Key? key,
    this.balance,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Остаток кассы',
      subtitle: 'Текущий остаток в кассе',
      value: balance ?? '0 ₽',
      icon: Icons.account_balance_wallet,
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