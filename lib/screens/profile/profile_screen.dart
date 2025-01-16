import 'package:crm_task_manager/bloc/organization/organization_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/screens/auth/login_screen.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/biometric.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/edit_profile_button.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/languages.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/profile_button_1c.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/organization/organization_bloc.dart';
import 'package:crm_task_manager/bloc/organization/organization_event.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/profile_organization_list.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/profile_logout.dart';

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

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                      // const NotificationSettingsWidget(),
                      const PinChangeWidget(),
                      const ProfileEdit(),
                      const LanguageButtonWidget(),
                      const LogoutButtonWidget(),
                      UpdateWidget1C(organization: selectedOrg),
                    ],
                  );
                } else if (state is OrganizationError) {
                  if (state.message.contains("Неавторизованный доступ!")) {
                    ApiService().logout().then((_) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
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
    );
  }
}



/*
import 'package:crm_task_manager/bloc/organization/organization_state.dart';
import 'package:crm_task_manager/screens/auth/login_screen.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/biometric.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/edit_profile_button.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/profile_button_1c.dart';
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


@override
Widget build(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: SingleChildScrollView(
      child: BlocBuilder<OrganizationBloc, OrganizationState>(
        builder: (context, state) {
          if (state is OrganizationLoading) {
            // Состояние загрузки
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(color: Color(0xff1E2E52)),
              ),
            );
          } else if (state is OrganizationLoaded) {
            // Состояние успешной загрузки
            final selectedOrg = _selectedOrganization != null
                ? state.organizations.firstWhere(
                    (org) => org.id.toString() == _selectedOrganization,
                    orElse: () => state.organizations.first,
                  )
                : state.organizations.first;

            return Column(
              children: [
                // Добавляем изображение
                Center(
                  child: Image.asset(
                    'assets/icons/11.jpg',
                    height: 100, // Настройка размера изображения
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16), // Отступ между изображением и остальными элементами

                // Виджет организации
                OrganizationWidget(
                  selectedOrganization: _selectedOrganization,
                  onChanged: _onOrganizationChanged,
                ),

                // Остальные виджеты, которые зависят от загрузки
                const PinChangeWidget(),
                const ProfileEdit(),
                const LogoutButtonWidget(),
                UpdateWidget1C(organization: selectedOrg),
              ],
            );
          } else if (state is OrganizationError) {
            // Состояние ошибки
            if (state.message.contains("Неавторизованный доступ!")) {
              ApiService().logout().then((_) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
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
          // Пустое состояние, если ничего не загружено
          return const SizedBox.shrink();
        },
      ),
    ),
  );
}

}

*/