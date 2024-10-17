import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_card_dashboard.dart';

class TasksBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DashboardItem(
      title: 'Задачи',
      iconWidget: Image.asset(
        'assets/icons/Dashboard/tasks_box.png', // Путь к вашей иконке
        width: 36, // Задайте нужный размер
        height: 36,
      ),
      stats: ['134 выполнено', '134 просрочено', '134 открытых'],
    );
  }
}
