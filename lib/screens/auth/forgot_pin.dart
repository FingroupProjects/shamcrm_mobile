import 'dart:async';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/auth/pin_setup_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/auth_bloc_pin/forgot_auth_bloc.dart';
import 'package:crm_task_manager/bloc/auth_bloc_pin/forgot_auth_event.dart';
import 'package:crm_task_manager/bloc/auth_bloc_pin/forgot_auth_state.dart';

// Утилита для маскировки email
String maskEmail(String email) {
  if (email.isEmpty) return '';
  
  final parts = email.split('@');
  if (parts.length != 2) return email;
  
  final username = parts[0];
  final domain = parts[1];
  
  if (username.length <= 2) {
    return '${username[0]}***@$domain';
  }
  
  final visibleStart = username.substring(0, 1);
  final visibleEnd = username.substring(username.length - 1);
  
  return '$visibleStart${'*' * (username.length - 2)}$visibleEnd@$domain';
}

// Первый экран - запрос логина
class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({Key? key}) : super(key: key);

  @override
  _ForgotPinScreenState createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final TextEditingController _loginController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return _ForgotPinShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('forgot_pin_title'),
            style: textStyles.titleLg.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.translate('forgot_pin_subtitle'),
            style: textStyles.bodyMd.copyWith(
              fontSize: 14,
              height: 1.4,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _loginController,
            hintText: localizations.translate('enter_login'),
            label: localizations.translate('login_label'),
            backgroundColor: colors.backgroundPrimary.withValues(alpha: 0.36),
            labelColor: colors.textPrimary,
            hintColor: colors.textSecondary,
            textColor: colors.textPrimary,
            borderColor: colors.borderSubtle.withValues(alpha: 0.36),
            focusedBorderColor: colors.buttonPrimaryBg,
          ),
          const SizedBox(height: 16),
          CustomButton(
            buttonText: localizations.translate('request_confirmation'),
            buttonColor: colors.buttonPrimaryBg,
            textColor: colors.buttonPrimaryFg,
            isLoading: _isLoading,
            onPressed: _isLoading
                ? null
                : () {
                    if (_loginController.text.isNotEmpty) {
                      setState(() => _isLoading = true);

                      // Небольшая задержка для UX
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) {
                          setState(() => _isLoading = false);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PinVerificationScreen(
                                login: _loginController.text,
                              ),
                            ),
                          );
                        }
                      });
                    } else {
                      showCustomSnackBar(
                        context: context,
                        message: localizations.translate('enter_login_error'),
                        isSuccess: false,
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }
}

// Второй экран - проверка PIN
class PinVerificationScreen extends StatefulWidget {
  final String login;

  const PinVerificationScreen({Key? key, required this.login})
      : super(key: key);

  @override
  _PinVerificationScreenState createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  final TextEditingController _pinController = TextEditingController();
  ForgotPinBloc? _forgotPinBloc;
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _isTimerActive = false;
  String? _receivedPin;
  String? _maskedEmail; // 👈 НОВОЕ ПОЛЕ для хранения замаскированного email

  @override
  void initState() {
    super.initState();
    _forgotPinBloc = BlocProvider.of<ForgotPinBloc>(context);
    _requestPin();
  }

  void _requestPin() {
    _forgotPinBloc!.add(RequestForgotPin(
      login: widget.login,
      password: '',
    ));
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _isTimerActive = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isTimerActive = false;
        });
      }
    });
  }

  void _navigateToPinSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinSetupScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final fieldBackground = colors.backgroundPrimary.withValues(alpha: 0.36);
    final fieldBorder = colors.borderSubtle.withValues(alpha: 0.36);

    return _ForgotPinShell(
      child: BlocListener<ForgotPinBloc, ForgotPinState>(
        listener: (context, state) {
          if (state is ForgotPinSuccess) {
            setState(() {
              _receivedPin = state.pin.toString();
              _maskedEmail = maskEmail(state.email);
            });
          } else if (state is ForgotPinFailure) {
            // 👇 УЛУЧШЕННАЯ ОБРАБОТКА ОШИБОК
            showCustomSnackBar(
              context: context,
              message: state.error.replaceAll('Exception: ', ''),
              isSuccess: false,
            );
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Почта, куда ушёл код. Цвета берём из темы, не из синего макета.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: fieldBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: fieldBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    color: colors.buttonPrimaryBg,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.translate('check_email'),
                          style: textStyles.bodyLg.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localizations.translate('code_sent_to_email'),
                          style: textStyles.bodyMd.copyWith(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // 👇 Показываем замаскированный email
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfacePrimary.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colors.buttonPrimaryBg.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            _maskedEmail ?? widget.login,
                            style: textStyles.bodyMd.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.buttonPrimaryBg,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _pinController,
              hintText: localizations.translate('enter_confirmation_code'),
              label: localizations.translate('confirmation_code_label'),
              keyboardType: TextInputType.number,
              backgroundColor: fieldBackground,
              labelColor: colors.textPrimary,
              hintColor: colors.textSecondary,
              textColor: colors.textPrimary,
              borderColor: fieldBorder,
              focusedBorderColor: colors.buttonPrimaryBg,
            ),
            const SizedBox(height: 16),
            if (_isTimerActive)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: fieldBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: colors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${localizations.translate('resend_available_in')} $_secondsRemaining ${localizations.translate('seconds')}',
                        style: textStyles.bodyMd.copyWith(
                          color: colors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!_isTimerActive)
              Center(
                child: TextButton.icon(
                  onPressed: _requestPin,
                  icon: Icon(Icons.refresh, color: colors.buttonPrimaryBg),
                  label: Text(
                    localizations.translate('did_not_receive_code'),
                    style: textStyles.labelLg.copyWith(
                      color: colors.buttonPrimaryBg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            CustomButton(
              buttonText: localizations.translate('confirm_code'),
              buttonColor: colors.buttonPrimaryBg,
              textColor: colors.buttonPrimaryFg,
              onPressed: () {
                if (_pinController.text == _receivedPin) {
                  _navigateToPinSetup();
                } else {
                  showCustomSnackBar(
                    context: context,
                    message: localizations.translate('wrong_confirmation_code'),
                    isSuccess: false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Общая оболочка экранов восстановления PIN.
/// Тот же фон и карточка, что на входе по почте.
class _ForgotPinShell extends StatelessWidget {
  final Widget child;

  const _ForgotPinShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

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
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: Center(
                      child: Container(
                        width: double.infinity,
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
                        child: child,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}