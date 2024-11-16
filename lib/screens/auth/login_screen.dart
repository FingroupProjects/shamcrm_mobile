import 'package:crm_task_manager/bloc/login/login_bloc.dart';
import 'package:crm_task_manager/bloc/login/login_event.dart';
import 'package:crm_task_manager/bloc/login/login_state.dart';
import 'package:crm_task_manager/utils/global_value.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/widgets/forgot_password.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final TextEditingController loginController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocListener<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LoginLoading) {
              // Здесь можно показать индикатор загрузки, если это необходимо
              // ScaffoldMessenger.of(context).showSnackBar(
              //   SnackBar(content: Text('Загрузка...')),
              // );
            } else if (state is LoginLoaded) {
              // Если логин успешен, переходите на главный экран
              // ScaffoldMessenger.of(context).showSnackBar(
              //   SnackBar(content: Text('Успешный вход')),
              // );
              userID.value = state.user.id.toString();
              Navigator.pushReplacementNamed(context, '/home');
            } else if (state is LoginError) {
              // Если произошла ошибка, покажите сообщение об ошибке
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          child: Column(
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
                  color: Color(0xfff99A4BA),
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
              CustomButton(
                buttonText: 'Войти',
                buttonColor: Color(0xfff4F40EC),
                textColor: Colors.white,
                onPressed: () {
                  final login = loginController.text.trim();
                  final password = passwordController.text.trim();

                  // Проверка на пустые поля
                  if (login.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Пожалуйста, заполните все поля')),
                    );
                    return; // Останавливаем дальнейшее выполнение, если поля пустые
                  }

                  // Отправляем событие CheckLogin в LoginBloc
                  BlocProvider.of<LoginBloc>(context)
                      .add(CheckLogin(login, password));
                },
              ),
              SizedBox(height: 16),
              ForgotPassword(
                onPressed: () {
                  // Здесь вы можете реализовать логику для сброса пароля
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
