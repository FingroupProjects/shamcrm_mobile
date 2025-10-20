import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/firebase_api.dart';
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
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/models/mini_app_settiings.dart';
import 'package:crm_task_manager/models/user_byId_model..dart';
import 'package:crm_task_manager/screens/auth/forgot_pin.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

// [ИМПОРТЫ ОСТАЮТСЯ БЕЗ ИЗМЕНЕНИЙ]

class PinScreen extends StatefulWidget {
  final RemoteMessage? initialMessage;

  const PinScreen({Key? key, this.initialMessage}) : super(key: key);

  @override
  _PinScreenState createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _isWrongPin = false;
  bool _isIosVersionAbove15 = false;
  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  final LocalAuthentication _auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];
  String _userName = '';
  String _userNameProfile = '';
  String _userImage = '';
  int? userRoleId;
  bool _isLoading = true;
  bool isPermissionsLoaded = false;
  String _storeName = '';
  Map<String, dynamic>? tutorialProgress;
  final ApiService _apiService = ApiService();
  
  // Делаем nullable - инициализируем только если Firebase готов
  FirebaseApi? _firebaseApi;

  @override
  void initState() {
    super.initState();
    print('PinScreen: initState started');
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticIn),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reset();
      }
    });

    // Запускаем инициализацию асинхронно
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWithInternetCheck();
    });
  }
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
  // ==========================================================================
  // ГЛАВНАЯ ИНИЦИАЛИЗАЦИЯ
  // ==========================================================================

  Future<void> _initializeWithInternetCheck() async {
    try {
      print('PinScreen: Начало инициализации');
      
      setState(() {
        _isLoading = true;
      });

      // ШАГ 1: Безопасная инициализация FirebaseApi
      await _initializeFirebaseApi();
      
      // ШАГ 2: Очистка кэша
      try {
        await _apiService.clearCachedSalesFunnels();
      } catch (e) {
        print('PinScreen: Ошибка очистки кэша: $e');
      }
      
      // ШАГ 3: Проверка интернета
      await _ensureInternetConnection();

      // ШАГ 4: Загрузка разрешений
      if (mounted) {
        try {
          context.read<PermissionsBloc>().add(FetchPermissionsEvent());
        } catch (e) {
          print('PinScreen: Ошибка загрузки разрешений: $e');
        }
      }

      // ШАГ 5: Параллельная загрузка данных
      await Future.wait([
        _loadUserPhone(),
        _loadUserRoleId(),
        _fetchMiniAppSettings(),
        _fetchTutorialProgress(),
        _fetchSettings(),
      ], eagerError: true).catchError((e) {
        print('PinScreen: Ошибка загрузки данных: $e');
      });
try {
  print('PinScreen: Загрузка конфигураций полей');
  await _apiService.loadAndCacheAllFieldConfigurations();
  print('PinScreen: Конфигурации полей загружены и закэшированы');
} catch (e) {
  print('PinScreen: Ошибка загрузки конфигураций полей: $e');
  // Не критично, продолжаем работу
}
      // ШАГ 6: Проверка PIN
      await _checkSavedPin();
      
      // ШАГ 7: Биометрия
      await _initBiometrics();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      print('PinScreen: Инициализация завершена успешно');
      
    } catch (e) {
      print('PinScreen: Критическая ошибка инициализации: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Ошибка инициализации', e.toString());
      }
    }
  }

  // ==========================================================================
  // БЕЗОПАСНАЯ ИНИЦИАЛИЗАЦИЯ FIREBASE API
  // ==========================================================================

  Future<void> _initializeFirebaseApi() async {
    try {
      print('PinScreen: Инициализация FirebaseApi');
      
      // Проверка 1: Firebase инициализирован?
      if (Firebase.apps.isEmpty) {
        print('PinScreen: Firebase не инициализирован, пропуск FirebaseApi');
        _firebaseApi = null;
        return;
      }

      // Проверка 2: Default app доступен?
      try {
        final app = Firebase.app();
        print('PinScreen: Firebase app доступен (${app.name})');
      } catch (e) {
        print('PinScreen: Firebase app недоступен: $e');
        _firebaseApi = null;
        return;
      }

      // Проверка 3: Ждём полной готовности
      await Future.delayed(const Duration(milliseconds: 500));

      // Проверка 4: Повторная проверка доступности
      try {
        Firebase.app();
      } catch (e) {
        print('PinScreen: Firebase app недоступен после задержки: $e');
        _firebaseApi = null;
        return;
      }

      // Теперь безопасно создаём FirebaseApi
      _firebaseApi = FirebaseApi();
      print('PinScreen: FirebaseApi успешно создан');
      
    } catch (e) {
      print('PinScreen: Ошибка создания FirebaseApi: $e');
      _firebaseApi = null;
    }
  }

  // ==========================================================================
  // ПРОВЕРКА ИНТЕРНЕТА
  // ==========================================================================

  Future<void> _ensureInternetConnection() async {
    bool hasInternet = false;
    int attempts = 0;
    const maxAttempts = 3;

    while (!hasInternet && attempts < maxAttempts && mounted) {
      attempts++;
      print('PinScreen: Проверка интернета (попытка $attempts)');
      
      var connectivityResult = await (Connectivity().checkConnectivity());
      
      if (connectivityResult == ConnectivityResult.none) {
        if (mounted) {
          await _showNoInternetDialog(context);
        }
      } else {
        try {
          final result = await InternetAddress.lookup('google.com')
              .timeout(Duration(seconds: 5));
          
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            hasInternet = true;
            print('PinScreen: Интернет соединение установлено');
          } else {
            if (mounted) {
              await _showNoInternetDialog(context);
            }
          }
        } catch (e) {
          print('PinScreen: Ошибка проверки интернета: $e');
          if (mounted) {
            await _showNoInternetDialog(context);
          }
        }
      }
    }
  }

  // ==========================================================================
  // ЗАГРУЗКА НАСТРОЕК
  // ==========================================================================

  Future<void> _fetchMiniAppSettings() async {
    try {
      print('PinScreen: Загрузка MiniAppSettings');
      
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
        await prefs.setBool('has_bonus', settings.hasBonus == 1);
        await prefs.setBool('identify_by_phone', settings.identifyByPhone == 1);
        
        print('PinScreen: MiniAppSettings сохранены успешно');
      }
    } catch (e) {
      print('PinScreen: Ошибка загрузки MiniAppSettings: $e');
      
      // Загружаем из кэша
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedSettings = prefs.getString('mini_app_settings');
        if (savedSettings != null) {
          final settings = MiniAppSettings.fromJson(json.decode(savedSettings));
          await prefs.setInt('currency_id', settings.currencyId);
          print('PinScreen: MiniAppSettings загружены из кэша');
        }
      } catch (cacheError) {
        print('PinScreen: Ошибка загрузки из кэша: $cacheError');
      }
    }
  }

  Future<void> _fetchSettings() async {
    try {
      print('PinScreen: Загрузка Settings');
      
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


        print('PinScreen: Settings сохранены успешно');
      }
    } catch (e) {
      print('PinScreen: Ошибка загрузки Settings: $e');
      
      // Устанавливаем значения по умолчанию
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('integration_with_1C', false);
        await prefs.setBool('good_measurement', false);
      await prefs.setBool('managing_deal_status_visibility', false);

      } catch (prefsError) {
        print('PinScreen: Ошибка установки значений по умолчанию: $prefsError');
      }
    }
  }

  Future<void> _fetchTutorialProgress() async {
    try {
      print('PinScreen: Загрузка TutorialProgress');
      
      final prefs = await SharedPreferences.getInstance();
      final progress = await _apiService.getTutorialProgress();
      
      setState(() {
        tutorialProgress = progress['result'];
      });
      
      await prefs.setString('tutorial_progress', json.encode(progress['result']));
      print('PinScreen: TutorialProgress обновлён сервера');
      print('PinScreen: TutorialProgress обновлён с сервера');
    } catch (e) {
      print('PinScreen: Ошибка загрузки TutorialProgress: $e');
      
      // Загружаем из кэша
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedProgress = prefs.getString('tutorial_progress');
        if (savedProgress != null) {
          setState(() {
            tutorialProgress = json.decode(savedProgress);
          });
          print('PinScreen: TutorialProgress загружен из кэша');
        }
      } catch (cacheError) {
        print('PinScreen: Ошибка загрузки из кэша: $cacheError');
      }
    }
  }

  // ==========================================================================
  // БИОМЕТРИЯ
  // ==========================================================================

  Future<void> _initBiometrics() async {
    try {
      print('PinScreen: Инициализация биометрии');
      
      final localizations = AppLocalizations.of(context);
      if (localizations == null) {
        print('PinScreen: Локализация не готова');
        return;
      }

      _canCheckBiometrics = await _auth.canCheckBiometrics;

      if (_canCheckBiometrics) {
        _availableBiometrics = await _auth.getAvailableBiometrics();
        print('PinScreen: Доступные биометрические методы: $_availableBiometrics');
        
        if (_availableBiometrics.isNotEmpty) {
          if (Platform.isIOS && _availableBiometrics.contains(BiometricType.face)) {
            print('PinScreen: Запуск Face ID');
            _authenticate();
          } else if (Platform.isAndroid && _availableBiometrics.contains(BiometricType.strong)) {
            print('PinScreen: Запуск отпечатка пальца');
            _authenticate();
          }
        }
      } else {
        print('PinScreen: Биометрия недоступна');
      }
    } on PlatformException catch (e) {
      print('PinScreen: Ошибка инициализации биометрии: $e');
    } catch (e) {
      print('PinScreen: Неожиданная ошибка биометрии: $e');
    }
  }

  Future<void> _authenticate() async {
    try {
      print('PinScreen: Попытка биометрической аутентификации');
      
      final localizations = AppLocalizations.of(context);
      if (localizations == null) return;

      if (!_canCheckBiometrics || _availableBiometrics.isEmpty) {
        print('PinScreen: Биометрия недоступна для аутентификации');
        return;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: localizations.translate('confirm_identity'),
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        print('PinScreen: Биометрическая аутентификация успешна');
        if (mounted) {
          _navigateToHome();
        }
      } else {
        print('PinScreen: Биометрическая аутентификация отменена');
      }
    } on PlatformException catch (e) {
      print('PinScreen: Ошибка биометрической аутентификации: $e');
    } catch (e) {
      print('PinScreen: Неожиданная ошибка аутентификации: $e');
    }
  }

  // ==========================================================================
  // ЗАГРУЗКА ДАННЫХ ПОЛЬЗОВАТЕЛЯ
  // ==========================================================================

  Future<void> _loadUserRoleId() async {
    try {
      print('PinScreen: Загрузка роли пользователя');
      
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('userID') ?? '';

      if (userId.isEmpty) {
        print('PinScreen: UserID не найден');
        if (mounted) {
          setState(() {
            userRoleId = 0;
          });
        }
        return;
      }

      await prefs.remove('userRoles');

      UserByIdProfile userProfile = await _apiService.getUserById(int.parse(userId));
      
      if (userProfile.role != null && userProfile.role!.isNotEmpty) {
        if (mounted) {
          setState(() {
            userRoleId = userProfile.role!.first.id;
          });
        }
        print('PinScreen: Роль пользователя загружена: $userRoleId');
      }

      if (mounted) {
        BlocProvider.of<LeadBloc>(context).add(FetchLeadStatuses());
        BlocProvider.of<DealBloc>(context).add(FetchDealStatuses());
        BlocProvider.of<TaskBloc>(context).add(FetchTaskStatuses());
        BlocProvider.of<MyTaskBloc>(context).add(FetchMyTaskStatuses());

        setState(() {
          isPermissionsLoaded = true;
        });
        
        print('PinScreen: Статусы загружены успешно');
      }
    } catch (e) {
      print('PinScreen: Ошибка загрузки роли пользователя: $e');
      if (mounted) {
        setState(() {
          userRoleId = 0;
        });
      }
    }
  }

  Future<void> _loadUserPhone() async {
    try {
      print('PinScreen: Загрузка данных пользователя');
      
      SharedPreferences prefs = await SharedPreferences.getInstance();

      String? savedUserName = prefs.getString('userName');
      String? savedUserNameProfile = prefs.getString('userNameProfile');
      String? savedUserImage = prefs.getString('userImage');

      if (savedUserName != null && savedUserNameProfile != null && savedUserImage != null) {
        if (mounted) {
          setState(() {
            _userName = savedUserName;
            _userNameProfile = savedUserNameProfile;
            _userImage = savedUserImage;
          });
        }
        print('PinScreen: Данные пользователя загружены из кэша');
        return;
      }

      String UUID = prefs.getString('userID') ?? '';
      
      if (UUID.isEmpty) {
        print('PinScreen: UserID не найден');
        return;
      }

      print('PinScreen: Загрузка профиля пользователя с сервера');
      UserByIdProfile userProfile = await _apiService.getUserById(int.parse(UUID));

      await prefs.setString('userName', userProfile.name);
      await prefs.setString('userNameProfile', userProfile.name ?? '');
      await prefs.setString('userImage', userProfile.image ?? '');
      
      if (mounted) {
        setState(() {
          _userName = userProfile.name;
          _userNameProfile = userProfile.name ?? '';
          _userImage = userProfile.image ?? '';
        });
      }
      
      print('PinScreen: Данные пользователя загружены с сервера');
    } catch (e) {
      print('PinScreen: Ошибка загрузки данных пользователя: $e');
      if (mounted) {
        setState(() {
          _userName = 'Не найдено';
          _userNameProfile = 'Не найдено';
          _userImage = '';
        });
      }
    }
  }

  Future<void> _checkSavedPin() async {
    try {
      print('PinScreen: Проверка сохраненного PIN');
      
      final prefs = await SharedPreferences.getInstance();
      final savedPin = prefs.getString('user_pin');
      
      if (savedPin == null) {
        print('PinScreen: PIN не найден, переход на настройку');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/pin_setup');
        }
      } else {
        print('PinScreen: PIN найден');
      }
    } catch (e) {
      print('PinScreen: Ошибка проверки PIN: $e');
    }
  }

  // ==========================================================================
  // НАВИГАЦИЯ
  // ==========================================================================

  void _navigateToHome() {
    if (!mounted) return;
    
    print('PinScreen: Навигация на главный экран');
    
    // Выполняем асинхронно чтобы не блокировать UI
    Future.delayed(Duration(milliseconds: 50), () {
      if (!mounted) return;
      
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          // Загружаем tutorial progress если нужно
          if (tutorialProgress == null) {
            print('PinScreen: Tutorial progress отсутствует, загружаем');
            await _fetchTutorialProgress();
          }
          
          // Обрабатываем initial message если есть
          if (widget.initialMessage != null) {
            if (_firebaseApi != null) {
              print('PinScreen: Обработка initial message');
              await _firebaseApi!.handleMessage(widget.initialMessage!);
            } else {
              print('PinScreen: FirebaseApi недоступен, initial message не обработано');
            }
          }
          
        } catch (e) {
          print('PinScreen: Ошибка в post frame callback: $e');
        }
      });
      
      // Выполняем навигацию
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  // ==========================================================================
  // ОБРАБОТКА ВВОДА PIN
  // ==========================================================================

  void _onNumberPressed(String number) async {
    if (_pin.length < 4) {
      setState(() {
        _pin += number;
      });

      // Вибрация
      try {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 50);
        }
      } catch (e) {
        // Игнорируем ошибки вибрации
      }

      if (_pin.length == 4) {
        print('PinScreen: PIN введен, проверка');
        
        final prefs = await SharedPreferences.getInstance();
        final savedPin = prefs.getString('user_pin');

        if (_pin == savedPin) {
          print('PinScreen: PIN корректен');
          if (mounted) {
            _navigateToHome();
          }
        } else {
          print('PinScreen: PIN некорректен');
          _triggerErrorEffect();
        }
      }
    }
  }

  void _triggerErrorEffect() async {
    print('PinScreen: Эффект ошибки PIN');
    
    // Вибрация
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 200);
      }
    } catch (e) {
      // Игнорируем
    }
    
    setState(() {
      _isWrongPin = true;
      _pin = '';
    });

    _animationController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      setState(() {
        _isWrongPin = false;
      });
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _isWrongPin = false;
      });
    }
  }

  void _onExitPressed() {
    print('PinScreen: Выход из приложения');
    SystemNavigator.pop();
  }

  // ==========================================================================
  // ДИАЛОГИ
  // ==========================================================================

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text('Произошла ошибка. Попробуйте перезапустить приложение.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              SystemNavigator.pop();
            },
            child: Text('Закрыть приложение'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeWithInternetCheck();
            },
            child: Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Future<void> _showNoInternetDialog(BuildContext context) async {
    final localizations = AppLocalizations.of(context);
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 48.0,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16.0),
                Text(
                  localizations?.translate('no_internet') ?? 'Нет интернета',
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Gilroy',
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
                Text(
                  localizations?.translate('please_check_internet') ??
                      'Пожалуйста, проверьте подключение к интернету',
                  style: const TextStyle(
                    fontSize: 16.0,
                    color: Colors.black54,
                    fontFamily: 'Gilroy',
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32.0,
                      vertical: 12.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 2.0,
                  ),
                  child: Text(
                    localizations?.translate('retry') ?? 'Повторить',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Gilroy',
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
  // ==========================================================================

  String getGreetingMessage() {
    final hour = DateTime.now().hour;
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return 'Добро пожаловать!';

    if (hour >= 5 && hour < 11) {
      return '${localizations.translate('greeting_morning')}, $_userNameProfile!';
    } else if (hour >= 11 && hour < 18) {
      return '${localizations.translate('greeting_day')}, $_userNameProfile!';
    } else if (hour >= 18 && hour < 22) {
      return '${localizations.translate('greeting_evening')}, $_userNameProfile!';
    } else {
      return '${localizations.translate('greeting_night')}, $_userNameProfile!';
    }
  }

  @override
  void dispose() {
    print('PinScreen: dispose');
    _animationController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    if (localizations == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Показываем индикатор загрузки
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
              // SizedBox(height: 20),
              // Text(
              //   'Загрузка...',
              //   style: TextStyle(
              //     fontSize: 16,
              //     color: Colors.grey[600],
              //   ),
              // ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.12,
              ),
              Image.asset(
                'assets/icons/playstore.png',
                height: 150,
              ),
              const SizedBox(height: 20),
              Text(
                getGreetingMessage(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isWrongPin
                    ? localizations.translate('wrong_pin')
                    : localizations.translate('enter_pin'),
                style: TextStyle(
                  fontSize: 16,
                  color: _isWrongPin ? Colors.red : Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_isWrongPin ? _shakeAnimation.value : 0, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        4,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8.0),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _isWrongPin
                                ? Colors.red
                                : (index < _pin.length
                                    ? const Color.fromARGB(255, 33, 41, 188)
                                    : Colors.grey.shade300),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  childAspectRatio: 1.5,
                  children: [
                    for (var i = 1; i <= 9; i++)
                      TextButton(
                        onPressed: () => _onNumberPressed(i.toString()),
                        child: Text(
                          i.toString(),
                          style: const TextStyle(
                              fontSize: 24, color: Colors.black),
                        ),
                      ),
                    TextButton(
                      onPressed: _onExitPressed,
                      child: Text(
                        localizations.translate('exit'),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color.fromARGB(255, 33, 41, 188),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _onNumberPressed('0'),
                      child: const Text(
                        '0',
                        style: TextStyle(fontSize: 24, color: Colors.black),
                      ),
                    ),
                    if (!_isIosVersionAbove15)
                      TextButton(
                        onPressed: _pin.isEmpty ? _authenticate : _onDelete,
                        child: Icon(
                          _pin.isEmpty
                              ? Icons.fingerprint
                              : Icons.backspace_outlined,
                          color: const Color.fromARGB(255, 33, 41, 188),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ForgotPinScreen(),
                  ));
                },
                child: Text(
                  localizations.translate('forgot_pin'),
                  style:
                      const TextStyle(color: Color.fromARGB(255, 24, 65, 99)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}