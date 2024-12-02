import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/auth_bloc_pin/forgot_auth_bloc.dart';
import 'package:crm_task_manager/bloc/auth_bloc_pin/forgot_auth_event.dart';
import 'package:crm_task_manager/bloc/auth_bloc_pin/forgot_auth_state.dart';

// Первый экран - запрос логина
class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({Key? key}) : super(key: key);

  @override
  _ForgotPinScreenState createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final TextEditingController _loginController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Забыли пароль?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'Gilroy',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _loginController,
              style: const TextStyle(
                color: Color.fromARGB(255, 0, 0, 0),
                fontFamily: 'Gilroy',
              ),
              decoration: InputDecoration(
                labelText: 'Введите ваш логин',
                labelStyle: const TextStyle(
                  color: Colors.grey,
                  fontFamily: 'Gilroy',
                ),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (_loginController.text.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PinVerificationScreen(
                          login: _loginController.text,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Введите логин'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 30, 46, 82),
                  foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                  side: BorderSide(color: Colors.black, width: 1),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Gilroy',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Запросить подтверждение'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Второй экран - проверка PIN
class PinVerificationScreen extends StatefulWidget {
  final String login;

  const PinVerificationScreen({Key? key, required this.login})
      : super(key: key);

  @override
  _PinVerificationScreenState createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  final TextEditingController _pinController = TextEditingController();
  ForgotPinBloc? _forgotPinBloc;
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _isTimerActive = false;
  String? _receivedPin;

  @override
  void initState() {
    super.initState();
    _forgotPinBloc = BlocProvider.of<ForgotPinBloc>(context);
    _requestPin();
  }

  void _requestPin() {
    _forgotPinBloc!.add(RequestForgotPin(
      login: widget.login,
      password: '',
    ));
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _isTimerActive = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isTimerActive = false;
        });
      }
    });
  }

  void _navigateToPinSetup() {
    Navigator.pushNamed(context, '/pin_setup');
  }

  @override
  void dispose() {
    _pinController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocListener<ForgotPinBloc, ForgotPinState>(
          listener: (context, state) {
            if (state is ForgotPinSuccess) {
              setState(() {
                _receivedPin = state.pin.toString();
              });
            } else if (state is ForgotPinFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error)),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Введите код подтверждение',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 0, 0, 0),
                  fontFamily: 'Gilroy',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                style: const TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontFamily: 'Gilroy',
                ),
                decoration: InputDecoration(
                  labelText: 'Введите код подтверждение',
                  labelStyle: const TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontFamily: 'Gilroy',
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (_isTimerActive)
                Center(
                  child: Text(
                    'Повторный запрос доступен через $_secondsRemaining секунд',
                    style: const TextStyle(
                      color: Colors.black,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ),
              if (!_isTimerActive)
                Center(
                  child: ElevatedButton(
                    onPressed: _requestPin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 30, 46, 82),
                      textStyle: const TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                    child: const Text(
                      'Не получили код подтверждение?',
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontFamily: 'Gilroy',
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_pinController.text == _receivedPin) {
                      _navigateToPinSetup();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Неверный код подтверждение!'),
                          backgroundColor: Colors.red, // Красный фон
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 30, 46, 82),
                    textStyle: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                  child: const Text(
                    'Подтвердить код подтверждение',
                    style: TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
