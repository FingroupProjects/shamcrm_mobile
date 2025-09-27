import 'package:flutter/material.dart';
import 'dashboard_card.dart';

class OrdersCountCard extends StatelessWidget {
  final String? count;
  final VoidCallback? onTap;
  final bool isSelected;

  const OrdersCountCard({
    Key? key,
    this.count,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Количество заказов',
      subtitle: 'Общее количество заказов',
      value: count ?? '0 заказов',
      icon: Icons.shopping_cart,
      iconColor: const Color(0xFF6366F1),
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
