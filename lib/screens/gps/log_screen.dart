import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class MapScreen extends StatefulWidget {
  final LatLng? currentLocation;

  const MapScreen({Key? key, this.currentLocation}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController _mapController;
  LatLng? _currentLocation;
  bool _isLoadingLocation = false;
  bool _isFollowingUser = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentLocation = widget.currentLocation;
    
    // Если нет переданного местоположения, получаем текущее
    if (_currentLocation == null) {
      _getCurrentLocation();
    } else {
      // Загружаем последние сохраненные координаты
      _loadLastKnownLocation();
    }
  }

  Future<void> _loadLastKnownLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastLocation = prefs.getString('last_location');
      if (lastLocation != null) {
        final locationData = jsonDecode(lastLocation);
        final savedLocation = LatLng(locationData['lat'], locationData['lon']);
        
        // Используем более свежее местоположение
        if (_currentLocation == null) {
          setState(() {
            _currentLocation = savedLocation;
          });
        }
        print('MapScreen: Loaded last known location: $savedLocation');
      }
    } catch (e) {
      print('MapScreen: Error loading last known location: $e');
    }
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
          _showLocationError('Разрешение на местоположение отклонено');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError('Разрешение на местоположение отклонено навсегда');
        return;
      }

      // Проверяем, включены ли службы местоположения
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError('Службы местоположения отключены');
        return;
      }

      // Получаем текущую позицию
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      );

      final newLocation = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _currentLocation = newLocation;
        _isLoadingLocation = false;
      });

      // Сохраняем в SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_location', jsonEncode({
        'lat': position.latitude,
        'lon': position.longitude,
      }));

      // Перемещаем карту к новому местоположению
      _mapController.move(newLocation, 16.0);

      print('MapScreen: Got current location: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('MapScreen: Error getting current location: $e');
      _showLocationError('Не удалось получить текущее местоположение: $e');
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _showLocationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _centerOnLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 16.0);
    } else {
      _getCurrentLocation();
    }
  }

  void _toggleFollowUser() {
    setState(() {
      _isFollowingUser = !_isFollowingUser;
    });
    
    if (_isFollowingUser) {
      _centerOnLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('map'),
          style: const TextStyle(
            fontFamily: 'Gilroy', 
            fontSize: 20, 
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xff1E2E52),
        elevation: 0,
        actions: [
          if (_isLoadingLocation)
            Container(
              margin: EdgeInsets.all(16),
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _getCurrentLocation,
              tooltip: 'Обновить местоположение',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Основная карта
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? LatLng(38.5816, 68.7739), // Душанбе по умолчанию
              initialZoom: _currentLocation != null ? 15.0 : 10.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              keepAlive: true,
              interactionOptions: InteractionOptions(
                enableMultiFingerGestureRace: true,
                pinchZoomThreshold: 0.5,
                rotationThreshold: 20.0,
              ),
            ),
            children: [
              // Слой с тайлами карты
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
                maxZoom: 18,
                userAgentPackageName: 'com.example.crm_task_manager',
              ),
              
              // Слой с маркером текущего местоположения
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 60.0,
                      height: 60.0,
                      point: _currentLocation!,
                      alignment: Alignment.center,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          margin: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.person_pin_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Информационная панель вверху
          if (_currentLocation != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Текущие координаты:',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Широта: ${_currentLocation!.latitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        'Долгота: ${_currentLocation!.longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Кнопка центрирования
          Positioned(
            bottom: 90,
            right: 16,
            child: FloatingActionButton(
              heroTag: "center",
              onPressed: _centerOnLocation,
              backgroundColor: Color(0xff1E2E52),
              child: Icon(
                Icons.my_location,
                color: Colors.white,
              ),
            ),
          ),

          // Кнопка следования за пользователем
          Positioned(
            bottom: 150,
            right: 16,
            child: FloatingActionButton(
              heroTag: "follow",
              onPressed: _toggleFollowUser,
              backgroundColor: _isFollowingUser ? Colors.blue : Color(0xff1E2E52),
              child: Icon(
                _isFollowingUser ? Icons.location_searching : Icons.location_disabled,
                color: Colors.white,
              ),
            ),
          ),

          // Сообщение если нет местоположения
          if (_currentLocation == null && !_isLoadingLocation)
            Center(
              child: Card(
                margin: EdgeInsets.all(32),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Местоположение недоступно',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Нажмите кнопку обновления, чтобы получить текущие координаты',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: Icon(Icons.location_searching),
                        label: Text(
                          'Получить местоположение',
                          style: TextStyle(fontFamily: 'Gilroy'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff1E2E52),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}