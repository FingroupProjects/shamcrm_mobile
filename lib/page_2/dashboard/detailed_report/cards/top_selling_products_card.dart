import 'package:flutter/material.dart';
import 'dashboard_card.dart';

class TopSellingProductsCard extends StatelessWidget {
  final String? count;
  final VoidCallback? onTap;
  final bool isSelected;

  const TopSellingProductsCard({
    Key? key,
    this.count,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Топ продаваемых товаров',
      subtitle: 'Самые популярные товары',
      value: count ?? '0 товаров',
      icon: Icons.trending_up,
      iconColor: const Color(0xFF8B5CF6),
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