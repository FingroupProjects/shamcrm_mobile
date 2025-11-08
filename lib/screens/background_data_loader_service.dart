import 'dart:convert';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_bloc.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_event.dart';
import 'package:crm_task_manager/bloc/permission/permession_bloc.dart';
import 'package:crm_task_manager/bloc/permission/permession_event.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/models/mini_app_settiings.dart';
import 'package:crm_task_manager/models/user_byId_model..dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для фоновой загрузки данных после входа в приложение
/// Все операции выполняются незаметно для пользователя
class BackgroundDataLoaderService {
  final ApiService _apiService;
  final BuildContext context;

  BackgroundDataLoaderService({
    required ApiService apiService,
    required this.context,
  }) : _apiService = apiService;

  /// Запуск полной фоновой загрузки всех данных
  Future<void> loadAllDataInBackground() async {
    try {
      //print('BackgroundLoader: Начало фоновой загрузки данных');

      // Запускаем все загрузки параллельно (неблокирующие)
      await Future.wait([
        _loadPermissions(),
        _loadUserData(),
        _loadFieldConfigurations(),
        _loadMiniAppSettings(),
        _loadSettings(),
        _loadTutorialProgress(),
      ], eagerError: false); // Продолжаем даже если какая-то загрузка упала

      //print('BackgroundLoader: Фоновая загрузка завершена');
    } catch (e) {
      //print('BackgroundLoader: Ошибка фоновой загрузки: $e');
      // Не показываем ошибку пользователю, просто логируем
    }
  }

  // ==========================================================================
  // ЗАГРУЗКА РАЗРЕШЕНИЙ
  // ==========================================================================

  Future<void> _loadPermissions() async {
    try {
      //print('BackgroundLoader: Загрузка разрешений');
      context.read<PermissionsBloc>().add(FetchPermissionsEvent());
    } catch (e) {
      //print('BackgroundLoader: Ошибка загрузки разрешений: $e');
    }
  }

  // ==========================================================================
  // ЗАГРУЗКА ДАННЫХ ПОЛЬЗОВАТЕЛЯ
  // ==========================================================================

  Future<void> _loadUserData() async {
    try {
      //print('BackgroundLoader: Загрузка данных пользователя');

      final prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('userID') ?? '';

      if (userId.isEmpty) {
        //print('BackgroundLoader: UserID не найден');
        return;
      }

      // Удаляем старые роли
      await prefs.remove('userRoles');

      // Загружаем полный профиль пользователя
      UserByIdProfile userProfile = await _apiService.getUserById(int.parse(userId));

      // Сохраняем данные пользователя
      if (userProfile.name != null) {
        await prefs.setString('userName', userProfile.name);
        await prefs.setString('userNameProfile', userProfile.name ?? '');
        await prefs.setString('userImage', userProfile.image ?? '');
      }

      // Загружаем роли и статусы
      if (userProfile.role != null && userProfile.role!.isNotEmpty) {
        context.read<LeadBloc>().add(FetchLeadStatuses());
        context.read<DealBloc>().add(FetchDealStatuses());
        context.read<TaskBloc>().add(FetchTaskStatuses());
        context.read<MyTaskBloc>().add(FetchMyTaskStatuses());
      }

      //print('BackgroundLoader: Данные пользователя загружены');
    } catch (e) {
      //print('BackgroundLoader: Ошибка загрузки данных пользователя: $e');
    }
  }

  // ==========================================================================
  // ЗАГРУЗКА КОНФИГУРАЦИЙ ПОЛЕЙ
  // ==========================================================================

  Future<void> _loadFieldConfigurations() async {
    try {
      //print('BackgroundLoader: Загрузка конфигураций полей');
      await _apiService.loadAndCacheAllFieldConfigurations();
      //print('BackgroundLoader: Конфигурации полей загружены');
    } catch (e) {
      //print('BackgroundLoader: Ошибка загрузки конфигураций полей: $e');
    }
  }

  // ==========================================================================
  // ЗАГРУЗКА MINI APP SETTINGS
  // ==========================================================================

