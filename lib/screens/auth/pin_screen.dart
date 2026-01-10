import 'dart:convert';
import 'dart:io';
// import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/firebase_api.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/screens/auth/forgot_pin.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

import '../../update_dialog.dart';

class PinScreen extends StatefulWidget {
  final RemoteMessage? initialMessage;

  const PinScreen({
    Key? key,
    this.initialMessage,
  }) : super(key: key);

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
  bool _isBiometricEnabled = false;
  String _userName = '';
  String _userNameProfile = '';
  String _userImage = '';
  bool _isLoading = true;
  bool _isInitialized = false;
  bool _isPinVerified = false; // ✅ НОВОЕ: Флаг верификации PIN
  final ApiService _apiService = ApiService();
  
  FirebaseApi? _firebaseApi;

  @override
  void initState() {
    super.initState();
    
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

    _initializeMinimal();
  }

  // ==========================================================================
  // МИНИМАЛЬНАЯ ИНИЦИАЛИЗАЦИЯ
  // ==========================================================================

  Future<void> _initializeMinimal() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      // ШАГ 1: Проверка обновления (быстро, не блокирует)
      _checkForNewVersionSilently();

      // ШАГ 2: Инициализация FirebaseApi
      await _initializeFirebaseApi();

      // ШАГ 3: Загрузка базовой информации (из кэша - быстро)
      await _loadUserBasicInfo();

      // ШАГ 4: Проверка PIN
      await _checkSavedPin();
      
      // ШАГ 5: Загрузка настройки биометрии
      await _loadBiometricSetting();
      
