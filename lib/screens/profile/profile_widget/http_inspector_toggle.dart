import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';

/// Переключатель HTTP Inspector (только в DEBUG режиме)
class HttpInspectorToggleWidget extends StatefulWidget {
  const HttpInspectorToggleWidget({Key? key}) : super(key: key);

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
          ),
          backgroundColor: value ? Colors.green : Colors.grey,
          duration: const Duration(seconds: 2),
        ),
      );

      // Перезагружаем приложение для применения изменений
      if (value) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Перезапустите приложение для отображения кнопки'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Switch(
            value: _isEnabled,
            onChanged: _toggleInspector,
            activeColor: const Color.fromARGB(255, 255, 255, 255),
            inactiveTrackColor:
                const Color.fromARGB(255, 179, 179, 179).withOpacity(0.5),
            activeTrackColor: ChatSmsStyles.messageBubbleSenderColor,
            inactiveThumbColor: const Color.fromARGB(255, 255, 255, 255),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isEnabled ? 'HTTP Inspector включен' : 'HTTP Inspector выключен',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xFF1E1E1E),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
