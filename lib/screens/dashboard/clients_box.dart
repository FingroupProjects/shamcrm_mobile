import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_card_dashboard.dart';

class ClientsBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DashboardItem(
      title: 'Клиенты',
      iconWidget: Image.asset(
        'assets/icons/Dashboard/clients_box.png', // Путь к вашей иконке
        width: 36, // Задайте нужный размер
        height: 36,
      ),
      stats: ['251 приведено', '120 неизвестно', '134 ушедших'],
    );
  }
}
