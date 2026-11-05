import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid/utils/chess_grid_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' hide Path;

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

/// Ultra-Clean, High-Performance Satellite Map Screen
/// Shows real Google Satellite imagery with a soft circular site aura
/// and compact architectural building badges.
class ComplexMapPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final String? initialAddress;
  final String? complexName;
  final int buildingCount;
  final List<Building>? buildings;
  final bool isReadOnly;

  const ComplexMapPickerScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
    this.initialAddress,
    this.complexName,
    this.buildingCount = 3,
    this.buildings,
    this.isReadOnly = false,
  });

  static Future<ComplexLocationResult?> show({
    required BuildContext context,
    double initialLat = 41.311081,
    double initialLng = 69.240562,
    String? initialAddress,
    String? complexName,
    int buildingCount = 3,
    List<Building>? buildings,
    bool isReadOnly = false,
  }) {
    return Navigator.push<ComplexLocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ComplexMapPickerScreen(
          initialLat: initialLat,
          initialLng: initialLng,
          initialAddress: initialAddress,
          complexName: complexName,
          buildingCount: buildingCount,
          buildings: buildings,
          isReadOnly: isReadOnly,
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
  double _currentZoom = 16.5;
  String _detectedAddress = '';
  bool _isGeocoding = false;
  bool _isLocatingUser = false;
  List<_SearchResultItem> _searchResults = [];
  bool _isSearching = false;
  bool _showBuildings = false;

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
        return context.tr('chess_grid_hybrid_title', fallback: 'Спутник Google');
      case ComplexMapLayerType.googleSatellite:
        return context.tr('chess_grid_pure_satellite_title', fallback: 'Чистый спутник');
      case ComplexMapLayerType.googleRoadmap:
        return context.tr('chess_grid_roadmap_title', fallback: 'Схема Google');
      case ComplexMapLayerType.osmStreet:
        return context.tr('chess_grid_osm_title', fallback: 'OpenStreetMap');
    }
  }

  Future<void> _locateUser() async {
    HapticFeedback.lightImpact();
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
      _currentZoom = 17.0;
      setState(() {
        _currentCenter = newPoint;
      });
      _mapController.move(newPoint, _currentZoom);
      _reverseGeocode(newPoint);
    } catch (e) {
      debugPrint('Error locating user: $e');
    } finally {
      if (mounted) setState(() => _isLocatingUser = false);
    }
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    _currentZoom = camera.zoom;
    if (hasGesture && !widget.isReadOnly) {
      _currentCenter = camera.center;
      _reverseGeocodeDebounce?.cancel();
      _reverseGeocodeDebounce = Timer(const Duration(milliseconds: 500), () {
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
      // ignore network errors
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
    HapticFeedback.selectionClick();
    final point = LatLng(item.lat, item.lng);
    _currentZoom = 17.0;
    setState(() {
      _currentCenter = point;
      _detectedAddress = item.name;
      _searchResults = [];
      _searchController.clear();
      FocusScope.of(context).unfocus();
    });
    _mapController.move(point, _currentZoom);
  }

  void _confirmSelection() {
    HapticFeedback.mediumImpact();
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
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                context.tr('chess_grid_map_layer_title', fallback: 'Слой спутниковой карты'),
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              _buildLayerOption(
                type: ComplexMapLayerType.googleHybrid,
                title: context.tr('chess_grid_hybrid_title', fallback: 'Google Спутник (Гибрид)'),
                subtitle: context.tr('chess_grid_hybrid_sub', fallback: 'Высокодетализированный снимок с дорогами и домами'),
                icon: Icons.satellite_alt_rounded,
              ),
              _buildLayerOption(
                type: ComplexMapLayerType.googleSatellite,
                title: context.tr('chess_grid_pure_satellite_title', fallback: 'Чистый спутник Google'),
                subtitle: context.tr('chess_grid_pure_satellite_sub', fallback: 'Реальные снимки из космоса без разметки'),
                icon: Icons.public_rounded,
              ),
              _buildLayerOption(
                type: ComplexMapLayerType.googleRoadmap,
                title: context.tr('chess_grid_roadmap_title', fallback: 'Google Схема дорог'),
                subtitle: context.tr('chess_grid_roadmap_sub', fallback: 'Классическая карта Google улиц и строений'),
                icon: Icons.map_rounded,
              ),
              _buildLayerOption(
                type: ComplexMapLayerType.osmStreet,
                title: context.tr('chess_grid_osm_title', fallback: 'OpenStreetMap'),
                subtitle: context.tr('chess_grid_osm_sub', fallback: 'Открытая топографическая карта'),
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
          color: isSelected ? const Color(0xFF2979FF) : Colors.white10,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 22,
          color: Colors.white,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          fontSize: 14,
          color: isSelected ? const Color(0xFF64B5F6) : Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontFamily: 'Golos', fontSize: 11, color: Colors.white60),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2979FF), size: 20)
          : null,
    );
  }

  List<LatLng> _createCirclePoints(LatLng center, double radiusMeters, [int pointsCount = 48]) {
    const earthRadius = 6378137.0;
    final lat = center.latitudeInRad;
    final lng = center.longitudeInRad;
    final dR = radiusMeters / earthRadius;

    final points = <LatLng>[];
    for (int i = 0; i < pointsCount; i++) {
      final bearing = (i * 2 * math.pi) / pointsCount;
      final pLat = math.asin(
        math.sin(lat) * math.cos(dR) + math.cos(lat) * math.sin(dR) * math.cos(bearing),
      );
      final pLng = lng + math.atan2(
        math.sin(bearing) * math.sin(dR) * math.cos(lat),
        math.cos(dR) - math.sin(lat) * math.sin(pLat),
      );
      points.add(LatLng(pLat * 180 / math.pi, pLng * 180 / math.pi));
    }
    return points;
  }

  /// Elegant circular site aura
  List<Polygon> _buildComplexPolygons() {
    final center = _currentCenter;
    final polygons = <Polygon>[];

    // Primary translucent blue radius
    polygons.add(
      Polygon(
        points: _createCirclePoints(center, 65.0),
        color: const Color(0xFF2979FF).withValues(alpha: 0.22),
        borderColor: const Color(0xFF2979FF).withValues(alpha: 0.75),
        borderStrokeWidth: 2.0,
      ),
    );

    // Subtle soft outer boundary
    polygons.add(
      Polygon(
        points: _createCirclePoints(center, 88.0),
        color: const Color(0xFF00E5FF).withValues(alpha: 0.05),
        borderColor: const Color(0xFF38BDF8).withValues(alpha: 0.35),
        borderStrokeWidth: 1.0,
      ),
    );

    return polygons;
  }

  /// Clean, compact markers with zero overflow
  List<Marker> _buildComplexMarkers() {
    final center = _currentCenter;
    final markers = <Marker>[];

    // 1. Center glowing pinpoint (always visible)
    markers.add(
      Marker(
        point: center,
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2979FF),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x662979FF),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.location_on_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );

    // If buildings overlay is turned off, only show the center point
    if (!_showBuildings) {
      return markers;
    }

    final buildings = widget.buildings;
    final count = buildings?.isNotEmpty == true
        ? buildings!.length
        : widget.buildingCount.clamp(1, 6);

    // 2. Compact building badges (A, B, C)
    for (int i = 0; i < count; i++) {
      final b = (buildings != null && i < buildings.length) ? buildings[i] : null;
      final label = b != null && b.name.isNotEmpty
          ? (b.name.length > 10 ? b.name.substring(0, 10) : b.name)
          : '${context.tr('chess_grid_building', fallback: 'Корп.')} ${String.fromCharCode(65 + i)}';

      final double progress = count > 1 ? i / (count - 1) : 0.5;
      final double offsetLat = (progress * 0.00040) - 0.00020;
      final double offsetLng = 0.00030 - (progress * 0.00060);

      final bCenter = LatLng(
        center.latitude + offsetLat,
        center.longitude + offsetLng,
      );

      markers.add(
        Marker(
          point: bCenter,
          width: 96,
          height: 28,
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF38BDF8),
                width: 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.apartment_rounded, size: 11, color: Color(0xFF38BDF8)),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. Floating Complex Title Capsule
    final complexTitle = widget.complexName?.isNotEmpty == true
        ? widget.complexName!
        : context.tr('chess_grid_new_complex', fallback: 'Жилой комплекс');

    markers.add(
      Marker(
        point: LatLng(center.latitude - 0.00045, center.longitude),
        width: 196,
        height: 34,
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2979FF).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x662979FF),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_rounded, size: 13, color: Colors.white),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$complexTitle • $count ${ChessGridL10n.buildingPlural(context, count)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // ── Flutter Map (Native crisp satellite layer) ─────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: _currentZoom,
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
              if (_showBuildings)
                PolygonLayer(
                  polygons: _buildComplexPolygons(),
                ),
              MarkerLayer(
                markers: _buildComplexMarkers(),
              ),
            ],
          ),

          // ── Top Bar: Back, Search & Layer ─────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Back Button
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.90),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, size: 20),
                          color: Colors.white,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Search input
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.90),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _searchAddress,
                            style: const TextStyle(
                              fontFamily: 'Golos',
                              fontSize: 13,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: context.tr('chess_grid_search_address_hint', fallback: 'Поиск улицы, города, объекта...'),
                              hintStyle: const TextStyle(
                                fontFamily: 'Golos',
                                fontSize: 13,
                                color: Colors.white60,
                              ),
                              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF38BDF8)),
                              suffixIcon: _isSearching
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: Center(
                                        child: SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        ),
                                      ),
                                    )
                                  : (_searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded, size: 16, color: Colors.white70),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchResults = []);
                                          },
                                        )
                                      : null),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Layer toggle
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.90),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.layers_rounded, size: 20),
                          color: const Color(0xFF38BDF8),
                          tooltip: 'Слои карты',
                          onPressed: _showLayerSelector,
                        ),
                      ),
                    ],
                  ),

                  // Search Dropdown List
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
                        itemBuilder: (ctx, idx) {
                          final item = _searchResults[idx];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF38BDF8)),
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontFamily: 'Golos',
                                fontSize: 12.5,
                                color: Colors.white,
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

          // ── Right Side Clean Controls (Buildings, Layer, Zoom, GPS) ────────
          Positioned(
            right: 14,
            bottom: 165,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 1. Toggle Buildings Overlay Button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _showBuildings = !_showBuildings);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: _showBuildings
                          ? const Color(0xFF2979FF)
                          : const Color(0xFF0F172A).withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _showBuildings
                            ? const Color(0xFF60A5FA)
                            : Colors.white12,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _showBuildings
                              ? const Color(0x662979FF)
                              : Colors.black26,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.apartment_rounded,
                          size: 14,
                          color: _showBuildings ? Colors.white : const Color(0xFF38BDF8),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _showBuildings ? 'Скрыть корпуса' : 'Показать корпуса',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: _showBuildings ? Colors.white : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // 2. Layer pill
                GestureDetector(
                  onTap: _showLayerSelector,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.satellite_alt_rounded, size: 13, color: Colors.amber),
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
                const SizedBox(height: 8),

                // 3. Zoom controls (+ / -)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 38),
                        onPressed: () {
                          _currentZoom = (_currentZoom + 1).clamp(3.0, 20.0);
                          _mapController.move(_currentCenter, _currentZoom);
                        },
                      ),
                      Container(height: 1, width: 24, color: Colors.white12),
                      IconButton(
                        icon: const Icon(Icons.remove_rounded, size: 20, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 38),
                        onPressed: () {
                          _currentZoom = (_currentZoom - 1).clamp(3.0, 20.0);
                          _mapController.move(_currentCenter, _currentZoom);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 4. GPS button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: IconButton(
                    icon: _isLocatingUser
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.my_location_rounded, size: 18, color: Color(0xFF38BDF8)),
                    tooltip: 'Мое местоположение',
                    onPressed: _isLocatingUser ? null : _locateUser,
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Floating Card: Selected Point & Action ──────────────────
          Positioned(
            left: 14,
            right: 14,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2979FF).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF38BDF8)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isGeocoding
                                  ? context.tr('chess_grid_determining_address', fallback: 'Определение адреса точки...')
                                  : (_detectedAddress.isNotEmpty
                                      ? _detectedAddress
                                      : (widget.complexName ?? context.tr('chess_grid_point_chosen', fallback: 'Координаты выбраны'))),
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_currentCenter.latitude.toStringAsFixed(6)}, ${_currentCenter.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(
                                fontFamily: 'Golos',
                                fontSize: 11,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: widget.isReadOnly ? () => Navigator.pop(context) : _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2979FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.isReadOnly ? Icons.arrow_back_rounded : Icons.check_circle_outline_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.isReadOnly
                                ? context.tr('chess_grid_return_to_3d', fallback: 'Вернуться к 3D модели ЖК')
                                : context.tr('chess_grid_select_this_point', fallback: 'Выбрать эту точку на карте'),
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
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
