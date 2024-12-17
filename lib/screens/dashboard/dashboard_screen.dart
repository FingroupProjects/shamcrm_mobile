import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/lead%20chart/chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/lead%20chart/chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/project_chart/task_chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/project_chart/task_chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/task_chart/task_chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/task_chart/task_chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard/stats_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/stats_event.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/models/user_byId_model..dart';
import 'package:crm_task_manager/screens/dashboard/deal_stats.dart';
// import 'package:crm_task_manager/screens/dashboard/deals_box.dart';
import 'package:crm_task_manager/screens/dashboard/project_chart.dart';
import 'package:crm_task_manager/screens/dashboard/task_chart.dart';
import 'package:crm_task_manager/screens/dashboard/lead_conversion.dart';
import 'package:crm_task_manager/screens/dashboard/graphic_dashboard.dart';
// import 'package:crm_task_manager/screens/dashboard/leads_box.dart';
// import 'package:crm_task_manager/screens/dashboard/tasks_dart.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isClickAvatarIcon = false;
  bool areBoxesLoaded = false;
  String userRoleName = 'No role assigned';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    // context.read<DashboardConversionBloc>().add(LoadLeadConversionData());

    _loadImportantBoxes();
  }

  Future<void> _loadUserRole() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('userID') ?? '';

      if (userId.isEmpty) {
        setState(() {
          userRoleName = 'No user ID found';
        });
        return;
      }

      // Получение роли через API
      UserByIdProfile userProfile =
          await ApiService().getUserById(int.parse(userId));
      setState(() {
        userRoleName = (userProfile.role?.isNotEmpty ?? false)
            ? userProfile.role!.first.name
            : 'No role assigned';
      });

      print('Role: $userRoleName');
    } catch (e) {
      print('Error loading user role: $e');
      setState(() {
        userRoleName = 'Error loading role';
      });
    }
  }

  Future<void> _loadImportantBoxes() async {
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      areBoxesLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DashboardStatsBloc(
            context.read<ApiService>(),
          )..add(LoadDashboardStats()),
        ),
        BlocProvider(
          create: (context) => DashboardChartBloc(
            context.read<ApiService>(),
          )..add(LoadLeadChartData()),
        ),
        BlocProvider(
          create: (context) => DashboardConversionBloc(
            context.read<ApiService>(),
          )..add(LoadLeadConversionData()),
        ),
        BlocProvider(
          create: (context) => DealStatsBloc(
            context.read<ApiService>(),
          )..add(LoadDealStatsData()),
        ),
        BlocProvider(
          create: (context) => ProjectChartBloc(
            context.read<ApiService>(),
          ),
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: CustomAppBar(
          title: isClickAvatarIcon ? 'Настройки' : 'Дашборд',
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
                padding: EdgeInsets.only(left: 16, right: 16),
                child: Column(
                  children: _buildDashboardContent(),
                ),
              ),
      ),
    );
  }

  List<Widget> _buildDashboardContent() {
    if (userRoleName == 'admin') {
      return [
        // LeadsBox(),
        // SizedBox(height: 16),
        // TasksBox(),
        // SizedBox(height: 16),
        // DealsBox(),
        // SizedBox(height: 16),
        GraphicsDashboard(),
        // SizedBox(height: 16),
        LeadConversionChart(),
        DealStatsChart(),
        TaskChartWidget(),
        ProjectChartTable(),
      ];
    } else if (userRoleName == 'manager') {
      return [
        // LeadsBox(),суфк
        // SizedBox(height: 16),
        // TasksBox(),
        // SizedBox(height: 16),
        // DealsBox(),
        // SizedBox(height: 16),
        GraphicsDashboard(),
        // SizedBox(height: 16),
        LeadConversionChart(),
        DealStatsChart(),
        TaskChartWidget(),
      ];
    } else {
      return [
        TaskChartWidget(),
      ];
    }
  }
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
      tilePadding: EdgeInsets.symmetric(horizontal: 160, vertical: 8),
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
