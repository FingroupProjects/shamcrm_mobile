import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:background_location_tracker/background_location_tracker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
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
  static const int _minUpdateIntervalSeconds = 60; // Каждую минуту

  GpsRepo._();

  factory GpsRepo() => _instance ??= GpsRepo._();

Future<void> update(BackgroundLocationUpdateData data) async {
  final now = DateTime.now();
  if (_lastUpdateTime != null && now.difference(_lastUpdateTime!).inSeconds < _minUpdateIntervalSeconds) {
    print('GPS: Skipping update, interval too short');
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userID');
  print('GPS: Loaded userID from SharedPreferences: $userId');
  
  // Исправленная проверка: userId должен быть валидной строкой с числовым значением
  if (userId == null || userId.isEmpty) {
    print('GPS: UserID is null or empty, aborting update');
    return;
  }
  
  // Проверяем, что userId содержит только цифры
  if (!RegExp(r'^\d+$').hasMatch(userId)) {
    print('GPS: Invalid userID format ($userId), aborting update');
    return;
  }
  
  // Дополнительная проверка: если это тестовый или системный пользователь, можно добавить логику
  // Но userID = '1' может быть валидным в некоторых системах
  
  // Получаем UUID
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

  // Проверки (gps enabled, time window)
  final gpsEnabled = prefs.getBool('gps_enabled') ?? true;
  print('GPS: GPS enabled: $gpsEnabled');
  if (!gpsEnabled) {
    print('GPS: GPS is disabled by user settings');
    return;
  }

  // Отправка
  await _gpsService.sendLocationToServer(data.lat, data.lon, userId, uuid);
  _lastUpdateTime = now;
  print('GPS: Location update sent at $now');
}
}

class GpsService {
  final ApiService _apiService = ApiService(); // Используем существующий API
  bool _isSendingPendingData = false;
  DateTime? _lastSentTime;
  static const int _minSendIntervalSeconds = 10;

Future<void> sendLocationToServer(double latitude, double longitude, String userId, String uuid) async {
  final now = DateTime.now();
  final formattedDate = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
      '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  print('GPS: Preparing to send location: lat=$latitude, lon=$longitude, userId=$userId, uuid=$uuid, date=$formattedDate');

  final data = {
    'user_id': userId,
    'latitude': latitude.toString(),
    'longitude': longitude.toString(),
    'date': formattedDate,
    'uuid': uuid,
  };

  // Сохраняем лог попытки
  await _saveLog({
    'timestamp': now.toIso8601String(),
    'user_id': userId,
    'latitude': latitude,
    'longitude': longitude,
    'status': 'pending',
  });

  // Убираем проверку на userId == '1', так как это может быть валидным ID
  // Проверяем только базовую валидность
  if (userId.isEmpty || !RegExp(r'^\d+$').hasMatch(userId)) {
    print('GPS: Invalid userID format ($userId), saving to pending');
    await _savePendingData(data);
    await _saveLog({
      'timestamp': now.toIso8601String(),
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'status': 'invalid_user_id',
      'error': 'UserID format is invalid',
    });
    return;
  }

  final hasInternet = await _isInternetAvailable();
  if (!hasInternet) {
    print('GPS: No internet, saving to pending: $data');
    await _savePendingData(data);
    await _saveLog({
      'timestamp': now.toIso8601String(),
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'status': 'no_internet',
    });
    return;
  }

  // Проверяем минимальный интервал отправки
  if (_lastSentTime != null && now.difference(_lastSentTime!).inSeconds < _minSendIntervalSeconds) {
    print('GPS: Rate limiting - saving to pending: $data');
    await _savePendingData(data);
    await _saveLog({
      'timestamp': now.toIso8601String(),
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'status': 'rate_limited',
    });
    return;
  }

  try {
    final response = await _apiService.sendGpsData(data);
    print('GPS: Successfully sent GPS data at $now: $response');
    await _saveLog({
      'timestamp': now.toIso8601String(),
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'status': 'success',
      'response': response.toString(),
    });
    _lastSentTime = now;
    
    // Пытаемся отправить накопленные данные только после успешной отправки текущих
    await _checkAndSendPendingData();
  } catch (e) {
    print('GPS: Failed to send GPS data: $e');
    await _savePendingData(data);
    await _saveLog({
      'timestamp': now.toIso8601String(),
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'status': 'error',
      'error': e.toString(),
    });
  }
}

Future<void> _saveLog(Map<String, dynamic> log) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> logs = prefs.getStringList('gps_logs') ?? [];
  logs.add(jsonEncode(log));
  if (logs.length > 100) logs = logs.sublist(logs.length - 100); // Ограничим 100 записями
  await prefs.setStringList('gps_logs', logs);
  print('GPS: Saved log: $log');
}
  // Остальные методы: _isInternetAvailable, _savePendingData, _checkAndSendPendingData — аналогично треккеру, но без _baseUrl (используем _apiService._postRequest)
  Future<bool> _isInternetAvailable() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _savePendingData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pending = prefs.getStringList('pending_gps') ?? [];
    pending.add(jsonEncode(data));
    await prefs.setStringList('pending_gps', pending);
  }

Future<void> _checkAndSendPendingData() async {
  if (_isSendingPendingData) {
    print('GPS: Already sending pending data, skipping');
    return;
  }
  _isSendingPendingData = true;

  try {
    final prefs = await SharedPreferences.getInstance();
    List<String> pending = prefs.getStringList('pending_gps') ?? [];
    print('GPS: Pending data count: ${pending.length}');
    
    if (pending.isEmpty) {
      print('GPS: No pending data to send');
      return;
    }

    // Ограничиваем количество записей для отправки за раз (например, 50)
    const batchSize = 50;
    List<String> currentBatch = pending.take(batchSize).toList();
    List<String> remainingPending = pending.skip(batchSize).toList();

    List<Map<String, dynamic>> dataList = currentBatch
        .map((str) {
          try {
            return Map<String, dynamic>.from(jsonDecode(str));
          } catch (e) {
            print('GPS: Error decoding pending data: $e, data: $str');
            return null;
          }
        })
        .where((data) => data != null)
        .cast<Map<String, dynamic>>()
        .toList();

    if (dataList.isEmpty) {
      print('GPS: No valid pending data to send');
      // Очищаем невалидные данные
      await prefs.setStringList('pending_gps', remainingPending);
      return;
    }

    print('GPS: Sending pending data batch: ${dataList.length} items');
    final response = await _apiService.sendGpsDataBatch(dataList);
    print('GPS: Successfully sent pending data batch: $response');
    
    // Обновляем список pending данных, убирая отправленные
    await prefs.setStringList('pending_gps', remainingPending);
    
    // Если остались еще данные, планируем следующую отправку через небольшую задержку
    if (remainingPending.isNotEmpty) {
      print('GPS: ${remainingPending.length} pending items remain, scheduling next batch');
      Future.delayed(Duration(seconds: 5), () {
        _checkAndSendPendingData();
      });
    }
    
  } catch (e) {
    print('GPS: Failed to send pending data batch: $e');
    // В случае ошибки не очищаем pending данные
  } finally {
    _isSendingPendingData = false;
  }
}
}