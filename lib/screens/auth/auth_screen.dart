import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../bloc/auth_domain/domain_bloc.dart';
import '../../bloc/auth_domain/domain_event.dart';
import '../../bloc/auth_domain/domain_state.dart';
import '../../bloc/login/login_bloc.dart';
import '../../bloc/login/login_event.dart';
import '../../bloc/login/login_state.dart';
import 'qr_scanner_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _showManualInput = false;
  bool _showPasswordField = false;
  String _verifiedLogin = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDomainAsync();
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  Future<void> _checkDomainAsync() async {
    try {
      await context.read<ApiService>().isDomainChecked();
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openQrScanner(AppLocalizations localizations) async {
    try {
      final scanResult = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QrScannerScreen()),
      );
      if (scanResult != null && scanResult is String && mounted) {
        if (_isValidEmail(scanResult)) {
          setState(() {
            _showManualInput = true;
            emailController.text = scanResult;
            _showPasswordField = false;
            _verifiedLogin = '';
          });
          context.read<DomainBloc>().add(CheckEmail(scanResult));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('invalid_email_in_qr')),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('qr_scan_error')),
          ),
        );
      }
    }
  }

  void _resetToQrMode() {
    setState(() {
      _showManualInput = false;
      _showPasswordField = false;
      emailController.clear();
      passwordController.clear();
      _verifiedLogin = '';
    });
  }

  Future<void> _checkPinSetupStatus(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isPinSetupComplete = prefs.getBool('isPinSetupComplete') ?? false;

      if (!isPinSetupComplete) {
        await prefs.setBool('isPinSetupComplete', true);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/pin_setup');
        }
      } else {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/pin_screen');
        }
      }
    } catch (_) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/pin_setup');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    if (localizations == null) {
      return const Scaffold(
        body: Center(child: Text('Localization not available')),
      );
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.backgroundPrimary,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const AppBackgroundOverlay(preset: AppBackgroundPreset.aurora),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colors.buttonPrimaryBg),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    localizations.translate('configuration_check'),
                    style: textStyles.bodyLg.copyWith(
                      fontSize: 16,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.iconPrimary),
        forceMaterialTransparency: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppBackgroundOverlay(preset: AppBackgroundPreset.aurora),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  width: screenWidth * 0.92,
                  constraints: const BoxConstraints(maxWidth: 420),
                  margin: EdgeInsets.only(
                    top: screenHeight * 0.05,
                    bottom: 24,
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
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
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/new_icon_shamCRM.jpg',
                        height: 84,
                      ),
                      const SizedBox(height: 24),
                      if (!_showManualInput) ...[
                        Text(
                          localizations.translate('scan_qr_prompt'),
                          textAlign: TextAlign.center,
                          style: textStyles.titleLg.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Icon(
                          Icons.arrow_downward_rounded,
                          size: 42,
                          color: colors.buttonPrimaryBg,
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: () => _openQrScanner(localizations),
                          child: Container(
                            width: 156,
                            height: 156,
                            decoration: BoxDecoration(
                              color: colors.backgroundPrimary
                                  .withValues(alpha: 0.42),
                              border: Border.all(
                                color: colors.buttonPrimaryBg
                                    .withValues(alpha: 0.58),
                                width: 1.4,
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.buttonPrimaryBg
                                      .withValues(alpha: 0.16),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 96,
                              color: colors.buttonPrimaryBg,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSecondaryAction(
                          label: localizations.translate('manual_input'),
                          onPressed: () {
                            setState(() {
                              _showManualInput = true;
                            });
                          },
                        ),
                      ],
                      if (_showManualInput) ...[
                        CustomTextField(
                          controller: emailController,
                          hintText: 'example@company.com',
                          label: localizations.translate('email'),
                          keyboardType: TextInputType.emailAddress,
                          enabled: !_showPasswordField,
                          showEditButton: _showPasswordField,
                          onEditPressed: () {
                            setState(() {
                              _showPasswordField = false;
                              passwordController.clear();
                              _verifiedLogin = '';
                            });
                          },
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
                        if (_showPasswordField) ...[
                          CustomTextField(
                            controller: passwordController,
                            hintText:
                                localizations.translate('login_password_hint'),
                            label:
                                localizations.translate('login_password_label'),
                            isPassword: true,
                            backgroundColor: colors.backgroundPrimary
                                .withValues(alpha: 0.36),
                            labelColor: colors.textPrimary,
                            hintColor: colors.textSecondary,
                            textColor: colors.textPrimary,
                            borderColor:
                                colors.borderSubtle.withValues(alpha: 0.36),
                            focusedBorderColor: colors.buttonPrimaryBg,
                          ),
                          const SizedBox(height: 16),
                        ],
                        BlocConsumer<DomainBloc, DomainState>(
                          listener: (context, state) async {
                            if (state is DomainError) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(context)!
                                        .translate(state.message),
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
                            } else if (state is EmailVerified) {
                              setState(() {
                                _showPasswordField = true;
                                _verifiedLogin = state.login;
                              });
                              await context
                                  .read<ApiService>()
                                  .initializeWithEmailFlow();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          localizations.translate(
                                            'email_verified_success',
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          },
                          builder: (context, domainState) {
                            if (!_showPasswordField) {
                              if (domainState is DomainLoading) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colors.buttonPrimaryBg,
                                    ),
                                  ),
                                );
                              }
                              return CustomButton(
                                buttonText:
                                    localizations.translate('continue_button'),
                                buttonColor: colors.buttonPrimaryBg,
                                textColor: colors.buttonPrimaryFg,
                                onPressed: () {
                                  final email = emailController.text.trim();
                                  if (email.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          localizations
                                              .translate('enter_email'),
                                        ),
                                      ),
                                    );
                                  } else if (!_isValidEmail(email)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          localizations
                                              .translate('invalid_email'),
                                        ),
                                      ),
                                    );
                                  } else {
                                    context
                                        .read<DomainBloc>()
                                        .add(CheckEmail(email));
                                  }
                                },
                              );
                            }
                            return BlocConsumer<LoginBloc, LoginState>(
                              listener: (context, loginState) async {
                                if (loginState is LoginLoaded) {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setString(
                                    'userName',
                                    loginState.user.name.toString(),
                                  );
                                  await prefs.setString(
                                    'userID',
                                    loginState.user.id.toString(),
                                  );
                                  await prefs.setString(
                                    'userLogin',
                                    loginState.user.login.toString(),
                                  );
                                  await prefs.setBool(
                                    'hasMiniApp',
                                    loginState.hasMiniApp,
                                  );
                                  await context
                                      .read<ApiService>()
                                      .getSelectedOrganization();
                                  await Future.delayed(
                                    const Duration(seconds: 2),
                                  );
                                  if (mounted) {
                                    await _checkPinSetupStatus(context);
                                  }
                                } else if (loginState is LoginError) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(context)!
                                            .translate(loginState.message),
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
                              builder: (context, loginState) {
                                if (loginState is LoginLoading ||
                                    loginState is LoginLoaded) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        colors.buttonPrimaryBg,
                                      ),
                                    ),
                                  );
                                }
                                return CustomButton(
                                  buttonText:
                                      localizations.translate('login_button'),
                                  buttonColor: colors.buttonPrimaryBg,
                                  textColor: colors.buttonPrimaryFg,
                                  onPressed: () {
                                    final password =
                                        passwordController.text.trim();
                                    if (password.isNotEmpty) {
                                      context.read<LoginBloc>().add(
                                            CheckLogin(
                                              _verifiedLogin,
                                              password,
                                            ),
                                          );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            localizations.translate(
                                              'login_password_hint',
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildSecondaryAction(
                          label: localizations.translate('qr_code_label'),
                          onPressed: _resetToQrMode,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryAction({
    required String label,
    required VoidCallback onPressed,
  }) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: colors.backgroundPrimary.withValues(alpha: 0.38),
          border: Border.all(
            color: colors.buttonPrimaryBg.withValues(alpha: 0.56),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextButton(
          onPressed: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              label,
              style: textStyles.labelLg.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.buttonPrimaryBg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
