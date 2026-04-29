import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class PickedLocation {
  final double latitude;
  final double longitude;
  final double? accuracy;

  const PickedLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
  });
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  static const LatLng _fallbackCenter = LatLng(40.283, 69.622);
  static const String _streetTiles =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String _satelliteTiles =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  static const String _labelsTiles =
      'https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}{r}.png';

  LatLng _selectedPoint = _fallbackCenter;
  double? _accuracy;
  bool _isLoadingLocation = true;
  bool _isSending = false;
  _LocationMapType _mapType = _LocationMapType.street;
  bool _isSearchOpen = false;
  bool _isSearching = false;
  String? _locationError;
  List<_PlaceResult> _places = [];
  int _searchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Геолокация выключена';
          _isLoadingLocation = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Нет доступа к геолокации';
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final point = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedPoint = point;
        _accuracy = position.accuracy;
        _isLoadingLocation = false;
      });
      _mapController.move(point, 16);
    } catch (e) {
      setState(() {
        _locationError = 'Не удалось получить геопозицию';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _searchPlaces(String query) async {
    final generation = ++_searchGeneration;
    final trimmed = query.trim();
    if (trimmed.length < 3) {
      setState(() => _places = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final data = await _fetchPlaceSearchResults(trimmed);
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _places = data
            .whereType<Map>()
            .map((item) => _PlaceResult.fromJson(item))
            .where((place) => place.point != null)
            .fold<List<_PlaceResult>>(
              [],
              (places, place) {
                final exists = places.any(
                  (item) =>
                      item.point!.latitude.toStringAsFixed(5) ==
                          place.point!.latitude.toStringAsFixed(5) &&
                      item.point!.longitude.toStringAsFixed(5) ==
                          place.point!.longitude.toStringAsFixed(5),
                );
                if (!exists) places.add(place);
                return places;
              },
            )
            .take(6)
            .toList();
      });
    } finally {
      if (mounted && generation == _searchGeneration) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<List<dynamic>> _fetchPlaceSearchResults(String query) async {
    final queries = _buildSearchQueries(query);
    final results = <dynamic>[];

    for (final searchQuery in queries) {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': searchQuery,
        'format': 'json',
        'limit': '8',
        'addressdetails': '1',
        'namedetails': '1',
        'countrycodes': 'tj',
        'accept-language': 'ru,tg,en',
        'viewbox': '67.25,41.15,75.20,36.60',
        'bounded': '0',
      });
      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'shamCRM mobile location picker',
        },
      );
      if (response.statusCode != 200) continue;

      final data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty) {
        results.addAll(data);
      }
      if (results.length >= 6) break;
    }

    return results;
  }

  List<String> _buildSearchQueries(String query) {
    final normalized = query.replaceAll(RegExp(r'\s+'), ' ').trim();
    final transliterated = _transliterateRuToLatin(normalized);
    final withoutCafe = normalized
        .replaceAll(RegExp(r'^(кафе|cafe|kafe)\s+', caseSensitive: false), '')
        .trim();

    return <String>{
      normalized,
      '$normalized Худжанд',
      '$normalized Таджикистан',
      if (withoutCafe.isNotEmpty) withoutCafe,
      if (withoutCafe.isNotEmpty) '$withoutCafe Худжанд',
      if (transliterated != normalized) transliterated,
      if (transliterated != normalized) '$transliterated Khujand',
      if (transliterated != normalized) '$transliterated Tajikistan',
    }.where((item) => item.length >= 3).toList();
  }

  String _transliterateRuToLatin(String value) {
    const letters = <String, String>{
      'а': 'a',
      'б': 'b',
      'в': 'v',
      'г': 'g',
      'д': 'd',
      'е': 'e',
      'ё': 'yo',
      'ж': 'zh',
      'з': 'z',
      'и': 'i',
      'й': 'y',
      'к': 'k',
      'л': 'l',
      'м': 'm',
      'н': 'n',
      'о': 'o',
      'п': 'p',
      'р': 'r',
      'с': 's',
      'т': 't',
      'у': 'u',
      'ф': 'f',
      'х': 'kh',
      'ц': 'ts',
      'ч': 'ch',
      'ш': 'sh',
      'щ': 'shch',
      'ъ': '',
      'ы': 'y',
      'ь': '',
      'э': 'e',
      'ю': 'yu',
      'я': 'ya',
    };

    final buffer = StringBuffer();
    for (final codePoint in value.runes) {
      final char = String.fromCharCode(codePoint);
      final lower = char.toLowerCase();
      final replacement = letters[lower];
      if (replacement == null) {
        buffer.write(char);
      } else if (char == lower) {
        buffer.write(replacement);
      } else {
        buffer.write(
          replacement.isEmpty
              ? replacement
              : replacement[0].toUpperCase() + replacement.substring(1),
        );
      }
    }
    return buffer.toString();
  }

  void _selectPoint(LatLng point, {double? accuracy}) {
    setState(() {
      _selectedPoint = point;
      _accuracy = accuracy;
      _places = [];
      _isSearchOpen = false;
      _searchController.clear();
    });
    _mapController.move(point, 16);
  }

  void _sendSelectedLocation() {
    setState(() => _isSending = true);
    Navigator.pop(
      context,
      PickedLocation(
        latitude: _selectedPoint.latitude,
        longitude: _selectedPoint.longitude,
        accuracy: _accuracy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xff1E2E52),
        foregroundColor: Colors.white,
        title: _isSearchOpen
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Поиск места',
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                onChanged: _searchPlaces,
              )
            : const Text(
                'Геопозиция',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearchOpen ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                _places = [];
                _searchGeneration++;
                _searchController.clear();
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedPoint,
                        initialZoom: 15,
                        onTap: (_, point) => _selectPoint(point),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: _mapType == _LocationMapType.street
                              ? _streetTiles
                              : _satelliteTiles,
                          userAgentPackageName: 'com.softtech.crm_task_manager',
                          maxNativeZoom:
                              _mapType == _LocationMapType.street ? 19 : 18,
                          maxZoom: 20,
                        ),
                        if (_mapType == _LocationMapType.hybrid)
                          TileLayer(
                            urlTemplate: _labelsTiles,
                            subdomains: const ['a', 'b', 'c', 'd'],
                            userAgentPackageName:
                                'com.softtech.crm_task_manager',
                            maxNativeZoom: 20,
                            maxZoom: 20,
                            retinaMode: RetinaMode.isHighDensity(context),
                          ),
                        MarkerLayer(
                          rotate: true,
                          alignment: Alignment.topCenter,
                          markers: [
                            Marker(
                              width: 48,
                              height: 48,
                              point: _selectedPoint,
                              child: const Icon(
                                Icons.location_pin,
                                color: Color(0xffEA4335),
                                size: 46,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      right: 14,
                      top: 14,
                      child: _MapTypeMenuButton(
                        selectedType: _mapType,
                        onSelected: (type) => setState(() => _mapType = type),
                      ),
                    ),
                    Positioned(
                      right: 14,
                      bottom: 14,
                      child: _RoundMapButton(
                        icon: Icons.my_location_rounded,
                        onTap: _loadCurrentLocation,
                      ),
                    ),
                    if (_isLoadingLocation)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
              _BottomLocationPanel(
                accuracy: _accuracy,
                error: _locationError,
                isSending: _isSending,
                onSend: _sendSelectedLocation,
              ),
            ],
          ),
          if (_isSearchOpen && (_places.isNotEmpty || _isSearching))
            Positioned(
              left: 12,
              right: 12,
              top: 8,
              child: Material(
                color: const Color(0xff1E2E52),
                borderRadius: BorderRadius.circular(14),
                elevation: 8,
                child: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          final place = _places[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xff4C9BFF),
                              child: Icon(
                                Icons.place_outlined,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              place.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () => _selectPoint(place.point!),
                          );
                        },
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: Colors.white12,
                        ),
                        itemCount: _places.length,
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomLocationPanel extends StatelessWidget {
  final double? accuracy;
  final String? error;
  final bool isSending;
  final VoidCallback onSend;

  const _BottomLocationPanel({
    required this.accuracy,
    required this.error,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final accuracyText = accuracy == null
        ? 'Выберите точку на карте'
        : 'С точностью до ${accuracy!.round()} метров';

    return Container(
      width: double.infinity,
      color: const Color(0xff0F1B2A),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xff57A8FF),
                child: Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              title: const Text(
                'Отправить выбранную геопозицию',
                style: TextStyle(
                  color: Color(0xff9BC8FF),
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                error ?? accuracyText,
                style: TextStyle(
                  color: error == null ? Colors.white54 : Colors.redAccent,
                  fontFamily: 'Gilroy',
                ),
              ),
              onTap: isSending ? null : onSend,
            ),
          ],
        ),
      ),
    );
  }
}

