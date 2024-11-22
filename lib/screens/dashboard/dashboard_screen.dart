import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard/dashboard_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/dashboard_event.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/screens/dashboard/deals_box.dart';
import 'package:crm_task_manager/screens/dashboard/lead_conversion.dart';
import 'package:crm_task_manager/screens/dashboard/graphic_dashboard%20copy%202.dart';
import 'package:crm_task_manager/screens/dashboard/graphic_dashboard%20copy%203.dart';
import 'package:crm_task_manager/screens/dashboard/graphic_dashboard%20copy.dart';
import 'package:crm_task_manager/screens/dashboard/graphic_dashboard.dart';
import 'package:crm_task_manager/screens/dashboard/leads_box.dart';
import 'package:crm_task_manager/screens/dashboard/tasks_dart.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isClickAvatarIcon = false;
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadLeadConversionData());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc(
        context.read<ApiService>(),
      )..add(LoadDashboardStats()),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: CustomAppBar(
            title: "Дашборд",
            onClickProfileAvatar: () {
              setState(() {
                isClickAvatarIcon = !isClickAvatarIcon;
              });
            },
            onChangedSearchInput: (input) {},
            textEditingController: TextEditingController(),
            focusNode: FocusNode(),
            clearButtonClick: (isSearching) {},
            showSearchIcon: false,
          ),
        ),
        body: isClickAvatarIcon
            ? ProfileScreen()
            : SingleChildScrollView(
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
                    SizedBox(height: 16),
                    AnimatedConversionChart(),
                    // SizedBox(height: 16),
                    // GraphicTasksDashboard(),
                    // SizedBox(height: 16),
                    // GraphicBarDashboard(),
                    // SizedBox(height: 16),
                    // GraphicCircleDashboardProject(),
                  ],
                ),
              ),
      ),
    );
  }

  // Метод для стилизованных раскрывающихся карточек
  Widget _buildExpansionTile({required String title, required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: const Color.fromARGB(255, 244, 247, 254),
      elevation: 4,
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        iconColor: Color(0xFF2D3748),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ],
      ),
    );
  }
}
