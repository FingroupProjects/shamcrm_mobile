import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/change_password/forgot_password_screen.dart';
import 'package:crm_task_manager/screens/profile/change_password/password_flow_shell.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/user_friendly_error.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';

/// Смена пароля, когда текущий пароль известен.
/// Внизу текстовая кнопка «Забыли пароль?» открывает восстановление по почте.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final localizations = AppLocalizations.of(context)!;
    final current = _currentController.text;
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (current.trim().isEmpty ||
        password.trim().isEmpty ||
        confirm.trim().isEmpty) {
      _showError(localizations.translate('fill_all_fields'));
      return;
    }
    if (password != confirm) {
      _showError(localizations.translate('passwords_do_not_match'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.changePassword(
        currentPassword: current,
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
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      _showError(friendlyError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openForgotPassword() async {
    final reset = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const ForgotPasswordScreen(),
      ),
    );
    // Восстановление уже показало успех. Закрываем и эту форму.
    if (reset == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showError(String message) {
    showCustomSnackBar(
      context: context,
      message: message,
      isSuccess: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return PasswordFlowShell(
      title: localizations.translate('change_password'),
      subtitle: localizations.translate('change_password_subtitle'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          passwordFlowField(
            context: context,
            controller: _currentController,
            label: localizations.translate('current_password'),
            hint: localizations.translate('enter_current_password'),
            isPassword: true,
          ),
          const SizedBox(height: 16),
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
            onPressed: _isLoading ? null : _save,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _isLoading ? null : _openForgotPassword,
              child: Text(
                localizations.translate('forgot_password'),
                style: textStyles.labelLg.copyWith(
                  color: colors.buttonPrimaryBg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
