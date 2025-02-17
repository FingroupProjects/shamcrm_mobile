import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/firebase_api.dart';
import 'package:crm_task_manager/api/service/secure_storage_service.dart';
import 'package:crm_task_manager/bloc/My-Task_Status_Name/statusName_bloc.dart';
import 'package:crm_task_manager/bloc/Task_Status_Name/statusName_bloc.dart';
import 'package:crm_task_manager/bloc/auth_bloc_pin/forgot_auth_bloc.dart';
import 'package:crm_task_manager/bloc/auth_domain/domain_bloc.dart';
import 'package:crm_task_manager/bloc/author/get_all_author_bloc.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_task_bloc.dart';
import 'package:crm_task_manager/bloc/chats/delete_message/delete_message_bloc.dart';
import 'package:crm_task_manager/bloc/chats/groupe_chat/group_chat_bloc.dart';
import 'package:crm_task_manager/bloc/contact_person/contact_person_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/user_task/user_task_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/process_speed/ProcessSpeed_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/conversion/conversion_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/dealStats/dealStats_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/lead_chart/chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/process_speed/ProcessSpeed_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/task_chart/task_chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/user_task/user_task_bloc.dart';
import 'package:crm_task_manager/bloc/data_1c/data_1c_bloc.dart';
import 'package:crm_task_manager/bloc/deal_task/deal_task_bloc.dart';
import 'package:crm_task_manager/bloc/event/event_bloc.dart';
import 'package:crm_task_manager/bloc/eventByID/event_byId_bloc.dart';
import 'package:crm_task_manager/bloc/history_lead_notice_deal/history_lead_notice_deal_bloc.dart';
import 'package:crm_task_manager/bloc/history_my-task/task_history_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead_multi_list/lead_multi_bloc.dart';
import 'package:crm_task_manager/bloc/lead_navigate_to_chat/lead_navigate_to_chat_bloc.dart';
import 'package:crm_task_manager/bloc/lead_to_1c/lead_to_1c_bloc.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_bloc.dart';
import 'package:crm_task_manager/bloc/chats/chats_bloc.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_file_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_text_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_voice_cubit.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/lead_chart/chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/task_chart/task_chart_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal_by_id/dealById_bloc.dart';
import 'package:crm_task_manager/bloc/history_deal/deal_history_bloc.dart';
import 'package:crm_task_manager/bloc/history_lead/history_bloc.dart';
import 'package:crm_task_manager/bloc/history_task/task_history_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_bloc.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_bloc.dart';
import 'package:crm_task_manager/bloc/login/login_bloc.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_bloc.dart';
import 'package:crm_task_manager/bloc/my-task_by_id/taskById_bloc.dart';
import 'package:crm_task_manager/bloc/my-task_status_add/task_bloc.dart';
import 'package:crm_task_manager/bloc/notes/notes_bloc.dart';
import 'package:crm_task_manager/bloc/notice_subject_list/notice_subject_list_bloc.dart';
import 'package:crm_task_manager/bloc/notifications/notifications_bloc.dart';
import 'package:crm_task_manager/bloc/organization/organization_bloc.dart';
import 'package:crm_task_manager/bloc/permission/permession_bloc.dart';
import 'package:crm_task_manager/bloc/profile/profile_bloc.dart';
import 'package:crm_task_manager/bloc/project/project_bloc.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_bloc.dart';
import 'package:crm_task_manager/bloc/region_list/region_bloc.dart';
import 'package:crm_task_manager/bloc/role/role_bloc.dart';
import 'package:crm_task_manager/bloc/source_lead/source_lead_bloc.dart';
import 'package:crm_task_manager/bloc/source_list/source_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task_add_from_deal/task_add_from_deal_bloc.dart';
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
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/languages/local_manager_lang.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async { 
  WidgetsFlutterBinding.ensureInitialized(); 
  await AppTrackingTransparency.requestTrackingAuthorization();
  final apiService = ApiService();
  final authService = AuthService();
  final bool isDomainChecked = await apiService.isDomainChecked();
  if (isDomainChecked) {
    await apiService.initialize();
  }
  final String? token = await apiService.getToken();
  final String? pin = await authService.getPin();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,  
  );
  await FirebaseMessaging.instance.requestPermission();
  await getFCMTokens(apiService);

  FirebaseApi firebaseApi = FirebaseApi();
  await firebaseApi.initNotifications();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
    ),
  );

  final String? savedLanguageCode = await LanguageManager.getLanguage();
  final Locale savedLocale = savedLanguageCode != null ? Locale(savedLanguageCode) : const Locale('ru');

 final prefs = await SharedPreferences.getInstance();
  final bool openedViaNotification = prefs.getBool('openedViaNotification') ?? false;

  runApp(MyApp(
    apiService: apiService,
    authService: authService,
    isDomainChecked: isDomainChecked,
    token: token,
    pin: pin,
    initialLocale: savedLocale,
    openedViaNotification: openedViaNotification, 
  ));
}
Future<void> getFCMTokens(ApiService apiService) async {}

