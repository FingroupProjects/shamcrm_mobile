import 'dart:async';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/firebase_api.dart';
import 'package:crm_task_manager/bloc/auth_domain/domain_bloc.dart';
import 'package:crm_task_manager/bloc/history/history_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/login/login_bloc.dart';
import 'package:crm_task_manager/bloc/region/region_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:crm_task_manager/firebase_options.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart'; // Главный экран
import 'screens/chats/chats_screen.dart'; // Экран уведомлений

// Обработчик фоновых push-сообщений
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  print('Message data: ${message.data}');
  print('Received a message while in the foreground!');

  // Дополнительно выводим данные уведомления
  print('Notification title: ${message.notification?.title}');
  print('Notification body: ${message.notification?.body}');
}
  final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Firebase с конфигурацией для текущей платформы
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
// Получаем FCM-токен
  String? fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken != null) {
    print('FCM-токен: $fcmToken');

    // Отправляем FCM-токен на сервер
    ApiService apiService = ApiService();
    await apiService.sendDeviceToken(fcmToken);
  } else {
    print('Не удалось получить FCM-токен');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
    ),
  );

  // Инициализация Firebase API для push-уведомлений
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseApi firebaseApi = FirebaseApi();
  await firebaseApi.initNotifications();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => DomainBloc(ApiService())),
        BlocProvider(create: (context) => LoginBloc(ApiService())),
        BlocProvider(create: (context) => LeadBloc(ApiService())),
        BlocProvider(create: (context) => RegionBloc(ApiService())),
        BlocProvider(create: (context) => HistoryBloc(ApiService())), // Добавляем HistoryBloc
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CRM TASK MANAGER',
        routes: {
          '/': (context) => AuthScreen(),  // Экран для проверки домена
          '/login': (context) => LoginScreen(),  // Экран логина
          '/home': (context) => HomeScreen(),  // Главный экран после успешного входа
          '/notification_screen': (context) => ChatsScreen(), // Экран уведомлений
        },
      ),
    );
  }
}
