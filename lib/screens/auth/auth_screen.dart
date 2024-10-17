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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'CRM TASK MANAGER',
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
                listener: (context, state) {
                  if (state is DomainError) {
                    // Отображение сообщения об ошибке в виде SnackBar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  } else if (state is DomainLoaded) {
                    if (state.domainCheck.result) {
                      // Если домен действителен, перейдите на экран входа в систему.
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                      );
                    } else {
                      // Если домен недействителен, отобразить сообщение об ошибке
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
                    // Показать индикатор загрузки с измененным цветом
                    return CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xfff1E2E52),), // Укажите желаемый цвет
                    );
                  }
                  return CustomButton(
                    buttonText: 'Войти',
                    buttonColor: Color(0xfff4F40EC),
                    textColor: Colors.white,
                    onPressed: () {
                      final subdomain = subdomainController.text.trim();
                      if (subdomain.isNotEmpty) {
                        context.read<DomainBloc>().add(CheckDomain(subdomain));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Пожалуйста, введите поддомен')),
                        );
                      }
                    },
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}





// import 'package:crm_task_manager/custom_widget/custom_button.dart';
// import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
// import 'package:crm_task_manager/screens/auth/login_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../bloc/auth_domain/domain_bloc.dart';
// import '../../bloc/auth_domain/domain_event.dart';
// import '../../bloc/auth_domain/domain_state.dart';

// class AuthScreen extends StatelessWidget {
//   const AuthScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final TextEditingController subdomainController = TextEditingController();

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               const Text(
//                 'CRM TASK MANAGER',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 32,
//                   fontWeight: FontWeight.w600,
//                   fontFamily: 'Gilroy',
//                 ),
//               ),
//               SizedBox(height: 8),
//               const Text(
//                 'Введите ваш поддомен',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   fontFamily: 'Gilroy',
//                 ),
//               ),
//               SizedBox(height: 24),
//               CustomTextField(
//                 controller: subdomainController,
//                 hintText: 'Введите поддомен',
//                 label: 'Поддомен',
//               ),
//               SizedBox(height: 24),
//               BlocConsumer<DomainBloc, DomainState>(
//                 listener: (context, state) {
//                   if (state is DomainError) {
//                     // Отображение сообщения об ошибке в виде SnackBar
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text(state.message)),
//                     );
//                   } else if (state is DomainLoaded) {
//                     if (state.domainCheck.result) {
//                       // Если домен действителен, перейдите на экран входа в систему с эффектом свайпа
//                       Navigator.pushReplacement(
//                         context,
//                         PageRouteBuilder(
//                           pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
//                           transitionsBuilder: (context, animation, secondaryAnimation, child) {
//                             const begin = Offset(1.0, 0.0); // Начальная позиция (слева)
//                             const end = Offset.zero; // Конечная позиция (центр)
//                             const curve = Curves.easeInOut; // Кривая анимации

//                             var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
//                             var offsetAnimation = animation.drive(tween);

//                             return SlideTransition(
//                               position: offsetAnimation,
//                               child: child,
//                             );
//                           },
//                         ),
//                       );
//                     } else {
//                       // Если домен недействителен, отобразить сообщение об ошибке
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text(
//                               'Неверный поддомен: ${state.domainCheck.errors ?? "Unknown error"}'),
//                         ),
//                       );
//                     }
//                   }
//                 },
//                 builder: (context, state) {
//                   if (state is DomainLoading) {
//                     // Показать индикатор загрузки с измененным цветом
//                     return CircularProgressIndicator(
//                       valueColor: AlwaysStoppedAnimation<Color>(Color(0xfff4F40EC)), // Укажите желаемый цвет
//                     );
//                   }
//                   return CustomButton(
//                     buttonText: 'Войти',
//                     onPressed: () {
//                       final subdomain = subdomainController.text.trim();
//                       if (subdomain.isNotEmpty) {
//                         context.read<DomainBloc>().add(CheckDomain(subdomain));
//                       } else {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(content: Text('Пожалуйста, введите поддомен')),
//                         );
//                       }
//                     },
//                   );
//                 },
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }