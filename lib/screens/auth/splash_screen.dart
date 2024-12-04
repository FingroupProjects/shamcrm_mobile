// import 'package:crm_task_manager/bloc/auth_bloc_pin/auth_bloc.dart';
// import 'package:crm_task_manager/bloc/auth_bloc_pin/auth_state.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// class SplashScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<AuthBloc, AuthState>(
//       listener: (context, state) {
//         if (state is AuthPinRequired) {
//           Navigator.pushReplacementNamed(context, '/setup-pin');
//         } else if (state is AuthAuthenticated) {
//           Navigator.pushReplacementNamed(context, '/home');
//         }
//       },
//       child: const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       ),
//     );
//   }
// }
