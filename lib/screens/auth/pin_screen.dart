// lib/screens/auth/auth_screen.dart
import 'package:crm_task_manager/screens/auth/forgot_pin.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({Key? key}) : super(key: key);

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _isWrongPin = false;
  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  final LocalAuthentication _auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];

@override
void initState() {
  super.initState();
  _checkSavedPin();
  _initBiometrics();

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
}

Future<void> _initBiometrics() async {
  try {
    _canCheckBiometrics = await _auth.canCheckBiometrics;
    if (_canCheckBiometrics) {
      _availableBiometrics = await _auth.getAvailableBiometrics();
      if (_availableBiometrics.isNotEmpty) {
        // Автоматический вызов аутентификации
        // _authenticate();
      }
    }
  } on PlatformException catch (e) {
    debugPrint('Ошибка инициализации биометрии: $e');
  }
}

  Future<void> _checkSavedPin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('user_pin');
    if (savedPin == null) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/pin_setup');
      }
    }
  }

  Future<void> _authenticate() async {
    try {
      if (!_canCheckBiometrics || _availableBiometrics.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Биометрическая аутентификация недоступна'),
            ),
          );
        }
        return;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Подтвердите личность',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка биометрической аутентификации: ${e.message}'),
          ),
        );
      }
    }
  }

  void _onNumberPressed(String number) async {
    if (_pin.length < 4) {
      setState(() {
        _pin += number;
      });

      if (_pin.length == 4) {
        final prefs = await SharedPreferences.getInstance();
        final savedPin = prefs.getString('user_pin');
        if (_pin == savedPin) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        } else {
          _triggerErrorEffect();
        }
      }
    }
  }

  void _triggerErrorEffect() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }
    setState(() {
      _isWrongPin = true;
      _pin = '';
    });

    _animationController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
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
    SystemNavigator.pop(); // Closes the application
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Image.asset(
                'assets/icons/playstore.png',
                height: 160,
              ),
              const SizedBox(height: 16),
              const Text(
                'Добро пожаловать',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isWrongPin ? 'Неправильный пароль' : 'Введите ваш PIN-код',
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
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                childAspectRatio: 1.5,
                children: [
                  for (var i = 1; i <= 9; i++)
                    TextButton(
                      onPressed: () => _onNumberPressed(i.toString()),
                      child: Text(
                        i.toString(),
                        style:
                            const TextStyle(fontSize: 24, color: Colors.black),
                      ),
                    ),
                  TextButton(
                    onPressed: _onExitPressed,
                    child: const Text(
                      'Выйти',
                      style: TextStyle(
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
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ForgotPinScreen(),
                  ));
                },
                child: const Text(
                  'Забыли PIN-код?',
                  style: TextStyle(color: Color.fromARGB(255, 24, 65, 99)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
