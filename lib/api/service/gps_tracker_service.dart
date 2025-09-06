import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:background_location_tracker/background_location_tracker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/gps/cache_gps.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart'; // Для вычисления расстояния
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
void backgroundCallback() {
  BackgroundLocationTrackerManager.handleBackgroundUpdated(
    (data) async => GpsRepo().update(data),
  );
}

class GpsRepo {
  static GpsRepo? _instance;
  final _gpsService = GpsService();
  DateTime? _lastUpdateTime;
  LatLng? _lastLocation; // Последнее сохранённое местоположение

  // Интервал для сохранения геолокации (в секундах)
  static const int _minUpdateIntervalSeconds = 10; // Каждые 10 секунд
  // Минимальное расстояние для сохранения новых данных (в метрах)
  static const double _minDistanceMeters = 5.0;

  GpsRepo._();

  factory GpsRepo() => _instance ??= GpsRepo._();

  Future<void> update(BackgroundLocationUpdateData data) async {
    final now = DateTime.now();
    final newLocation = LatLng(data.lat, data.lon);

    // Проверяем минимальный интервал для сохранения данных
    if (_lastUpdateTime != null &&
        now.difference(_lastUpdateTime!).inSeconds < _minUpdateIntervalSeconds) {
      print('GPS: Skipping update, interval too short ($_minUpdateIntervalSeconds seconds)');
      return;
    }

    // Проверяем расстояние до последнего местоположения
    if (_lastLocation != null) {
      final distance = Geolocator.distanceBetween(
        _lastLocation!.latitude,
        _lastLocation!.longitude,
        newLocation.latitude,
        newLocation.longitude,
      );
      if (distance < _minDistanceMeters) {
        print('GPS: Skipping update, distance too small ($distance meters < $_minDistanceMeters meters)');
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userID');
    print('GPS: Loaded userID from SharedPreferences: $userId');

    // Проверяем валидность userId
    if (userId == null || userId.isEmpty || !RegExp(r'^\d+$').hasMatch(userId)) {
      print('GPS: Invalid userID ($userId), aborting update');
      return;
    }

    // Получаем UUID устройства
    final deviceInfo = DeviceInfoPlugin();
    String uuid = '';
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      uuid = androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      uuid = iosInfo.identifierForVendor ?? '';
    }
    print('GPS: Device UUID: $uuid');

    // Проверяем настройки GPS
    final gpsEnabled = prefs.getBool('gps_enabled') ?? true;
    if (!gpsEnabled) {
      print('GPS: GPS is disabled by user settings');
      return;
    }

    // Формируем данные для отправки
    final formattedDate =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

    final gpsData = {
      'user_id': userId,
      'latitude': data.lat.toString(),
      'longitude': data.lon.toString(),
      'date': formattedDate,
      'uuid': uuid,
    };

    // Сохраняем данные в кэш
    await CacheManager().saveGpsData(gpsData);
    _lastUpdateTime = now;
    _lastLocation = newLocation; // Обновляем последнее местоположение
    print('GPS: Saved location to cache at $now');

    // Отправляем данные на сервер, если прошло достаточно времени
    await _gpsService.sendPendingDataIfNeeded();
  }
}

class GpsService {
  final ApiService _apiService = ApiService();
  final CacheManager _cacheManager = CacheManager();
  bool _isSendingPendingData = false;
  DateTime? _lastSentTime;

  // Интервал для отправки данных на сервер (в секундах)
  static const int _minSendIntervalSeconds = 60; // Каждую минуту
  // Максимальное количество записей в одном батче
  static const int _maxBatchSize = 50;

  Future<void> sendLocationToServer(Map<String, dynamic> data) async {
    final now = DateTime.now();
    print('GPS: Preparing to send location: $data');

    // Сохраняем лог попытки
    await _cacheManager.saveLog({
      'timestamp': now.toIso8601String(),
      'user_id': data['user_id'],
      'latitude': data['latitude'],
      'longitude': data['longitude'],
      'status': 'pending',
    });

    final hasInternet = await _isInternetAvailable();
    if (!hasInternet) {
      print('GPS: No internet, data saved to cache: $data');
      await _cacheManager.saveGpsData(data);
      await _cacheManager.saveLog({
        'timestamp': now.toIso8601String(),
        'user_id': data['user_id'],
        'latitude': data['latitude'],
        'longitude': data['longitude'],
        'status': 'no_internet',
      });
      return;
    }

    try {
      final response = await _apiService.sendGpsData(data);
      print('GPS: Successfully sent GPS data at $now: $response');
      await _cacheManager.saveLog({
        'timestamp': now.toIso8601String(),
        'user_id': data['user_id'],
        'latitude': data['latitude'],
        'longitude': data['longitude'],
        'status': 'success',
        'response': response.toString(),
      });
    } catch (e) {
      print('GPS: Failed to send GPS data: $e');
      await _cacheManager.saveGpsData(data);
      await _cacheManager.saveLog({
        'timestamp': now.toIso8601String(),
        'user_id': data['user_id'],
        'latitude': data['latitude'],
        'longitude': data['longitude'],
        'status': 'error',
        'error': e.toString(),
      });
    }
  }

  Future<void> sendPendingDataIfNeeded() async {
    final now = DateTime.now();
    // Проверяем, прошло ли достаточно времени с последней отправки
    if (_lastSentTime != null &&
        now.difference(_lastSentTime!).inSeconds < _minSendIntervalSeconds) {
      print('GPS: Skipping send, interval too short ($_minSendIntervalSeconds seconds)');
      return;
    }

    if (_isSendingPendingData) {
      print('GPS: Already sending pending data, skipping');
      return;
    }
    _isSendingPendingData = true;

    // Объявляем pendingData вне try-catch
    List<Map<String, dynamic>> pendingData = [];

    try {
      pendingData = await _cacheManager.getPendingGpsData();
      print('GPS: Pending data count: ${pendingData.length}');

      if (pendingData.isEmpty) {
        print('GPS: No pending data to send');
        return;
      }

      // Ограничиваем размер пакета
      List<Map<String, dynamic>> currentBatch = pendingData.take(_maxBatchSize).toList();
      List<Map<String, dynamic>> remainingData = pendingData.skip(_maxBatchSize).toList();

      if (currentBatch.isEmpty) {
        print('GPS: No valid pending data to send');
        return;
      }

      print('GPS: Sending pending data batch: ${currentBatch.length} items');
      final response = await _apiService.sendGpsDataBatch(currentBatch);
      print('GPS: Successfully sent pending data batch: $response');

      // Очищаем отправленные данные
      await _cacheManager.clearPendingGpsData();
      for (var data in currentBatch) {
        await _cacheManager.saveLog({
          'timestamp': DateTime.now().toIso8601String(),
          'user_id': data['user_id'],
          'latitude': data['latitude'],
          'longitude': data['longitude'],
          'status': 'success',
          'response': response.toString(),
        });
      }

      // Сохраняем оставшиеся данные
      for (var data in remainingData) {
        await _cacheManager.saveGpsData(data);
      }

      _lastSentTime = now;
    } catch (e) {
      print('GPS: Failed to send pending data batch: $e');
      // Сохраняем данные в кэш при ошибке
      for (var data in pendingData) {
        await _cacheManager.saveGpsData(data);
      }
    } finally {
      _isSendingPendingData = false;
    }
  }

  Future<bool> _isInternetAvailable() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
}