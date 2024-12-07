import 'package:crm_task_manager/bloc/login/login_bloc.dart';
import 'package:crm_task_manager/bloc/login/login_event.dart';
import 'package:crm_task_manager/bloc/login/login_state.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocListener<LoginBloc, LoginState>(
          listener: (context, state) async {
            if (state is LoginLoaded) {
              // Сохраняем userID после успешного входа
              userID.value = state.user.id.toString();

              // Сохранение имени пользователя в SharedPreferences
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('userName', state.user.name.toString());
              await prefs.setString('userID', state.user.id.toString());
              await prefs.setString('userPhone', state.user.phone.toString());
              await prefs.setString('userLogin', state.user.login.toString());
              await prefs.setString('userImage', state.user.image.toString());
              if (state.user.role != null && state.user.role!.isNotEmpty) {
                await prefs.setString('userRoleName', state.user.role![0].name);
              } else {
                // Обработка ситуации, когда role пусто или null
                await prefs.setString('userRoleName', 'No role assigned');
              }
              await prefs.setString('userEmail', state.user.email.toString());

              // Получаем токен устройства и отправляем его на сервер
              String? fcmToken = await FirebaseMessaging.instance.getToken();
              if (fcmToken != null) {
                await apiService.sendDeviceToken(fcmToken);
              }

              // Проверяем сохранённую организацию
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

              // Проверяем состояние PIN-настройки
              await _checkPinSetupStatus(context);
            } else if (state is LoginError) {
              // Показываем сообщение об ошибке
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          child: BlocBuilder<LoginBloc, LoginState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 75),
                  const Text(
                    'Вход',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                  SizedBox(height: 8),
                  const Text(
                    'Введите логин и пароль для входа',
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
                    hintText: 'Введите логин',
                    label: 'Логин',
                  ),
                  SizedBox(height: 16),
                  CustomTextField(
                    controller: passwordController,
                    hintText: 'Введите пароль',
                    label: 'Пароль',
                    isPassword: true,
                  ),
                  SizedBox(height: 16),
                  state is LoginLoading
                      ? Center(
                          child: CircularProgressIndicator(
                              color: Color(0xff1E2E52)))
                      : CustomButton(
                          buttonText: 'Войти',
                          buttonColor: Color(0xff4F40EC),
                          textColor: Colors.white,
                          onPressed: () {
                            final login = loginController.text.trim();
                            final password = passwordController.text.trim();
                            if (login.isEmpty || password.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Пожалуйста, заполните все поля'),
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
      // Первый раз: переходим на страницу /pin_setup
      prefs.setBool('isPinSetupComplete', true);
      Navigator.pushReplacementNamed(context, '/pin_setup');
    } else {
      // Последующие разы: переходим на страницу /pin_screen
      Navigator.pushReplacementNamed(context, '/pin_screen');
    }
  }
}
