import 'dart:convert';
import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/biometric_service.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
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
import 'package:crm_task_manager/models/user_byId_model..dart';
import 'package:crm_task_manager/screens/home_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/services/workday_profile_redirect_service.dart';
import 'package:crm_task_manager/widgets/biometric_dialogs.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen>
    with SingleTickerProviderStateMixin {
  // ═══════════════════════════════════════════════════════════════════════
  // ПЕРЕМЕННЫЕ СОСТОЯНИЯ
  // ═══════════════════════════════════════════════════════════════════════

  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _pinsDoNotMatch = false;
  static const String _biometricPromptShownKey =
      'biometric_prompt_shown_after_first_login';

  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  final BiometricService _biometricService = BiometricService();

  int? userRoleId;
  bool isPermissionsLoaded = false;
  Map<String, dynamic>? tutorialProgress;

  // ✅ Убрано: final ApiService _apiService = ApiService(); — используем context.read<ApiService>()

  // ✅ НОВОЕ: Флаг для предотвращения повторной отправки FCM токена
  bool _fcmTokenSent = false;

  // ✅ НОВОЕ: Флаг для отслеживания статуса инициализации
  bool _isInitializing = false;

  // ═══════════════════════════════════════════════════════════════════════
  // ИНИЦИАЛИЗАЦИЯ
  // ═══════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();

    // Запускаем permissions
    context.read<PermissionsBloc>().add(FetchPermissionsEvent());

    // Загружаем данные пользователя
    _loadUserRoleId();
    _fetchTutorialProgress();
    _fetchSettings();
    _fetchMiniAppSettings();

    // ✅ КРИТИЧНО: Отправляем FCM токен при открытии экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendFCMTokenOnInit();
    });

    // Инициализируем анимацию
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FCM ТОКЕН - ОТПРАВКА ПРИ ИНИЦИАЛИЗАЦИИ
  // ═══════════════════════════════════════════════════════════════════════

  /// ✅ Отправка FCM токена при открытии экрана
  Future<void> _sendFCMTokenOnInit() async {
    // Защита от повторного вызова
    if (_fcmTokenSent || _isInitializing) {
      debugPrint('PinSetupScreen: FCM токен уже обрабатывается или отправлен');
      return;
    }

    _isInitializing = true;

    final apiService = context.read<ApiService>();

    try {
      debugPrint('════════════════════════════════════════════════════════');
      debugPrint(
          'PinSetupScreen: 📱 СТАРТ: Отправка FCM токена при инициализации');
      debugPrint('════════════════════════════════════════════════════════');

      // ✅ ШАГ 1: Инициализируем ApiService
      debugPrint('PinSetupScreen: 🔧 Шаг 1/3: Инициализация ApiService...');
      await apiService.ensureInitialized();

      // Проверяем что baseUrl инициализирован
      if (apiService.baseUrl == null || apiService.baseUrl!.isEmpty) {
        debugPrint(
            'PinSetupScreen: ⚠️ baseUrl не инициализирован после ensureInitialized');
        debugPrint('PinSetupScreen: 🔄 Пробуем явную инициализацию...');

        await apiService.initialize();

        // Финальная проверка
        if (apiService.baseUrl == null || apiService.baseUrl!.isEmpty) {
          debugPrint(
              'PinSetupScreen: ❌ baseUrl всё ещё null, откладываем отправку');
          debugPrint(
              '════════════════════════════════════════════════════════');
          _isInitializing = false;
          return;
        }
      }

      debugPrint('PinSetupScreen: ✅ ApiService инициализирован');
      debugPrint('PinSetupScreen: 🌐 baseUrl: ${apiService.baseUrl}');

      // ✅ ШАГ 2: Получаем FCM токен (с поддержкой iOS)
      debugPrint('PinSetupScreen: 📡 Шаг 2/3: Получение FCM токена...');
      String? fcmToken = await _getFCMToken();

      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('PinSetupScreen: ⚠️ Не удалось получить FCM токен');
        debugPrint('════════════════════════════════════════════════════════');
        _isInitializing = false;
        return;
      }

      debugPrint('PinSetupScreen: ✅ FCM токен получен');
      debugPrint(
          'PinSetupScreen: 🔑 Token (первые 30 символов): ${fcmToken.substring(0, fcmToken.length > 30 ? 30 : fcmToken.length)}...');

      // ✅ ШАГ 3: Отправляем токен на сервер
      debugPrint(
          'PinSetupScreen: 📤 Шаг 3/3: Отправка FCM токена на сервер...');
      await apiService.sendDeviceToken(fcmToken);

      _fcmTokenSent = true;
      debugPrint('PinSetupScreen: ✅ FCM токен УСПЕШНО отправлен на сервер!');
      debugPrint('════════════════════════════════════════════════════════');
    } catch (e, stackTrace) {
      debugPrint('════════════════════════════════════════════════════════');
      debugPrint('PinSetupScreen: ❌ ОШИБКА отправки FCM токена');
      debugPrint('PinSetupScreen: Exception: $e');
      debugPrint('PinSetupScreen: StackTrace: $stackTrace');
      debugPrint('════════════════════════════════════════════════════════');
      // Не прерываем работу экрана, просто логируем ошибку
    } finally {
      _isInitializing = false;
    }
  }

  /// ✅ Получение FCM токена с поддержкой iOS (APNS)
  Future<String?> _getFCMToken() async {
    try {
      if (Platform.isIOS) {
        debugPrint('PinSetupScreen: 🍎 Платформа: iOS');
        debugPrint('PinSetupScreen: 🔍 Проверка APNS токена...');

        // Для iOS сначала проверяем APNS
        String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();

        if (apnsToken != null) {
          debugPrint('PinSetupScreen: ✅ APNS токен получен');
          // Если APNS токен есть, получаем FCM токен
          String? fcmToken = await FirebaseMessaging.instance.getToken();
          return fcmToken;
        } else {
          debugPrint('PinSetupScreen: ⚠️ APNS токен недоступен, ждём...');

          // Ждём до 5 секунд появления APNS токена
          int attempts = 0;
          const maxAttempts = 10;
          const delayMs = 500;

          while (attempts < maxAttempts) {
            await Future.delayed(Duration(milliseconds: delayMs));
            apnsToken = await FirebaseMessaging.instance.getAPNSToken();

            if (apnsToken != null) {
              debugPrint(
                  'PinSetupScreen: ✅ APNS токен получен после ${(attempts + 1) * delayMs}ms ожидания');
              String? fcmToken = await FirebaseMessaging.instance.getToken();
              return fcmToken;
            }
            attempts++;
            debugPrint('PinSetupScreen: ⏳ Попытка $attempts/$maxAttempts...');
          }

          debugPrint(
              'PinSetupScreen: ⚠️ APNS токен так и не появился после ${maxAttempts * delayMs}ms');
          debugPrint(
              'PinSetupScreen: 🔄 Пробуем получить FCM токен напрямую...');

          // Последняя попытка получить FCM токен напрямую
          return await FirebaseMessaging.instance.getToken();
        }
      } else {
        // Для Android просто получаем FCM токен
        debugPrint('PinSetupScreen: 🤖 Платформа: Android');
        debugPrint('PinSetupScreen: 📡 Получение FCM токена...');

        String? fcmToken = await FirebaseMessaging.instance.getToken();
        return fcmToken;
      }
    } catch (e, stackTrace) {
      debugPrint('PinSetupScreen: ❌ Ошибка получения FCM токена: $e');
      debugPrint('PinSetupScreen: StackTrace: $stackTrace');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // НАСТРОЙКИ И ДАННЫЕ
  // ═══════════════════════════════════════════════════════════════════════

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

  Future<void> _fetchMiniAppSettings() async {
    final apiService = context.read<ApiService>();
    try {
      final prefs = await SharedPreferences.getInstance();
      final organizationId = await apiService.getSelectedOrganization();

      if (organizationId == null) {
        debugPrint(
            'PinSetupScreen: organizationId is null, пропускаем загрузку MiniAppSettings');
        return;
      }

      final settingsList = await apiService.getMiniAppSettings(organizationId);

      if (settingsList.isNotEmpty) {
        final settings = settingsList.first;
        await prefs.setInt('currency_id', settings.currencyId);
        debugPrint(
            'PinSetupScreen: MiniAppSettings загружены, currency_id: ${settings.currencyId}');
      } else {
        debugPrint(
            'PinSetupScreen: MiniAppSettings пусты для organizationId: $organizationId');
      }
    } catch (e) {
      debugPrint('PinSetupScreen: Ошибка загрузки MiniAppSettings: $e');

      // Используем кэшированное значение
      final prefs = await SharedPreferences.getInstance();
      final savedCurrencyId = prefs.getInt('currency_id');
      debugPrint(
          'PinSetupScreen: Используем кэшированный currency_id: $savedCurrencyId');
    }
  }

  Future<void> _fetchTutorialProgress() async {
    final apiService = context.read<ApiService>();
    try {
      final prefs = await SharedPreferences.getInstance();
      bool isNewUser = prefs.getString('user_pin') == null;

      if (isNewUser) {
        final progress = await apiService.getTutorialProgress();
        setState(() {
          tutorialProgress = progress['result'];
        });
        await prefs.setString(
            'tutorial_progress', json.encode(progress['result']));
        debugPrint(
            'PinSetupScreen: Tutorial progress загружен для нового пользователя');
      } else {
        final savedProgress = prefs.getString('tutorial_progress');
        if (savedProgress != null) {
          setState(() {
            tutorialProgress = json.decode(savedProgress);
          });
          debugPrint('PinSetupScreen: Tutorial progress загружен из кэша');
        }
      }
    } catch (e) {
      debugPrint('PinSetupScreen: Ошибка загрузки tutorial progress: $e');
    }
  }

  Future<void> _fetchSettings() async {
    final apiService = context.read<ApiService>();
    try {
      final prefs = await SharedPreferences.getInstance();
      final organizationId = await apiService.getSelectedOrganization();

      if (organizationId == null) {
        debugPrint(
            'PinSetupScreen: organizationId is null, используем настройки по умолчанию');
        await _setDefaultSettings(prefs);
        return;
      }

      final response = await apiService.getSettings(organizationId);

      if (response['result'] != null) {
        // Сохраняем localization
        String? localization = response['result']['localization'];

        // Логика: если localization == null, используем "+992"
        String defaultDialCode =
            (localization != null && localization.isNotEmpty)
                ? localization
                : '+992';

        await prefs.setString('default_dial_code', defaultDialCode);

        // Остальные настройки
        await prefs.setBool(
            'department_enabled', _toBool(response['result']['department']));

        await prefs.setBool('integration_with_1C',
            _toBool(response['result']['integration_with_1C']));

        await prefs.setBool('good_measurement',
            _toBool(response['result']['good_measurement']));

        await prefs.setBool('managing_deal_status_visibility',
            _toBool(response['result']['managing_deal_status_visibility']));

        await prefs.setBool(
            'has_deal_users', _toBool(response['result']['has_deal_users']));

        await prefs.setBool('change_deal_to_multiple_statuses',
            _toBool(response['result']['change_deal_to_multiple_statuses']));

        await prefs.setBool('push_status_change_enabled',
            _toBool(response['result']['push_status_change_enabled']));

        await prefs.setBool('push_to_lead_author',
            _toBool(response['result']['push_to_lead_author']));

        await prefs.setBool('push_to_lead_manager',
            _toBool(response['result']['push_to_lead_manager']));

        await prefs.setBool(
            'notify_user', _toBool(response['result']['notify_user']));
        await prefs.setBool('sms_notice_notification',
            _toBool(response['result']['sms_notice_notification']));

        await prefs.setBool('managing_lead_status_visibility',
            _toBool(response['result']['managing_lead_status_visibility']));

        await prefs.setBool('create_order_from_deal',
            _toBool(response['result']['create_order_from_deal']));

        await prefs.setBool('create_task_in_deal',
            _toBool(response['result']['create_task_in_deal']));

        await prefs.setBool('show_chat_in_deals',
            _toBool(response['result']['show_chat_in_deals']));

        await prefs.setBool('show_accept_button',
            _toBool(response['result']['show_accept_button']));

        await prefs.setBool('show_accept_decline_button',
            _toBool(response['result']['show_accept_decline_button']));

        await prefs.setBool('ask_reason_for_refusal',
            _toBool(response['result']['ask_reason_for_refusal']));

        await prefs.setInt(
            'accept_lead_status_id',
            response['result']['accept_lead_status_id'] is int
                ? response['result']['accept_lead_status_id'] as int
                : int.tryParse(
                        '${response['result']['accept_lead_status_id']}') ??
                    0);

        if (kDebugMode) {
          debugPrint('PinSetupScreen: Настройки сохранены успешно');
          debugPrint(
              'PinSetupScreen: localization = $localization, default_dial_code = $defaultDialCode');
        }
      } else {
        debugPrint(
            'PinSetupScreen: response[result] is null, используем настройки по умолчанию');
        await _setDefaultSettings(prefs);
      }
    } catch (e) {
      debugPrint('PinSetupScreen: Ошибка загрузки settings: $e');

      final prefs = await SharedPreferences.getInstance();
      await _setDefaultSettings(prefs);
    }
  }

  Future<void> _setDefaultSettings(SharedPreferences prefs) async {
    await prefs.setBool('integration_with_1C', false);
    await prefs.setBool('good_measurement', false);
    await prefs.setBool('managing_deal_status_visibility', false);
    await prefs.setBool('department_enabled', false);
    await prefs.setBool('has_deal_users', false);
    await prefs.setBool('change_deal_to_multiple_statuses', false);
    await prefs.setBool('push_status_change_enabled', false);
    await prefs.setBool('push_to_lead_author', false);
    await prefs.setBool('push_to_lead_manager', false);
    await prefs.setBool('notify_user', false);
    await prefs.setBool('sms_notice_notification', false);
    await prefs.setBool('managing_lead_status_visibility', false);
    await prefs.setBool('create_order_from_deal', false);
    await prefs.setBool('create_task_in_deal', false);
    await prefs.setBool('show_chat_in_deals', false);
    await prefs.setBool('show_accept_button', false);
    await prefs.setBool('show_accept_decline_button', false);
    await prefs.setBool('ask_reason_for_refusal', false);
    await prefs.setInt('accept_lead_status_id', 0);
    await prefs.setString('default_dial_code', '+992');
    debugPrint('PinSetupScreen: Установлены настройки по умолчанию');
  }

  Future<void> _loadUserRoleId() async {
    final apiService = context.read<ApiService>();
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('userID') ?? '';

      if (userId.isEmpty) {
        debugPrint('PinSetupScreen: userID пуст');
        setState(() {
          userRoleId = 0;
        });
        return;
      }

      UserByIdProfile userProfile =
          await apiService.getUserById(int.parse(userId));

      setState(() {
        userRoleId = userProfile.role!.first.id;
      });

      await prefs.setInt('userRoleId', userRoleId!);
      await prefs.setString('userRoleName', userProfile.role![0].name);
      final allRoles =
          userProfile.role?.map((role) => role.name).join(', ') ?? '';
      await prefs.setString('userAllRoles', allRoles);

      // Загружаем статусы
      BlocProvider.of<LeadBloc>(context).add(FetchLeadStatuses());
      BlocProvider.of<DealBloc>(context).add(FetchDealStatuses());
      BlocProvider.of<TaskBloc>(context).add(FetchTaskStatuses());
      BlocProvider.of<MyTaskBloc>(context).add(FetchMyTaskStatuses());

      setState(() {
        isPermissionsLoaded = true;
      });

      debugPrint('PinSetupScreen: User role загружена: $userRoleId');
    } catch (e) {
      debugPrint('PinSetupScreen: Ошибка загрузки user role: $e');
      setState(() {
        userRoleId = 0;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ЛОГИКА PIN-КОДА
  // ═══════════════════════════════════════════════════════════════════════

  void _onNumberPressed(String number) {
    setState(() {
      if (_pinsDoNotMatch) {
        _pinsDoNotMatch = false;
        _confirmPin = '';
      }

      if (_isConfirming) {
        if (_confirmPin.length < 4) {
          _confirmPin += number;
        }
        if (_confirmPin.length == 4) {
          _validatePins();
        }
      } else {
        if (_pin.length < 4) {
          _pin += number;
        }
        if (_pin.length == 4 && !_isConfirming) {
          _isConfirming = true;
        }
      }
    });
  }

  void _onClear() {
    setState(() {
      _pin = '';
      _confirmPin = '';
      _pinsDoNotMatch = false;
      _isConfirming = false;
    });
  }

  void _onDelete() {
    setState(() {
      if (_isConfirming && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      } else if (!_isConfirming && _pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  Future<void> _validatePins() async {
    final apiService = context.read<ApiService>();
    if (_pin == _confirmPin) {
      debugPrint('════════════════════════════════════════════════════════');
      debugPrint('PinSetupScreen: ✅ PIN-коды совпадают, сохраняем...');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_pin', _pin);

      debugPrint('PinSetupScreen: ✅ PIN-код сохранён');

      // ✅ Проверка отложенных токенов (на всякий случай)
      try {
        debugPrint('PinSetupScreen: 📤 Проверка отложенных push токенов...');
        await apiService.ensureInitialized();
        await apiService.sendPendingFCMTokenIfNeeded();
        await apiService.sendPendingVoipTokenIfNeeded();
        debugPrint('PinSetupScreen: ✅ Отложенные токены обработаны');
      } catch (e) {
        debugPrint('PinSetupScreen: ❌ Ошибка отправки отложенных токенов: $e');
      }

      if (isPermissionsLoaded) {
        debugPrint('PinSetupScreen: 🏠 Переход на HomeScreen');
        debugPrint('════════════════════════════════════════════════════════');

        await _maybeShowBiometricPrompt();
        final shouldOpenWorkdayProfile =
            await _shouldOpenInitialWorkdayProfile(apiService);
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              initialShowProfileScreen: shouldOpenWorkdayProfile,
            ),
          ),
          (Route<dynamic> route) => false,
        );
      } else {
        debugPrint('PinSetupScreen: ⚠️ Permissions ещё не загружены');
        debugPrint('════════════════════════════════════════════════════════');
      }
    } else {
      debugPrint('PinSetupScreen: ❌ PIN-коды не совпадают');
      _triggerErrorEffect();
    }
  }

  Future<bool> _shouldOpenInitialWorkdayProfile(ApiService apiService) async {
    try {
      final isWorkdayEnabled = await apiService.isWorkdayFeatureEnabled();
      if (!isWorkdayEnabled) {
        WorkdayProfileRedirectService.closeProfileBlock();
        return false;
      }

      final status = await apiService.getWorkdayStatus();
      if (status?.isActive == true) {
        WorkdayProfileRedirectService.closeProfileBlock();
        return false;
      }

      WorkdayProfileRedirectService.requestOpenProfile();
      return true;
    } catch (e) {
      debugPrint(
        'PinSetupScreen: Ошибка подготовки workday-редиректа после PIN: $e',
      );
      WorkdayProfileRedirectService.requestOpenProfile();
      return true;
    }
  }

  Future<void> _maybeShowBiometricPrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasShown = prefs.getBool(_biometricPromptShownKey) ?? false;
      final isEnabled = await _biometricService.isBiometricEnabled();

      if (wasShown || isEnabled) {
        return;
      }

      final availability = await _biometricService.getAvailability();
      if (!mounted) {
        return;
      }

      final shouldEnable = await _showBiometricPromptDialog(availability);
      await prefs.setBool(_biometricPromptShownKey, true);

      if (shouldEnable != true || !mounted) {
        return;
      }

      if (!availability.hasAnyBiometric) {
        final localizations = AppLocalizations.of(context);
        if (localizations == null) return;

        final shouldOpenSettings = await showBiometricSetupRequiredDialog(
          context: context,
          localizations: localizations,
          availability: availability,
        );
        if (shouldOpenSettings == true) {
          await _biometricService.openBiometricSettings();
        }
        await _biometricService.setBiometricEnabled(false);
        return;
      }

      final didAuthenticate = await _biometricService.authenticate(
        reason: 'Подтвердите личность, чтобы включить быстрый вход в shamCRM',
      );

      await _biometricService.setBiometricEnabled(didAuthenticate);

      if (!didAuthenticate || !mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Биометрический вход включен'),
          backgroundColor: Color(0xFF1E9E63),
        ),
      );
    } catch (e) {
      debugPrint('PinSetupScreen: Ошибка предложения биометрии: $e');
    }
  }

  Future<bool?> _showBiometricPromptDialog(BiometricAvailability availability) {
    final localizations = AppLocalizations.of(context);
    final title = localizations == null
        ? 'Enable biometric sign-in?'
        : biometricEnableTitle(localizations, availability);
    final description = localizations == null
        ? 'Sign in faster and more securely with biometrics. PIN will remain a backup sign-in method.'
        : biometricEnableDescription(localizations, availability);

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E9E63).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: biometricIconWidget(
                      availability: availability,
                      size: 38,
                      color: const Color(0xFF1E9E63),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Gilroy',
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Gilroy',
                    color: Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475467),
                          side: const BorderSide(color: Color(0xFFD0D5DD)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          localizations?.translate('later') ?? 'Later',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E9E63),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          localizations?.translate('biometric_enable_action') ??
                              'Enable',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _triggerErrorEffect() async {
    setState(() {
      _pinsDoNotMatch = true;
    });
    _animationController.forward(from: 0);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _pinsDoNotMatch = false;
      _confirmPin = '';
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UI
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppBackgroundOverlay(preset: AppBackgroundPreset.aurora),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  decoration: BoxDecoration(
                    color: colors.surfacePrimary.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: colors.borderSubtle.withValues(alpha: 0.42),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icons/playstore.png',
                        height: 132,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isConfirming
                            ? (_pinsDoNotMatch
                                ? AppLocalizations.of(context)!
                                    .translate('pins_do_not_match_error')
                                : AppLocalizations.of(context)!
                                    .translate('confirm_pin_title'))
                            : AppLocalizations.of(context)!
                                .translate('set_pin_title'),
                        textAlign: TextAlign.center,
                        style: textStyles.titleLg.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _pinsDoNotMatch
                              ? colors.error
                              : colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              _pinsDoNotMatch ? _shakeAnimation.value : 0,
                              0,
                            ),
                            child: Column(
                              children: [
                                _buildPinRow(_pin),
                                if (_isConfirming) const SizedBox(height: 16),
                                if (_isConfirming) _buildPinRow(_confirmPin),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.45,
                        children: [
                          for (var i = 1; i <= 9; i++)
                            TextButton(
                              onPressed: () => _onNumberPressed(i.toString()),
                              child: Text(
                                i.toString(),
                                style: textStyles.titleLg.copyWith(
                                  fontSize: 24,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                          TextButton(
                            onPressed: _onDelete,
                            child: Icon(
                              Icons.backspace_outlined,
                              color: colors.buttonPrimaryBg,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _onNumberPressed('0'),
                            child: Text(
                              '0',
                              style: textStyles.titleLg.copyWith(
                                fontSize: 24,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _onClear,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.buttonPrimaryBg,
                          foregroundColor: colors.buttonPrimaryFg,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 24.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.translate('clear'),
                          style: textStyles.labelLg.copyWith(
                            color: colors.buttonPrimaryFg,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinRow(String pin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        4,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: _pinsDoNotMatch
                ? context.appColors.error
                : (index < pin.length
                    ? context.appColors.buttonPrimaryBg
                    : context.appColors.borderSubtle.withValues(alpha: 0.48)),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
