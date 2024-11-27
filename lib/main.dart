import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/firebase_api.dart';
import 'package:crm_task_manager/api/service/secure_storage_service.dart';
import 'package:crm_task_manager/bloc/Task_Status_Name/statusName_bloc.dart';
import 'package:crm_task_manager/bloc/auth_domain/domain_bloc.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_bloc.dart';
import 'package:crm_task_manager/bloc/chats/chats_bloc.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_file_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_text_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_voice_cubit.dart';
import 'package:crm_task_manager/bloc/currency/currency_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/lead%20chart/chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/project_chart/task_chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/task_chart/task_chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/stats_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal_by_id/dealById_bloc.dart';
import 'package:crm_task_manager/bloc/history_deal/deal_history_bloc.dart';
import 'package:crm_task_manager/bloc/history_lead/history_bloc.dart';
import 'package:crm_task_manager/bloc/history_task/task_history_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_bloc.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_bloc.dart';
import 'package:crm_task_manager/bloc/login/login_bloc.dart';
import 'package:crm_task_manager/bloc/manager/manager_bloc.dart';
import 'package:crm_task_manager/bloc/notes/notes_bloc.dart';
import 'package:crm_task_manager/bloc/notifications/notifications_bloc.dart';
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
import 'package:crm_task_manager/screens/auth/pin_screen.dart';
import 'package:crm_task_manager/screens/chats/chats_screen.dart';
import 'package:crm_task_manager/screens/auth/pin_setup_screen.dart';
import 'package:crm_task_manager/screens/auth/auth_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = ApiService();
  final authService = AuthService();
  final bool isDomainChecked = await apiService.isDomainChecked();
  final String? token = await apiService.getToken();
  final String? pin = await authService.getPin();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseMessaging.instance.requestPermission();

  await getFCMTokens(apiService);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
    ),
  );

  FirebaseApi firebaseApi = FirebaseApi();
  await firebaseApi.initNotifications();

  runApp(MyApp(
    apiService: apiService,
    authService: authService,
    isDomainChecked: isDomainChecked,
    token: token,
    pin: pin,
  ));
}

Future<void> getFCMTokens(ApiService apiService) async {
  // Функция оставлена пустой, как в оригинальном коде
}

class MyApp extends StatelessWidget {
  final ApiService apiService;
  final AuthService authService;
  final bool isDomainChecked;
  final String? token;
  final String? pin;

  const MyApp({
    required this.apiService,
    required this.authService,
    required this.isDomainChecked,
    this.token,
    this.pin,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<AuthService>.value(value: authService),
        BlocProvider(create: (context) => DomainBloc(apiService)),
        BlocProvider(create: (context) => LoginBloc(apiService)),
        BlocProvider(create: (context) => LeadBloc(apiService)),
        BlocProvider(create: (context) => HistoryBloc(apiService)),
        BlocProvider(create: (context) => NotesBloc(apiService)),
        BlocProvider(create: (context) => ManagerBloc(apiService)),
        BlocProvider(create: (context) => RegionBloc(apiService)),
        BlocProvider(create: (context) => DealBloc(apiService)),
        BlocProvider(create: (context) => CurrencyBloc(apiService)),
        BlocProvider(create: (context) => TaskBloc(apiService)),
        BlocProvider(create: (context) => ProjectBloc(apiService)),
        BlocProvider(create: (context) => UserTaskBloc(apiService)),
        BlocProvider(create: (context) => HistoryBlocTask(apiService)),
        BlocProvider(create: (context) => RoleBloc(apiService)),
        BlocProvider(create: (context) => TaskStatusNameBloc(apiService)),
        BlocProvider(create: (context) => LeadByIdBloc(apiService)),
        BlocProvider(create: (context) => DealByIdBloc(apiService)),
        BlocProvider(create: (context) => TaskByIdBloc(apiService)),
        BlocProvider(create: (context) => DealHistoryBloc(apiService)),
        BlocProvider(create: (context) => GetAllClientBloc()),
        BlocProvider(create: (context) => CreateClientBloc()),
        BlocProvider(create: (context) => ListenSenderTextCubit()),
        BlocProvider(create: (context) => ListenSenderVoiceCubit()),
        BlocProvider(create: (context) => ListenSenderFileCubit()),
        BlocProvider(create: (context) => ChatsBloc(ApiService())),
        BlocProvider(create: (context) => TaskStatusBloc(ApiService())),
        BlocProvider(create: (context) => OrganizationBloc(ApiService())),
        BlocProvider(create: (context) => NotificationBloc(ApiService())),
        BlocProvider(create: (context) => DashboardChartBloc(ApiService())),
        BlocProvider(
            create: (context) => DashboardConversionBloc(ApiService())),
        BlocProvider(create: (context) => DashboardStatsBloc(ApiService())),
        BlocProvider(create: (context) => DealStatsBloc(ApiService())),
        BlocProvider(create: (context) => DashboardTaskChartBloc(ApiService())),
        BlocProvider(create: (context) => ProjectChartBloc(ApiService())),
        BlocProvider(create: (context) => LeadDealsBloc(ApiService())),
        BlocProvider(create: (context) => ChatProfileBloc(ApiService())),
      ],
      child: MaterialApp(
        
        color: Colors.white,
        debugShowCheckedModeBanner: false,
        title: 'SHAMCRM',
        navigatorKey: navigatorKey,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: Builder(
          builder: (context) {
            if (token == null) {
              return isDomainChecked ? LoginScreen() : AuthScreen();
            } else if (pin == null) {
              return PinSetupScreen();
            } else {
              return PinScreen(); // Для последующих входов
            }
          },
        ),
        routes: {
          '/login': (context) => LoginScreen(),
          '/home': (context) => HomeScreen(),
          '/chats': (context) => ChatsScreen(),
          '/pin_setup': (context) => PinSetupScreen(),
          '/local_auth': (context) => const AuthScreen(),
        },
      ),
    );
  }
}
