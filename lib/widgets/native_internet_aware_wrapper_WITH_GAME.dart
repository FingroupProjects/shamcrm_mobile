import 'package:crm_task_manager/widgets/native_internet_monitor_simple.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'internet_overlay_widget.dart'; // ✅ ВАШ ДИЗАЙН С ИГРОЙ!

/// 🚀 Обертка для НАТИВНОГО мониторинга с ВАШИМ дизайном
class NativeInternetAwareWrapper extends StatefulWidget {
  final Widget child;

  const NativeInternetAwareWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<NativeInternetAwareWrapper> createState() => _NativeInternetAwareWrapperState();
}

class _NativeInternetAwareWrapperState extends State<NativeInternetAwareWrapper> 
    with WidgetsBindingObserver {
  final _internetMonitor = NativeInternetMonitor();
  
  bool _isConnected = true;
  bool _showOverlay = false;
  
  // ✅ Минимальная задержка для защиты от UI "мерцания"
  Timer? _debounceTimer;
  static const Duration _uiDebounce = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeMonitoring();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      debugPrint('🚀 NativeWrapper: Приложение resumed');
    } else if (state == AppLifecycleState.paused) {
      debugPrint('🚀 NativeWrapper: Приложение paused');
      _debounceTimer?.cancel();
    }
  }

  Future<void> _initializeMonitoring() async {
    // ✅ Получаем начальный статус
    _isConnected = _internetMonitor.isConnected;
    debugPrint('🚀 NativeWrapper: Начальный статус -> $_isConnected');

    // ✅ Слушаем НАТИВНЫЕ события
    _internetMonitor.internetStatus.listen((isConnected) {
      if (!mounted) return;
      
      debugPrint('🚀 NativeWrapper: Получен статус -> $isConnected');
      
      if (_isConnected != isConnected) {
        _isConnected = isConnected;
        
        if (!isConnected) {
          // ❌ Интернет пропал - показываем с минимальной задержкой
          _handleDisconnect();
        } else {
          // ✅ Интернет восстановлен - скрываем МГНОВЕННО
          _handleReconnect();
        }
      }
    });
  }

  /// ❌ Обработка отключения
  void _handleDisconnect() {
    _debounceTimer?.cancel();
    
    debugPrint('🚀 NativeWrapper: ⚠️ Отключение - показываем overlay через ${_uiDebounce.inMilliseconds}ms');
    
    // ✅ Минимальная задержка для плавности UI
    _debounceTimer = Timer(_uiDebounce, () {
      if (!mounted || _isConnected) return;
      
      debugPrint('🚀 NativeWrapper: ❌ ПОКАЗЫВАЕМ OVERLAY');
      
      setState(() {
        _showOverlay = true;
      });
    });
  }

  /// ✅ Обработка восстановления
  void _handleReconnect() {
    _debounceTimer?.cancel();
    
    debugPrint('🚀 NativeWrapper: ✅ Подключение восстановлено');
    
    // ✅ МГНОВЕННО скрываем overlay
    if (_showOverlay) {
      setState(() {
        _showOverlay = false;
      });
      debugPrint('🚀 NativeWrapper: Overlay скрыт');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // ✅ ВАШ КРУТОЙ OVERLAY С ИГРОЙ! 🎮
        if (_showOverlay)
          const Positioned.fill(
            child: InternetOverlayWidget(), // ← ВАШ ДИЗАЙН
          ),
      ],
    );
  }
}