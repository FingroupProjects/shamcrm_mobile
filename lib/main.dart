import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/auth_domain/domain_bloc.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_file_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_text_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_voice_cubit.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/login/login_bloc.dart';
import 'package:crm_task_manager/bloc/user/client/get_all_client_bloc.dart';
import 'package:crm_task_manager/bloc/user/create_cleant/create_client_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart'; // Главный экран

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // // Обязательно инициализируем Flutter binding, чтобы плагин мог корректно работать
  // WidgetsFlutterBinding.ensureInitialized();

  // // // Пример инициализации плеера (опционально, если требуется инициализация заранее)
  // final AudioPlayer audioPlayer = AudioPlayer();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DomainBloc(ApiService()),
        ),
        BlocProvider(
          create: (context) => LoginBloc(ApiService()), // Добавьте LoginBloc
        ),
        BlocProvider(
          create: (context) => LeadBloc(ApiService()), // Добавьте LeadBloc
        ),
        BlocProvider(
          create: (context) => GetAllClientBloc(),
        ),
        BlocProvider(
          create: (context) => CreateClientBloc(),
        ),
        BlocProvider(
          create: (context) => DealBloc(ApiService()),
        ),

         BlocProvider(
          create: (context) => ListenSenderTextCubit(),
        ),

         BlocProvider(
          create: (context) => ListenSenderVoiceCubit(),
        ),
         BlocProvider(
          create: (context) => ListenSenderFileCubit(),
        ),

      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CRM TASK MANAGER',
        routes: {
          '/': (context) => AuthScreen(), // Экран для проверки домена
          '/login': (context) => LoginScreen(), // Экран логина
          '/home': (context) =>
              HomeScreen(), // Главный экран после успешного входа
        },
      ),
    );
  }
}
