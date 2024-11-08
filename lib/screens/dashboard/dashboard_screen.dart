import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/screens/dashboard/chart_box.dart';
import 'package:crm_task_manager/screens/dashboard/clients_box.dart';
import 'package:crm_task_manager/screens/dashboard/orders_box.dart';
import 'package:crm_task_manager/screens/dashboard/tasks_dart.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';


class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  TextEditingController searchController = TextEditingController();
  FocusNode focusNode = FocusNode();
  bool isClickAvatarIcon = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        elevation: 1,

        title: CustomAppBar(title: 'Дашборд',
          onClickProfileAvatar: () {

            setState(() {
              isClickAvatarIcon = !isClickAvatarIcon;
            });

          },
          onChangedSearchInput: (value) {}, textEditingController: searchController, focusNode: focusNode,
        ),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,

      body: isClickAvatarIcon == true ? ProfileScreen(): SingleChildScrollView(
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