enum _LocationMapType {
  street,
  satellite,
  hybrid,
}

extension _LocationMapTypeView on _LocationMapType {
  String get label {
    switch (this) {
      case _LocationMapType.street:
        return 'Карта';
      case _LocationMapType.satellite:
        return 'Спутник';
      case _LocationMapType.hybrid:
        return 'Гибрид';
    }
  }

  IconData get icon {
    switch (this) {
      case _LocationMapType.street:
        return Icons.map_outlined;
      case _LocationMapType.satellite:
        return Icons.terrain_outlined;
      case _LocationMapType.hybrid:
        return Icons.layers_outlined;
    }
  }
}

class _MapTypeMenuButton extends StatelessWidget {
  final _LocationMapType selectedType;
  final ValueChanged<_LocationMapType> onSelected;

  const _MapTypeMenuButton({
    required this.selectedType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_LocationMapType>(
      color: const Color(0xff1E2E52),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      initialValue: selectedType,
      onSelected: onSelected,
      itemBuilder: (context) => _LocationMapType.values
          .map(
            (type) => PopupMenuItem<_LocationMapType>(
              value: type,
              child: Row(
                children: [
                  Icon(type.icon, color: Colors.white, size: 24),
                  const SizedBox(width: 16),
                  Text(
                    type.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      child: const Material(
        color: Color(0xff1E2E52),
        shape: CircleBorder(),
        elevation: 5,
        child: _RoundMapButtonBody(icon: Icons.layers_rounded),
      ),
    );
  }
}

class _RoundMapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundMapButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xff1E2E52),
      shape: const CircleBorder(),
      elevation: 5,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: _RoundMapButtonBody(icon: icon),
      ),
    );
  }
}

class _RoundMapButtonBody extends StatelessWidget {
  final IconData icon;

  const _RoundMapButtonBody({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _PlaceResult {
  final String title;
  final LatLng? point;

  const _PlaceResult({
    required this.title,
    required this.point,
  });

  factory _PlaceResult.fromJson(Map json) {
    final lat = double.tryParse(json['lat']?.toString() ?? '');
    final lon = double.tryParse(json['lon']?.toString() ?? '');
    return _PlaceResult(
      title: json['display_name']?.toString() ?? 'Место',
      point: lat == null || lon == null ? null : LatLng(lat, lon),
    );
  }
}
