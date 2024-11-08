import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/chats/chats_bloc.dart';
import 'package:crm_task_manager/screens/MyNavBar.dart';
import 'package:crm_task_manager/screens/chats/chats_screen.dart';
import 'package:crm_task_manager/screens/clients/clients_screen.dart';
import 'package:crm_task_manager/screens/dashboard/dashboard_screen.dart';
import 'package:crm_task_manager/screens/deal/deal_screen.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart'; // Импортируйте экран профиля
import 'package:crm_task_manager/screens/lead/lead_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Добавьте экран профиля в список виджетов
  final List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    ClientsScreen(),
    LeadScreen(),
    BlocProvider(
      create: (context) => ChatsBloc(ApiService()),
      child: ChatsScreen(),
    ),
    DealScreen(),
    ProfileScreen(), // Добавьте экран профиля
  ];

  final List<String> _titles = [
    'Дашборд',
    'Задачи',
    'Лиды',
    'Чаты',
    'Сделки',
    'Профиль', // Заголовок для экрана профиля
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   forceMaterialTransparency: true,
      //   title: CustomAppBar(title: 'title', onClickProfileAvatar: () {
      //
      //   },),
      //   backgroundColor: Colors.white,
      // ),
      body: _widgetOptions[
          _selectedIndex], // Теперь отображаем профиль вместе с другими экранами
      backgroundColor: Colors.white,
      bottomNavigationBar: _selectedIndex == 5
          ? null // Отключаем нижнюю навигацию на экране профиля
          : MyNavBar(
              selectedIndex: _selectedIndex, // Передаем текущий индекс
              onItemSelected: (index) {
                setState(() {
                  _selectedIndex =
                      index; // Обновляем индекс при выборе навигации
                });
              },
            ),
    );
  }
}
