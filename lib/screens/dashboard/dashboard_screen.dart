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
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/creditors/sales_dashboard_creditors_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/debtors/sales_dashboard_debtors_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/goods/sales_dashboard_goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/sales_dashboard_bloc.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/models/user_byId_model..dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/dialogs/dialog_creditors_info.dart';
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
import 'package:crm_task_manager/page_2/dashboard/widgets/charts/top_selling_products_chart.dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/charts/sales_dynamics_line_chart.dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/charts/net_profit_chart.dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/charts/expense_structure_chart.dart';
// import 'package:crm_task_manager/page_2/dashboard/widgets/charts/profit_margin_chart.dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/charts/order_quantity_chart.dart';
import 'package:crm_task_manager/page_2/dashboard/sales_dashboard_screen.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/TutorialStyleWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../bloc/page_2_BLOC/dashboard/cash_balance/sales_dashboard_cash_balance_bloc.dart';
import '../../models/page_2/dashboard/dashboard_top.dart';
import '../../models/page_2/dashboard/expense_structure.dart';
import '../../models/page_2/dashboard/illiquids_model.dart';
import '../../models/page_2/dashboard/net_profit_model.dart';
import '../../models/page_2/dashboard/order_dashboard_model.dart';
import '../../models/page_2/dashboard/profitability_dashboard_model.dart';
import '../../models/page_2/dashboard/sales_model.dart';
import '../../models/page_2/dashboard/top_selling_model.dart';
import '../../page_2/dashboard/widgets/charts/profitability_chart.dart';
import '../../page_2/dashboard/widgets/dialogs/dialog_cash_balance_info.dart';
import '../../page_2/dashboard/widgets/dialogs/dialog_debtors_info.dart';
import '../../page_2/dashboard/widgets/dialogs/dialog_products_info.dart';
import '../../page_2/dashboard/widgets/stat_card.dart';
import '../../widgets/snackbar_widget.dart';



