import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth_domain/domain_bloc.dart';
import '../../bloc/auth_domain/domain_event.dart';
import '../../bloc/auth_domain/domain_state.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController subdomainController = TextEditingController();

    return FutureBuilder(
      future: context.read<ApiService>().isDomainChecked(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: Color(0xff1E2E52)));
        }

        if (snapshot.data == true) {
          // Если домен уже проверен, переходим на экран логина
          Future.microtask(() => Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => LoginScreen())));
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Ваш UI для ввода поддомена
                  const Text(
                    'SHAMCRM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                  SizedBox(height: 8),
                  const Text(
                    'Введите ваш поддомен',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                  SizedBox(height: 24),
                  CustomTextField(
                    controller: subdomainController,
                    hintText: 'Введите поддомен',
                    label: 'Поддомен',
                  ),
                  SizedBox(height: 24),
                  BlocConsumer<DomainBloc, DomainState>(
                    listener: (context, state) async {
                      if (state is DomainError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.message)),
                        );
                      } else if (state is DomainLoaded) {
                        if (state.domainCheck.result) {
                          // Если домен действителен, сохраняем его статус и переходим на экран входа
                          await context
                              .read<ApiService>()
                              .saveDomainChecked(true);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => LoginScreen()),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Неверный поддомен: ${state.domainCheck.errors ?? "Ошибка"}')),
                          );
                        }
                      }
                    },
                    builder: (context, state) {
                      if (state is DomainLoading) {
                        return CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xfff1E2E52)),
                        );
                      }
                      return CustomButton(
                        buttonText: 'Войти',
                        buttonColor: Color(0xfff4F40EC),
                        textColor: Colors.white,
                        onPressed: () {
                          final subdomain = subdomainController.text.trim();
                          if (subdomain.isNotEmpty) {
                            context
                                .read<DomainBloc>()
                                .add(CheckDomain(subdomain));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Пожалуйста, введите поддомен')),
                            );
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
 }
// // lib/screens/auth/auth_screen.dart
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:vibration/vibration.dart';
// import 'package:local_auth/local_auth.dart';
// import 'package:flutter/services.dart';

// class AuthScreen extends StatefulWidget {
//   const AuthScreen({Key? key}) : super(key: key);

//   @override
//   State<AuthScreen> createState() => _AuthScreenState();
// }

// class _AuthScreenState extends State<AuthScreen>
//     with SingleTickerProviderStateMixin {
//   String _pin = '';
//   bool _isWrongPin = false;
//   late AnimationController _animationController;
//   late Animation<double> _shakeAnimation;
//   final LocalAuthentication _auth = LocalAuthentication();
//   bool _canCheckBiometrics = false;
//   List<BiometricType> _availableBiometrics = [];

//   @override
//   void initState() {
//     super.initState();
//     _checkSavedPin();
//     _initBiometrics();

//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 500),
//       vsync: this,
//     );

//     _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.elasticIn),
//     );

//     _animationController.addStatusListener((status) {
//       if (status == AnimationStatus.completed) {
//         _animationController.reset();
//       }
//     });
//   }

//   Future<void> _initBiometrics() async {
//     try {
//       _canCheckBiometrics = await _auth.canCheckBiometrics;
//       if (_canCheckBiometrics) {
//         _availableBiometrics = await _auth.getAvailableBiometrics();
//       }
//     } on PlatformException catch (e) {
//       debugPrint('Ошибка инициализации биометрии: $e');
//     }
//   }

//   Future<void> _checkSavedPin() async {
//     final prefs = await SharedPreferences.getInstance();
//     final savedPin = prefs.getString('user_pin');
//     if (savedPin == null) {
//       if (mounted) {
//         Navigator.of(context).pushReplacementNamed('/pin_setup');
//       }
//     }
//   }

//   Future<void> _authenticate() async {
//     try {
//       if (!_canCheckBiometrics || _availableBiometrics.isEmpty) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Биометрическая аутентификация недоступна'),
//             ),
//           );
//         }
//         return;
//       }

//       final bool didAuthenticate = await _auth.authenticate(
//         localizedReason: 'Подтвердите личность с помощью отпечатка пальца',
//         options: const AuthenticationOptions(
//           biometricOnly: true,
//           useErrorDialogs: true,
//           stickyAuth: true,
//         ),
//       );

//       if (didAuthenticate && mounted) {
//         Navigator.of(context).pushReplacementNamed('/home');
//       }
//     } on PlatformException catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Ошибка биометрической аутентификации: ${e.message}'),
//           ),
//         );
//       }
//     }
//   }

//   void _onNumberPressed(String number) async {
//     if (_pin.length < 4) {
//       setState(() {
//         _pin += number;
//       });

//       if (_pin.length == 4) {
//         final prefs = await SharedPreferences.getInstance();
//         final savedPin = prefs.getString('user_pin');
//         if (_pin == savedPin) {
//           if (mounted) {
//             Navigator.of(context).pushReplacementNamed('/home');
//           }
//         } else {
//           _triggerErrorEffect();
//         }
//       }
//     }
//   }

//   void _triggerErrorEffect() async {
//     if (await Vibration.hasVibrator() ?? false) {
//       Vibration.vibrate(duration: 100);
//     }
//     setState(() {
//       _isWrongPin = true;
//       _pin = '';
//     });

//     _animationController.forward();

//     await Future.delayed(const Duration(milliseconds: 500));
//     if (mounted) {
//       setState(() {
//         _isWrongPin = false;
//       });
//     }
//   }

//   void _onDelete() {
//     if (_pin.isNotEmpty) {
//       setState(() {
//         _pin = _pin.substring(0, _pin.length - 1);
//         _isWrongPin = false;
//       });
//     }
//   }

//  void _onExitPressed() {
//   SystemNavigator.pop(); // Closes the application
// }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 36.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const SizedBox(height: 40),
//               Image.asset(
//                 'assets/icons/playstore.png',
//                 height: 160,
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 'Добро пожаловать',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 _isWrongPin ? 'Неправильный пароль' : 'Введите ваш PIN-код',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: _isWrongPin ? Colors.red : Colors.grey,
//                 ),
//               ),
//               const SizedBox(height: 24),
//               AnimatedBuilder(
//                 animation: _shakeAnimation,
//                 builder: (context, child) {
//                   return Transform.translate(
//                     offset: Offset(_isWrongPin ? _shakeAnimation.value : 0, 0),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: List.generate(
//                         4,
//                         (index) => Container(
//                           margin: const EdgeInsets.symmetric(horizontal: 8.0),
//                           width: 12,
//                           height: 12,
//                           decoration: BoxDecoration(
//                             color: _isWrongPin
//                                 ? Colors.red
//                                 : (index < _pin.length
//                                     ? const Color.fromARGB(255, 33, 41, 188)
//                                     : Colors.grey.shade300),
//                             shape: BoxShape.circle,
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//               const SizedBox(height: 24),
//               GridView.count(
//                 crossAxisCount: 3,
//                 shrinkWrap: true,
//                 childAspectRatio: 1.5,
//                 children: [
//                   for (var i = 1; i <= 9; i++)
//                     TextButton(
//                       onPressed: () => _onNumberPressed(i.toString()),
//                       child: Text(
//                         i.toString(),
//                         style: const TextStyle(fontSize: 24, color: Colors.black),
//                       ),
//                     ),
//                   TextButton(
//                     onPressed: _onExitPressed,
//                     child: const Text(
//                       'Выйти',
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Color.fromARGB(255, 33, 41, 188),
//                       ),
//                     ),
//                   ),
//                   TextButton(
//                     onPressed: () => _onNumberPressed('0'),
//                     child: const Text(
//                       '0',
//                       style: TextStyle(fontSize: 24, color: Colors.black),
//                     ),
//                   ),
//                   TextButton(
//                     onPressed: _pin.isEmpty ? _authenticate : _onDelete,
//                     child: Icon(
//                       _pin.isEmpty
//                           ? Icons.fingerprint
//                           : Icons.backspace_outlined,
//                       color: const Color.fromARGB(255, 33, 41, 188),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 24),
//               TextButton(
//                 onPressed: () {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Забыли PIN-код?')),
//                   );
//                 },
//                 child: const Text(
//                   'Забыли PIN-код?',
//                   style: TextStyle(color: Color.fromARGB(255, 24, 65, 99)),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }