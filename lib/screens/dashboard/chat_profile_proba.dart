import 'package:crm_task_manager/custom_widget/custom_bottom_dropdown.dart';
import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // Белый фон для AppBar
        title: Text(
          "Профиль пользователя",
          style: TextStyle(
            color: Colors.black, // Черный цвет текста
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Имя пользователя
            ListTile(
              leading: Icon(Icons.person),
              title: Text("Имя: Bahovaddinkhon"),
            ),
            // Телефон
            ListTile(
              leading: Icon(Icons.phone),
              title: Text("Телефон: 992933009966"),
            ),
            // WhatsApp
            ListTile(
              leading: Icon(Icons.chat),
              title: Text("WhatsApp: 992933009966"),
            ),
            // Количество сообщений
            ListTile(
              leading: Icon(Icons.message),
              title: Text("Количество сообщений: 6"),
            ),
            // Другие данные
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text("Дата рождения: Не указано"),
            ),
            ListTile(
              leading: Icon(Icons.location_on),
              title: Text("Адрес: Не указано"),
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text("Описание: Не указано"),
            ),
            ListTile(
              leading: Icon(Icons.date_range),
              title: Text("Дата создания: 2024-11-26"),
            ),
          ],
        ),
      ),
    );
  }
}
