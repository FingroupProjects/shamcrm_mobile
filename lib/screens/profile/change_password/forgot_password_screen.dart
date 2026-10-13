import 'dart:async';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/auth/password_reset.dart';
import 'package:crm_task_manager/screens/auth/forgot_pin.dart';
import 'package:crm_task_manager/screens/profile/change_password/password_flow_shell.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/user_friendly_error.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum _ForgotStep { email, code, password }

/// Восстановление пароля: почта → код из письма → новый пароль.
/// Код приходит в ответе `/forgot-password` и проверяется так же, как PIN.
/// С входа почта уже известна: [initialEmail] сразу запрашивает код.
class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  _ForgotStep _step = _ForgotStep.email;
  ForgotPasswordChallenge? _challenge;
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _isTimerActive = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final email = widget.initialEmail?.trim() ?? '';
    if (!_looksLikeEmail(email)) return;

    // Почту только что ввели на входе. Сразу шлём код, без второго поля почты.
    _emailController.text = email;
    _step = _ForgotStep.code;
    _isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _requestCode();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_isLoading) return;
    setState(() {
      if (_step == _ForgotStep.password) {
        _step = _ForgotStep.code;
      } else {
        _step = _ForgotStep.email;
      }
    });
  }

  Future<void> _requestCode() async {
    final localizations = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    if (!_looksLikeEmail(email)) {
      _showError(localizations.translate('invalid_email'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = await _apiReadyForReset();
      final challenge = await api.requestForgotPassword(email);
      if (!mounted) return;
      setState(() {
        _challenge = challenge;
        _step = _ForgotStep.code;
        _codeController.clear();
      });
      _startTimer();
    } catch (error) {
      if (!mounted) return;
      // Кода ещё нет — возвращаем поле почты, чтобы можно было отправить снова.
      if (_challenge == null) {
        setState(() => _step = _ForgotStep.email);
      }
      _showError(friendlyError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmCode() {
    final localizations = AppLocalizations.of(context)!;
    final challenge = _challenge;
    if (challenge == null) {
      _showError(localizations.translate('forgot_password_bad_result'));
      return;
    }
    if (!passwordCodesMatch(_codeController.text, challenge.code)) {
      _showError(localizations.translate('wrong_confirmation_code'));
      return;
    }
    setState(() => _step = _ForgotStep.password);
  }

  Future<void> _saveNewPassword() async {
    final localizations = AppLocalizations.of(context)!;
    final challenge = _challenge;
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (challenge == null) {
      _showError(localizations.translate('forgot_password_bad_result'));
      return;
    }
    if (password.trim().isEmpty || confirm.trim().isEmpty) {
      _showError(localizations.translate('fill_all_fields'));
      return;
    }
    if (password != confirm) {
      _showError(localizations.translate('passwords_do_not_match'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = await _apiReadyForReset();
      await api.setPasswordAfterReset(
        userId: challenge.userId,
        password: password,
        passwordConfirmation: confirm,
      );
      if (!mounted) return;
      showCustomSnackBar(
        context: context,
        message: localizations.translate('password_changed_successfully'),
        isSuccess: true,
      );
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _showError(friendlyError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 60;
      _isTimerActive = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        setState(() => _isTimerActive = false);
      }
    });
  }

  /// Общий ApiService уже знает домен после проверки почты.
  /// Новый экземпляр на входе домен не поднимает: токена ещё нет.
  Future<ApiService> _apiReadyForReset() async {
    final api = context.read<ApiService>();
    if (api.baseUrl == null || api.baseUrl!.isEmpty) {
      await api.initializeWithEmailFlow();
    }
    return api;
  }

  void _showError(String message) {
    showCustomSnackBar(
      context: context,
      message: message,
      isSuccess: false,
    );
  }

  bool _looksLikeEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return PopScope(
      canPop: _step == _ForgotStep.email && !_isLoading,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _goBack();
      },
      child: PasswordFlowShell(
        title: _title(localizations),
        subtitle: _subtitle(localizations),
        child: _buildStep(localizations),
      ),
    );
  }

  String _title(AppLocalizations localizations) {
    switch (_step) {
      case _ForgotStep.email:
        return localizations.translate('forgot_password_title');
      case _ForgotStep.code:
        return localizations.translate('check_email');
      case _ForgotStep.password:
        return localizations.translate('new_password');
    }
  }

  String _subtitle(AppLocalizations localizations) {
    switch (_step) {
      case _ForgotStep.email:
        return localizations.translate('forgot_password_subtitle');
      case _ForgotStep.code:
        return localizations.translate('enter_code_below');
      case _ForgotStep.password:
        return localizations.translate('new_password_subtitle');
    }
  }

  Widget _buildStep(AppLocalizations localizations) {
    switch (_step) {
      case _ForgotStep.email:
        return _emailStep(localizations);
      case _ForgotStep.code:
        return _codeStep(localizations);
      case _ForgotStep.password:
        return _passwordStep(localizations);
    }
  }

  Widget _emailStep(AppLocalizations localizations) {
    final colors = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        passwordFlowField(
          context: context,
          controller: _emailController,
          label: localizations.translate('email'),
          hint: localizations.translate('enter_email'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        CustomButton(
          buttonText: localizations.translate('request_confirmation'),
          buttonColor: colors.buttonPrimaryBg,
          textColor: colors.buttonPrimaryFg,
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _requestCode,
        ),
      ],
    );
  }

  Widget _codeStep(AppLocalizations localizations) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final shownEmail = maskEmail(_challenge?.email ?? _emailController.text);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SentEmailCard(email: shownEmail),
        const SizedBox(height: 20),
        passwordFlowField(
          context: context,
          controller: _codeController,
          label: localizations.translate('confirmation_code_label'),
          hint: localizations.translate('enter_confirmation_code'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        if (_isTimerActive)
          Center(
            child: Text(
              '${localizations.translate('resend_available_in')} $_secondsRemaining ${localizations.translate('seconds')}',
              style: textStyles.bodyMd.copyWith(
                color: colors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        if (!_isTimerActive)
          Center(
            child: TextButton.icon(
              onPressed: _isLoading ? null : _requestCode,
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
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _confirmCode,
        ),
      ],
    );
  }

  Widget _passwordStep(AppLocalizations localizations) {
    final colors = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        passwordFlowField(
          context: context,
          controller: _passwordController,
          label: localizations.translate('new_password'),
          hint: localizations.translate('enter_new_password'),
          isPassword: true,
        ),
        const SizedBox(height: 16),
        passwordFlowField(
          context: context,
          controller: _confirmController,
          label: localizations.translate('repeat_new_password'),
          hint: localizations.translate('enter_repeat_new_password'),
          isPassword: true,
        ),
        const SizedBox(height: 16),
        CustomButton(
          buttonText: localizations.translate('save'),
          buttonColor: colors.buttonPrimaryBg,
          textColor: colors.buttonPrimaryFg,
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _saveNewPassword,
        ),
      ],
    );
  }
}

class _SentEmailCard extends StatelessWidget {
  final String email;

  const _SentEmailCard({required this.email});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final fieldBackground = colors.backgroundPrimary.withValues(alpha: 0.36);
    final fieldBorder = colors.borderSubtle.withValues(alpha: 0.36);
    final localizations = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fieldBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fieldBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.email_outlined, color: colors.buttonPrimaryBg, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.translate('code_sent_to_email'),
                  style: textStyles.bodyMd.copyWith(
                    fontSize: 13,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  style: textStyles.bodyMd.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.buttonPrimaryBg,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
