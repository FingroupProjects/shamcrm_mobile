import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/lead%20chart/chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/lead%20chart/chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/project_chart/task_chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/stats_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/stats_event.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/screens/dashboard/deal_stats.dart';
import 'package:crm_task_manager/screens/dashboard/deals_box.dart';
import 'package:crm_task_manager/screens/dashboard/project_chart.dart';
import 'package:crm_task_manager/screens/dashboard/task_chart.dart';
import 'package:crm_task_manager/screens/dashboard/lead_conversion.dart';
import 'package:crm_task_manager/screens/dashboard/graphic_dashboard.dart';
import 'package:crm_task_manager/screens/dashboard/leads_box.dart';
import 'package:crm_task_manager/screens/dashboard/tasks_dart.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isClickAvatarIcon = false;
  bool areBoxesLoaded = false; // Состояние для загрузки основных коробок

  @override
  void initState() {
    super.initState();
    // Загрузка данных конверсии лидов
    context.read<DashboardConversionBloc>().add(LoadLeadConversionData());
    _loadImportantBoxes();
  }

  // Метод для имитации загрузки важных коробок
  Future<void> _loadImportantBoxes() async {
    await Future.delayed(Duration(seconds: 2)); // Имитация загрузки
    setState(() {
      areBoxesLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DashboardStatsBloc(
            context.read<ApiService>(),
          )..add(LoadDashboardStats()),
        ),
        BlocProvider(
          create: (context) => DashboardChartBloc(
            context.read<ApiService>(),
          )..add(LoadLeadChartData()),
        ),
        BlocProvider(
          create: (context) => DashboardConversionBloc(
            context.read<ApiService>(),
          )..add(LoadLeadConversionData()),
        ),
        BlocProvider(
          create: (context) => DealStatsBloc(
            context.read<ApiService>(),
          )..add(LoadDealStatsData()),
        ),
        BlocProvider(
          create: (context) => ProjectChartBloc(
            context.read<ApiService>(),
          ),
          child: const ProjectChartTable(),
        )
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: CustomAppBar(
            title: "Дашборд",
            onClickProfileAvatar: () {
              setState(() {
                isClickAvatarIcon = !isClickAvatarIcon;
              });
            },
            onChangedSearchInput: (input) {},
            textEditingController: TextEditingController(),
            focusNode: FocusNode(),
            clearButtonClick: (isSearching) {},
            showSearchIcon: false,
          ),
        ),
        body: isClickAvatarIcon
            ? ProfileScreen()
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Важные коробки
                    LeadsBox(),
                    SizedBox(height: 16),
                    TasksBox(),
                    SizedBox(height: 16),
                    DealsBox(),
                    SizedBox(height: 16),
                    
                    // Остальная часть интерфейса загружается только после отображения важных коробок
                    if (areBoxesLoaded) ...[
                  GraphicsDashboard(),
                    SizedBox(height: 16),
                      LeadConversionChart(),
                      SizedBox(height: 16),
                      DealStatsChart(),
                      SizedBox(height: 16),
                      TaskChartWidget(),
                      SizedBox(height: 16),
                      ProjectChartTable(),
                    ] else ...[
                      Center(
                        child: CircularProgressIndicator(),
                      ),
                    ]
                  ],
                ),
              ),
      ),
    );
  }

  // Метод для стилизованных раскрывающихся карточек
  Widget _buildExpansionTile({required String title, required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: const Color.fromARGB(255, 244, 247, 254),
      elevation: 4,
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        iconColor: Color(0xFF2D3748),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ],
      ),
    );
  }
}