  Future<void> _loadMiniAppSettings() async {
    try {
      //print('BackgroundLoader: Загрузка MiniAppSettings');

      final prefs = await SharedPreferences.getInstance();
      final organizationId = await _apiService.getSelectedOrganization();

      final settingsList = await _apiService.getMiniAppSettings(organizationId);

      if (settingsList.isNotEmpty) {
        final settings = settingsList.first;
        await prefs.setString('mini_app_settings', json.encode(settings.toJson()));
        await prefs.setInt('currency_id', settings.currencyId);
        await prefs.setString('store_name', settings.name);
        await prefs.setString('store_phone', settings.phone);
        await prefs.setString('delivery_sum', settings.deliverySum);
        await prefs.setBool('has_bonus', settings.hasBonus);
        await prefs.setBool('identify_by_phone', settings.identifyByPhone);

        //print('BackgroundLoader: MiniAppSettings сохранены');
      }
    } catch (e) {
      //print('BackgroundLoader: Ошибка загрузки MiniAppSettings: $e');

      // Загружаем из кэша в случае ошибки
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedSettings = prefs.getString('mini_app_settings');
        if (savedSettings != null) {
          final settings = MiniAppSettings.fromJson(json.decode(savedSettings));
          await prefs.setInt('currency_id', settings.currencyId);
          //print('BackgroundLoader: MiniAppSettings загружены из кэша');
        }
      } catch (cacheError) {
        //print('BackgroundLoader: Ошибка загрузки из кэша: $cacheError');
      }
    }
  }

  // ==========================================================================
  // ЗАГРУЗКА SETTINGS
  // ==========================================================================

  bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return false;
  }

  Future<void> _loadSettings() async {
    try {
      //print('BackgroundLoader: Загрузка Settings');

      final prefs = await SharedPreferences.getInstance();
      final organizationId = await _apiService.getSelectedOrganization();

      final response = await _apiService.getSettings(organizationId);

      if (response['result'] != null) {
        await prefs.setBool(
          'department_enabled',
          _toBool(response['result']['department'])
        );

        await prefs.setBool(
          'integration_with_1C',
          _toBool(response['result']['integration_with_1C'])
        );

        await prefs.setBool(
          'good_measurement',
          _toBool(response['result']['good_measurement'])
        );

        await prefs.setBool(
          'managing_deal_status_visibility',
          _toBool(response['result']['managing_deal_status_visibility'])
        );

        //print('BackgroundLoader: Settings сохранены');
      }
    } catch (e) {
      //print('BackgroundLoader: Ошибка загрузки Settings: $e');

      // Устанавливаем значения по умолчанию
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('integration_with_1C', false);
        await prefs.setBool('good_measurement', false);
        await prefs.setBool('managing_deal_status_visibility', false);
      } catch (prefsError) {
        //print('BackgroundLoader: Ошибка установки значений по умолчанию: $prefsError');
      }
    }
  }

  // ==========================================================================
  // ЗАГРУЗКА TUTORIAL PROGRESS
  // ==========================================================================

  Future<void> _loadTutorialProgress() async {
    try {
      //print('BackgroundLoader: Загрузка TutorialProgress');

      final prefs = await SharedPreferences.getInstance();
      final progress = await _apiService.getTutorialProgress();

      await prefs.setString('tutorial_progress', json.encode(progress['result']));
      //print('BackgroundLoader: TutorialProgress обновлён с сервера');
    } catch (e) {
      //print('BackgroundLoader: Ошибка загрузки TutorialProgress: $e');

      // Загружаем из кэша
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedProgress = prefs.getString('tutorial_progress');
        if (savedProgress != null) {
          //print('BackgroundLoader: TutorialProgress загружен из кэша');
        }
      } catch (cacheError) {
        //print('BackgroundLoader: Ошибка загрузки из кэша: $cacheError');
      }
    }
  }

  // ==========================================================================
  // ОЧИСТКА КЭША (опционально, если нужно)
  // ==========================================================================

  Future<void> clearCacheIfNeeded() async {
    try {
      await _apiService.clearCachedSalesFunnels();
    } catch (e) {
      //print('BackgroundLoader: Ошибка очистки кэша: $e');
    }
  }
}