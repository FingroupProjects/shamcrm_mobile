// dashboard/dashboard_screen.dart
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard/dashboard_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/dashboard_event.dart';
import 'package:crm_task_manager/screens/dashboard/deals_box.dart';
import 'package:crm_task_manager/screens/dashboard/graphic_dashboard.dart';
import 'package:crm_task_manager/screens/dashboard/leads_box.dart';
import 'package:crm_task_manager/screens/dashboard/tasks_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc(
        context.read<ApiService>(),
      )..add(LoadDashboardStats()),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              LeadsBox(),
              SizedBox(height: 16),
              TasksBox(),
              SizedBox(height: 16),
              DealsBox(),
              SizedBox(height: 16),
              GraphicsDashboard(),
            ],
          ),
        ),
      ),
    );
  }
}
