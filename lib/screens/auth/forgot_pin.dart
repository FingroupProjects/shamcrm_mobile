import 'dart:async';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/auth/pin_setup_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/auth_bloc_pin/forgot_auth_bloc.dart';
import 'package:crm_task_manager/bloc/auth_bloc_pin/forgot_auth_event.dart';
import 'package:crm_task_manager/bloc/auth_bloc_pin/forgot_auth_state.dart';

// Утилита для маскировки email
String maskEmail(String email) {
  if (email.isEmpty) return '';
  
  final parts = email.split('@');
  if (parts.length != 2) return email;
  
  final username = parts[0];
  final domain = parts[1];
  
  if (username.length <= 2) {
    return '${username[0]}***@$domain';
  }
  
  final visibleStart = username.substring(0, 1);
  final visibleEnd = username.substring(username.length - 1);
  
  return '$visibleStart${'*' * (username.length - 2)}$visibleEnd@$domain';
}

// Первый экран - запрос логина
class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({Key? key}) : super(key: key);

  @override
  _ForgotPinScreenState createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final TextEditingController _loginController = TextEditingController();
  bool _isLoading = false;

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
            SizedBox(height: 8),
            Text(
              localizations.translate('forgot_pin_subtitle'),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Gilroy',
                height: 1.4,
              ),
            ),
            SizedBox(height: 24),
            CustomTextField(
              controller: _loginController,
              hintText: localizations.translate('enter_login'),
              label: localizations.translate('login_label'),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : () {
                  if (_loginController.text.isNotEmpty) {
                    setState(() => _isLoading = true);
                    
                    // Небольшая задержка для UX
                    Future.delayed(Duration(milliseconds: 300), () {
                      if (mounted) {
                        setState(() => _isLoading = false);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PinVerificationScreen(
                              login: _loginController.text,
                            ),
                          ),
                        );
                      }
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              localizations.translate('enter_login_error'),
                              style: TextStyle(fontFamily: 'Gilroy'),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.orange[700],
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 30, 46, 82),
                  foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                  side: BorderSide(color: Colors.black, width: 1),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(localizations.translate('request_confirmation')),
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
  String? _maskedEmail; // 👈 НОВОЕ ПОЛЕ для хранения замаскированного email

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BlocListener<ForgotPinBloc, ForgotPinState>(
            listener: (context, state) {
              if (state is ForgotPinSuccess) {
                setState(() {
                  _receivedPin = state.pin.toString();
                  _maskedEmail = maskEmail(state.email);
                });
              } else if (state is ForgotPinFailure) {
                // 👇 УЛУЧШЕННАЯ ОБРАБОТКА ОШИБОК
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.error.replaceAll('Exception: ', ''),
                            style: TextStyle(fontFamily: 'Gilroy'),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red[700],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                
                // 📧 Информационный блок с замаскированным email
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        color: Colors.blue[700],
                        size: 32,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.translate('check_email'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontFamily: 'Gilroy',
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              localizations.translate('code_sent_to_email'),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontFamily: 'Gilroy',
                              ),
                            ),
                            SizedBox(height: 6),
                            // 👇 Показываем замаскированный email
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue[300]!, width: 1),
                              ),
                              child: Text(
                                _maskedEmail ?? widget.login, // Fallback на логин
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[900],
                                  fontFamily: 'Gilroy',
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
      
                
                CustomTextField(
                  controller: _pinController,
                  hintText: localizations.translate('enter_confirmation_code'),
                  label: localizations.translate('confirmation_code_label'),
                  keyboardType: TextInputType.number,
                ),
                
                const SizedBox(height: 20),
                
                // Таймер или кнопка повторной отправки
                if (_isTimerActive)
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined, color: Colors.grey[600], size: 18),
                          SizedBox(width: 8),
                          Text(
                            '${localizations.translate('resend_available_in')} $_secondsRemaining ${localizations.translate('seconds')}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontFamily: 'Gilroy',
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                if (!_isTimerActive)
                  Center(
                    child: TextButton.icon(
                      onPressed: _requestPin,
                      icon: Icon(Icons.refresh, color: Color.fromARGB(255, 30, 46, 82)),
                      label: Text(
                        localizations.translate('did_not_receive_code'),
                        style: TextStyle(
                          color: Color.fromARGB(255, 30, 46, 82),
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Кнопка подтверждения
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_pinController.text == _receivedPin) {
                          _navigateToPinSetup();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.white),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      localizations.translate('wrong_confirmation_code'),
                                      style: TextStyle(fontFamily: 'Gilroy'),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 30, 46, 82),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Gilroy',
                          fontSize: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}