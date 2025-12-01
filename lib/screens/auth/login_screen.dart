import 'dart:io';
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
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final TextEditingController loginController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocListener<LoginBloc, LoginState>(
          listener: (context, state) async {
            if (state is LoginLoaded) {
              debugPrint('LoginScreen: Успешный вход');

              userID.value = state.user.id.toString();

              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('userName', state.user.name.toString());
              await prefs.setString('userID', state.user.id.toString());
              await prefs.setString('userLogin', state.user.login.toString());
              await prefs.setBool('hasMiniApp', state.hasMiniApp);

              if (state.user.role != null && state.user.role!.isNotEmpty) {
                await prefs.setString('userRoleName', state.user.role![0].name);
                String allRoles = state.user.role!.map((r) => r.name).join(', ');
                await prefs.setString('userAllRoles', allRoles);
              }

              // FCM-токен отправится в PinSetupScreen — здесь НЕ трогаем!
              await Future.delayed(Duration(seconds: 1));
              await _checkPinSetupStatus(context);
            } else if (state is LoginError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
            }
          },
          child: BlocBuilder<LoginBloc, LoginState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 75),
                  Text(localizations!.translate('login_title'), style: TextStyle(fontSize: 38, fontWeight: FontWeight.w600, fontFamily: 'Gilroy')),
                  SizedBox(height: 8),
                  Text(localizations.translate('login_subtitle'), style: TextStyle(fontSize: 14, color: Color(0xff99A4BA), fontWeight: FontWeight.w500, fontFamily: 'Gilroy')),
                  SizedBox(height: 16),
                  CustomTextField(controller: loginController, hintText: localizations.translate('login_username_hint'), label: localizations.translate('login_username_label')),
                  SizedBox(height: 16),
                  CustomTextField(controller: passwordController, hintText: localizations.translate('login_password_hint'), label: localizations.translate('login_password_label'), isPassword: true),
                  SizedBox(height: 16),
                  if (state is LoginLoading)
                    Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)))
                  else
                    CustomButton(
                      buttonText: localizations.translate('login_button'),
                      buttonColor: Color(0xff4F40EC),
                      textColor: Colors.white,
                      onPressed: () {
                        final login = loginController.text.trim();
                        final password = passwordController.text.trim();
                        if (login.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Заполните все поля')));
                          return;
                        }
                        context.read<LoginBloc>().add(CheckLogin(login, password));
                      },
                    ),
                  SizedBox(height: 16),
                  ForgotPassword(onPressed: () {}),
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
      await prefs.setBool('isPinSetupComplete', true);
      Navigator.pushReplacementNamed(context, '/pin_setup');
    } else {
      Navigator.pushReplacementNamed(context, '/pin_screen');
    }
  }
}