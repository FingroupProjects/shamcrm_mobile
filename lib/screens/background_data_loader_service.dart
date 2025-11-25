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
      //debugPrint('BackgroundLoader: Начало фоновой загрузки данных');

      // Запускаем все загрузки параллельно (неблокирующие)
      await Future.wait([
        _loadPermissions(),
        _loadUserData(),
        _loadFieldConfigurations(),
        _loadMiniAppSettings(),
        _loadSettings(),
        _loadTutorialProgress(),
      ], eagerError: false); // Продолжаем даже если какая-то загрузка упала

      //debugPrint('BackgroundLoader: Фоновая загрузка завершена');
    } catch (e) {
      //debugPrint('BackgroundLoader: Ошибка фоновой загрузки: $e');
      // Не показываем ошибку пользователю, просто логируем
    }
  }

  // ==========================================================================
  // MARK: ЗАГРУЗКА РАЗРЕШЕНИЙ
  // ==========================================================================

  Future<void> _loadPermissions() async {
    try {
      //debugPrint('BackgroundLoader: Загрузка разрешений');
      context.read<PermissionsBloc>().add(FetchPermissionsEvent());
    } catch (e) {
      //debugPrint('BackgroundLoader: Ошибка загрузки разрешений: $e');
    }
  }

  // ==========================================================================
  // ЗАГРУЗКА ДАННЫХ ПОЛЬЗОВАТЕЛЯ
  // ==========================================================================

  Future<void> _loadUserData() async {
    try {
      //debugPrint('BackgroundLoader: Загрузка данных пользователя');

      final prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('userID') ?? '';

      if (userId.isEmpty) {
        //debugPrint('BackgroundLoader: UserID не найден');
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

      //debugPrint('BackgroundLoader: Данные пользователя загружены');
    } catch (e) {
      //debugPrint('BackgroundLoader: Ошибка загрузки данных пользователя: $e');
    }
  }

  // ==========================================================================
  // ЗАГРУЗКА КОНФИГУРАЦИЙ ПОЛЕЙ
  // ==========================================================================

  Future<void> _loadFieldConfigurations() async {
    try {
      //debugPrint('BackgroundLoader: Загрузка конфигураций полей');
      await _apiService.loadAndCacheAllFieldConfigurations();
      //debugPrint('BackgroundLoader: Конфигурации полей загружены');
    } catch (e) {
      //debugPrint('BackgroundLoader: Ошибка загрузки конфигураций полей: $e');
    }
  }

  // ==========================================================================
  // ЗАГРУЗКА MINI APP SETTINGS
  // ==========================================================================

  Future<void> _loadMiniAppSettings() async {
    try {
      //debugPrint('BackgroundLoader: Загрузка MiniAppSettings');

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

        //debugPrint('BackgroundLoader: MiniAppSettings сохранены');
      }
    } catch (e) {
      //debugPrint('BackgroundLoader: Ошибка загрузки MiniAppSettings: $e');

      // Загружаем из кэша в случае ошибки
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedSettings = prefs.getString('mini_app_settings');
        if (savedSettings != null) {
          final settings = MiniAppSettings.fromJson(json.decode(savedSettings));
          await prefs.setInt('currency_id', settings.currencyId);
          //debugPrint('BackgroundLoader: MiniAppSettings загружены из кэша');
        }
      } catch (cacheError) {
        //debugPrint('BackgroundLoader: Ошибка загрузки из кэша: $cacheError');
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
    debugPrint('BackgroundLoader: Загрузка Settings');

    final prefs = await SharedPreferences.getInstance();
    final organizationId = await _apiService.getSelectedOrganization();

    final response = await _apiService.getSettings(organizationId);

    if (response['result'] != null) {
      // Сохраняем localization
      String? localization = response['result']['localization'];
      
      // Логика: если localization == null, используем "+992"
      String defaultDialCode = (localization != null && localization.isNotEmpty) 
          ? localization 
          : '+992';
      
      await prefs.setString('default_dial_code', defaultDialCode);
      
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

      await prefs.setBool(
        'has_deal_users',
        _toBool(response['result']['has_deal_users'])
      );

      // ✅ НОВОЕ: Сохраняем change_deal_to_multiple_statuses
      await prefs.setBool(
        'change_deal_to_multiple_statuses',
        _toBool(response['result']['change_deal_to_multiple_statuses'])
      );

      debugPrint('BackgroundLoader: Settings сохранены');
      debugPrint('  - default_dial_code = $defaultDialCode');
      debugPrint('  - managing_deal_status_visibility = ${_toBool(response['result']['managing_deal_status_visibility'])}');
      debugPrint('  - change_deal_to_multiple_statuses = ${_toBool(response['result']['change_deal_to_multiple_statuses'])}');
      debugPrint('  - has_deal_users = ${_toBool(response['result']['has_deal_users'])}');
    }
  } catch (e) {
    debugPrint('BackgroundLoader: Ошибка загрузки Settings: $e');

    // Устанавливаем значения по умолчанию
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('integration_with_1C', false);
      await prefs.setBool('good_measurement', false);
      await prefs.setBool('managing_deal_status_visibility', false);
      await prefs.setBool('has_deal_users', false);
      await prefs.setBool('change_deal_to_multiple_statuses', false); // ✅ НОВОЕ
      await prefs.setString('default_dial_code', '+992');
    } catch (prefsError) {
      debugPrint('BackgroundLoader: Ошибка установки значений по умолчанию: $prefsError');
    }
  }
}

  // ==========================================================================
  // ЗАГРУЗКА TUTORIAL PROGRESS
  // ==========================================================================

  Future<void> _loadTutorialProgress() async {
    try {
      //debugPrint('BackgroundLoader: Загрузка TutorialProgress');

      final prefs = await SharedPreferences.getInstance();
      final progress = await _apiService.getTutorialProgress();

      await prefs.setString('tutorial_progress', json.encode(progress['result']));
      //debugPrint('BackgroundLoader: TutorialProgress обновлён с сервера');
    } catch (e) {
      //debugPrint('BackgroundLoader: Ошибка загрузки TutorialProgress: $e');

      // Загружаем из кэша
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedProgress = prefs.getString('tutorial_progress');
        if (savedProgress != null) {
          //debugPrint('BackgroundLoader: TutorialProgress загружен из кэша');
        }
      } catch (cacheError) {
        //debugPrint('BackgroundLoader: Ошибка загрузки из кэша: $cacheError');
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
      //debugPrint('BackgroundLoader: Ошибка очистки кэша: $e');
    }
  }
}