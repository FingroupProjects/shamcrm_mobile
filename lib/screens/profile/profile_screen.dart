import 'package:crm_task_manager/bloc/organization/organization_state.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/biometric.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/organization/organization_bloc.dart';
import 'package:crm_task_manager/bloc/organization/organization_event.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/profile_organization_list.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/profile_logout.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/profile_notification_settings.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _selectedOrganization;

  @override
  void initState() {
    super.initState();
    _loadSelectedOrganization();
    context.read<OrganizationBloc>().add(FetchOrganizations());
  }

  Future<void> _loadSelectedOrganization() async {
    final savedOrganization = await ApiService().getSelectedOrganization();
    if (savedOrganization == null) {
      // Если организация не сохранена, то выберем первую из списка
      final firstOrganization = await _getFirstOrganization();
      if (firstOrganization != null) {
        _onOrganizationChanged(firstOrganization);
      }
    } else {
      setState(() {
        _selectedOrganization = savedOrganization;
      });
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             OrganizationWidget(
              selectedOrganization: _selectedOrganization,
              onChanged: _onOrganizationChanged,
            ),
            const NotificationSettingsWidget(),
            const PinChangeWidget(),
            const LogoutButtonWidget(),
          ],
        ),
      ),
    );
  }
}