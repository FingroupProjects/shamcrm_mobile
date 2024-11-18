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
              // Optional loading indicator in the Snackbar if needed
              // ScaffoldMessenger.of(context).showSnackBar(
              //   SnackBar(content: Text('Loading...')),
              // );
            } else if (state is LoginLoaded) {
<<<<<<< HEAD
              // Если логин успешен, переходите на главный экран
              // ScaffoldMessenger.of(context).showSnackBar(
              //   SnackBar(content: Text('Успешный вход')),
              // );
              userID.value = state.user.id.toString();
=======
              // On successful login, navigate to the home screen
>>>>>>> main
              Navigator.pushReplacementNamed(context, '/home');
            } else if (state is LoginError) {
              // Show error message if login fails
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
                  state is LoginLoading
                      ? Center(
                          child: CircularProgressIndicator(
                              color: Color(0xff1E2E52)))
                      : CustomButton(
                          buttonText: 'Войти',
                          buttonColor: Color(0xfff4F40EC),
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
}
