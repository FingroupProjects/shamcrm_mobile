import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
// import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/biometric_service.dart';
import 'package:crm_task_manager/app_feature_flags.dart';
import 'package:crm_task_manager/core/theme/app_theme_controller.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/auth/forgot_pin.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/sip/sip_screen.dart';
import 'package:crm_task_manager/screens/sip/sip_service.dart';
import 'package:crm_task_manager/screens/sip/sip_state.dart';
import 'package:crm_task_manager/services/chat_unread_counter_service.dart';
import 'package:crm_task_manager/widgets/biometric_dialogs.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _showIntro = true;
  bool _didNavigateToSipCall = false;
  _PinAdaptivePalette? _adaptivePalette;
  String? _adaptivePaletteKey;

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
    final controller = AppThemeController.instance;
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paletteKey = [
      controller.backgroundPreset.storageKey,
      controller.backgroundImagePath ?? '',
      controller.backgroundAssetPath ?? '',
      controller.backgroundBlurPercent.toStringAsFixed(1),
      isDark,
      size.width.round(),
      size.height.round(),
    ].join('|');

    if (_adaptivePaletteKey == paletteKey) return;
    _adaptivePaletteKey = paletteKey;
    _adaptivePalette = _PinAdaptivePalette.fallback(
      isDark: isDark,
      backgroundLuminance:
          context.appColors.backgroundPrimary.computeLuminance(),
    );
    unawaited(
      _loadAdaptivePalette(
        paletteKey: paletteKey,
        controller: controller,
        screenSize: size,
      ),
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
    if (!kShowSip) return false;
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
        final hasAccess = await _checkAccountAccess();
        if (!hasAccess) return;

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

  void _navigateToSipCallOnly() {
    if (!kShowSip || !mounted) return;

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

  Future<void> _loadAdaptivePalette({
    required String paletteKey,
    required AppThemeController controller,
    required Size screenSize,
  }) async {
    if (controller.backgroundPreset != AppBackgroundPreset.custom) return;

    final imagePath = controller.backgroundImagePath;
    final assetPath = controller.backgroundAssetPath;
    if ((imagePath == null || imagePath.isEmpty) &&
        (assetPath == null || assetPath.isEmpty)) {
      return;
    }
    final themeLuminance =
        context.appColors.backgroundPrimary.computeLuminance();

    try {
      final bytes = imagePath != null && imagePath.isNotEmpty
          ? await File(imagePath).readAsBytes()
          : (await rootBundle.load(assetPath!)).buffer.asUint8List();
      final codec = await instantiateImageCodec(bytes, targetWidth: 120);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(format: ImageByteFormat.rawRgba);
      if (byteData == null) {
        image.dispose();
        codec.dispose();
        return;
      }

      final sample = _sampleBackgroundLuminance(
        bytes: byteData,
        imageWidth: image.width,
        imageHeight: image.height,
        screenSize: screenSize,
        fallbackLuminance: themeLuminance,
      );
      image.dispose();
      codec.dispose();

      if (!mounted || _adaptivePaletteKey != paletteKey) return;
      setState(() {
        _adaptivePalette = _PinAdaptivePalette(
          headerLuminance: sample.header,
          keypadLuminance: sample.keypad,
          bottomLuminance: sample.bottom,
        );
      });
    } catch (error) {
      debugPrint('PinScreen: adaptive background palette skipped: $error');
    }
  }

  _PinBackgroundLuminance _sampleBackgroundLuminance({
    required ByteData bytes,
    required int imageWidth,
    required int imageHeight,
    required Size screenSize,
    required double fallbackLuminance,
  }) {
    final imageAspect = imageWidth / imageHeight;
    final screenAspect = screenSize.width / screenSize.height;

    double cropLeft = 0;
    double cropTop = 0;
    double visibleWidth = imageWidth.toDouble();
    double visibleHeight = imageHeight.toDouble();

    if (imageAspect > screenAspect) {
      visibleWidth = imageHeight * screenAspect;
      cropLeft = (imageWidth - visibleWidth) / 2;
    } else {
      visibleHeight = imageWidth / screenAspect;
      cropTop = (imageHeight - visibleHeight) / 2;
    }

    double sampleRegion(double top, double bottom) {
      var luminanceTotal = 0.0;
      var sampleCount = 0;

      for (var yIndex = 0; yIndex < 8; yIndex++) {
        final screenY = top + (bottom - top) * ((yIndex + 0.5) / 8);
        final imageY = (cropTop + visibleHeight * screenY)
            .round()
            .clamp(0, imageHeight - 1);

        for (var xIndex = 0; xIndex < 8; xIndex++) {
          final screenX = 0.12 + 0.76 * ((xIndex + 0.5) / 8);
          final imageX = (cropLeft + visibleWidth * screenX)
              .round()
              .clamp(0, imageWidth - 1);
          final offset = (imageY * imageWidth + imageX) * 4;
          final red = bytes.getUint8(offset);
          final green = bytes.getUint8(offset + 1);
          final blue = bytes.getUint8(offset + 2);
          final alpha = bytes.getUint8(offset + 3) / 255;
          final pixelLuminance = _relativeLuminance(red, green, blue);
          luminanceTotal +=
              pixelLuminance * alpha + fallbackLuminance * (1 - alpha);
          sampleCount++;
        }
      }

      final sampled = luminanceTotal / sampleCount;
      return sampled * 0.88 + fallbackLuminance * 0.12;
    }

    return _PinBackgroundLuminance(
      header: sampleRegion(0.13, 0.37),
      keypad: sampleRegion(0.39, 0.82),
      bottom: sampleRegion(0.80, 0.96),
    );
  }

  double _relativeLuminance(int red, int green, int blue) {
    double linearize(int channel) {
      final value = channel / 255;
      return value <= 0.04045
          ? value / 12.92
          : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * linearize(red) +
        0.7152 * linearize(green) +
        0.0722 * linearize(blue);
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
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adaptivePalette = _adaptivePalette ??
        _PinAdaptivePalette.fallback(
          isDark: isDark,
          backgroundLuminance: colors.backgroundPrimary.computeLuminance(),
        );
    final pinForeground =
        adaptivePalette.foregroundFor(adaptivePalette.headerLuminance);
    final pinSecondary =
        adaptivePalette.secondaryFor(adaptivePalette.headerLuminance);
    final pinAccent =
        adaptivePalette.accentFor(adaptivePalette.headerLuminance);
    final keypadForeground =
        adaptivePalette.foregroundFor(adaptivePalette.keypadLuminance);
    final keypadAccent =
        adaptivePalette.accentFor(adaptivePalette.keypadLuminance);
    final actionForeground =
        adaptivePalette.foregroundFor(adaptivePalette.bottomLuminance);
    final keypadShadow =
        adaptivePalette.shadowFor(adaptivePalette.keypadLuminance);
    final actionShadow =
        adaptivePalette.shadowFor(adaptivePalette.bottomLuminance);
    final pinTextShadow =
        adaptivePalette.shadowFor(adaptivePalette.headerLuminance);
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
    final backgroundImagePath =
        isDark ? 'assets/images/night.png' : 'assets/images/day.png';

    if (localizations == null) {
      return Scaffold(
        backgroundColor: colors.backgroundPrimary,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const AppBackgroundOverlay(preset: AppBackgroundPreset.aurora),
            Center(
              child: SizedBox(
                width: 1,
                height: 1,
              ),
            ),
          ],
        ),
      );
    }

    if (_showIntro) {
      return Scaffold(
        backgroundColor: colors.backgroundPrimary,
        body: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _introController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _introScale.value,
                  child: child,
                );
              },
              child: Image.asset(
                backgroundImagePath,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 460),
                  padding: const EdgeInsets.fromLTRB(4, 20, 4, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 96,
                        height: 96,
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
                      const SizedBox(height: 20),
                      Text(
                        getGreetingMessage(),
                        style: textStyles.titleLg.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: pinForeground,
                          shadows: [pinTextShadow],
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
                          fontWeight: FontWeight.w600,
                          color: _isWrongPin ? pinErrorColor : pinSecondary,
                          shadows: [pinTextShadow],
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
                                        ? pinErrorColor
                                        : (index < _pin.length
                                            ? pinAccent
                                            : pinForeground.withValues(
                                                alpha: 0.24,
                                              )),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _isWrongPin
                                          ? pinErrorColor
                                          : pinForeground.withValues(
                                              alpha: 0.34,
                                            ),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(
                                          alpha: isDark ? 0.12 : 0.72,
                                        ),
                                        blurRadius: 6,
                                      ),
                                    ],
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
                        childAspectRatio: 1.14,
                        children: [
                          for (var i = 1; i <= 9; i++)
                            _LiquidPinKey(
                              digit: i.toString(),
                              letters: const [
                                '',
                                'ABC',
                                'DEF',
                                'GHI',
                                'JKL',
                                'MNO',
                                'PQRS',
                                'TUV',
                                'WXYZ',
                              ][i - 1],
                              onPressed: () => _onNumberPressed(i.toString()),
                              textColor: keypadForeground,
                              accentColor: keypadAccent,
                              isDark: keypadOnDarkBackground,
                            ),
                          _PinPlainAction(
                            onPressed: _onExitPressed,
                            semanticLabel: localizations.translate('exit'),
                            child: Text(
                              localizations.translate('exit'),
                              style: textStyles.bodyMd.copyWith(
                                fontSize: 16,
                                color: keypadForeground,
                                fontWeight: FontWeight.w800,
                                shadows: [keypadShadow],
                              ),
                            ),
                          ),
                          _LiquidPinKey(
                            digit: '0',
                            onPressed: () => _onNumberPressed('0'),
                            textColor: keypadForeground,
                            accentColor: keypadAccent,
                            isDark: keypadOnDarkBackground,
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
                                      shadows: [keypadShadow],
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
                                shadows: [keypadShadow],
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
                            color: actionForeground,
                            fontWeight: FontWeight.w700,
                            shadows: [actionShadow],
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

class _PinBackgroundLuminance {
  final double header;
  final double keypad;
  final double bottom;

  const _PinBackgroundLuminance({
    required this.header,
    required this.keypad,
    required this.bottom,
  });
}

class _PinAdaptivePalette {
  final double headerLuminance;
  final double keypadLuminance;
  final double bottomLuminance;

  const _PinAdaptivePalette({
    required this.headerLuminance,
    required this.keypadLuminance,
    required this.bottomLuminance,
  });

  factory _PinAdaptivePalette.fallback({
    required bool isDark,
    required double backgroundLuminance,
  }) {
    final luminance = backgroundLuminance.isFinite
        ? backgroundLuminance.clamp(0.0, 1.0)
        : (isDark ? 0.08 : 0.94);
    return _PinAdaptivePalette(
      headerLuminance: luminance,
      keypadLuminance: luminance,
      bottomLuminance: luminance,
    );
  }

  bool isDarkBackground(double luminance) => luminance < 0.34;

  Color foregroundFor(double luminance) {
    return isDarkBackground(luminance) ? Colors.white : const Color(0xFF073B55);
  }

  Color secondaryFor(double luminance) {
    return isDarkBackground(luminance)
        ? Colors.white.withValues(alpha: 0.84)
        : const Color(0xFF18556D);
  }

  Color accentFor(double luminance) {
    return isDarkBackground(luminance)
        ? const Color(0xFFC3F1FF)
        : const Color(0xFF00698F);
  }

  Shadow shadowFor(double luminance) {
    final onDark = isDarkBackground(luminance);
    return Shadow(
      color: onDark
          ? Colors.black.withValues(alpha: 0.56)
          : Colors.white.withValues(alpha: 0.94),
      blurRadius: onDark ? 9 : 6,
      offset: const Offset(0, 2),
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

class _LiquidPinKey extends StatefulWidget {
  final String digit;
  final String letters;
  final VoidCallback onPressed;
  final Color textColor;
  final Color accentColor;
  final bool isDark;

  const _LiquidPinKey({
    required this.digit,
    required this.onPressed,
    required this.textColor,
    required this.accentColor,
    required this.isDark,
    this.letters = '',
  });

  @override
  State<_LiquidPinKey> createState() => _LiquidPinKeyState();
}

class _LiquidPinKeyState extends State<_LiquidPinKey> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isDark
        ? Colors.white.withValues(alpha: _isPressed ? 0.68 : 0.38)
        : widget.accentColor.withValues(alpha: _isPressed ? 0.58 : 0.38);

    return Semantics(
      button: true,
      label: widget.digit,
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _isPressed ? 0.94 : 1,
            duration: const Duration(milliseconds: 140),
            curve: _isPressed ? Curves.easeOutCubic : Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (widget.isDark ? Colors.black : widget.accentColor)
                        .withValues(
                      alpha: _isPressed ? 0.10 : 0.22,
                    ),
                    blurRadius: _isPressed ? 9 : 22,
                    offset: Offset(0, _isPressed ? 3 : 10),
                  ),
                  BoxShadow(
                    color: widget.accentColor.withValues(
                      alpha: _isPressed ? 0.08 : 0.14,
                    ),
                    blurRadius: _isPressed ? 8 : 16,
                    spreadRadius: _isPressed ? 0 : 1,
                  ),
                ],
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _isPressed ? 11 : 18,
                    sigmaY: _isPressed ? 11 : 18,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 1.1),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.isDark
                            ? [
                                Colors.white.withValues(
                                  alpha: _isPressed ? 0.24 : 0.18,
                                ),
                                Colors.white.withValues(
                                  alpha: _isPressed ? 0.13 : 0.08,
                                ),
                                const Color(0xFF073B55).withValues(
                                  alpha: _isPressed ? 0.10 : 0.04,
                                ),
                              ]
                            : [
                                const Color(0xFFE5F7FF).withValues(
                                  alpha: _isPressed ? 0.94 : 0.82,
                                ),
                                const Color(0xFF8FD5EF).withValues(
                                  alpha: _isPressed ? 0.52 : 0.38,
                                ),
                                const Color(0xFF2788AF).withValues(
                                  alpha: _isPressed ? 0.24 : 0.15,
                                ),
                              ],
                        stops: const [0, 0.56, 1],
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: const Alignment(-0.46, -0.72),
                              radius: _isPressed ? 0.72 : 0.92,
                              colors: [
                                Colors.white.withValues(
                                  alpha: widget.isDark
                                      ? (_isPressed ? 0.18 : 0.30)
                                      : (_isPressed ? 0.34 : 0.52),
                                ),
                                Colors.white.withValues(alpha: 0),
                              ],
                              stops: const [0, 0.72],
                            ),
                          ),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            end: _isPressed ? 1 : 0,
                          ),
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          builder: (context, liquidProgress, child) {
                            return CustomPaint(
                              painter: _LiquidGlassRimPainter(
                                accentColor: widget.accentColor,
                                isDark: widget.isDark,
                                progress: liquidProgress,
                              ),
                            );
                          },
                        ),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: widget.letters.isEmpty ? 0 : 2,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.digit,
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 31,
                                    height: 0.94,
                                    fontWeight: FontWeight.w400,
                                    color: widget.textColor,
                                    shadows: [
                                      Shadow(
                                        color: widget.isDark
                                            ? Colors.black.withValues(
                                                alpha: 0.42,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.92,
                                              ),
                                        blurRadius: widget.isDark ? 7 : 5,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                if (widget.letters.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.letters,
                                    style: TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontSize: 9,
                                      height: 1,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.35,
                                      color: widget.textColor.withValues(
                                        alpha: 0.82,
                                      ),
                                      shadows: [
                                        Shadow(
                                          color: widget.isDark
                                              ? Colors.black.withValues(
                                                  alpha: 0.38,
                                                )
                                              : Colors.white.withValues(
                                                  alpha: 0.88,
                                                ),
                                          blurRadius: widget.isDark ? 5 : 3,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiquidGlassRimPainter extends CustomPainter {
  final Color accentColor;
  final bool isDark;
  final double progress;

  const _LiquidGlassRimPainter({
    required this.accentColor,
    required this.isDark,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerRect = Rect.fromCircle(
      center: center,
      radius: size.shortestSide / 2 - 1.4,
    );
    final innerRect = outerRect.deflate(3.2);

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.45
      ..shader = SweepGradient(
        transform: const GradientRotation(-math.pi / 2),
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.72 : 0.96),
          accentColor.withValues(alpha: isDark ? 0.22 : 0.46),
          Colors.white.withValues(alpha: 0.18),
          accentColor.withValues(alpha: isDark ? 0.38 : 0.58),
          Colors.white.withValues(alpha: isDark ? 0.72 : 0.96),
        ],
        stops: const [0, 0.24, 0.5, 0.76, 1],
      ).createShader(outerRect);
    canvas.drawOval(outerRect, rimPaint);

    final innerRimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withValues(alpha: isDark ? 0.13 : 0.38);
    canvas.drawOval(innerRect, innerRimPaint);

    final causticCenter = Offset(
      size.width * (0.28 + 0.24 * progress),
      size.height * (0.22 + 0.10 * progress),
    );
    final causticRadius = size.shortestSide * (0.30 + 0.04 * progress);
    final causticRect = Rect.fromCircle(
      center: causticCenter,
      radius: causticRadius,
    );
    final causticPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(
            alpha: isDark ? 0.16 : 0.34,
          ),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0, 1],
      ).createShader(causticRect);
    canvas.drawCircle(causticCenter, causticRadius, causticPaint);

    final topRefractionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: isDark ? 0.54 : 0.86);
    canvas.drawArc(
      innerRect,
      -2.72 + progress * 0.18,
      1.18,
      false,
      topRefractionPaint,
    );

    final bottomRefractionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round
      ..color = accentColor.withValues(alpha: isDark ? 0.20 : 0.34);
    canvas.drawArc(
      innerRect,
      0.32 - progress * 0.14,
      1.28,
      false,
      bottomRefractionPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassRimPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark;
  }
}
