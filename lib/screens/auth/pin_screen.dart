import 'dart:async';
// import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crm_task_manager/api/service/biometric_service.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/screens/auth/forgot_pin.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/services/chat_unread_counter_service.dart';
import 'package:crm_task_manager/widgets/biometric_dialogs.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';

import '../../update_dialog.dart';

class PinScreen extends StatefulWidget {
  final RemoteMessage? initialMessage;

  const PinScreen({
    super.key,
    this.initialMessage,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _isWrongPin = false;
  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  final BiometricService _biometricService = BiometricService();
  BiometricAvailability? _biometricAvailability;
  bool _isBiometricEnabled = false;
  String _userNameProfile = '';
  bool _isLoading = true;
  bool _isInitialized = false;
  bool _isPinVerified = false; // ✅ НОВОЕ: Флаг верификации PIN

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
        _showErrorDialog(
          AppLocalizations.of(context)?.translate('initialization_error') ??
              'Ошибка инициализации',
          e.toString(),
        );
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
      if (mounted) {
        final fallbackUser =
            AppLocalizations.of(context)?.translate('user') ?? 'Пользователь';
        setState(() {
          _userNameProfile =
              savedUserNameProfile ?? savedUserName ?? fallbackUser;
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
      debugPrint(
          "pinScreen. APP_VERSION: Current: ${status?.localVersion}, Store: ${status?.storeVersion}, CanUpdate: ${status?.canUpdate}");

      if (mounted &&
          context.mounted &&
          status != null &&
          status.canUpdate == true) {
        final localizations = AppLocalizations.of(context);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && context.mounted) {
            UpdateDialog.show(
              context: context,
              status: status,
              title: localizations?.translate('app_update_available_title') ??
                  'Обновление',
              message:
                  localizations?.translate('app_update_available_message') ??
                      'Доступна новая версия приложения',
              updateButton:
                  localizations?.translate('app_update_button') ?? 'Обновить',
              laterButton: localizations?.translate('later') ??
                  'Позже', // ← Добавь перевод
              onLaterPressed: () {
                // Опционально: можно сохранить, что пользователь отложил обновление
                // Например: SharedPreferences.setBool('update_later_shown', true);
                debugPrint('Пользователь отложил обновление');
              },
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
        return;
      }

      try {
        Firebase.app();
      } catch (e) {
        return;
      }

      await Future.delayed(const Duration(milliseconds: 300));

      try {
        Firebase.app();
      } catch (e) {
        return;
      }
    } catch (e) {
      debugPrint('PinScreen: FirebaseApi init skipped: $e');
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
      final isEnabled = await _biometricService.isBiometricEnabled();
      final availability = await _biometricService.getAvailability();
      if (!mounted) return;

      setState(() {
        _biometricAvailability = availability;
        _isBiometricEnabled = isEnabled && availability.hasAnyBiometric;
      });
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

      final availability =
          _biometricAvailability ?? await _biometricService.getAvailability();
      _biometricAvailability = availability;

      if (availability.hasAnyBiometric) {
        _authenticate();
      }
    } catch (e) {
      //print('PinScreen: Неожиданная ошибка биометрии: $e');
    }
  }

  Future<void> _authenticate() async {
    try {
      final localizations = AppLocalizations.of(context);
      if (localizations == null) return;

      final availability =
          _biometricAvailability ?? await _biometricService.getAvailability();
      if (!availability.hasAnyBiometric) return;

      final bool didAuthenticate = await _biometricService.authenticate(
        reason: localizations.translate('confirm_identity'),
      );

      if (didAuthenticate && mounted) {
        // ✅ ИСПРАВЛЕНИЕ: Устанавливаем флаг верификации
        setState(() {
          _isPinVerified = true;
        });
        _navigateToHome();
      }
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
    unawaited(ChatUnreadCounterService.instance.initialize());

    // ✅ ИСПРАВЛЕНИЕ: Передаем initialMessage через arguments
    Future.delayed(Duration(milliseconds: 50), () {
      if (!mounted) return;

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
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
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate(duration: 50);
        }
      } catch (e) {
        debugPrint('PinScreen: vibration error on press: $e');
      }

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
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 200);
      }
    } catch (e) {
      debugPrint('PinScreen: vibration error on mismatch: $e');
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
            child: Text(
              AppLocalizations.of(context)?.translate('close_app') ??
                  'Закрыть приложение',
            ),
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
            child: Text(
              AppLocalizations.of(context)?.translate('retry_dialog') ??
                  'Повторить',
            ),
          ),
        ],
      ),
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
    _animationController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.backgroundPrimary,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const AppBackgroundOverlay(preset: AppBackgroundPreset.aurora),
            Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: const Duration(milliseconds: 1000),
              ),
            ),
          ],
        ),
      );
    }

    if (localizations == null) {
      return Scaffold(
        backgroundColor: colors.backgroundPrimary,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const AppBackgroundOverlay(preset: AppBackgroundPreset.aurora),
            Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: const Duration(milliseconds: 1000),
              ),
            ),
          ],
        ),
      );
    }

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
                        height: 124,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        getGreetingMessage(),
                        style: textStyles.titleLg.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isWrongPin
                            ? localizations.translate('wrong_pin')
                            : localizations.translate('enter_pin'),
                        style: textStyles.bodyMd.copyWith(
                          fontSize: 16,
                          color: _isWrongPin
                              ? colors.error
                              : colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset:
                                Offset(_isWrongPin ? _shakeAnimation.value : 0, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                4,
                                (index) => Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _isWrongPin
                                        ? colors.error
                                        : (index < _pin.length
                                            ? colors.buttonPrimaryBg
                                            : colors.borderSubtle
                                                .withValues(alpha: 0.48)),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
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
                            onPressed: _onExitPressed,
                            child: Text(
                              localizations.translate('exit'),
                              style: textStyles.bodyMd.copyWith(
                                fontSize: 16,
                                color: colors.buttonPrimaryBg,
                                fontWeight: FontWeight.w700,
                              ),
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
                          if (_isBiometricEnabled &&
                              (_biometricAvailability?.hasAnyBiometric ?? false))
                            TextButton(
                              onPressed: _pin.isEmpty ? _authenticate : _onDelete,
                              child: _pin.isEmpty
                                  ? biometricIconWidget(
                                      availability: _biometricAvailability!,
                                      size: 24,
                                      color: colors.buttonPrimaryBg,
                                    )
                                  : Icon(
                                      Icons.backspace_outlined,
                                      color: colors.buttonPrimaryBg,
                                    ),
                            )
                          else if (!_isBiometricEnabled && _pin.isNotEmpty)
                            TextButton(
                              onPressed: _onDelete,
                              child: Icon(
                                Icons.backspace_outlined,
                                color: colors.buttonPrimaryBg,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ForgotPinScreen(),
                            ),
                          );
                        },
                        child: Text(
                          localizations.translate('forgot_pin'),
                          style: textStyles.bodyMd.copyWith(
                            color: colors.buttonPrimaryBg,
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
}
