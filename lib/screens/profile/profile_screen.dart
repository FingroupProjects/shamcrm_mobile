import 'dart:convert';

import 'package:crm_task_manager/bloc/organization/organization_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/models/organization_model.dart';
import 'package:crm_task_manager/screens/auth/login_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/biometric.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/edit_profile_button.dart';
import 'package:crm_task_manager/screens/profile/languages/languages.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/profile_button_1c.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/switch_button.dart';
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
  Map<String, dynamic>? tutorialProgress; // Добавлено: Для хранения прогресса туториалов

  // Ключи для подсказок
  final GlobalKey keyOrganizationWidget = GlobalKey();
  final GlobalKey keyProfileEdit = GlobalKey();
  final GlobalKey keyLanguageButton = GlobalKey();
  final GlobalKey keyPinChange = GlobalKey();
  final GlobalKey keyLogoutButton = GlobalKey();
  final GlobalKey keyToggleFeature = GlobalKey();
  final GlobalKey keyUpdateWidget1C = GlobalKey();
  final GlobalKey keySupportChat = GlobalKey();

  List<TargetFocus> targets = [];
  bool _isTutorialShown = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedOrganization();
    _checkPermission();
    _loadOrganizations();
    _fetchTutorialProgress(); // Добавлено: Загрузка прогресса туториалов
  }

  // Добавлено: Метод для получения прогресса туториалов
  Future<void> _fetchTutorialProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool isTutorialShown = prefs.getBool('isTutorialShownProfile') ?? false;
      
      if (!isTutorialShown) {
        final progress = await _apiService.getTutorialProgress();
        setState(() {
          tutorialProgress = progress['result'];
        });
        await prefs.setString('tutorial_progress', json.encode(progress['result']));
      } else {
        final savedProgress = prefs.getString('tutorial_progress');
        if (savedProgress != null) {
          setState(() {
            tutorialProgress = json.decode(savedProgress);
          });
        }
      }
    } catch (e) {
      print('Error fetching tutorial progress: $e');
    }
  }

Future<void> _saveOrganizationsToCache(List<Organization> organizations) async {
  final prefs = await SharedPreferences.getInstance();
  final jsonList = jsonEncode(organizations.map((org) => org.toJson()).toList());
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
    targets.addAll([
      createTarget(
        identify: "profileOrganizationWidget",
        keyTarget: keyOrganizationWidget,
        title: AppLocalizations.of(context)!
            .translate('tutorial_profile_organization_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_profile_organization_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
      createTarget(
        identify: "profileEditButton",
        keyTarget: keyProfileEdit,
        title: AppLocalizations.of(context)!
            .translate('tutorial_profile_edit_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_profile_edit_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
      createTarget(
        identify: "profileLanguageButton",
        keyTarget: keyLanguageButton,
        title: AppLocalizations.of(context)!
            .translate('tutorial_profile_language_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_profile_language_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
      createTarget(
        identify: "profilePinChange",
        keyTarget: keyPinChange,
        title: AppLocalizations.of(context)!
            .translate('tutorial_profile_pin_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_profile_pin_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
      createTarget(
        identify: "profileLogoutButton",
        keyTarget: keyLogoutButton,
        title: AppLocalizations.of(context)!
            .translate('tutorial_profile_logout_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_profile_logout_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
      createTarget(
        identify: "profileToggleFeature",
        keyTarget: keyToggleFeature,
        title: AppLocalizations.of(context)!
            .translate('tutorial_profile_toggle_feature_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_profile_toggle_feature_description'),
        align: ContentAlign.top,
        context: context,
        contentPosition: ContentPosition.below,
      ),
      createTarget(
        identify: "profileUpdateWidget1C",
        keyTarget: keyUpdateWidget1C,
        title: AppLocalizations.of(context)!
            .translate('tutorial_profile_update_1c_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_profile_update_1c_description'),
        align: ContentAlign.top,
        context: context,
        contentPosition: ContentPosition.below,
      ),
      createTarget(
        identify: "profileSupportChat",
        keyTarget: keySupportChat,
        title: AppLocalizations.of(context)!
            .translate('tutorial_profile_support_chat_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_profile_support_chat_description'),
        align: ContentAlign.top,
        context: context,
        contentPosition: ContentPosition.above,
      ),
    ]);
  }

  TargetFocus createTarget({
    required String identify,
    required GlobalKey keyTarget,
    required String title,
    required String description,
    required ContentAlign align,
    required BuildContext context,
    required ContentPosition contentPosition,
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
      shape: ShapeLightFocus.RRect,
      radius: 5,
    );
  }

  void _showTutorialIfNeeded() {
    _initTutorialTargets();
    if (!_isTutorialShown && tutorialProgress != null && tutorialProgress!['settings']?['index'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showTutorial();
        setState(() {
          _isTutorialShown = true;
        });
      });
    }
  }

  void showTutorial() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isTutorialShown = prefs.getBool('isTutorialShownProfile') ?? false;

    if (!isTutorialShown) {
      List<TargetFocus> visibleTargets = targets.where((target) {
        if (target.identify == "profileToggleFeature") {
          return _hasPermissionToAddLeadAndSwitch;
        }
        if (target.identify == "profileUpdateWidget1C") {
          return _hasPermissionForOneC;
        }
        return true;
      }).toList();

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
          prefs.setBool('isTutorialShownProfile', true);
          _apiService.markPageCompleted("settings", "index").catchError((e) {
            print('Error marking page completed on skip: $e');
          });
          return true;
        },
        onFinish: () async {
          await prefs.setBool('isTutorialShownProfile', true);
          try {
            await _apiService.markPageCompleted("settings", "index");
          } catch (e) {
            print('Error marking page completed on finish: $e');
          }
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

  void _onOrganizationChanged(String? newOrganization) {
    setState(() {
      _selectedOrganization = newOrganization;
    });
    if (newOrganization != null) {
      ApiService().saveSelectedOrganization(newOrganization);
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
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
                          size: 80.0,
                          duration: Duration(milliseconds: 1000),
                        ),
                      ),
                    );
                  } else if (state is OrganizationLoaded) {
                    final selectedOrg = _selectedOrganization != null
                        ? state.organizations.firstWhere(
                            (org) => org.id.toString() == _selectedOrganization,
                            orElse: () => state.organizations.first,
                          )
                        : state.organizations.first;

                    _showTutorialIfNeeded();

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
                        LogoutButtonWidget(key: keyLogoutButton),
                        if (_hasPermissionToAddLeadAndSwitch)
                          ToggleFeatureButton(key: keyToggleFeature),
                        if (_hasPermissionForOneC)
                          UpdateWidget1C(
                            key: keyUpdateWidget1C,
                            organization: selectedOrg,
                          ),
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
                            color: Colors.black,
                          ),
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
      floatingActionButton: FloatingActionButton(
        key: keySupportChat,
        onPressed: _openSupportChat,
        backgroundColor: Color(0xff1E2E52),
        child: Image.asset(
          'assets/icons/Profile/support_chat.png',
          width: 36,
          height: 36,
        ),
      ),
    );
  }
}