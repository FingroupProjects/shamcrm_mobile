import 'package:crm_task_manager/app/fcm_debug_send_switch.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Галочка «Тестовый» только для debug.
/// Включена — FCM на сервер не отправляем.
/// Выключена — отправляем, если токен устройства есть.
class DebugTestLoginCheckbox extends StatefulWidget {
  const DebugTestLoginCheckbox({super.key});

  @override
  State<DebugTestLoginCheckbox> createState() => _DebugTestLoginCheckboxState();
}

class _DebugTestLoginCheckboxState extends State<DebugTestLoginCheckbox> {
  bool _testLogin = debugTestLogin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await ensureDebugTestLoginLoaded();
    if (!mounted) {
      return;
    }
    setState(() {
      _testLogin = debugTestLogin;
    });
  }

  Future<void> _onChanged(bool? value) async {
    final next = value ?? true;
    setState(() {
      _testLogin = next;
    });
    await setDebugTestLogin(next);
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final localizations = AppLocalizations.of(context);
    final title = localizations?.translate('debug_test_login') ?? 'Тестовый';
    // final hint = localizations?.translate('debug_test_login_hint') ??
    //     'Включено — FCM-токен на сервер не уходит. Выключите, чтобы отправить.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: colors.backgroundPrimary.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onChanged(!_testLogin),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _testLogin,
                  activeColor: colors.buttonPrimaryBg,
                  onChanged: _onChanged,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textStyles.labelLg.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        // const SizedBox(height: 2),
                        // Text(
                        //   hint,
                        //   style: textStyles.bodyMd.copyWith(
                        //     color: colors.textSecondary,
                        //     fontSize: 12,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
