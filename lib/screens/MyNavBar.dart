import 'package:crm_task_manager/widgets/bottom_navy_bar.dart';
import 'package:flutter/material.dart';

class MyNavBar extends StatefulWidget {
  final Function(int) onItemSelected;

  MyNavBar({required this.onItemSelected, required int selectedIndex});

  @override
  _MyNavBarState createState() => _MyNavBarState();
}

class _MyNavBarState extends State<MyNavBar> {
  int currentIndex = 0;
  static const double _iconSize = 24;

  final TextStyle _titleStyle = const TextStyle(
    color: Colors.white,
    fontFamily: 'Golos',
    fontWeight: FontWeight.w500,
    fontSize: 14,
  );

  BottomNavyBarItem _buildNavBarItem(
      int index, String title, String activeIconPath, String inactiveIconPath) {
    return BottomNavyBarItem(
      icon: SizedBox(
        width: _iconSize,
        height: _iconSize,
        child: Image.asset(
          currentIndex == index ? activeIconPath : inactiveIconPath,
        ),
      ),
      title: Text(title, style: _titleStyle),
      activeColor: Color(0xff1E2E52),
      inactiveColor: Colors.grey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavyBar(
      backgroundColor: Color(0xffF4F7FD),
      selectedIndex: currentIndex,
      onItemSelected: (index) {
        setState(() {
          currentIndex = index;
        });
        widget.onItemSelected(index);
      },
      items: <BottomNavyBarItem>[
        _buildNavBarItem(0, 'Дашборд', 'assets/icons/MyNavBar/dashboard_ON.png', 'assets/icons/MyNavBar/dashboard_OFF.png'),
        _buildNavBarItem(1, 'Задачи', 'assets/icons/MyNavBar/tasks_ON.png', 'assets/icons/MyNavBar/tasks_OFF.png'),
        _buildNavBarItem(2, 'Лиды', 'assets/icons/MyNavBar/clients_ON.png', 'assets/icons/MyNavBar/clients_OFF.png'),
        _buildNavBarItem(3, 'Сообщения', 'assets/icons/MyNavBar/chats_ON.png', 'assets/icons/MyNavBar/chats_OFF.png'),
        _buildNavBarItem(4, 'Сделки', 'assets/icons/MyNavBar/deal_ON.png', 'assets/icons/MyNavBar/deal_OFF.png'),
      ],
    );
  }
}
