import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/firebase_api.dart';
import 'package:crm_task_manager/bloc/Task_Status_Name/statusName_bloc.dart';
import 'package:crm_task_manager/bloc/auth_domain/domain_bloc.dart';
import 'package:crm_task_manager/bloc/chats/chats_bloc.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_file_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_text_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_voice_cubit.dart';
import 'package:crm_task_manager/bloc/currency/currency_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/dashboard_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal_by_id/dealById_bloc.dart';
import 'package:crm_task_manager/bloc/history_deal/deal_history_bloc.dart';
import 'package:crm_task_manager/bloc/history_lead/history_bloc.dart';
import 'package:crm_task_manager/bloc/history_task/task_history_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_bloc.dart';
import 'package:crm_task_manager/bloc/login/login_bloc.dart';
import 'package:crm_task_manager/bloc/manager/manager_bloc.dart';
import 'package:crm_task_manager/bloc/notes/notes_bloc.dart';
import 'package:crm_task_manager/bloc/organization/organization_bloc.dart';
import 'package:crm_task_manager/bloc/project/project_bloc.dart';
import 'package:crm_task_manager/bloc/region/region_bloc.dart';
import 'package:crm_task_manager/bloc/role/role_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task_by_id/taskById_bloc.dart';
import 'package:crm_task_manager/bloc/task_status_add/task_bloc.dart';
import 'package:crm_task_manager/bloc/user/client/get_all_client_bloc.dart';
import 'package:crm_task_manager/bloc/user/create_cleant/create_client_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_bloc.dart';
import 'package:crm_task_manager/firebase_options.dart';
import 'package:crm_task_manager/screens/chats/chats_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = ApiService();
  final bool isDomainChecked = await apiService.isDomainChecked();

  // Инициализация Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Запрос разрешений на уведомления
  await FirebaseMessaging.instance.requestPermission();

  // Получаем токены (APNS и FCM)
  await getFCMTokens(apiService);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
    ),
  );

  // Инициализация уведомлений
  FirebaseApi firebaseApi = FirebaseApi();
  await firebaseApi.initNotifications();
  

  runApp(MyApp(apiService: apiService, isDomainChecked: isDomainChecked));
}

Future<void> getFCMTokens(ApiService apiService) async {
  // try {
  //   // Получаем APNS токен
  //   String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
  //   if (apnsToken != null) {
  //     print('APNS Token: $apnsToken');
  //   } else {
  //     print('Не удалось получить APNS токен');
  //   }
}

class MyApp extends StatelessWidget {
  final ApiService apiService;
  final bool isDomainChecked;

  const MyApp({required this.apiService, required this.isDomainChecked});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        BlocProvider(
          create: (context) => DomainBloc(apiService),
        ),
        BlocProvider(
          create: (context) => LoginBloc(apiService),
        ),
        BlocProvider(
          create: (context) => LeadBloc(apiService),
        ),
        BlocProvider(
          create: (context) => HistoryBloc(apiService),
        ),
        BlocProvider(
          create: (context) => NotesBloc(apiService),
        ),
        BlocProvider(
          create: (context) => ManagerBloc(apiService),
        ),
        BlocProvider(
          create: (context) => RegionBloc(apiService),
        ),
        BlocProvider(
          create: (context) => DealBloc(apiService),
        ),
        BlocProvider(
          create: (context) => CurrencyBloc(apiService),
        ),
        BlocProvider(
          create: (context) => TaskBloc(apiService),
        ),
        BlocProvider(
          create: (context) => ProjectBloc(apiService),
        ),
        BlocProvider(
          create: (context) => UserTaskBloc(apiService),
        ),
        BlocProvider(
          create: (context) => HistoryBlocTask(apiService),
        ),
        BlocProvider(
          create: (context) => DashboardBloc(apiService),
        ),
        BlocProvider(
          create: (context) => RoleBloc(apiService),
        ),
        BlocProvider(
          create: (context) => TaskStatusNameBloc(apiService),
        ),
        BlocProvider(
          create: (context) => LeadByIdBloc(apiService),
        ),
        BlocProvider(
          create: (context) => DealByIdBloc(apiService),
        ),
        BlocProvider(
          create: (context) => TaskByIdBloc(apiService),
        ),
        BlocProvider(
          create: (context) => DealHistoryBloc(apiService),
        ),
        BlocProvider(
          create: (context) => GetAllClientBloc(),
        ),
        BlocProvider(
          create: (context) => CreateClientBloc(),
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
        BlocProvider(
          create: (context) => ChatsBloc(ApiService()),
        ),
        BlocProvider(
          create: (context) => TaskStatusBloc(ApiService()),
        ),
        BlocProvider(
          create: (context) => OrganizationBloc(ApiService()),
        ),
        
      ],
      child: MaterialApp(
        color: Colors.white,
        debugShowCheckedModeBanner: false,
        title: 'CRM TASK MANAGER',
        navigatorKey: navigatorKey, // Навигационный ключ
        routes: {
          '/': (context) => isDomainChecked ? LoginScreen() : AuthScreen(),
          '/login': (context) => LoginScreen(),
          '/home': (context) => HomeScreen(),
          '/chats': (context) => ChatsScreen(),
        },
      ),
    );
  }
}
