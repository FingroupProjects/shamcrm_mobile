import 'package:crm_task_manager/api/service/firebase_api.dart';
import 'package:crm_task_manager/bloc/login/login_bloc.dart';
import 'package:crm_task_manager/bloc/login/login_event.dart';
import 'package:crm_task_manager/bloc/login/login_state.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_value.dart';
import 'package:crm_task_manager/widgets/forgot_password.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController loginController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppBackgroundOverlay(preset: AppBackgroundPreset.aurora),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                  decoration: BoxDecoration(
                    color: colors.surfacePrimary.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: colors.borderSubtle.withValues(alpha: 0.42),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withValues(alpha: 0.16),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: BlocListener<LoginBloc, LoginState>(
                    listener: (context, state) async {
                      if (state is LoginLoaded) {
                        userID.value = state.user.id.toString();

                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('userName', state.user.name.toString());
                        await prefs.setString('userID', state.user.id.toString());
                        await prefs.setString('userLogin', state.user.login.toString());
                        await prefs.setBool('hasMiniApp', state.hasMiniApp);

                        if (state.user.role != null && state.user.role!.isNotEmpty) {
                          await prefs.setString('userRoleName', state.user.role![0].name);
                          final allRoles =
                              state.user.role!.map((r) => r.name).join(', ');
                          await prefs.setString('userAllRoles', allRoles);
                        }

                        try {
                          await FirebaseApi().syncCurrentTokenWithServer();
                        } catch (e) {
                          debugPrint(
                            'LoginScreen: Ошибка синхронизации push токенов после логина: $e',
                          );
                        }

                        await Future.delayed(const Duration(seconds: 1));
                        await _checkPinSetupStatus(context);
                      } else if (state is LoginError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)!.translate(state.message),
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: BlocBuilder<LoginBloc, LoginState>(
                      builder: (context, state) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Image.asset(
                                'assets/images/new_icon_shamCRM.jpg',
                                height: 72,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              localizations.translate('login_title'),
                              style: textStyles.titleLg.copyWith(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              localizations.translate('login_subtitle'),
                              style: textStyles.bodyMd.copyWith(
                                fontSize: 14,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            CustomTextField(
                              controller: loginController,
                              hintText:
                                  localizations.translate('login_username_hint'),
                              label:
                                  localizations.translate('login_username_label'),
                              backgroundColor:
                                  colors.backgroundPrimary.withValues(alpha: 0.36),
                              labelColor: colors.textPrimary,
                              hintColor: colors.textSecondary,
                              textColor: colors.textPrimary,
                              borderColor:
                                  colors.borderSubtle.withValues(alpha: 0.36),
                              focusedBorderColor: colors.buttonPrimaryBg,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: passwordController,
                              hintText:
                                  localizations.translate('login_password_hint'),
                              label:
                                  localizations.translate('login_password_label'),
                              isPassword: true,
                              backgroundColor:
                                  colors.backgroundPrimary.withValues(alpha: 0.36),
                              labelColor: colors.textPrimary,
                              hintColor: colors.textSecondary,
                              textColor: colors.textPrimary,
                              borderColor:
                                  colors.borderSubtle.withValues(alpha: 0.36),
                              focusedBorderColor: colors.buttonPrimaryBg,
                            ),
                            const SizedBox(height: 16),
                            if (state is LoginLoading)
                              Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colors.buttonPrimaryBg,
                                  ),
                                ),
                              )
                            else
                              CustomButton(
                                buttonText: localizations.translate('login_button'),
                                buttonColor: colors.buttonPrimaryBg,
                                textColor: colors.buttonPrimaryFg,
                                onPressed: () {
                                  final login = loginController.text.trim();
                                  final password = passwordController.text.trim();
                                  if (login.isEmpty || password.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          localizations.translate('fill_all_fields'),
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  context
                                      .read<LoginBloc>()
                                      .add(CheckLogin(login, password));
                                },
                              ),
                            const SizedBox(height: 16),
                            ForgotPassword(onPressed: () {}),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