      // ШАГ 6: Биометрия (только если включена)
      await _initBiometrics();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Ошибка инициализации', e.toString());
      }
    }
  }

  // ==========================================================================
  // ЗАГРУЗКА БАЗОВОЙ ИНФОРМАЦИИ
  // ==========================================================================

  Future<void> _loadUserBasicInfo() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      String? savedUserName = prefs.getString('userName');
      String? savedUserNameProfile = prefs.getString('userNameProfile');
      String? savedUserImage = prefs.getString('userImage');

      if (mounted) {
        setState(() {
          _userName = savedUserName ?? 'Пользователь';
          _userNameProfile = savedUserNameProfile ?? 'Пользователь';
          _userImage = savedUserImage ?? '';
        });
      }
    } catch (e) {
      //print('PinScreen: Ошибка загрузки базовой информации: $e');
    }
  }

  // ==========================================================================
  // ПРОВЕРКА ОБНОВЛЕНИЙ
  // ==========================================================================

  Future<void> _checkForNewVersionSilently() async {
    try {
      final newVersionPlus = NewVersionPlus();
      final status = await newVersionPlus.getVersionStatus();
      debugPrint("pinScreen. APP_VERSION: Current: ${status?.localVersion}, Store: ${status?.storeVersion}, CanUpdate: ${status?.canUpdate}");

      if (mounted && context.mounted && status != null && status.canUpdate == true) {
        final localizations = AppLocalizations.of(context);
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && context.mounted) {
            UpdateDialog.show(
              context: context,
              status: status,
              title: localizations?.translate('app_update_available_title') ?? 'Обновление',
              message: localizations?.translate('app_update_available_message') ?? 'Доступна новая версия приложения',
              updateButton: localizations?.translate('app_update_button') ?? 'Обновить',
            );
          }
        });
      }
    } catch (e) {
      // Игнорируем
    }
  }

  // ==========================================================================
  // FIREBASE
  // ==========================================================================

  Future<void> _initializeFirebaseApi() async {
    try {
      if (Firebase.apps.isEmpty) {
        _firebaseApi = null;
        return;
      }

      try {
        Firebase.app();
      } catch (e) {
        _firebaseApi = null;
        return;
      }

      await Future.delayed(const Duration(milliseconds: 300));

      try {
        Firebase.app();
      } catch (e) {
        _firebaseApi = null;
        return;
      }

      _firebaseApi = FirebaseApi();
      
    } catch (e) {
      _firebaseApi = null;
    }
  }

  // ==========================================================================
  // PIN И БИОМЕТРИЯ
  // ==========================================================================

  Future<void> _checkSavedPin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPin = prefs.getString('user_pin');
      
      if (savedPin == null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/pin_setup');
        }
      }
    } catch (e) {
      //print('PinScreen: Ошибка проверки PIN: $e');
    }
  }

  Future<void> _loadBiometricSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _isBiometricEnabled = prefs.getBool('biometric_auth_enabled') ?? false;
        });
      }
    } catch (e) {
      //print('PinScreen: Ошибка загрузки настройки биометрии: $e');
    }
  }

  Future<void> _initBiometrics() async {
    try {
      // Check if biometric auth is enabled in settings
      if (!_isBiometricEnabled) {
        return; // Biometric auth is disabled, don't show/trigger it
      }

      final localizations = AppLocalizations.of(context);
      if (localizations == null) return;

      _canCheckBiometrics = await _auth.canCheckBiometrics;

      if (_canCheckBiometrics) {
        _availableBiometrics = await _auth.getAvailableBiometrics();
        
        if (_availableBiometrics.isNotEmpty) {
          if (Platform.isIOS && _availableBiometrics.contains(BiometricType.face)) {
            _authenticate();
          } else if (Platform.isAndroid && _availableBiometrics.contains(BiometricType.strong)) {
            _authenticate();
          }
        }
      }
    } on PlatformException catch (e) {
      //print('PinScreen: Ошибка инициализации биометрии: $e');
    } catch (e) {
      //print('PinScreen: Неожиданная ошибка биометрии: $e');
    }
  }

  Future<void> _authenticate() async {
    try {
      final localizations = AppLocalizations.of(context);
      if (localizations == null) return;

      if (!_canCheckBiometrics || _availableBiometrics.isEmpty) return;

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: localizations.translate('confirm_identity'),
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate && mounted) {
        // ✅ ИСПРАВЛЕНИЕ: Устанавливаем флаг верификации
        setState(() {
          _isPinVerified = true;
        });
        _navigateToHome();
      }
    } on PlatformException catch (e) {
      //print('PinScreen: Ошибка биометрической аутентификации: $e');
    } catch (e) {
      //print('PinScreen: Неожиданная ошибка аутентификации: $e');
    }
  }

  // ==========================================================================
  // НАВИГАЦИЯ
  // ==========================================================================

  void _navigateToHome() {
    if (!mounted) return;
    
    // ✅ КРИТИЧНО: Проверяем флаг верификации
    if (!_isPinVerified) {
      debugPrint('PinScreen: PIN не верифицирован, отменяем навигацию');
      return;
    }
    
    debugPrint('PinScreen: PIN верифицирован, переход на HomeScreen');
    
    // ✅ ИСПРАВЛЕНИЕ: Передаем initialMessage через arguments
    Future.delayed(Duration(milliseconds: 50), () {
      if (!mounted) return;
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/home',
          arguments: {
            'initialMessage': widget.initialMessage, // ⬅️ Передаем сообщение
          },
        );
      }
    });
  }

  // ==========================================================================
  // ОБРАБОТКА PIN
  // ==========================================================================

  void _onNumberPressed(String number) async {
    if (_pin.length < 4) {
      setState(() {
        _pin += number;
      });

      try {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 50);
        }
      } catch (e) {}

      if (_pin.length == 4) {
        final prefs = await SharedPreferences.getInstance();
        final savedPin = prefs.getString('user_pin');

        if (_pin == savedPin) {
          debugPrint('PinScreen: PIN корректен');
          
          // ✅ ИСПРАВЛЕНИЕ: Устанавливаем флаг ПЕРЕД навигацией
          setState(() {
            _isPinVerified = true;
          });
          
          if (mounted) {
            _navigateToHome();
          }
        } else {
          debugPrint('PinScreen: PIN некорректен');
          _triggerErrorEffect();
        }
      }
    }
  }

  void _triggerErrorEffect() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 200);
      }
    } catch (e) {}
    
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
        content: Text(message),
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
              setState(() {
                _isInitialized = false;
                _isLoading = true;
              });
              _initializeMinimal();
            },
            child: Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showNoInternetDialog(BuildContext context) async {
    final localizations = AppLocalizations.of(context);
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: Text(
                          'Отмена',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Gilroy',
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
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
                ],
              ),
            ),
          ),
        );
      },
    );

    return result ?? false;
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
    _animationController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: PlayStoreImageLoading(
            size: 80.0,
            duration: Duration(milliseconds: 1000),
          ),
        ),
      );
    }

    if (localizations == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: PlayStoreImageLoading(
            size: 80.0,
            duration: Duration(milliseconds: 1000),
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
                    if (!_isIosVersionAbove15 && _isBiometricEnabled)
                      TextButton(
                        onPressed: _pin.isEmpty ? _authenticate : _onDelete,
                        child: Icon(
                          _pin.isEmpty
                              ? Icons.fingerprint
                              : Icons.backspace_outlined,
                          color: const Color.fromARGB(255, 33, 41, 188),
                        ),
                      )
                    else if (!_isIosVersionAbove15 && !_isBiometricEnabled && _pin.isNotEmpty)
                      TextButton(
                        onPressed: _onDelete,
                        child: const Icon(
                          Icons.backspace_outlined,
                          color: Color.fromARGB(255, 33, 41, 188),
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
