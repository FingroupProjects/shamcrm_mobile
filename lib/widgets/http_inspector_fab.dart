import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/debug/http_inspector_screen.dart';
import '../api/service/http_logger.dart';
import '../main.dart'; // Для доступа к navigatorKey

/// Плавающая кнопка для быстрого доступа к HTTP Inspector
/// Показывается только в DEBUG режиме И если включена в настройках
class HttpInspectorFab extends StatefulWidget {
  const HttpInspectorFab({Key? key}) : super(key: key);

  @override
  State<HttpInspectorFab> createState() => _HttpInspectorFabState();
}

class _HttpInspectorFabState extends State<HttpInspectorFab> {
  final HttpLogger _logger = HttpLogger();
  Offset _position = const Offset(20, 100);
  bool _isDragging = false;
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkIfEnabled();
    // Проверяем состояние каждые 2 секунды
    _startPeriodicCheck();
  }

  void _startPeriodicCheck() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _checkIfEnabled();
        _startPeriodicCheck();
      }
    });
  }

  Future<void> _checkIfEnabled() async {
    if (!kDebugMode) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Перезагружаем для получения свежих данных
    final enabled = prefs.getBool('http_inspector_enabled') ?? false;

    if (mounted && _isEnabled != enabled) {
      setState(() => _isEnabled = enabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Показываем только в DEBUG режиме И если включено в настройках
    if (!kDebugMode || !_isEnabled) return const SizedBox.shrink();

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() => _isDragging = true);
        },
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              (_position.dx + details.delta.dx).clamp(
                0.0,
                MediaQuery.of(context).size.width - 60,
              ),
              (_position.dy + details.delta.dy).clamp(
                0.0,
                MediaQuery.of(context).size.height - 60,
              ),
            );
          });
        },
        onPanEnd: (_) {
          setState(() => _isDragging = false);
        },
        onTap: () {
          if (!_isDragging) {
            // Используем navigatorKey для доступа к Navigator
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => const HttpInspectorScreen(),
              ),
            );
          }
        },
        child: StreamBuilder(
          stream: _logger.logsStream,
          initialData: _logger.logs,
          builder: (context, snapshot) {
            final logCount = _logger.logs.length;

            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Иконка
                  Center(
                    child: Icon(
                      Icons.network_check,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  // Badge с количеством запросов
                  if (logCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            logCount > 99 ? '99+' : '$logCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
