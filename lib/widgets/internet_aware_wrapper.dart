import 'package:crm_task_manager/api/service/internet_monitor_service.dart';
import 'package:flutter/material.dart';
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

class _InternetAwareWrapperState extends State<InternetAwareWrapper> {
  final _internetMonitor = InternetMonitorService();
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _initializeMonitoring();
  }

  Future<void> _initializeMonitoring() async {
    // Получаем начальный статус
    _isConnected = _internetMonitor.isConnected;

    // Слушаем изменения
    _internetMonitor.internetStatus.listen((isConnected) {
      if (mounted && _isConnected != isConnected) {
        setState(() {
          _isConnected = isConnected;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Основное приложение
        widget.child,
        
        // Overlay при отсутствии интернета
        if (!_isConnected)
          Positioned.fill(
            child: InternetOverlayWidget(),
          ),
      ],
    );
  }
}