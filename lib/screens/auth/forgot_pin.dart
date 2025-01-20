import 'dart:async';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/auth/pin_setup_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
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
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localizations.translate('forgot_pin_title'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'Gilroy',
              ),
            ),
            SizedBox(height: 16),
            CustomTextField(
              controller: _loginController,
              hintText: localizations.translate('enter_login'),
              label: localizations.translate('login_label'),
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
                      SnackBar(
                        content: Text(localizations.translate('enter_login_error')),
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
                child: Text(localizations.translate('request_confirmation')),
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
    // Navigator.push(context, '/pin_setup'); 
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinSetupScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
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
              const SizedBox(height: 8),
              CustomTextField(
                controller: _pinController,
                hintText: localizations.translate('enter_confirmation_code'),
                label: localizations.translate('confirmation_code_label'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              if (_isTimerActive)
                 Center(
                  child: Text(
                    '${localizations.translate('resend_available_in')} $_secondsRemaining ${localizations.translate('seconds')}',
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
                    child:  Text(
                      localizations.translate('did_not_receive_code'),
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
                          content: Text(localizations.translate('wrong_confirmation_code')),
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
                  child: Text(
                    localizations.translate('confirm_code'),
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