// Enum для типов дашборда
enum DashboardType {
  crm,
  accounting
}

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isClickAvatarIcon = false;
  List<String> userRoles = [];
  bool isLoading = true;
  bool isRefreshing = false;
  
  DashboardType _activeDashboard = DashboardType.crm;
  
  // НОВОЕ: Флаг для проверки прав на дашборд учёта
  bool _hasAccountingDashboardPermission = false;

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
  Map<String, dynamic>? tutorialProgress;
  bool _hasDashboardIndexPermission = false;
  bool _isPermissionsChecked = false;

  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();

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
          _checkPermissionsAndTutorial(),
          _checkAccountingDashboardPermission(), // НОВОЕ: Проверяем право
          Future.delayed(const Duration(seconds: 3)),
        ]);
        await prefs.setBool('isFirstTime', false);
      } else {
        await _loadUserRoles();
        await _checkPermissionsAndTutorial();
        await _checkAccountingDashboardPermission(); // НОВОЕ: Проверяем право
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // НОВОЕ: Метод для проверки права на дашборд учёта
  Future<void> _checkAccountingDashboardPermission() async {
    try {
      final hasPermission = await _apiService.hasPermission('accounting_dashboard');
      if (mounted) {
        setState(() {
          _hasAccountingDashboardPermission = hasPermission;
        });
      }
    } catch (e) {
      debugPrint('Ошибка при проверке права accounting_dashboard: $e');
      if (mounted) {
        setState(() {
          _hasAccountingDashboardPermission = false;
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
          await _apiService.getUserById(int.parse(userId));
      if (mounted) {
        setState(() {
          userRoles = userProfile.role?.map((role) => role.name).toList() ??
              ['No role assigned'];
        });
        await prefs.setString('userRoles', userRoles.join(','));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userRoles = ['Error loading roles'];
        });
      }
    }
  }

  Future<void> _checkPermissionsAndTutorial() async {
    if (_isPermissionsChecked) {
      return;
    }

    _isPermissionsChecked = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final progress = await _apiService.getTutorialProgress();

      setState(() {
        tutorialProgress = progress['result'];
        _hasDashboardIndexPermission =
            progress['result']['dashboard']?['index'] ?? false;
      });
      await prefs.setString(
          'tutorial_progress', json.encode(progress['result']));

      bool isTutorialShown = prefs.getBool('isTutorialShownDashboard') ?? false;

      setState(() {
        _isTutorialShown = isTutorialShown;
      });

      if (!isTutorialShown &&
          tutorialProgress != null &&
          !_hasDashboardIndexPermission &&
          mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _initTutorialTargets();
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching tutorial progress for dashboard: $e');
    }
  }

  void _initTutorialTargets() {
    targets.clear();
    if (userRoles.contains('admin')) {
      _initAdminTutorialTargets();
    } else if (userRoles.contains('manager')) {
      _initTutorialTargetsManagers();
    } else {
      _initTutorialTargetsUsers();
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
        contentPosition: ContentPosition.above,
        contentPadding: EdgeInsets.only(top: 5),
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
        contentPadding: EdgeInsets.only(top: 5),
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
    if (_isTutorialShown) {
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isTutorialShown = prefs.getBool('isTutorialShownDashboard') ?? false;

    if (isTutorialShown ||
        tutorialProgress == null ||
        _hasDashboardIndexPermission) {
      return;
    }

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
        prefs.setBool('isTutorialShownDashboard', true).then((_) {
          _apiService.markPageCompleted("dashboard", "index").catchError((e) {});
        });
        setState(() {
          _isTutorialShown = true;
        });
        return true;
      },
      onFinish: () async {
        await prefs.setBool('isTutorialShownDashboard', true);
        try {
          await _apiService.markPageCompleted("dashboard", "index");
        } catch (e) {}
        setState(() {
          _isTutorialShown = true;
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

  void _scrollToTarget(GlobalKey key) {
    final RenderObject? renderObject = key.currentContext?.findRenderObject();
    if (renderObject != null && renderObject is RenderBox) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
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

        if (_activeDashboard == DashboardType.crm) {
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
    
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SalesDashboardBloc(),
        ),
        BlocProvider(
          create: (context) => SalesDashboardGoodsBloc(),
        ),
        BlocProvider(
          create: (context) => SalesDashboardCashBalanceBloc(),
        ),
        BlocProvider(
          create: (context) => SalesDashboardCreditorsBloc(),
        ),
        BlocProvider(
          create: (context) => SalesDashboardDebtorsBloc(),
        ),
      ],
      child: Scaffold(
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
            showCallCenter: true,
            showEvent: false,
            showSeparateMyTasks: true,
            showMenuIcon: false,
            showCalendarDashboard: true,
            clearButtonClickFiltr: (bool) {},
            NotificationIconKey: keyNotificationIcon,
            MyTaskIconKey: keyMyTaskIcon,
          ),
        ),
        body: isClickAvatarIcon
            ? ProfileScreen()
            : Stack(
                children: [
                  Column(
                    children: [
                      // ИЗМЕНЕНО: Показываем переключатель только если есть право
                      if (_hasAccountingDashboardPermission)
                        DashboardSwitcher(
                          activeDashboard: _activeDashboard,
                          onDashboardChanged: (type) {
                            setState(() {
                              _activeDashboard = type;
                            });
                          },
                        ),
                      Expanded(
                        child: RefreshIndicator(
                          color: const Color(0xff1E2E52),
                          backgroundColor: Colors.white,
                          onRefresh: _onRefresh,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              // ИЗМЕНЕНО: Показываем дашборд учёта только если есть право
                              children: (_hasAccountingDashboardPermission && _activeDashboard == DashboardType.accounting)
                                  ? _buildAccountingDashboard()
                                  : _buildDashboardContent(),
                            ),
                          ),
                        ),
                      ),
                    ],
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
        ProcessSpeedGauge(key: keyAdminProcessSpeed),
        Divider(thickness: 1, color: Colors.grey[300]),
        DealStatsChart(key: keyAdminDealStats),
      ];
    } else if (userRoles.contains('manager')) {
      return [
        LeadConversionChartManager(key: keyAdminLeadConversion),
        Divider(thickness: 1, color: Colors.grey[300]),
        GoalCompletionChart(key: keyManagerGoalComplietion),
        Divider(thickness: 1, color: Colors.grey[300]),
        GraphicsDashboardManager(lineChartKey: keyAdminGraphics),
        Divider(thickness: 1, color: Colors.grey[300]),
        TaskChartWidgetManager(key: keyAdminTaskChart),
        Divider(thickness: 1, color: Colors.grey[300]),
        ProcessSpeedGaugeManager(key: keyAdminProcessSpeed),
        Divider(thickness: 1, color: Colors.grey[300]),
        DealStatsChartManager(key: keyAdminDealStats),
      ];
    } else {
      return [
        GoalCompletionChart(key: keyManagerGoalComplietion),
        Divider(thickness: 1, color: Colors.grey[300]),
        TaskChartWidgetManager(key: keyAdminTaskChart),
      ];
    }
  }

  List<Widget> _buildAccountingDashboard() {
    return [
      BlocConsumer<SalesDashboardBloc, SalesDashboardState>(
        listener: (context, state) {
          if (state is SalesDashboardError) {
            showCustomSnackBar(context: context, message: state.message, isSuccess: false);
          }
        },
        builder: (context, state) {
          if (state is SalesDashboardLoading) {
            return const Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            );
          } else if (state is SalesDashboardLoaded) {
            final SalesResponse? salesData = state.salesData;
            final List<AllNetProfitData> netProfitData = state.netProfitData;
            final List<AllOrdersData> orderDashboardData = state.orderDashboardData;
            final List<AllExpensesData> expenseStructureData = state.expenseStructureData;
            final List<AllProfitabilityData> profitabilityData = state.profitabilityData;
            final List<AllTopSellingData> topSellingData = state.topSellingData;

            return Column(
              children: [
                TopPart(state: state),
                const SizedBox(height: 16),
                TopSellingProductsChart(topSellingData),
                const SizedBox(height: 16),
                SalesDynamicsLineChart(salesData),
                const SizedBox(height: 16),
                NetProfitChart(netProfitData),
                const SizedBox(height: 16),
                ExpenseStructureChart(expenseStructureData),
                const SizedBox(height: 16),
                ProfitabilityChart(profitabilityData: profitabilityData),
                const SizedBox(height: 16),
                OrderQuantityChart(orderDashboardData: orderDashboardData),
                const SizedBox(height: 16),
              ],
            );
          } else {
            return Center(
              child: Text(AppLocalizations.of(context)!.translate('error_loading') ?? 'Ошибка загрузки'),
            );
          }
        },
      ),
    ];
  }
}

// Виджет переключателя дашбордов (без изменений)
class DashboardSwitcher extends StatelessWidget {
  final DashboardType activeDashboard;
  final Function(DashboardType) onDashboardChanged;

  const DashboardSwitcher({
    Key? key,
    required this.activeDashboard,
    required this.onDashboardChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              context: context,
              label: 'CRM',
              icon: Icons.dashboard_rounded,
              isActive: activeDashboard == DashboardType.crm,
              onTap: () => onDashboardChanged(DashboardType.crm),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTab(
              context: context,
              label: 'Учёт',
              icon: Icons.analytics_rounded,
              isActive: activeDashboard == DashboardType.accounting,
              onTap: () => onDashboardChanged(DashboardType.accounting),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xff1E2E52) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xff1E2E52).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontSize: 16,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w500,
                fontFamily: 'Gilroy',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TopPart extends StatelessWidget {
  final SalesDashboardState state;

  const TopPart({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final DashboardTopPart? salesDashboardTopPart = (state as SalesDashboardLoaded).salesDashboardTopPart;
    final IlliquidGoodsResponse illiquidGoodsData = (state as SalesDashboardLoaded).illiquidGoodsData;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                onTap: () {
                  showSimpleInfoDialog(context);
                },
                accentColor: Colors.orange,
                title: localizations.translate('illiquid_goods') ?? 'ТОВАРЫ/НЕЛИКВИДНЫМИ ТОВАРЫ',
                leading: const Icon(Icons.inventory_2, color: Colors.orange),
                amountText: "${illiquidGoodsData.result?.liquidChange ?? 0}/${illiquidGoodsData.result?.nonLiquidGoods ?? 0}",
                showCurrencySymbol: false,
                isUp: illiquidGoodsData.result?.liquidChangeFormatted.startsWith("+") ?? true,
                trendText: "${illiquidGoodsData.result?.liquidChangeFormatted ?? '0.0%'}/${illiquidGoodsData.result?.nonLiquidChangeFormatted ?? '0.0%'}",
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                onTap: () {
                  showCashBalanceDialog(context);
                },
                accentColor: Colors.blue,
                title: localizations.translate('cash_balance') ?? 'ОСТАТОК КАССЫ',
                leading: const Icon(Icons.account_balance_wallet, color: Colors.blue),
                amount: salesDashboardTopPart?.result?.cashBalance?.totalBalance ?? 0,
                showCurrencySymbol: salesDashboardTopPart?.result?.cashBalance?.currency != null,
                currencySymbol: salesDashboardTopPart?.result?.cashBalance?.currency ?? '₽',
                isUp: salesDashboardTopPart?.result?.cashBalance?.isPositiveChange ?? true,
                trendText: salesDashboardTopPart?.result?.cashBalance?.percentageChange.toString() ?? '0.0%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                onTap: () {
                  showCreditorsDialog(context);
                },
                accentColor: Colors.red,
                title: localizations.translate('our_debts') ?? 'НАШИ ДОЛГИ',
                leading: const Icon(Icons.trending_down, color: Colors.red),
                amount: salesDashboardTopPart?.result?.ourDebts?.currentDebts ?? 0,
                showCurrencySymbol: false,
                currencySymbol: '₽',
                isUp: salesDashboardTopPart?.result?.ourDebts?.isPositiveChange ?? false,
                trendText: salesDashboardTopPart?.result?.ourDebts?.percentageChange.toString() ?? '',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                onTap: () {
                  showDebtorsDialog(context);
                },
                accentColor: Colors.green,
                title: localizations.translate('owed_to_us') ?? 'НАМ ДОЛЖНЫ',
                leading: const Icon(Icons.trending_up, color: Colors.green),
                amount: salesDashboardTopPart?.result?.debtsToUs?.totalDebtsToUs ?? 0,
                showCurrencySymbol: false,
                isUp: salesDashboardTopPart?.result?.debtsToUs?.isPositiveChange ?? false,
                trendText: '${salesDashboardTopPart?.result?.debtsToUs?.percentageChange ?? 'n/a'}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}