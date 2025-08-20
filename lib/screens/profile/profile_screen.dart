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
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
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
import 'dart:io' show Platform; // Добавляем импорт для проверки платформы

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

  // ЗАКОММЕНТИРОВАНЫ ВСЕ КЛЮЧИ ДЛЯ ОТКЛЮЧЕНИЯ ТУТОРИАЛА
  // final GlobalKey keyOrganizationWidget = GlobalKey();
  // final GlobalKey keyProfileEdit = GlobalKey();
  // final GlobalKey keyLanguageButton = GlobalKey();
  // final GlobalKey keyPinChange = GlobalKey();
  // final GlobalKey keyLogoutButton = GlobalKey();
  // final GlobalKey keyToggleFeature = GlobalKey();
  // final GlobalKey keyUpdateWidget1C = GlobalKey();
  // final GlobalKey keySupportChat = GlobalKey();
  // final GlobalKey keyPhoneCall = GlobalKey();
  
  List<TargetFocus> targets = [];
  bool _isTutorialShown = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedOrganization();
    _checkPermission();
    _loadOrganizations();

    // ЗАКОММЕНТИРОВАН ВЫЗОВ ТУТОРИАЛА
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   await Future.delayed(Duration(milliseconds: 500));
    //   _checkPermissionsAndTutorial();
    // });
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

  Future<void> _openAppStoreLink() async {
    const androidUrl = 'https://play.google.com/store/apps/details?id=com.softtech.crm_task_manager';
    const iosUrl = 'https://apps.apple.com/tj/app/shamcrm/id6745598713';
    final url = Platform.isAndroid ? androidUrl : iosUrl;

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        showCustomSnackBar(
          context: context,
          message: AppLocalizations.of(context)!.translate('failed_to_open_link'),
          isSuccess: false,
        );
      }
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: AppLocalizations.of(context)!.translate('failed_to_open_link'),
        isSuccess: false,
      );
    }
  }

  // ВСЕ ФУНКЦИИ ТУТОРИАЛА ЗАКОММЕНТИРОВАНЫ
  /*
  void _initTutorialTargets() {
    targets = [];

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
        shape: ShapeLightFocus.RRect,
        radius: 5,
      ));
    }

    // ... остальные targets
  }

  TargetFocus createTarget({
    required String identify,
    required GlobalKey keyTarget,
    required String title,
    required String description,
    required ContentAlign align,
    required BuildContext context,
    required ContentPosition contentPosition,
    ShapeLightFocus shape = ShapeLightFocus.RRect,
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
      shape: shape,
      radius: radius,
    );
  }

  void showTutorial() async {
    // Весь код туториала закомментирован
  }

  Future<void> _checkPermissionsAndTutorial() async {
    // Весь код проверки туториала закомментирован
  }

  void _scrollToTarget(GlobalKey key) {
    // Функция скролла закомментирована
  }
  */

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
    const tgUrl = 'https://t.me/shamcrm_support_bot';
    const webUrl = 'https://t.me/shamcrm_support_bot:';
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
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 80),
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
                                selectedOrganization: _selectedOrganization,
                                onChanged: _onOrganizationChanged,
                              ),
                              ProfileEdit(),
                              LanguageButtonWidget(),
                              PinChangeWidget(),
                              LogoutButtonWidget(),
                              if (_hasPermissionToAddLeadAndSwitch)
                                ToggleFeatureButton(),
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
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: _openAppStoreLink,
                  child: Text(
                    '${AppLocalizations.of(context)!.translate('version_mobile')}: 2.0.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(255, 6, 44, 231),
                      decoration: TextDecoration.none,
                    ),
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