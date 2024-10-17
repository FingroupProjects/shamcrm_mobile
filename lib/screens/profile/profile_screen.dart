import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Константы для стилей
  static const Color backgroundColor = Color(0xFFF4F7FD);
  static const Color textColor = Color(0xFF1E1E1E);
  static const TextStyle titleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: textColor,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotificationSettings(context),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Настройки уведомлений',
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
      child: _buildProfileOption(
        iconPath: 'assets/icons/Profile/notification.png',
        text: 'Настройка уведомлений',
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Создаем экземпляр ApiService
        ApiService apiService = ApiService();

        // Удаляем токен
        await apiService.logout();

        // Перенаправляем пользователя на экран аутентификации
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
        );
      },
      child: _buildProfileOption(
        iconPath: 'assets/icons/Profile/logout.png',
        text: 'Выйти',
      ),
    );
  }

  Widget _buildProfileOption({required String iconPath, required String text}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor, // Цвет фона
        borderRadius: BorderRadius.circular(16), // Скругление углов
      ),
      child: Row(
        children: [
          Image.asset(
            iconPath,
            width: 40,
            height: 40,
          ),
          const SizedBox(width: 16), // Отступ между иконкой и текстом
          Expanded(
            child: Text(
              text,
              style: titleStyle,
            ),
          ),
          Image.asset(
            'assets/icons/arrow-right.png', // Путь к вашему значку
            width: 16, // Укажите нужную ширину
            height: 16, // Укажите нужную высоту
          ),
        ],
      ),
    );
  }
}
