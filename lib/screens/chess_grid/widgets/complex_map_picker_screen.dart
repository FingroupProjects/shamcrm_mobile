import 'dart:async';
import 'dart:convert';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class ComplexLocationResult {
  final double latitude;
  final double longitude;
  final String? address;

  const ComplexLocationResult({
    required this.latitude,
    required this.longitude,
    this.address,
  });
}

enum ComplexMapLayerType {
  googleHybrid, // Satellite + Roads + Labels
  googleSatellite, // Pure satellite
  googleRoadmap, // Standard Google vector style
  osmStreet, // OpenStreetMap
}

class ComplexMapPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final String? initialAddress;

  const ComplexMapPickerScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
    this.initialAddress,
  });

  static Future<ComplexLocationResult?> show({
    required BuildContext context,
    double initialLat = 41.311081,
    double initialLng = 69.240562,
    String? initialAddress,
  }) {
    return Navigator.push<ComplexLocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ComplexMapPickerScreen(
          initialLat: initialLat,
          initialLng: initialLng,
          initialAddress: initialAddress,
        ),
      ),
    );
  }

  @override
  State<ComplexMapPickerScreen> createState() => _ComplexMapPickerScreenState();
}

class _ComplexMapPickerScreenState extends State<ComplexMapPickerScreen> {
  late final MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _reverseGeocodeDebounce;

  // Google Satellite tile servers:
  // lyrs=y: Hybrid (Satellite + Roads + Places)
  // lyrs=s: Pure Satellite
  // lyrs=m: Standard Google Roadmap
  static const String _googleHybridTiles =
      'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
  static const String _googleSatelliteTiles =
      'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}';
  static const String _googleRoadmapTiles =
      'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
  static const String _osmTiles =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  ComplexMapLayerType _layerType = ComplexMapLayerType.googleHybrid;
  late LatLng _currentCenter;
  String _detectedAddress = '';
  bool _isGeocoding = false;
  bool _isLocatingUser = false;
  List<_SearchResultItem> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentCenter = LatLng(widget.initialLat, widget.initialLng);
    _detectedAddress = widget.initialAddress ?? '';