/*import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/lead%20chart/chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/lead%20chart/chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/project_chart/task_chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/stats_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/stats_event.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/models/user.dart';
import 'package:crm_task_manager/screens/dashboard/deal_stats.dart';
import 'package:crm_task_manager/screens/dashboard/deals_box.dart';
import 'package:crm_task_manager/screens/dashboard/project_chart.dart';
import 'package:crm_task_manager/screens/dashboard/task_chart.dart';
import 'package:crm_task_manager/screens/dashboard/lead_conversion.dart';
import 'package:crm_task_manager/screens/dashboard/graphic_dashboard.dart';
import 'package:crm_task_manager/screens/dashboard/leads_box.dart';
import 'package:crm_task_manager/screens/dashboard/tasks_dart.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardScreen extends StatefulWidget {
    final User user; 
    const DashboardScreen({Key? key, required this.user}) : super(key: key);
    

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isClickAvatarIcon = false;
  bool areBoxesLoaded = false; // State for loading main boxes

  @override
  void initState() {
    super.initState();
    // Load lead conversion data
    context.read<DashboardConversionBloc>().add(LoadLeadConversionData());
    _loadImportantBoxes();
  }

  // Method to simulate loading of important boxes
  Future<void> _loadImportantBoxes() async {
    await Future.delayed(Duration(seconds: 2)); // Simulate loading
    setState(() {
      areBoxesLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
      // Проверка роли пользователя
    bool isUserRole = widget.user.role?.name == 'user'; // Поменяйте, если в вашей модели другая структура
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DashboardStatsBloc(
            context.read<ApiService>(),
          )..add(LoadDashboardStats()),
        ),
        BlocProvider(
          create: (context) => DashboardChartBloc(
            context.read<ApiService>(),
          )..add(LoadLeadChartData()),
        ),
        BlocProvider(
          create: (context) => DashboardConversionBloc(
            context.read<ApiService>(),
          )..add(LoadLeadConversionData()),
        ),
        BlocProvider(
          create: (context) => DealStatsBloc(
            context.read<ApiService>(),
          )..add(LoadDealStatsData()),
        ),
        BlocProvider(
          create: (context) => ProjectChartBloc(
            context.read<ApiService>(),
          ),
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: CustomAppBar(
            title: "Дашборд",
            onClickProfileAvatar: () {
              setState(() {
                isClickAvatarIcon = !isClickAvatarIcon;
              });
            },
            onChangedSearchInput: (input) {},
            textEditingController: TextEditingController(),
            focusNode: FocusNode(),
            clearButtonClick: (isSearching) {},
            showSearchIcon: false,
          ),
        ),
       body: isClickAvatarIcon
            ? ProfileScreen()
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Важные коробки
                    if (!isUserRole) ...[
                      LeadsBox(),
                      SizedBox(height: 16),
                      TasksBox(),
                      SizedBox(height: 16),
                      DealsBox(),
                      SizedBox(height: 16),
                    ],
                    // Загружаемые элементы только если роль не "user"
                    if (!isUserRole && areBoxesLoaded) ...[
                      GraphicsDashboard(),
                      SizedBox(height: 16),
                      LeadConversionChart(),
                      SizedBox(height: 16),
                      DealStatsChart(),
                      SizedBox(height: 16),
                      ProjectChartTable(),
                    ] else if (isUserRole) ...[
                      // Отображаем только TaskChartWidget, если роль "user"
                      TaskChartWidget(),
                    ] else ...[
                      Center(
                        child: CircularProgressIndicator(),
                      ),
                    ]
                  ],
                ),
              ),
      ),
    );
  }

  // Method to build styled expandable cards with access control
  Widget _buildExpansionTile({required String title, required Widget child, required List<String> roles}) {
    bool hasAccess = _checkUserRoleAccess(roles);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: const Color.fromARGB(255, 244, 247, 254),
      elevation: 4,
      child: hasAccess ? ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        iconColor: Color(0xFF2D3748),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ],
      ) : Container(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Access Denied',
          style: TextStyle(
            color: Colors.red,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  bool _checkUserRoleAccess(List<String> roles) {
    // Implement role-checking logic here
    String currentUserRole = 'user'; // Replace with actual logic for current user role retrieval

    return roles.contains(currentUserRole);
  }
}
*/