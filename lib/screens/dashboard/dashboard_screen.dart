import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/lead_chart/chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/lead_chart/chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/user_task/user_task_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/user_task/user_task_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/process_speed/ProcessSpeed_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/process_speed/ProcessSpeed_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/project_chart/task_chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/stats_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/stats_event.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/models/user_byId_model..dart';
import 'package:crm_task_manager/screens/dashboard/Skeleton_Loading_Animation_Components.dart';
import 'package:crm_task_manager/screens/dashboard/deal_stats.dart';
import 'package:crm_task_manager/screens/dashboard/users_chart.dart';
import 'package:crm_task_manager/screens/dashboard/process_speed.dart';
import 'package:crm_task_manager/screens/dashboard/task_chart.dart';
import 'package:crm_task_manager/screens/dashboard/lead_conversion.dart';
import 'package:crm_task_manager/screens/dashboard/graphic_dashboard.dart';
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
  String userRoleName = 'No role assigned';
  bool isLoading = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _loadUserRole();
    
    // Имитация загрузки данных
    await Future.delayed(const Duration(seconds: 1));
    
    // Добавляем дополнительную задержку в 2 секунды после загрузки данных
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
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

      UserByIdProfile userProfile = await ApiService().getUserById(int.parse(userId));
      if (mounted) {
        setState(() {
          userRoleName = (userProfile.role?.isNotEmpty ?? false)
              ? userProfile.role!.first.name
              : 'No role assigned';
        });
      }
    } catch (e) {
      print('Error loading user role!');
      if (mounted) {
        setState(() {
          userRoleName = 'Error loading role';
        });
      }
    }
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
        BlocProvider(
          create: (context) => ProcessSpeedBloc(
            context.read<ApiService>(),
          )..add(LoadProcessSpeedData()),
        ),
        BlocProvider(
          create: (context) => TaskCompletionBloc(
            context.read<ApiService>(),
          )..add(LoadTaskCompletionData()),
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
                padding: EdgeInsets.all(16),
                child: isLoading
                    ? Column(
                        children: List.generate(
                          3,
                          (index) => ChartSkeletonLoading(),
                        ),
                      )
                    : Column(
                        children: _buildDashboardContent(),
                      ),
              ),
      ),
    );
  }

  List<Widget> _buildDashboardContent() {
    if (userRoleName == 'admin') {
      return [
        LeadConversionChart(),
        Divider(thickness: 1, color: Colors.grey[300]),
        TaskCompletionChart(),
        Divider(thickness: 1, color: Colors.grey[300]),
        TaskChartWidget(),
        Divider(thickness: 1, color: Colors.grey[300]),
        GraphicsDashboard(),
        Divider(thickness: 1, color: Colors.grey[300]),
        DealStatsChart(),
        Divider(thickness: 1, color: Colors.grey[300]),
        ProcessSpeedGauge(),
      ];
    } else if (userRoleName == 'manager') {
      return [
        LeadConversionChart(),
        Divider(thickness: 1, color: Colors.grey[300]),
        GraphicsDashboard(),
        Divider(thickness: 1, color: Colors.grey[300]),
        TaskChartWidget(),
        Divider(thickness: 1, color: Colors.grey[300]),
        DealStatsChart(),
        Divider(thickness: 1, color: Colors.grey[300]),
        ProcessSpeedGauge(),
      ];
    } else {
      return [
        LeadConversionChart(),
        Divider(thickness: 1, color: Colors.grey[300]),
        GraphicsDashboard(),
        Divider(thickness: 1, color: Colors.grey[300]),
        TaskChartWidget(),
        Divider(thickness: 1, color: Colors.grey[300]),
        DealStatsChart(),
        Divider(thickness: 1, color: Colors.grey[300]),
        ProcessSpeedGauge(),
      ];
    }
  }
}