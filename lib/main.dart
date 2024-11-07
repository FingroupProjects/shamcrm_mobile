import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/auth_domain/domain_bloc.dart';
import 'package:crm_task_manager/bloc/currency/currency_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/history/history_bloc.dart';
import 'package:crm_task_manager/bloc/history_task/task_history_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/login/login_bloc.dart';
import 'package:crm_task_manager/bloc/manager/manager_bloc.dart';
import 'package:crm_task_manager/bloc/notes/notes_bloc.dart';
import 'package:crm_task_manager/bloc/project/project_bloc.dart';
import 'package:crm_task_manager/bloc/region/region_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = ApiService();
  final bool isDomainChecked = await apiService.isDomainChecked();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
    ),
  );

  runApp(MyApp(apiService: apiService, isDomainChecked: isDomainChecked));
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
        
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CRM TASK MANAGER',
        routes: {
          '/': (context) => isDomainChecked ? LoginScreen() : AuthScreen(),
          '/login': (context) => LoginScreen(),
          '/home': (context) => HomeScreen(),
        },
      ),
    );
  }
}
