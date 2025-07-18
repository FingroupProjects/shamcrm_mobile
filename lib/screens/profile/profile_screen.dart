import 'dart:convert';
import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/lead_chart/chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/lead_chart/chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/process_speed/ProcessSpeed_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/process_speed/ProcessSpeed_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/task_chart/task_chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/task_chart/task_chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/user_task/user_task_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/user_task/user_task_event.dart';
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
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/organization/organization_state.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/models/organization_model.dart';
import 'package:crm_task_manager/notification_cache.dart';
import 'package:crm_task_manager/screens/auth/login_screen.dart';
import 'package:crm_task_manager/screens/deal/deal_cache.dart';
import 'package:crm_task_manager/screens/lead/lead_cache.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/biometric.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/edit_profile_button.dart';
import 'package:crm_task_manager/screens/profile/languages/languages.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/phone_call_widget.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/profile_button_1c.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/switch_button.dart';
import 'package:crm_task_manager/screens/task/task_cache.dart';
import 'package:crm_task_manager/utils/TutorialStyleWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/organization/organization_bloc.dart';
import 'package:crm_task_manager/bloc/organization/organization_event.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/profile_organization_list.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/profile_logout.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _selectedOrganization;
  final ApiService _apiService = ApiService();
  bool _hasPermissionToAddLeadAndSwitch = false;
  bool _hasPermissionForOneC = false;
  Map<String, dynamic>? tutorialProgress;
  bool _hasSettingsIndexPermission = false;
  bool _isPermissionsChecked = false;

  final GlobalKey keyOrganizationWidget = GlobalKey();
  final GlobalKey keyProfileEdit = GlobalKey();
  final GlobalKey keyLanguageButton = GlobalKey();
  final GlobalKey keyPinChange = GlobalKey();
  final GlobalKey keyLogoutButton = GlobalKey();
  final GlobalKey keyToggleFeature = GlobalKey();
  final GlobalKey keyUpdateWidget1C = GlobalKey();
  final GlobalKey keySupportChat = GlobalKey();
