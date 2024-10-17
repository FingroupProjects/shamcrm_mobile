import 'package:crm_task_manager/screens/MyNavBar.dart';
import 'package:crm_task_manager/screens/chats/chats_screen.dart';
import 'package:crm_task_manager/screens/clients/clients_screen.dart';
import 'package:crm_task_manager/screens/dashboard/dashboard_screen.dart';
import 'package:crm_task_manager/screens/deal/deal_screen.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart'; // Импортируйте экран профиля
import 'package:crm_task_manager/screens/lead/lead_screen.dart';
import 'package:flutter/material.dart';

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
    ChatsScreen(),
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
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (_selectedIndex == 5) // Если экран профиля
              IconButton(
                icon: Image.asset('assets/icons/arrow-left.png', width: 24, height: 24),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 0; // Возвращаемся на главный экран
                  });
                },
              ),
            Container(
              width: 40,
              height: 40,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Image.asset('assets/images/avatar.png'),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 5; // Установите индекс для профиля
                  });
                },
              ),
            ),
            SizedBox(width: 8),
            Text(
              _titles[_selectedIndex],
              style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600),
            ),
            Spacer(),
            Row(
              children: [
                IconButton(
                  icon: Image.asset(
                    'assets/icons/AppBar/notification.png',
                    width: 24,
                    height: 24,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Image.asset(
                    'assets/icons/AppBar/search.png',
                    width: 24,
                    height: 24,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
      ),
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
