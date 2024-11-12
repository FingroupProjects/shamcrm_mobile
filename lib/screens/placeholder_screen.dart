
import 'package:flutter/material.dart';

class PlaceholderScreen extends StatelessWidget {
  final String message;

  PlaceholderScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }
}

// else {
//       widgets.add(PlaceholderScreen(message: 'Экран Дашборд недоступен вам.'));
//       titles.add('Дашборд');
//       navBarTitles.add('Дашборд');
//       activeIcons.add('assets/icons/MyNavBar/dashboard_ON.png');
//       inactiveIcons.add('assets/icons/MyNavBar/dashboard_OFF.png');
//     }

// else {
//       widgets.add(PlaceholderScreen(message: 'Экран Задачи недоступен вам.'));
//       titles.add('Задачи');
//       navBarTitles.add('Задачи');
//       activeIcons.add('assets/icons/MyNavBar/tasks_ON.png');
//       inactiveIcons.add('assets/icons/MyNavBar/tasks_OFF.png');
//     }