    if (_detectedAddress.isEmpty) {
      _reverseGeocode(_currentCenter);
    }
  }

  @override
  void dispose() {
    _reverseGeocodeDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String get _currentTileUrl {
    switch (_layerType) {
      case ComplexMapLayerType.googleHybrid:
        return _googleHybridTiles;
      case ComplexMapLayerType.googleSatellite:
        return _googleSatelliteTiles;
      case ComplexMapLayerType.googleRoadmap:
        return _googleRoadmapTiles;
      case ComplexMapLayerType.osmStreet:
        return _osmTiles;
    }
  }

  String get _layerLabel {
    switch (_layerType) {
      case ComplexMapLayerType.googleHybrid:
        return 'Спутник Google (Гибрид)';
      case ComplexMapLayerType.googleSatellite:
        return 'Чистый спутник Google';
      case ComplexMapLayerType.googleRoadmap:
        return 'Схема Google';
      case ComplexMapLayerType.osmStreet:
        return 'OpenStreetMap';
    }
  }

  Future<void> _locateUser() async {
    setState(() => _isLocatingUser = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final newPoint = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentCenter = newPoint;
      });
      _mapController.move(newPoint, 17);
      _reverseGeocode(newPoint);
    } catch (e) {
      debugPrint('Error locating user: $e');
    } finally {
      if (mounted) setState(() => _isLocatingUser = false);
    }
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      _currentCenter = camera.center;
      _reverseGeocodeDebounce?.cancel();
      _reverseGeocodeDebounce = Timer(const Duration(milliseconds: 600), () {
        _reverseGeocode(_currentCenter);
      });
    }
  }

  Future<void> _reverseGeocode(LatLng point) async {
    if (!mounted) return;
    setState(() => _isGeocoding = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${point.latitude}&lon=${point.longitude}&format=json&accept-language=ru',
      );
      final resp = await http.get(url, headers: {
        'User-Agent': 'shamCRM-Mobile-App/1.0',
      }).timeout(const Duration(seconds: 4));

      if (resp.statusCode == 200 && mounted) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final displayName = data['display_name']?.toString() ?? '';
        final addr = data['address'] as Map<String, dynamic>?;

        String compact = '';
        if (addr != null) {
          final road = addr['road'] ?? addr['street'] ?? addr['pedestrian'];
          final house = addr['house_number'];
          final city = addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['state'];
          if (road != null) {
            compact = '$road${house != null ? ', $house' : ''}${city != null ? ', $city' : ''}';
          }
        }

        setState(() {
          _detectedAddress = compact.isNotEmpty ? compact : displayName;
        });
      }
    } catch (_) {
      // ignore network errors for reverse geocode
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  Future<void> _searchAddress(String query) async {
    final q = query.trim();
    if (q.length < 3) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(q)}&format=json&accept-language=ru&limit=5',
      );
      final resp = await http.get(url, headers: {
        'User-Agent': 'shamCRM-Mobile-App/1.0',
      }).timeout(const Duration(seconds: 5));

      if (resp.statusCode == 200 && mounted) {
        final list = jsonDecode(resp.body) as List;
        setState(() {
          _searchResults = list.map((item) {
            return _SearchResultItem(
              name: item['display_name']?.toString() ?? '',
              lat: double.tryParse(item['lat']?.toString() ?? '') ?? 0,
              lng: double.tryParse(item['lon']?.toString() ?? '') ?? 0,
            );
          }).where((i) => i.lat != 0 && i.lng != 0).toList();
        });
      }
    } catch (_) {
      // ignore search errors
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(_SearchResultItem item) {
    final point = LatLng(item.lat, item.lng);
    setState(() {
      _currentCenter = point;
      _detectedAddress = item.name;
      _searchResults = [];
      _searchController.clear();
      FocusScope.of(context).unfocus();
    });
    _mapController.move(point, 17);
  }

  void _confirmSelection() {
    Navigator.pop(
      context,
      ComplexLocationResult(
        latitude: _currentCenter.latitude,
        longitude: _currentCenter.longitude,
        address: _detectedAddress.isNotEmpty ? _detectedAddress : null,
      ),
    );
  }

  void _showLayerSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = ctx.appColors;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          decoration: BoxDecoration(
            color: colors.surfacePrimary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Слой карты',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildLayerOption(
                type: ComplexMapLayerType.googleHybrid,
                title: 'Google Спутник (Гибрид)',
                subtitle: 'Высокодетализированный снимок с дорогами и домами',
                icon: Icons.satellite_alt_rounded,
              ),
              _buildLayerOption(
                type: ComplexMapLayerType.googleSatellite,
                title: 'Чистый спутник Google',
                subtitle: 'Реальные снимки из космоса без разметки',
                icon: Icons.public_rounded,
              ),
              _buildLayerOption(
                type: ComplexMapLayerType.googleRoadmap,
                title: 'Google Схема дорог',
                subtitle: 'Классическая карта Google улиц и строений',
                icon: Icons.map_rounded,
              ),
              _buildLayerOption(
                type: ComplexMapLayerType.osmStreet,
                title: 'OpenStreetMap',
                subtitle: 'Открытая топографическая карта',
                icon: Icons.layers_rounded,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLayerOption({
    required ComplexMapLayerType type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final colors = context.appColors;
    final isSelected = _layerType == type;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      onTap: () {
        setState(() => _layerType = type);
        Navigator.pop(context);
      },
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? colors.buttonPrimaryBg : colors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isSelected ? Colors.white : colors.iconSecondary,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          fontSize: 14,
          color: isSelected ? colors.buttonPrimaryBg : colors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontFamily: 'Golos', fontSize: 11, color: colors.textSecondary),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: colors.buttonPrimaryBg, size: 20)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: Stack(
        children: [
          // ── Flutter Map ────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 16,
              maxZoom: 20,
              minZoom: 3,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: _currentTileUrl,
                userAgentPackageName: 'com.softtech.crm_task_manager',
                maxZoom: 20,
                maxNativeZoom: 19,
                subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
              ),
            ],
          ),

          // ── Center Crosshair Pin ───────────────────────────────────────────
          Center(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Text(
                        'Точка ЖК',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.location_on_rounded,
                      size: 44,
                      color: Color(0xFFEF4444),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Top Navigation & Search Bar ────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Back Button
                      Container(
                        decoration: BoxDecoration(
                          color: colors.surfacePrimary.withValues(alpha: 0.94),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: colors.textPrimary,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Search input
                      Expanded(
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: colors.surfacePrimary.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _searchAddress,
                            style: TextStyle(
                              fontFamily: 'Golos',
                              fontSize: 13.5,
                              color: colors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Поиск улицы, города, объекта...',
                              hintStyle: TextStyle(
                                fontFamily: 'Golos',
                                fontSize: 13,
                                color: colors.textSecondary,
                              ),
                              prefixIcon: Icon(Icons.search_rounded, size: 20, color: colors.buttonPrimaryBg),
                              suffixIcon: _isSearching
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: Center(
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                    )
                                  : (_searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded, size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchResults = []);
                                          },
                                        )
                                      : null),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Layer toggle button
                      Container(
                        decoration: BoxDecoration(
                          color: colors.surfacePrimary.withValues(alpha: 0.94),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.layers_rounded),
                          color: colors.buttonPrimaryBg,
                          tooltip: 'Слои карты',
                          onPressed: _showLayerSelector,
                        ),
                      ),
                    ],
                  ),

                  // Search Results Dropdown List
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        color: colors.surfacePrimary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: colors.borderSubtle),
                        itemBuilder: (ctx, idx) {
                          final item = _searchResults[idx];
                          return ListTile(
                            dense: true,
                            leading: Icon(Icons.location_on_outlined, size: 18, color: colors.buttonPrimaryBg),
                            title: Text(
                              item.name,
                              style: TextStyle(
                                fontFamily: 'Golos',
                                fontSize: 12.5,
                                color: colors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectSearchResult(item),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Right Side Floating Actions (Layer pill, GPS, Zoom) ─────────────
          Positioned(
            right: 14,
            bottom: 180,
            child: Column(
              children: [
                // Active layer badge
                GestureDetector(
                  onTap: _showLayerSelector,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.satellite_alt_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          _layerLabel,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // My GPS location button
                FloatingActionButton.small(
                  heroTag: 'map_gps_btn',
                  onPressed: _isLocatingUser ? null : _locateUser,
                  backgroundColor: colors.surfacePrimary,
                  foregroundColor: colors.buttonPrimaryBg,
                  elevation: 3,
                  child: _isLocatingUser
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                ),
                const SizedBox(height: 8),

                // Zoom In
                FloatingActionButton.small(
                  heroTag: 'map_zoom_in',
                  onPressed: () {
                    _mapController.move(_currentCenter, _mapController.camera.zoom + 1);
                  },
                  backgroundColor: colors.surfacePrimary,
                  foregroundColor: colors.textPrimary,
                  elevation: 3,
                  child: const Icon(Icons.add_rounded),
                ),
                const SizedBox(height: 6),

                // Zoom Out
                FloatingActionButton.small(
                  heroTag: 'map_zoom_out',
                  onPressed: () {
                    _mapController.move(_currentCenter, _mapController.camera.zoom - 1);
                  },
                  backgroundColor: colors.surfacePrimary,
                  foregroundColor: colors.textPrimary,
                  elevation: 3,
                  child: const Icon(Icons.remove_rounded),
                ),
              ],
            ),
          ),

          // ── Bottom Floating Card: Selected Point & Confirmation ─────────────
          Positioned(
            left: 14,
            right: 14,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfacePrimary.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.8)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Address line
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colors.buttonPrimaryBg.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.location_on_rounded, size: 20, color: colors.buttonPrimaryBg),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isGeocoding
                                  ? 'Определение адреса точки...'
                                  : (_detectedAddress.isNotEmpty
                                      ? _detectedAddress
                                      : 'Координаты выбраны'),
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: colors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_currentCenter.latitude.toStringAsFixed(6)}, ${_currentCenter.longitude.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontFamily: 'Golos',
                                fontSize: 11.5,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.buttonPrimaryBg,
                        foregroundColor: colors.buttonPrimaryFg,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Выбрать эту точку на карте',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultItem {
  final String name;
  final double lat;
  final double lng;

  const _SearchResultItem({
    required this.name,
    required this.lat,
    required this.lng,
  });
}
