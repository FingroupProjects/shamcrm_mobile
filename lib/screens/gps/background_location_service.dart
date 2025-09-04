import 'dart:convert';
import 'package:crm_task_manager/screens/gps/log_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:background_location_tracker/background_location_tracker.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

class GpsScreen extends StatefulWidget {
  const GpsScreen({Key? key}) : super(key: key);

  @override
  _GpsScreenState createState() => _GpsScreenState();
}

class _GpsScreenState extends State<GpsScreen> with SingleTickerProviderStateMixin {
  bool isTracking = false;
  String? userId;
  List<Map<String, dynamic>> logs = [];
  LatLng? currentLocation;
  late AnimationController _animationController;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadUserId();
    _getTrackingStatus();
    _loadLogs();
    _initLocationUpdates();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userID');
      print('GpsScreen: Loaded userID: $userId');
    });
  }

  Future<void> _getTrackingStatus() async {
    try {
      isTracking = await BackgroundLocationTrackerManager.isTracking();
      setState(() {});
      print('GpsScreen: Tracking status: $isTracking');
    } catch (e) {
      print('GpsScreen: Error getting tracking status: $e');
    }
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logStrings = prefs.getStringList('gps_logs') ?? [];
    setState(() {
      logs = logStrings.map((str) {
        try {
          return Map<String, dynamic>.from(jsonDecode(str));
        } catch (e) {
          print('GpsScreen: Error decoding log: $e, log: $str');
          return <String, dynamic>{};
        }
      }).where((log) => log.isNotEmpty).toList();
      // Сортируем логи по времени (новые сначала)
      logs.sort((a, b) {
        try {
          return DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp']));
        } catch (e) {
          return 0;
        }
      });
      print('GpsScreen: Loaded ${logs.length} logs');
    });
  }

  Future<void> _clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('gps_logs', []);
    setState(() {
      logs = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Логи очищены'),
        backgroundColor: Colors.green,
      ),
    );
    print('GpsScreen: Logs cleared');
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Проверяем разрешения
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Разрешение на местоположение отклонено');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Разрешение на местоположение отклонено навсегда');
      }

      // Проверяем службы местоположения
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Службы местоположения отключены');
      }

      // Получаем текущую позицию
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
      });

      // Сохраняем в SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_location', jsonEncode({
        'lat': position.latitude,
        'lon': position.longitude,
      }));

      print('GpsScreen: Got current location: ${position.latitude}, ${position.longitude}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Местоположение обновлено'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('GpsScreen: Error getting current location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка получения местоположения: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      // Пытаемся загрузить последнее известное местоположение
      await _loadLastKnownLocation();
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _loadLastKnownLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLocation = prefs.getString('last_location');
    if (lastLocation != null) {
      try {
        final locationData = jsonDecode(lastLocation);
        setState(() {
          currentLocation = LatLng(locationData['lat'], locationData['lon']);
        });
        print('GpsScreen: Loaded last known location: $currentLocation');
      } catch (e) {
        print('GpsScreen: Error loading last known location: $e');
      }
    }
  }

  Future<void> _initLocationUpdates() async {
    // Сначала загружаем последнее известное местоположение
    await _loadLastKnownLocation();

    // Затем пытаемся получить текущее местоположение
    if (currentLocation == null) {
      await _getCurrentLocation();
    }

    // Подписываемся на обновления от background tracker
    try {
      BackgroundLocationTrackerManager.handleBackgroundUpdated(
        (data) async {
          setState(() {
            currentLocation = LatLng(data.lat, data.lon);
          });
          
          // Сохраняем обновленное местоположение
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_location', jsonEncode({
            'lat': data.lat,
            'lon': data.lon,
          }));
          
          print('GpsScreen: Received location update: $currentLocation');
        },
      );
    } catch (e) {
      print('GpsScreen: Error setting up location updates: $e');
    }
  }

  Future<void> _showMapScreen() async {
    // Если нет текущего местоположения, пытаемся его получить
    if (currentLocation == null && !_isLoadingLocation) {
      await _getCurrentLocation();
    }

    // Открываем экран карты с текущим местоположением (может быть null)
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(currentLocation: currentLocation),
      ),
    );
    
    // После возврата обновляем местоположение
    await _loadLastKnownLocation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'no_internet':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('gps_tracking'),
          style: const TextStyle(fontFamily: 'Gilroy', fontSize: 20, color: Colors.white),
        ),
        backgroundColor: const Color(0xff1E2E52),
        actions: [
          IconButton(
            icon: const Icon(Icons.map, color: Colors.white),
            onPressed: _showMapScreen,
            tooltip: 'Открыть карту',
          ),
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white),
            onPressed: _getCurrentLocation,
            tooltip: 'Обновить местоположение',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _clearLogs,
            tooltip: 'Очистить логи',
          ),
        ],
      ),
      body: Column(
        children: [
          // Карточка статуса
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Статус GPS трекинга',
                      style: const TextStyle(fontFamily: 'Gilroy', fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    
                    // Статус трекинга
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isTracking ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Трекинг: ${isTracking ? "Активен" : "Неактивен"}',
                          style: const TextStyle(fontFamily: 'Gilroy', fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // UserID
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'UserID: ${userId ?? "Не найден"}',
                          style: const TextStyle(fontFamily: 'Gilroy', fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Отображение текущего местоположения
                    if (_isLoadingLocation)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Получение местоположения...',
                            style: const TextStyle(fontFamily: 'Gilroy', fontSize: 14, color: Colors.blue),
                          ),
                        ],
                      )
                    else if (currentLocation != null)
                      Column(
                        children: [
                          Text(
                            'Текущее местоположение:',
                            style: const TextStyle(fontFamily: 'Gilroy', fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Широта: ${currentLocation!.latitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontFamily: 'Gilroy', fontSize: 14),
                          ),
                          Text(
                            'Долгота: ${currentLocation!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontFamily: 'Gilroy', fontSize: 14),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Местоположение недоступно',
                        style: const TextStyle(fontFamily: 'Gilroy', fontSize: 14, color: Colors.red),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (isTracking) {
                          await BackgroundLocationTrackerManager.stopTracking();
                        } else {
                          await BackgroundLocationTrackerManager.startTracking();
                        }
                        _getTrackingStatus();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff1E2E52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        isTracking ? AppLocalizations.of(context)!.translate('stop') : AppLocalizations.of(context)!.translate('start'),
                        style: const TextStyle(fontFamily: 'Gilroy', color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: logs.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)!.translate('no_logs'),
                      style: const TextStyle(fontFamily: 'Gilroy', fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _animationController.value * 10),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${AppLocalizations.of(context)!.translate('time')}: ${log['timestamp']}',
                                      style: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.bold),
                                    ),
                                    Text('${AppLocalizations.of(context)!.translate('user_id')}: ${log['user_id']}'),
                                    Text('${AppLocalizations.of(context)!.translate('latitude')}: ${log['latitude']}'),
                                    Text('${AppLocalizations.of(context)!.translate('longitude')}: ${log['longitude']}'),
                                    Text(
                                      '${AppLocalizations.of(context)!.translate('status')}: ${log['status']}',
                                      style: TextStyle(
                                        color: log['status'] == 'success' ? Colors.green : Colors.red,
                                        fontFamily: 'Gilroy',
                                      ),
                                    ),
                                    if (log['response'] != null)
                                      Text('${AppLocalizations.of(context)!.translate('response')}: ${log['response']}'),
                                    if (log['error'] != null)
                                      Text('${AppLocalizations.of(context)!.translate('error')}: ${log['error']}'),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
