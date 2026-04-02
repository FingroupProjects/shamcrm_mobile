import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crm_task_manager/offline/core/network_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NetworkProfileService {
  NetworkProfileService._();

  static const _manualLowBandwidthKey = 'offline.manual_low_bandwidth_mode';
  static const _autoLowBandwidthKey = 'offline.auto_low_bandwidth_mode';

  static final NetworkProfileService instance = NetworkProfileService._();

  final _controller = StreamController<NetworkProfile>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  NetworkProfile _currentProfile = NetworkProfile.offline;
  bool _manualLowBandwidthMode = false;

  NetworkProfile get currentProfile => _currentProfile;
  Stream<NetworkProfile> get profileStream => _controller.stream;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _manualLowBandwidthMode = prefs.getBool(_manualLowBandwidthKey) ?? false;
    _currentProfile = await _resolveProfile();
    _controller.add(_currentProfile);
    _subscription ??=
        Connectivity().onConnectivityChanged.listen((_) async {
      _currentProfile = await _resolveProfile();
      _controller.add(_currentProfile);
    });
  }

  Future<void> setManualLowBandwidthMode(bool enabled) async {
    _manualLowBandwidthMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_manualLowBandwidthKey, enabled);
    _currentProfile = await _resolveProfile();
    _controller.add(_currentProfile);
  }

  Future<NetworkProfile> _resolveProfile() async {
    final connectivity = await Connectivity().checkConnectivity();
    final primary = connectivity.isEmpty
        ? ConnectivityResult.none
        : connectivity.first;
    final autoLowBandwidth = _isLowBandwidth(primary);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoLowBandwidthKey, autoLowBandwidth);
    final lowBandwidth = _manualLowBandwidthMode || autoLowBandwidth;

    switch (primary) {
      case ConnectivityResult.none:
        return NetworkProfile.offline;
      case ConnectivityResult.wifi:
        return NetworkProfile(
          type: NetworkType.wifi,
          isOnline: true,
          lowBandwidthMode: lowBandwidth,
          allowsHeavyBackgroundWork: !lowBandwidth,
          maxParallelRequests: lowBandwidth ? 2 : 4,
        );
      case ConnectivityResult.ethernet:
        return NetworkProfile(
          type: NetworkType.ethernet,
          isOnline: true,
          lowBandwidthMode: false,
          allowsHeavyBackgroundWork: true,
          maxParallelRequests: 4,
        );
      case ConnectivityResult.mobile:
        return NetworkProfile(
          type: lowBandwidth ? NetworkType.mobile3g : NetworkType.mobile4g,
          isOnline: true,
          lowBandwidthMode: lowBandwidth,
          allowsHeavyBackgroundWork: false,
          maxParallelRequests: lowBandwidth ? 1 : 2,
        );
      case ConnectivityResult.bluetooth:
      case ConnectivityResult.vpn:
      case ConnectivityResult.other:
        return NetworkProfile(
          type: NetworkType.unknown,
          isOnline: true,
          lowBandwidthMode: lowBandwidth,
          allowsHeavyBackgroundWork: !lowBandwidth,
          maxParallelRequests: lowBandwidth ? 1 : 2,
        );
    }
  }

  bool _isLowBandwidth(ConnectivityResult result) {
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.bluetooth;
  }

  Future<bool> isLowBandwidthModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getBool(_manualLowBandwidthKey) ?? false) ||
        (prefs.getBool(_autoLowBandwidthKey) ?? false);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}
