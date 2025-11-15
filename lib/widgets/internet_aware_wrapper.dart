import 'package:flutter/material.dart';
import '../api/service/internet_monitor_service.dart';
import 'internet_overlay_widget.dart';

class InternetAwareWrapper extends StatefulWidget {
  final Widget child;

  const InternetAwareWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<InternetAwareWrapper> createState() => _InternetAwareWrapperState();
}

class _InternetAwareWrapperState extends State<InternetAwareWrapper> 
    with WidgetsBindingObserver {
  final _internetMonitor = InternetMonitorService();
  bool _isConnected = true;
  bool _isFirstCheck = true; // ✅ Флаг первой проверки после resume

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeMonitoring();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      debugPrint('🌐 InternetAwareWrapper: Приложение resumed');
      _isFirstCheck = true; // ✅ Устанавливаем флаг
      _checkImmediately(); // ✅ МГНОВЕННАЯ проверка
    }
  }

  // ✅ МГНОВЕННАЯ проверка (синхронная)
  void _checkImmediately() {
    // Запускаем асинхронную проверку БЕЗ ожидания
    _internetMonitor.checkNow().then((_) {
      if (mounted) {
        final newStatus = _internetMonitor.isConnected;
        if (_isConnected != newStatus) {
          setState(() {
            _isConnected = newStatus;
          });
          debugPrint('🌐 InternetAwareWrapper: БЫСТРОЕ обновление -> $_isConnected');
        }
        _isFirstCheck = false;
      }
    });
  }

  Future<void> _initializeMonitoring() async {
    // ✅ Получаем начальный статус
    _isConnected = _internetMonitor.isConnected;

    // ✅ Слушаем изменения
    _internetMonitor.internetStatus.listen((isConnected) {
      // ❌ НЕ обновляем UI сразу после resume (ждем _checkImmediately)
      if (mounted && !_isFirstCheck && _isConnected != isConnected) {
        setState(() {
          _isConnected = isConnected;
        });
        debugPrint('🌐 InternetAwareWrapper: Статус изменился -> $_isConnected');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // ✅ Показываем overlay только если точно нет интернета
        if (!_isConnected && !_isFirstCheck)
          const Positioned.fill(
            child: InternetOverlayWidget(),
          ),
      ],
    );
  }
}