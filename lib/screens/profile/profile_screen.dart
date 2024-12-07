import 'package:crm_task_manager/bloc/organization/organization_state.dart';
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
    if (savedOrganization == null) {
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
            BlocBuilder<OrganizationBloc, OrganizationState>(
              builder: (context, state) {
                if (state is OrganizationLoading) {
                  return const Center(
                    child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(
                            color: Color(0xff1E2E52))),
                  );
                } else if (state is OrganizationLoaded) {
                  // Проверка на null для выбранной организации
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
                      const NotificationSettingsWidget(),
                      const PinChangeWidget(),
                      const ProfileEdit(),
                      const LogoutButtonWidget(),
                      UpdateWidget1C(
                        organization: selectedOrg,
                      ),
                    ],
                  );
                } else if (state is OrganizationError) {
                  // Отображение ошибки в случае неудачной загрузки
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Center(
                      child: Text(
                        'Ошибка загрузки организаций: ${state.message}',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:crm_task_manager/bloc/organization/organization_state.dart';
// import 'package:crm_task_manager/screens/profile/profile_widget/biometric.dart';
// import 'package:crm_task_manager/screens/profile/profile_widget/edit_profile_button.dart';
// import 'package:crm_task_manager/screens/profile/profile_widget/profile_button_1c.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:crm_task_manager/api/service/api_service.dart';
// import 'package:crm_task_manager/bloc/organization/organization_bloc.dart';
// import 'package:crm_task_manager/bloc/organization/organization_event.dart';
// import 'package:crm_task_manager/screens/profile/profile_widget/profile_organization_list.dart';
// import 'package:crm_task_manager/screens/profile/profile_widget/profile_logout.dart';
// import 'package:crm_task_manager/screens/profile/profile_widget/profile_notification_settings.dart';

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});

//   @override
//   _ProfileScreenState createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   String? _selectedOrganization;

//   @override
//   void initState() {
//     super.initState();
//     _loadSelectedOrganization();
//     context.read<OrganizationBloc>().add(FetchOrganizations());
//   }

//   Future<void> _loadSelectedOrganization() async {
//     final savedOrganization = await ApiService().getSelectedOrganization();
//     if (savedOrganization == null) {
//       final firstOrganization = await _getFirstOrganization();
//       if (firstOrganization != null) {
//         _onOrganizationChanged(firstOrganization);
//       }
//     } else {
//       setState(() {
//         _selectedOrganization = savedOrganization;
//       });
//     }
//   }

//   Future<String?> _getFirstOrganization() async {
//     final state = context.read<OrganizationBloc>().state;
//     if (state is OrganizationLoaded && state.organizations.isNotEmpty) {
//       return state.organizations.first.id.toString();
//     }
//     return null;
//   }

//   void _onOrganizationChanged(String? newOrganization) {
//     setState(() {
//       _selectedOrganization = newOrganization;
//     });

//     if (newOrganization != null) {
//       ApiService().saveSelectedOrganization(newOrganization);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             BlocBuilder<OrganizationBloc, OrganizationState>(
//               builder: (context, state) {
//                 if (state is OrganizationLoading) {
//                   return const Center(
//                     child: Padding(
//                       padding: EdgeInsets.symmetric(vertical: 20),
//                        child: CircularProgressIndicator(color: Color(0xff1E2E52))
//                     ),
//                   );
//                 } else if (state is OrganizationLoaded) {
//                   final selectedOrg = state.organizations.firstWhere(
//                     (org) => org.id.toString() == _selectedOrganization,
//                     orElse: () => state.organizations.first,
//                   );

//                   return Column(
//                     children: [
//                       OrganizationWidget(
//                         selectedOrganization: _selectedOrganization,
//                         onChanged: _onOrganizationChanged,
//                       ),
//                       const NotificationSettingsWidget(),
//                       const PinChangeWidget(),
//                       const ProfileEdit(),
//                       const LogoutButtonWidget(),
//                       UpdateWidget1C(organization: selectedOrg,
//                       ),
//                     ],
//                   );
//                 } else if (state is OrganizationError) {
//                   return Text('Ошибка загрузки организаций: ${state.message}');
//                 } else {
//                   return const SizedBox.shrink();
//                 }
//               },
//             ),


//           ],
//         ),
//       ),
//     );
//   }
// }
