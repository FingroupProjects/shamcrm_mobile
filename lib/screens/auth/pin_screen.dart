import 'dart:async';
// import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/biometric_service.dart';
import 'package:crm_task_manager/app_feature_flags.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/auth/forgot_pin.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/sip/sip_screen.dart';
import 'package:crm_task_manager/screens/sip/sip_service.dart';
import 'package:crm_task_manager/screens/sip/sip_state.dart';
import 'package:crm_task_manager/services/chat_unread_counter_service.dart';
import 'package:crm_task_manager/widgets/adaptive_pin_layout.dart';
import 'package:crm_task_manager/widgets/biometric_dialogs.dart';
import 'package:crm_task_manager/widgets/liquid_pin_key.dart';
import 'package:crm_task_manager/widgets/pin_adaptive_contrast.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';

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

class _PinScreenState extends State<PinScreen> with TickerProviderStateMixin {
  static const String _sipPinRequiredAfterCallKey =
      'sip_pin_required_after_call_v1';
  String _pin = '';
  bool _isWrongPin = false;
  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  late AnimationController _introController;
  late Animation<double> _introScale;
  final BiometricService _biometricService = BiometricService();
  BiometricAvailability? _biometricAvailability;
  bool _isBiometricEnabled = false;
  String _userNameProfile = '';
  bool _isInitialized = false;
  bool _isPinVerified = false; // ✅ НОВОЕ: Флаг верификации PIN
  bool _isPinChecking = false;
  bool _showIntro = true;
  bool _didNavigateToSipCall = false;
  final PinAdaptiveContrastController _adaptiveContrast =
      PinAdaptiveContrastController();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _introController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    _introScale = Tween<double>(begin: 1.18, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticIn),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reset();
      }
    });

    _startIntroAndInitialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adaptiveContrast.syncWithContext(
      context,
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _startIntroAndInitialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final introEnabled =
          prefs.getBool('app_login_intro_animation_v1') ?? true;

      if (mounted) {
        setState(() {
          _showIntro = introEnabled;
        });
      }

      final initFuture = _initializeMinimal();

      if (introEnabled) {
        await _introController.forward();
      } else {
        await Future.delayed(const Duration(milliseconds: 120));
      }

      if (!mounted) return;
      setState(() {
        _showIntro = false;
      });

      await initFuture;

      if (_didNavigateToSipCall || !mounted) return;
      await _loadBiometricSetting();
      await _initBiometrics();
    } catch (e) {
      debugPrint('PinScreen: intro init error: $e');
      if (mounted) {
        setState(() {
          _showIntro = false;
        });
      }
      await _initializeMinimal();
      if (_didNavigateToSipCall || !mounted) return;
      await _loadBiometricSetting();
      await _initBiometrics();
    }
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

      final shouldBypassPin = await _shouldBypassPinForActiveSipCall().timeout(
        const Duration(seconds: 4),
        onTimeout: () => false,
      );
      if (shouldBypassPin && mounted) {
        await _markPinRequiredAfterSipCall();
        _didNavigateToSipCall = true;
        _navigateToSipCallOnly();
      }
    } catch (e) {
      if (mounted) {
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

  Future<bool> _shouldBypassPinForActiveSipCall() async {
    if (!sipEnabled) return false;
    try {
      final sipService = SipService();
      await sipService.initialize();
      final status = sipService.state.callStatus;
      return status == SipCallUiStatus.incoming ||
          status == SipCallUiStatus.calling ||
          status == SipCallUiStatus.ringing ||
          status == SipCallUiStatus.inCall;
    } catch (_) {
      return false;
    }
  }

  Future<void> _markPinRequiredAfterSipCall() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_sipPinRequiredAfterCallKey, true);
    } catch (_) {}
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
    if (_showIntro) {
      return;
    }
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
    if (_isPinChecking || _isPinVerified) return;

    try {
      final localizations = AppLocalizations.of(context);
      if (localizations == null) return;

      final availability =
          _biometricAvailability ?? await _biometricService.getAvailability();
      if (!availability.hasAnyBiometric) return;

      // Face ID / отпечаток используют тот же визуальный статус, что и PIN:
      // четыре заполненные точки идут волной, пока система проверяет личность.
      setState(() => _isPinChecking = true);
      final bool didAuthenticate = await _biometricService.authenticate(
        reason: localizations.translate('confirm_identity'),
      );

      if (didAuthenticate && mounted) {
        final hasAccess = await _checkAccountAccess();
        if (!hasAccess) return;

        // ✅ ИСПРАВЛЕНИЕ: Устанавливаем флаг верификации
        setState(() {
          _isPinVerified = true;
        });
        _navigateToHome();
      } else if (mounted) {
        _triggerErrorEffect();
      }
    } catch (e) {
      debugPrint('PinScreen: biometric authentication failed: $e');
      if (mounted) {
        _triggerErrorEffect();
      }
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

  void _navigateToSipCallOnly() {
    if (!sipEnabled || !mounted) return;

    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const SipScreen(),
          settings: const RouteSettings(name: '/sip_call_only'),
        ),
        (route) => false,
      );
    });
  }

  // ==========================================================================
  // ОБРАБОТКА PIN
  // ==========================================================================

  void _onNumberPressed(String number) async {
    if (_isPinChecking) return;

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
        setState(() => _isPinChecking = true);
        try {
          final prefs = await SharedPreferences.getInstance();
          final savedPin = prefs.getString('user_pin');

          if (_pin == savedPin) {
            debugPrint('PinScreen: PIN корректен');

            final hasAccess = await _checkAccountAccess();
            if (!hasAccess) return;

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
        } finally {
          if (mounted && !_isPinVerified) {
            setState(() => _isPinChecking = false);
          }
        }
      }
    }
  }

  Future<bool> _checkAccountAccess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = int.tryParse(
        prefs.getString('userID') ?? prefs.getString('user_id') ?? '',
      );

      if (userId == null) {
        debugPrint('PinScreen: Не удалось определить user_id для проверки');
        return true;
      }

      final hasAccess =
          await context.read<ApiService>().checkUserAccess(userId);
      if (hasAccess) return true;

      debugPrint('PinScreen: ⛔ Аккаунт пользователя заблокирован');
      if (!mounted) return false;

      _showBlockedAccountSnackBar();
      _triggerErrorEffect();
      return false;
    } catch (e) {
      debugPrint('PinScreen: Ошибка проверки доступа: $e');
      return true;
    }
  }

  void _showBlockedAccountSnackBar() {
    final colors = context.appColors;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          elevation: 8,
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          duration: const Duration(minutes: 1),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colors.surfacePrimary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.error.withValues(alpha: 0.26),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    color: colors.error,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 15,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      children: [
                        const TextSpan(
                          text:
                              'Ваш аккаунт заблокирован. Пожалуйста, обратитесь к тех поддержке ',
                        ),
                        TextSpan(
                          text: '@shamcrm_uz',
                          style: TextStyle(
                            color: colors.buttonPrimaryBg,
                            fontWeight: FontWeight.w800,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = _openSupportTelegram,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  Future<void> _openSupportTelegram() async {
    const username = 'shamcrm_uz';
    final telegramUri = Uri.parse('tg://resolve?domain=$username');
    final webUri = Uri.parse('https://t.me/$username');

    final openedTelegram = await launchUrl(
      telegramUri,
      mode: LaunchMode.externalApplication,
    );

    if (!openedTelegram) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
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
      _isPinChecking = false;
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
    if (_isPinChecking) return;

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
    _introController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final textStyles = context.appTextStyles;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adaptivePalette = _adaptiveContrast.resolve(
      context,
      isDark: isDark,
    );
    final pinForeground =
        adaptivePalette.foregroundFor(adaptivePalette.headerLuminance);
    final pinSecondary =
        adaptivePalette.secondaryFor(adaptivePalette.headerLuminance);
    final pinAccent =
        adaptivePalette.accentFor(adaptivePalette.headerLuminance);
    final keypadForeground =
        adaptivePalette.foregroundFor(adaptivePalette.keypadLuminance);
    final actionForeground =
        adaptivePalette.foregroundFor(adaptivePalette.bottomLuminance);
    final keypadShadows =
        adaptivePalette.shadowsFor(adaptivePalette.keypadLuminance);
    final actionShadows =
        adaptivePalette.shadowsFor(adaptivePalette.bottomLuminance);
    final pinTextShadows =
        adaptivePalette.shadowsFor(adaptivePalette.headerLuminance);
    final headerOnDarkBackground =
        adaptivePalette.isDarkBackground(adaptivePalette.headerLuminance);
    final keypadOnDarkBackground =
        adaptivePalette.isDarkBackground(adaptivePalette.keypadLuminance);
    final pinErrorColor = headerOnDarkBackground
        ? const Color(0xFFFFB4AB)
        : const Color(0xFFB3261E);
    final pinLogo = Image.asset(
      'assets/icons/playstore.png',
      fit: BoxFit.contain,
    );

    if (localizations == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: const SizedBox.expand(),
      );
    }

    if (_showIntro) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Keep the same wallpaper as the rest of the app during intro
            // so we never flash the solid theme color / day-night assets.
            AnimatedBuilder(
              animation: _introController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _introScale.value,
                  child: child,
                );
              },
              child: const AppBackgroundOverlay(
                preset: AppBackgroundPreset.aurora,
                forceRender: true,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Parent MaterialApp already draws the wallpaper; keep PIN chrome
          // transparent so the solid blue scaffold never flashes underneath.
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: AdaptivePinContent(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 460),
                  padding: const EdgeInsets.fromLTRB(4, 20, 4, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, 6),
                        child: SizedBox(
                          width: 150,
                          height: 150,
                          child: headerOnDarkBackground
                              ? ColorFiltered(
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                  child: pinLogo,
                                )
                              : pinLogo,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        getGreetingMessage(),
                        style: textStyles.titleLg.copyWith(
                          fontFamily: 'SF Pro Display',
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: pinForeground,
                          shadows: pinTextShadows,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isWrongPin
                            ? localizations.translate('wrong_pin')
                            : localizations.translate('enter_pin'),
                        style: textStyles.bodyMd.copyWith(
                          fontFamily: 'SF Pro Display',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _isWrongPin ? pinErrorColor : pinSecondary,
                          shadows: pinTextShadows,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                                _isWrongPin ? _shakeAnimation.value : 0, 0),
                            child: PinProgressDots(
                              filledCount: _pin.length,
                              isLoading: _isPinChecking,
                              isError: _isWrongPin,
                              activeColor: pinAccent,
                              inactiveColor:
                                  pinForeground.withValues(alpha: 0.24),
                              errorColor: pinErrorColor,
                              size: 12,
                              spacing: 8,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      AdaptivePinKeypad(
                        children: [
                          for (var i = 1; i <= 9; i++)
                            LiquidPinKey(
                              digit: i.toString(),
                              onPressed: () => _onNumberPressed(i.toString()),
                              textColor: keypadForeground,
                              isDarkBackground: keypadOnDarkBackground,
                            ),
                          _PinPlainAction(
                            onPressed: _onExitPressed,
                            semanticLabel: localizations.translate('exit'),
                            child: Text(
                              localizations.translate('exit'),
                              style: textStyles.bodyMd.copyWith(
                                fontFamily: 'SF Pro Display',
                                fontSize: 16,
                                color: keypadForeground,
                                fontWeight: FontWeight.w600,
                                shadows: keypadShadows,
                              ),
                            ),
                          ),
                          LiquidPinKey(
                            digit: '0',
                            onPressed: () => _onNumberPressed('0'),
                            textColor: keypadForeground,
                            isDarkBackground: keypadOnDarkBackground,
                          ),
                          if (_isBiometricEnabled &&
                              (_biometricAvailability?.hasAnyBiometric ??
                                  false))
                            _PinPlainAction(
                              onPressed:
                                  _pin.isEmpty ? _authenticate : _onDelete,
                              semanticLabel: _pin.isEmpty
                                  ? localizations.translate('confirm_identity')
                                  : 'Удалить цифру',
                              child: _pin.isEmpty
                                  ? biometricIconWidget(
                                      availability: _biometricAvailability!,
                                      size: 30,
                                      color: keypadForeground,
                                    )
                                  : Icon(
                                      Icons.backspace_outlined,
                                      color: keypadForeground,
                                      size: 27,
                                      shadows: keypadShadows,
                                    ),
                            )
                          else if (!_isBiometricEnabled && _pin.isNotEmpty)
                            _PinPlainAction(
                              onPressed: _onDelete,
                              semanticLabel: 'Удалить цифру',
                              child: Icon(
                                Icons.backspace_outlined,
                                color: keypadForeground,
                                size: 27,
                                shadows: keypadShadows,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _PinPlainAction(
                        semanticLabel: localizations.translate('forgot_pin'),
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
                            fontFamily: 'SF Pro Display',
                            color: actionForeground,
                            fontWeight: FontWeight.w600,
                            shadows: actionShadows,
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

class _PinPlainAction extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final String semanticLabel;

  const _PinPlainAction({
    required this.onPressed,
    required this.child,
    required this.semanticLabel,
  });

  @override
  State<_PinPlainAction> createState() => _PinPlainActionState();
}

class _PinPlainActionState extends State<_PinPlainAction> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _isPressed ? 0.90 : 1,
            duration: const Duration(milliseconds: 140),
            curve: _isPressed ? Curves.easeOutCubic : Curves.easeOutBack,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 56,
                minHeight: 48,
              ),
              child: Center(child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
