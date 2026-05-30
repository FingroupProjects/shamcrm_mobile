import 'package:flutter/foundation.dart';

class WorkdayProfileRedirectService {
  static final ValueNotifier<int> requestCounter = ValueNotifier<int>(0);
  static final ValueNotifier<int> closeCounter = ValueNotifier<int>(0);
  static bool _pendingOpenProfile = false;

  static void requestOpenProfile() {
    _pendingOpenProfile = true;
    requestCounter.value++;
  }

  static void closeProfileBlock() {
    _pendingOpenProfile = false;
    closeCounter.value++;
  }

  static bool consumePendingOpenProfile() {
    final shouldOpen = _pendingOpenProfile;
    _pendingOpenProfile = false;
    return shouldOpen;
  }
}
