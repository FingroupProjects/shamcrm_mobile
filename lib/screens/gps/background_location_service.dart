import 'dart:async';
import 'dart:convert';
import 'package:crm_task_manager/screens/gps/cache_gps.dart';
import 'package:crm_task_manager/screens/gps/log_screen.dart';
import 'package:crm_task_manager/screens/gps/map_screen.dart';
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
  bool _isLoadingLogs = true;
  final CacheManager _cacheManager = CacheManager();
  Timer? _timeCheckTimer;
  bool _isWorkingHours = false;
  Map<String, int> _logsStatistics = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadUserId();
    _getTrackingStatus();
    _loadLogsAsync();
    _initLocationUpdates();
    _startTimeCheckTimer();
  }

  void _startTimeCheckTimer() {
    _checkWorkingHours();
    _timeCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkWorkingHours();
    });
  }

  void _checkWorkingHours() async {
    final now = DateTime.now();
    final hour = now.hour;
    final isWorkingHours = hour >= 8 && hour < 17;

    setState(() {
      _isWorkingHours = isWorkingHours;
    });

    if (isWorkingHours && !isTracking) {
      await BackgroundLocationTrackerManager.startTracking();
      await _getTrackingStatus();
      print('GpsScreen: Automatically started tracking at $now (working hours)');
    } else if (!isWorkingHours && isTracking) {
      await BackgroundLocationTrackerManager.stopTracking();
      await _getTrackingStatus();
      print('GpsScreen: Automatically stopped tracking at $now (non-working hours)');
    }
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

  Future<void> _loadLogsAsync() async {
    setState(() {
      _isLoadingLogs = true;
    });
    try {
      final loadedLogs = await _cacheManager.getLogs();
      final stats = await _cacheManager.getLogsStatistics();
      setState(() {
        logs = loadedLogs;
        _logsStatistics = stats;
        print('GpsScreen: Loaded ${logs.length} logs with stats: $stats');
      });
    } catch (e) {
      print('GpsScreen: Error loading logs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('error_loading_logs')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingLogs = false;
      });
    }
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('clear_logs')),
          content: Text('Вы уверены, что хотите очистить все логи?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Очистить'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _cacheManager.clearLogs();
      setState(() {
        logs = [];
        _logsStatistics = {};
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('logs_cleared')),
          backgroundColor: Colors.green,
        ),
      );
      print('GpsScreen: Logs cleared');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(AppLocalizations.of(context)!.translate('location_permission_denied'));
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(AppLocalizations.of(context)!.translate('location_permission_denied_forever'));
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(AppLocalizations.of(context)!.translate('location_services_disabled'));
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_location', jsonEncode({
        'lat': position.latitude,
        'lon': position.longitude,
      }));

      print('GpsScreen: Got current location: ${position.latitude}, ${position.longitude}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('location_updated')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('GpsScreen: Error getting current location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.translate('location_error')}: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
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
    await _loadLastKnownLocation();
    if (currentLocation == null) {
      await _getCurrentLocation();
    }

    try {
      BackgroundLocationTrackerManager.handleBackgroundUpdated(
        (data) async {
          setState(() {
            currentLocation = LatLng(data.lat, data.lon);
          });

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
    if (currentLocation == null && !_isLoadingLocation) {
      await _getCurrentLocation();
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(currentLocation: currentLocation),
      ),
    );

    await _loadLastKnownLocation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timeCheckTimer?.cancel();
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
      case 'cached':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'success':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'error':
        return Icons.error;
      case 'no_internet':
        return Icons.wifi_off;
      case 'cached':
        return Icons.storage;
      default:
        return Icons.help;
    }
  }

  Widget _buildStatisticsCard() {
    if (_logsStatistics.isEmpty) {
      return Container();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статистика логов',
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _logsStatistics.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(entry.key).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(entry.key)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(entry.key),
                        size: 16,
                        color: _getStatusColor(entry.key),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.key}: ${entry.value}',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 12,
                          color: _getStatusColor(entry.key),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
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
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.map, color: Colors.white),
            onPressed: _showMapScreen,
            tooltip: AppLocalizations.of(context)!.translate('open_map'),
          ),
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white),
            onPressed: _getCurrentLocation,
            tooltip: AppLocalizations.of(context)!.translate('update_location'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadLogsAsync,
            tooltip: 'Обновить логи',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _clearLogs,
            tooltip: AppLocalizations.of(context)!.translate('clear_logs'),
          ),
        ],
      ),
      body: _isLoadingLogs
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.translate('loading_logs'),
                    style: const TextStyle(fontFamily: 'Gilroy', fontSize: 16),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadLogsAsync,
              child: Column(
                children: [
                  // Основная информационная карточка
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
                              AppLocalizations.of(context)!.translate('gps_status'),
                              style: const TextStyle(fontFamily: 'Gilroy', fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
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
                                  '${AppLocalizations.of(context)!.translate('tracking')}: ${isTracking ? AppLocalizations.of(context)!.translate('active') : AppLocalizations.of(context)!.translate('inactive')}',
                                  style: const TextStyle(fontFamily: 'Gilroy', fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  '${AppLocalizations.of(context)!.translate('user_id')}: ${userId ?? AppLocalizations.of(context)!.translate('not_found')}',
                                  style: const TextStyle(fontFamily: 'Gilroy', fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isWorkingHours
                                  ? AppLocalizations.of(context)!.translate('working_hours_active')
                                  : AppLocalizations.of(context)!.translate('non_working_hours'),
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 14,
                                color: _isWorkingHours ? Colors.blue : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_isLoadingLocation)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.translate('getting_location'),
                                    style: const TextStyle(fontFamily: 'Gilroy', fontSize: 14, color: Colors.blue),
                                  ),
                                ],
                              )
                            else if (currentLocation != null)
                              Column(
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.translate('current_location'),
                                    style: const TextStyle(fontFamily: 'Gilroy', fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${AppLocalizations.of(context)!.translate('latitude')}: ${currentLocation!.latitude.toStringAsFixed(6)}',
                                    style: const TextStyle(fontFamily: 'Gilroy', fontSize: 14),
                                  ),
                                  Text(
                                    '${AppLocalizations.of(context)!.translate('longitude')}: ${currentLocation!.longitude.toStringAsFixed(6)}',
                                    style: const TextStyle(fontFamily: 'Gilroy', fontSize: 14),
                                  ),
                                ],
                              )
                            else
                              Text(
                                AppLocalizations.of(context)!.translate('location_unavailable'),
                                style: const TextStyle(fontFamily: 'Gilroy', fontSize: 14, color: Colors.red),
                              ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _isWorkingHours
                                  ? null
                                  : () async {
                                      if (isTracking) {
                                        await BackgroundLocationTrackerManager.stopTracking();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(AppLocalizations.of(context)!.translate('tracking_stopped')),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        await BackgroundLocationTrackerManager.startTracking();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(AppLocalizations.of(context)!.translate('tracking_started')),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                      await _getTrackingStatus();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff1E2E52),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: Text(
                                isTracking
                                    ? AppLocalizations.of(context)!.translate('stop')
                                    : AppLocalizations.of(context)!.translate('start'),
                                style: const TextStyle(fontFamily: 'Gilroy', color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Статистика логов
                  _buildStatisticsCard(),

                  // Список логов
                  Expanded(
                    child: logs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.list_alt,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(context)!.translate('no_logs'),
                                  style: const TextStyle(fontFamily: 'Gilroy', fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Логи будут появляться здесь при работе GPS',
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: logs.length,
                            itemBuilder: (context, index) {
                              final log = logs[index];
                              return LogItemWidget(
                                log: log,
                                onTap: () {
                                  // При нажатии на лог можем показать дополнительную информацию
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Новый виджет для отображения отдельного лога
class LogItemWidget extends StatefulWidget {
  final Map<String, dynamic> log;
  final VoidCallback onTap;

  const LogItemWidget({
    Key? key,
    required this.log,
    required this.onTap,
  }) : super(key: key);

  @override
  _LogItemWidgetState createState() => _LogItemWidgetState();
}

class _LogItemWidgetState extends State<LogItemWidget> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
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
      case 'cached':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'success':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'error':
        return Icons.error;
      case 'no_internet':
        return Icons.wifi_off;
      case 'cached':
        return Icons.storage;
      default:
        return Icons.help;
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'success':
        return 'Отправлено';
      case 'pending':
        return 'Ожидание';
      case 'error':
        return 'Ошибка';
      case 'no_internet':
        return 'Без интернета';
      case 'cached':
        return 'Кэш';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.log['status'] ?? 'unknown';
    final timestamp = widget.log['timestamp'] ?? '';
    final latitude = widget.log['latitude'] ?? '0';
    final longitude = widget.log['longitude'] ?? '0';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _toggleExpansion,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Основная информация (всегда видна)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Иконка статуса
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getStatusColor(status).withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      _getStatusIcon(status),
                      color: _getStatusColor(status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Основная информация
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getStatusDisplayName(status),
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(status),
                              ),
                            ),
                            Text(
                              _formatTimestamp(timestamp),
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Координаты: ${double.tryParse(latitude)?.toStringAsFixed(4) ?? latitude}, ${double.tryParse(longitude)?.toStringAsFixed(4) ?? longitude}',
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Стрелка раскрытия
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Раскрывающаяся детальная информация
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    
                    // Детали для разработчика
                    _buildDetailRow('User ID', widget.log['user_id']?.toString() ?? 'N/A'),
                    _buildDetailRow('Действие', widget.log['action']?.toString() ?? 'GPS операция'),
                    
                    if (widget.log['details'] != null && widget.log['details'].toString().isNotEmpty)
                      _buildDetailRow('Детали', widget.log['details'].toString()),
                    
                    if (widget.log['response'] != null && widget.log['response'].toString().isNotEmpty)
                      _buildDetailSection('Ответ сервера', widget.log['response'].toString()),
                    
                    if (widget.log['error'] != null && widget.log['error'].toString().isNotEmpty)
                      _buildDetailSection('Ошибка', widget.log['error'].toString(), isError: true),
                    
                    if (widget.log['server_response'] != null && widget.log['server_response'].toString().isNotEmpty)
                      _buildDetailSection('Полный ответ', widget.log['server_response'].toString()),
                    
                    if (widget.log['http_code'] != null)
                      _buildDetailRow('HTTP код', widget.log['http_code'].toString()),
                    
                    // Точные координаты
                    const SizedBox(height: 8),
                    Text(
                      'Точные координаты:',
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Широта: $latitude',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      'Долгота: $longitude',
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 11,
                        // fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isError ? Colors.red : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isError ? Colors.red[50] : Colors.blue[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isError ? Colors.red[200]! : Colors.blue[200]!,
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: isError ? Colors.red[800] : Colors.blue[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}