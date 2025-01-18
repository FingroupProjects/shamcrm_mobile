import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/lead_chart/chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/lead_chart/chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/task_chart/task_chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/task_chart/task_chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/user_task/user_task_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/user_task/user_task_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/process_speed/ProcessSpeed_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/process_speed/ProcessSpeed_event.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/conversion/conversion_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/conversion/conversion_event.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/dealStats/dealStats_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/dealStats/dealStats_event.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/lead_chart/chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/lead_chart/chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/process_speed/ProcessSpeed_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/process_speed/ProcessSpeed_event.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/task_chart/task_chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/task_chart/task_chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/user_task/user_task_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/user_task/user_task_event.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/models/user_byId_model..dart';
import 'package:crm_task_manager/screens/dashboard/deal_stats.dart';
import 'package:crm_task_manager/screens/dashboard/users_chart.dart';
import 'package:crm_task_manager/screens/dashboard/process_speed.dart';
import 'package:crm_task_manager/screens/dashboard/task_chart.dart';
import 'package:crm_task_manager/screens/dashboard/lead_conversion.dart';
import 'package:crm_task_manager/screens/dashboard/graphic_dashboard.dart';
import 'package:crm_task_manager/screens/dashboard_for_manager/deal_stats.dart';
import 'package:crm_task_manager/screens/dashboard_for_manager/graphic_dashboard.dart';
import 'package:crm_task_manager/screens/dashboard_for_manager/lead_conversion.dart';
import 'package:crm_task_manager/screens/dashboard_for_manager/process_speed.dart';
import 'package:crm_task_manager/screens/dashboard_for_manager/task_chart.dart';
import 'package:crm_task_manager/screens/dashboard_for_manager/users_chart.dart';
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
  List<String> userRoles = [];
  bool isLoading = true;
  bool isRefreshing = false;

 @override
void initState() {
  super.initState();
  _initializeData();
}

Future<void> _initializeData() async {
  try {
    setState(() {
      isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();

    bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

    if (isFirstTime) {
      await Future.wait([
        _loadUserRoles(),
        Future.delayed(const Duration(seconds: 3)),
      ]);

      await prefs.setBool('isFirstTime', false);
    } else {
      await _loadUserRoles();
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  } catch (e) {
    print('Error in initialization: $e');
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}

 Future<void> _loadUserRoles() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userID') ?? '';

    if (userId.isEmpty) {
      setState(() {
        userRoles = ['No user ID found'];
      });
      return;
    }

    String? storedRoles = prefs.getString('userRoles');
    if (storedRoles != null) {
      setState(() {
        userRoles = storedRoles.split(',');
      });
      return;
    }

    // If roles are not stored, call the API and save them
    UserByIdProfile userProfile = await ApiService().getUserById(int.parse(userId));
    if (mounted) {
      setState(() {
        userRoles = userProfile.role?.map((role) => role.name).toList() ?? ['No role assigned'];
      });

      // Save roles in SharedPreferences for future use
      await prefs.setString('userRoles', userRoles.join(','));
    }
  } catch (e) {
    print('Error loading user roles!');
    if (mounted) {
      setState(() {
        userRoles = ['Error loading roles'];
      });
    }
  }
}


 Future<void> _onRefresh() async {
  if (isRefreshing) return;

  try {
    setState(() {
      isRefreshing = true;
    });

    // Загрузка данных пользователя и задержка (эмуляция загрузки)
    await Future.wait(
        [_loadUserRoles(), Future.delayed(const Duration(seconds: 3))]);

    if (mounted) {
      setState(() {
        isRefreshing = false;
      });

      // Отправляем события для обновления всех блоков графиков
      context.read<TaskCompletionBloc>().add(LoadTaskCompletionData());
      context.read<DashboardChartBloc>().add(LoadLeadChartData());
      context.read<DashboardChartBlocManager>().add(LoadLeadChartDataManager());
      context.read<ProcessSpeedBloc>().add(LoadProcessSpeedData());
      context.read<DashboardConversionBloc>().add(LoadLeadConversionData());
      context.read<DashboardConversionBlocManager>().add(LoadLeadConversionDataManager());
      context.read<DealStatsBloc>().add(LoadDealStatsData());
      context.read<DealStatsManagerBloc>().add(LoadDealStatsManagerData());
      context.read<UserBlocManager>().add(LoadUserData());
      context.read<DashboardTaskChartBloc>().add(LoadTaskChartData());
      context.read<DashboardTaskChartBlocManager>().add(LoadTaskChartDataManager());
      context.read<ProcessSpeedBlocManager>().add(LoadProcessSpeedDataManager());
      
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        isRefreshing = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
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
            showFilterTaskIcon: false,
            showFilterIcon: false,
          ),
        ),
        body: isClickAvatarIcon
            ? ProfileScreen()
            : Stack(
                children: [
                  RefreshIndicator(
                    color: Color(0xff1E2E52),
                    backgroundColor: Colors.white,
                    onRefresh: _onRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: _buildDashboardContent(),
                      ),
                    ),
                  ),
                  if (isLoading || isRefreshing)
                    Container(
                      color: Colors.white,
                      child: const Center(
                        child: PlayStoreImageLoading(
                          size: 80.0,
                          duration: Duration(milliseconds: 1000),
                        ),
                      ),
                    ),
                ],
              ),
    );
  }


List<Widget> _buildDashboardContent() {
    if (userRoles.contains('admin')) {
      return [
        LeadConversionChart(),
        Divider(thickness: 1, color: Colors.grey[300]),
        TaskCompletionChart(),
        Divider(thickness: 1, color: Colors.grey[300]),
        TaskChartWidget(),
        Divider(thickness: 1, color: Colors.grey[300]),
        GraphicsDashboard(),
        Divider(thickness: 1, color: Colors.grey[300]),
        ProcessSpeedGauge(),
        Divider(thickness: 1, color: Colors.grey[300]),
        DealStatsChart(),
      ];
    } else if (userRoles.contains('manager')) {
      return [
        LeadConversionChartManager(),
        Divider(thickness: 1, color: Colors.grey[300]),
        GoalCompletionChart(),
        Divider(thickness: 1, color: Colors.grey[300]),
        GraphicsDashboardManager(),
        Divider(thickness: 1, color: Colors.grey[300]),
        TaskChartWidgetManager(),
        Divider(thickness: 1, color: Colors.grey[300]),
        ProcessSpeedGaugeManager(),
        Divider(thickness: 1, color: Colors.grey[300]),
        DealStatsChartManager(),
      ];
    } else {
      return [
        GoalCompletionChart(),
        Divider(thickness: 1, color: Colors.grey[300]),
        TaskChartWidgetManager(),         ];
    }
  }
}

