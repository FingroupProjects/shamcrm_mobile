import 'dart:io';
import 'package:crm_task_manager/bloc/login/login_bloc.dart';
import 'package:crm_task_manager/bloc/login/login_event.dart';
import 'package:crm_task_manager/bloc/login/login_state.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/utils/global_value.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController codeController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isCodeChecked = false;
  String? _login;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocListener<LoginBloc, LoginState>(
          listener: (context, state) async {
            if (state is LoginLoaded) {
              userID.value = state.user.user.id.toString();
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('token', state.user.token); // Сохраняем токен
              // await prefs.setString('userName', state.user.user.name);
              await prefs.setString('userID', state.user.user.id.toString());
              // await prefs.setString('userLogin', state.user.user.login);

              if (state.user.user.role != null && state.user.user.role!.isNotEmpty) {
                await prefs.setString('userRoleName', state.user.user.role![0].name);
                String allRoles = state.user.user.role!.map((role) => role.name).join(', ');
                await prefs.setString('userAllRoles', allRoles);
              } else {
                await prefs.setString('userRoleName', 'No role assigned');
                await prefs.setString('userAllRoles', 'No role assigned');
              }

              try {
                String? fcmToken;
                if (Platform.isIOS) {
                  String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
                  if (apnsToken == null) {
                    // print('APNS token is not available yet. Skipping FCM token retrieval.');
                  } else {
                    fcmToken = await FirebaseMessaging.instance.getToken();
                  }
                } else {
                  fcmToken = await FirebaseMessaging.instance.getToken();
                }
                if (fcmToken != null) {
                  await context.read<ApiService>().sendDeviceToken(fcmToken);
                }
              } catch (e) {
                // print('Error getting FCM token: $e');
              }

              final savedOrganization = await context.read<ApiService>().getSelectedOrganization();
              if (savedOrganization == null) {
                final organizations = await context.read<ApiService>().getOrganization();
                if (organizations.isNotEmpty) {
                  final firstOrganization = organizations.first;
                  await context.read<ApiService>().saveSelectedOrganization(firstOrganization.id.toString());
                }
              }

              await Future.delayed(Duration(seconds: 2));
              await _checkPinSetupStatus(context);
            } else if (state is LoginError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
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
            } else if (state is CodeChecked) {
              setState(() {
                _isCodeChecked = true;
                _login = state.login;
              });
            }
          },
          child: BlocBuilder<LoginBloc, LoginState>(
            builder: (context, state) {
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
                    controller: codeController,
                    hintText: localizations.translate('login_id_hint'),
                    label: localizations.translate('login_id_label'),
                    enabled: !_isCodeChecked,
                  ),
                  if (_isCodeChecked) ...[
                    SizedBox(height: 16),
                    CustomTextField(
                      controller: passwordController,
                      hintText: localizations.translate('login_password_hint'),
                      label: localizations.translate('login_password_label'),
                      isPassword: true,
                    ),
                  ],
                  SizedBox(height: 16),
                  if (state is LoginLoading || state is CodeChecking)
                    Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff1E2E52),
                      ),
                    )
                  else
                    CustomButton(
                      buttonText: _isCodeChecked
                          ? localizations.translate('login_button')
                          : localizations.translate('check_code_button'),
                      buttonColor: Color(0xff4F40EC),
                      textColor: Colors.white,
                      onPressed: () {
                        if (!_isCodeChecked) {
                          final code = codeController.text.trim();
                          if (code.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(localizations.translate('enter_code_error')),
                              ),
                            );
                            return;
                          }
                          context.read<LoginBloc>().add(CheckCode(code));
                        } else {
                          final password = passwordController.text.trim();
                          if (password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(localizations.translate('enter_password_error')),
                              ),
                            );
                            return;
                          }
                          context.read<LoginBloc>().add(CheckLogin(_login!, password));
                        }
                      },
                    ),
                  SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      localizations.translate('forgot_password'),
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xff4F40EC),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
      await prefs.setBool('isPinSetupComplete', true);
      Navigator.pushReplacementNamed(context, '/pin_setup');
    } else {
      Navigator.pushReplacementNamed(context, '/pin_screen');
    }
  }
}