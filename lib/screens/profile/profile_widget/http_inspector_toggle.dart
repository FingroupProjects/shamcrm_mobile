import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/profile_toggle_card.dart';

/// Переключатель HTTP Inspector (только в DEBUG режиме)
class HttpInspectorToggleWidget extends StatefulWidget {
  const HttpInspectorToggleWidget({super.key});

  @override
  State<HttpInspectorToggleWidget> createState() =>
      _HttpInspectorToggleWidgetState();

  /// Получить текущее состояние инспектора
  static Future<bool> isInspectorEnabled() async {
    if (!kDebugMode) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('http_inspector_enabled') ?? false;
  }

  /// Установить состояние инспектора
  static Future<void> setInspectorEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('http_inspector_enabled', enabled);
    // Уведомляем об изменении через SharedPreferences reload
    await prefs.reload();
  }
}

class _HttpInspectorToggleWidgetState extends State<HttpInspectorToggleWidget> {
  bool _isEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInspectorState();
  }

  Future<void> _loadInspectorState() async {
    final enabled = await HttpInspectorToggleWidget.isInspectorEnabled();
    if (mounted) {
      setState(() {
        _isEnabled = enabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleInspector(bool value) async {
    setState(() => _isEnabled = value);
    await HttpInspectorToggleWidget.setInspectorEnabled(value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'HTTP Inspector включен' : 'HTTP Inspector выключен',
            style: context.appTextStyles.bodyMd.copyWith(
              color: context.appColors.textInverse,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor:
              value ? context.appColors.success : context.appColors.textMuted,
          duration: const Duration(seconds: 2),
        ),
      );

      // Перезагружаем приложение для применения изменений
      if (value) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Перезапустите приложение для отображения кнопки',
              style: context.appTextStyles.bodyMd.copyWith(
                color: context.appColors.textInverse,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: context.appColors.info,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Показываем только в DEBUG режиме
    if (!kDebugMode) return const SizedBox.shrink();

    if (_isLoading) {
      return const SizedBox.shrink();
    }

    return ProfileToggleCard(
      icon: Icon(
        Icons.bug_report_outlined,
        color: context.appColors.buttonPrimaryBg,
        size: 22,
      ),
      title: _isEnabled ? 'HTTP Inspector включен' : 'HTTP Inspector выключен',
      value: _isEnabled,
      onChanged: _toggleInspector,
    );
  }
}