class MyApp extends StatefulWidget {
  final ApiService apiService;
  final AuthService authService;
  final bool isDomainChecked;
  final String? token;
  final String? pin;
  final Locale initialLocale; 
  final bool openedViaNotification; 

  const MyApp({
    required this.apiService,
    required this.authService,
    required this.isDomainChecked,
    this.token,
    this.pin,
    required this.initialLocale, 
    required this.openedViaNotification, 
  });

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale; 
  }

  void setLocale(Locale newLocale) {
    setState(() {
      _locale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
          Provider<ApiService>.value(value: widget.apiService),
          Provider<AuthService>.value(value: widget.authService),
          BlocProvider(create: (context) => DomainBloc(widget.apiService)),
          BlocProvider(create: (context) => LoginBloc(widget.apiService)),
          BlocProvider(create: (context) => LeadBloc(widget.apiService)),
          BlocProvider(create: (context) => HistoryBloc(widget.apiService)),
          BlocProvider(create: (context) => NotesBloc(widget.apiService)),
          BlocProvider(create: (context) => GetAllManagerBloc()),
          BlocProvider(create: (context) => GetAllRegionBloc()),
          BlocProvider(create: (context) => GetAllSourceBloc()),
          BlocProvider(create: (context) => GetAllLeadBloc()),
          BlocProvider(create: (context) => GetAllRegionBloc()),
          BlocProvider(create: (context) => GetAllLeadMultiBloc()),
          BlocProvider(create: (context) => DealBloc(widget.apiService)),
          BlocProvider(create: (context) => TaskBloc(widget.apiService)),
          BlocProvider(create: (context) => MyTaskBloc(widget.apiService)),
          BlocProvider(create: (context) => GetTaskProjectBloc()),
          BlocProvider(create: (context) => GetAllProjectBloc()),
          BlocProvider(create: (context) => UserTaskBloc(widget.apiService)),
          BlocProvider(create: (context) => HistoryBlocTask(widget.apiService)),
          BlocProvider(create: (context) => HistoryLeadsBloc(widget.apiService)),
          BlocProvider(create: (context) => HistoryBlocMyTask(widget.apiService)),
          BlocProvider(create: (context) => RoleBloc(widget.apiService)),
          BlocProvider(create: (context) => TaskStatusNameBloc(widget.apiService)),
          BlocProvider(create: (context) => MyTaskMyStatusNameBloc(widget.apiService)),
          BlocProvider(create: (context) => LeadByIdBloc(widget.apiService)),
          BlocProvider(create: (context) => DealByIdBloc(widget.apiService)),
          BlocProvider(create: (context) => TaskByIdBloc(widget.apiService)),
          BlocProvider(create: (context) => MyTaskByIdBloc(widget.apiService)),
          BlocProvider(create: (context) => DealHistoryBloc(widget.apiService)),
          BlocProvider(create: (context) => GetAllClientBloc(apiService: widget.apiService)),
          BlocProvider(create: (context) => GetAllAuthorBloc(apiService: widget.apiService)),
          BlocProvider(create: (context) => CreateClientBloc()),
          BlocProvider(create: (context) => GroupChatBloc(widget.apiService)),
          BlocProvider(create: (context) => DeleteMessageBloc(ApiService())),
          BlocProvider(create: (context) => ListenSenderTextCubit()),
          BlocProvider(create: (context) => ListenSenderVoiceCubit()),
          BlocProvider(create: (context) => ListenSenderFileCubit()),
          BlocProvider(create: (context) => ChatsBloc(ApiService()),),
          BlocProvider(create: (context) => TaskStatusBloc(ApiService())),
          BlocProvider(create: (context) => MyTaskStatusBloc(ApiService())),
          BlocProvider(create: (context) => OrganizationBloc(ApiService())),
          BlocProvider(create: (context) => NotificationBloc(ApiService())),
          BlocProvider(create: (context) => ChatsBloc(ApiService()),),
          BlocProvider(create: (context) => TaskStatusBloc(ApiService())),
          BlocProvider(create: (context) => DashboardChartBloc(ApiService())),
          BlocProvider(create: (context) => DashboardChartBlocManager(ApiService())),
          BlocProvider(create: (context) => DashboardConversionBloc(ApiService())),
          BlocProvider(create: (context) => DashboardConversionBlocManager(ApiService())),
          BlocProvider(create: (context) => UserBlocManager(ApiService())),
          BlocProvider(create: (context) => DealStatsBloc(ApiService())),
          BlocProvider(create: (context) => DealStatsManagerBloc(ApiService())),
          BlocProvider(create: (context) => DashboardTaskChartBloc(ApiService())),
          BlocProvider(create: (context) => DashboardTaskChartBlocManager(ApiService())),
          BlocProvider(create: (context) => LeadDealsBloc(ApiService())),
          BlocProvider(create: (context) => DealTasksBloc(ApiService())),
          BlocProvider(create: (context) => ProcessSpeedBlocManager(ApiService())),
          BlocProvider(create: (context) => ContactPersonBloc(ApiService())),
          BlocProvider(create: (context) => LeadToChatBloc(widget.apiService)),
          BlocProvider(create: (context) => ChatProfileBloc(ApiService())),
          BlocProvider(create: (context) => TaskProfileBloc(ApiService())),
          BlocProvider(create: (context) => PermissionsBloc(ApiService())),
          BlocProvider(create: (context) => ForgotPinBloc(apiService: ApiService())),
          BlocProvider(create: (context) => SourceLeadBloc(widget.apiService)),
          BlocProvider(create: (context) => LeadToCBloc(apiService: widget.apiService)),
          BlocProvider(create: (context) => Data1CBloc(apiService: widget.apiService)),
          BlocProvider(create: (context) => ProfileBloc(apiService: widget.apiService)),
          BlocProvider(create: (context) => ProcessSpeedBloc(widget.apiService)),
          BlocProvider(create: (context) => TaskCompletionBloc(widget.apiService)),
          BlocProvider(create: (context) => TaskAddFromDealBloc(apiService: ApiService())),
          BlocProvider(create: (context) => EventBloc(widget.apiService)),
          BlocProvider(create: (context) => NoticeBloc(widget.apiService)),
          BlocProvider(create: (context) => GetAllSubjectBloc()),
          ],
      child: MaterialApp(
        locale: _locale ?? const Locale('ru'), 
        color: Colors.white,
        debugShowCheckedModeBanner: false,
        title: 'shamCRM',
        navigatorKey: navigatorKey,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
        ),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          const Locale('ru', ''),
          const Locale('en', ''),
          const Locale('uz', ''),
        ],
        localeResolutionCallback: (locale, supportedLocales) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale?.languageCode) {
              return supportedLocale;
            }
          }
          return supportedLocales.first;
        },
        home: Builder(
          builder: (context) {
            if (widget.token == null) {
              return AuthScreen();
            } else if (widget.pin == null) {
              return PinSetupScreen();
    } else if (widget.openedViaNotification) {
      // Ожидаем, пока завершится pop
      Future.microtask(() async {
        await Future.delayed(Duration(milliseconds: 100), () async {
           WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context); // Ждем, пока выполнится pop
          }
        });
        });
      });
      return Container(color: Colors.white,); 
            } else {
              return PinScreen();
            }
          },
        ),
        routes: {
          '/local_auth': (context) => AuthScreen(),
          '/login': (context) => LoginScreen(),
          '/home': (context) => HomeScreen(),
          '/chats': (context) => ChatsScreen(),
          '/pin_setup': (context) => PinSetupScreen(),
          '/pin_screen': (context) => PinScreen(),
        },
      ),
    );
  }
}