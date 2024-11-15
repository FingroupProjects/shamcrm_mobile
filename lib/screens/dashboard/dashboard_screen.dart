import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard/dashboard_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/dashboard_event.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/screens/dashboard/deals_box.dart';
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
        )),
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
                  ],
                ),
              ),
      ),
    );
  }
}
