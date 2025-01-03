// lib/screens/auth/auth_screen.dart
import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/permission/permession_bloc.dart';
import 'package:crm_task_manager/bloc/permission/permession_event.dart';
import 'package:crm_task_manager/models/user_byId_model..dart';
import 'package:crm_task_manager/screens/auth/forgot_pin.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
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
  bool _isIosVersionAbove15 = false;
  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  final LocalAuthentication _auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];
  String _userName = '';
  String _userNameProfile = '';
  String _userImage = '';
  int? userRoleId ;

  @override
  void initState() {
    super.initState();
  _loadUserRoleId().then((_) {
    // После загрузки разрешений продолжаем остальные операции
    _checkSavedPin();
    _initBiometrics();
    _loadUserPhone();
  });

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



  Future<void> _checkSavedPin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('user_pin');
    if (savedPin == null) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/pin_setup');
      }
    }
  }

  void _onNumberPressed(String number) async {
    if (_pin.length < 4) {
      setState(() {
        _pin += number;
      });
      // Вибрация при каждом нажатии на кнопку
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 50); // Вибрация длиной 50 миллисекунд
      }
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
      Vibration.vibrate(duration: 200);
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String getGreetingMessage() {
    final hour = DateTime.now().hour;
    final greetingPrefix;

    if (hour >= 5 && hour < 11) {
      greetingPrefix = 'Доброе утро';
    } else if (hour >= 11 && hour < 18) {
      greetingPrefix = 'Добрый день';
    } else if (hour >= 18 && hour < 22) {
      greetingPrefix = 'Добрый вечер';
    } else {
      greetingPrefix = 'Доброй ночи';
    }
    print(
        '-----------------------------------------------------------------------------');
    print(
        '-------------------------------------------------UESRNAMFPROIEFIEJFSOPFSJ----------------------------');
    print(_userNameProfile);
    return '$greetingPrefix, $_userNameProfile!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          // В виджете используйте _userImage для отображения
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.2,
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
      Future<void> _loadUserRoleId() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userID') ?? '';
    if (userId.isEmpty) {
      setState(() {
        userRoleId = 0;
      });
      return;
    }

    // Получение ИД РОЛЯ через API
    UserByIdProfile userProfile = await ApiService().getUserById(int.parse(userId));
    setState(() {
      userRoleId = userProfile.role!.first.id;
    });
    // Выводим данные в консоль
    context.read<PermissionsBloc>().add(FetchPermissionsEvent(userRoleId.toString()));

  } catch (e) {
    print('Error loading user role!');
    setState(() {
      userRoleId = 0;
    });
  }
}

  // Метод для загрузки данных пользователя из SharedPreferences
 void _loadUserPhone() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Получаем данные из SharedPreferences
  String? savedUserName = prefs.getString('userName');
  String? savedUserNameProfile = prefs.getString('userNameProfile');
  String? savedUserImage = prefs.getString('userImage');

  // Если данные есть в SharedPreferences, проверяем их с данными с сервера
  if (savedUserName != null && savedUserNameProfile != null && savedUserImage != null) {
    // Попробуем получить данные с сервера
    try {
      UserByIdProfile userProfile = await ApiService().getUserById(int.parse(savedUserName)); // Предположим, что userName это ID
      if (userProfile.name == savedUserName) {
        // Если name из сервера совпадает с name из SharedPreferences, используем данные с сервера
        setState(() {
          _userName = userProfile.name;
          _userNameProfile = savedUserNameProfile; // Используем имя профиля из SharedPreferences
          _userImage = savedUserImage; // Используем изображение из SharedPreferences
        });
      } else {
        // Если данные не совпадают, берем данные с сервера
        setState(() {
          _userName = userProfile.name;
          _userNameProfile = userProfile.lastname ?? ''; // Обновляем профиль на основе данных с сервера
          _userImage = userProfile.image ?? ''; // Используем изображение с сервера
        });

        // Обновляем SharedPreferences данными с сервера
        await prefs.setString('userName', userProfile.name);
        await prefs.setString('userNameProfile', userProfile.name ?? '');
        await prefs.setString('userImage', userProfile.image ?? '');
      }
    } catch (e) {
      print('Ошибка при загрузке данных с сервера!');
      // Если произошла ошибка при запросе с сервера, выводим сохраненные данные
      setState(() {
        _userName = savedUserName;
        _userNameProfile = savedUserNameProfile;
        _userImage = savedUserImage;
      });
    }
  } else {
    // Если данных нет в SharedPreferences, загружаем их с сервера
    try {
      UserByIdProfile userProfile = await ApiService().getUserById(1); // Предположим, что это какой-то ID
      setState(() {
        _userName = userProfile.name;
        _userNameProfile = userProfile.name ?? '';
        _userImage = userProfile.image ?? '';
      });

      // Сохраняем данные в SharedPreferences
      await prefs.setString('userName', userProfile.name);
      await prefs.setString('userNameProfile', userProfile.name ?? '');
      await prefs.setString('userImage', userProfile.image ?? '');
    } catch (e) {
      print('Ошибка при загрузке данных с сервера!');
      // Обрабатываем ошибку, если данные не удалось загрузить с сервера
      setState(() {
        _userName = 'Не найдено';
        _userNameProfile = 'Не найдено';
        _userImage = '';
      });
    }
  }
}


  Future<void> _initBiometrics() async {
    try {
      _canCheckBiometrics = await _auth.canCheckBiometrics;

      if (_canCheckBiometrics) {
        _availableBiometrics = await _auth.getAvailableBiometrics();
        if (_availableBiometrics.isNotEmpty) {
          if (Platform.isIOS &&
              _availableBiometrics.contains(BiometricType.face)) {
            _authenticate();
          } else if (Platform.isAndroid &&
              _availableBiometrics.contains(BiometricType.strong)) {
            _authenticate();
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Биометрическая аутентификация недоступна'),
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      debugPrint('Ошибка инициализации биометрии!');
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
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Ошибка биометрической аутентификации: ${e.message}'),
        //   ),
        // );
      }
    }
  }
}
