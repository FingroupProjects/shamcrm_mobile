import 'package:crm_task_manager/screens/dashboard/chart_box.dart';
import 'package:crm_task_manager/screens/dashboard/clients_box.dart';
import 'package:crm_task_manager/screens/dashboard/orders_box.dart';
import 'package:crm_task_manager/screens/dashboard/tasks_dart.dart';
import 'package:flutter/material.dart';


class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            OrdersBox(),
            SizedBox(height: 16),
            ClientsBox(),
            SizedBox(height: 16),
            TasksBox(),
            SizedBox(height: 16),
            ChartBox(),
          ],
        ),
      ),
    );
  }
}
