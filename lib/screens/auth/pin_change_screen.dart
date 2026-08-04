import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/widgets/adaptive_pin_layout.dart';
import 'package:crm_task_manager/widgets/liquid_pin_key.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class PinChangeScreen extends StatefulWidget {
  const PinChangeScreen({Key? key}) : super(key: key);

  @override
  State<PinChangeScreen> createState() => _PinChangeScreenState();
}

class _PinChangeScreenState extends State<PinChangeScreen>
    with SingleTickerProviderStateMixin {
  // Текущий шаг: 0 = ввод старого PIN, 1 = ввод нового, 2 = подтверждение
  int _currentStep = 0;

  String _oldPin = '';
  String _newPin = '';
  String _confirmPin = '';

  bool _isError = false;
  bool _isPinChecking = false;

  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_animationController);

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reset();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // ЛОГИКА ВВОДА
  // ==========================================================================

  void _onNumberPressed(String number) async {
    if (_isPinChecking) return;

    String currentPin = _getCurrentPinInput();

    if (currentPin.length < 4) {
      setState(() {
        _setCurrentPinInput(currentPin + number);
        _isError = false;
      });

      // Вибрация
      try {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 50);
        }
      } catch (e) {}

      // Проверка после 4-й цифры
      if (_getCurrentPinInput().length == 4) {
        setState(() => _isPinChecking = true);
        try {
          await _handlePinComplete();
        } finally {
          if (mounted) {
            setState(() => _isPinChecking = false);
          }
        }
      }
    }
  }

  void _onDelete() {
    if (_isPinChecking) return;

    String currentPin = _getCurrentPinInput();
    if (currentPin.isNotEmpty) {
      setState(() {
        _setCurrentPinInput(currentPin.substring(0, currentPin.length - 1));
        _isError = false;
      });
    }
  }

  void _onClear() {
    if (_isPinChecking) return;

    setState(() {
      _oldPin = '';
      _newPin = '';
      _confirmPin = '';
      _currentStep = 0;
      _isError = false;
    });
  }

  // ==========================================================================
  // ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
  // ==========================================================================

  String _getCurrentPinInput() {
    switch (_currentStep) {
      case 0:
        return _oldPin;
      case 1:
        return _newPin;
      case 2:
        return _confirmPin;
      default:
        return '';
    }
  }

  void _setCurrentPinInput(String value) {
    switch (_currentStep) {
      case 0:
        _oldPin = value;
        break;
      case 1:
        _newPin = value;
        break;
      case 2:
        _confirmPin = value;
        break;
    }
  }

  // ==========================================================================
  // ПРОВЕРКА И ПЕРЕХОД МЕЖДУ ШАГАМИ
  // ==========================================================================

  Future<void> _handlePinComplete() async {
    if (_currentStep == 0) {
      // Проверяем старый PIN
      final prefs = await SharedPreferences.getInstance();
      final savedPin = prefs.getString('user_pin');

      if (_oldPin == savedPin) {
        // Правильный старый PIN → переходим к вводу нового
        setState(() {
          _currentStep = 1;
          _isError = false;
        });
      } else {
        // Неправильный старый PIN
        _triggerErrorEffect();
      }
    } else if (_currentStep == 1) {
      // Ввели новый PIN → переходим к подтверждению
      setState(() {
        _currentStep = 2;
      });
    } else if (_currentStep == 2) {
      // Проверяем совпадение нового PIN
      if (_newPin == _confirmPin) {
        await _savePinAndGoBack();
      } else {
        _triggerErrorEffect();
      }
    }
  }

  void _triggerErrorEffect() async {
    // Вибрация ошибки
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 200);
      }
    } catch (e) {}

    setState(() {
      _isError = true;
      _isPinChecking = false;
      // Очищаем текущий ввод
      if (_currentStep == 0) {
        _oldPin = '';
      } else if (_currentStep == 2) {
        _confirmPin = '';
      }
    });

    _animationController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isError = false;
      });
    }
  }

  Future<void> _savePinAndGoBack() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_pin', _newPin);

    if (mounted) {
      // Показываем сообщение об успехе
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.translate('pin_changed_successfully') ??
                'PIN успешно изменён',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Возвращаемся назад через небольшую задержку
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  // ==========================================================================
  // UI - ЗАГОЛОВКИ
  // ==========================================================================

  String _getTitle() {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return '';

    switch (_currentStep) {
      case 0:
        return localizations.translate('enter_current_pin') ??
            'Введите текущий PIN';
      case 1:
        return localizations.translate('enter_new_pin') ?? 'Введите новый PIN';
      case 2:
        return localizations.translate('confirm_new_pin') ??
            'Подтвердите новый PIN';
      default:
        return '';
    }
  }

  String _getErrorMessage() {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return '';

    switch (_currentStep) {
      case 0:
        return localizations.translate('wrong_current_pin') ??
            'Неверный текущий PIN';
      case 2:
        return localizations.translate('pins_do_not_match') ??
            'PIN-коды не совпадают';
      default:
        return '';
    }
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
    final foreground = isDark ? Colors.white : colors.textPrimary;
    final secondary =
        isDark ? Colors.white.withValues(alpha: 0.76) : colors.textSecondary;
    final pinLogo = Image.asset(
      'assets/icons/playstore.png',
      fit: BoxFit.contain,
    );

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppBackgroundOverlay(preset: AppBackgroundPreset.aurora),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.chevron_left_rounded, color: foreground),
                      tooltip: localizations?.translate('back') ?? 'Назад',
                    ),
                  ),
                  AdaptivePinContent(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 460),
                      padding: const EdgeInsets.fromLTRB(4, 20, 4, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Иконка
                          Transform.translate(
                            offset: const Offset(0, 6),
                            child: SizedBox(
                              width: 150,
                              height: 150,
                              child: isDark
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

                          // Заголовок
                          Text(
                            _isError ? _getErrorMessage() : _getTitle(),
                            style: textStyles.titleLg.copyWith(
                              fontFamily: 'SF Pro Display',
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: _isError ? Colors.red : foreground,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            localizations?.translate('change_pin_code') ??
                                'Изменить PIN',
                            style: textStyles.bodyMd.copyWith(
                              fontFamily: 'SF Pro Display',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _isError ? Colors.red : secondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // PIN индикаторы с анимацией
                          AnimatedBuilder(
                            animation: _shakeAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(
                                    _isError ? _shakeAnimation.value : 0, 0),
                                child: _buildPinRow(_getCurrentPinInput()),
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Клавиатура
                          AdaptivePinKeypad(
                            children: [
                              for (var i = 1; i <= 9; i++)
                                _buildNumberButton(i.toString()),

                              const SizedBox(), // Пустая ячейка

                              _buildNumberButton('0'),

                              _buildDeleteButton(),
                            ],
                          ),

                          const SizedBox(height: 4),

                          // Кнопка "Очистить"
                          TextButton(
                            onPressed: _onClear,
                            child: Text(
                              localizations?.translate('clear') ?? 'Очистить',
                              style: textStyles.labelLg.copyWith(
                                fontFamily: 'SF Pro Display',
                                color: foreground,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ
  // ==========================================================================

  Widget _buildPinRow(String pin) {
    return PinProgressDots(
      filledCount: pin.length,
      isLoading: _isPinChecking,
      isError: _isError,
      activeColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : context.appColors.buttonPrimaryBg,
      inactiveColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.28)
          : context.appColors.borderSubtle.withValues(alpha: 0.48),
      errorColor: Colors.red,
      size: 12,
      spacing: 8,
    );
  }

  Widget _buildNumberButton(String number) {
    return LiquidPinKey(
      digit: number,
      onPressed: () => _onNumberPressed(number),
      textColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : context.appColors.textPrimary,
      isDarkBackground: Theme.of(context).brightness == Brightness.dark,
    );
  }

  Widget _buildDeleteButton() {
    return TextButton(
      onPressed: _onDelete,
      child: Icon(
        Icons.backspace_outlined,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : context.appColors.textPrimary,
        size: 28,
      ),
    );
  }
}
