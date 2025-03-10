import 'package:crm_task_manager/bloc/login/login_bloc.dart';
import 'package:crm_task_manager/bloc/login/login_event.dart';
import 'package:crm_task_manager/bloc/login/login_state.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_value.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/widgets/forgot_password.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final TextEditingController loginController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final apiService = context.read<ApiService>();
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocListener<LoginBloc, LoginState>(
          listener: (context, state) async {
            if (state is LoginLoaded) {
              print('Received userId: ${state.user.id}');
              userID.value = state.user.id.toString();

              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('userName', state.user.name.toString());
              await prefs.setString('userID', state.user.id.toString());
              await prefs.setString('userLogin', state.user.login.toString());

              // Сохраняем первую роль как раньше для обратной совместимости
              if (state.user.role != null && state.user.role!.isNotEmpty) {
                await prefs.setString('userRoleName', state.user.role![0].name);
                // Сохраняем все роли в новое поле, соединяя их через запятую
                String allRoles =
                    state.user.role!.map((role) => role.name).join(', ');
                await prefs.setString('userAllRoles', allRoles);
              } else {
                await prefs.setString('userRoleName', 'No role assigned');
                await prefs.setString('userAllRoles', 'No role assigned');
              }

              String? fcmToken = await FirebaseMessaging.instance.getToken();
              if (fcmToken != null) {
                await apiService.sendDeviceToken(fcmToken);
              }

              final savedOrganization =
                  await apiService.getSelectedOrganization();
              if (savedOrganization == null) {
                final organizations = await apiService.getOrganization();
                if (organizations.isNotEmpty) {
                  final firstOrganization = organizations.first;
                  await apiService.saveSelectedOrganization(
                      firstOrganization.id.toString());
                }
              }

              // Показываем анимацию 2 секунды перед переходом
              await Future.delayed(Duration(seconds: 2));
              await _checkPinSetupStatus(context);
            } else if (state is LoginError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${state.message}',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.red,
                    elevation: 3,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    duration: Duration(seconds: 3),
                  ),
                );
              });
            }
          },
          child: BlocBuilder<LoginBloc, LoginState>(
            builder: (context, state) {
              final localizations = AppLocalizations.of(context);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 75),
                  Text(
                    localizations!.translate('login_title'),
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    localizations.translate('login_subtitle'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xff99A4BA),
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                  SizedBox(height: 16),
                  CustomTextField(
                    controller: loginController,
                    hintText: localizations.translate('login_username_hint'),
                    label: localizations.translate('login_username_label'),
                  ),
                  SizedBox(height: 16),
                  CustomTextField(
                    controller: passwordController,
                    hintText: localizations.translate('login_password_hint'),
                    label: localizations.translate('login_password_label'),
                    isPassword: true,
                  ),
                  SizedBox(height: 16),
                  // Показываем анимацию загрузки для состояний LoginLoading и LoginLoaded
                  if (state is LoginLoading || state is LoginLoaded)
                    Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff1E2E52),
                      ),
                    )
                  // Показываем кнопку только если состояние Initial или Error
                  else
                    CustomButton(
                      buttonText: localizations.translate('login_button'),
                      buttonColor: Color(0xff4F40EC),
                      textColor: Colors.white,
                      onPressed: () {
                        final login = loginController.text.trim();
                        final password = passwordController.text.trim();
                        if (login.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(localizations
                                  .translate('login_empty_fields_error')),
                            ),
                          );
                          return;
                        }
                        BlocProvider.of<LoginBloc>(context)
                            .add(CheckLogin(login, password));
                      },
                    ),
                  SizedBox(height: 16),
                  ForgotPassword(
                    onPressed: () {},
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _checkPinSetupStatus(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final isPinSetupComplete = prefs.getBool('isPinSetupComplete') ?? false;

    if (!isPinSetupComplete) {
      prefs.setBool('isPinSetupComplete', true);
      Navigator.pushReplacementNamed(context, '/pin_setup');
    } else {
      Navigator.pushReplacementNamed(context, '/pin_screen');
    }
  }
}
