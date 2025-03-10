import 'dart:convert';
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
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/TutorialStyleWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isClickAvatarIcon = false;
  List<String> userRoles = [];
  bool isLoading = true;
  bool isRefreshing = false;

  final GlobalKey keyNotificationIcon = GlobalKey();
  final GlobalKey keyMyTaskIcon = GlobalKey();
  final GlobalKey keyAdminLeadConversion = GlobalKey();
  final GlobalKey keyAdminTaskComplietion = GlobalKey();
  final GlobalKey keyAdminTaskChart = GlobalKey();
  final GlobalKey keyAdminGraphics = GlobalKey();
  final GlobalKey keyAdminProcessSpeed = GlobalKey();
  final GlobalKey keyAdminDealStats = GlobalKey();

  final GlobalKey keyManagerGoalComplietion = GlobalKey();

  List<TargetFocus> targets = [];
  bool _isTutorialShown = false;
  bool _isTaskScreenTutorialCompleted = false;
  Map<String, dynamic>? tutorialProgress;
  final ApiService _apiService = ApiService();

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeData();
    _fetchTutorialProgress();
  }

Future<void> _fetchTutorialProgress() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    // Всегда получаем данные с сервера
    final progress = await _apiService.getTutorialProgress();
    setState(() {
      tutorialProgress = progress['result'];
    });
    // Сохраняем актуальные данные в SharedPreferences
    await prefs.setString('tutorial_progress', json.encode(progress['result']));
    // Проверяем локальный флаг завершения туториала
    bool isTutorialShown = prefs.getBool('isTutorialShownDashboard') ?? false;
    if (isTutorialShown) {
      setState(() {
        _isTutorialShown = true;
      });
    }
  } catch (e) {
    print('Error fetching tutorial progress: $e');
    // В случае ошибки пытаемся загрузить из кэша
    final prefs = await SharedPreferences.getInstance();
    final savedProgress = prefs.getString('tutorial_progress');
    if (savedProgress != null) {
      setState(() {
        tutorialProgress = json.decode(savedProgress);
      });
    }
  }
}

  void _initTutorialTargets() {
    if (userRoles.contains('admin')) {
      _initAdminTutorialTargets();
    } else if (userRoles.contains('manager')) {
      _initTutorialTargetsManagers();
    } else {
      _initTutorialTargetsUsers();
    }

    _showTutorialIfNeeded();
  }

  void _showTutorialIfNeeded() {
    if (!_isTutorialShown &&
        tutorialProgress != null &&
        tutorialProgress!['dashboard']?['index'] == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showTutorial();
        setState(() {
          _isTutorialShown = true;
        });
      });
    }
  }

  void _initAdminTutorialTargets() {
    targets.addAll([
      createTarget(
        identify: "dashboardNotificationIcon",
        keyTarget: keyNotificationIcon,
        title: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_notification_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_notification_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
      createTarget(
        identify: "dashboardMyTaskIcon",
        keyTarget: keyMyTaskIcon,
        title: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_mytask_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_mytask_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
      createTarget(
        identify: "dashboardAdminLeadConversion",
        keyTarget: keyAdminLeadConversion,
        title: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_lead_conversion_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_lead_conversion_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
        contentPadding: EdgeInsets.only(top: 30),
      ),
      createTarget(
        identify: "dashboardAdminTaskComplietion",
        keyTarget: keyAdminTaskComplietion,
        title: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_task_completion_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_task_completion_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.below,
        contentPadding: EdgeInsets.only(top: 10),
      ),
      createTarget(
        identify: "dashboardAdminTaskChart",
        keyTarget: keyAdminTaskChart,
        title: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_task_chart_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_task_chart_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
      createTarget(
        identify: "dashboardAdminGraphics",
        keyTarget: keyAdminGraphics,
        title: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_graphics_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_graphics_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
        contentPadding: EdgeInsets.only(top: 80),
      ),
      createTarget(
        identify: "dashboardAdminProcessSpeed",
        keyTarget: keyAdminProcessSpeed,
        title: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_lead_process_speed_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_lead_process_speed_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
        contentPadding: EdgeInsets.only(top: 80),
      ),
      createTarget(
        identify: "dashboardAdminDealStats",
        keyTarget: keyAdminDealStats,
        title: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_deal_stats_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_deal_stats_description'),
        align: ContentAlign.top,
        context: context,
        contentPosition: ContentPosition.below,
      ),
    ]);
  }

  void _initTutorialTargetsManagers() {
    targets.addAll([
      createTarget(
        identify: "dashboardNotificationIcon",
        keyTarget: keyNotificationIcon,
        title: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_notification_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_notification_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
      createTarget(
        identify: "dashboardMyTaskIcon",
        keyTarget: keyMyTaskIcon,
        title: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_mytask_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_mytask_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
      createTarget(
        identify: "dashboardAdminLeadConversion",
        keyTarget: keyAdminLeadConversion,
        title: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_lead_conversion_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_lead_conversion_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
        contentPadding: EdgeInsets.only(top: 30),
      ),
      createTarget(
        identify: "dashboardManagerGoalComplietion",
        keyTarget: keyManagerGoalComplietion,
        title: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_user_goal_completion_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_user_goal_completion_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.below,
        contentPadding: EdgeInsets.only(top: 10),
      ),
      createTarget(
        identify: "dashboardAdminGraphics",
        keyTarget: keyAdminGraphics,
        title: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_graphics_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_graphics_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
        contentPadding: EdgeInsets.only(top: 80),
      ),
      createTarget(
        identify: "dashboardAdminTaskChart",
        keyTarget: keyAdminTaskChart,
        title: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_task_chart_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_task_chart_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
        contentPadding: EdgeInsets.only(top: 30),
      ),
      createTarget(
        identify: "dashboardAdminProcessSpeed",
        keyTarget: keyAdminProcessSpeed,
        title: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_lead_process_speed_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_lead_process_speed_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
        contentPadding: EdgeInsets.only(top: 80),
      ),
      createTarget(
        identify: "dashboardAdminDealStats",
        keyTarget: keyAdminDealStats,
        title: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_deal_stats_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_deal_stats_description'),
        align: ContentAlign.top,
        context: context,
        contentPosition: ContentPosition.below,
      ),
    ]);
  }

  void _initTutorialTargetsUsers() {
    targets.addAll([
      createTarget(
        identify: "dashboardNotificationIcon",
        keyTarget: keyNotificationIcon,
        title: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_notification_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_notification_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
      createTarget(
        identify: "dashboardMyTaskIcon",
        keyTarget: keyMyTaskIcon,
        title: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_mytask_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_mytask_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
      createTarget(
        identify: "dashboardUserGoalComplietion",
        keyTarget: keyManagerGoalComplietion,
        title: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_user_goal_completion_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_user_goal_completion_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
        contentPadding: EdgeInsets.only(top: 50),
      ),
      createTarget(
        identify: "dashboardUserTaskChart",
        keyTarget: keyAdminTaskChart,
        title: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_task_chart_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_dashboard_task_chart_description'),
        align: ContentAlign.top,
        context: context,
        contentPosition: ContentPosition.below,
      ),
    ]);
  }

  void showTutorial() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isTutorialShown = prefs.getBool('isTutorialShownDashboard') ?? false;

    if (!isTutorialShown) {
      TutorialCoachMark(
        targets: targets,
        textSkip: AppLocalizations.of(context)!.translate('skip'),
        textStyleSkip: TextStyle(
          color: Colors.white,
          fontFamily: 'Gilroy',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
            Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
            Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
            Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
          ],
        ),
        colorShadow: Color(0xff1E2E52),
        onSkip: () {
          // Изменено: убрано async, возвращаем bool напрямую
          prefs.setBool('isTutorialShownDashboard', true);
          _apiService.markPageCompleted("dashboard", "index").catchError((e) {
            print('Error marking page completed on skip: $e');
          });
          setState(() {
            _isTaskScreenTutorialCompleted = true;
          });
          return true;
        },
        onFinish: () async {
          await prefs.setBool('isTutorialShownDashboard', true);
          try {
            await _apiService.markPageCompleted("dashboard", "index");
          } catch (e) {
            print('Error marking page completed on finish: $e');
          }
          setState(() {
            _isTaskScreenTutorialCompleted = true;
          });
        },
        onClickTarget: (target) async {
          int currentIndex =
              targets.indexWhere((t) => t.identify == target.identify);
          if (currentIndex < targets.length - 1) {
            final nextTarget = targets[currentIndex + 1];

            if (nextTarget.keyTarget != null) {
              await Future.delayed(Duration(milliseconds: 300));
              _scrollToTarget(nextTarget.keyTarget!);
            }
          }
        },
      ).show(context: context);
    }
  }

  void _scrollToTarget(GlobalKey key) {
    final RenderObject? renderObject = key.currentContext?.findRenderObject();
    if (renderObject != null && renderObject is RenderBox) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      print("Error: Unable to find render object for key");
    }
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

      UserByIdProfile userProfile =
          await ApiService().getUserById(int.parse(userId));
      if (mounted) {
        setState(() {
          userRoles = userProfile.role?.map((role) => role.name).toList() ??
              ['No role assigned'];
        });

        await prefs.setString('userRoles', userRoles.join(','));
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initTutorialTargets();
      });
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

      await Future.wait(
          [_loadUserRoles(), Future.delayed(const Duration(seconds: 3))]);
      if (mounted) {
        setState(() {
          isRefreshing = false;
        });

        context.read<TaskCompletionBloc>().add(LoadTaskCompletionData());
        context.read<DashboardChartBloc>().add(LoadLeadChartData());
        context
            .read<DashboardChartBlocManager>()
            .add(LoadLeadChartDataManager());
        context.read<ProcessSpeedBloc>().add(LoadProcessSpeedData());
        context.read<DashboardConversionBloc>().add(LoadLeadConversionData());
        context
            .read<DashboardConversionBlocManager>()
            .add(LoadLeadConversionDataManager());
        context.read<DealStatsBloc>().add(LoadDealStatsData());
        context.read<DealStatsManagerBloc>().add(LoadDealStatsManagerData());
        context.read<UserBlocManager>().add(LoadUserData());
        context.read<DashboardTaskChartBloc>().add(LoadTaskChartData());
        context
            .read<DashboardTaskChartBlocManager>()
            .add(LoadTaskChartDataManager());
        context
            .read<ProcessSpeedBlocManager>()
            .add(LoadProcessSpeedDataManager());
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
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: CustomAppBar(
          title: isClickAvatarIcon
              ? localizations!.translate('appbar_settings')
              : localizations!.translate('appbar_dashboard'),
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
          showMyTaskIcon: true,
          showEvent: false,
          showSeparateMyTasks: true,
          showMenuIcon: false,
          clearButtonClickFiltr: (bool) {},
          NotificationIconKey: keyNotificationIcon,
          MyTaskIconKey: keyMyTaskIcon,
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
                    controller: _scrollController,
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
        LeadConversionChart(key: keyAdminLeadConversion),
        Divider(thickness: 1, color: Colors.grey[300]),
        TaskCompletionChart(key: keyAdminTaskComplietion),
        Divider(thickness: 1, color: Colors.grey[300]),
        TaskChartWidget(key: keyAdminTaskChart),
        Divider(thickness: 1, color: Colors.grey[300]),
        GraphicsDashboard(lineChartKey: keyAdminGraphics),
        Divider(thickness: 1, color: Colors.grey[300]),
        ProcessSpeedGauge(
          key: keyAdminProcessSpeed,
        ),
        Divider(thickness: 1, color: Colors.grey[300]),
        DealStatsChart(
          key: keyAdminDealStats,
        ),
      ];
    } else if (userRoles.contains('manager')) {
      return [
        LeadConversionChartManager(
          key: keyAdminLeadConversion,
        ),
        Divider(thickness: 1, color: Colors.grey[300]),
        GoalCompletionChart(
          key: keyManagerGoalComplietion,
        ),
        Divider(thickness: 1, color: Colors.grey[300]),
        GraphicsDashboardManager(
          lineChartKey: keyAdminGraphics,
        ),
        Divider(thickness: 1, color: Colors.grey[300]),
        TaskChartWidgetManager(
          key: keyAdminTaskChart,
        ),
        Divider(thickness: 1, color: Colors.grey[300]),
        ProcessSpeedGaugeManager(
          key: keyAdminProcessSpeed,
        ),
        Divider(thickness: 1, color: Colors.grey[300]),
        DealStatsChartManager(
          key: keyAdminDealStats,
        ),
      ];
    } else {
      return [
        GoalCompletionChart(
          key: keyManagerGoalComplietion,
        ),
        Divider(thickness: 1, color: Colors.grey[300]),
        TaskChartWidgetManager(
          key: keyAdminTaskChart,
        ),
      ];
    }
  }
}