final GlobalKey keyPhoneCall = GlobalKey();
  List<TargetFocus> targets = [];
  bool _isTutorialShown = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedOrganization();
    _checkPermission();
    _loadOrganizations();

    // Даем время на инициализацию, затем проверяем разрешения и показываем туториал
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Дополнительная задержка для полной загрузки интерфейса
      await Future.delayed(Duration(milliseconds: 500));
      _checkPermissionsAndTutorial();
    });
  }

  Future<void> _saveOrganizationsToCache(
      List<Organization> organizations) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList =
        jsonEncode(organizations.map((org) => org.toJson()).toList());
    await prefs.setString('cached_organizations', jsonList);
  }

  Future<List<Organization>> _getOrganizationsFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('cached_organizations');
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((data) => Organization.fromJson(data)).toList();
    }
    return [];
  }

  Future<void> _loadOrganizations() async {
    final cachedOrganizations = await _getOrganizationsFromCache();
    final currentState = context.read<OrganizationBloc>().state;

    if (currentState is OrganizationLoaded) {
      final newOrganizations = currentState.organizations;
      if (jsonEncode(newOrganizations) != jsonEncode(cachedOrganizations)) {
        await _saveOrganizationsToCache(newOrganizations);
        setState(() {
          _selectedOrganization = newOrganizations.isNotEmpty
              ? newOrganizations.first.id.toString()
              : null;
        });
      }
    } else {
      context.read<OrganizationBloc>().add(FetchOrganizations());
    }
  }

  void _initTutorialTargets() {
    // Сбрасываем список целей
    targets = [];

    // Добавляем только те цели, которые должны быть видимы и существуют на экране
    // Обратите внимание на проверку currentContext для каждой цели

    if (keyOrganizationWidget.currentContext != null) {
      targets.add(createTarget(
        identify: "profileOrganizationWidget",
        keyTarget: keyOrganizationWidget,
        title: AppLocalizations.of(context)!
            .translate('tutorial_profile_organization_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_profile_organization_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
        shape: ShapeLightFocus.RRect, // Явное указание прямоугольной формы
        radius: 5,
      ));
    }

    if (keyProfileEdit.currentContext != null) {
      targets.add(createTarget(
        identify: "profileEditButton",
        keyTarget: keyProfileEdit,
        title: AppLocalizations.of(context)!
            .translate('tutorial_profile_edit_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_profile_edit_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
        shape: ShapeLightFocus.RRect, // Явное указание прямоугольной формы
        radius: 5,
      ));
    }

    if (keyLanguageButton.currentContext != null) {
      targets.add(createTarget(
        identify: "profileLanguageButton",
        keyTarget: keyLanguageButton,
        title: AppLocalizations.of(context)!
            .translate('tutorial_profile_language_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_profile_language_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
        shape: ShapeLightFocus.RRect, // Явное указание прямоугольной формы
        radius: 5,
      ));
    }

    if (keyPinChange.currentContext != null) {
      targets.add(createTarget(
        identify: "profilePinChange",
        keyTarget: keyPinChange,
        title: AppLocalizations.of(context)!
            .translate('tutorial_profile_pin_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_profile_pin_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
        shape: ShapeLightFocus.RRect, // Явное указание прямоугольной формы
        radius: 5,
      ));
    }

    if (keyLogoutButton.currentContext != null) {
      targets.add(createTarget(
        identify: "profileLogoutButton",
        keyTarget: keyLogoutButton,
        title: AppLocalizations.of(context)!
            .translate('tutorial_profile_logout_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_profile_logout_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
        shape: ShapeLightFocus.RRect, // Явное указание прямоугольной формы
        radius: 5,
      ));
    }

    // Проверка и разрешения И существования виджета в дереве
    if (_hasPermissionToAddLeadAndSwitch &&
        keyToggleFeature.currentContext != null) {
      targets.add(createTarget(
        identify: "profileToggleFeature",
        keyTarget: keyToggleFeature,
        title: AppLocalizations.of(context)!
            .translate('tutorial_profile_toggle_feature_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_profile_toggle_feature_description'),
        align: ContentAlign.top,
        context: context,
        contentPosition: ContentPosition.below,
        shape: ShapeLightFocus.RRect, // Явное указание прямоугольной формы
        radius: 5,
      ));
    }

    // Точно такой же подход для 1C - проверяем И разрешение И существование виджета
    if (_hasPermissionForOneC && keyUpdateWidget1C.currentContext != null) {
      targets.add(createTarget(
        identify: "profileUpdateWidget1C",
        keyTarget: keyUpdateWidget1C,
        title: AppLocalizations.of(context)!
            .translate('tutorial_profile_update_1c_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_profile_update_1c_description'),
        align: ContentAlign.top,
        context: context,
        contentPosition: ContentPosition.below,
        shape: ShapeLightFocus.RRect, // Явное указание прямоугольной формы
        radius: 5,
      ));
    }

    // Проверяем наличие виджета техподдержки
    if (keySupportChat.currentContext != null) {
      targets.add(createTarget(
        identify: "profileSupportChat",
        keyTarget: keySupportChat,
        title: AppLocalizations.of(context)!
            .translate('tutorial_profile_support_chat_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_profile_support_chat_description'),
        align: ContentAlign.top,
        context: context,
        contentPosition: ContentPosition.above,
        shape: ShapeLightFocus
            .RRect, // Явное указание прямоугольной формы с закругленными углами для кнопки
        radius: 30, // Большее значение для FAB, так как он круглый
      ));
    }
  }

// Удаляем функцию createTarget, так как теперь параметры задаются прямо в _initTutorialTargets
// Если эта функция используется в других местах, оставьте её с дополнительным параметром shape
  TargetFocus createTarget({
    required String identify,
    required GlobalKey keyTarget,
    required String title,
    required String description,
    required ContentAlign align,
    required BuildContext context,
    required ContentPosition contentPosition,
    ShapeLightFocus shape =
        ShapeLightFocus.RRect, // По умолчанию прямоугольная форма
    double radius = 5,
    EdgeInsets contentPadding = EdgeInsets.zero,
  }) {
    return TargetFocus(
      identify: identify,
      keyTarget: keyTarget,
      contents: [
        TargetContent(
          align: align,
          child: Container(
            padding: contentPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Gilroy',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    description,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      shape: shape, // Используем переданную форму
      radius: radius, // Используем переданный радиус
    );
  }

  void showTutorial() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isTutorialShown = prefs.getBool('isTutorialShownProfile') ?? false;

    if (isTutorialShown || _hasSettingsIndexPermission) return;

    // Теперь targets уже содержит только действительно видимые цели,
    // поэтому дополнительная фильтрация не требуется
    List<TargetFocus> visibleTargets = targets;

    // Если нет видимых целей, отмечаем туториал как просмотренный и выходим
    if (visibleTargets.isEmpty) {
      await prefs.setBool('isTutorialShownProfile', true);
      await _apiService.markPageCompleted("settings", "index").catchError((e) {
        //print('Error marking page completed - no visible targets: $e');
      });
      setState(() {
        _isTutorialShown = true;
      });
      return;
    }

    // Добавляем небольшую задержку, чтобы убедиться, что все элементы загрузились
    await Future.delayed(Duration(milliseconds: 500));

    TutorialCoachMark(
      targets: visibleTargets,
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
        //print("Tutorial skipped");
        prefs.setBool('isTutorialShownProfile', true);
        _apiService.markPageCompleted("settings", "index").catchError((e) {
          //print('Error marking page completed on skip: $e');
        });
        setState(() {
          _isTutorialShown = true;
        });
        return true;
      },
      onFinish: () async {
        await prefs.setBool('isTutorialShownProfile', true);
        await _apiService
            .markPageCompleted("settings", "index")
            .catchError((e) {
          //print('Error marking page completed on finish: $e');
        });
        setState(() {
          _isTutorialShown = true;
        });
      },
      onClickTarget: (target) async {
        int currentIndex =
            visibleTargets.indexWhere((t) => t.identify == target.identify);
        if (currentIndex < visibleTargets.length - 1) {
          final nextTarget = visibleTargets[currentIndex + 1];
          if (nextTarget.keyTarget != null) {
            await Future.delayed(Duration(milliseconds: 300));
            _scrollToTarget(nextTarget.keyTarget!);
          }
        }
      },
    ).show(context: context);
  }

  Future<void> _checkPermissionsAndTutorial() async {
    if (_isPermissionsChecked) return;

    _isPermissionsChecked = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final progress = await _apiService.getTutorialProgress();

      setState(() {
        tutorialProgress = progress['result'];
        _hasSettingsIndexPermission =
            progress['result']['settings']?['index'] ?? false;
      });
      await prefs.setString(
          'tutorial_progress', json.encode(progress['result']));

      bool isTutorialShown = prefs.getBool('isTutorialShownProfile') ?? false;
      setState(() {
        _isTutorialShown = isTutorialShown;
      });

      if (!isTutorialShown && !_hasSettingsIndexPermission && mounted) {
        // Критически важно: даем время на полное построение UI
        await Future.delayed(Duration(milliseconds: 1000));

        if (mounted) {
          // Инициализация будет делать проверку currentContext,
          // которая возможна только после построения UI
          _initTutorialTargets();
          showTutorial();
        }
      }
    } catch (e) {
      //print('Error fetching tutorial progress: $e');
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
    }
  }

  Future<void> _checkPermission() async {
    bool hasLeadCreatePermission =
        await _apiService.hasPermission('lead.create');
    bool hasLeadOneCPermission = await _apiService.hasPermission('lead.oneC');
    setState(() {
      _hasPermissionToAddLeadAndSwitch = hasLeadCreatePermission;
      _hasPermissionForOneC = hasLeadOneCPermission;
    });
  }

  Future<void> _loadSelectedOrganization() async {
    final savedOrganization = await ApiService().getSelectedOrganization();
    if (savedOrganization != null) {
      setState(() {
        _selectedOrganization = savedOrganization;
      });
    } else {
      final firstOrganization = await _getFirstOrganization();
      if (firstOrganization != null) {
        _onOrganizationChanged(firstOrganization);
      }
    }
  }

  Future<String?> _getFirstOrganization() async {
    final state = context.read<OrganizationBloc>().state;
    if (state is OrganizationLoaded && state.organizations.isNotEmpty) {
      return state.organizations.first.id.toString();
    }
    return null;
  }

  Future<void> _onOrganizationChanged(String? newOrganization) async {
    setState(() {
      _selectedOrganization = newOrganization;
    });
    if (newOrganization != null) {
      ApiService().saveSelectedOrganization(newOrganization);

      await DealCache.clearDealStatuses();
      await DealCache.clearAllDeals();

      await LeadCache.clearLeadStatuses();
      await LeadCache.clearAllLeads();

      await TaskCache.clearTaskStatuses();
      await TaskCache.clearAllTasks();

      await NotificationCacheHandler.clearCache();

      BlocProvider.of<DealBloc>(context).add(FetchDealStatuses());
      BlocProvider.of<LeadBloc>(context).add(FetchLeadStatuses());
      BlocProvider.of<TaskBloc>(context).add(FetchTaskStatuses());

      context.read<TaskCompletionBloc>().add(LoadTaskCompletionData());
      context.read<DashboardChartBloc>().add(LoadLeadChartData());
      context.read<DashboardChartBlocManager>().add(LoadLeadChartDataManager());
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

  void _openSupportChat() async {
    const tgUrl = 'https://t.me/shamcrm_bot';
    const webUrl = 'https://t.me/shamcrm_bot';
    if (await canLaunchUrl(Uri.parse(tgUrl))) {
      await launchUrl(Uri.parse(tgUrl), mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
    }
  }

 @override
Widget build(BuildContext context) {
  final localizations = AppLocalizations.of(context)!;
  return Scaffold(
    body: SafeArea( // SafeArea обеспечивает отступы от системных элементов
      child: Stack(
        children: [
          // Основной контент
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 80), // Место для версии
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BlocBuilder<OrganizationBloc, OrganizationState>(
                    builder: (context, state) {
                      if (state is OrganizationLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: PlayStoreImageLoading(
                                size: 80.0, duration: Duration(milliseconds: 1000)),
                          ),
                        );
                      } else if (state is OrganizationLoaded) {
                        final selectedOrg = _selectedOrganization != null
                            ? state.organizations.firstWhere(
                                (org) => org.id.toString() == _selectedOrganization,
                                orElse: () => state.organizations.first,
                              )
                            : state.organizations.first;

                        return Column(
                          children: [
                            OrganizationWidget(
                              key: keyOrganizationWidget,
                              selectedOrganization: _selectedOrganization,
                              onChanged: _onOrganizationChanged,
                            ),
                            ProfileEdit(key: keyProfileEdit),
                            LanguageButtonWidget(key: keyLanguageButton),
                            PinChangeWidget(key: keyPinChange),
                            // PhoneCallWidget(key: keyPhoneCall),
                            LogoutButtonWidget(key: keyLogoutButton),
                            if (_hasPermissionToAddLeadAndSwitch)
                              ToggleFeatureButton(key: keyToggleFeature),
                            if (_hasPermissionForOneC)
                              UpdateWidget1C(organization: selectedOrg),
                          ],
                        );
                      } else if (state is OrganizationError) {
                        if (state.message.contains(
                            localizations.translate("unauthorized_access"))) {
                          ApiService().logout().then((_) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginScreen()),
                              (Route<dynamic> route) => false,
                            );
                          });
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Center(
                            child: Text(
                              '${state.message}',
                              style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Версия прикреплена к низу SafeArea
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Text(
                '${AppLocalizations.of(context)!.translate('version_mobile')}: 1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 6, 44, 231),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
