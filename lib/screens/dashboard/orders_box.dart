import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_card_dashboard.dart';

class OrdersBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DashboardItem(
      title: 'Заказы',
      iconWidget: Image.asset(
        'assets/icons/Dashboard/orders_box.png', // Путь к вашей иконке
        width: 36, // Задайте нужный размер
        height: 36,
      ),
      stats: ['24 заказа обработано'],
    );
  }
}
