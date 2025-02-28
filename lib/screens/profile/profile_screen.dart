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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/organization/organization_bloc.dart';
import 'package:crm_task_manager/bloc/organization/organization_event.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/profile_organization_list.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/profile_logout.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        _selectedOrganization = newOrganizations.isNotEmpty ? newOrganizations.first.id.toString() : null;
      });
    }
  } else {
    context.read<OrganizationBloc>().add(FetchOrganizations());
  }
}

@override
void initState() {
  super.initState();
  _loadSelectedOrganization();
  _checkPermission();
  _loadOrganizations();
}


  Future<void> _checkPermission() async {
    bool hasPermission = await _apiService.hasPermission('lead.create');
    setState(() {
      _hasPermissionToAddLeadAndSwitch = hasPermission;
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
                    return Column(
                      children: [
                        OrganizationWidget(
                          selectedOrganization: _selectedOrganization,
                          onChanged: _onOrganizationChanged,
                        ),
                        const ProfileEdit(),
                        const LanguageButtonWidget(),
                        const PinChangeWidget(),
                        const LogoutButtonWidget(),
                        //   if(_hasPermissionToAddLeadAndSwitch)
                        // const ToggleFeatureButton(),
                        UpdateWidget1C(organization: selectedOrg),
                      ],
                    );
                  } else if (state is OrganizationError) {
                    if (state.message.contains( localizations.translate("unauthorized_access"))) {
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
