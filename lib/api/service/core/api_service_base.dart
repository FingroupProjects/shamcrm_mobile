part of '../api_service.dart';

abstract class ApiServiceBase {
  String? baseUrl;

  String? baseUrlSocket;

  bool _isInitializing = false;

  bool _isInitialized = false;
}
